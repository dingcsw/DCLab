module DAC(
  input   i_rst,
  input   i_bclk,
  input   i_daclrc,
  input   i_play,
  input   i_stop,
  input   i_pause,
  input   i_fast,
  input   i_inter,
  input   [3:0]  i_speed,
  input   [15:0] i_dq,
  input   [19:0] i_last,      // Last Address to be played
  output  o_dacdat,
  output  [4:0] o_state,      // SRAM states (CE, OE, WE, UB, LB)
  output  [19:0] o_addr       // SRAM address
);

  parameter IDLE      = 0;
  parameter WAIT      = 1;
  parameter PLAY_FAST = 2;
  parameter PLAY_SLOW = 3;
  parameter PAUSE     = 4;
	parameter WAIT_PLAY = 5;

  logic[2:0]    state_w,state_r;
  logic[3:0]    data_counter_w,data_counter_r;
  logic[15:0]   data_w,data_r,old_w,old_r,inter_w,inter_r;
  logic[19:0]   addr_w,addr_r;
  logic[4:0]    SRAM_state_w,SRAM_state_r;
  logic         block_w,block_r;
  logic         pause_w,pause_r,stop_w,stop_r;
  logic[3:0]    speed_w,speed_r;
	logic					temp_w,temp_r;

  assign o_addr = addr_r;
  assign o_state = SRAM_state_r;
  assign o_dacdat = (i_inter) ? inter_r[15] : old_r[15];

  always_comb begin
    state_w = state_r;
    data_counter_w = data_counter_r;
    data_w = data_r;
    old_w = old_r;
    addr_w = addr_r;
    SRAM_state_w = SRAM_state_r;
    block_w = block_r;
    pause_w = pause_r;
    stop_w = stop_r;
    speed_w = speed_r;
		inter_w = inter_r;
		temp_w = temp_r;

    case(state_r)
      IDLE: begin
        addr_w = 0;
        data_counter_w = 0;
        speed_w = 0;
        if(i_play) begin
          state_w = WAIT;
        end
      end

      WAIT: begin
				data_w = i_dq;
        if(!i_daclrc) begin
					old_w = data_r;
          if(i_fast) begin    // play fast
            state_w = PLAY_FAST;
            if (addr_r + i_speed > i_last) addr_w = i_last;
            else addr_w = addr_r + i_speed;
          end
          else begin          // play slow
            if (addr_r == i_last)
              state_w = IDLE;
            else begin
              state_w = PLAY_SLOW;
              addr_w = addr_r + 1;
              inter_w = data_r + (i_dq - data_r) * signed'(speed_r) / signed'(i_speed);
            end
          end
        end
        if(i_pause) state_w = PAUSE;
        else if(i_stop) state_w = IDLE;
        if(addr_r == 0) state_w = WAIT;
      end

      PLAY_FAST: begin
        old_w = old_r << 1;
        old_w[0] = 0;

        if(data_counter_r == 15) begin

          state_w = WAIT;
          data_counter_w = 0;
          
          if(!i_daclrc) begin
            state_w = WAIT_PLAY;
            temp_w = old_w[15];
            old_w[15] = 0;
          end

          if(pause_r || i_pause) state_w = PAUSE;
          else if(stop_r || i_stop || addr_r == i_last) state_w = IDLE; // Add last addr

        end
        else  data_counter_w = data_counter_r + 1;

        if(i_stop) stop_w = 1;
        else if(i_pause) pause_w = 1;
      end

      PLAY_SLOW: begin
        if(i_inter) begin
          inter_w = inter_r << 1;
          inter_w[0] = 0;
          if(data_counter_r == 15) begin
            data_counter_w = 0;
            if(!i_daclrc) begin
              state_w = WAIT_PLAY;
              temp_w = inter_w[15];
              inter_w[15] = 0;
            end else begin
              inter_w[15] = 0;
              if(speed_r == i_speed - 1) begin
                state_w = WAIT;
                speed_w = 0;
              end
              else begin
                speed_w = speed_r + 1;
                state_w = WAIT;
                addr_w = addr_r - 1;
              end
              if(pause_r || i_pause) state_w = PAUSE;
              else if(stop_r || i_stop) state_w = IDLE;
            end
          end
        end
        else begin
          old_w = old_r << 1;
          old_w[0] = old_r[15];
          if(data_counter_r == 15) begin
            data_counter_w = 0;

            if(!i_daclrc)begin
                state_w = WAIT_PLAY;
                temp_w = old_w[15];
								old_w[15] = 0;
            end else begin
              if(speed_r == i_speed - 1) begin
                if(addr_r == i_last) state_w = IDLE;
							  else begin
								  old_w[15] = 0;
								  state_w = WAIT;
							  end
              end
              else begin
                speed_w = speed_r + 1;
                addr_w = addr_r - 1;
                state_w = WAIT;
            end
					

            if(pause_r || i_pause) state_w = PAUSE;
            else if(stop_r || i_stop) state_w = IDLE;

          end
					else  data_counter_w = data_counter_r + 1;
        end

        if(i_stop) stop_w = 1;
        else if(i_pause) pause_w = 1;
      end

      PAUSE: begin
        pause_w = 0;
        if(i_play) begin
          state_w = WAIT;
        end else if (i_stop) begin
          state_w = IDLE;
        end
      end
			
			WAIT_PLAY: begin
				if(i_daclrc) begin
          if(!i_fast) begin
					  state_w = PLAY_SLOW;
            if(i_inter) begin
              inter_w[15] = temp_r;
              temp_w = 0;
            end else begin
					    old_w[15] = temp_r;
					    temp_w = 0;
            end
          end
          else begin
            state_w = PLAY_FAST;
					  old_w[15] = temp_r;
					  temp_w = 0;            
          end
				end
			end
    endcase
  end



  always_ff@(posedge i_bclk or negedge i_rst) begin
    if(!i_rst) begin
      state_r <= IDLE;
      data_counter_r <= 0;
      data_r <= 0;
      addr_r <= 0;
      SRAM_state_r <= 5'b10000;
      block_r <= 0;
      pause_r <= 0;
      stop_r <= 0;
      speed_r <= 0;
      inter_r <= 0;
			old_r <= 0;
			temp_r <= 0;
    end
    else begin
      state_r <= state_w;
      data_counter_r <= data_counter_w;
      data_r <= data_w;
      addr_r <= addr_w;
      SRAM_state_r <= SRAM_state_w;
      block_r <= block_w;
      pause_r <= pause_w;
      stop_r <= stop_w;
      speed_r <= speed_w;
      inter_r <= inter_w;
			old_r <= old_w;
			temp_r <= temp_w;
    end
  end
endmodule
