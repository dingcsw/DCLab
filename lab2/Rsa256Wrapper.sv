module Rsa256Wrapper(
	input avm_rst,
	input avm_clk,
	output [4:0] avm_address,
	output avm_read,
	input [31:0] avm_readdata,
	output avm_write,
	output [31:0] avm_writedata,
	input avm_waitrequest
);
	localparam RX_BASE     = 0*4;
	localparam TX_BASE     = 1*4;
	localparam STATUS_BASE = 2*4;
	localparam TX_OK_BIT = 6;
	localparam RX_OK_BIT = 7;

	localparam S_GET_KEY = 0;
	localparam S_GET_DATA = 1;
	localparam S_WAIT_CALCULATE = 2;
	localparam S_SEND_DATA = 3;

	logic [255:0] n_r, n_w, e_r, e_w, enc_r, enc_w, dec_r, dec_w;
	logic [1:0] state_r, state_w;
	logic [6:0] bytes_counter_r, bytes_counter_w;
    logic [6:0] n_counter_r, n_counter_w, e_counter_r, e_counter_w;
	logic [4:0] avm_address_r, avm_address_w;
	logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

	logic rsa_start_r, rsa_start_w;
	logic rsa_finished;
	logic [255:0] rsa_dec;

	assign avm_address = avm_address_r;
	assign avm_read = avm_read_r;
	assign avm_write = avm_write_r;
	assign avm_writedata = dec_r[247-:8];

	Rsa256Core rsa256_core(
		.i_clk(avm_clk),
		.i_rst(avm_rst),
		.i_start(rsa_start_r),
		.i_a(enc_r),
		.i_e(e_r),
		.i_n(n_r),
		.o_a_pow_e(rsa_dec),
		.o_finished(rsa_finished)
	);

	task StartRead;
		input [4:0] addr;
		begin
			avm_read_w = 1;
			avm_write_w = 0;
			avm_address_w = addr;
		end
	endtask
	task StartWrite;
		input [4:0] addr;
		begin
			avm_read_w = 0;
			avm_write_w = 1;
			avm_address_w = addr;
		end
	endtask

	always_comb begin
		// TODO
	    n_w = n_r;
        e_w = e_r;
        enc_w = enc_r;
        dec_w = dec_r;
        avm_address_w = avm_address_r;
        avm_read_w = avm_read_r;
        avm_writer_w = avm_writer_r;
        state_w = state_r;
        bytes_counter_w = bytes_counter_r;
        rsa_start_w = ras_start_r;
        
        case (state_r)
            S_GET_KEY: begin
                StartRead(STATUS_BASE);
                if(avm_wait_request == 1'b0) begin
                    if(avm_readdata[RX_OK_BIT] == 1'b1) begin
                        StartRead(RX_BASE);
                        state_w = S_GET_DATA;
                    end else if (avm_readdata[TX_OK_BIT] == 1'b1) begin
                        StartWrite(TX_BASE);
                        state_w = S_SEND_DATA;
                    end
                end        
            end
            
            S_GET_DATA: begin
                if(avm_wait_request == 1'b0 && avm_read_r == 1'b1) begin
                    state_w = S_GET_KEY; 
                    avm_read_w = 0;

                    if(n_counter_w > 31) begin 
                        n_w = n_w << 8;
                        n_w[7:0] = readdata[7:0];
                        n_counter_w --;
                    end else if(e_counter_w > 31) begin
                        e_w = e_w << 8;
                        e_w[7:0] = readdata[7:0];
                        e_counter_w --;
                    end else if(bytes_counter_w >= 0) begin
                        enc_w = enc_w << 8;
                        enc_w[7:0] = readdata[7:0];
                        if(bytes_counter_w == 0) begin
                            rsa_start_w = 1;
                            state_w = S_WAIT_CALCULATE;
                            bytes_counter_w = 63;
                            n_counter_w = 63;
                            e_counter_w = 63;
                        end else 
                            bytes_counter_w --;
                    end              
            end
   
            S_WAIT_CALCULATE: begin
                if(rsa_finished) begin
                    rsa_start_w = 0;
                    state_w = S_GET_KEY;
                    dec_w = rsa_dec;
                end
            end

            S_SEND_DATA: begin
                if(avm_wait_request == 1'b0 && avm_write_w == 1'b1) begin
                    state_w = S_GET_KEY;
                    avm_write_w = 0;
                    bytes_counter_w --;
                    dec_w = dec_w >> 8;
                    writedata[7:0] = dec_w[7:0];
                    if(bytes_counter_w == 0) begin
                        state_w = S_GET_KEY;
                        bytes_counter_w = 63;
                    end
                end
            end
    end

	always_ff @(posedge avm_clk or posedge avm_rst) begin
		if (avm_rst) begin
			n_r <= 0;
			e_r <= 0;
			enc_r <= 0;
			dec_r <= 0;
			avm_address_r <= STATUS_BASE;
			avm_read_r <= 1;
			avm_write_r <= 0;
			state_r <= S_GET_KEY;
			bytes_counter_r <= 63;
            n_counter_r <= 63;
            e_counter_r <= 63;
			rsa_start_r <= 0;
		end else begin
			n_r <= n_w;
			e_r <= e_w;
			enc_r <= enc_w;
			dec_r <= dec_w;
			avm_address_r <= avm_address_w;
			avm_read_r <= avm_read_w;
			avm_write_r <= avm_write_w;
			state_r <= state_w;
			bytes_counter_r <= bytes_counter_w;
			n_counter_r <= n_counter_w;
            e_counter_r <= e_counter_w;
            rsa_start_r <= rsa_start_w;
		end
	end
endmodule
