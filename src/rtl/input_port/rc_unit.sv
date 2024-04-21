import noc_params::*;

module rc_unit #(
    parameter DEST_ADDR_SIZE_X = 4,
    parameter DEST_ADDR_SIZE_Y = 4
)(
    input [DEST_ADDR_SIZE_X-1 : 0] x_current,
    input [DEST_ADDR_SIZE_Y-1 : 0] y_current,
    input [7:0]                    router_conn,
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

    function port_t config2orientation;
        input [1:0] cfg;
        begin
            case(cfg)
            2'b00: config2orientation = NORTH;
            2'b01: config2orientation = SOUTH;
            2'b10: config2orientation = EAST;
            2'b11: config2orientation = WEST;
            endcase
        end
    endfunction

    port_t TO_NORTH;
    assign TO_NORTH = config2orientation(router_conn[1:0]);
    port_t TO_SOUTH;
    assign TO_SOUTH = config2orientation(router_conn[3:2]);
    port_t TO_WEST;
    assign TO_WEST = config2orientation(router_conn[5:4]);
    port_t TO_EAST;
    assign TO_EAST = config2orientation(router_conn[7:6]);

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
        out_port_o = DLA0;
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
            out_port_o = TO_WEST;
        end
        else if (x_offset > 0)
        begin
            out_port_o = TO_EAST;
        end
        else if (x_offset == 0 & y_offset < 0)
        begin
            out_port_o = TO_NORTH;
        end
        else if (x_offset == 0 & y_offset > 0)
        begin
            out_port_o = TO_SOUTH;
        end
    end

endmodule