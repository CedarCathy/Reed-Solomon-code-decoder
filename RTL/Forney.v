module Forney#(
    parameter n = 255,  //data frame length
    parameter k = 239,  //valid message length
    parameter t = 8,    //this decoder can only correct errors less than 8
    parameter m = 8     //data width
)
(
    input  wire           clk_in,
    input  wire           sys_rst_n,
    input  wire           BM_done,
    input  wire           Scalc_done,
 
    input  wire [m-1 : 0] Lambda1,
	input  wire [m-1 : 0] Lambda3,
	input  wire [m-1 : 0] Lambda5,
	input  wire [m-1 : 0] Lambda7,
   
	input  wire [m-1 : 0] Delta,
  
	output wire [m-1 : 0] Error_approx,
	output reg  [m-1 : 0] Error_approx_latch,
	output reg  [  3 : 0] end_operation_cnt
    );

    reg  [m-1 : 0] Omega       [t-1      : 0];//Omega(x)的系数
    reg  [m-1 : 0] Omega_cnt;

    reg  [m-1 : 0] Omega_reg   [t-1 : 0];
    wire [m-1 : 0] Omega_alpha [t-1 : 0];
    reg  [m-1 : 0] Omega_alpha_pow_minus_i;//存储Omega(a^-i)

    reg  [m-1 : 0] Delta_delay;
    always @(posedge clk_in) begin
        Delta_delay <= Delta;
    end

    reg  frame_start_flag;
    always @(posedge clk_in) begin
        if(Scalc_done == 1'b1) begin
            frame_start_flag <= 1'b1;
        end
        else if(BM_done == 1'b1) begin
            frame_start_flag <= 1'b0;
        end
        else begin
            frame_start_flag <= 1'b0;
        end
    end

    always @(posedge clk_in) begin
        if ((BM_done == 1'b1) && (frame_start_flag == 1'b1)) begin
            Omega_cnt <= 8'd1;
        end
        else if((Omega_cnt >= 1) && (Omega_cnt <= t)) begin
            Omega_cnt <= Omega_cnt + 1'b1;
        end
        else begin
            Omega_cnt <= 8'd0;
        end
    end

    always @(posedge clk_in) begin
        if((BM_done == 1'b1) && (frame_start_flag == 1'b1)) begin
            Omega[0] <= 8'd0;
            Omega[1] <= 8'd0;
            Omega[2] <= 8'd0;
            Omega[3] <= 8'd0;
            Omega[4] <= 8'd0;
            Omega[5] <= 8'd0;
            Omega[6] <= 8'd0;
            Omega[7] <= 8'd0;
        end
        else if((Omega_cnt >= 1) && (Omega_cnt <= t))begin
            Omega[0] <= Omega[1];
            Omega[1] <= Omega[2];
            Omega[2] <= Omega[3];
            Omega[3] <= Omega[4];
            Omega[4] <= Omega[5];
            Omega[5] <= Omega[6];
            Omega[6] <= Omega[7];
            Omega[7] <= Delta_delay;
        end
        else begin
            Omega[0] <= Omega[0];
            Omega[1] <= Omega[1];
            Omega[2] <= Omega[2];
            Omega[3] <= Omega[3];
            Omega[4] <= Omega[4];
            Omega[5] <= Omega[5];
            Omega[6] <= Omega[6];
            Omega[7] <= Omega[7];
        end
    end
    
    reg  ECalc_start;
    always @(Omega_cnt) begin
        if(Omega_cnt == t+1) begin
            ECalc_start <= 1'b1;
        end
        else begin
            ECalc_start <= 1'b0;
        end
    end

    always @(posedge clk_in) begin
        if(ECalc_start == 1'b1) begin
            Omega_reg[0] <= Omega[0];
            Omega_reg[1] <= Omega[1];
            Omega_reg[2] <= Omega[2];
            Omega_reg[3] <= Omega[3];
            Omega_reg[4] <= Omega[4];
            Omega_reg[5] <= Omega[5];
            Omega_reg[6] <= Omega[6];
            Omega_reg[7] <= Omega[7];
        end
        else begin
            Omega_reg[0] <= Omega_alpha[0];
            Omega_reg[1] <= Omega_alpha[1];
            Omega_reg[2] <= Omega_alpha[2];
            Omega_reg[3] <= Omega_alpha[3];
            Omega_reg[4] <= Omega_alpha[4];
            Omega_reg[5] <= Omega_alpha[5];
            Omega_reg[6] <= Omega_alpha[6];
            Omega_reg[7] <= Omega_alpha[7];
        end
    end

    GF_constMul #(.dual_const(15'h0E91)) Omega_a1  (.mul_numA(Omega_reg[0]),.prod(Omega_alpha[0]));//Omega0*a^16      15'h6202
    GF_constMul #(.dual_const(15'h0748)) Omega_a2  (.mul_numA(Omega_reg[1]),.prod(Omega_alpha[1]));//Omega1*a^17      15'h7101
    GF_constMul #(.dual_const(15'h03A4)) Omega_a3  (.mul_numA(Omega_reg[2]),.prod(Omega_alpha[2]));//Omega2*a^18      15'h3880
    GF_constMul #(.dual_const(15'h01D2)) Omega_a4  (.mul_numA(Omega_reg[3]),.prod(Omega_alpha[3]));//Omega3*a^19      15'h1C40
    GF_constMul #(.dual_const(15'h40E9)) Omega_a5  (.mul_numA(Omega_reg[4]),.prod(Omega_alpha[4]));//Omega4*a^20      15'h0E20
    GF_constMul #(.dual_const(15'h6074)) Omega_a6  (.mul_numA(Omega_reg[5]),.prod(Omega_alpha[5]));//Omega5*a^21      15'h4710
    GF_constMul #(.dual_const(15'h303A)) Omega_a7  (.mul_numA(Omega_reg[6]),.prod(Omega_alpha[6]));//Omega6*a^22      15'h2388
    GF_constMul #(.dual_const(15'h181D)) Omega_a8  (.mul_numA(Omega_reg[7]),.prod(Omega_alpha[7]));//Omega7*a^23      15'h11C4

    always @(posedge clk_in) begin
        if(sys_rst_n == 1'b0)begin
            Omega_alpha_pow_minus_i <= 8'd0;
        end
        else begin
            Omega_alpha_pow_minus_i <= Omega_reg[0] ^
                                       Omega_reg[1] ^
                                       Omega_reg[2] ^
                                       Omega_reg[3] ^
                                       Omega_reg[4] ^
                                       Omega_reg[5] ^
                                       Omega_reg[6] ^
                                       Omega_reg[7];
        end
    end

    reg  [m-1 : 0] Omega_ai_delay1;
    reg  [m-1 : 0] Omega_ai_delay2;
    always @(posedge clk_in) begin
        Omega_ai_delay1 <= Omega_alpha_pow_minus_i;
        Omega_ai_delay2 <= Omega_ai_delay1;
    end
    
    reg  [m-1 : 0] diff_Lambda       [(t>>1)-1 : 0];
    wire [m-1 : 0] diff_Lambda_alpha [(t>>1)-1 : 0];
    reg  [m-1 : 0] diff_Lambda_alpha_pow_minus_i;//存储Lambda'(a^-i)

    reg  [m-1 : 0] Lambda_odd  [(t>>1)-1 : 0];

    always @(posedge clk_in) begin
        if ((BM_done == 1'b1) && (frame_start_flag == 1'b1)) begin
            Lambda_odd[0] <= Lambda1;
		    Lambda_odd[1] <= Lambda3;
		    Lambda_odd[2] <= Lambda5;
		    Lambda_odd[3] <= Lambda7;
        end
        else begin
            Lambda_odd[0] <= Lambda_odd[0];
            Lambda_odd[1] <= Lambda_odd[1];
            Lambda_odd[2] <= Lambda_odd[2];
            Lambda_odd[3] <= Lambda_odd[3];
        end
    end

    always@(posedge clk_in)begin:dLambda_Calc
    	if(ECalc_start)begin
    		diff_Lambda[0] <= Lambda_odd[0];
    		diff_Lambda[1] <= Lambda_odd[1];
    		diff_Lambda[2] <= Lambda_odd[2];
    		diff_Lambda[3] <= Lambda_odd[3];
    	end
    	else begin
    		diff_Lambda[0] <= diff_Lambda_alpha[0];
    		diff_Lambda[1] <= diff_Lambda_alpha[1];
    		diff_Lambda[2] <= diff_Lambda_alpha[2];
    		diff_Lambda[3] <= diff_Lambda_alpha[3];
    	end
    end

    GF_constMul #(.dual_const(15'h6202)) dLambda_a1(.mul_numA(diff_Lambda[0]),.prod(diff_Lambda_alpha[0]));
    GF_constMul #(.dual_const(15'h3880)) dLambda_a2(.mul_numA(diff_Lambda[1]),.prod(diff_Lambda_alpha[1]));
    GF_constMul #(.dual_const(15'h0E20)) dLambda_a4(.mul_numA(diff_Lambda[2]),.prod(diff_Lambda_alpha[2]));
    GF_constMul #(.dual_const(15'h2388)) dLambda_a6(.mul_numA(diff_Lambda[3]),.prod(diff_Lambda_alpha[3]));

    always @(posedge clk_in) begin
        if(sys_rst_n == 1'b0)begin
            diff_Lambda_alpha_pow_minus_i <= 8'd0;
        end
        else begin
            diff_Lambda_alpha_pow_minus_i <= diff_Lambda[0] ^
                                             diff_Lambda[1] ^
                                             diff_Lambda[2] ^
                                             diff_Lambda[3];
        end
    end

    wire [m-1 : 0] inv_dLambda_ai;
    ROM_INV inv_dLambda(
        .clka(clk_in),
        .addra(diff_Lambda_alpha_pow_minus_i),

        .douta(inv_dLambda_ai)
    );

    GF_mul_clk AlphaOmega_invdLambda(
        .sys_clk(clk_in),
        .mul_A(Omega_ai_delay2),
        .mul_B(inv_dLambda_ai),

        .prod(Error_approx)
    );

    always @(posedge clk_in) begin
    	if(BM_done == 1'b1)begin
    		end_operation_cnt <= 4'd1;
    	end
    	else if((end_operation_cnt >= 4'd1) && (end_operation_cnt <= 4'd13))begin
    		end_operation_cnt <= end_operation_cnt + 1'b1;
    	end
    	else begin
    		end_operation_cnt <= 1'b0;
    	end
    end

    always @(posedge clk_in) begin
    	if (end_operation_cnt == 4'd14) begin
    		Error_approx_latch <= Error_approx;
    	end
    	else begin
    		Error_approx_latch <= Error_approx_latch;
    	end
    end
endmodule
