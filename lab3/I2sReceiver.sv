module I2sReceiver(
	input i_start,
	input i_finish,
	input i_ADCLRC,
	input i_BCLK,
	input i_ADCDAT,
	output o_sram_we,
	output o_sram_ce,
	output o_sram_oe,
	output o_sram_lb,
	output o_sram_ub,
	output [19:0] o_sram_addr,
	output [19:0] o_start_addr,
	output [19:0] o_end_addr,
	output [15:0] o_SRAMDQ,
	output o_is_full
);

parameter IDLE = 0, WAIT = 1, RECEIVE = 2, TRANSMITT = 3;
logic [1:0] state_r, state_w;
logic [15:0] SRAMDQ_r, SRAMDQ_w;
logic is_right_r, is_right_w, we, ce, oe, lb, ub, is_full_r, is_full_w;
logic [4:0] rec_counter_w, rec_counter_r;
logic [19:0] start_addr_r, start_addr_w, end_addr_r, end_addr_w, sram_addr;

assign o_SRAMDQ = SRAMDQ_r;
assign o_sram_we = we;
assign o_sram_ce = ce;
assign o_sram_oe = oe;
assign o_sram_lb = lb;
assign o_sram_ub = ub;
assign o_sram_addr = sram_addr;
assign o_start_addr = start_addr_r;
assign o_end_addr = end_addr_r;
assign o_is_full = is_full_r;

always_comb begin
	rec_counter_w = rec_counter_r;
	is_right_w = is_right_r;
	is_full_w = is_full_r;
	state_w = state_r;
	start_addr_w = start_addr_r;
	end_addr_w = end_addr_r;
	SRAMDQ_w = SRAMDQ_r;
	sram_addr = end_addr_r;
	we = 1;
	ce = 0;
	oe = 0;
	lb = 0;
	ub = 0;
	case(state_r)
		IDLE : begin
			we = 'z;
			ce = 'z;
			oe = 'z;
			lb = 'z;
			ub = 'z;
			SRAMDQ_w = 'z;
			sram_addr = 'z;
			if(i_start) begin
				state_w = WAIT;
				start_addr_w = 0;
				end_addr_w = 0;
				is_full_w = 0;
				is_right_w = i_ADCLRC;
				/*if(i_ADCLRC) begin
					is_right_w = 1;
				end else begin
					is_right_w = 0;
				end*/
			end
		end
		WAIT : begin
			if(i_finish) begin
				state_w = IDLE;
			end else if(is_right_r == 1 & i_ADCLRC == 0) begin
				state_w = RECEIVE;
				rec_counter_w = 0;
			end else if(i_ADCLRC == 1) begin
				is_right_w = 1;
			end
		end
		RECEIVE : begin
			if(i_finish) begin
				state_w = IDLE;
				//SRAMDQ_w[15 - rec_counter_r] = i_ADCDAT;
			end else begin
				if (rec_counter_r <= 15) begin
					rec_counter_w = rec_counter_r + 1;
					SRAMDQ_w[15 - rec_counter_r] = i_ADCDAT;  // question
				end else if (rec_counter_r == 16 & i_ADCLRC == 1) begin
					state_w = TRANSMITT;
				end
			end
		end
		TRANSMITT : begin
			we = 0;
			ce = 0;
			lb = 0;
			ub = 0;
			if (end_addr_r == '1) begin
				end_addr_w = 0;
				start_addr_w = 1;
				is_full_w = 1;
			end else begin
				end_addr_w = end_addr_r + 1;
				if(end_addr_r + 1 == start_addr_r)
					start_addr_w = start_addr_r + 1;
			end
			if(i_finish) begin
				state_w = IDLE;
			end else begin
				state_w = WAIT;
			end
			is_right_w = i_ADCLRC;
		end
		default : begin
			state_w = IDLE;
		end
	endcase
end	


always_ff @(negedge i_BCLK) begin
	state_r <= state_w;
	rec_counter_r <= rec_counter_w;
	is_right_r <= is_right_w;
	is_full_r <= is_full_w;
	SRAMDQ_r <= SRAMDQ_w;
	start_addr_r <= start_addr_w;
	end_addr_r <= end_addr_w;
end
endmodule
