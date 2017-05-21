module Play (
	input i_start,
	input i_stop,
	input i_pause,
	input i_clk,
	input [19:0] i_start_addr, // location of storage start
	input [19:0] i_end_addr,   // location of storage end
	output o_sram_we,
	output o_sram_ce,
	output o_sram_oe,
	output o_sram_lb,
	output o_sram_ub,
	input [17:0] sw,
	input i_DACLRC,
	output o_aud_dacdat,
	output [19:0] sram_addr,
	input [15:0] i_sram_dq, // change
	input i_is_full,
	output o_finish
);

parameter IDLE = 0, WAIT = 1, PLAY_RIGHT = 2, PLAY_LEFT = 3, PAUSE = 4, threshold = 50;
logic aud_dacdat;
logic sram_we, sram_ce, sram_oe, sram_lb, sram_ub;
//logic [15:0] sram_dat;
logic [19:0] addr_r, addr_w;
//logic [19:0] start_addr_r, start_addr_w, end_addr_r, end_addr_w;
logic [2:0] state_w, state_r;
logic [3:0] counter_r, counter_w;
logic is_right_r, is_right_w, pause_w, pause_r, is_at_head_w, is_at_head_r;
logic fin;
logic [3:0] step;
//logic [15:0] diff_r, diff_w;
logic signed [31:0] result_r, result_w; 
logic [3:0] slowmode_counter_r, slowmode_counter_w, fastmode_counter_r, fastmode_counter_w;
logic [3:0] interp_interval;
logic signed [31:0] sram_dq, prev_sram_dq_r, prev_sram_dq_w;

assign sram_addr = addr_r;
assign o_aud_dacdat = aud_dacdat;
assign o_sram_ce = sram_ce;
assign o_sram_lb = sram_lb;
assign o_sram_oe = sram_oe;
assign o_sram_ub = sram_ub;
assign o_sram_we = sram_we;
assign sram_dq = {{16{i_sram_dq[15]}},i_sram_dq[15:0]};
//assign sram_dq = i_sram_dq;
//assign i_sram_dq = sram_dat;
assign o_finish = fin;

always_comb begin
	if (sw[0] == 1)
		//step = 1*threshold;
		step = 2;
	else if (sw[1] == 1)
		//step = 2*threshold;
		step = 3;
	else if (sw[2] == 1)
		//step = 3*threshold;
		step = 4;
	else if (sw[3] == 1)
		//step = 4*threshold;
		step = 5;
	else if (sw[4] == 1)
		//step = 5*threshold;
		step = 6;
	else if (sw[5] == 1)
		//step = 6*threshold;
		step = 7;
	else if (sw[6] == 1)
		//step = 7*threshold;
		step = 8;
	else 
	step = 1;
end

always_comb begin
	if (sw[7] == 1)
		interp_interval = 2;
	else if (sw[8] == 1)
		interp_interval = 3;
	else if (sw[9] == 1)
		interp_interval = 4;
	else if (sw[10] == 1)
		interp_interval = 5;
	else if (sw[11] == 1)
		interp_interval = 6;
	else if (sw[12] == 1)
		interp_interval = 7;
	else if (sw[13] == 1)
		interp_interval = 8;
	else 
	interp_interval = 1;
end

always_comb begin
	fastmode_counter_w = fastmode_counter_r;
	addr_w = addr_r;
	state_w = state_r;
	counter_w = counter_r;
	slowmode_counter_w = slowmode_counter_r;
	//diff_w = diff_r;
	sram_we = 1;
	sram_ce = 0;
	sram_oe = 0;
	sram_lb = 0;
	sram_ub = 0;
	pause_w = pause_r;
	is_right_w = is_right_r;
	fin = 0;
	aud_dacdat = 0;
	is_at_head_w = is_at_head_r;
	result_w = result_r;
	prev_sram_dq_w = prev_sram_dq_r;
	case(state_r)
		IDLE : begin
			addr_w = 'z;
			sram_we = 'z;
			sram_ce = 'z;
			sram_oe = 'z;
			sram_lb = 'z;
			sram_ub = 'z;
			fin = 1;
			if (i_start) begin
				is_at_head_w = ~i_is_full;
				state_w = WAIT;
				addr_w = i_start_addr;
				is_right_w = i_DACLRC;
				prev_sram_dq_w = 0;
				slowmode_counter_w = 1;
				fastmode_counter_w = 0;
			end
			pause_w = 0;
		end
		WAIT : begin
			if (i_start_addr == i_end_addr & ~i_is_full) begin
				state_w = IDLE;
			end else if (i_pause) begin
				state_w = PAUSE;
			end else if (i_stop) begin
				state_w = IDLE;
			end else if(is_right_r == 1 & i_DACLRC == 0) begin
				state_w = PLAY_LEFT;
				counter_w = 0;
			end else if(i_DACLRC == 1) begin
				is_right_w = 1;
			end
			//result_w = i_sram_dq;
			if (sw[16]) begin
				case(interp_interval)
					1 : begin
						//result_w = prev_sram_dq_r + (sram_dq - prev_sram_dq_r)*slowmode_counter_r;
						result_w = sram_dq;
					end
					2 : begin
						result_w = (prev_sram_dq_r/2)*(2 - slowmode_counter_r) + (sram_dq/2)*slowmode_counter_r;//prev_sram_dq_r + ((sram_dq - prev_sram_dq_r)/2)*slowmode_counter_r;
					end
					3 : begin
						result_w = (prev_sram_dq_r/8*3)*(8/3 - slowmode_counter_r) + (sram_dq/8*3)*slowmode_counter_r;//prev_sram_dq_r + ((sram_dq - prev_sram_dq_r)/3)*slowmode_counter_r;
					end
					4 : begin
						result_w = (prev_sram_dq_r/4)*(4 - slowmode_counter_r) + (sram_dq/4)*slowmode_counter_r;//prev_sram_dq_r + ((sram_dq - prev_sram_dq_r)/4)*slowmode_counter_r;
					end
					5 : begin
						result_w = (prev_sram_dq_r*3/16)*(16/3 - slowmode_counter_r) + (sram_dq*3/16)*slowmode_counter_r;//prev_sram_dq_r + ((sram_dq - prev_sram_dq_r)/5)*slowmode_counter_r;
					end
					6 : begin
						result_w = (prev_sram_dq_r*21/128)*(128/21 - slowmode_counter_r) + (sram_dq*21/128)*slowmode_counter_r;//prev_sram_dq_r + ((sram_dq - prev_sram_dq_r)/6)*slowmode_counter_r;
					end
					7 : begin
						result_w = (prev_sram_dq_r*9/64)*(64/9 - slowmode_counter_r) + (sram_dq*9/64)*slowmode_counter_r;//prev_sram_dq_r + ((sram_dq - prev_sram_dq_r)/7)*slowmode_counter_r;
					end
					8 : begin
						result_w = (prev_sram_dq_r/8)*(8 - slowmode_counter_r) + (sram_dq/8)*slowmode_counter_r;//prev_sram_dq_r + ((sram_dq - prev_sram_dq_r)/8)*slowmode_counter_r;
					end
				endcase
			end else begin
				result_w = sram_dq;
			end
		end
		PLAY_LEFT : begin
			if (i_pause) begin
				pause_w = 1;
				// change addr
			end else if (i_stop) begin
				state_w = IDLE;
				addr_w = 0;
			end else begin
				aud_dacdat = result_r[15 - counter_r];//i_sram_dq[15 - counter_r];
				if (counter_r == 15 & i_DACLRC == 1) begin
					if (pause_r) begin
						state_w = PAUSE;
						pause_w = 0;
					end
					state_w = PLAY_RIGHT;
					counter_w = 0;
				end else if (counter_r < 15)begin	
					counter_w = counter_r + 1;
				end
			end
		end
		PLAY_RIGHT : begin
			if (i_pause)
				pause_w = 1;
			if (i_stop) begin
				state_w = IDLE;
				addr_w = 0;
			end else begin
				aud_dacdat = result_r[15 - counter_r];//i_sram_dq[15 - counter_r];
				if (counter_r == 15) begin
					if (is_at_head_r) begin
						if (i_end_addr - addr_r < step)
							state_w = IDLE;
						else begin
							if (pause_r) begin
								state_w = PAUSE;
								pause_w = 0;
							end else begin
								state_w = WAIT;	
								is_right_w = i_DACLRC;
							end
							if (slowmode_counter_r == interp_interval) begin
								/*if (fastmode_counter_r == threshold) begin
									addr_w = addr_r + step;
									fastmode_counter_w = 0;
								end else begin
									addr_w = addr_r + 1;
									fastmode_counter_w = fastmode_counter_r + 1;
								end*/
								addr_w = addr_r + step;
								slowmode_counter_w = 1;
								prev_sram_dq_w = {{16{i_sram_dq[15]}},i_sram_dq[15:0]};
								//prev_sram_dq_w = i_sram_dq;
							end else
								slowmode_counter_w = slowmode_counter_r + 1;
							
							counter_w = 0;
						end
					end else if ('1 - addr_r < step) begin
						is_at_head_w = 1;
						if (pause_r) begin
							state_w = PAUSE;
							pause_w = 0;
						end else begin
							state_w = WAIT;							
							is_right_w = i_DACLRC;
						end
						if (slowmode_counter_r == interp_interval) begin
							/*if (fastmode_counter_r == threshold) begin
								addr_w = 0;
								fastmode_counter_w = 0;
							end else begin
								addr_w = 0;
								fastmode_counter_w = fastmode_counter_r + 1;
							end*/
							addr_w = 0;
							slowmode_counter_w = 1;
							prev_sram_dq_w = {{16{i_sram_dq[15]}},i_sram_dq[15:0]};
							//prev_sram_dq_w = i_sram_dq;
						end else
							slowmode_counter_w = slowmode_counter_r + 1;
						//addr_w = 0; // no consider step
						counter_w = 0;
					end else begin
						if (pause_r) begin
							state_w = PAUSE;
							pause_w = 0;
						end else begin
							state_w = WAIT;	
							is_right_w = i_DACLRC;
						end
						if (slowmode_counter_r == interp_interval) begin
							/*if (fastmode_counter_r == threshold) begin
								addr_w = addr_r + step;
								fastmode_counter_w = 0;
							end else begin
								addr_w = addr_r + 1;
								fastmode_counter_w = fastmode_counter_r + 1;
							end*/
							addr_w = addr_r + step;
							slowmode_counter_w = 1;
							prev_sram_dq_w = {{16{i_sram_dq[15]}},i_sram_dq[15:0]};
							//prev_sram_dq_w = i_sram_dq;
						end else
							slowmode_counter_w = slowmode_counter_r + 1;
						counter_w = 0;
					end
					
				end else begin	
					counter_w = counter_r + 1;
				end
			end
		end
		PAUSE : begin
			if (i_start) begin
				state_w = WAIT;
				is_right_w = i_DACLRC;
			end
		end
		default : begin
			state_w = IDLE;
		end
	endcase
end

always_ff @(negedge i_clk) begin
	addr_r <= addr_w;
	fastmode_counter_r <= fastmode_counter_w;
	//start_addr_r <= start_addr_w;
	//end_addr_r <= end_addr_w;
	state_r <= state_w;
	counter_r <= counter_w;
	slowmode_counter_r <= slowmode_counter_w;
	//diff_r <= diff_w;
	is_right_r <= is_right_w;
	pause_r <= pause_w;
	is_at_head_r <= is_at_head_w;
	prev_sram_dq_r <= prev_sram_dq_w;
	result_r <= result_w;
end

endmodule