timeunit 1us;
timeprecision 1ns;

module adc_permit_tb;
	bit clk = 0, aclr = 1, sclr = 1;
	bit [9:0] adc = 0;
	bit adc_err = 0;
	wire adc_valid;
	
	wire [9:0] flt_adc;
	wire flt_valid;
	
	bit soft_permit = 1, fb_ena = 1;
	bit [9:0] low = 10'h80, high = 10'h100;
	bit oi = 0;
	wire permit;
	
	always #20us clk++;
	
	initial begin
		repeat(10) @(posedge clk);
		aclr = 0;
		repeat(10) @(posedge clk);
		sclr = 0;
		repeat(10) @(posedge clk);
		
		#1ms adc = 10'h101;
		#1s adc = 10'h7F;
		
//		while (permit) begin
//			@(posedge clk);
//			oi = 1;
//			@(posedge clk);
//			oi = 0;
//		end
		
		#8s adc = 10'h101;
	end
	
	always #10s $stop(1);
	
	clock_div #(.DIV(3)) div(.clock(clk), .enable(1'b1), .clock_ena(adc_valid));
	
//	always @(posedge clk)
//		if (adc_valid)
//			adc = adc + 1;

	adc_permit dut(.*);
	
endmodule :adc_permit_tb

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
