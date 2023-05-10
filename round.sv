`ifndef _round_
`define _round_

module round_comb #(parameter
	DATA_WIDTH = 32,
	RES_WIDTH = 24
)(
	input signed [DATA_WIDTH-1:0] data,
	output logic signed [RES_WIDTH-1:0] result
);
	localparam CUT = DATA_WIDTH - RES_WIDTH;
	localparam MAX = {1'b0, {(RES_WIDTH - 1){1'b1}}};
	localparam MIN = ~MAX;

	generate
		if (RES_WIDTH < DATA_WIDTH)
			begin
				wire signed [RES_WIDTH-1:0] res = data[CUT +: RES_WIDTH];
			
				always_comb
					if (data[CUT +: RES_WIDTH] == MAX || data < 'sh0 || data[CUT-1] == 1'b0)
						result = res;
					else
						result = res + RES_WIDTH'('sh1);
			end
		else
			always_comb result = RES_WIDTH'('sh0) + data;
	endgenerate
	
endmodule :round_comb

module u_round_comb #(parameter
	DATA_WIDTH = 32,
	RES_WIDTH = 24
)(
	input [DATA_WIDTH-1:0] data,
	output logic [RES_WIDTH-1:0] result
);
	localparam CUT = DATA_WIDTH - RES_WIDTH;
	localparam bit [RES_WIDTH-1:0] MAX = '1;

	generate
		if (RES_WIDTH < DATA_WIDTH)
			begin
				wire signed [RES_WIDTH-1:0] res = data[CUT +: RES_WIDTH];
			
				always_comb
					if (data[CUT +: RES_WIDTH] == MAX || data[CUT-1] == 1'b0)
						result = res;
					else
						result = res + 1'b1;
			end
		else
			always_comb result = RES_WIDTH'(data);
	endgenerate
	
endmodule :u_round_comb

`endif
