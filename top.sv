`ifndef _top_
`define _top_

`include "mcu_main.sv"
`include "header.sv"
`include "my_types.sv"

module top(
	input gen24,

	// MCU bus
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"", useioff = 1 *)
	input ne, noe, nwe, nadv,
	
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"", useioff = 1 *)
	inout [15:0] ad,
	
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"", useioff = 1 *)
	input [1:0] nbl,
	
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"" *)
	output nirq,
	
	// Motors
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"", useioff = 1 *)
	output [4:0] X, Y,
	
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"", useioff = 1 *)
	output [2:0] U, V,
	
	// Line sensor
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"", useioff = 1 *)
	input [2:0] enc_A, enc_B, enc_Z,
	
	// HV ADC
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\""*)
	output adc_sclk, adc_csn, adc_mosi,
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"", useioff = 1 *)
	input adc_miso,
	
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\""*)
	output ind_sclk, ind_sdo, ind_load,
	
	//
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"", useioff = 1 *)
	input wire_break, OK220, // limsw_stop, limsw_fwd, limsw_rev,
	
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"", useioff = 1 *)
	input [7:0] sig_in,
	
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"" *)
	output hv_ena, hv_lvl, pump_ena, estop, drum_fwd, drum_rev, oe, center_n,
	
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"" *)
	output [2:0] drum_vel,
	
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"" *)
	output step, dir, sd_ena, sd_oe_n,
	
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"" *)
	output [5:0] current,
	
	// SPI
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"", useioff = 1 *)	
	output gen_sclk, gen_load, gen_sdo,
	
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\"" *)
	output led_n,
	
	(* altera_attribute = "-name IO_STANDARD \"3.3-V LVTTL\""*)
	output [2:0] res
);
	
	assign res = 3'h0;
	
	
	wire pll_locked, aclr, clk;
	
	reg areset = 1'b1;
	always_ff @(posedge gen24)
		areset <= 1'b0;
	
	main_pll	pll_inst(.areset(areset), .inclk0(gen24), .c0(clk), .locked(pll_locked));
	
	assign aclr = !pll_locked;
	
	wire led;
	assign led_n = !led;
	
	wire [7:0] l_step, l_dir;
	wire [15:0] sig_out;
	wire _adc_sclk, _adc_csn, _adc_mosi;
	
	mcu_main mcu_inst(
		.clk, .aclr,
		.ne, .noe, .nwe, .nadv, .nbl, .ad, .nirq,
		.step(l_step), .dir(l_dir), .sd_ena, .sd_oe_n,
		.X, .Y, .U, .V,
		.enc_A({{5{1'b1}}, enc_A}),
		.enc_B({{5{1'b1}}, enc_B}),
		.enc_Z({{5{1'b1}}, enc_Z }),
		.adc_sclk(_adc_sclk), .adc_csn(_adc_csn), .adc_mosi(_adc_mosi), .adc_miso(!adc_miso),

		.sig_out,
		.gen_sclk, .gen_sdo, .gen_lock(gen_load), .gen_sdi(1'b0),
		.pult_sclk(ind_sclk), .pult_sdo(ind_sdo), .pult_lock(ind_load), .pult_sdi(1'b0),
		.power_OK(OK220), .wire_break, .sig_in,

		.led(),
		.oe, .center_n
	);
	
	assign adc_sclk	= !_adc_sclk;
	assign adc_csn		= !_adc_csn;
	assign adc_mosi	= !_adc_mosi;
	
	led_flash led_inst(.clk, .aclr, .led);
//	led_flash #(.SYS_CLOCK(24_000_000)) led_inst(.clk(gen24), .aclr(1'b0), .led);
	
	assign hv_ena = sig_out[0]; // relay
	assign hv_lvl = sig_out[1]; // relay
	assign current = sig_out[7:2];
	
	assign drum_fwd = sig_out[8]; // relay
	assign drum_rev = sig_out[9]; // relay
	assign drum_vel = sig_out[12:10]; // relay
	
	assign pump_ena = sig_out[13]; // relay
	assign estop = 1'b0; // relay
	
	assign step = l_step[4];
	assign dir = l_dir[4];
	
endmodule :top

module led_flash #(parameter
	SYS_CLOCK = 72_000_000
)(
	input clk, aclr,
	output led
);
	localparam MAX = SYS_CLOCK / 2 - 1;
	localparam WIDTH = `GET_WIDTH(MAX);
	
	reg [WIDTH-1:0] cnt;
	wire max;
	reg led_reg = 1'b0;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			cnt <= '0;
		else if (max)
			cnt <= '0;
		else
			cnt <= cnt + 1'b1;
			
	assign max = cnt >= MAX;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			led_reg <= 1'b0;
		else if (max)
			led_reg <= !led_reg;
	
	assign led = led_reg;
	
endmodule :led_flash

`endif
