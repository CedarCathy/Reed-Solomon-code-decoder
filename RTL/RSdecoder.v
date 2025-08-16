//use GF(p^m) to represent Galois Field with parameters: prime p and power m instead of \mathcal{F}_{p^m} or \mathbb{F}(p^m)
module RSdecoder#(
    parameter n = 255,  //data frame length，数据帧长度
    parameter k = 239,  //valid message length，有效信息长度
    parameter t = 8,    //decoder can only correct less than 8 error symbols，译码器对单帧数据至多纠正8个错误码元
    parameter m = 8     //data width，数据位宽
)
(
    input  wire           clk_in,       //system clock
    input  wire           sys_rst_n,    //reset signal
    input  wire           sync,         //data sychronisation signal,valid when it's low
    input  wire [m-1 : 0] data_in,      //data received,contains error symbols

    output wire [m-1 : 0] data_out      //data get corrected
    );


    wire [m-1 : 0] Syndrome_out;
    wire Scalc_done;
    
    SyndromeCalc SyndromeCalc_U(
	    .clk_in(clk_in),
	    .sync(sync),
	    .data_in(data_in),


	    .Syndrome_out(Syndrome_out),
	    .Scalc_done(Scalc_done)
    );


    wire [m-1:0] Lambda0;
    wire [m-1:0] Lambda1;
    wire [m-1:0] Lambda2;
    wire [m-1:0] Lambda3;
    wire [m-1:0] Lambda4;
    wire [m-1:0] Lambda5;
    wire [m-1:0] Lambda6;
    wire [m-1:0] Lambda7;
    wire [m-1:0] Lambda8;

    wire BM_done;
    wire [m-1:0] Delta;

    Reformulated_BM Reformulated_BM_U(
        .clk_in(clk_in),
        .Scalc_done(Scalc_done),
        .Syndrome_out(Syndrome_out),


        .Lambda0(Lambda0),
	    .Lambda1(Lambda1),
	    .Lambda2(Lambda2),
	    .Lambda3(Lambda3),
	    .Lambda4(Lambda4),
	    .Lambda5(Lambda5),
	    .Lambda6(Lambda6),
	    .Lambda7(Lambda7),
	    .Lambda8(Lambda8),
	    .Delta(Delta),
	    .BM_done(BM_done)
    );


    wire Error_symbol;
    wire End_Error_symbol;

    Chien_Search Chien_Search_U(
        .clk_in(clk_in),
        .Scalc_done(Scalc_done),
        .BM_done(BM_done),
        
        .Lambda0(Lambda0),
	    .Lambda1(Lambda1),
	    .Lambda2(Lambda2),
	    .Lambda3(Lambda3),
	    .Lambda4(Lambda4),
	    .Lambda5(Lambda5),
	    .Lambda6(Lambda6),
	    .Lambda7(Lambda7),
	    .Lambda8(Lambda8),


        .Error_symbol(Error_symbol),
	    .End_Error_symbol(End_Error_symbol)
    );


    wire [m-1 : 0] Error_approx;
    wire [m-1 : 0] Error_approx_latch;
    wire [  3 : 0] end_operation_cnt;

    Forney Forney_U(
        .clk_in(clk_in),
        .sys_rst_n(sys_rst_n),
        .BM_done(BM_done),
        .Scalc_done(Scalc_done),
    
        .Lambda1(Lambda1),
	    .Lambda3(Lambda3),
	    .Lambda5(Lambda5),
	    .Lambda7(Lambda7),
    
	    .Delta(Delta),
    

	    .Error_approx(Error_approx),
	    .Error_approx_latch(Error_approx_latch),
	    .end_operation_cnt(end_operation_cnt)
    );


    wire [m-1 : 0] data_shifted;
    //shift_reg depth = 287
    Shift_Reg Shift_Reg_U(
	    .D(data_in),
	    .CLK(clk_in),


	    .Q(data_shifted)
    );


    ErrorCorrect ErrorCorrect_U(
        .clk_in(clk_in),
        .data_shifted(data_shifted),
        .Error_approx(Error_approx),
        .Error_approx_latch(Error_approx_latch),
        .end_operation_cnt(end_operation_cnt),
        .Error_Symbol(Error_symbol),
        .End_Error_Symbol(End_Error_symbol),

        
        .data_out(data_out)
    );
endmodule
