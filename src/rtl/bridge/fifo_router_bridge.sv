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
    input  logic [FLIT_TOTAL_SIZE-1:0]   router_rdbuf_rdata,
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

logic dla2noc_grnt_fifo_wfull;
logic dla2noc_grnt_fifo_awfull;
assign router_is_allocatable_in = {VC_NUM{1'b1}};
assign router_is_on_off_in = {VC_NUM{!router_wrbuf_afull && !router_wrbuf_full && 
    !dla2noc_grnt_fifo_awfull && !dla2noc_grnt_fifo_wfull}};

// =================================================================================
//
// dla2noc grant
// 
// =================================================================================

logic dla2noc_grnt_fifo_wen;
logic [DEST_ADDR_SIZE_X+DEST_ADDR_SIZE_Y+2-1:0] dla2noc_grnt_fifo_wdata;

logic dla2noc_grnt_fifo_ren;
logic [DEST_ADDR_SIZE_X+DEST_ADDR_SIZE_Y+2-1:0] dla2noc_grnt_fifo_rdata;
logic dla2noc_grnt_fifo_rempty;

async_fifo #(
  .DW         (DEST_ADDR_SIZE_X+DEST_ADDR_SIZE_Y+2),
  .AW         (2)
) dla2noc_grant_fifo (
  .wclk       (clk_router              ),
  .wrst       (rst_router              ),
  .wen        (dla2noc_grnt_fifo_wen   ),
  .wdata      (dla2noc_grnt_fifo_wdata ),
  .wfull      (dla2noc_grnt_fifo_wfull ),
  .awfull     (dla2noc_grnt_fifo_awfull),
  
  .rclk       (clk_dla                 ),
  .rrst       (rst_dla                 ),
  .ren        (dla2noc_grnt_fifo_ren   ),
  .rdata      (dla2noc_grnt_fifo_rdata ),
  .rempty     (dla2noc_grnt_fifo_rempty)
); 

assign dla2noc_grnt_fifo_ren = !dla2noc_grnt_fifo_rempty;

always @(posedge clk_dla or posedge rst_dla) begin
    if (rst_dla) begin
        dla2noc_granted_vld <= 1'b0;
    end else begin
        dla2noc_granted_vld <= dla2noc_grnt_fifo_ren;
    end 
end

assign dla2noc_granted_dla =  dla2noc_grnt_fifo_rdata[1:0];
assign dla2noc_granted_y   =  dla2noc_grnt_fifo_rdata[2+:DEST_ADDR_SIZE_Y];
assign dla2noc_granted_x   =  dla2noc_grnt_fifo_rdata[2+DEST_ADDR_SIZE_Y+:DEST_ADDR_SIZE_X];

// =================================================================================
//
// router ---> fifo
// 
// =================================================================================

always@(posedge clk_router or posedge rst_router) begin
    if(rst_router) begin
        router_wrbuf_wen                      <= 1'b0;
        router_wrbuf_wdata                    <= '0;
        dla2noc_grnt_fifo_wen                 <= 1'b0;
    end else begin
        if (router_valid_out) begin
            if (router_data_out.flit_label == HEADTAIL) begin
                dla2noc_grnt_fifo_wen         <= 1'b1;
                router_wrbuf_wen              <= 1'b0;
                dla2noc_grnt_fifo_wdata       <= 
                    router_data_out.data.head_data.head_pl[DEST_ADDR_SIZE_X+DEST_ADDR_SIZE_Y+2-1:0];
            end else if (router_data_out.flit_label != HEAD) begin
                dla2noc_grnt_fifo_wen         <= 1'b0;
                router_wrbuf_wen              <= 1'b1;
                router_wrbuf_wdata            <= router_data_out.data;
            end
        end else begin
            dla2noc_grnt_fifo_wen             <= 1'b0;
            router_wrbuf_wen                  <= 1'b0;
            router_wrbuf_wdata                <= {FLIT_DATA_SIZE{1'b0}};
        end
    end
end

// =================================================================================
//
// router <--- fifo
// 
// =================================================================================

logic vc_id, vc_id_assigned;
logic ok_to_send;

assign ok_to_send = vc_id == 1'b0 ? router_is_on_off_out[0] : router_is_on_off_out[1];

assign router_rdbuf_ren = ok_to_send && !router_rdbuf_rempty && vc_id_assigned;

logic router_rdbuf_vld;
always @(posedge clk_router or posedge rst_router) begin
    if (rst_router) begin
        router_rdbuf_vld      <= 1'b0;
    end else begin
        router_rdbuf_vld      <= router_rdbuf_ren;
    end
end

always @(posedge clk_router or posedge rst_router) begin
    if (rst_router) begin
        vc_id_assigned <= 1'b0;
        vc_id          <= 1'b0;
    end else begin
        if (vc_id_assigned) begin
            if ((router_data_in.flit_label == HEADTAIL || router_data_in.flit_label == TAIL) && router_valid_in) begin
                vc_id_assigned <= 1'b0;
            end
        end else begin
            vc_id_assigned <= |router_is_on_off_out;
            vc_id          <= router_is_on_off_out[0]? 1'b0:1'b1;
        end
    end
end

flit_label_t router_rdbuf_rdata_label;
logic [DEST_ADDR_SIZE_X-1 : 0] router_rdbuf_rdata_dest_x; // 4
logic [DEST_ADDR_SIZE_Y-1 : 0] router_rdbuf_rdata_dest_y; // 4
logic [DEST_ADDR_SIZE_L-1 : 0] router_rdbuf_rdata_dest_l; // 3
logic [DEST_ADDR_SIZE_X+DEST_ADDR_SIZE_Y+1-1:0] noc2dla_grnt_HEAD_pl;
assign router_rdbuf_rdata_label = flit_label_t'(router_rdbuf_rdata[FLIT_TOTAL_SIZE-1:FLIT_DATA_SIZE]);
assign router_rdbuf_rdata_dest_l = router_rdbuf_rdata[0                                +:DEST_ADDR_SIZE_L];
assign router_rdbuf_rdata_dest_y = router_rdbuf_rdata[DEST_ADDR_SIZE_L                 +:DEST_ADDR_SIZE_Y];
assign router_rdbuf_rdata_dest_x = router_rdbuf_rdata[DEST_ADDR_SIZE_L+DEST_ADDR_SIZE_Y+:DEST_ADDR_SIZE_X];
assign noc2dla_grnt_HEAD_pl = router_rdbuf_rdata[DEST_ADDR_SIZE_L+DEST_ADDR_SIZE_Y+DEST_ADDR_SIZE_X+:(DEST_ADDR_SIZE_Y+DEST_ADDR_SIZE_X+2)];


always @(posedge clk_router or posedge rst_router) begin
    if (rst_router) begin
        router_data_in.flit_label                     <= HEADTAIL;
        router_data_in.data                           <= '0;
        router_data_in.vc_id                          <= 1'b0;
        router_valid_in                               <= 1'b0;
    end else begin
        if (router_rdbuf_vld) begin
            router_data_in.vc_id                      <= vc_id;
            router_valid_in                           <= 1'b1;
            router_data_in.flit_label                 <= router_rdbuf_rdata_label;
            if (router_rdbuf_rdata_label == HEAD || router_rdbuf_rdata_label == HEADTAIL) begin
                router_data_in.data.head_data.x_dest  <= router_rdbuf_rdata_dest_x;
                router_data_in.data.head_data.y_dest  <= router_rdbuf_rdata_dest_y;
                router_data_in.data.head_data.l_dest  <= router_rdbuf_rdata_dest_l;
                if (router_rdbuf_rdata_label == HEAD) begin    
                    router_data_in.data.head_data.head_pl <= '0;
                end else begin
                    router_data_in.data.head_data.head_pl <= noc2dla_grnt_HEAD_pl;
                end
            end else begin
                router_data_in.data                   <= router_rdbuf_rdata;
            end
        end else begin
            router_valid_in                           <= 1'b0;
        end
    end
end

endmodule
