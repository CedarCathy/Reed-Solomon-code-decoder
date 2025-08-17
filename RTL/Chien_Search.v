module Chien_Search#(
    parameter n = 255,  //data frame length
    parameter k = 239,  //valid message length
    parameter t = 8,    //this decoder can only correct errors less than 8
    parameter m = 8     //data width
)
(
    input  wire         clk_in,
    input  wire         Scalc_done,
    input  wire         BM_done,
    
    input  wire [m-1:0] Lambda0,
	input  wire [m-1:0] Lambda1,
	input  wire [m-1:0] Lambda2,
	input  wire [m-1:0] Lambda3,
	input  wire [m-1:0] Lambda4,
	input  wire [m-1:0] Lambda5,
	input  wire [m-1:0] Lambda6,
	input  wire [m-1:0] Lambda7,
	input  wire [m-1:0] Lambda8,

    output wire         Error_symbol,
	output reg          End_Error_symbol
    );

    reg  [m-1 : 0] Lambda                   [t : 0];
    wire [m-1 : 0] Lambda_alpha_pow_minus_i [t : 1];
    reg  [  8 : 0] Serial_machine_cnt;

    always@(posedge clk_in)begin
    	if (Scalc_done) begin
    		Serial_machine_cnt <= 1'b1;
    	end
    	else begin
    		Serial_machine_cnt <= Serial_machine_cnt + 1'b1;
    	end
    end

    always @(posedge clk_in)begin:Chien
    	if(BM_done && (Serial_machine_cnt == 9'd17))begin
    		Lambda[0] <= Lambda0;		
    		Lambda[1] <= Lambda1;
    		Lambda[2] <= Lambda2;
    		Lambda[3] <= Lambda3;
    		Lambda[4] <= Lambda4;
    		Lambda[5] <= Lambda5;
    		Lambda[6] <= Lambda6;
    		Lambda[7] <= Lambda7;
    		Lambda[8] <= Lambda8;		
    	end
    	else begin
            Lambda[0] <= Lambda[0];
            Lambda[1] <= Lambda_alpha_pow_minus_i[1];
            Lambda[2] <= Lambda_alpha_pow_minus_i[2];
            Lambda[3] <= Lambda_alpha_pow_minus_i[3];
            Lambda[4] <= Lambda_alpha_pow_minus_i[4];
            Lambda[5] <= Lambda_alpha_pow_minus_i[5];
            Lambda[6] <= Lambda_alpha_pow_minus_i[6];
            Lambda[7] <= Lambda_alpha_pow_minus_i[7];
            Lambda[8] <= Lambda_alpha_pow_minus_i[8];               
    	end
    end

    GF_constMul #(.dual_const(15'h6202)) Lambda_a1(.mul_numA(Lambda[1]),.prod(Lambda_alpha_pow_minus_i[1]));//Lambda[1]*a^1
    GF_constMul #(.dual_const(15'h7101)) Lambda_a2(.mul_numA(Lambda[2]),.prod(Lambda_alpha_pow_minus_i[2]));//Lambda[2]*a^2
    GF_constMul #(.dual_const(15'h3880)) Lambda_a3(.mul_numA(Lambda[3]),.prod(Lambda_alpha_pow_minus_i[3]));//Lambda[3]*a^3
    GF_constMul #(.dual_const(15'h1C40)) Lambda_a4(.mul_numA(Lambda[4]),.prod(Lambda_alpha_pow_minus_i[4]));//Lambda[4]*a^4
    GF_constMul #(.dual_const(15'h0E20)) Lambda_a5(.mul_numA(Lambda[5]),.prod(Lambda_alpha_pow_minus_i[5]));//Lambda[5]*a^5
    GF_constMul #(.dual_const(15'h4710)) Lambda_a6(.mul_numA(Lambda[6]),.prod(Lambda_alpha_pow_minus_i[6]));//Lambda[6]*a^6
    GF_constMul #(.dual_const(15'h2388)) Lambda_a7(.mul_numA(Lambda[7]),.prod(Lambda_alpha_pow_minus_i[7]));//Lambda[7]*a^7
    GF_constMul #(.dual_const(15'h11C4)) Lambda_a8(.mul_numA(Lambda[8]),.prod(Lambda_alpha_pow_minus_i[8]));//Lambda[8]*a^8

    wire flag;
    assign flag=(Lambda[0] ^
	             Lambda[1] ^
				 Lambda[2] ^
				 Lambda[3] ^
				 Lambda[4] ^
				 Lambda[5] ^
				 Lambda[6] ^
				 Lambda[7] ^
				 Lambda[8])?1'b0:1'b1;

    //shift reg depth = 13
    ErrSymbol_ShiftReg ErrSymbol_ShiftReg_U(
    	.D(flag),
    	.CLK(clk_in),

    	.Q(Error_symbol)
    );
    reg [3:0] end_operation_cnt;
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
    	if((end_operation_cnt == 4'd14) && (Error_symbol == 1'b1))begin
    		End_Error_symbol <= 1'b1;
    	end
    	else if ((end_operation_cnt == 4'd14) && (Error_symbol == 1'b0)) begin
    		End_Error_symbol <= 1'b0;
    	end
    	else begin
    		End_Error_symbol <= End_Error_symbol;
    	end
    end
endmodule
