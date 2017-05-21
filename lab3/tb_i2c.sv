`timescale 1ns/100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK/2;

    logic clk, sta, fin, rst, sclk;
    wire sdat;
    logic [1:0] state;
    initial clk = 0;
    always #HCLK clk = ~clk;

    I2C core(
        .i_clk(clk),
        .i_start(sta),
        .i_rst(rst),
        .o_sclk(sclk),
        .io_sdat(sdat)
    );

    initial begin
        $fsdbDumpfile("lab3_i2c.fsdb");
        $fsdbDumpvars;
        rst = 1;
        #(2*CLK)
        rst = 0;
        //#(2*CLK)
        //rst = 1;
        for (int j = 0; j < 3; j++) begin
            @(posedge clk);
        end
        sta <= 1;
        @(posedge clk)
        sta <= 0;
        @(posedge fin)

        #(10000*CLK)
        @(posedge clk)
        rst = 1;
		// again
        @(posedge clk)
        sta <= 1;
        @(posedge clk)
        sta <= 1;
        @(posedge clk)
        sta <= 0;
        @(posedge fin)
        #(10000*CLK)
        $finish;
    end

    initial begin
        #(30000*CLK)
        $display("Too slow, abort.");
        $finish;
    end

endmodule
