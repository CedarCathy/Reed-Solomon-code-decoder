//////////////////////////////////////////////////////////////////////////////////
//RS编码器
//码生成多项式：g(x)=(x+m^0)(x+m^1)...(x+m^15) m=0x02
//十进制下码生成多项式的系数g0~g15为：59，36，50，98，229，41，65，163，8，30，209，68，189，104，13，59
//域生成多项式：p(x)=x^8+x^4+x^3+x^2+1
//RS系统码的码字结构为：前k个码元为原始码字，后n-k个码元为校验码
//////////////////////////////////////////////////////////////////////////////////

module RSEncoder(
    input  wire         clk_in,
    input  wire         sys_rst_n,
    input  wire         coding_start,
    input  wire [7 : 0] data_in,
    input  wire         data_or_eval,

    output reg  [7 : 0] code_out,
    output reg          doe
);

	always@(posedge clk_in or negedge sys_rst_n)begin
	    if(sys_rst_n == 1'b0)begin
	        doe <= 1'b0;
	    end
	    else begin
	        doe <= data_or_eval;
	    end
	end
	
	//有限域乘法结果
	wire [7:0] GF_prod [0:15];//有限域乘法结果
	
	reg [7:0] GF_sum [0:15];//加法结果寄存器
	reg [7:0] data_feedback;//反馈数据
	always@(posedge clk_in)begin
		if(coding_start == 1'b1)begin
			if(data_or_eval == 1'b1)begin
				code_out <= data_in;
			end
			else begin
				code_out <= GF_sum[15];
			end
		end
		else begin
			code_out <= 8'd0;
		end
	end
	always@(data_or_eval or data_in or GF_sum[15])begin
		if(data_or_eval == 1'b1)begin
			data_feedback = data_in ^ GF_sum[15];
		end
		else begin
			data_feedback = 8'd0;
		end
	end
	always@(posedge clk_in or negedge sys_rst_n)begin
		if(sys_rst_n == 1'b0)begin
			GF_sum[0]  <= 8'd0;
			GF_sum[1]  <= 8'd0;
			GF_sum[2]  <= 8'd0;
			GF_sum[3]  <= 8'd0;
			GF_sum[4]  <= 8'd0;
			GF_sum[5]  <= 8'd0;
			GF_sum[6]  <= 8'd0;
			GF_sum[7]  <= 8'd0;
			GF_sum[8]  <= 8'd0;
			GF_sum[9]  <= 8'd0;
			GF_sum[10] <= 8'd0;
			GF_sum[11] <= 8'd0;
			GF_sum[12] <= 8'd0;
			GF_sum[13] <= 8'd0;
			GF_sum[14] <= 8'd0;
			GF_sum[15] <= 8'd0;
		end
		else if(coding_start == 1'b1)begin 
			GF_sum[0]  <= GF_prod[0];
			GF_sum[1]  <= GF_sum [0] ^ GF_prod[1];
			GF_sum[2]  <= GF_sum [1] ^ GF_prod[2];
			GF_sum[3]  <= GF_sum [2] ^ GF_prod[3];
			GF_sum[4]  <= GF_sum [3] ^ GF_prod[4];
			GF_sum[5]  <= GF_sum [4] ^ GF_prod[5];
			GF_sum[6]  <= GF_sum [5] ^ GF_prod[6];
			GF_sum[7]  <= GF_sum [6] ^ GF_prod[7];
			GF_sum[8]  <= GF_sum [7] ^ GF_prod[8];
			GF_sum[9]  <= GF_sum [8] ^ GF_prod[9];
			GF_sum[10] <= GF_sum [9] ^ GF_prod[10];
			GF_sum[11] <= GF_sum [10]^ GF_prod[11];
			GF_sum[12] <= GF_sum [11]^ GF_prod[12];
			GF_sum[13] <= GF_sum [12]^ GF_prod[13];
			GF_sum[14] <= GF_sum [13]^ GF_prod[14];
			GF_sum[15] <= GF_sum [14]^ GF_prod[15];
		end
		else  begin
					GF_sum[0]  <= GF_sum[0];
					GF_sum[1]  <= GF_sum[1];
					GF_sum[2]  <= GF_sum[2];
					GF_sum[3]  <= GF_sum[3];
					GF_sum[4]  <= GF_sum[4];
					GF_sum[5]  <= GF_sum[5];
					GF_sum[6]  <= GF_sum[6];
					GF_sum[7]  <= GF_sum[7];
					GF_sum[8]  <= GF_sum[8];
					GF_sum[9]  <= GF_sum[9];
					GF_sum[10] <= GF_sum[10];
					GF_sum[11] <= GF_sum[11];
					GF_sum[12] <= GF_sum[12];
					GF_sum[13] <= GF_sum[13];
					GF_sum[14] <= GF_sum[14];
					GF_sum[15] <= GF_sum[15];
		end
	end
	//例化有限域常数乘法器
	GF_constMul #(.dual_const(15'h0CE7))U_GF_constMul_0 (.mul_numA(data_feedback),.prod(GF_prod[0]));//59    
	GF_constMul #(.dual_const(15'h7F21))U_GF_constMul_1 (.mul_numA(data_feedback),.prod(GF_prod[1]));//36
	GF_constMul #(.dual_const(15'h7062))U_GF_constMul_2 (.mul_numA(data_feedback),.prod(GF_prod[2]));//50
	GF_constMul #(.dual_const(15'h2B32))U_GF_constMul_3 (.mul_numA(data_feedback),.prod(GF_prod[3]));//98
	GF_constMul #(.dual_const(15'h5FBC))U_GF_constMul_4 (.mul_numA(data_feedback),.prod(GF_prod[4]));//229
	GF_constMul #(.dual_const(15'h72A5))U_GF_constMul_5 (.mul_numA(data_feedback),.prod(GF_prod[5]));//41
	GF_constMul #(.dual_const(15'h0315))U_GF_constMul_6 (.mul_numA(data_feedback),.prod(GF_prod[6]));//65
	GF_constMul #(.dual_const(15'h0BAF))U_GF_constMul_7 (.mul_numA(data_feedback),.prod(GF_prod[7]));//163
	GF_constMul #(.dual_const(15'h3880))U_GF_constMul_8 (.mul_numA(data_feedback),.prod(GF_prod[8]));//8
	GF_constMul #(.dual_const(15'h37C3))U_GF_constMul_9 (.mul_numA(data_feedback),.prod(GF_prod[9]));//30
	GF_constMul #(.dual_const(15'h3CDD))U_GF_constMul_10(.mul_numA(data_feedback),.prod(GF_prod[10]));//209
	GF_constMul #(.dual_const(15'h3611))U_GF_constMul_11(.mul_numA(data_feedback),.prod(GF_prod[11]));//68
	GF_constMul #(.dual_const(15'h3C6C))U_GF_constMul_12(.mul_numA(data_feedback),.prod(GF_prod[12]));//189
	GF_constMul #(.dual_const(15'h71B0))U_GF_constMul_13(.mul_numA(data_feedback),.prod(GF_prod[13]));//104
	GF_constMul #(.dual_const(15'h0D84))U_GF_constMul_14(.mul_numA(data_feedback),.prod(GF_prod[14]));//13
	GF_constMul #(.dual_const(15'h0CE7))U_GF_constMul_15(.mul_numA(data_feedback),.prod(GF_prod[15]));//59
endmodule




