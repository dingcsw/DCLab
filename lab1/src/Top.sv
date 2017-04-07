module Top(
	input i_clk,
	input i_rst,
	input i_start,
	output [3:0] o_random_out
);

	`ifdef FAST_SIM
		parameter FREQ_HZ = 1000;
	`elsif
		parameter FREQ_HZ = 50000000;
	`endif

	parameter MULTIPLIER = 48271;
	parameter MODULAR = 2147483647;
	parameter COUNTER_STOP = 110000000;

	logic running_flag_r, running_flag_w;
	logic [63:0] counter;
	logic [63:0] random_number_r, random_number_w;
	logic [3:0] o_random_out_r, o_random_out_w;

	assign o_random_out = o_random_out_r;

	always_comb begin
		random_number_w = random_number_r * MULTIPLIER % MODULAR;

		if (running_flag_r &&
			(counter == 2500000 ||
			counter == 5000000 ||
			counter == 7500000 ||
			counter == 10000000 ||
			counter == 15000000 ||
			counter == 20000000 ||
			counter == 25000000 ||
			counter == 35000000 ||
			counter == 45000000 ||
			counter == 55000000 ||
			counter == 80000000 ||
			counter == COUNTER_STOP)
		)
			o_random_out_w = random_number_r % 16;
		else
			o_random_out_w = o_random_out_r;

		if (counter == COUNTER_STOP)
			running_flag_w = 0;
		else
			running_flag_w = 1;
	end

	always_ff @(posedge i_clk or negedge i_rst) begin
		if (!i_rst) begin
			counter <= COUNTER_STOP + 1;
			random_number_r <= 0;
			o_random_out_r <= 0;
			running_flag_r <= 0;
		end else begin
			if (i_start) begin
				running_flag_r <= 1;
				counter <= 0;
				random_number_r <= counter;
			end else begin
				counter <= counter + 1;
				random_number_r <= random_number_w;
				running_flag_r <= running_flag_w;
			end
			o_random_out_r <= o_random_out_w;
		end
	end

endmodule
