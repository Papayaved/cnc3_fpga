`ifndef _delay_line_
`define _delay_line_

module delay_line #(parameter
	DATA_WIDTH = 18,
	DELAY = 64,
	DELAY_WIDTH = 6
)(
	input aclr, clock, sclr, clock_ena,
	input [DATA_WIDTH-1:0] data,
	output reg [DATA_WIDTH-1:0] q
);

	localparam _DELAY = DELAY - 1;

(* ramstyle = "no_rw_check" *) reg [DATA_WIDTH-1:0] ram[2**DELAY_WIDTH - 1:0]; // = '{DELAY{18'h0}};
	
	reg [DELAY_WIDTH-1:0] wraddr = '0, rdaddr = '0;
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			wraddr <= '0;
		else if (sclr)
			wraddr <= '0;
		else if (clock_ena)
			wraddr <= wraddr + 1'b1;
			
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			rdaddr <= '0;
		else if (sclr)
			rdaddr <= '0;
		else if (clock_ena)
			rdaddr <= wraddr - _DELAY[DELAY_WIDTH-1:0];
	
	always_ff @(posedge clock)
		if (clock_ena)
			ram[wraddr] <= data;
	
	reg oe = 1'b0;
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			oe <= 1'b0;
		else if (sclr)
			oe <= 1'b0;
		else if (clock_ena && wraddr == _DELAY[DELAY_WIDTH-1:0])
			oe <= 1'b1;
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			q <= '0;
		else if (!oe)
			q <= '0;
		else if (clock_ena)
			q <= ram[rdaddr];

endmodule :delay_line

module delay_line_var #(parameter
	DATA_WIDTH = 18,
	DELAY_WIDTH = 6
)(
	input aclr, clock, sclr,
	input [DELAY_WIDTH-1:0] delay,
	input clock_ena,
	input [DATA_WIDTH-1:0] data,
	output reg [DATA_WIDTH-1:0] q
);

(* ramstyle = "no_rw_check" *) reg [DATA_WIDTH-1:0] ram[2**DELAY_WIDTH - 1:0]; // = '{DELAY{18'h0}};
	
	reg [DELAY_WIDTH-1:0] wraddr = '0, rdaddr = '0;
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			wraddr <= '0;
		else if (sclr)
			wraddr <= '0;
		else if (clock_ena)
			wraddr <= wraddr + 1'b1;
			
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			rdaddr <= '0;
		else if (sclr)
			rdaddr <= '0;
		else if (clock_ena)
			rdaddr <= wraddr - delay;
	
	always_ff @(posedge clock)
		if (clock_ena)
			ram[wraddr] <= data;
	
	reg oe = 1'b0;
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			oe <= 1'b0;
		else if (sclr)
			oe <= 1'b0;
		else if (clock_ena && wraddr == delay)
			oe <= 1'b1;
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			q <= '0;
		else if (!oe)
			q <= '0;
		else if (clock_ena)
			q <= ram[rdaddr];

endmodule :delay_line_var

`endif
