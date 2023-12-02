`include "INC_global.v"

module fifo_router_bridge (
    input clk_router,
    input rst_router,
    // router side
    output flit_t               router_data_in,
    output logic                router_valid_in, 
    output logic  [VC_NUM-1:0]  router_is_on_off_in,  
    output logic  [VC_NUM-1:0]  router_is_allocatable_in,
    input flit_t                router_data_out,
    input logic                 router_valid_out, 
    input logic   [VC_NUM-1:0]  router_is_on_off_out,  
    input logic   [VC_NUM-1:0]  router_is_allocatable_out,
    // fifo side
    input  logic                         fifo2router_en,
    input  logic [FLIT_DATA_SIZE-1:0]    fifo2router_data,
    output logic                         router2fifo_en,
    output logic [FLIT_DATA_SIZE-1:0]    router2fifo_data,
    input router_write_buffer_afull
);

// =================================================================================
//
// flow control
// 
// =================================================================================

assign router_is_allocatable_in = {VC_NUM{1'b1}};
assign router_is_on_off_in = {VC_NUM{!router_write_buffer_afull}};

// =================================================================================
//
// router <--- fifo
// 
// =================================================================================

always@(posedge clk_router or posedge rst_router) begin
    if(rst_router) begin
            router2fifo_en      <= 1'b0;
            router2fifo_data    <= {FLIT_DATA_SIZE{1'b0}};
    end else begin
        if (router_valid_out) begin
            if(router_data_out.flit_label == HEAD || router_data_out.flit_label == HEADTAIL) begin
                router2fifo_en   <= 1'b0;
                router2fifo_data <= {FLIT_DATA_SIZE{1'b0}};
            end else begin
                router2fifo_en   <= (~router_write_buffer_afull) & router_valid_out;
                router2fifo_data <= router_data_out.data;
            end 
        end else begin
            router2fifo_en <= 1'b0;
            router2fifo_data <= {FLIT_DATA_SIZE{1'b0}};
        end
    end
end

// =================================================================================
//
// router ---> fifo
// 
// =================================================================================

enum logic  [1:0]           {IDLE,HEAD_STATE,BODY_STATE,TAIL_STATE}ss,ss_next;
logic       [7:0]           cnt, cnt_next;
flit_t                      router_data_in_next;
logic                       router_valid_in_next;
logic       [7:0]           dla2noc_data_len,dla2noc_data_len_next;

always_ff @(posedge clk_router or posedge rst_router) begin
    if(rst_router) begin
        ss                             <= IDLE;    
        cnt                            <= 5'b0;
        router_data_in.flit_label     <= HEADTAIL;
        router_data_in.vc_id          <= 0;
        router_data_in.data           <= {FLIT_DATA_SIZE{1'b0}};
        router_valid_in               <= 1'b0;
        dla2noc_data_len               <= 8'b0;
    end else begin
        ss                             <= ss_next;    
        cnt                            <= cnt_next;
        router_data_in                <= router_data_in_next;
        router_valid_in               <= router_valid_in_next;
        dla2noc_data_len               <= dla2noc_data_len_next;
    end
end


always_comb
begin
    router_data_in_next.flit_label                       = HEADTAIL;
    router_data_in_next.vc_id                            = 0;
    router_data_in_next.data                             = {FLIT_DATA_SIZE{1'b0}};
    ss_next                                               = ss;
    router_valid_in_next                                 = 1'b0;
    cnt_next                                              = cnt;
    dla2noc_data_len_next                                 = dla2noc_data_len;

    case(ss)
    IDLE:
    begin
        if(fifo2router_en)
        begin
            ss_next                                       = HEAD_STATE;
            router_valid_in_next                         = 1'b1;
            router_data_in_next.flit_label               = HEAD;
            router_data_in_next.vc_id                    = 0;
            router_data_in_next.data.head_data.x_dest    = fifo2router_data[FLIT_DATA_SIZE-1:FLIT_DATA_SIZE-4];
            router_data_in_next.data.head_data.y_dest    = fifo2router_data[FLIT_DATA_SIZE-5:FLIT_DATA_SIZE-8];
            router_data_in_next.data.head_data.l_dest    = fifo2router_data[FLIT_DATA_SIZE-9:FLIT_DATA_SIZE-11];
            dla2noc_data_len_next                        = fifo2router_data[FLIT_DATA_SIZE-12:FLIT_DATA_SIZE-19];
            router_data_in_next.data.head_data.head_pl   = fifo2router_data[FLIT_DATA_SIZE-20:0];
            cnt_next                                      = 8'b0;
        end
    end

    HEAD_STATE: 
    if (fifo2router_en) begin
        if(dla2noc_data_len== 8'b0)
        begin
            ss_next                                       = TAIL_STATE;
            router_data_in_next.flit_label               = TAIL;
            router_data_in_next.data                     = fifo2router_data;
            router_data_in_next.vc_id                    = 0;
            cnt_next                                      = 8'b0;
            router_valid_in_next                          = 1'b1;
        end else begin
            ss_next                                       = BODY_STATE;
            router_data_in_next.flit_label               = BODY;
            router_data_in_next.data                     = fifo2router_data;
            router_data_in_next.vc_id                    = 0;
            cnt_next                                      = 8'b1;
            router_valid_in_next                          = 1'b1;
        end
    end else begin
        ss_next = HEAD_STATE;
    end

    BODY_STATE: 
    if (fifo2router_en) begin
        if(dla2noc_data_len                               == cnt)
        begin
            ss_next                                       = TAIL_STATE;
            router_data_in_next.flit_label               = TAIL;
            router_data_in_next.data                     = fifo2router_data;
            router_data_in_next.vc_id                    = 0;
            cnt_next                                      = 8'b0;
            router_valid_in_next                          = 1'b1;
        end else begin
            ss_next                                       = BODY_STATE;
            router_data_in_next.flit_label               = BODY;
            router_data_in_next.data                     = fifo2router_data;
            router_data_in_next.vc_id                    = 0;
            cnt_next                                      = cnt + 8'b1;
            router_valid_in_next                          = 1'b1;
        end   
    end else begin
        ss_next = BODY_STATE;
    end

    TAIL_STATE:
    begin
            ss_next                                       = IDLE;
            cnt_next                                      = 5'b0;
            router_data_in_next.flit_label               = HEADTAIL;
            router_data_in_next.vc_id                    = 0;
            router_data_in_next.data                     = {FLIT_DATA_SIZE{1'b0}};
            dla2noc_data_len_next                         = 8'b0; 
    end  
    endcase
end                                       

// =============================================================================
endmodule

    


