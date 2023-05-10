`ifndef _fifo2_
`define _fifo2_
`include "fifo_rdreq.sv"

module fifo2 #(parameter DATA_WIDTH = 24)(
	input aclr,
	input adc_clk, adc_wrreq,
	input [DATA_WIDTH-1:0] adc,
	
	input clk, rdreq,
	output [DATA_WIDTH-1:0] q,
	output empty
);
	reg sclr = 1'b1;
	always_ff @(posedge clk, posedge aclr)
		sclr <= (aclr) ? 1'b1 : 1'b0;
	
	reg [DATA_WIDTH-1:0] adc_reg;
	reg wrreq_reg = 1'b0;
	
	always_ff @(posedge adc_clk) begin
		if (adc_wrreq) adc_reg <= adc;
		wrreq_reg <= adc_wrreq;
	end
	
	reg [1:0][DATA_WIDTH-1:0] data_clk;
	always_ff @(posedge clk)
		data_clk <= {data_clk[0], adc_reg};

	reg [2:0] wrreq_clk = '0;
	always_ff @(posedge clk)
		wrreq_clk <= {wrreq_clk[1:0], wrreq_reg};
		
	wire l_wrreq = wrreq_clk[2:1] == 2'b01;
	wire full;
	
	fifo_rdreq #(.ADDR_WIDTH(1), .DATA_WIDTH(DATA_WIDTH)) fifo_inst(
		.clock(clk), .sclr,
		.data(data_clk[1]),
		.wrreq(l_wrreq), .rdreq(rdreq || (full && l_wrreq)),
		.q,
		.empty, .full,
		.usedw()
	);
	
endmodule :fifo2

`endif
