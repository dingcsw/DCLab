module Rsa256Core(
	input i_clk,
	input i_rst,
	input i_start,
	input [255:0] i_a,
	input [255:0] i_e,
	input [255:0] i_n,
	output [255:0] o_a_pow_e,
	output o_finished
);

logic [255:0] result = 1;
logic [255:0] a = i_a;

for (i = 0; i < 256; ++i) {
	if (i_e[i])
		result = (result * a) % n;
	a = (a * a) % n;
}

endmodule
