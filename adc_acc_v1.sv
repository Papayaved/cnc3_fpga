`ifndef _adc_acc_
`define _adc_acc_

`include "header.sv"
`include "adc_MCP3008.sv"
`include "accum.sv"


module adc_acc #(parameter
	CLOCK_HZ = 72_000_000,
	SCLK_HZ = 1_000_000,
	ADC_WIDTH = 10
)(
	input clk, aclr, sclr,
	
	// SPI
	output sclk, csn, mosi,
	input miso,
	
	output [7:0][ADC_WIDTH-1:0] adc,
	output [7:0] err,
	
	input soft_permit, fb_ena,
	input [ADC_WIDTH-1:0] low, high, // low < high
	input [11:0] shc_delay,
	output [12:0] shc_cnt,
	output reg permit
);

	wire [7:0][ADC_WIDTH-1:0] chip_adc;
	wire [7:0] chip_err, sample;
	
	// 6,579 Hz
	adc_MCP3008 #(.CLOCK_HZ(CLOCK_HZ), .SCLK_HZ(SCLK_HZ)) adc_inst(
		.clk, .aclr, .sclr,
		.sclk, .csn, .mosi, .miso,
		.adc(chip_adc), .err, .sample
	);

	wire [ADC_WIDTH-1:0] acc_adc;
	wire acc_valid;
	
	// ~51 Hz
	accum #(.DATA_WIDTH(ADC_WIDTH), .RES_WIDTH(ADC_WIDTH), .ACC_POW(7)) acc_inst(
		.aclr, .clock(clk), .sclr,
		.data_in(chip_adc[0]), .valid_in(sample[0]),
		.data_out(acc_adc), .valid_out(acc_valid)
	);
	
	assign adc[0] = acc_adc;
	assign adc[1] = chip_adc[1];
	assign adc[2] = chip_adc[2];
	assign adc[3] = chip_adc[3];
	assign adc[4] = chip_adc[4];
	assign adc[5] = chip_adc[5];
	assign adc[6] = chip_adc[6];
	assign adc[7] = chip_adc[7];
	
	reg fb_ena_reg;
	always_ff @(posedge clk, posedge aclr)
		fb_ena_reg <= aclr ? 1'b0 : fb_ena;
	
	//
	wire less = adc[0] < low;
	
	// 1.6 Hz
	accum_var #(.DATA_WIDTH(1), .ACC_POW(12), .RES_WIDTH(13)) shortcuts(
		.aclr, .clock(clk), .sclr(!permit),
		.delay(shc_delay),
		.data_in(less), .valid_in(acc_valid),
		.data_out(shc_cnt), .valid_out()
	);
	
	// 0.8 Hz
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			permit <= 1'b0;
		else if (sclr || !soft_permit || (fb_ena && !fb_ena_reg))
			permit <= 1'b0;
		else if (!fb_ena)
			permit <= 1'b1;
		else if (err[0])
			permit <= 1'b0;
		else if (permit && shc_cnt > shc_delay[11:1])
			permit <= 1'b0;
		else if (!permit && adc[0] >= high)
			permit <= 1'b1;
		
endmodule :adc_acc

`endif // _adc_acc_
