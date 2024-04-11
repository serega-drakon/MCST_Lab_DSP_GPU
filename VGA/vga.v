`include "vga_sync.v"
`include "clk_div2.v"

module vga (
    input           clk,
    input           rst,

    output          vga_clk,
    output          h_sync,
    output          v_sync,
    output          blank_n,
    output          sync_n,
    output  [9:0]   point_pos_x,
    output  [9:0]   point_pos_y
);

assign sync_n = 1'd0;

clk_div2 clk_div2
(
    .clk        (clk),
    .rst        (rst),
    .clk_div2   (vga_clk)
);

vga_sync vga_sync
(
    .clk        (vga_clk),
    .rst        (rst),
    .h_sync     (h_sync),
    .v_sync     (v_sync),
    .pos_x      (point_pos_x),
    .pos_y      (point_pos_y),
    .blank_n    (blank_n)
);

endmodule