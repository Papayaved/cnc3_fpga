`ifndef _hv_pwm_
`define _hv_pwm_

module hv_pwm #(parameter
	WIDTH = 32,
	NUM = 8
)(
	input clk, aclr,
	input [WIDTH-1:0] cnt_max, width,
	input [NUM-1:0] hv_ena,
	input wrreq,
	output pwm, hv_sclk, hv_sdo, hv_lock
);
	reg [WIDTH-1:0] cnt_max_reg = '1, width_reg = '0;
	reg [NUM-1:0] hv_ena_reg = '0;

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			begin
				cnt_max_reg <= '1;
				width_reg <= '0;
				hv_ena_reg <= 1'b0;
			end
		else if (wrreq)
			begin
				cnt_max_reg <= cnt_max;
				width_reg <= width;
				hv_ena_reg <= hv_ena;
			end

	pwm #(.WIDTH(WIDTH)) pwm_inst(
		.clk, .aclr,
		.cnt_max(cnt_max_reg), .width(width_reg),
		.pwm
	);

	piso_reg #(.WIDTH(NUM), .CLK_DIV(10)) piso_inst(
		.clk, .aclr,
		.data(hv_ena_reg),
		.wrreq(slow_wrreq),
		.sclk(slow_out_sclk), .sdo(slow_out_sdo), .lock(slow_out_lock)
	);
	
endmodule :hv_pwm

module pwm #(parameter
	WIDTH = 32
)(
	input clk, aclr,
	input [WIDTH-1:0] cnt_max, width,
	output reg pwm
);
	reg [WIDTH-1:0] cnt = '0;

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			cnt <= '0;
		else if (cnt == cnt_max)
			cnt <= '0;
		else
			cnt <= cnt + 1'b1;
	
	always_ff @(posedge clk, posedge aclr)
		pwm <= aclr ? 1'b0 : cnt < width;
	
endmodule :pwm

`endif
