
module router_csr #(
   parameter AWIDTH = 32,
   parameter DWIDTH = 32
) (

   input   logic                i_hclk,
   input   logic                i_hreset,
   input   logic                i_write,
   input   logic                i_read,
   input   logic [AWIDTH-1:0]   i_addr,
   input   logic [DWIDTH-1:0]   i_wdata,
   output  logic [DWIDTH-1:0]   o_rdata,
   output  logic                o_error,
   output  logic                o_ready,
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

   typedef enum logic [5:0] {
      DECODE_router_CFG_0,
      DECODE_router_CFG_1,
      DECODE_router_CFG_2,
      DECODE_router_CFG_3,
      DECODE_router_CFG_4,
      DECODE_router_CFG_5,
      DECODE_router_CFG_6,
      DECODE_router_CFG_7,
      DECODE_router_STA_0,
      DECODE_router_STA_1,
      DECODE_router_STA_2,
      DECODE_router_STA_3,
      DECODE_router_STA_4,
      DECODE_router_STA_5,
      DECODE_router_STA_6,
      DECODE_router_STA_7,
      DECODE_NOOP
   } DECODE_T;

   DECODE_T decode;

   assign o_ready = 1'b1;

   always_comb begin
      o_error = 1'b0;
      case ({16'h0,i_addr[15:0]})
         32'h0: decode = DECODE_router_CFG_0;
         32'h4: decode = DECODE_router_CFG_1;
         32'h8: decode = DECODE_router_CFG_2;
         32'hC: decode = DECODE_router_CFG_3;
         32'h10: decode = DECODE_router_CFG_4;
         32'h14: decode = DECODE_router_CFG_5;
         32'h18: decode = DECODE_router_CFG_6;
         32'h1C: decode = DECODE_router_CFG_7;
         32'h20:decode =DECODE_router_STA_0;
         32'h24:decode =DECODE_router_STA_1;
         32'h28:decode =DECODE_router_STA_2;
         32'h2C:decode =DECODE_router_STA_3;
         32'h30:decode =DECODE_router_STA_4;
         32'h34:decode =DECODE_router_STA_5;
         32'h38:decode =DECODE_router_STA_6;
         32'h3C:decode =DECODE_router_STA_7;
         default : begin 
            decode = DECODE_NOOP;
            o_error = 1'b1;
         end
      endcase
   end

   logic [31:0] router_cfg_0_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_cfg_0_q <= 32'b0;
      else
         if (i_write)
            if (decode == DECODE_router_CFG_0)
               router_cfg_0_q <= i_wdata;

   assign o_router_cfg_0 = router_cfg_0_q[31:0];

   logic [31:0] router_cfg_1_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_cfg_1_q <= 32'b0;
      else
         if (i_write)
            if (decode == DECODE_router_CFG_1)
               router_cfg_1_q <= i_wdata;

   assign o_router_cfg_1 = router_cfg_1_q[31:0];

   logic [31:0] router_cfg_2_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_cfg_2_q <= 32'b0;
      else
         if (i_write)
            if (decode == DECODE_router_CFG_2)
               router_cfg_2_q <= i_wdata;

   assign o_router_cfg_2 = router_cfg_2_q[31:0];

   logic [31:0] router_cfg_3_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_cfg_3_q <= 32'b0;
      else
         if (i_write)
            if (decode == DECODE_router_CFG_3)
               router_cfg_3_q <= i_wdata;

   assign o_router_cfg_3 = router_cfg_3_q[31:0];

   logic [31:0] router_cfg_4_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_cfg_4_q <= 32'b0;
      else
         if (i_write)
            if (decode == DECODE_router_CFG_4)
               router_cfg_4_q <= i_wdata;

   assign o_router_cfg_4 = router_cfg_4_q[31:0];

   logic [31:0] router_cfg_5_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_cfg_5_q <= 32'b0;
      else
         if (i_write)
            if (decode == DECODE_router_CFG_5)
               router_cfg_5_q <= i_wdata;

   assign o_router_cfg_5 = router_cfg_5_q[31:0];

   logic [31:0] router_cfg_6_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_cfg_6_q <= 32'b0;
      else
         if (i_write)
            if (decode == DECODE_router_CFG_6)
               router_cfg_6_q <= i_wdata;

   assign o_router_cfg_6 = router_cfg_6_q[31:0];

   logic [31:0] router_cfg_7_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_cfg_7_q <= 32'b0;
      else
         if (i_write)
            if (decode == DECODE_router_CFG_7)
               router_cfg_7_q <= i_wdata;

   assign o_router_cfg_7 = router_cfg_7_q[31:0];

   logic [31:0] router_sta_0_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_sta_0_q <= '0;
      else
         router_sta_0_q <= i_router_sta_0;

   logic [31:0] router_sta_1_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_sta_1_q <= '0;
      else
         router_sta_1_q <= i_router_sta_1;

   logic [31:0] router_sta_2_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_sta_2_q <= '0;
      else
         router_sta_2_q <= i_router_sta_2;

   logic [31:0] router_sta_3_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_sta_3_q <= '0;
      else
         router_sta_3_q <= i_router_sta_3;
   
   logic [31:0] router_sta_4_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_sta_4_q <= '0;
      else
         router_sta_4_q <= i_router_sta_4;

   logic [31:0] router_sta_5_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_sta_5_q <= '0;
      else
         router_sta_5_q <= i_router_sta_5;

   logic [31:0] router_sta_6_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_sta_6_q <= '0;
      else
         router_sta_6_q <= i_router_sta_6;

   logic [31:0] router_sta_7_q;
   always_ff @( posedge i_hclk, posedge i_hreset)
      if (i_hreset)
         router_sta_7_q <= '0;
      else
         router_sta_7_q <= i_router_sta_7;
   

   always_comb
      if (i_read)
         case (decode)
            DECODE_router_CFG_0:o_rdata=router_cfg_0_q;
            DECODE_router_CFG_1:o_rdata=router_cfg_1_q;
            DECODE_router_CFG_2:o_rdata=router_cfg_2_q;
            DECODE_router_CFG_3:o_rdata=router_cfg_3_q;
            DECODE_router_CFG_4:o_rdata=router_cfg_4_q;
            DECODE_router_CFG_5:o_rdata=router_cfg_5_q;
            DECODE_router_CFG_6:o_rdata=router_cfg_6_q;
            DECODE_router_CFG_7:o_rdata=router_cfg_7_q;
            DECODE_router_STA_0:o_rdata=router_sta_0_q;
            DECODE_router_STA_1:o_rdata=router_sta_1_q;
            DECODE_router_STA_2:o_rdata=router_sta_2_q;
            DECODE_router_STA_3:o_rdata=router_sta_3_q;
            DECODE_router_STA_4:o_rdata=router_sta_4_q;
            DECODE_router_STA_5:o_rdata=router_sta_5_q;
            DECODE_router_STA_6:o_rdata=router_sta_6_q;
            DECODE_router_STA_7:o_rdata=router_sta_7_q;
            default : o_rdata = '0;
         endcase
      else
         o_rdata = '0;

endmodule
