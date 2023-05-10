`ifndef _clk_div_var_
`define _clk_div_var_

module clk_div_var #(parameter CNT_WIDTH = 5)(
	input clk, aclr, sync_ena,
	input [CNT_WIDTH-1:0] cnt_max,
	output clk_ena
);

	reg [CNT_WIDTH-1:0] div_cnt = '0;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			div_cnt <= '0;
		else if (!sync_ena || div_cnt == cnt_max)
			div_cnt <= '0;
		else
			div_cnt <= div_cnt + 1'b1;
	
	reg clk_ena_reg = 1'b0;
	always_ff @(posedge clk, posedge aclr)
		clk_ena_reg <= (aclr) ? 1'b0 : sync_ena && div_cnt == 'h0;
	
	assign clk_ena = sync_ena && clk_ena_reg;

endmodule :clk_div_var

`endif
