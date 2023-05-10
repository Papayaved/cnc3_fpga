`ifndef _calc_sched_
`define _calc_sched_

`include "header.sv"
`include "traj_calc_2clk.sv"

module calc_sched #(parameter
	TS_WIDTH = `TS_WIDTH,
	N_WIDTH = `N_WIDTH
)(
	input clk, clk2x, aclr,
	input braking, brake_clk,
	input MotorParam[7:0] par,
//	input [7:0][TS_WIDTH-1:0] ts,
//	input [7:0][N_WIDTH-1:0] N,
//	input [7:0][31:0] V0, minus_2dVdec, R, sinH1s,
//	input [7:0] dir, mode,
	input [7:0] calc_req,
	
	output reg [7:0][TS_WIDTH-1:0] T,
	output reg [7:0][31:0] V1,
	output reg [7:0] isV1,
	output reg [7:0] valid,
	
	output error
);

	reg [2:0] task_num_in = '1;
	reg valid_in = 1'b0;
	reg [7:0] calc = '0; wire [7:0] calc_full;
	wire [7:0] l_calc_req = calc_req & ~calc_full; 
	
	always_ff @(posedge clk, posedge aclr) begin
		if (aclr)
			task_num_in <= '1;
		else if (brake_clk)
			task_num_in <= '1;
		else if (l_calc_req != '0)
			task_num_in <= next_task2(calc_req, task_num_in);
		
		valid_in <= (aclr) ? 1'b0 : (brake_clk) ? 1'b0 : l_calc_req != '0;
	end
	
	wire [TS_WIDTH - 1:0] T_res;
	wire [31:0] V1_res;
	wire isV1_res;
	wire [2:0] task_num_out;
	wire valid_out;
	
	traj_calc_2clk func(
		.aclr, .clk, .clk2x, .brake_clk, .braking,
		.par(par[task_num_in]),
		.task_num_in, .valid_in,
		.T(T_res), .V1(V1_res), .isV1(isV1_res), .task_num_out, .valid_out,
		.error
	);
	
	genvar i;
	generate for (i = 0; i < 8; i++)
		begin :gen
			always_ff @(posedge clk, posedge aclr)
				if (aclr)
					valid[i] <= 1'b0;
				else if (brake_clk)
					valid[i] <= 1'b0;
				else if (valid_out && task_num_out == i)
					valid[i] <= 1'b1;
				else if (calc_req[i])
					valid[i] <= 1'b0;
			
			always_ff @(posedge clk, posedge aclr)
				if (aclr)
					T[i] <= '1;
				else if (brake_clk)
					T[i] <= '1;
				else if (valid_out && task_num_out == i)
					T[i] <= T_res;
					
			always_ff @(posedge clk, posedge aclr)
				if (aclr)
					V1[i] <= '0;
				else if (brake_clk)
					V1[i] <= '0;
				else if (valid_out && task_num_out == i)
					V1[i] <= V1_res;
					
			always_ff @(posedge clk, posedge aclr)
				if (aclr)
					isV1[i] <= '0;
				else if (brake_clk)
					isV1[i] <= '0;
				else if (valid_out && task_num_out == i)
					isV1[i] <= isV1_res;
					
			always_ff @(posedge clk, posedge aclr)
				if (aclr)
					calc[i] <= '0;
				else if (brake_clk)
					calc[i] <= '0;
				else if (valid_in && task_num_in == i)
					calc[i] <= 1'b1;
				else if (!calc_req[i])
					calc[i] <= 1'b0;
					
			assign calc_full[i] = calc[i] || valid_in && task_num_in == i;
		end
	endgenerate
	
	function [2:0] next_task(input [7:0] req, bit [2:0] cur_task);
		int i, t;
		
		for (i = 0; i < 8; i++) begin
			t = cur_task + 1 + i;
			if (req[t[2:0]]) break;
		end
		
		return t[2:0];
	endfunction
	
	function [2:0] next_task2(input [7:0] req, bit [2:0] cur_task);
		//bit[2:0] next;
		bit [7:0] req_reg;
		bit[2:0] res;	
		
		//next = cur_task + 1'b1;
		//req_reg = {req[cur_task:0], req[7:next]};
		//req_reg = (req << cur_task) | (req >> (cur_task + 1'b1)); // error
		case (cur_task)
			3'h0: req_reg = {req[0], req[7:1]};
			3'h1: req_reg = {req[1:0], req[7:2]};
			3'h2: req_reg = {req[2:0], req[7:3]};
			3'h3: req_reg = {req[3:0], req[7:4]};
			3'h4: req_reg = {req[4:0], req[7:5]};
			3'h5: req_reg = {req[5:0], req[7:6]};
			3'h6: req_reg = {req[6:0], req[7]};
			3'h7: req_reg = req;
		endcase
		
		if (req_reg[0])
			res = cur_task + 3'h1;
		else if (req_reg[1])
			res = cur_task + 3'h2;
		else if (req_reg[2])
			res = cur_task + 3'h3;
		else if (req_reg[3])
			res = cur_task + 3'h4;
		else if (req_reg[4])
			res = cur_task + 3'h5;
		else if (req_reg[5])
			res = cur_task + 3'h6;
		else if (req_reg[6])
			res = cur_task + 3'h7;
		else
			res = cur_task;
		
		return res;
	endfunction

endmodule :calc_sched

`endif
