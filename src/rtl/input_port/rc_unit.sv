import noc_params::*;

module rc_unit #(
    parameter DEST_ADDR_SIZE_X = 4,
    parameter DEST_ADDR_SIZE_Y = 4
)(
    input [DEST_ADDR_SIZE_X-1 : 0] x_current,
    input [DEST_ADDR_SIZE_Y-1 : 0] y_current,
    input enable_skip,
    input [DEST_ADDR_SIZE_X-1 : 0] x_skip_dest,
    input [DEST_ADDR_SIZE_Y-1 : 0] y_skip_dest,

    input logic [DEST_ADDR_SIZE_X-1 : 0] x_dest_i,
    input logic [DEST_ADDR_SIZE_Y-1 : 0] y_dest_i,
    input logic [DEST_ADDR_SIZE_L-1 : 0] l_dest_i,

    output port_t out_port_o
);

    wire signed [DEST_ADDR_SIZE_X-1 : 0] x_offset;
    wire signed [DEST_ADDR_SIZE_Y-1 : 0] y_offset;

    assign x_offset = x_dest_i - x_current;
    assign y_offset = y_dest_i - y_current;

    /*
    Combinational logic:
    - the route computation follows a DOR (Dimension-Order Routing) algorithm,
      with the nodes of the Network-on-Chip arranged in a 2D mesh structure,
      hence with 5 inputs and 5 outputs per node (except for boundary routers),
      i.e., both for input and output:
        * left, right, up and down links to the adjacent nodes
        * one link to the end node
    - the 2D Mesh coordinates scheme is mapped as following:
        * X increasing from Left to Right
        * Y increasing from  Up  to Down
    */
    always_comb
    begin
        if (enable_skip) begin
            if (x_offset == 0 & y_offset == 0) begin
                if (l_dest_i == 0) begin
                    out_port_o = DLA0;
                end else if (l_dest_i == 1) begin
                    out_port_o = DLA1;
                end else if (l_dest_i == 2) begin
                    out_port_o = DLA2;
                end else begin
                    out_port_o = DLA3;
                end
            end
            else if (x_dest_i == x_skip_dest && y_dest_i == y_skip_dest) begin
                out_port_o = SKIP;
            end
            else if (x_offset < 0)
            begin
                out_port_o = WEST;
            end
            else if (x_offset > 0)
            begin
                out_port_o = EAST;
            end
            else if (x_offset == 0 & y_offset < 0)
            begin
                out_port_o = NORTH;
            end
            else if (x_offset == 0 & y_offset > 0)
            begin
                out_port_o = SOUTH;
            end
        end else begin
            if (x_offset == 0 & y_offset == 0) begin
                if (l_dest_i == 0) begin
                    out_port_o = DLA0;
                end else if (l_dest_i == 1) begin
                    out_port_o = DLA1;
                end else if (l_dest_i == 2) begin
                    out_port_o = DLA2;
                end else if (l_dest_i == 3) begin
                    out_port_o = DLA3;
                end else begin
                    out_port_o = SKIP;
                end
            end
            else if (x_offset < 0)
            begin
                out_port_o = WEST;
            end
            else if (x_offset > 0)
            begin
                out_port_o = EAST;
            end
            else if (x_offset == 0 & y_offset < 0)
            begin
                out_port_o = NORTH;
            end
            else if (x_offset == 0 & y_offset > 0)
            begin
                out_port_o = SOUTH;
            end
        end
    end

endmodule