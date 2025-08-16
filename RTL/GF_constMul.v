module GF_constMul #(
    parameter dual_const=15'h0//弱对偶基表示的有限域常数
)
(
    input  wire [7 : 0] mul_numA,

    output reg  [7 : 0] prod
);

    reg  [ 7 : 0] prod_dual;          //弱对偶基表示的有限域乘法结果
    wire [14 : 0] constant;           //弱对偶基表示的有限域常数

    assign constant = dual_const;

    always @(mul_numA or constant) begin
        //计算乘法结果
        //calculate product of the constant with input number on GF(2^m)
        //prod_dual[i]=constant[i]mul_numA[0]+constant[i+1]mul_numA[1]+...+constant[i+7]mul_numA[7]
        prod_dual[0] = ^ ((constant >> (0)) & mul_numA);
        prod_dual[1] = ^ ((constant >> (1)) & mul_numA);
        prod_dual[2] = ^ ((constant >> (2)) & mul_numA);
        prod_dual[3] = ^ ((constant >> (3)) & mul_numA);
        prod_dual[4] = ^ ((constant >> (4)) & mul_numA);
        prod_dual[5] = ^ ((constant >> (5)) & mul_numA);
        prod_dual[6] = ^ ((constant >> (6)) & mul_numA);
        prod_dual[7] = ^ ((constant >> (7)) & mul_numA);
        //将弱对偶基表示的乘法结果转换到多项式基表示
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