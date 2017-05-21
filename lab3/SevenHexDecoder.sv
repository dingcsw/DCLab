module SevenHexDecoder(
  input  [4:0] i_second,
	input  [2:0] i_state,
	input  [1:0] i_i2c_state,
	output logic [6:0] o_seven_i2c_state,
	output logic [6:0] o_seven_state,
  output logic [6:0] o_seven_ten,
  output logic [6:0] o_seven_one
) /*synthesis noprune*/ /*synthesis preserve*/ /*synthesis keep*/;

  parameter D0 = 7'b1000000;
  parameter D1 = 7'b1111001;
  parameter D2 = 7'b0100100;
  parameter D3 = 7'b0110000;
  parameter D4 = 7'b0011001;
  parameter D5 = 7'b0010010;
  parameter D6 = 7'b0000010;
  parameter D7 = 7'b1011000;
  parameter D8 = 7'b0000000;
  parameter D9 = 7'b0010000;

  always_comb begin
    case(i_second)
      5'd0: begin o_seven_ten = D0; o_seven_one = D0; end
      5'd1: begin o_seven_ten = D0; o_seven_one = D1; end
      5'd2: begin o_seven_ten = D0; o_seven_one = D2; end
      5'd3: begin o_seven_ten = D0; o_seven_one = D3; end
      5'd4: begin o_seven_ten = D0; o_seven_one = D4; end
      5'd5: begin o_seven_ten = D0; o_seven_one = D5; end
      5'd6: begin o_seven_ten = D0; o_seven_one = D6; end
      5'd7: begin o_seven_ten = D0; o_seven_one = D7; end
      5'd8: begin o_seven_ten = D0; o_seven_one = D8; end
      5'd9: begin o_seven_ten = D0; o_seven_one = D9; end
      5'd10: begin o_seven_ten = D1; o_seven_one = D0; end
      5'd11: begin o_seven_ten = D1; o_seven_one = D1; end
      5'd12: begin o_seven_ten = D1; o_seven_one = D2; end
      5'd13: begin o_seven_ten = D1; o_seven_one = D3; end
      5'd14: begin o_seven_ten = D1; o_seven_one = D4; end
      5'd15: begin o_seven_ten = D1; o_seven_one = D5; end
      5'd16: begin o_seven_ten = D1; o_seven_one = D6; end
      5'd17: begin o_seven_ten = D1; o_seven_one = D7; end
      5'd18: begin o_seven_ten = D1; o_seven_one = D8; end
      5'd19: begin o_seven_ten = D1; o_seven_one = D9; end
      5'd20: begin o_seven_ten = D2; o_seven_one = D0; end
      5'd21: begin o_seven_ten = D2; o_seven_one = D1; end
      5'd22: begin o_seven_ten = D2; o_seven_one = D2; end
      5'd23: begin o_seven_ten = D2; o_seven_one = D3; end
      5'd24: begin o_seven_ten = D2; o_seven_one = D4; end
      5'd25: begin o_seven_ten = D2; o_seven_one = D5; end
      5'd26: begin o_seven_ten = D2; o_seven_one = D6; end
      5'd27: begin o_seven_ten = D2; o_seven_one = D7; end
      5'd28: begin o_seven_ten = D2; o_seven_one = D8; end
      5'd29: begin o_seven_ten = D2; o_seven_one = D9; end
      5'd30: begin o_seven_ten = D3; o_seven_one = D0; end
      5'd31: begin o_seven_ten = D3; o_seven_one = D1; end
    endcase
		
		case(i_state)
      3'd0: begin o_seven_state = D0; end
      3'd1: begin o_seven_state = D1; end
      3'd2: begin o_seven_state = D2; end
      3'd3: begin o_seven_state = D3; end
      3'd4: begin o_seven_state = D4; end
      3'd5: begin o_seven_state = D5; end
      3'd6: begin o_seven_state = D6; end
      3'd7: begin o_seven_state = D7; end
    endcase
		
		case(i_i2c_state)
      2'd0: begin o_seven_i2c_state = D0; end
      2'd1: begin o_seven_i2c_state = D1; end
      2'd2: begin o_seven_i2c_state = D2; end
      2'd3: begin o_seven_i2c_state = D3; end
    endcase	
		
  end
  
endmodule
