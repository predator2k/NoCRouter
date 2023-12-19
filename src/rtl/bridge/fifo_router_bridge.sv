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
    output logic                          dla2noc_granted_vld,
    // noc2dla grant side
    input                                 noc2dla_grant_vld,
    input  [10:0]                         noc2dla_grant_data,
    output logic                          noc2dla_grant_ack,
    input  [DEST_ADDR_SIZE_X-1 : 0]       x_current,
    input  [DEST_ADDR_SIZE_Y-1 : 0]       y_current,
    input  [1:0]                          DLA_IDX,

    input [  6:0]     stgr_status
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
// noc2dla grant
// 
// =================================================================================

logic noc2dla_grnt_fifo_wen;
logic noc2dla_grnt_fifo_ren;
logic [DEST_ADDR_SIZE_X+DEST_ADDR_SIZE_Y+2+11-1:0] noc2dla_grnt_fifo_rdata;
logic noc2dla_grnt_fifo_rempty;

async_fifo #(
  .DW         (DEST_ADDR_SIZE_X+DEST_ADDR_SIZE_Y+2+DEST_ADDR_SIZE_X+DEST_ADDR_SIZE_Y+DEST_ADDR_SIZE_L),
  .AW         (3)
) noc2dla_grant_fifo (
  .wclk       (clk_dla                 ),
  .wrst       (rst_dla                 ),
  .wen        (noc2dla_grnt_fifo_wen   ),
  .wdata      (noc2dla_grnt_fifo_wdata ),
  .wfull      (noc2dla_grnt_fifo_wfull ),
  
  .rclk       (clk_router              ),
  .rrst       (rst_router              ),
  .ren        (noc2dla_grnt_fifo_ren   ),
  .rdata      (noc2dla_grnt_fifo_rdata ),
  .rempty     (noc2dla_grnt_fifo_rempty)
); 

assign noc2dla_grnt_fifo_wen = noc2dla_grant_vld && !noc2dla_grnt_fifo_wfull;
assign noc2dla_grnt_fifo_wdata = {x_current, y_current, DLA_IDX, noc2dla_grant_data};
always @(posedge clk_router or posedge rst_router) begin
    if (rst_router) begin
        noc2dla_grant_ack <= 1'b0;
    end else begin
        noc2dla_grant_ack <= noc2dla_grnt_fifo_wen;
    end
end

logic [DEST_ADDR_SIZE_X+DEST_ADDR_SIZE_Y+1-1:0] noc2dla_grnt_fifo_rdata_head_data;
logic [DEST_ADDR_SIZE_X-1 : 0]                  noc2dla_grnt_fifo_rdata_dest_x; // 4
logic [DEST_ADDR_SIZE_Y-1 : 0]                  noc2dla_grnt_fifo_rdata_dest_y; // 4
logic [DEST_ADDR_SIZE_L-1 : 0]                  noc2dla_grnt_fifo_rdata_dest_l; // 3
assign noc2dla_grnt_fifo_rdata_dest_l    = noc2dla_grnt_fifo_rdata[0                                                 +:DEST_ADDR_SIZE_L];
assign noc2dla_grnt_fifo_rdata_dest_y    = noc2dla_grnt_fifo_rdata[DEST_ADDR_SIZE_L                                  +:DEST_ADDR_SIZE_Y];
assign noc2dla_grnt_fifo_rdata_dest_x    = noc2dla_grnt_fifo_rdata[DEST_ADDR_SIZE_L+DEST_ADDR_SIZE_Y                 +:DEST_ADDR_SIZE_X];
assign noc2dla_grnt_fifo_rdata_head_data = noc2dla_grnt_fifo_rdata[DEST_ADDR_SIZE_L+DEST_ADDR_SIZE_Y+DEST_ADDR_SIZE_X+:(DEST_ADDR_SIZE_Y+DEST_ADDR_SIZE_X+2)];

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

assign router_rdbuf_ren = ok_to_send && !router_rdbuf_rempty && vc_id_assigned && stgr_status[5];
assign noc2dla_grnt_fifo_ren = ok_to_send && !noc2dla_grnt_fifo_rempty && vc_id_assigned && stgr_status[6];

logic router_rdbuf_vld;
logic noc2dla_grnt_fifo_vld;
always @(posedge clk_router or posedge rst_router) begin
    if (rst_router) begin
        router_rdbuf_vld      <= 1'b0;
        noc2dla_grnt_fifo_vld <= 1'b0;
    end else begin
        router_rdbuf_vld      <= router_rdbuf_ren;
        noc2dla_grnt_fifo_vld <= noc2dla_grnt_fifo_ren;
    end
end

always @(posedge clk_router or posedge rst_router) begin
    if (rst_router) begin
        vc_id_assigned <= 1'b0;
        vc_id          <= 1'b0;
    end else begin
        if (vc_id_assigned) begin
            if ((router_data_in.flit_label == HEADTAIL || router_data_in.flit_label == TAIL) || router_valid_in) begin
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
assign router_rdbuf_rdata_label = flit_label_t'(router_rdbuf_rdata[FLIT_TOTAL_SIZE-1:FLIT_DATA_SIZE]);
assign router_rdbuf_rdata_dest_l = router_rdbuf_rdata[0                                +:DEST_ADDR_SIZE_L];
assign router_rdbuf_rdata_dest_y = router_rdbuf_rdata[DEST_ADDR_SIZE_L                 +:DEST_ADDR_SIZE_Y];
assign router_rdbuf_rdata_dest_x = router_rdbuf_rdata[DEST_ADDR_SIZE_L+DEST_ADDR_SIZE_Y+:DEST_ADDR_SIZE_X];


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
            if (router_rdbuf_rdata_label == HEAD) begin
                router_data_in.data.head_data.x_dest  <= router_rdbuf_rdata_dest_x;
                router_data_in.data.head_data.y_dest  <= router_rdbuf_rdata_dest_y;
                router_data_in.data.head_data.l_dest  <= router_rdbuf_rdata_dest_l;
                router_data_in.data.head_data.head_pl <= '0;
            end else begin
                router_data_in.data                   <= router_rdbuf_rdata;
            end
        end else if (noc2dla_grnt_fifo_vld) begin
            router_data_in.vc_id                      <= vc_id;
            router_valid_in                           <= 1'b1;
            router_data_in.flit_label                 <= HEADTAIL;
            router_data_in.data.head_data.x_dest      <= noc2dla_grnt_fifo_rdata_dest_x;
            router_data_in.data.head_data.y_dest      <= noc2dla_grnt_fifo_rdata_dest_y;
            router_data_in.data.head_data.l_dest      <= noc2dla_grnt_fifo_rdata_dest_l;
            router_data_in.data.head_data.head_pl     <= noc2dla_grnt_fifo_rdata_head_data;
        end else begin
            router_valid_in                           <= 1'b0;
        end
    end
end

endmodule
