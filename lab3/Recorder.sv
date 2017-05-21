module Recorder(
  input   i_ready,            // wait for initialization to be finished
  input   [3:0] i_key,        // buttons on main board
                              // play/pause(key3), stop(key2), record(key1)
  input   [4:0] i_sw,         // Control speed(0~3) interpolation(4)
  input   i_rst,              // reset(key0)
  input   i_bclk,             // WM8731 clock
  inout   i_adclrc,           // WM8731 L/R channel (recording)
  inout   i_daclrc,           // WM8731 L/R channel (playing)
  input   i_adcdat,           // WM8731 data (recording)
  output  o_dacdat,           // WM8731 data (playing)
	output  [6:0] o_led,
	output	[5:0] o_adcled,
  output  [4:0] o_second,     // display time
	output	[2:0] o_show_state,
  output  [4:0] o_state,      // SRAM states (WE, CE, OE, LB, UB)
  output  [19:0] o_addr,      // SRAM address
  inout   [15:0] io_dq        // SRAM data
);

  localparam S_PREPARING = 0;
  localparam S_INIT      = 1;
  localparam S_REC       = 2;
  localparam S_REC_II    = 3;
  localparam S_IDLE      = 4;
  localparam S_PLAY      = 5;
  localparam S_PLAY_II   = 6;

  logic [3:0] speed;
  logic [2:0] state_r, state_w;
  logic [4:0] sram_state_r, sram_state_w;
  logic [4:0] sram_state_adc, sram_state_dac;
  logic [19:0] sram_addr_r, sram_addr_w;
  logic [19:0] sram_addr_adc, sram_addr_dac;
  logic [19:0] end_addr;
  logic [15:0] i_dq, o_dq;
	logic set_record, set_play, set_stop, set_pause;
  logic set_record_w, set_play_w, set_stop_w, set_pause_w;
	logic set_record_r, set_play_r, set_stop_r, set_pause_r;
	logic adclrc, daclrc;
	logic [6:0] o_led_w, o_led_r;
	logic bclk_1, bclk_2;
	
	assign bclk_1 = i_bclk;
	assign bclk_2 = i_bclk;
	
  ADC adc(
    .i_rst(i_rst),
    .i_bclk(bclk_1),
    .i_adclrc(adclrc),
    .i_adcdat(i_adcdat),
    .i_record(set_record),
    .i_stop(set_stop),
    .i_pause(set_pause),
    .o_state(sram_state_adc),
    .o_addr(sram_addr_adc),
    .o_dq(o_dq),
    .o_last(end_addr),
		.o_adcled(o_adcled)
  );

  DAC dac(
    .i_rst(i_rst),
    .i_bclk(bclk_2),
    .i_daclrc(daclrc),
    .i_play(set_play),
    .i_stop(set_stop),
    .i_pause(set_pause),
    .i_fast(i_sw[0]),
    .i_inter(i_sw[4]),
    .i_speed(speed+1),
    .i_dq(i_dq),
    .i_last(end_addr),
		.o_dacdat(o_dacdat),
    .o_state(sram_state_dac),
    .o_addr(sram_addr_dac)
  );

	assign io_dq        = (state_r == S_REC || state_r == S_REC_II) ? o_dq: 16'bzzzzzzzzzzzzzzzz;
  assign o_state      = sram_state_r;
  assign o_addr       = sram_addr_r;
  assign o_second     = sram_addr_r[19:15];
	assign o_show_state = state_r;
  assign speed[0]     = i_sw[1];
  assign speed[1]     = i_sw[2];
  assign speed[2]     = i_sw[3];
	assign o_led        = o_led_r;
	assign set_record   = set_record_r;
	assign set_play     = set_play_r;
	assign set_stop     = set_stop_r;
	assign set_pause    = set_pause_r;
	
  always_comb begin
    state_w       = state_r;
    sram_state_w  = 5'b01000;
    sram_addr_w   = 20'b0;
    set_record_w  = 1'b0;
    set_play_w    = 1'b0;
    set_stop_w    = 1'b0;
		set_pause_w 	= 1'b0;
		o_led_w				= o_led_r;
		
    case (state_r)
      S_PREPARING: begin
				o_led_w[0] = 1;
        if (i_ready == 1) begin
          state_w     = S_INIT;
          set_stop_w  = 1'b1;
        end
      end

      S_INIT: begin
				o_led_w[1] = 1;
        if (i_key[1]) begin
          state_w      = S_REC;
          set_record_w = 1'b1;
        end
      end

      S_REC: begin
        o_led_w[2] = 1;
				if (i_key[1]) begin
          state_w     = S_REC_II;
          set_pause_w = 1'b1;
        end
        else if (i_key[2]) begin
          state_w     = S_IDLE;
          set_stop_w  = 1'b1;
        end
        sram_state_w  = sram_state_adc;
        sram_addr_w   = sram_addr_adc;
      end

      S_REC_II: begin
        o_led_w[3] = 1;
				if (i_key[1]) begin
          state_w     = S_REC;
          set_record_w = 1'b1;
        end
        else if (i_key[2]) begin
          state_w     = S_IDLE;
          set_stop_w  = 1'b1;
        end
        sram_state_w  = sram_state_adc;
        sram_addr_w   = sram_addr_adc;
      end

      S_IDLE: begin
        o_led_w[4] = 1;
				if (i_key[1]) begin
          state_w     = S_REC;
          set_record_w = 1'b1;
        end
        else if (i_key[3]) begin
          state_w     = S_PLAY;
          set_play_w  = 1'b1;
        end
      end

      S_PLAY: begin
        o_led_w[5] = 1;
				if (i_key[3]) begin
          state_w     = S_PLAY_II;
          set_pause_w = 1'b1;
        end
        else if (i_key[2]) begin
          state_w     = S_IDLE;
          set_stop_w  = 1'b1;
        end
        sram_state_w  = sram_state_dac;
        sram_addr_w   = sram_addr_dac;
      end

      S_PLAY_II: begin
        o_led_w[6] = 1;
				if (i_key[3]) begin
          state_w     = S_PLAY;
          set_pause_w = 1'b1;
        end
        else if (i_key[2]) begin
          state_w     = S_IDLE;
          set_stop_w  = 1'b1;
        end
        sram_state_w  = sram_state_dac;
        sram_addr_w   = sram_addr_dac;
      end
    endcase
  end

  always_ff @(posedge i_bclk or negedge i_rst) begin
    if (!i_rst) begin
      i_dq          <= io_dq;
      state_r       <= 0;
      sram_state_r  <= sram_state_w;
      sram_addr_r   <= 0;
			adclrc				<= i_adclrc;
			daclrc				<= i_daclrc;
			o_led_r				<= 7'b0000001;
			set_record_r  <= 0;
			set_play_r    <= 0;
			set_stop_r    <= 0;
			set_pause_r   <= 0;
    end else begin
      i_dq          <= io_dq;
      state_r       <= state_w;
      sram_state_r  <= sram_state_w;
      sram_addr_r   <= sram_addr_w;
			adclrc				<= i_adclrc;
			daclrc				<= i_daclrc;
			o_led_r				<= o_led_w;
			set_record_r  <= set_record_w;
			set_play_r    <= set_play_w;
			set_stop_r    <= set_stop_w;
			set_pause_r   <= set_pause_w;
    end
  end

endmodule
