module router_ahb_csr #(
   parameter AWIDTH = 32,
   parameter DWIDTH = 32
) (

   input   logic                i_hclk,
   input   logic                i_hreset,
   input   logic [AWIDTH-1:0]   i_haddr,
   input   logic                i_hwrite,
   input   logic                i_hsel,
   input   logic [DWIDTH-1:0]   i_hwdata,
   input   logic [1:0]          i_htrans,
   input   logic [2:0]          i_hsize,
   input   logic [2:0]          i_hburst,
   input   logic                i_hreadyin,
   output  logic                o_hready,
   output  logic [DWIDTH-1:0]   o_hrdata,
   output  logic [1:0]          o_hresp,
   //csr
   output logic [31:0] o_router_cfg_0,
   output logic [31:0] o_router_cfg_1,
   output logic [31:0] o_router_cfg_2,
   output logic [31:0] o_router_cfg_3,
   output logic [31:0] o_router_cfg_4,
   output logic [31:0] o_router_cfg_5,
   output logic [31:0] o_router_cfg_6,
   output logic [31:0] o_router_cfg_7,

   input logic [31:0] i_router_sta_0,
   input logic [31:0] i_router_sta_1,
   input logic [31:0] i_router_sta_2,
   input logic [31:0] i_router_sta_3,
   input logic [31:0] i_router_sta_4,
   input logic [31:0] i_router_sta_5,
   input logic [31:0] i_router_sta_6,
   input logic [31:0] i_router_sta_7
);

   logic                slv_write;
   logic                slv_read;
   logic                slv_error;
   logic [AWIDTH-1:0]   slv_addr;
   logic [DWIDTH-1:0]   slv_wdata;
   logic [DWIDTH-1:0]   slv_rdata;
   logic                slv_ready;

   cphy_ahb_slave #(
      .AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH)
   ) ahb_slave (
      .i_hclk     (i_hclk),
      .i_hreset   (i_hreset),
      .i_haddr    (i_haddr),
      .i_hwrite   (i_hwrite),
      .i_hsel     (i_hsel),
      .i_hwdata   (i_hwdata),
      .i_htrans   (i_htrans),
      .i_hsize    (i_hsize),
      .i_hburst   (i_hburst),
      .i_hreadyin (i_hreadyin),
      .o_hready   (o_hready),
      .o_hrdata   (o_hrdata),
      .o_hresp    (o_hresp),
      .o_write    (slv_write),
      .o_read     (slv_read),
      .o_wdata    (slv_wdata),
      .o_addr     (slv_addr),
      .i_rdata    (slv_rdata),
      .i_error    (slv_error),
      .i_ready    (slv_ready)
   );

    
   router_csr #(
      .AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH)
   ) ucie_csr (
      .i_hclk   (i_hclk),
      .i_hreset (i_hreset),
      .i_write  (slv_write),
      .i_read   (slv_read),
      .i_wdata  (slv_wdata),
      .i_addr   (slv_addr),
      .o_rdata  (slv_rdata),
      .o_error  (slv_error),
      .o_ready  (slv_ready),
      //cfg
      .o_router_cfg_0(o_router_cfg_0),
      .o_router_cfg_1(o_router_cfg_1),
      .o_router_cfg_2(o_router_cfg_2),
      .o_router_cfg_3(o_router_cfg_3),
      .o_router_cfg_4(o_router_cfg_4),
      .o_router_cfg_5(o_router_cfg_5),
      .o_router_cfg_6(o_router_cfg_6),
      .o_router_cfg_7(o_router_cfg_7),
      .i_router_sta_0(i_router_sta_0),
      .i_router_sta_1(i_router_sta_1),
      .i_router_sta_2(i_router_sta_2),
      .i_router_sta_3(i_router_sta_3),
      .i_router_sta_4(i_router_sta_4),
      .i_router_sta_5(i_router_sta_5),
      .i_router_sta_6(i_router_sta_6),
      .i_router_sta_7(i_router_sta_7)
);


endmodule
