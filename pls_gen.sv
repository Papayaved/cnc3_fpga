`ifndef _pls_gen_
`define _pls_gen_

`include "header.sv"

module pls_gen #(
	parameter T_MIN = `T_MIN,
	parameter T_MAX = `T_MAX
)(
	input clk, clk_ena, aclr, abort,
	input permit,
	input start_clk, stop_clk,	
	input [31:0] T,
	input dir_req,
	input pause_req,
	
	output run,
	output loaded,
	output reg pls, dir,
	
	output stop_req, start_rdy,
	output reg cnt_end	
);

	reg [31:0] T0 = '1, T1 = '0;
	reg run_reg = 1'b0;
	reg [31:0] cnt = '0;
	wire load_cnt;
	wire stop; reg stop_reg = 1'b0;
	reg abort_reg = 1'b0, abort_state = 1'b0;
	wire abort_clk, abort_state_clk;
	
	reg pause_reg = 1'b0;
	wire pause;

	assign loaded = load_cnt && (start_clk || run_reg && !stop) && !abort;

	wire [31:0] T_lim = (T > T_MAX) ? T_MAX : (T < T_MIN) ? T_MIN : T;

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			begin
				T0 <= '1;
				T1 <= '0;
			end
		else if (abort || abort_state)
			begin
				T0 <= '1;
				T1 <= '0;
			end
		else if (loaded)
			if (pause_req)
				begin
					T0 <= '1;
					T1 <= '0;
				end
			else
				begin
					T0 <= T_lim[31:1] - T_lim[31:2];
					T1 <= T_lim[31:1] + T_lim[31:2];
				end

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			dir <= 1'b0;
		else if (!pause_req && loaded)
			dir <= dir_req;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			pause_reg <= 1'b0;
		else if (abort || abort_state || !run)
			pause_reg <= 1'b0;
		else if (loaded)
			pause_reg <= (pause_req) ? 1'b1 : 1'b0;
		else if (load_cnt)
			pause_reg <= 1'b0;
		
	assign pause = (pause_req && loaded || pause_reg) && !(!pause_req && loaded);			

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			run_reg <= 1'b0;
		else if (!pls && abort || abort_state)
			run_reg <= 1'b0;
		else if (!run_reg && start_clk)
			run_reg <= 1'b1;
		else if (load_cnt && stop && !loaded)
			run_reg <= 1'b0;

	assign run = abort_state || run_reg || start_clk;

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			begin
				cnt <= '0;
				cnt_end <= 1'b0;
			end
		else if (pause)
			if (abort)
				begin
					cnt <= '0;
					cnt_end <= 1'b1;
				end
			else if (loaded)
				begin
					cnt <= T;
					cnt_end <= 1'b0;
				end
			else if (cnt != '0)
				begin
					if (clk_ena)
						cnt <= cnt - 1'b1;
						
					cnt_end <= clk_ena && cnt == 'h1;
				end
			else
				cnt_end <= 1'b0;
		else if (abort_state_clk || abort_state)
			if (abort_state_clk)
				begin
					cnt <= 32'(T_MIN);
					cnt_end <= 1'b0;
				end
			else if (cnt != '0)
				begin
					cnt <= cnt - 1'b1;
					cnt_end <= cnt == 'h1;
				end
			else
				cnt_end <= 1'b0;
		else
			if (abort)
				begin
					cnt <= 32'h0;
					cnt_end <= abort_clk;
				end
			else if (loaded)
				begin
					cnt <= T_lim;
					cnt_end <= 1'b0;
				end
			else if (permit && cnt != '0)
				begin
					cnt <= cnt - 1'b1;
					cnt_end <= cnt == 'h1;
				end
			else
				cnt_end <= 1'b0;

	assign load_cnt = cnt == '0;

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			pls <= 1'b0;
		else if (pause || !run)
			pls <= 1'b0;
		else if (abort_state_clk || abort_state)
			pls <= 1'b1;
		else
			pls <= cnt >= T0 && cnt < T1;

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			stop_reg <= 1'b0;
		else if (abort || abort_state || !run || (load_cnt && start_clk))
			stop_reg <= 1'b0;
		else if (stop_clk && !start_clk)
			stop_reg <= 1'b1;

	assign stop = !abort && !abort_state && run && !(load_cnt && start_clk) && (stop_clk && !start_clk || stop_reg);

	assign stop_req = !abort && !abort_state && cnt > '0 && cnt <= 'h3;
	assign start_rdy = !abort && !abort_state && (!run || (stop && cnt <= 'h3));

	always_ff @(posedge clk, posedge aclr)
		abort_reg <= aclr ? 1'b0 : abort;
			
	assign abort_clk = abort && !abort_reg;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			abort_state <= 1'b0;
		else if (cnt == '0)
			abort_state <= 1'b0;
		else if (abort_state_clk)
			abort_state <= 1'b1;
			
	assign abort_state_clk = pls && abort && !abort_state;
			
endmodule: pls_gen

`endif
