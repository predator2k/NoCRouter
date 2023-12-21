import noc_params::*;

module input_port #(
    parameter BUFFER_SIZE = 8
)(
    input [DEST_ADDR_SIZE_X-1 : 0] x_current,
    input [DEST_ADDR_SIZE_Y-1 : 0] y_current,
    input                          enable_skip,
    input [DEST_ADDR_SIZE_X-1 : 0] x_skip_dest,
    input [DEST_ADDR_SIZE_Y-1 : 0] y_skip_dest,
    
    input flit_t data_i,
    input valid_flit_i,
    input rst,
    input clk,
    // input [VC_SIZE-1:0] sa_sel_vc_i,
    // input [VC_SIZE-1:0] va_new_vc_i [VC_NUM-1:0],
    input va_valid_i,
    input sa_valid_i,
    output flit_t xb_flit_o,
    output logic is_on_off_o,
    output logic is_allocatable_vc_o,
    output logic va_request_o,
    output logic sa_request_o,
    // output logic [VC_SIZE-1:0] sa_downstream_vc_o [VC_NUM-1:0],
    output port_t out_port_o,
    output logic is_full_o,
    output logic is_empty_o,
    output logic error_o
);

    flit_t data_cmd;
    flit_t data_out;

    port_t out_port_cmd;

    logic read_cmd;
    logic write_cmd;

    genvar vc;
    generate
        // for(vc=0; vc<VC_NUM; vc++)
        begin: generate_virtual_channels
            input_buffer #(
                .BUFFER_SIZE(BUFFER_SIZE)
            )
            input_buffer (
                .data_i(data_cmd),
                .read_i(read_cmd),
                .write_i(write_cmd),
                // .vc_new_i(va_new_vc_i),
                .vc_valid_i(va_valid_i),
                .out_port_i(out_port_cmd),
                .rst(rst),
                .clk(clk),
                .data_o(data_out),
                .is_full_o(is_full_o),
                .is_empty_o(is_empty_o),
                .on_off_o(is_on_off_o),
                .out_port_o(out_port_o),
                .vc_request_o(va_request_o),
                .switch_request_o(sa_request_o),
                .vc_allocatable_o(is_allocatable_vc_o),
                // .downstream_vc_o(sa_downstream_vc_o),
                .error_o(error_o)
            );
        end
    endgenerate

    rc_unit #(
        .DEST_ADDR_SIZE_X(DEST_ADDR_SIZE_X),
        .DEST_ADDR_SIZE_Y(DEST_ADDR_SIZE_Y)
    )
    rc_unit (
        .x_current(x_current),
        .y_current(y_current), 
        .enable_skip(enable_skip),
        .x_skip_dest(x_skip_dest),
        .y_skip_dest(y_skip_dest),  
          
        .x_dest_i(data_i.data.head_data.x_dest),
        .y_dest_i(data_i.data.head_data.y_dest),
        .l_dest_i(data_i.data.head_data.l_dest),
        .out_port_o(out_port_cmd)
    );

    /*
    Combinational logic:
    - if the input flit is valid, assert the write command of the corresponding
      virtual channel buffer where the flit has to be stored;
    - assert the read command of the virtual channel buffer selected by the
      interfaced switch allocator and propagate at the crossbar interface the
      corresponding flit.
    */
    always_comb
    begin
        data_cmd.flit_label = data_i.flit_label;
        data_cmd.data = data_i.data;
        
        write_cmd = 1'b0;
        if(valid_flit_i)
            write_cmd = 1;

        read_cmd = 1'b0;
        if(sa_valid_i)
            read_cmd = 1'b1;
        xb_flit_o = data_out;
    end

endmodule