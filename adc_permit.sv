`ifndef _adc_permit_
`define _adc_permit_

`include "header.sv"
`include "cic_decim_osr.sv"
`include "accum.sv"

module adc_permit #(parameter
	ADC_WIDTH = 10
)(
	input clk, aclr, sclr,
	// 6,579 Hz
	input [ADC_WIDTH-1:0] adc,
	input adc_err, adc_valid,
	
	output [ADC_WIDTH-1:0] flt_adc,
	output flt_valid,
	
	input soft_permit, fb_ena,
	input [ADC_WIDTH-1:0] low, high, // low < high
	
	input oi,
	
	output reg permit,

	input [ADC_WIDTH-1:0] cthld,
	input center,
	input [1:0] cmode,
	output reg cstop
);
	
	// 128 - ~51 Hz; 32 - 205 Hz
	cic_decim_osr #(.DATA_WIDTH(ADC_WIDTH), .OSR_WIDTH(5)) cic(
		.aclr, .sclr, .clock(clk),
		.data(adc), .clock_ena(adc_valid),
		.osr({5{1'b1}}),
		.res(flt_adc), .valid(flt_valid)
	);
	
	//
	wire l_fb_ena = fb_ena && !center;
	
	reg fb_ena_reg;
	always_ff @(posedge clk, posedge aclr)
		fb_ena_reg <= aclr ? 1'b0 : l_fb_ena;
	
	reg oi_reg;
	always_ff @(posedge clk, posedge aclr)
		oi_reg <= aclr ? 1'b0 : ( sclr ? 1'b0 : oi );
	
	wire less = flt_adc < low;
	
	wire [8:0] steps_cnt;
	
	accum_var #(.DATA_WIDTH(1), .ACC_POW(8), .RES_WIDTH(9)) shc_step(
		.aclr, .clock(clk), .sclr(!permit),
		.delay(8'd255), // 255 oi
		.data_in(less), .valid_in(oi && !oi_reg),
		.data_out(steps_cnt), .valid_out()
	);
	
	wire [10:0] time_cnt;
//	wire time_cnt_valid;
	
	accum_var #(.DATA_WIDTH(1), .ACC_POW(10), .RES_WIDTH(11)) shc_time(
		.aclr, .clock(clk), .sclr(!permit),
		.delay(10'd1023), // 255 adc samples ~ 1.3 sec * 4
		.data_in(less), .valid_in(flt_valid),
		.data_out(time_cnt), .valid_out()
	);
	
	// 127 steps or 1.2 sec
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			permit <= 1'b0;
		else if (sclr || !soft_permit || (l_fb_ena && !fb_ena_reg))
			permit <= 1'b0;
		else if (!l_fb_ena)
			permit <= 1'b1;
//		else if (adc_err)
//			permit <= 1'b0;
		else if (permit && (steps_cnt > 9'd127 || time_cnt > 11'd511)) // same as +-counter
			permit <= 1'b0;
		else if (!permit && flt_adc >= high)
			permit <= 1'b1;
			
	// Centring
	reg [1:0] cmode_reg;
	reg center_reg;
	
	always_ff @(posedge clk, posedge aclr) begin
		cmode_reg	<= aclr ? '0 : cmode;
		center_reg	<= aclr ? 1'b0 : center;
	end
	
	wire mode_changed = cmode != cmode_reg || center != center_reg;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			cstop <= 1'b0;
		else if (sclr)
			cstop <= 1'b0;
		else if (mode_changed)
			cstop <= 1'b1;
		else if (!center)
			cstop <= 1'b0;
		else if (cmode == 2'b01) // forward
			begin
				if (adc <= cthld)
					cstop <= 1'b1;
				else
					cstop <= 1'b0;
			end
		else if (cmode == 2'b10) // reverse
			begin
				if (adc >= cthld)
					cstop <= 1'b1;
				else
					cstop <= 1'b0;
			end
		else
			cstop <= 1'b0;
	
endmodule :adc_permit

`endif // _adc_permit_
