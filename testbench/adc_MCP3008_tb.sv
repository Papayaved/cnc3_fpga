timeunit 1ns;
timeprecision 1ps;

`include "MCP3008.sv"

module adc_MCP3008_tb;
	localparam ADC_NUM = 8;
	
	bit clk = 0, aclr = 1, sclr = 1;

	wire sclk, csn, mosi;
	wire miso;
	
	wire [ADC_NUM-1:0][9:0] adc;
	wire [ADC_NUM-1:0] err;
	
	bit [7:0][9:0] data = '0;
	
	always #6.944ns clk++;
	
	initial begin
		repeat(10) @(posedge clk);		
		aclr = 0;
		sclr = 0;
		repeat(10) @(posedge clk);
		
		data[0] = 10'h2AA;
		data[1] = 2;
		data[2] = 3;
		data[3] = 4;
		data[4] = 5;
		data[5] = 6;
		data[6] = 7;
		data[7] = 10'h155;
		
	end
	
	always #200us $stop(2);
	
	MCP3008 adc_inst(.*);
	
	adc_MCP3008 dut(.*);

endmodule :adc_MCP3008_tb
