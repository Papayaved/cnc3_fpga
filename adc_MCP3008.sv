`ifndef _adc_MCP3008_
`define _adc_MCP3008_

`include "header.sv"

// sampling SCLK_HZ / 19 / 8 = 6,579 Hz
module adc_MCP3008 #(parameter
	CLOCK_HZ = 72_000_000,
	SCLK_HZ = 1_000_000,
	ADC_NUM = 8
)(
	input clk, aclr, sclr,
	
	// SPI
	output reg sclk, csn, mosi,
	input miso,
	
//	input [5:1] ena,
	output [7:0][9:0] adc,
	output [7:0] err, sample
);
	localparam SCLK_MAX = CLOCK_HZ / SCLK_HZ - 1;
	localparam SCLK_WIDTH = `GET_WIDTH(SCLK_MAX);
	
	enum bit [2:0] { ADC0 = 3'h0, ADC1 = 3'h1, ADC2 = 3'h2, ADC3 = 3'h3, ADC4 = 3'h4, ADC5 = 3'h5, ADC6 = 3'h6, ADC7 = 3'h7 } adc_cnt = ADC0;
	reg [7:0][9:0] adc_reg = {8{10'h0}};
	reg [7:0] err_reg = '0, smp = '0;
	

	reg [SCLK_WIDTH-1:0] clk_cnt = '0;
	reg clk_rise = 1'b0, clk_fall = 1'b0;	
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			clk_cnt <= 0;
		else if (sclr || clk_cnt == SCLK_WIDTH'(SCLK_MAX))
			clk_cnt <= 0;
		else
			clk_cnt <= clk_cnt + 1'b1;
	
	always_ff @(posedge clk, posedge aclr)
		clk_rise <= aclr ? 1'b0 : ( sclr ? 1'b0 : clk_cnt == SCLK_WIDTH'((SCLK_MAX + 1) / 2 - 1) );
		
	always_ff @(posedge clk, posedge aclr)
		clk_fall <= aclr ? 1'b0 : ( sclr ? 1'b0 : clk_cnt == SCLK_WIDTH'(SCLK_MAX) );
		
	always_ff @(posedge clk, posedge aclr)
		sclk <= aclr ? 1'b0 : ( sclr ? 1'b0 : ( clk_rise ? 1'b1 : clk_fall ? 1'b0 : sclk ) );
	
	reg [9:1] data = '0;
	reg error = '0;
	
	enum {START, SINGLE, A2, A1, A0, SAMPLE, NULL0, NULL1, D9, D8, D7, D6, D5, D4, D3, D2, D1, D0, CS} state = START;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			reset();
		else if (sclr)
			reset();
		else
			case (state)
				START:
					if (clk_fall) begin
						csn <= 1'b0;
						mosi <= 1'b1;
						state <= state.next();
					end
				SINGLE:
					if (clk_fall) begin
						mosi <= 1'b1;
						state <= state.next();
					end
				A2:
					if (clk_fall) begin
						mosi <= adc_cnt[2];
						state <= state.next();
					end
				A1:
					if (clk_fall) begin
						mosi <= adc_cnt[1];
						state <= state.next();
					end
				A0:
					if (clk_fall) begin
						mosi <= adc_cnt[0];
						state <= state.next();
					end
				SAMPLE:
					if (clk_fall) begin
						mosi <= 1'b0;
						state <= state.next();
					end
				NULL0:
					if (clk_fall)
						state <= state.next();
				NULL1:
					if (clk_rise) begin
						error <= miso;
						state <= state.next();
					end
				D9:
					if (clk_rise) begin
						data[9] <= miso;
						state <= state.next();
					end
				D8:
					if (clk_rise) begin
						data[8] <= miso;
						state <= state.next();
					end
				D7:
					if (clk_rise) begin
						data[7] <= miso;
						state <= state.next();
					end
				D6:
					if (clk_rise) begin
						data[6] <= miso;
						state <= state.next();
					end
				D5:
					if (clk_rise) begin
						data[5] <= miso;
						state <= state.next();
					end
				D4:
					if (clk_rise) begin
						data[4] <= miso;
						state <= state.next();
					end
				D3:
					if (clk_rise) begin
						data[3] <= miso;
						state <= state.next();
					end
				D2:
					if (clk_rise) begin
						data[2] <= miso;
						state <= state.next();
					end
				D1:
					if (clk_rise) begin
						data[1] <= miso;
						state <= state.next();
					end
				D0:
					if (clk_rise) begin
						adc_reg[adc_cnt] <= {data, miso};
						err_reg[adc_cnt] <= error;
						smp[adc_cnt] <= 1'b1;
						state <= state.next();
					end
				CS:
					begin
						smp <= '0;
						
						if (clk_fall) begin
							csn <= 1'b1;
							adc_cnt <= adc_cnt == adc_cnt.last ? adc_cnt.first() : adc_cnt.next();
							state <= state.first();
						end
					end
			endcase
	
	assign adc[0] = adc_reg[ADC0];
	assign adc[1] = adc_reg[ADC1];
	assign adc[2] = adc_reg[ADC2];
	assign adc[3] = adc_reg[ADC3];
	assign adc[4] = adc_reg[ADC4];
	assign adc[5] = adc_reg[ADC5];
	assign adc[6] = adc_reg[ADC6];
	assign adc[7] = adc_reg[ADC7];
	
	assign err[0] = err_reg[ADC0];
	assign err[1] = err_reg[ADC1];
	assign err[2] = err_reg[ADC2];
	assign err[3] = err_reg[ADC3];
	assign err[4] = err_reg[ADC4];
	assign err[5] = err_reg[ADC5];
	assign err[6] = err_reg[ADC6];
	assign err[7] = err_reg[ADC7];
	
	assign sample[0] = smp[ADC0];
	assign sample[1] = smp[ADC1];
	assign sample[2] = smp[ADC2];
	assign sample[3] = smp[ADC3];
	assign sample[4] = smp[ADC4];
	assign sample[5] = smp[ADC5];
	assign sample[6] = smp[ADC6];
	assign sample[7] = smp[ADC7];

	task reset();
		adc_cnt <= adc_cnt.first();
		state <= state.first();
		csn <= 1'b1;
		mosi <= 1'b0;
		error <= 1'b0;
		data <= '0;
		adc_reg <= {8{10'h0}};	
		err_reg <= '0;
		smp <= '0;
	endtask
	
endmodule :adc_MCP3008


`endif
