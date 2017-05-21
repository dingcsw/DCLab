module I2C(
  input   i_clk,
  input   i_start,
  input   i_rst,
  output  o_sclk,
  output  o_ready,
	output  [1:0] o_state,
	output	[3:0] o_led,
  inout   io_sdat
) /*synthesis noprune*/ /*synthesis preserve*/ /*synthesis keep*/;

// initialize WM8731 settings
parameter bit [23:0] Init_Data [0:9] = '{
  24'b0011010_0_000_0000_0_1001_0111,
  24'b0011010_0_000_0001_0_1001_0111,
  24'b0011010_0_000_0010_0_0111_1001,
  24'b0011010_0_000_0011_0_0111_1001,
  24'b0011010_0_000_0100_0_0001_0101,
  24'b0011010_0_000_0101_0_0000_0000,
  24'b0011010_0_000_0110_0_0000_0000,
  24'b0011010_0_000_0111_0_0100_0010,
  24'b0011010_0_000_1000_0_0001_1001,
  24'b0011010_0_000_1001_0_0000_0001
};

localparam IDLE = 0;
localparam NEXT = 1;
localparam SEND = 2;
localparam FINISH = 3;

logic[1:0]    state_w,state_r;
logic[4:0]    bits_counter_w,bits_counter_r;
logic[3:0]    data_counter_w,data_counter_r;
logic         sclk_w,sclk_r;
logic         sdat_w,sdat_r;
logic         clk_counter_w,clk_counter_r;
logic[23:0]   tx_data_r,tx_data_w;
logic         oe_w,oe_r;
logic					o_ready_w,o_ready_r; 
logic[3:0]		led_w, led_r;

assign o_sclk = sclk_r;
assign io_sdat = oe_r ? sdat_r : 1'bz;
assign o_ready = o_ready_r;
assign o_state = state_r;
assign o_led = led_r;

always_comb begin
	state_w = state_r;
	bits_counter_w = bits_counter_r;
	data_counter_w = data_counter_r;
	sclk_w = sclk_r;
	clk_counter_w = clk_counter_r;
	tx_data_w = tx_data_r;
	oe_w = oe_r;
	sdat_w = sdat_r;
	o_ready_w = o_ready_r;
	led_w = led_r;

  case(state_r)
    IDLE: begin
      //IDLE
			led_w[0] = 1;
      if(i_start==1) begin
        state_w = NEXT;
        tx_data_w = Init_Data[data_counter_r];
      end
    end

    NEXT: begin
      //ready to send
			led_w[1] = 1;
			if (sdat_r == 1) begin
				sdat_w = 0;
			end else begin
				state_w = SEND;
				data_counter_w = data_counter_r + 1;
				sclk_w = 0;
				clk_counter_w = 1'b1;
				bits_counter_w = 0;
			end
    end

    SEND: begin
      //send data
			led_w[2] = 1;
			
			case(clk_counter_r)
				1'b0: begin
					if (bits_counter_r == 28) begin
						clk_counter_w = 1'b0;
						bits_counter_w = 29;
						sdat_w = 0;
					end else if (bits_counter_r == 29) begin
						if (data_counter_r == 10) begin
							state_w = FINISH;
							sdat_w = 1;
						end else begin
							sdat_w = 1;
							state_w = NEXT;
							tx_data_w = Init_Data[data_counter_r];
						end
					end else begin
						clk_counter_w = 1'b1;
					end
					sclk_w = 1;
				end
				1'b1: begin
					clk_counter_w = 1'b0;
					sclk_w = 0;
					if (bits_counter_r == 8 || bits_counter_r == 17 || bits_counter_r == 26) begin
						oe_w = 0;
					end else if (bits_counter_r == 27) begin 
						oe_w = 1;
						sdat_w = 0;
					end else begin
						oe_w = 1;
						sdat_w = tx_data_r[23];
						tx_data_w = tx_data_r << 1;
					end
					bits_counter_w = bits_counter_r + 1;
				end
			endcase
	  end

    FINISH: begin
			led_w[3] = 1;
      o_ready_w = 1;
			sdat_w = 1;
			sclk_w = 1;
    end
		endcase
end

always_ff @(posedge i_clk or negedge i_rst) begin
  if(!i_rst) begin
    state_r <= IDLE;
    bits_counter_r <= 0;
    data_counter_r <= 0;
    sclk_r <= 1;
    clk_counter_r <= 0;
    tx_data_r <= 0;
    sdat_r <= 1;
    oe_r <= 1;
		o_ready_r <= 0;
		led_r <= 4'b0000;
  end else begin
    state_r <= state_w;
    bits_counter_r <= bits_counter_w;
    data_counter_r <= data_counter_w;
    sclk_r <= sclk_w;
    clk_counter_r <= clk_counter_w;
    tx_data_r <= tx_data_w;
    sdat_r <= sdat_w;
    oe_r <= oe_w;
		o_ready_r <= o_ready_w;
		led_r <= led_w;
  end
end
endmodule
