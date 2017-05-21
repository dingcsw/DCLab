module ADC(
  input   i_rst,
  input   i_bclk,
  input   i_adclrc,
  input   i_adcdat,
  input   i_record,           // start & pause ?
  input   i_stop,
  input   i_pause,
  output  [4:0] o_state,      // SRAM states (CE, OE, WE, UB, LB)
  output  [19:0] o_addr,      // SRAM address
  output  [15:0] o_dq,
  output  [19:0] o_last,
	output  [5:0] o_adcled
);

  parameter IDLE  = 0;
  parameter WAIT  = 1;
  parameter GET   = 2;
  parameter SEND  = 3;
  parameter PAUSE = 4;
  parameter STOP  = 5;

  logic[2:0]    state_w,state_r;
  logic[3:0]    data_counter_w,data_counter_r;
  logic[15:0]   data_w,data_r;
  logic[19:0]   addr_w,addr_r;
  logic[19:0]   last_w,last_r;
  logic[4:0]    SRAM_state_w,SRAM_state_r;
  logic         block_w,block_r;
  logic         pause_w,pause_r,stop_w,stop_r;
	logic[5:0]    o_adcled_w,o_adcled_r;

  assign o_addr = addr_r;
  assign o_state = SRAM_state_r;
  assign o_last = last_r;
	assign o_dq = data_r;
	assign o_adcled = o_adcled_r;

  always_comb begin
    state_w = state_r;
    data_counter_w = data_counter_r;
    data_w = data_r;
    addr_w = addr_r;
    SRAM_state_w = SRAM_state_r;
    block_w = block_r;
    last_w = last_r;
    pause_w = pause_r;
    stop_w = stop_r;
		o_adcled_w = o_adcled_r;

    case(state_r)
      IDLE: begin
        //IDLE
				o_adcled_w[0] = 1;
        if(i_record) begin
          state_w = WAIT;
          last_w = 0;
        end
      end

      WAIT: begin
        //wait
				o_adcled_w[1] = 1;
				data_w = 0;
        if(i_stop) begin
          state_w = STOP;
        end else if(i_pause) begin
          state_w = PAUSE;
        end else if(!i_adclrc) begin
          state_w = GET;
          block_w = 1;
        end
      end

      GET: begin
        //get data
				o_adcled_w[2] = 1;
          /*if(block_r == 1) begin 
            block_w = 0;
					end
          else begin //block_r = 0*/
            if(data_counter_r < 16) begin
              data_w = data_r << 1;
              data_w[0] = i_adcdat;
              if(data_counter_r == 15) begin
								SRAM_state_w[3] = 0;
                state_w = SEND;
                data_counter_w = 0;
              end
              else
                data_counter_w = data_counter_r + 1;
            end
          //end
          if(i_pause) pause_w = 1;  //pause
          else if(i_stop) stop_w = 1; //stop
      end

      SEND: begin
			  o_adcled_w[3] = 1;
        //send data



        if(i_stop || addr_r == 1048575 || stop_r) begin // 1048575 ?
          state_w = STOP;
        end else if(i_pause || pause_r) begin
          state_w = PAUSE;
        end else if(i_adclrc) begin
          state_w = WAIT;
					SRAM_state_w[3] = 1;
					addr_w = addr_r + 1;

        end
      end

      PAUSE: begin
        // pause
				o_adcled_w[4] = 1;
        pause_w = 0;
        if(i_record) begin
          state_w = WAIT;
        end else if (i_stop) begin
          state_w = STOP;
        end
      end

      STOP: begin
        //stop
				o_adcled_w[5] = 1;
        stop_w = 0;
        last_w = addr_r;
        state_w = IDLE;
				addr_w = 0;
      end
    endcase
  end

  always_ff@(posedge i_bclk or negedge i_rst) begin //i_bclk is negedge in PDF ?
    if(!i_rst) begin
      state_r <= IDLE;
      data_counter_r <= 0;
      data_r <= 0;
      addr_r <= 0;
      SRAM_state_r <= 5'b01000;
      block_r <= 0;
      last_r <= 0;
      pause_r <= 0;
      stop_r <= 0;
			o_adcled_r <= 0;
    end
    else begin
      state_r <= state_w;
      data_counter_r <= data_counter_w;
      data_r <= data_w;
      addr_r <= addr_w;
      SRAM_state_r <= SRAM_state_w;
      block_r <= block_w;
      last_r <= last_w;
      pause_r <= pause_w;
      stop_r <= stop_w;
			o_adcled_r <= o_adcled_w; 
    end
  end
endmodule
