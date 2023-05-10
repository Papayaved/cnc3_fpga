`ifndef _limit_
`define _limit_

module limit_comb #(parameter
	DATA_WIDTH,
	RES_WIDTH,
	bit signed [DATA_WIDTH-1:0] MAX = DATA_WIDTH'({(RES_WIDTH-1){1'b1}}),
	bit signed [DATA_WIDTH-1:0] MIN = ~MAX
)(
	input signed [DATA_WIDTH-1:0] data,
	output logic signed [RES_WIDTH-1:0] result
);

	generate
		if (DATA_WIDTH > RES_WIDTH)
			begin :gen_lim
				always_comb
					if (data > MAX)
						result = MAX[RES_WIDTH-1:0];
					else if (data < MIN)
						result = MIN[RES_WIDTH-1:0];
					else
						result = data[RES_WIDTH-1:0];
			end
		else
			begin :gen_wide
				always_comb result = RES_WIDTH'('sh0) + data;
			end
	endgenerate
	
endmodule :limit_comb

module u_limit_comb #(parameter
	DATA_WIDTH,
	RES_WIDTH,
	bit [DATA_WIDTH-1:0] MAX = DATA_WIDTH'({RES_WIDTH{1'b1}})
)(
	input [DATA_WIDTH-1:0] data,
	output [RES_WIDTH-1:0] result
);

	generate
		if (DATA_WIDTH > RES_WIDTH)
			begin :gen_lim
				assign result = (data > MAX) ? MAX[RES_WIDTH-1:0] : data[RES_WIDTH-1:0];
			end
		else
			begin :gen_wide
				assign result = RES_WIDTH'(data);
			end
	endgenerate
	
endmodule :u_limit_comb

module limit #(parameter
	DATA_WIDTH,
	RES_WIDTH
)(
	input clock,
	input signed [DATA_WIDTH-1:0] data,
	output reg signed [RES_WIDTH-1:0] result
);

	wire signed [RES_WIDTH-1:0] res_comb;
	limit_comb #(.DATA_WIDTH(DATA_WIDTH), .RES_WIDTH(RES_WIDTH)) inst(.data, .result(res_comb));

	always_ff @(posedge clock)
		result <= res_comb;
	
endmodule :limit

`endif
