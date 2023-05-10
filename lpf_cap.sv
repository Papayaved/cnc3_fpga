/*
Simple low-pass filter. Digital capacity
*/

`ifndef _lpf_cap_
`define _lpf_cap_
`include "header.sv"

module lpf_cap #(parameter FILTER_WIDTH = 7)( // about half bit
	input clock, sclr,
	input in,
	output out,
	output ready, timeout
);

	lpf_cap_full #(.FILTER_WIDTH(FILTER_WIDTH)) lpf_inst(
		.clock, .aclr(1'b0), .sclr, .clock_ena(1'b1), .in,
		.out, .ready, .timeout
	);

endmodule :lpf_cap

module lpf_cap_full #(parameter
	FILTER_WIDTH = 7, // 128
	LIMIT = 2 ** (FILTER_WIDTH - 2) - 1, // 31
	LIMIT_UP = 2 ** FILTER_WIDTH - 1 - LIMIT, // 95
	LIMIT_DOWN = LIMIT // 31
)( // about half bit
	input clock, aclr, sclr, clock_ena,
	input in,
	output reg out, ready, timeout
);
	reg [FILTER_WIDTH-1:0] cnt = {1'b1, {(FILTER_WIDTH-2){1'b0}}};
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			cnt <= {1'b1, {(FILTER_WIDTH-2){1'b0}}}; // middle value
		else if (sclr)
			cnt <= {1'b1, {(FILTER_WIDTH-2){1'b0}}};
		else if (clock_ena)
			if (in == 1'b1 && cnt != '1)
				cnt <= cnt + 1'b1; // charging
			else if (in == 1'b0 && cnt != '0)
				cnt <= cnt - 1'b1; // discharging
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			out <= 1'b0;
		else if (sclr)
			out <= 1'b0;
		else if (clock_ena)
			if (cnt >= LIMIT_UP) // full
				out <= 1'b1;
			else if (cnt <= LIMIT_DOWN) // empty
				out <= 1'b0;
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			ready <= 1'b0;
		else if (sclr)
			ready <= 1'b0;
		else if (clock_ena && (cnt == '1 || cnt == '0))
			ready <= 1'b1;
	
	localparam TIMER_WIDTH = FILTER_WIDTH + 4;
	
	reg [TIMER_WIDTH-1:0] timer = '0;
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			timer <= '0;
		else if (sclr || !ready)
			timer <= '0;
		else if (clock_ena)
			if (cnt >= LIMIT_UP || cnt <= LIMIT_DOWN)
				timer <= '0;
			else if (timer != '1)
				timer <= timer + 1'b1;
	
	// long time in middle state
	always_ff @(posedge clock, posedge aclr)
		timeout <= (aclr) ? 1'b0 : (sclr) ? 1'b0 : timer == '1;
	
endmodule :lpf_cap_full

//module lpf_cap_high #(parameter FILTER_WIDTH = 7)(
//	input clock, aclr, sclr, clock_ena,
//	input in,
//	output reg out
//);
//
//	reg [FILTER_WIDTH-1:0] cnt = '0;
//	
//	always_ff @(posedge clock, posedge aclr)
//		if (aclr)
//			cnt <= '0;
//		else if (sclr)
//			cnt <= '0;
//		else if (clock_ena)
//			if (in == 1'b1 && cnt != '1)
//				cnt <= cnt + 1'b1; // charging
//			else if (in == 1'b0)
//				cnt <= '0; // quick discharge
//	
//	always_ff @(posedge clock, posedge aclr)
//		if (aclr)
//			out <= 1'b0;
//		else if (sclr)
//			out <= 1'b0;
//		else if (clock_ena)
//			out <= cnt == '1;
//
//endmodule :lpf_cap_high

module input_filter #(parameter
	SYS_CLOCK = 72_000_000,
	POLL_CLOCK = 100_000,
	FILTER_WIDTH = 7
)(
	input clock, aclr, sclr,
	input in, level,
	output out,
	output ready, timeout
);

	localparam MAX = SYS_CLOCK / POLL_CLOCK - 1;
	localparam WIDTH = `GET_WIDTH(MAX);
	
	reg [WIDTH-1:0] cnt;
	wire clock_ena;
	
	reg [2:0] in_reg = '0;
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			in_reg <= 1'b0;
		else if (sclr)
			in_reg <= 1'b0;
		else
			in_reg <= {in_reg[1:0], in};
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			cnt <= '0;
		else if (sclr)
			cnt <= '0;
		else if (cnt >= MAX)
			cnt <= '0;
		else
			cnt <= cnt + 1'b1;
	
	assign clock_ena = cnt == MAX;
	
	lpf_cap_full #(.FILTER_WIDTH(FILTER_WIDTH)) lpf_inst(.clock, .aclr, .sclr, .clock_ena, .in(in_reg[2] ^ level), .out, .ready, .timeout);
	
endmodule :input_filter

`endif
