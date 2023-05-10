`ifndef _piso_
`define _piso_

`include "header.sv"
`include "clk_div.sv"

module piso_reg #(parameter
	WIDTH = 16,
	CLK_DIV = 10
)(
	input clk, aclr, sclr, cancel,
	input [WIDTH-1:0] data,
	input we,
	output busy,
	output reg wrreq,
	output [WIDTH-1:0] shift,
	output sclk, sdo, lock,
	input sdi	
);
	wire load;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			wrreq <= 1'b1;
		else if (sclr)
			wrreq <= 1'b1;
		else if (we)
			wrreq <= 1'b1;
		else if (cancel)
			wrreq <= 1'b0;
		else if (load)
			wrreq <= 1'b0;
	
	piso #(.WIDTH(WIDTH), .CLK_DIV(CLK_DIV)) piso_inst(
		.clk, .aclr, .sclr,
		.data,
		.wrreq(wrreq && !cancel && !we),
		.busy, .load, .shift,
		.sclk, .sdo, .lock, .sdi
	);
	
endmodule :piso_reg

module piso_always #(parameter
	WIDTH = 16,
	CLK_DIV = 10
)(
	input clk, aclr, sclr,
	input [WIDTH-1:0] data,
	output [WIDTH-1:0] data_old,
	output sclk, sdo, lock,
	input sdi	
);
	
	wire busy, load;
	
	piso #(.WIDTH(WIDTH), .CLK_DIV(CLK_DIV)) piso_inst(
		.clk, .aclr, .sclr,
		.data,
		.wrreq(1'b1),
		.busy, .load, .shift(data_old),
		.sclk, .sdo, .lock, .sdi
	);
	
endmodule :piso_always

// todo: cancel
// 74AHC595
module piso #(parameter
	WIDTH = 16,
	CLK_DIV = 10
)(
	input clk, aclr, sclr,
	input [WIDTH-1:0] data,
	input wrreq,
	output busy,	
	output load,
	output reg [WIDTH-1:0] shift,
	output reg sclk,
	output sdo,
	output reg lock,
	input sdi
);
	localparam CNT_WIDTH = `GET_WIDTH(WIDTH);
	localparam bit [CNT_WIDTH-1:0] CNT_MAX = CNT_WIDTH'(WIDTH - 1'b1);
	
	reg sclk_clr = 1'b1;
	wire sclk_ena;
	
	reg sdi_reg = 1'b0;
	
	clk_div #(.CLK_DIV(CLK_DIV/2)) clk_div_inst(.clk, .aclr, .sclr(sclk_clr), .clk_ena(sclk_ena));
	
	reg l_sclk = 1'b0;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			l_sclk <= 1'b0;
		else if (sclk_clr)
			l_sclk <= 1'b0;
		else if (sclk_ena)
			l_sclk <= !l_sclk;
	
	wire sclk_fall = sclk_ena && l_sclk;
	
	reg [CNT_WIDTH-1:0] bit_cnt = '0;
	
	enum {IDLE, SEND, LOCK} state = IDLE;
	
	task reset();
		shift <= '0;
		sdi_reg <= 1'b0;
		bit_cnt <= '0;
		sclk_clr <= 1'b1;
		state <= IDLE;
	endtask :reset
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			reset();
		else if (sclr)
			reset();
		else
			case (state)
				IDLE:
					if (wrreq)
						begin
							shift <= data;
							sdi_reg <= sdi;
							bit_cnt <= '0;
							sclk_clr <= 1'b0;
							state <= SEND;
						end
				SEND:
					if (sclk_fall) begin
						shift <= {shift[WIDTH-2:0], sdi_reg};
						sdi_reg <= sdi;
						bit_cnt <= bit_cnt + 1'b1;
						if (bit_cnt >= CNT_MAX)
							state <= LOCK;
					end
				LOCK:
					if (sclk_fall) begin
						sclk_clr <= 1'b1;
						state <= IDLE;
					end
			endcase
	
	assign load = state == IDLE && wrreq;
			
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			sclk <= 1'b0;
		else if (sclr)
			sclk <= 1'b0;
		else if (state == SEND)
			begin
				if (sclk_ena)
					sclk <= !sclk;
			end
		else
			sclk <= 1'b0;
			
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			lock <= 1'b0;
		else if (sclr)
			lock <= 1'b0;
		else if (state == LOCK)
			begin
				if (sclk_ena)
					lock <= !sclk;
			end
		else
			lock <= 1'b0;
	
	assign busy = state != IDLE;
	
	assign sdo = shift[WIDTH-1];
	
endmodule :piso

`endif
