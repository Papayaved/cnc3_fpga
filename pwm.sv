`ifndef _pwm_
`define _pwm_

module pwm #(
	parameter WIDTH = 32
)(
	input clk, aclr, sclr,
	input [WIDTH-1:0] per,
	input [1:0][WIDTH-1:0] t,
	input inv,
	output load,
	output q
);
	reg [WIDTH-1:0] cnt = '0;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			cnt <= '0;
		else if (sclr || load)
			cnt <= '0;
		else
			cnt <= cnt + 1'b1;
	
	reg s = 1'b0;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			s <= 1'b0;
		else if (sclr)
			s <= 1'b0;
		else
			s <= cnt >= t[0] && cnt < t[1];
			
	assign q = inv ? !s : s;
	
	assign load = cnt >= per;
	
endmodule :pwm

`endif
