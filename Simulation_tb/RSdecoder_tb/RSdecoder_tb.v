`timescale 1ns/1ps
module RSdecoder_tb;
    reg  clk_100M;
    reg  pll_rst_n;
    reg  sys_rst_n;
    reg  data_generate_start;

    wire         clk_in;
    wire         locked;
    wire         sync;
    wire [7 : 0] data_generated;
    wire         data_or_eval;
    data_generate data_generate_U(
        .clk_in(clk_in),
        .sys_rst_n(sys_rst_n),
        .data_generate_start(data_generate_start),
        .locked(locked),

        .sync(sync),
        .data_generated(data_generated),
        .data_or_eval(data_or_eval)
    );

    RSEncoder RSEncoder_U(
        .clk_in(clk_in),
        .sys_rst_n(sys_rst_n),
        .coding_start(sync),
        .data_in(data_generated),
        .data_or_eval(data_or_eval),

        .code_out(),
        .doe()
    );

    RSdecoder RSdecoder_U(
        .clk_in(clk_in),       //system clock
        .sys_rst_n(sys_rst_n),    //reset signal
        .sync(),         //data sychronisation signal,valid when it's low
        .data_in(),      //data received,contains error symbols

        .data_out()      //data get corrected
    );
endmodule