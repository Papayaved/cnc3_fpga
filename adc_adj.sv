`ifndef _adc_adj_
`define _adc_adj_

`include "header.sv"
`include "limit.sv"
`include "round.sv"

module adc_adj #(parameter
	ADC_NUM = 16,
	ADC_WIDTH = 3 * 16,
	SHIFT_WIDTH = 5,
	SCALE_WIDTH = 32,
	OFFSET_WIDTH = SCALE_WIDTH - 2,
	ADC_NUM_WIDTH = `GET_WIDTH(ADC_NUM)
)(
	input aclr, clock,
	input [ADC_NUM-1:0][ADC_WIDTH-1:0] adc,
	input [ADC_NUM-1:0] adc_valid,
	
	output [ADC_NUM_WIDTH-1:0] addr,
	input [SHIFT_WIDTH-1:0] shift_q,
	input [SCALE_WIDTH-1:0] scale_q,
	input signed [OFFSET_WIDTH-1:0] offset_q,
	
	output signed [31:0] result,
	output [ADC_NUM-1:0] result_valid,
	
	output reg scale_err
);

	// latch adc
	reg [ADC_NUM-1:0][ADC_WIDTH-1:0] adc_reg;
	reg [ADC_NUM-1:0] req = '0, ack = '0;
	reg [ADC_NUM-1:0][2:0] ack_reg = '0;

	reg [ADC_NUM_WIDTH-1:0] k = '0;
	assign addr = k;	
	
	genvar i;
	
	generate
		for (i = 0; i < ADC_NUM; i++)
			begin :gen
				always @(posedge clock)
					if (adc_valid[i])
						adc_reg[i] <= adc[i];
			
				always_ff @(posedge clock, posedge aclr)
					if (aclr)
						req[i] <= '0;
					else if (ack[i])
						req[i] <= 1'b0;
					else if (adc_valid[i])
						req[i] <= 1'b1;
						
				always_ff @(posedge clock, posedge aclr)
					if (aclr)
						ack[i] <= 1'b0;
					else
						ack[i] <= k == i && req[k];
					
				always_ff @(posedge clock, posedge aclr)
					if (aclr)
						ack_reg[i] <= '0;
					else
						ack_reg[i] <= {ack_reg[i][1:0], ack[i]};
					
				assign result_valid[i] = ack_reg[i][2];
				
			end
	endgenerate
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			k <= '0;
		else if (k == ADC_NUM - 1 || req == '0)
			k <= '0;
		else
			k <= k + 1'b1;
	
	localparam bit [SCALE_WIDTH-1:0] SCALE_MAX = {1'b1, {(SCALE_WIDTH-1){1'b0}}};
	localparam ADC_SCALE_WIDTH			= 32 + SCALE_WIDTH;
	localparam ADC_SCALE_CUT_WIDTH	= ADC_SCALE_WIDTH - (SCALE_WIDTH - 1);
	localparam ADC_OFFSET_WIDTH		= ADC_SCALE_CUT_WIDTH + 1;	
	
	reg [ADC_WIDTH-1:0] data;
	reg [SCALE_WIDTH-1:0] scale;
	reg [1:0][OFFSET_WIDTH-1:0] offset;
	
	reg [ADC_WIDTH-1:0] adc_shift;
	wire [31:0] adc_shift_lim;
	
	reg [ADC_SCALE_WIDTH-1:0] adc_scale;
	wire [ADC_SCALE_CUT_WIDTH-1:0] adc_scale_cut;
	reg signed [ADC_OFFSET_WIDTH-1:0] adc_offset;
			
// todo: round
	
	always_ff @(posedge clock) begin
		if (k < ADC_NUM) data <= adc_reg[k];
		
		scale <= (scale_q[SCALE_WIDTH-1]) ? SCALE_MAX : scale_q;
		offset <= {offset[0], offset_q};
		
		adc_shift <= data >> shift_q;
		
		adc_scale <= adc_shift_lim * scale;
		
		adc_offset <= signed'({1'b0, adc_scale_cut}) - signed'(offset[1]);
	end	
	
	u_limit_comb #(.DATA_WIDTH(ADC_WIDTH), .RES_WIDTH(32))								lim_inst0(.data(adc_shift), .result(adc_shift_lim)); // 0
	
	u_round_comb #(.DATA_WIDTH(ADC_SCALE_WIDTH), .RES_WIDTH(ADC_SCALE_CUT_WIDTH))	round_inst(.data(adc_scale), .result(adc_scale_cut)); // 0
	
	limit_comb #(.DATA_WIDTH(ADC_OFFSET_WIDTH), .RES_WIDTH(32))							lim_inst1(.data(adc_offset), .result(result)); // 0
	
	always_ff @(posedge clock, posedge aclr)
		scale_err <= (aclr) ? 1'b0 : scale_q > SCALE_MAX;
	
endmodule :adc_adj

`endif
