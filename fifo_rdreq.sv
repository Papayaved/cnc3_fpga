`ifndef _fifo_rdreq_
`define _fifo_rdreq_

module fifo_rdreq #(parameter
	ADDR_WIDTH = 9, DATA_WIDTH = 32
)(
	input clock, aclr, sclr,
	input [DATA_WIDTH-1:0] data,
	input wrreq, rdreq,
	output reg [DATA_WIDTH-1:0] q,
	output reg empty, full,
	output reg [ADDR_WIDTH-1:0] usedw
);

//initial begin empty = 1'b1; full = 1'b1; q = '0; usedw = '0; end

reg [ADDR_WIDTH-1:0] wr_addr = '0, rd_addr = '0;

(* ramstyle = "no_rw_check" *) reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH - 1:0] = '{(2**ADDR_WIDTH){DATA_WIDTH'(0)}};

(* direct_enable *) wire l_wrreq = wrreq && !full;
(* direct_enable *) wire l_rdreq = rdreq && !empty;

always_ff @ (posedge clock)
	if (l_wrreq)
		ram[wr_addr] <= data;
		
always_ff @(posedge clock)
	if (l_rdreq)
		q <= ram[rd_addr];

always_ff @(posedge clock, posedge aclr)
	if (aclr)
		wr_addr <= '0;
	else if (sclr)
		wr_addr <= '0;
	else if (l_wrreq)
		wr_addr <= wr_addr + 1'b1;

always_ff @(posedge clock, posedge aclr)
	if (aclr)
		rd_addr <= '0;
	else if (sclr)
		rd_addr <= '0;
	else if (l_rdreq)
		rd_addr <= rd_addr + 1'b1;

always_ff @(posedge clock, posedge aclr)
	if (aclr)
		usedw <= '0;
	else if (sclr)
		usedw <= '0;
	else if (l_wrreq && l_rdreq)
		;
	else if (l_wrreq)
		usedw <= usedw + 1'b1;
	else if (l_rdreq)
		usedw <= usedw - 1'b1;

reg full_clr = 1'b1;
always_ff @(posedge clock, posedge aclr)
	if (aclr)			full_clr <= 1'b1;
	else if (sclr)		full_clr <= 1'b1;
	else if (!full)	full_clr <= 1'b0;
		
always_ff @(posedge clock, posedge aclr)
	if (aclr)
		full <= 1'b1;
	else if (sclr)
		full <= 1'b1;
	else if (full_clr)
		full <= 1'b0;
	else if (l_wrreq && l_rdreq)
		;
	else if (l_rdreq)
		full <= 1'b0;
	else if (l_wrreq)
		full <= wr_addr + 1'b1 == rd_addr;

always_ff @(posedge clock, posedge aclr)
	if (aclr)
		empty <= 1'b1;
	else if (sclr)
		empty <= 1'b1;
	else if (l_wrreq && l_rdreq)
		;
	else if (l_wrreq)
		empty <= 1'b0;
	else if (l_rdreq)
		empty <= rd_addr + 1'b1 == wr_addr;

endmodule :fifo_rdreq

`endif
