`ifndef _imit_enc_
`define _imit_enc_

// Imitation of linear encoders

module imit_enc(
	input clk, aclr, sclr,
	input step, dir,
	
	output A, B
);
	localparam STEP_MAX = 4'sd4;
	localparam STEP_MIN = -4'sd4;

	parameter logic [1:0] gray[4] = '{2'b00, 2'b01, 2'b11, 2'b10};
	
	reg [1:0] gray_cnt = 0;	
	reg step_reg = 1'b0;
	
	always @(posedge clk, posedge aclr)
		step_reg <= (aclr) ? 1'b0 : (sclr) ? 1'b0 : step;
		
	wire stop_clk = step && !step_reg;
	
	reg signed [3:0] step_cnt = 'sh0;

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			step_cnt <= 'sh0;
		else if (sclr)
			step_cnt <= 'sh0;
		else if (stop_clk)
			if (dir == 0)
				if (step_cnt == STEP_MAX)
					step_cnt <= 'sh0;
				else
					step_cnt <= step_cnt + 1'b1;
			else
				if (step_cnt == STEP_MIN)
					step_cnt <= 'sh0;
				else
					step_cnt <= step_cnt - 1'b1;
	
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			gray_cnt <= '0;
		else if (sclr)
			gray_cnt <= '0;
		else if (stop_clk)
			if (!dir && step_cnt == STEP_MAX)
				gray_cnt <= gray_cnt + 1'b1;
			else if (dir && step_cnt == STEP_MIN)
				gray_cnt <= gray_cnt - 1'b1;
	
	assign {B, A} = gray[gray_cnt];	
	
endmodule :imit_enc

`endif // _imit_enc_
