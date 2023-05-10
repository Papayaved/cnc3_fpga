timeunit 1ns;
timeprecision 1ps;

module cic_decim_osr_tb;
	localparam DATA_WIDTH = 10;
	localparam OSR_WIDTH = 7; // 2**OSR_WIDTH - over sampling ratio	
	localparam RES_WIDTH = DATA_WIDTH;
	localparam WIDTH = 3 * OSR_WIDTH + DATA_WIDTH;

	bit aclr = 1, sclr = 1;
	bit clock = 0;
	wire clock_ena;
	bit [DATA_WIDTH-1:0] data = 0;
	
	localparam OSR = 127;
	bit [OSR_WIDTH-1:0] osr = OSR; // OSR minus 1
	wire [RES_WIDTH-1:0] res;
	wire valid;

	always #50ns clock++;
	
	clock_div #(.DIV(3)) clk_div(.clock, .enable(1'b1), .clock_ena);
	
	initial begin
		repeat(10) @(posedge clock);
		aclr = 0;
		repeat(10) @(posedge clock);
		sclr = 0;
		repeat(10) @(posedge clock);
		
	end
	
	always #(128*1*(2**10)*2*4*100ns) $stop(2);

	//
	wire adc_valid;
	clock_div #(.DIV((OSR + 1)*1 - 1)) adc_div(.clock, .enable(clock_ena), .clock_ena(adc_valid));
	
	always_ff @(posedge clock)
//		data <= '1;
		if (clock_ena && adc_valid)
			data <= data + 1;
			
	cic_decim_osr dut(.*);

endmodule :cic_decim_osr_tb

module clock_div #(parameter DIV)(input clock, input enable, output clock_ena);
	int clk_cnt = 0;
	
	always_ff @(posedge clock)
		if (enable)
			if (clock_ena)
				clk_cnt = 0;
			else
				clk_cnt = clk_cnt + 1;
	
	assign clock_ena = clk_cnt == DIV;
endmodule :clock_div
