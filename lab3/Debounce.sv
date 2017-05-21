module Debounce(
		input i_in,
		input i_clk,
		input i_rst,
		output o_debounced,
		output o_neg,
		output o_pos
) /*synthesis noprune*/ /*synthesis preserve*/ /*synthesis keep*/;

		parameter CNT_N = 7;
		localparam CNT_BIT = $clog2(CNT_N+1);

		logic debounced_r, debounced_w;
		logic [CNT_BIT-1:0] counter_r, counter_w;
		logic neg_r, neg_w;
		logic pos_r, pos_w;

		assign o_debounced = debounced_r;
		assign o_neg = neg_r;
		assign o_pos = pos_r;

		always_comb begin
			if (i_in != debounced_r)
				counter_w = counter_r - 1;
			else
				counter_w = CNT_N;

			if (counter_r == 0)
				debounced_w = ~debounced_r;
			else
				debounced_w = debounced_r;

			neg_w = debounced_r & ~debounced_w;
			pos_w = ~debounced_r & debounced_w;
		end

		always_ff @(posedge i_clk or negedge i_rst) begin
			if (!i_rst) begin
				debounced_r <= 0;
				counter_r <= 0;
				neg_r <= 0;
				pos_r <= 0;
			end else begin
				debounced_r <= debounced_w;
				counter_r <= counter_w;
				neg_r <= neg_w;
				pos_r <= pos_w;
			end
		end
endmodule
