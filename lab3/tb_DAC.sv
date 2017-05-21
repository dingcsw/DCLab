`timescale 1ns/100ps

module tb;
  localparam CLK = 10;
  localparam HCLK = CLK/2;
  localparam SAMP = 20;
  localparam KCLK = 120*CLK;
  logic clk,kclk,dacdat,daclrck,fast,inter,sta,stop,pause;
  logic [4:0] state;
  logic [15:0] sramdq;
  logic [19:0] outputaddr;
  logic [3:0] speed;

  initial clk = 0;
  initial kclk = 0;
  always #HCLK clk = ~clk;
  always #(120*CLK) kclk = ~ kclk;
  localparam dat = 16'hac54;

DAC  dac(
  .i_bclk(clk),
  .i_daclrc(daclrck),
  .i_play(sta),
  .i_stop(stop),
  .i_pause(pause),
  .i_fast(fast),
  .i_inter(inter),
  .i_speed(speed),
  .i_dq(sramdq),
  .o_dacdat(dacdat),
  .o_state(state),
  .o_addr(outputaddr)
);

initial begin
  $fsdbDumpfile("lab3_dac.fsdb");
  $fsdbDumpvars;
  #(600*CLK)
  daclrck <= 1;
  fast <= 1;
  inter <= 0;
  speed <= 4'b0001;
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
