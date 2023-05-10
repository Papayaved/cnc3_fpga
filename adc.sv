`ifndef _adc_
`define _adc_

`include "header.sv"
`include "u_sinc3_decim.sv"
`include "adc_adj.sv"
`include "fifo2.sv"

module adc #(parameter
	ADC_NUM = 16,
	OSR_WIDTH = 16,
	SHIFT_WIDTH = 5,
	SCALE_WIDTH = 32,
	ADC_WIDTH = 3 * OSR_WIDTH,
	OFFSET_WIDTH = SCALE_WIDTH - 2,	
	ADC_NUM_WIDTH = `GET_WIDTH(ADC_NUM)
)(
	input aclr,
	
	input adc_clk,
	input [ADC_NUM-1:0] adc_sdi,
	
	input clk, sclr,
	input [ADC_NUM-1:0] adc_sync,
	
	input [ADC_NUM-1:0][OSR_WIDTH-1:0] osr,	
	
	output [ADC_NUM_WIDTH-1:0] addr,
	input [SHIFT_WIDTH-1:0] shift_q,
	input [SCALE_WIDTH-1:0] scale_q,
	input signed [OFFSET_WIDTH-1:0] offset_q,
	
	output [ADC_NUM-1:0] empty,
	input [ADC_NUM-1:0] sample_clk,
	output [ADC_NUM-1:0][31:0] q,
	
	output scale_err
);
//	reg [ADC_NUM-1:0][OSR_WIDTH-1:0] osr_reg;
	
//	always_ff @(posedge adc_clk)
//		osr_reg <= osr;
	
	reg l_aclr = 1'b1;
	always_ff @(posedge clk, posedge aclr)
		l_aclr <= (aclr) ? 1'b1 : sclr;
		
	wire [ADC_NUM-1:0][ADC_WIDTH-1:0] adc;
	wire [ADC_NUM-1:0] adc_valid;
	
	genvar i;
	
	generate for (i = 0; i < ADC_NUM; i++)
		begin :gen_adc
			reg sync_req = 1'b1;
			reg [2:0] sync_ack = '0;
	
			always_ff @(posedge clk, posedge aclr)
				if (aclr)
					sync_req <= 1'b1;
				else if (sclr || adc_sync[i])
					sync_req <= 1'b1;
				else if (sync_ack[2])
					sync_req <= 1'b0;		
		
			always_ff @(posedge adc_clk)
				sync_ack <= {sync_ack[1:0], sync_req};
		
			u_sinc3_decim #(.OSR_WIDTH(OSR_WIDTH)) decim_inst(
				.sclr(sync_req), .clock(adc_clk), .sdi(adc_sdi[i]), .osr(osr[i]), .data(adc[i]), .valid(adc_valid[i])
			);
		end
	endgenerate
	
	wire signed [31:0] result;
	wire [ADC_NUM-1:0] result_valid;
	
	adc_adj #(.ADC_NUM(ADC_NUM), .ADC_WIDTH(ADC_WIDTH), .SHIFT_WIDTH(SHIFT_WIDTH), .SCALE_WIDTH(SCALE_WIDTH)) adj_inst(
		.aclr(l_aclr), .clock(adc_clk),
		.adc, .adc_valid,
		
		.addr, .shift_q, .scale_q, .offset_q,
		
		.result, .result_valid,
		
		.scale_err
	);
	
	genvar j;
	
	generate for (j = 0; j < ADC_NUM; j++)
		begin :gen_fifo
			fifo2 #(.DATA_WIDTH(32)) fifo2_inst(
				.aclr(l_aclr),
				.adc_clk(adc_clk), .adc_wrreq(result_valid[j]), .adc(result),
				.clk, .rdreq(sample_clk[j]), .q(q[j]), .empty(empty[j])
			);
		end
	endgenerate
	
endmodule :adc

`endif
