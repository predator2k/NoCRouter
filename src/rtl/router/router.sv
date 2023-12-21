import noc_params::*;

module router #(
    parameter BUFFER_SIZE = 16
)(
    input [DEST_ADDR_SIZE_X-1 : 0] x_current,
    input [DEST_ADDR_SIZE_Y-1 : 0] y_current,
    input                          enable_skip,
    input [DEST_ADDR_SIZE_X-1 : 0] x_skip_dest,
    input [DEST_ADDR_SIZE_Y-1 : 0] y_skip_dest,  

    input clk,
    input rst,

    //connections from upstream
    output flit_t data_out [PORT_NUM-1:0],
    output logic  [PORT_NUM-1:0] is_valid_out,
    input   [PORT_NUM-1:0] is_on_off_in,
    input   [PORT_NUM-1:0] is_allocatable_in,

    //connections from downstream
    input flit_t data_in [PORT_NUM-1:0],
    input  is_valid_in [PORT_NUM-1:0],
    output logic  is_on_off_out [PORT_NUM-1:0],
    output logic  is_allocatable_out [PORT_NUM-1:0],

    output logic error_o [PORT_NUM-1:0]
);

    input_block2crossbar ib2xbar_if();
    input_block2switch_allocator ib2sa_if();
    input_block2vc_allocator ib2va_if();
    switch_allocator2crossbar sa2xbar_if();

    input_block #(
        .BUFFER_SIZE(BUFFER_SIZE),
        .PORT_NUM(PORT_NUM)
    )
    input_block (
        .x_current(x_current),
        .y_current(y_current),
        .enable_skip(enable_skip),
        .x_skip_dest(x_skip_dest),
        .y_skip_dest(y_skip_dest),

        .rst(rst),
        .clk(clk),
        .data_i(data_in),
        .valid_flit_i(is_valid_in),
        .crossbar_if(ib2xbar_if),
        .sa_if(ib2sa_if),
        .va_if(ib2va_if),
        .on_off_o(is_on_off_out),
        .vc_allocatable_o(is_allocatable_out),
        .error_o(error_o)
    );

    crossbar #(
    )
    crossbar (
        .ib_if(ib2xbar_if),
        .sa_if(sa2xbar_if),
        .data_o(data_out)
    );

    switch_allocator #(
    )
    switch_allocator (
        .rst(rst),
        .clk(clk),
        .on_off_i(is_on_off_in),
        .ib_if(ib2sa_if),
        .xbar_if(sa2xbar_if),
        .valid_flit_o(is_valid_out)
    );
    
    vc_allocator #(
    )
    vc_allocator (
        .rst(rst),
        .clk(clk),
        .idle_downstream_vc_i(is_allocatable_in),
        .ib_if(ib2va_if)
    );

endmodule