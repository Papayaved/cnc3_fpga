/*
	Counter for quadrature rotary encoder with low-pass filter
*/

`ifndef _rot_enc_flt_
`define _rot_enc_flt_
`include "lpf_cap.sv"
`include "q_rotary_enc.sv"

module rot_enc_zero(
	input clock,
	input sclr,
	input ena,
	input dir, // main direction
	input A, B, Z,
	output signed [31:0] bidir_counter,
	output error,
	output ready, // counter enabled
	
	output reg signed [31:0] Z_pos,
	output reg Z_flag,
	input Z_clr,
	
	input addr,
	input [1:0] be,
	input write,	
	input [15:0] data,
	
	output enc_changed
);
	reg A_reg = 1'b0, B_reg = 1'b0, Z_reg = 1'b0;
	wire A_flt, B_flt, Z_flt;
	reg [1:0] dir_reg = '0;
	wire dir_changed;
	wire [2:0] flt_ready;
	
	// to trigger A, B signals on input pins
	always_ff @(posedge clock) begin
		A_reg <= A;
		B_reg <= B;
		dir_reg <= {dir_reg[0], dir};
	end		
		
	assign dir_changed = dir_reg[1] ^ dir_reg[0];
	
	// debouncing
	lpf_cap #(14) // 72MHz / 2**14 = 4.4kHz
		f0(.clock, .sclr(dir_changed), .in(A_reg), .out(A_flt), .ready(flt_ready[0]), .timeout()),
		f1(.clock, .sclr(dir_changed), .in(B_reg), .out(B_flt), .ready(flt_ready[1]), .timeout()),
		f2(.clock, .sclr(dir_changed), .in(Z_reg), .out(Z_flt), .ready(flt_ready[2]), .timeout());
	
	reg ready_reg = 1'b0;
	always_ff @(posedge clock)
		ready_reg <= (dir_changed) ? 1'b0 : &flt_ready;
	
	assign ready = ready_reg;
	
	q_rotary_enc enc_inst(
		.clock, .sclr(sclr || dir_changed), .ena(&flt_ready & ena), .dir(dir_reg[0]),
		.A(A_flt), .B(B_flt),
		.bidir_counter,
		.error,
		.addr, .be, .write, .data,
		.enc_changed
	);
	
	reg Z_flt_reg = 1'b0;
	wire Z_clk = Z_flt_reg && !Z_flt;
	
	always_ff @(posedge clock) begin
		Z_flt_reg <= (sclr || dir_changed) ? 1'b0 : Z_flt;
		
		if (sclr || dir_changed)
			Z_pos <= '0;
		else if (Z_clk)
			Z_pos <= bidir_counter;
		
		if (sclr || dir_changed || Z_clr)
			Z_flag <= 1'b0;
		else if (Z_clk)
			Z_flag <= 1'b1;
	end

endmodule :rot_enc_zero

`endif
