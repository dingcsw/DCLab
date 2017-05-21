`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;
	localparam SAMP = 20;
	logic clk, sta, fin, rst, sclk, dat_r, dat_w, write, keydown, lrc, sram_we, sram_ce, sram_lb, sram_ub, adc_dat;
	logic [15:0] sram_dat;
	logic [19:0] sram_addr, sta_addr, end_addr;
	wire sdat;
	initial clk = 0;
	always #HCLK clk = ~clk;
	localparam dat = 16'hac54;
	I2sReceiver core(
		.i_start(sta),
		.i_finish(keydown),
		.i_ADCLRC(lrc),
		.i_BCLK(clk),
		.i_ADCDAT(adc_dat),
		.o_sram_we(sram_we),
		.o_sram_ce(sram_ce),
		.o_sram_lb(sram_lb),
		.o_sram_ub(sram_ub),
		.o_sram_addr(sram_addr),
		.o_start_addr(sta_addr),
		.o_end_addr(end_addr),
		.o_SRAMDQ(sram_dat),
		.o_is_full(fin)
	);

	initial begin
		$fsdbDumpfile("lab3_i2s.fsdb");
		$fsdbDumpvars;
		#(2*CLK)	//initial at left channel
		@(negedge clk)
		lrc = 0;
		@(posedge clk)
		sta = 1;
		#(CLK)
		sta = 0;
		for(int j=0;j<1100000;++j) begin
			@(negedge clk)
			#(SAMP*CLK)	//turn to right channel
			lrc = 1;
			#(SAMP*CLK)
			lrc = 0 ;
			// begin transmit 
			for(int i=0;i<16;++i) begin
			#(CLK)
			adc_dat <= dat[15-i];
			end
		end

		#(SAMP*CLK)	//turn to right channel
		lrc = 1;
		$display("data=%10h at %8h , next=%6h",sram_dat,sram_addr-1,sram_addr);
		$finish;
	end

	/*initial begin
		#(300*CLK)
		//$display("Too slow, abort.");
		//$finish;
	end*/

endmodule
