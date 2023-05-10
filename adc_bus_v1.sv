`ifndef _adc_bus_
`define _adc_bus_

`include "adc_acc.sv"

module adc_bus #(parameter
	BAR = 'h0,
	MASK = 'h1F,
	ADC_WIDTH = 10
)(
	input clk, aclr, sclr,
	input [15:0] rdaddr, wraddr,
	input [1:0] be,
	input write,
	input [15:0] wrdata,
	output reg [15:0] rddata,	
	
	//
	output cut_permit,
	
	// ADC
	output sclk, csn, mosi,
	input miso
);
	wire rdhit = (rdaddr & ~MASK) == BAR;
	wire wrhit = (wraddr & ~MASK) == BAR;
	
	wire [15:0] l_rdaddr = rdaddr & MASK[15:0];
	wire [15:0] l_wraddr = wraddr & MASK[15:0];

	wire [7:0][ADC_WIDTH-1:0] adc;
	wire [7:0] err;
	reg [7:0][ADC_WIDTH-1:0] adc_snap;
	reg [7:0] err_snap = '0;
	
	reg [ADC_WIDTH-1:0] low_thld, high_thld;
	reg [11:0] shc_delay;
	wire [12:0] shc_cnt;
	reg fb_ena, soft_permit;
	
	task reset();
		low_thld <= '0;
		high_thld <= '1;
		fb_ena <= 1'b0;
		soft_permit <= 1'b1;
		shc_delay <= '1;
	endtask
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			reset();
		else if (sclr)
			reset();
		else if (write && wrhit)
			case (l_wraddr)
				'h10: begin
							if (be[0]) low_thld[7:0] <= wrdata[7:0];
							if (be[1]) low_thld[ADC_WIDTH-1:8] <= wrdata[ADC_WIDTH-1:8];
						end
				'h12: begin
							if (be[0]) high_thld[7:0] <= wrdata[7:0];
							if (be[1]) high_thld[ADC_WIDTH-1:8] <= wrdata[ADC_WIDTH-1:8];
						end
				'h14: begin
							if (be[0]) fb_ena <= wrdata[0];
						end
				'h16: begin
							if (be[0]) soft_permit <= wrdata[0];
						end
				'h1A: begin
							if (be[0]) shc_delay <= wrdata[7:0];
							if (be[1]) shc_delay <= wrdata[11:8];
						end
			endcase

	wire snapshot = write && wrhit && l_wraddr == 'h0 && be[0] && wrdata[0];
			
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			rddata <= '0;
		else if (sclr)
			rddata <= '0;
		else if (rdhit)
			case (l_rdaddr)
				'h0: rddata <= {5'h0, err_snap[0], adc_snap[0]};
				'h2: rddata <= {5'h0, err_snap[1], adc_snap[1]};
				'h4: rddata <= {5'h0, err_snap[2], adc_snap[2]};
				'h6: rddata <= {5'h0, err_snap[3], adc_snap[3]};
				'h8: rddata <= {5'h0, err_snap[4], adc_snap[4]};
				'hA: rddata <= {5'h0, err_snap[5], adc_snap[5]};
				'hC: rddata <= {5'h0, err_snap[6], adc_snap[6]};
				'hE: rddata <= {5'h0, err_snap[7], adc_snap[7]};
				'h10: rddata <= 16'(low_thld);
				'h12: rddata <= 16'(high_thld);
				'h14: rddata <= {15'h0, fb_ena};
				'h16: rddata <= {15'h0, soft_permit};				
				'h18: rddata <= {15'h0, cut_permit};
				'h1A: rddata <= {4'h0, shc_delay};
				'h1C: rddata <= {3'h0, shc_cnt};
				
				default: rddata <= '0;
			endcase
		else
			rddata <= '0;
			
	adc_acc #(.ADC_WIDTH(ADC_WIDTH)) adc_inst(
		.clk, .aclr, .sclr,
		.sclk, .csn, .mosi, .miso,
		.adc, .err,
		
		.soft_permit, .fb_ena,
		.low(low_thld), .high(high_thld),
		.shc_delay,
		.shc_cnt,
		.permit(cut_permit)
	);
		
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			adc_reset();
		else if (sclr)
			adc_reset();
		else if (snapshot)
			begin
				adc_snap <= adc;
				err_snap <= err;
			end
			
	task adc_reset();
		adc_snap[0] <= 10'h111;
		adc_snap[1] <= 10'h222;
		adc_snap[2] <= 10'h333;
		adc_snap[3] <= 10'h044;
		adc_snap[4] <= 10'h155;
		adc_snap[5] <= 10'h266;
		adc_snap[6] <= 10'h377;
		adc_snap[7] <= 10'h088;
		err_snap <= '0;
	endtask
	
endmodule :adc_bus

`endif
