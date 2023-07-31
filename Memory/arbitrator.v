module arbitrator
(
	input 		clk,
	input		reset,
	input	[31:0]	enable,
	input	[191:0]	addr,
	input	[127:0]	wr_data,
	output	[127:0]	rd_data,
	output	[15:0]	val
);

reg	[3:0] 	id_curent_core;
reg		skip;
reg	[1:0]	request_core;	

function [1:0] form_request;	
	input	[31:0]	request_all;
	input	[3:0]	id_core;
begin
	form_request = {request_all[id_core * 2 + 1], request_all[id_core * 2]};
end
endfunction

function [4:0]	find_id_core;	
	input [3:0]	start_search;	
	input [31:0]	request_all;	
	input [3:0]	iteration;	
begin
	if(iteration == 4'b1111)
	begin
		find_id_core = 5'b10000;
	end
	else if(form_request(request_all,start_search + 1) == 0)
	begin
		find_id_core = find_id_core(start_search + 1, request_all, iteration + 1);
	end
	else
	begin
		find_id_core = start_search + 1;
	end
end
endfunction



always @(posedge clk)
begin
	if (reset)
	begin
		id_curent_core <= 0;
	end
	else
	begin
		
	end
end

endmodule
