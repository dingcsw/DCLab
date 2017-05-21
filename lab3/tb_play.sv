`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;
	localparam SAMP = 20;
	localparam KCLK =  120*CLK;
	logic clk,sclk,adcdat,adclrck,kclk,dacdat,daclrck,sw,sram_we,sram_ce,sram_lb,sram_ub,sta,stop,pause;
	logic [2:0] state;
	logic [3:0] key;
	logic [15:0] sram_dat,sramdq;
	logic [19:0] sram_addr, sta_addr, end_addr;
// no sdat
  wire sdat;
	initial clk = 0;
	initial kclk=0;
	always #HCLK clk = ~clk;
	always #(120*CLK) kclk=~kclk;
	localparam dat = 16'hac54;

Play  play(
	.i_start(sta),
	.i_stop(stop),
	.i_pause(pause),
	.i_clk(clk),
	.i_start_addr(sta_addr), // location of storage start
	.i_end_addr(end_addr),   // location of storage end
	.o_sram_we(sram_we),
	.o_sram_ce(sram_ce),
	.o_sram_oe(sram_oe),
	.o_sram_lb(sram_lb),
	.o_sram_ub(sram_ub),
	.sw(sw),
	.i_DACLRC(daclrck),
	.o_aud_dacdat(dacdat),
	.sram_addr(sram_addr),
	.i_sram_dq(sramdq), // change
	.o_finish(fin)
);

	initial begin
		$fsdbDumpfile("lab3_play.fsdb");
		$fsdbDumpvars;
		#(600*CLK)
		sta_addr = '0;
		end_addr = '0;
		daclrck <= 1;
		sw <= 0;
		sramdq <= dat;
		@(posedge clk)
		sta <= 1;
		#(240*CLK)
		sta <= 0;
		@(negedge clk)
		daclrck <= 0;
		#(30*CLK)
		daclrck <= 1;

		#(30000*120*CLK);
		$finish;
	end

	/*initial begin
		#(300*CLK)
		//$display("Too slow, abort.");
		//$finish;
	end*/

endmodule
