`ifndef _parser_
`define _parser_
`include "header.sv"
`include "task_parser.sv"
`include "computer.sv"

module parser #(parameter
	N_WIDTH = `N_WIDTH
)(
	input clk, aclr, abort, enable,
	input [31:0] cmd_q,
	input cmd_empty,
	output cmd_rdreq,
	
	// Current parameters
	output TaskParam par,
	
	input step_req, braking, brake_clk,
	output task_empty,
	output reg step_ack,
	output [7:0] stopped,
	
	output [7:0] pls_sop, pls_eop,
	output PlsData [7:0] pls_data,
	output [7:0] pls_wrreq,
	input [7:0] pls_full,
	input PlsContext [7:0] cur_data,
	
	output [8:0] error
);

	import MyFuncPkg::*;

	typedef enum {IDLE, RDACK, CALC, ACK, ERR} State;
	State state;

	reg task_rdack = 1'b0;
	wire [7:0] comp_rdy;

	wire [7:0] task_error;

	reg load = 1'b0;
		
	TaskParam par_q;

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			begin
				task_rdack <= 1'b0;
				load <= 1'b0;			
				step_ack <= 1'b0;
				par <= '0;
				state <= IDLE;
			end
		else if (abort)
			begin
				task_rdack <= 1'b0;
				load <= 1'b0;
				step_ack <= 1'b0;
				state <= ERR;
			end
		else
			case (state)
				IDLE:
					if (task_error != '0 || step_req && !task_empty)
						begin
							par <= par_q;
							
							if (task_error == '0) begin
									task_rdack <= 1'b1;
									state <= RDACK;
								end
						end
				RDACK:
					begin
						task_rdack <= 1'b0;
						
						if (comp_rdy == '1) begin
							load <= 1'b1;
							state <= CALC;
						end
					end
				CALC:
					begin
						load <= 1'b0;
						
						if (comp_rdy == '1) begin
							step_ack <= 1'b1;
							state <= ACK;
						end
					end
				ACK:
					begin
						if (!step_req) begin
							step_ack <= 1'b0;
							state <= IDLE;
						end
					end
				ERR: ;
			endcase

	task_parser tparse(
		.clk, .aclr, .abort, .enable,
		.q(cmd_q), .empty(cmd_empty), .rdreq(cmd_rdreq),
		.task_empty, .task_rdack, .task_parsing(), .task_error,
		.par(par_q)
	);

	MotorParam[7:0] m_par;
	wire calc_error;

	computer comp_inst(
		.clk, .aclr, .sclr(1'b0), .braking, .brake_clk,
		.m_par,	.load,
		.ready(comp_rdy), .stopped,
		.pls_full, .pls_sop, .pls_eop, .pls_data, .pls_wrreq,
		.cur_data, .error(calc_error)
	);

	assign error = {calc_error, task_error};

	genvar i;
	generate for (i = 0; i < 8; i++)
		begin :gen
			always_comb begin
				m_par[i].ts = par.ts;
				m_par[i].mask = par.N[i] != '0;						
				m_par[i].N = N_WIDTH'(abs32(par.N[i]));
				m_par[i].dir = sign32(par.N[i]); // less 0
				m_par[i].V0 = par.V0[i];
			end
		end
	endgenerate

endmodule :parser

`endif
