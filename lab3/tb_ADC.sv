`timescale 1ns/100ps

module tb;
  localparam CLK = 10;
  localparam HCLK = CLK/2;
  localparam SAMP = 20;
  logic clk,rec,adclrc,adcdat,stop,pause;
  logic [4:0] state;
  logic [19:0] sramaddr;
  logic [15:0] sramdq;
  logic [19:0] lastaddr;

  initial clk = 0;
  always #HCLK clk = ~clk;
  localparam dat = 16'hac54;

  ADC adc(
    .i_bclk(clk),
    .i_adclrc(adclrc),
    .i_adcdat(adcdat),
    .i_record(rec),
    .i_stop(stop),
    .i_pause(pause),
    .o_state(state),
    .o_addr(sramaddr),
    .o_dq(sramdq),
    .o_last(lastaddr)
  );

  initial begin
    $fsdbDumpfile("lab3_adc.fsdb");
    $fsdbDumpvars;
    #(2*CLK)
    @(negedge clk)
    adclrc = 0;
    @(posedge clk)
    rec = 1;
    #(CLK)
    rec = 0;
    for (int j=0;j<1100000;j++)begin
      @(negedge clk)
      #(SAMP*CLK)
      adclrc = 1;
      #(SAMP*CLK)
      adclrc = 0;
      for (int i=0;i<16;i++) begin
        #(CLK)
        adcdat <= dat[15-i];
      end
    end

    #(SAMP*CLK)
    adclrc = 1;
    $display("data=%10h at %8h , next=%6h" , sramdq,sramaddr-1,sramaddr);
  end

endmodule
