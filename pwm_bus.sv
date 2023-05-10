`ifndef _pwm_bus_
`define _pwm_bus_
`include "pwm.sv"

module pwm_bus#(
	parameter BAR = 'h0,
	parameter MASK = 'hF
)(
	input clk, aclr, sclr,
	input [15:0] addr,
	input [1:0] be,
	input write,
	input [15:0] wrdata,
	output [15:0] rddata,
	
	input ls,
	output hv_pwm,
	output reg [3:0] hv_code,
	output reg hv_update
);

	reg [31:0] per = '0;
	reg [1:0][31:0] t = '0;
	reg ena = 1'b0, inv = 1'b0;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			begin
				per <= '0;
				t <= '0;
				inv = 1'b0;
			end
		else if (sclr)
			begin
				per <= '0;
				t <= '0;
				inv = 1'b0;
			end
		else if (write && (addr & ~MASK) == BAR)
			case (addr & MASK)
				'h0:	begin
							if (be[0]) per[7:0] = wrdata[7:0];
							if (be[1]) per[15:8] = wrdata[15:8];
						end
				'h2:	begin
							if (be[0]) per[23:16] = wrdata[7:0];
							if (be[1]) per[31:24] = wrdata[15:8];
						end
				'h4:	begin
							if (be[0]) t[0][7:0] = wrdata[7:0];
							if (be[1]) t[0][15:8] = wrdata[15:8];
						end
				'h6:	begin
							if (be[0]) t[0][23:16] = wrdata[7:0];
							if (be[1]) t[0][31:24] = wrdata[15:8];
						end
				'h8:	begin
							if (be[0]) t[1][7:0] = wrdata[7:0];
							if (be[1]) t[1][15:8] = wrdata[15:8];
						end
				'hA:	begin
							if (be[0]) t[1][23:16] = wrdata[7:0];
							if (be[1]) t[1][31:24] = wrdata[15:8];
						end
				'hC:
						begin
							if (be[1]) inv = wrdata[9];
						end
			endcase
	
	wire change_state = write && (addr & ~MASK) == BAR && (addr & MASK) == 'hC;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			hv_code <= '0;
		else if (sclr || ls)
			hv_code <= '0;
		else if (change_state && be[0])
			hv_code <= wrdata[3:0];
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			ena <= 1'b0;
		else if (sclr || ls)
			ena <= 1'b0;
		else if (change_state && be[1])
			ena <= wrdata[8];
	
	always_ff @(posedge clk)
		if ((addr & ~MASK) == BAR)
			case (addr & MASK)
				'h0: rddata <= per[15:0];
				'h2: rddata <= per[31:16];
				'h4: rddata <= t[0][15:0];
				'h6: rddata <= t[0][31:16];
				'h8: rddata <= t[1][15:0];
				'hA: rddata <= t[1][31:16];
				'hC: rddata <= {6'h0, inv, ena, 4'h0, hv_code};
				default: rddata <= '0;
			endcase
		else
			rddata <= '0;

	pwm #(32) pwm_inst(.clk, .aclr, .sclr(!ena || sclr || !ena), .per, .t, .inv, .q(hv_pwm));
	
	reg ls_reg = 1'b0;
	
	always_ff @(posedge clk)
		ls_reg <= aclr ? 1'b0 : ls;
	
	always_ff @(posedge clk, posedge aclr)
		hv_update <= aclr ? 1'b1 : sclr || change_state || (ls ^ ls_reg);
			

endmodule :pwm_bus

`endif
