module Reformulated_BM#(
    parameter n = 255,  //data frame length，数据帧长度
    parameter k = 239,  //valid message length，有效信息长度
    parameter t = 8,    //decoder can only correct less than 8 error symbols，译码器对单帧数据至多纠正8个错误码元
    parameter m = 8     //data width，数据位宽
)
(
    input  wire           clk_in,
    input  wire           Scalc_done,
    input  wire [m-1 : 0] Syndrome_out,

    output wire [m-1 : 0] Lambda0,
	output wire [m-1 : 0] Lambda1,
	output wire [m-1 : 0] Lambda2,
	output wire [m-1 : 0] Lambda3,
	output wire [m-1 : 0] Lambda4,
	output wire [m-1 : 0] Lambda5,
	output wire [m-1 : 0] Lambda6,
	output wire [m-1 : 0] Lambda7,
	output wire [m-1 : 0] Lambda8,//Error symbol locater polynomial Lambda(x),Lambdas is coefficients
	output wire [m-1 : 0] Delta,//convolution of Lambda(x) and Syndrome 
	output reg            BM_done//signal informs iteration calculation of Lambda(x) completed
    );

	reg  [m-1 : 0] Lambda_temp [t : 0];//reg for iteration calculation of Lambda
	reg  [m-1 : 0] T           [t : 0];//polynomial T
	reg  [m-1 : 0] gamma;
	reg  [m-1 : 0] polynomial_degree;  //degree of Lambda(x)

	reg  [m-1 : 0] iteration_cnt;              
	reg  [m-1 : 0] Syndrome_buffer  [t+1 : 1]; //buffer input syndrome for convolution with Lambda(x)
	wire [m-1 : 0] Lambda_Syndrome  [t   : 0]; //Syndrome times Lambda

	wire [m-1 : 0] gamma_Lambda_temp [t : 0];//gamma*Lambda
	wire [m-1 : 0] Delta_T           [t : 1];//Delta*T(x)*x,*x is equivilent to array of coefficients <<1

	always @(posedge clk_in) begin
		if (Scalc_done == 1'b1) begin
			//iteration start after syndrome calcution completed
			iteration_cnt <= 8'd0;
		end
		else if (iteration_cnt <= 8'd15) begin
			//iteration need 16 clock periods to finish
			iteration_cnt <= iteration_cnt + 1'b1;
		end
		else begin
			iteration_cnt <= iteration_cnt;
		end
	end

	always @(posedge clk_in) begin
		if(Scalc_done == 1'b1)begin
			gamma <= 8'd1;
		end
		else begin
			if((Delta != 8'd0) && ((polynomial_degree << 1'b1) <= iteration_cnt))begin
				gamma <= Delta;
			end
			else begin
				gamma <= gamma;
			end
		end
	end

	always @(posedge clk_in) begin
		if(Scalc_done == 1'b1)begin
			polynomial_degree <= 8'd0;
		end
		else begin
			if((Delta != 8'd0) && ((polynomial_degree << 1'b1) <= iteration_cnt))begin
				polynomial_degree <= iteration_cnt - polynomial_degree + 1'b1;
			end
			else begin
				polynomial_degree <= polynomial_degree;
			end
		end
	end

	assign Delta = Lambda_Syndrome[0] ^
				   Lambda_Syndrome[1] ^
				   Lambda_Syndrome[2] ^
				   Lambda_Syndrome[3] ^
				   Lambda_Syndrome[4] ^
				   Lambda_Syndrome[5] ^
				   Lambda_Syndrome[6] ^
				   Lambda_Syndrome[7] ^
				   Lambda_Syndrome[8];

	GF_mul Lambda_temp0_Syndrome(.mul_A(Lambda_temp[0]),.mul_B(Syndrome_buffer[1]),.prod(Lambda_Syndrome[0]));
	GF_mul Lambda_temp1_Syndrome(.mul_A(Lambda_temp[1]),.mul_B(Syndrome_buffer[2]),.prod(Lambda_Syndrome[1]));
	GF_mul Lambda_temp2_Syndrome(.mul_A(Lambda_temp[2]),.mul_B(Syndrome_buffer[3]),.prod(Lambda_Syndrome[2]));
	GF_mul Lambda_temp3_Syndrome(.mul_A(Lambda_temp[3]),.mul_B(Syndrome_buffer[4]),.prod(Lambda_Syndrome[3]));
	GF_mul Lambda_temp4_Syndrome(.mul_A(Lambda_temp[4]),.mul_B(Syndrome_buffer[5]),.prod(Lambda_Syndrome[4]));
	GF_mul Lambda_temp5_Syndrome(.mul_A(Lambda_temp[5]),.mul_B(Syndrome_buffer[6]),.prod(Lambda_Syndrome[5]));
	GF_mul Lambda_temp6_Syndrome(.mul_A(Lambda_temp[6]),.mul_B(Syndrome_buffer[7]),.prod(Lambda_Syndrome[6]));
	GF_mul Lambda_temp7_Syndrome(.mul_A(Lambda_temp[7]),.mul_B(Syndrome_buffer[8]),.prod(Lambda_Syndrome[7]));
	GF_mul Lambda_temp8_Syndrome(.mul_A(Lambda_temp[8]),.mul_B(Syndrome_buffer[9]),.prod(Lambda_Syndrome[8]));	

	always @(posedge clk_in)begin
		if (Scalc_done == 1'b1) begin
			//Syndrome_buffer initialization after syndrome calculation completed
			Syndrome_buffer[1] <= Syndrome_out;
			Syndrome_buffer[2] <= 8'd0;
			Syndrome_buffer[3] <= 8'd0;
			Syndrome_buffer[4] <= 8'd0;
			Syndrome_buffer[5] <= 8'd0;
			Syndrome_buffer[6] <= 8'd0;
			Syndrome_buffer[7] <= 8'd0;
			Syndrome_buffer[8] <= 8'd0;
			Syndrome_buffer[9] <= 8'd0;
		end
		else begin
			//Shift in syndrome data from module SyndromeCalc
			Syndrome_buffer[1] <= Syndrome_out;
			Syndrome_buffer[2] <= Syndrome_buffer[1];
			Syndrome_buffer[3] <= Syndrome_buffer[2];
			Syndrome_buffer[4] <= Syndrome_buffer[3];
			Syndrome_buffer[5] <= Syndrome_buffer[4];
			Syndrome_buffer[6] <= Syndrome_buffer[5];
			Syndrome_buffer[7] <= Syndrome_buffer[6];
			Syndrome_buffer[8] <= Syndrome_buffer[7];
			Syndrome_buffer[9] <= Syndrome_buffer[8];
		end
	end

	always @(posedge clk_in) begin
		if(Scalc_done == 1'b1)begin
			Lambda_temp[0] <= 8'd1;
			Lambda_temp[1] <= 8'd0;
			Lambda_temp[2] <= 8'd0;
			Lambda_temp[3] <= 8'd0;
			Lambda_temp[4] <= 8'd0;
			Lambda_temp[5] <= 8'd0;
			Lambda_temp[6] <= 8'd0;
			Lambda_temp[7] <= 8'd0;
			Lambda_temp[8] <= 8'd0;	
		end
		else if (iteration_cnt == 8'd16) begin
			Lambda_temp[0] <= Lambda_temp[0];
			Lambda_temp[1] <= Lambda_temp[1];
			Lambda_temp[2] <= Lambda_temp[2];
			Lambda_temp[3] <= Lambda_temp[3];
			Lambda_temp[4] <= Lambda_temp[4];
			Lambda_temp[5] <= Lambda_temp[5];
			Lambda_temp[6] <= Lambda_temp[6];
			Lambda_temp[7] <= Lambda_temp[7];
			Lambda_temp[8] <= Lambda_temp[8];
		end
		else begin
			Lambda_temp[0] <= gamma_Lambda_temp[0];		
			Lambda_temp[1] <= gamma_Lambda_temp[1] ^ Delta_T[1];	
			Lambda_temp[2] <= gamma_Lambda_temp[2] ^ Delta_T[2];	
			Lambda_temp[3] <= gamma_Lambda_temp[3] ^ Delta_T[3];	
			Lambda_temp[4] <= gamma_Lambda_temp[4] ^ Delta_T[4];	
			Lambda_temp[5] <= gamma_Lambda_temp[5] ^ Delta_T[5];	
			Lambda_temp[6] <= gamma_Lambda_temp[6] ^ Delta_T[6];	
			Lambda_temp[7] <= gamma_Lambda_temp[7] ^ Delta_T[7];	
			Lambda_temp[8] <= gamma_Lambda_temp[8] ^ Delta_T[8];
		end
	end

	always @(posedge clk_in) begin
		if(Scalc_done == 1'b1)begin
			T[0] <= 8'd1;
			T[1] <= 8'd0;
			T[2] <= 8'd0;
			T[3] <= 8'd0;
			T[4] <= 8'd0;
			T[5] <= 8'd0;
			T[6] <= 8'd0;
			T[7] <= 8'd0;
			T[8] <= 8'd0;
		end
		else begin
			if((polynomial_degree == 8'd0) && (iteration_cnt == 8'd0) == 1'b1)begin
				T[0] <= T[0];
				T[1] <= T[1];
				T[2] <= T[2];
				T[3] <= T[3];
				T[4] <= T[4];
				T[5] <= T[5];
				T[6] <= T[6];
				T[7] <= T[7];
				T[8] <= T[8];
			end
			else if((Delta != 8'd0) && ((polynomial_degree << 1'b1) <= iteration_cnt))begin
				T[0] <= Lambda_temp[0];
				T[1] <= Lambda_temp[1];
				T[2] <= Lambda_temp[2];
				T[3] <= Lambda_temp[3];
				T[4] <= Lambda_temp[4];
				T[5] <= Lambda_temp[5];
				T[6] <= Lambda_temp[6];
				T[7] <= Lambda_temp[7];
				T[8] <= Lambda_temp[8];
			end
			else begin
				T[0] <= 8'd0;
				T[1] <= T[0];
				T[2] <= T[1];
				T[3] <= T[2];
				T[4] <= T[3];
				T[5] <= T[4];
				T[6] <= T[5];
				T[7] <= T[6];
				T[8] <= T[7];
			end
		end
	end

	GF_mul gamma_Lambda_temp0(.mul_A(gamma),.mul_B(Lambda_temp[0]),.prod(gamma_Lambda_temp[0]));
	GF_mul gamma_Lambda_temp1(.mul_A(gamma),.mul_B(Lambda_temp[1]),.prod(gamma_Lambda_temp[1]));
	GF_mul gamma_Lambda_temp2(.mul_A(gamma),.mul_B(Lambda_temp[2]),.prod(gamma_Lambda_temp[2]));
	GF_mul gamma_Lambda_temp3(.mul_A(gamma),.mul_B(Lambda_temp[3]),.prod(gamma_Lambda_temp[3]));
	GF_mul gamma_Lambda_temp4(.mul_A(gamma),.mul_B(Lambda_temp[4]),.prod(gamma_Lambda_temp[4]));
	GF_mul gamma_Lambda_temp5(.mul_A(gamma),.mul_B(Lambda_temp[5]),.prod(gamma_Lambda_temp[5]));
	GF_mul gamma_Lambda_temp6(.mul_A(gamma),.mul_B(Lambda_temp[6]),.prod(gamma_Lambda_temp[6]));
	GF_mul gamma_Lambda_temp7(.mul_A(gamma),.mul_B(Lambda_temp[7]),.prod(gamma_Lambda_temp[7]));
	GF_mul gamma_Lambda_temp8(.mul_A(gamma),.mul_B(Lambda_temp[8]),.prod(gamma_Lambda_temp[8]));

	GF_mul Delta_T1(.mul_A(Delta),.mul_B(T[0]),.prod(Delta_T[1]));
	GF_mul Delta_T2(.mul_A(Delta),.mul_B(T[1]),.prod(Delta_T[2]));
	GF_mul Delta_T3(.mul_A(Delta),.mul_B(T[2]),.prod(Delta_T[3]));
	GF_mul Delta_T4(.mul_A(Delta),.mul_B(T[3]),.prod(Delta_T[4]));
	GF_mul Delta_T5(.mul_A(Delta),.mul_B(T[4]),.prod(Delta_T[5]));
	GF_mul Delta_T6(.mul_A(Delta),.mul_B(T[5]),.prod(Delta_T[6]));
	GF_mul Delta_T7(.mul_A(Delta),.mul_B(T[6]),.prod(Delta_T[7]));
	GF_mul Delta_T8(.mul_A(Delta),.mul_B(T[7]),.prod(Delta_T[8]));

	always @(posedge clk_in) begin
		if(Scalc_done == 1'b1)begin
			BM_done <= 1'b0;
		end
		else if (iteration_cnt == 8'd15) begin
			BM_done <= 1'b1;
		end
		else begin
			BM_done <= 1'b0;
		end
	end

	assign Lambda0 = (BM_done)?Lambda_temp[0]:8'd0;
	assign Lambda1 = (BM_done)?Lambda_temp[1]:8'd0;
	assign Lambda2 = (BM_done)?Lambda_temp[2]:8'd0;
	assign Lambda3 = (BM_done)?Lambda_temp[3]:8'd0;
	assign Lambda4 = (BM_done)?Lambda_temp[4]:8'd0;
	assign Lambda5 = (BM_done)?Lambda_temp[5]:8'd0;
	assign Lambda6 = (BM_done)?Lambda_temp[6]:8'd0;
	assign Lambda7 = (BM_done)?Lambda_temp[7]:8'd0;
	assign Lambda8 = (BM_done)?Lambda_temp[8]:8'd0;

endmodule
