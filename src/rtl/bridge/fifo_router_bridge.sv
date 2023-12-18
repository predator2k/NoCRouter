`include "INC_global.v"

`default_nettype none

module fifo_router_bridge (
    input  logic                clk_router,
    input  logic                rst_router,
    input  logic                clk_dla,
    input  logic                rst_dla,
    // router side
    output flit_t               router_data_in,
    output logic                router_valid_in, 
    output logic  [VC_NUM-1:0]  router_is_on_off_in,  
    output logic  [VC_NUM-1:0]  router_is_allocatable_in,
    input  flit_t               router_data_out,
    input  logic                router_valid_out, 
    input  logic  [VC_NUM-1:0]  router_is_on_off_out,  
    input  logic  [VC_NUM-1:0]  router_is_allocatable_out,
    // fifo side
    input                                router_wrbuf_afull,
    input                                router_wrbuf_full,
    output logic                         router_wrbuf_wen,
    output logic [FLIT_DATA_SIZE-1:0]    router_wrbuf_wdata,
    input  logic                         router_rdbuf_rempty,
    output logic                         router_rdbuf_ren,
    input  logic [FLIT_DATA_SIZE-1:0]    router_rdbuf_rdata,
    // dla2noc grant side
    output logic [DEST_ADDR_SIZE_X-1 : 0] dla2noc_granted_x,
    output logic [DEST_ADDR_SIZE_Y-1 : 0] dla2noc_granted_y,
    output logic [1 : 0]                  dla2noc_granted_dla,
    output logic                          dla2noc_granted_vld
);

// =================================================================================
//
// flow control
// 
// =================================================================================

assign router_is_allocatable_in = {VC_NUM{1'b1}};
assign router_is_on_off_in = {VC_NUM{!router_wrbuf_afull && !router_wrbuf_full}};

// =================================================================================
//
// dla2noc grant
// 
// =================================================================================

logic grnt_fifo_wen;
logic [DEST_ADDR_SIZE_X+DEST_ADDR_SIZE_Y+2-1:0] grnt_fifo_wdata;

logic grnt_fifo_ren;
logic [DEST_ADDR_SIZE_X+DEST_ADDR_SIZE_Y+2-1:0] grnt_fifo_rdata;
logic grnt_fifo_rempty;

async_fifo #(
  .DW         (DEST_ADDR_SIZE_X+DEST_ADDR_SIZE_Y+2),
  .AW         (3)
) dla2noc_grant_fifo (
  .wclk       (clk_router      ),
  .wrst       (rst_router      ),
  .wen        (grnt_fifo_wen   ),
  .wdata      (grnt_fifo_wdata ),
  
  .rclk       (clk_dla         ),
  .rrst       (rst_dla         ),
  .ren        (grnt_fifo_ren   ),
  .rdata      (grnt_fifo_rdata ),
  .rempty     (grnt_fifo_rempty)
); 

assign grnt_fifo_ren = !grnt_fifo_rempty;

always @(posedge clk_dla or posedge rst_dla) begin
    if (rst_dla) begin
        dla2noc_granted_vld <= 1'b0;
    end else begin
        dla2noc_granted_vld <= grnt_fifo_ren;
    end 
end

assign dla2noc_granted_dla =  grnt_fifo_rdata[1:0];
assign dla2noc_granted_y   =  grnt_fifo_rdata[2+:DEST_ADDR_SIZE_Y];
assign dla2noc_granted_x   =  grnt_fifo_rdata[2+DEST_ADDR_SIZE_Y+:DEST_ADDR_SIZE_X];

// =================================================================================
//
// router ---> fifo
// 
// =================================================================================

always@(posedge clk_router or posedge rst_router) begin
    if(rst_router) begin
        router_wrbuf_wen      <= 1'b0;
        router_wrbuf_wdata    <= '0;
        grnt_fifo_wen         <= 1'b0;
    end else begin
        if (router_valid_out) begin
            if (router_data_out.flit_label == HEADTAIL) begin
                grnt_fifo_wen         <= 1'b1;
                router_wrbuf_wen      <= 1'b0;
                grnt_fifo_wdata       <= router_data_out.data.head_data.head_pl[DEST_ADDR_SIZE_X+DEST_ADDR_SIZE_Y+2-1:0];
            end else if (router_data_out.flit_label != HEAD) begin
                grnt_fifo_wen         <= 1'b0;
                router_wrbuf_wen      <= 1'b1;
                router_wrbuf_wdata    <= router_data_out.data;
            end
        end else begin
            grnt_fifo_wen   <= 1'b0;
            router_wrbuf_wen      <= 1'b0;
            router_wrbuf_wdata    <= {FLIT_DATA_SIZE{1'b0}};
        end
    end
end

// =================================================================================
//
// router <--- fifo
// 
// =================================================================================

enum logic  [2:0]  {IDLE,HEAD_STATE,BODY_STATE,TAIL_STATE,FETCH_HEAD} ss, ss_next;
logic       [7:0]           cnt, cnt_next, cnt_d;
flit_t                      router_data_in_next;
logic                       router_valid_in_next;
logic                       dla2noc_fifo_ren_next;
logic       [7:0]           dla2noc_data_len,dla2noc_data_len_next;
logic                       dla2noc_fifo_rempty_d,dla2noc_fifo_ren_d;
logic                       flits_vc_id, flits_vc_id_next;

always_ff @(posedge clk_router or posedge rst_router) begin
    if(rst_router) begin
        ss                             <= IDLE;    
        cnt                            <= 8'b0;
        cnt_d                          <= 8'b0;
        router_data_in.flit_label      <= HEADTAIL;
        router_data_in.vc_id           <= 0;
        router_data_in.data            <= {FLIT_DATA_SIZE{1'b0}};
        router_valid_in                <= 1'b0;
        dla2noc_data_len               <= 8'b0;
        router_rdbuf_ren               <= 8'b0;
        dla2noc_fifo_rempty_d          <= 1'b0;
        dla2noc_fifo_ren_d             <= 1'b0;
        flits_vc_id                    <= 1'b0;
    end else begin
        ss                             <= ss_next;    
        cnt                            <= cnt_next;
        cnt_d                          <= cnt;
        router_data_in                 <= router_data_in_next;
        router_valid_in                <= router_valid_in_next;
        dla2noc_data_len               <= dla2noc_data_len_next;
        router_rdbuf_ren               <= dla2noc_fifo_ren_next;
        dla2noc_fifo_rempty_d          <= router_rdbuf_rempty;
        dla2noc_fifo_ren_d             <= router_rdbuf_ren;
        flits_vc_id                    <= flits_vc_id_next;
    end
end

logic ok_to_send;
assign ok_to_send = flits_vc_id == 1'b0 ? router_is_on_off_out[0] : router_is_on_off_out[1];

always_comb
begin
    router_data_in_next.flit_label                        = HEADTAIL;
    router_data_in_next.vc_id                             = '0;
    router_data_in_next.data                              = {FLIT_DATA_SIZE{1'b0}};
    ss_next                                               = ss;
    router_valid_in_next                                  = 1'b0;
    cnt_next                                              = cnt;
    dla2noc_data_len_next                                 = dla2noc_data_len;
    dla2noc_fifo_ren_next                                 = 1'b0;
    flits_vc_id_next                                      = flits_vc_id;

    case(ss)
    IDLE:
    begin
        if(!router_rdbuf_rempty && (|router_is_on_off_out))
        begin
            ss_next                                      = FETCH_HEAD;
            dla2noc_fifo_ren_next                        = 1'b1;
            flits_vc_id_next                             = router_is_on_off_out[0] ? 1'b0 : 1'b1;
        end
    end

    FETCH_HEAD:
    begin
            ss_next                                      = HEAD_STATE;
    end

    HEAD_STATE:
    begin
        if (router_rdbuf_rdata[0]) begin
            ss_next                                      = IDLE;
            router_valid_in_next                         = 1'b1;
            router_data_in_next.flit_label               = HEADTAIL;
            router_data_in_next.vc_id                    = flits_vc_id;
            router_data_in_next.data.head_data.x_dest    = router_rdbuf_rdata[11:8];
            router_data_in_next.data.head_data.y_dest    = router_rdbuf_rdata[7:4];
            router_data_in_next.data.head_data.l_dest    = router_rdbuf_rdata[3:1];
            dla2noc_data_len_next                        = '0;
            router_data_in_next.data.head_data.head_pl   = router_rdbuf_rdata[12+DEST_ADDR_SIZE_X+DEST_ADDR_SIZE_Y+2-1:12];
            cnt_next                                     = '0; 
        end else begin
            ss_next                                      = BODY_STATE;
            router_valid_in_next                         = 1'b1;
            router_data_in_next.flit_label               = HEAD;
            router_data_in_next.vc_id                    = flits_vc_id;
            router_data_in_next.data.head_data.x_dest    = router_rdbuf_rdata[FLIT_DATA_SIZE-1:FLIT_DATA_SIZE-4];
            router_data_in_next.data.head_data.y_dest    = router_rdbuf_rdata[FLIT_DATA_SIZE-5:FLIT_DATA_SIZE-8];
            router_data_in_next.data.head_data.l_dest    = router_rdbuf_rdata[FLIT_DATA_SIZE-9:FLIT_DATA_SIZE-11];
            dla2noc_data_len_next                        = router_rdbuf_rdata[FLIT_DATA_SIZE-12:FLIT_DATA_SIZE-19];
            router_data_in_next.data.head_data.head_pl   = router_rdbuf_rdata[FLIT_DATA_SIZE-20:0];
            cnt_next                                     = 8'b0;
        end
    end


    BODY_STATE: 
    begin
        if(dla2noc_data_len-1 == cnt)
        begin
            ss_next                                       = TAIL_STATE;
            router_data_in_next.flit_label                = TAIL;
            router_data_in_next.data                      = router_rdbuf_rdata;
            router_data_in_next.vc_id                     = flits_vc_id;
            cnt_next                                      = 8'b0;
            router_valid_in_next                          = 1'b1;
            dla2noc_fifo_ren_next                         = 1'b0;
        end else begin
            ss_next                                       = BODY_STATE;
            router_data_in_next.flit_label                = BODY;
            router_data_in_next.data                      = router_rdbuf_rdata;
            router_data_in_next.vc_id                     = flits_vc_id;
            router_valid_in_next                          = dla2noc_fifo_ren_d && !dla2noc_fifo_rempty_d;
            if (dla2noc_fifo_ren_d && !dla2noc_fifo_rempty_d) begin
                cnt_next                                      = cnt + 8'b1;
            end
            if (!router_rdbuf_rempty && ok_to_send && (dla2noc_data_len-2 != cnt)) begin
                dla2noc_fifo_ren_next                         = 1'b1;
            end
        end   
    end

    TAIL_STATE:
    begin
            ss_next                                       = IDLE;
    end  
    endcase
end                                       

endmodule
