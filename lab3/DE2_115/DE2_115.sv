module DE2_115(
	input CLOCK_50,
	input CLOCK2_50,
	input CLOCK3_50,
	input ENETCLK_25,
	input SMA_CLKIN,
	output SMA_CLKOUT,
	output [8:0] LEDG,
	output [17:0] LEDR,
	input [3:0] KEY,
	input [17:0] SW,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [6:0] HEX6,
	output [6:0] HEX7,
	output LCD_BLON,
	inout [7:0] LCD_DATA,
	output LCD_EN,
	output LCD_ON,
	output LCD_RS,
	output LCD_RW,
	output UART_CTS,
	input UART_RTS,
	input UART_RXD,
	output UART_TXD,
	inout PS2_CLK,
	inout PS2_DAT,
	inout PS2_CLK2,
	inout PS2_DAT2,
	output SD_CLK,
	inout SD_CMD,
	inout [3:0] SD_DAT,
	input SD_WP_N,
	output [7:0] VGA_B,
	output VGA_BLANK_N,
	output VGA_CLK,
	output [7:0] VGA_G,
	output VGA_HS,
	output [7:0] VGA_R,
	output VGA_SYNC_N,
	output VGA_VS,
	input AUD_ADCDAT,
	inout AUD_ADCLRCK,
	inout AUD_BCLK,
	output AUD_DACDAT,
	inout AUD_DACLRCK,
	output AUD_XCK,
	output EEP_I2C_SCLK,
	inout EEP_I2C_SDAT,
	output I2C_SCLK,
	inout I2C_SDAT,
	output ENET0_GTX_CLK,
	input ENET0_INT_N,
	output ENET0_MDC,
	input ENET0_MDIO,
	output ENET0_RST_N,
	input ENET0_RX_CLK,
	input ENET0_RX_COL,
	input ENET0_RX_CRS,
	input [3:0] ENET0_RX_DATA,
	input ENET0_RX_DV,
	input ENET0_RX_ER,
	input ENET0_TX_CLK,
	output [3:0] ENET0_TX_DATA,
	output ENET0_TX_EN,
	output ENET0_TX_ER,
	input ENET0_LINK100,
	output ENET1_GTX_CLK,
	input ENET1_INT_N,
	output ENET1_MDC,
	input ENET1_MDIO,
	output ENET1_RST_N,
	input ENET1_RX_CLK,
	input ENET1_RX_COL,
	input ENET1_RX_CRS,
	input [3:0] ENET1_RX_DATA,
	input ENET1_RX_DV,
	input ENET1_RX_ER,
	input ENET1_TX_CLK,
	output [3:0] ENET1_TX_DATA,
	output ENET1_TX_EN,
	output ENET1_TX_ER,
	input ENET1_LINK100,
	input TD_CLK27,
	input [7:0] TD_DATA,
	input TD_HS,
	output TD_RESET_N,
	input TD_VS,
	inout [15:0] OTG_DATA,
	output [1:0] OTG_ADDR,
	output OTG_CS_N,
	output OTG_WR_N,
	output OTG_RD_N,
	input OTG_INT,
	output OTG_RST_N,
	input IRDA_RXD,
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output DRAM_CAS_N,
	output DRAM_CKE,
	output DRAM_CLK,
	output DRAM_CS_N,
	inout [31:0] DRAM_DQ,
	output [3:0] DRAM_DQM,
	output DRAM_RAS_N,
	output DRAM_WE_N,
	output [19:0] SRAM_ADDR,
	output SRAM_CE_N,
	inout [15:0] SRAM_DQ,
	output SRAM_LB_N,
	output SRAM_OE_N,
	output SRAM_UB_N,
	output SRAM_WE_N,
	output [22:0] FL_ADDR,
	output FL_CE_N,
	inout [7:0] FL_DQ,
	output FL_OE_N,
	output FL_RST_N,
	input FL_RY,
	output FL_WE_N,
	output FL_WP_N,
	inout [35:0] GPIO,
	input HSMC_CLKIN_P1,
	input HSMC_CLKIN_P2,
	input HSMC_CLKIN0,
	output HSMC_CLKOUT_P1,
	output HSMC_CLKOUT_P2,
	output HSMC_CLKOUT0,
	inout [3:0] HSMC_D,
	input [16:0] HSMC_RX_D_P,
	output [16:0] HSMC_TX_D_P,
	inout [6:0] EX_IO
);

	logic [3:0] keydown;
	logic [4:0] sram_state;
	logic [4:0] second_show;
	logic [2:0] state_show;
	logic [1:0] i2c_state_show;
	logic clk_100k;
	logic init_ready;
	logic aud_bclk;
	logic i2c_start_key;
	logic aud_xck;
	logic aud_bclk_1, aud_bclk_2, aud_bclk_3, aud_bclk_4;
	
	assign aud_bclk_1 = AUD_BCLK;
	assign aud_bclk_2 = AUD_BCLK;
	assign aud_bclk_3 = AUD_BCLK;
	assign aud_bclk_4 = AUD_BCLK;
	
	myclock altpll0(
		.altpll_0_c0_clk(aud_xck),		// 12M
		.altpll_0_c1_clk(clk_100k),		// 100k
		.clk_clk(CLOCK_50),
		.reset_reset_n(KEY[0])
	);
	
	Debounce de_start_i2c(
		.i_in(KEY[1]),
		.i_clk(clk_100k),
		.i_rst(KEY[0]),
		.o_neg(i2c_start_key)
	);

	// Key 1 : Record
	Debounce de1(
		.i_in(KEY[1]),
		.i_clk(aud_bclk_1),
		.i_rst(KEY[0]),
		.o_neg(keydown[1])
	);
	// Key 2 : Stop
	Debounce de2(
		.i_in(KEY[2]),
		.i_clk(aud_bclk_2),
		.i_rst(KEY[0]),
		.o_neg(keydown[2])
	);
	// Key 3 : Play/Pause
	Debounce de3(
		.i_in(KEY[3]),
		.i_clk(aud_bclk_3),
		.i_rst(KEY[0]),
		.o_neg(keydown[3])
	);

	I2C i2c(
		.i_clk(clk_100k),
  	.i_start(i2c_start_key),
  	.i_rst(KEY[0]),
  	.o_sclk(I2C_SCLK),
  	.o_ready(init_ready),
		.o_state(i2c_state_show),
		.o_led(LEDR[17:14]),
		.io_sdat(I2C_SDAT)
	);

	Recorder recorder(
		.i_ready(init_ready),
  	.i_key(keydown[3:0]),  
  	.i_sw(SW[4:0]),        
  	.i_rst(KEY[0]),      
 	  .i_bclk(aud_bclk_4),   
  	.i_adclrc(AUD_ADCLRCK),           
  	.i_daclrc(AUD_DACLRCK),        
  	.i_adcdat(AUD_ADCDAT),        
  	.o_dacdat(AUD_DACDAT),          
  	.o_second(second_show),    
  	.o_state(sram_state),   
  	.o_addr(SRAM_ADDR),
		.o_show_state(state_show),
		.o_led(LEDG[6:0]),
		.o_adcled(LEDR[5:0]),
  	.io_dq(SRAM_DQ)
	);

	SevenHexDecoder sevenHexDecoder(
  	.i_second(second_show),
		.i_state(state_show),
		.i_i2c_state(i2c_state_show),
		.o_seven_i2c_state(HEX4),
		.o_seven_state(HEX6),
  	.o_seven_ten(HEX1),
  	.o_seven_one(HEX0)
	);
	
	assign SRAM_WE_N = sram_state[4];
	assign SRAM_CE_N = sram_state[3];
	assign SRAM_OE_N = sram_state[2];
	assign SRAM_LB_N = sram_state[1];
	assign SRAM_UB_N = sram_state[0];
	assign AUD_XCK   = aud_xck;
	
	assign HEX2 = 7'b1111111;
	assign HEX3 = 7'b1111111;
	assign HEX5 = 7'b1111111;
	assign HEX7 = 7'b1111111;

endmodule
