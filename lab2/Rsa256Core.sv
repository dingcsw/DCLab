module Rsa256Core(
	input i_clk,
	input i_rst,
	input i_start,
	input [255:0] i_a,
	input [255:0] i_e,
	input [255:0] i_n,
	output [255:0] o_a_pow_e,
	output o_finished
);

	logic [255:0] a_r, a_w, e_r, e_w, n_r, n_w;
	logic [255:0] output_r, output_w;
	logic [8:0]   count_r, count_w;
	logic         fin_r, fin_w;

	logic         start_pre_r,start_pre_w;
	logic         finish_pre;
	logic [255:0] result_pre;
	logic [255:0] temp_pre_r, temp_pre_w;

	logic         start_mont1_r, start_mont1_w;
	logic         start_mont2_r, start_mont2_w;
	logic         finish_mont1;
	logic         finish_mont2;
	logic [255:0] result_mont1, result_mont2;
	logic [255:0] cal_r, cal_w;
	logic [255:0] a_mont1_r, a_mont1_w, b_mont1_r, b_mont1_w, mont2_r, mont2_w;
	logic [1:0]   hi_w, hi_r;
	enum {S_IDLE, S_PRESET, S_CAL, S_WAIT, S_END} state_r, state_w;

    assign o_a_pow_e = output_r;
    assign o_finished = fin_r;

    ModuloProduct mp(
    	.i_clk(i_clk),
    	.i_start(start_pre_r),
    	.i_rst(i_rst),
    	.i_a({1'b0,a_r}),
    	.i_n({1'b0,n_r}),
    	.o_product(result_pre),
    	.o_finished(finish_pre)
	);

    Montgomery m1 (
    	.i_clk(i_clk),
    	.i_start(start_mont1_r),
    	.i_rst(i_rst),
    	.i_a(a_mont1_r),
    	.i_b(b_mont1_r),
    	.i_n(n_r),
    	.o_mon(result_mont1),
    	.o_mon_fin(finish_mont1)
	);

	Montgomery m2 (
    	.i_clk(i_clk),
    	.i_start(start_mont2_r),
    	.i_rst(i_rst),
    	.i_a(mont2_r),
    	.i_b(mont2_r),
    	.i_n(n_r),
    	.o_mon(result_mont2),
    	.o_mon_fin(finish_mont2)
	);

    always_comb begin
        state_w = state_r;
        output_w = output_r;
        count_w = count_r;
        fin_w = fin_r;
        a_w = a_r;
        e_w = e_r;
        n_w = n_r;
		cal_w = cal_r;
		start_pre_w = start_pre_r;
		temp_pre_w = temp_pre_r;
		start_mont1_w = start_mont1_r;
		start_mont2_w = start_mont2_r;
		a_mont1_w = a_mont1_r;
		b_mont1_w = b_mont1_r;
		mont2_w = mont2_r;
		hi_w = hi_r;

        case (state_r)
            S_IDLE: begin
                count_w = 0;
				fin_w = 0;

                if (i_start) begin
                    output_w = 1;
                    a_w = i_a;
                    e_w = i_e;
                    n_w = i_n;
                    cal_w   = 1;
                    state_w = S_PRESET;
                end
            end

            S_PRESET: begin
                start_pre_w = 1;
                if (finish_pre == 1) begin
                    temp_pre_w = result_pre;
					start_pre_w = 0;
					state_w = S_CAL;
				end
            end
            // check e's bit is 1 or 0
			S_CAL: begin
				if (e_r[count_r]) begin
					start_mont1_w = 1;
					a_mont1_w = cal_r;
					b_mont1_w = temp_pre_r;
				end else begin
					hi_w = hi_r + 1;
				end

				start_mont2_w = 1;
				mont2_w = temp_pre_r;

				state_w = S_WAIT;
			end

			S_WAIT: begin
				start_mont1_w = 0;
				start_mont2_w = 0;

				if (finish_mont1) begin
					cal_w = result_mont1;
					output_w = result_mont1;
					hi_w[0] = 1;
				end

				if (finish_mont2) begin
					hi_w[1] = 1;
					temp_pre_w = result_mont2;
				end

				if (hi_r == 3) begin
					if (count_r == 255) begin
						fin_w = 1;
						count_w = 0;
						hi_w = 0;
						state_w = S_END;
					end else begin
						count_w = count_r + 1;
						state_w = S_CAL;
						hi_w = 0;
					end
				end
			end

			S_END: begin
				state_w = S_IDLE;
				fin_w = 0;
			end

            default: begin

            end
        endcase
    end

    always_ff @(posedge i_clk or posedge i_rst) begin

        if (i_rst) begin
            output_r <= output_w;
            count_r  <= 0;
            state_r  <= S_IDLE;
            fin_r    <= 0;
				start_mont1_r <= 0;
				start_mont2_r <= 0;
				start_pre_r <= 0;
        end else begin
			start_pre_r  	<= start_pre_w;
			temp_pre_r   	<= temp_pre_w;

			start_mont1_r	<= start_mont1_w;
			start_mont2_r	<= start_mont2_w;
            output_r     <= output_w;
            state_r      <= state_w;
            count_r      <= count_w;
            fin_r        <= fin_w;
            a_r          <= a_w;
            e_r          <= e_w;
            n_r          <= n_w;
			cal_r        <= cal_w;
			a_mont1_r    <= a_mont1_w;
			b_mont1_r    <= b_mont1_w;
			mont2_r      <= mont2_w;
			hi_r		 <= hi_w;
        end
    end

endmodule

module ModuloProduct(
    input           i_clk,
    input           i_start,
    input           i_rst,
    input[256:0]    i_a,
    input[256:0]    i_n,
    output[255:0]   o_product,
    output          o_finished
);

	 logic[256:0]	  a_r, a_w;
    logic[8:0]      count_r, count_w;
    logic           fin_r, fin_w;
    logic[256:0]    out_r, out_w;
	logic[256:0]	temp1_r, temp1_w, temp2_r,temp2_w; 
	

    enum {S_IDLE, S_RUN, S_END} state_r, state_w;

    assign o_product = out_r[255:0];
    assign o_finished = fin_r;

    always_comb begin
        state_w = state_r;
        count_w = count_r;
        fin_w   = fin_r;
        out_w   = out_r;
		a_w     = a_r;
		temp1_w = temp1_r;
		temp2_w = temp2_r;

        case (state_r)
            S_IDLE: begin
                count_w = 0;
				temp1_w = 0;
				temp2_w = 0;

                if (i_start) begin
                    fin_w = 0;
                    out_w = 0;
                    a_w  = i_a;
                    state_w = S_RUN;
                end
            end

            S_RUN: begin
				if (count_r == 0) begin
					temp1_w = a_r;
					temp2_w = a_r << 1;
					if (temp2_w >= i_n) temp2_w = temp2_w - i_n;

					count_w = count_r + 1;
				end else begin
					// update temp1
					temp1_w = temp2_r;
					// calculate temp2
					temp2_w = temp1_w << 1;
					if (temp2_w >= i_n) temp2_w = temp2_w - i_n;
					// Last time
					if (count_r == 256) begin
						state_w = S_END;
						fin_w = 1;
						count_w = 0;
						out_w = out_r + temp1_w;
					end else begin
						count_w = count_r + 1;
					end
				end
            end

			S_END: begin
				fin_w = 0;
				temp1_w = 0;
				temp2_w = 0;
				state_w = S_IDLE;
			end
        endcase
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state_r <= S_IDLE;
            fin_r   <= 0;
            out_r   <= 0;
            count_r <= 0;
        end else begin
            state_r <= state_w;
            fin_r   <= fin_w;
            out_r   <= out_w;
            count_r <= count_w;
            a_r     <= a_w;
			temp1_r <= temp1_w;
			temp2_r <= temp2_w;
        end
    end
endmodule

module Montgomery(
    input           i_clk,
    input           i_start,
    input           i_rst,
    input[255:0]    i_a,
    input[255:0]    i_b,
    input[255:0]    i_n,
    output[255:0]   o_mon,
    output          o_mon_fin
);

    logic[257:0]    out_r, out_w;
    logic           fin_r, fin_w;
    logic[8:0]      count_r, count_w;
    logic[255:0]    a_r, a_w;
    logic[255:0]    b_r, b_w;
    logic[255:0]    n_r, n_w;
	logic[257:0]	pre_r, pre_w;
	logic[257:0]    temp1_r, temp1_w, temp2_r, temp2_w;

    enum {S_IDLE, S_RUN, S_END} state_r, state_w;

    assign o_mon = out_r;
    assign o_mon_fin = fin_r;

    always_comb begin
        state_w = state_r;
        count_w = count_r;
        fin_w = fin_r;
		pre_w = pre_r;
        out_w = out_r;
        a_w = a_r;
        b_w = b_r;
        n_w = n_r;
		temp1_w = temp1_r;
		temp2_w = temp2_r;

        case (state_r)
            S_IDLE: begin
                count_w = 0;
				temp1_w = 0;
				temp2_w = 0;

                if (i_start) begin
                    fin_w = 0;
                    pre_w = 0;// (m)

                    a_w = i_a;
                    b_w = i_b;
                    n_w = i_n;

                    state_w = S_RUN;
                end
            end

            S_RUN: begin
                if (count_r == 256) begin
                    if (pre_r >= n_r)
                        out_w = pre_r - n_r;
					else
						out_w = pre_r;

                    fin_w = 1;
					count_w = 0;
					temp1_w = 0;
					temp2_w = 0;
                    state_w = S_END;

				end else begin
                    if(a_r[count_r])
                        temp1_w = pre_r + b_r;
					else
						temp1_w = pre_r;

                    if(temp1_w & 1)
                        temp2_w = temp1_w + n_r;
					else
						temp2_w = temp1_w;

                    pre_w  = temp2_w >> 1;
                    count_w = count_r + 1;
                end
            end

			S_END: begin
				fin_w = 0;
				temp1_w = 0;
				temp2_w = 0;
				state_w = S_IDLE;
			end
        endcase
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            state_r <= S_IDLE;
            fin_r   <= 0;
            out_r   <= 0;
            count_r <= 0;
			pre_r   <= 0;
			a_r     <= 0;
			b_r     <= 0;
			n_r     <= 0;
        end else begin
            state_r <= state_w;
            fin_r   <= fin_w;
            out_r   <= out_w;
            count_r <= count_w;
			pre_r   <= pre_w;
            a_r     <= a_w;
            b_r     <= b_w;
            n_r     <= n_w;
			temp1_r <= temp1_w;
			temp2_r <= temp2_w;
        end
    end
endmodule
