module vga_sync (
    input   clk,
    input   rst,

    output  reg     h_sync,
    output  reg     v_sync,
    output  [9:0]   pos_x,
    output  [9:0]   pos_y,
    output          blank_n
);

localparam h_front_t = 16;
localparam h_sync_t = 96;
localparam h_back_t = 48;
localparam h_active_t = 640;
localparam h_blank_t = h_front_t + h_sync_t + h_back_t;
localparam h_total_t = h_active_t + h_blank_t;
localparam h_blank_t_div5 = h_blank_t / 5;

localparam v_front_t = 10;
localparam v_sync_t = 2;
localparam v_back_t = 33;
localparam v_active_t = 480;
localparam v_blank_t = v_front_t + v_sync_t + v_back_t;
localparam v_total_t = v_active_t + v_blank_t;
localparam v_blank_t_div15 = v_blank_t / 15;

reg [9:0] h_counter;
reg [9:0] v_counter;

reg [9:0] h_counter_div5;
reg [9:0] v_counter_div15;

always @(posedge (clk & ~rst))
begin
	if(rst)
	begin
		{h_counter_div5, v_counter_div15} <= 20'b0;
        //h_counter_div5 <= 0;
        //v_counter_div15 <= 0;
	end
    else
    begin
	    h_counter_div5 <= h_counter_div5 + ((h_counter_div5 + 1) * 5 == h_counter);
	    v_counter_div15 <= v_counter_div15 + ((v_counter_div15 + 1) * 15 == v_counter);
    end
end

assign pos_x = h_counter_div5 - h_blank_t_div5;
assign pos_y = v_counter_div15 - v_blank_t_div15;

assign blank_n = ~((h_counter < h_blank_t) || (v_counter < v_blank_t));

always @(posedge (clk & ~rst))
begin
    if (rst)
    begin
        {h_sync, v_sync, h_counter, v_counter} <= 22'd0;
        //h_sync <= 0;
        //v_sync <= 0;
        //h_counter <= 0;
        //v_counter <= 0;
    end
    else
    begin
        h_counter <= (h_counter == h_total_t - 1) ? 10'd0 : h_counter + 1'd1;
        h_sync <= (h_counter < h_front_t - 1) | (h_counter > h_front_t + h_sync_t - 1);

        if (h_counter == h_front_t + h_sync_t - 1)
        begin
            v_counter <= (v_counter == v_total_t - 1) ? 10'd0 : v_counter + 1'd1;
            v_sync <= (v_counter < v_front_t - 1) | (v_counter > v_front_t + v_sync_t - 1);
        end
    end
end

endmodule