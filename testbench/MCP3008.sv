module MCP3008(
	input [7:0][9:0] data,
	
	input sclk, csn, mosi,
	output reg miso = 1'bz
);

	int bit_cnt = 0;
	
	always @(posedge sclk, posedge csn)
		bit_cnt <= csn ? 0 : bit_cnt + 1;
	
	bit start = 0, single = 0;
	bit [2:0] a = 0;
	
	always @(posedge sclk, posedge csn)
		if (csn)
			begin
				start <= 0;
				single <= 0;
				a <= 0;
			end
		else
			case (bit_cnt)
				0: start <= mosi;
				1: single <= mosi;
				2: a[2] <= mosi;
				3: a[1] <= mosi;
				4: a[0] <= mosi;
			endcase
			
	always @(negedge sclk, posedge csn)
		if (csn)
			miso = 1'bz;
		else
			case (bit_cnt)
				6: miso <= 0;
				7: miso <= start && single ? data[a][9] : 1'bz;
				8: miso <= start && single ? data[a][8] : 1'bz;
				9: miso <= start && single ? data[a][7] : 1'bz;
				10: miso <= start && single ? data[a][6] : 1'bz;
				11: miso <= start && single ? data[a][5] : 1'bz;
				12: miso <= start && single ? data[a][4] : 1'bz;
				13: miso <= start && single ? data[a][3] : 1'bz;
				14: miso <= start && single ? data[a][2] : 1'bz;
				15: miso <= start && single ? data[a][1] : 1'bz;
				16: miso <= start && single ? data[a][0] : 1'bz;
			endcase
			
endmodule :MCP3008
