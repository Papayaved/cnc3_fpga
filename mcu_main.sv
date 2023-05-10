`ifndef _mcu_main_
`define _mcu_main_

`include "mcu_amux_mem.sv"
`include "main.sv"
`include "my_types.sv"

module mcu_main(
	input clk, aclr,
	
	input ne, noe, nwe, nadv,
	input [1:0] nbl,
	inout [15:0] ad,
	output nirq,

	output [7:0] step, dir,
	output sd_ena, sd_oe_n,
	output [4:0] X, Y,
	output [2:0] U, V,
	
	input [7:0] enc_A, enc_B, enc_Z,
	
	output adc_sclk, adc_csn, adc_mosi,
	input adc_miso,
	
	// OUT
	output [15:0] sig_out,
	
	// HV out
	output gen_sclk, gen_sdo, gen_lock,
	input gen_sdi,
	
	// Pult out
	output pult_sclk, pult_sdo, pult_lock,
	input pult_sdi,
	
	// Limit switches
	input [7:0] sig_in,
	input power_OK, wire_break,
	
	output led,
	output oe, center_n
);

	wire [15:0] rdaddr, wraddr;
	wire [1:0] be;
	wire write;
	wire [15:0] rddata;
	wire [15:0] wrdata;

	mcu_amux_mem mux_if(
		.clk, .aclr,		
		.ne, .noe, .nwe, .nadv, .nbl, .ad,		
		.rdaddr, .wraddr, .be, .write, .rddata, .wrdata
	);
	
	main main_inst(
		.clk, .aclr,
		.rdaddr, .wraddr, .be, .write, .wrdata, .rddata, .nirq,
		.step, .dir, .sd_ena, .sd_oe_n, .X, .Y, .U, .V,
		.enc_A, .enc_B, .enc_Z,
		.adc_sclk, .adc_csn, .adc_mosi, .adc_miso,
		.sig_out,
		.gen_sclk, .gen_sdo, .gen_lock, .gen_sdi,	
		.pult_sclk, .pult_sdo, .pult_lock, .pult_sdi,
		.sig_in, .power_OK, .wire_break,
		.led,
		.oe, .center_n
	);

endmodule :mcu_main

`endif
