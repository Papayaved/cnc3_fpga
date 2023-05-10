`ifndef _pwm_bus_
`define _pwm_bus_
`include "pwm.sv"

module pwm_bus(
	input clk, aclr, sclr,
	input [3:0] addr,
	input [1:0] be,
	input write,
	input [15:0] wrdata,
	output [15:0] rddata,
	output q
);

	reg [31:0] per = '0;
	reg [1:0][31:0] t = '0;
	reg ena = 1'b0, inv = 1'b0;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			begin
				per <= '0;
				t <= '0;
				ena = 1'b0;
				inv = 1'b0;
			end
		else
			case (addr)
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
					if (be[0]) begin
						ena = wrdata[0];
						inv = wrdata[1];
					end
			endcase
	
	always_comb begin
		rddata = '0;
		
		case (addr)
			'h0: rddata = per[15:0];
			'h2: rddata = per[31:16];
			'h4: rddata = t[0][15:0];
			'h6: rddata = t[0][31:16];
			'h8: rddata = t[1][15:0];
			'hA: rddata = t[1][31:16];
			'hC: rddata = '{inv, ena};
			default: rddata = '0;
		endcase
	end

	pwm #(32) pwm_inst(.clk, .aclr, .sclr(!ena || sclr), .per, .t, .inv, .q);

endmodule :pwm_bus

`endif
