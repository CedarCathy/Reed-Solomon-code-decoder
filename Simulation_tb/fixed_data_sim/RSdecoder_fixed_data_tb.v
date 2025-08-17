`timescale 1ns/1ps
module RS_decoder_fixed_data_tb;
    reg clk_in;
    reg sys_rst_n;
    reg [7:0] data_in;
    reg sync;

    wire [7:0] data_out;

    always #4 clk_in = ~clk_in;
	wire locked;

    initial begin
    	clk_in=1'b0;
    	sync<=1'b1;
    	data_in<=8'd0;
        sys_rst_n = 1'b0;
        #30 sys_rst_n = 1'b1;
    	#9998 sync<=1'b0;
    	#8 data_in <= 8'b1;
    	#1912 data_in<=8'd185;
    	#8 data_in<=8'd20;
    	#8 data_in<=8'd223;
    	#8 data_in<=8'd201;
    	#8 data_in<=8'd145;
    	#8 data_in<=8'd106;
    	#8 data_in<=8'd254;
    	#8 data_in<=8'd175;
    	#8 data_in<=8'd6;
    	#8 data_in<=8'd15;
    	#8 data_in<=8'd150;
    	#8 data_in<=8'd25;
    	#8 data_in<=8'd134;
    	#8 data_in<=8'd83;//84-1
    	#8 data_in<=8'd231;//232-1
    	#8 data_in<=8'd171;//172-1
    	//第二组数据
    	#8 data_in<=8'd1;
    	#1912 data_in<=8'd185;
    	#8 data_in<=8'd20;
    	#8 data_in<=8'd223;
    	#8 data_in<=8'd201;
    	#8 data_in<=8'd145;
    	#8 data_in<=8'd106;
    	#8 data_in<=8'd254;
    	#8 data_in<=8'd175;
    	#8 data_in<=8'd6;
    	#8 data_in<=8'd14;//15-1
    	#8 data_in<=8'd150;
    	#8 data_in<=8'd25;
    	#8 data_in<=8'd134;
    	#8 data_in<=8'd83;//84-1
    	#8 data_in<=8'd231;//232-1
    	#8 data_in<=8'd171;//172-1
    	//第三组数据
    	#8 data_in<=8'd1;
    	#1912 data_in<=8'd185;
    	#8 data_in<=8'd19;//20-1
    	#8 data_in<=8'd48;//223-175
    	#8 data_in<=8'd201;
    	#8 data_in<=8'd144;//145-1
    	#8 data_in<=8'd106;
    	#8 data_in<=8'd254;
    	#8 data_in<=8'd170;//175-5
    	#8 data_in<=8'd0;//6-6
    	#8 data_in<=8'd15;
    	#8 data_in<=8'd149;//150-1
    	#8 data_in<=8'd25;
    	#8 data_in<=8'd134;
    	#8 data_in<=8'd83;//84-1
    	#8 data_in<=8'd231;//232-1
    	#8 data_in<=8'd172;
    	//第四组数据
    	#8 data_in<=8'd0;
    	#8 data_in<=8'd1;
    	#8 data_in<=8'd0;
    	#1896 data_in<=8'd44;
    	#8 data_in<=8'd164;//179-15
    	#8 data_in<=8'd224;
    	#8 data_in<=8'd77;
    	#8 data_in<=8'd193;
    	#8 data_in<=8'd133;
    	#8 data_in<=8'd17;
    	#8 data_in<=8'd187;
    	#8 data_in<=8'd207;
    	#8 data_in<=8'd63;
    	#8 data_in<=8'd171;
    	#8 data_in<=8'd4;
    	#8 data_in<=8'd53;
    	#8 data_in<=8'd242;
    	#8 data_in<=8'd149;
    	#8 data_in<=8'd208;
    	#8 data_in<=8'd208;
    end
    RSdecoder Rsdecoder_U(
    	.clk_in(clk_in),
    	.sync(sync),
    	.data_in(data_in),

    	.data_out(data_out)
);
endmodule