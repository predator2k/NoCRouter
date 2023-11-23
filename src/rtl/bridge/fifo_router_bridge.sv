import noc_params::*;

module fifo_router_bridge (
    input clk_router,
    input rst_router,
    // router side
    output flit_t               router_data_out,
    output logic                router_valid_out, 
    output logic  [VC_NUM-1:0]  router_is_on_off_out,  
    output logic  [VC_NUM-1:0]  router_is_allocatable_out,
    input flit_t                router_data_in,
    input logic                 router_valid_in, 
    input logic   [VC_NUM-1:0]  router_is_on_off_in,  
    input logic   [VC_NUM-1:0]  router_is_allocatable_in,
    // fifo side
    input  logic                             fifo2router_en,
    input  logic [TOTAL_PAYLOAD_SIZE-1:0]    fifo2router_data,
    output logic                             router2fifo_en,
    output logic [TOTAL_PAYLOAD_SIZE-1:0]    router2fifo_data,
    input router_write_buffer_afull
);

// =================================================================================
//
// flow control
// 
// =================================================================================

assign router_is_allocatable_out = {VC_NUM{1'b1}};
assign router_is_on_off_out = {VC_NUM{!router_write_buffer_afull}};

// =================================================================================
//
// router <--- fifo
// 
// =================================================================================

always@(posedge clk_router or posedge rst_router) begin
    if(rst_fifo) begin
            router2fifo_en      <= 1'b0;
            router2fifo_data    <= {TOTAL_PAYLOAD_SIZE{1'b0}};
    end else begin
        if(router_data_in.flit_label == HEAD || router_data_in.flit_label == HEADTAIL) begin
            router2fifo_en   <= 1'b0;
            router2fifo_data <= {TOTAL_PAYLOAD_SIZE{1'b0}};
        end else begin
            router2fifo_en   <= (~router_write_buffer_afull) & router_valid_in;
            router2fifo_data <= router_data_in.data;
        end
    end
end

// =================================================================================
//
// router ---> fifo
// 
// =================================================================================

enum logic  [1:0]           {IDLE,HEAD_STATE,BODY_STATE,TAIL_STATE}ss,ss_next;
logic       [4:0]           cnt, cnt_next;
flit_t                      router_data_out_next;
logic                       router_valid_out_next;
logic       [4:0]           dla2noc_data_len,dla2noc_data_len_next;

always_ff @(posedge clk_noc or posedge rst_noc) begin
    if(rst_noc) begin
        ss                             <= IDLE;    
        cnt                            <= 5'b0;
        router_data_out.flit_label     <= HEADTAIL;
        router_data_out.vc_id          <= 0;
        router_data_out.data           <= {TOTAL_PAYLOAD_SIZE{1'b0}};
        router_valid_out               <= 1'b0;
        dla2noc_data_len               <= 5'b0;
    end else begin
        ss                             <= ss_next;    
        cnt                            <= cnt_next;
        router_data_out                <= router_data_out_next;
        router_valid_out               <= router_valid_out_next;
        dla2noc_data_len               <= dla2noc_data_len_next;
    end
end


always_comb
begin
    router_data_out_next.flit_label                       = HEADTAIL;
    router_data_out_next.vc_id                            = 0;
    router_data_out_next.data                             = {TOTAL_PAYLOAD_SIZE{1'b0}};
    ss_next                                               = ss;
    router_valid_out_next                                 = router_valid_out;
    cnt_next                                              = cnt;
    dla2noc_data_len_next                                 = dla2noc_data_len;

    case(ss)
    IDLE:
    begin
        if(fifo2router_en)
        begin
            ss_next                                       = HEAD_STATE;
            router_valid_out_next                         = 1'b1;
            router_data_out_next.flit_label               = HEAD;
            router_data_out_next.vc_id                    = 0;
            router_data_out_next.data.head_data.x_dest    = fifo2router_data[TOTAL_PAYLOAD_SIZE-1:TOTAL_PAYLOAD_SIZE-4];
            router_data_out_next.data.head_data.y_dest    = fifo2router_data[TOTAL_PAYLOAD_SIZE-5:TOTAL_PAYLOAD_SIZE-8];
            router_data_out_next.data.head_data.head_pl   = fifo2router_data[TOTAL_PAYLOAD_SIZE-9:0];
            dla2noc_data_len_next                         = fifo2router_data[TOTAL_PAYLOAD_SIZE-9:TOTAL_PAYLOAD_SIZE-13];
            cnt_next                                      = 5'b0;
        end
    end

    HEAD_STATE:
    begin
        if(dla2noc_data_len== 5'b0)
        begin
            ss_next                                       = TAIL_STATE;
            router_data_out_next.flit_label               = TAIL;
            router_data_out_next.data                     = fifo2router_data;
            router_data_out_next.vc_id                    = 0;
            cnt_next                                      = 5'b0;
        end else begin
            ss_next                                       = BODY_STATE;
            router_data_out_next.flit_label               = BODY;
            router_data_out_next.data                     = fifo2router_data;
            router_data_out_next.vc_id                    = 0;
            cnt_next                                      = 5'b1;
        end
    end

    BODY_STATE:
    begin
        if(dla2noc_data_len                               == cnt)
        begin
            ss_next                                       = TAIL_STATE;
            router_data_out_next.flit_label               = TAIL;
            router_data_out_next.data                     = fifo2router_data;
            router_data_out_next.vc_id                    = 0;
            cnt_next                                      = 5'b0;
        end else begin
            ss_next                                       = BODY_STATE;
            router_data_out_next.flit_label               = BODY;
            router_data_out_next.data                     = fifo2router_data;
            router_data_out_next.vc_id                    = 0;
            cnt_next                                      = cnt + 5'b1;
        end   
    end

    TAIL_STATE:
    begin
            ss_next                                       = IDLE;
            cnt_next                                      = 5'b0;
            router_data_out_next.flit_label               = HEADTAIL;
            router_data_out_next.vc_id                    = 0;
            router_data_out_next.data                     = {TOTAL_PAYLOAD_SIZE{1'b0}};
            router_valid_out_next                         = 1'b0;
            dla2noc_data_len_next                         = 5'b0; 
    end  
    endcase
end                                       

// =============================================================================
endmodule

    


