`ifndef _step_dir_cnt_
`define _step_dir_cnt_

// write only if no step

module step_dir_cnt(
	input clk, aclr, sclr,
	input [1:1] addr,
	input [1:0] be,
	input [15:0] wrdata,
	input write, snapshot, enc_changed,
	
	input step, dir,
	output reg signed [31:0] cnt, cnt_enc
);

	reg [1:0] step_reg = '0;
	reg step_clk = 1'b0;
	reg [2:0] dir_reg = 1'b0;

	always_ff @(posedge clk, posedge aclr) begin
		step_reg	<= aclr ? 2'h0 : (sclr ? 2'h0 : {step_reg[0], step});
		step_clk	<= aclr ? 1'b0 : (sclr ? 1'b0 : step_reg == 2'b01);
		dir_reg	<= aclr ? 3'h0 : (sclr ? 3'h0 : {dir_reg[1:0], dir});
	end

	reg signed [31:0] step_cnt = '0, step_cnt_enc = '0;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			step_cnt <= '0;
		else if (sclr)
			step_cnt <= '0;
		else if (write)
			begin
				if (addr[1] == 1'b0 && be[0]) step_cnt[7:0] <= wrdata[7:0];
				if (addr[1] == 1'b0 && be[1]) step_cnt[15:8] <= wrdata[15:8];
				if (addr[1] == 1'b1 && be[0]) step_cnt[23:16] <= wrdata[7:0];
				if (addr[1] == 1'b1 && be[1]) step_cnt[31:24] <= wrdata[15:8];
			end
		else if (step_clk)
			step_cnt <= (dir_reg[2]) ? step_cnt - 1'b1 : step_cnt + 1'b1;
			
	// Lock by encoder
	reg enc_changed_reg = 1'b0;
	always_ff @(posedge clk, posedge aclr)
		enc_changed_reg <= (aclr) ? 1'b0 : (sclr) ? 1'b0 : enc_changed;
		
	wire enc_clk = enc_changed && !enc_changed_reg;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			step_cnt_enc <= '0;
		else if (sclr || (write && be != '0))
			step_cnt_enc <= '0;
		else if (enc_clk)
			step_cnt_enc <= step_cnt;
	
	// Snapshot
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			{cnt, cnt_enc} <= '0;
		else if (sclr)
			{cnt, cnt_enc} <= '0;
		else if (snapshot)
			begin
				cnt <= step_cnt;
				cnt_enc <= step_cnt_enc;
			end

endmodule: step_dir_cnt

`endif
