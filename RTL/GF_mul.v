module GF_mul#(
	parameter m=8
)
(
	input  wire [m-1 : 0] mul_A,
	input  wire [m-1 : 0] mul_B,
	output reg  [m-1 : 0] prod
);
reg [2*m-2 : 0] B_dual;//乘数B的对偶基表示
reg [2*m-2 : 0] prod_dual;//乘积的对偶基表示

always @(mul_A or mul_B)begin
	//乘数B从多项式基变换到弱对偶基
	B_dual[0] = mul_B[0] ^ mul_B[2];
	B_dual[1] = mul_B[1];
	B_dual[2] = mul_B[0];
	B_dual[3] = mul_B[7];
	B_dual[4] = mul_B[6];
	B_dual[5] = mul_B[5];
	B_dual[6] = mul_B[4];
	B_dual[7] = mul_B[3] ^ mul_B[7];
	//弱对偶基下系数扩展
	B_dual[8]  = B_dual[0] ^ B_dual[2] ^ B_dual[3] ^ B_dual[4];
	B_dual[9]  = B_dual[1] ^ B_dual[3] ^ B_dual[4] ^ B_dual[5];
	B_dual[10] = B_dual[2] ^ B_dual[4] ^ B_dual[5] ^ B_dual[6];
	B_dual[11] = B_dual[3] ^ B_dual[5] ^ B_dual[6] ^ B_dual[7];
	B_dual[12] = B_dual[4] ^ B_dual[6] ^ B_dual[7] ^ B_dual[8];
	B_dual[13] = B_dual[5] ^ B_dual[7] ^ B_dual[8] ^ B_dual[9];
	B_dual[14] = B_dual[6] ^ B_dual[8] ^ B_dual[9] ^ B_dual[10];
	//乘积
    prod_dual[0] = ^ ((B_dual >> (0)) & mul_A);
    prod_dual[1] = ^ ((B_dual >> (1)) & mul_A);
    prod_dual[2] = ^ ((B_dual >> (2)) & mul_A);
    prod_dual[3] = ^ ((B_dual >> (3)) & mul_A);
    prod_dual[4] = ^ ((B_dual >> (4)) & mul_A);
    prod_dual[5] = ^ ((B_dual >> (5)) & mul_A);
    prod_dual[6] = ^ ((B_dual >> (6)) & mul_A);
    prod_dual[7] = ^ ((B_dual >> (7)) & mul_A);
	//乘积由弱对偶基变换到多项式基
	prod[0] = prod_dual[2];
	prod[1] = prod_dual[1];
	prod[2] = prod_dual[0] ^ prod_dual[2];
	prod[3] = prod_dual[3] ^ prod_dual[7];
	prod[4] = prod_dual[6];
	prod[5] = prod_dual[5];
	prod[6] = prod_dual[4];
	prod[7] = prod_dual[3];
end
endmodule
