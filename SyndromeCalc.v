module SyndromeCalc#(
    parameter n = 255,  //data frame length
    parameter k = 239,  //valid message length
    parameter t = 8,    //decoder can only correct less than 8 error symbols
    parameter m = 8     //data width
)
(
    input  wire           clk_in,      //system clock
    input  wire           sync,        //data sychronisation signal,valid when it's low
    input  wire [m-1 : 0] data_in,     //data received,contains error symbols

    output reg  [m-1 : 0] Syndrome_out, //Syndrome output(serially,using 2t = 16 clock periods in total)
    output reg            Scalc_done    //1: Syndrome calculation finished for current data frame
    );

    reg  [m-1 : 0] Syndrome            [2*t : 1];
    reg  [m-1 : 0] Serial_machine_cnt;

    wire [m-1 : 0] data_alpha_pow_j    [2*t : 1];

	//Serial machine counter
    always @(posedge clk_in) begin
        if (sync == 1'b1) begin
            Serial_machine_cnt <= 8'd0;
        end
        else begin
            if (Serial_machine_cnt == n) begin
                Serial_machine_cnt <= 8'd1;
            end
            else begin
                Serial_machine_cnt <= Serial_machine_cnt + 1'b1;
            end
        end
    end

    always @(posedge clk_in) begin
    	if (sync == 1'b1) begin
			//syndrome initialization
    		Syndrome [1]  <= 8'd0;
    		Syndrome [2]  <= 8'd0;
    		Syndrome [3]  <= 8'd0;
    		Syndrome [4]  <= 8'd0;
    		Syndrome [5]  <= 8'd0;
    		Syndrome [6]  <= 8'd0;
    		Syndrome [7]  <= 8'd0;
    		Syndrome [8]  <= 8'd0;
    		Syndrome [9]  <= 8'd0;
    		Syndrome [10] <= 8'd0;
    		Syndrome [11] <= 8'd0;
    		Syndrome [12] <= 8'd0;
    		Syndrome [13] <= 8'd0;
    		Syndrome [14] <= 8'd0;
    		Syndrome [15] <= 8'd0;
    		Syndrome [16] <= 8'd0;
    	end
    	else begin
    		if (Serial_machine_cnt == 8'd1) begin
    			Syndrome [1]  <= data_in;
    			Syndrome [2]  <= data_in;
    			Syndrome [3]  <= data_in;
    			Syndrome [4]  <= data_in;
    			Syndrome [5]  <= data_in;
    			Syndrome [6]  <= data_in;
    			Syndrome [7]  <= data_in;
    			Syndrome [8]  <= data_in;
    			Syndrome [9]  <= data_in;
    			Syndrome [10] <= data_in;
    			Syndrome [11] <= data_in;
    			Syndrome [12] <= data_in;
    			Syndrome [13] <= data_in;
    			Syndrome [14] <= data_in;
    			Syndrome [15] <= data_in;
    			Syndrome [16] <= data_in;
    		end
    		else begin
				//syndrome iteration calculation
    			Syndrome [1]  <= data_in ^ data_alpha_pow_j [1];
    			Syndrome [2]  <= data_in ^ data_alpha_pow_j [2];
    			Syndrome [3]  <= data_in ^ data_alpha_pow_j [3];
    			Syndrome [4]  <= data_in ^ data_alpha_pow_j [4];
    			Syndrome [5]  <= data_in ^ data_alpha_pow_j [5];
    			Syndrome [6]  <= data_in ^ data_alpha_pow_j [6];
    			Syndrome [7]  <= data_in ^ data_alpha_pow_j [7];
    			Syndrome [8]  <= data_in ^ data_alpha_pow_j [8];
    			Syndrome [9]  <= data_in ^ data_alpha_pow_j [9];
    			Syndrome [10] <= data_in ^ data_alpha_pow_j [10];
    			Syndrome [11] <= data_in ^ data_alpha_pow_j [11];
    			Syndrome [12] <= data_in ^ data_alpha_pow_j [12];
    			Syndrome [13] <= data_in ^ data_alpha_pow_j [13];
    			Syndrome [14] <= data_in ^ data_alpha_pow_j [14];
    			Syndrome [15] <= data_in ^ data_alpha_pow_j [15];
    			Syndrome [16] <= data_in ^ data_alpha_pow_j [16];
    		end
    	end
    end

    //utility of constant multipliers on GF(2^m)
	//S[j]=R[0]+a^j(R[1]+a^j(R[2]+...+a^j(R[n-2]+R[n-1]*a^j)...)),S:Syndrome;R:data_in
    GF_constMul #(.dual_const(15'h4405)) data_alpha_pow_1 (.mul_numA(Syndrome[1]), .prod(data_alpha_pow_j[1] ));  //a^0  = 8'd1   --> 15'h4405
    GF_constMul #(.dual_const(15'h6202)) data_alpha_pow_2 (.mul_numA(Syndrome[2]), .prod(data_alpha_pow_j[2] ));  //a^1  = 8'd2   --> 15'h6202
    GF_constMul #(.dual_const(15'h7101)) data_alpha_pow_3 (.mul_numA(Syndrome[3]), .prod(data_alpha_pow_j[3] ));  //a^2  = 8'd4   --> 15'h7101
    GF_constMul #(.dual_const(15'h3880)) data_alpha_pow_4 (.mul_numA(Syndrome[4]), .prod(data_alpha_pow_j[4] ));  //a^3  = 8'd8   --> 15'h3880
    GF_constMul #(.dual_const(15'h1C40)) data_alpha_pow_5 (.mul_numA(Syndrome[5]), .prod(data_alpha_pow_j[5] ));  //a^4  = 8'd16  --> 15'h1C40
    GF_constMul #(.dual_const(15'h0E20)) data_alpha_pow_6 (.mul_numA(Syndrome[6]), .prod(data_alpha_pow_j[6] ));  //a^5  = 8'd32  --> 15'h0E20
    GF_constMul #(.dual_const(15'h4710)) data_alpha_pow_7 (.mul_numA(Syndrome[7]), .prod(data_alpha_pow_j[7] ));  //a^6  = 8'd64  --> 15'h4710
    GF_constMul #(.dual_const(15'h2388)) data_alpha_pow_8 (.mul_numA(Syndrome[8]), .prod(data_alpha_pow_j[8] ));  //a^7  = 8'd128 --> 15'h2388
    GF_constMul #(.dual_const(15'h11C4)) data_alpha_pow_9 (.mul_numA(Syndrome[9]), .prod(data_alpha_pow_j[9] ));  //a^8  = 8'd29  --> 15'h11C4
    GF_constMul #(.dual_const(15'h48E2)) data_alpha_pow_10(.mul_numA(Syndrome[10]),.prod(data_alpha_pow_j[10]));  //a^9  = 8'd58  --> 15'h48E2
    GF_constMul #(.dual_const(15'h2471)) data_alpha_pow_11(.mul_numA(Syndrome[11]),.prod(data_alpha_pow_j[11]));  //a^10 = 8'd116 --> 15'h2471
    GF_constMul #(.dual_const(15'h5238)) data_alpha_pow_12(.mul_numA(Syndrome[12]),.prod(data_alpha_pow_j[12]));  //a^11 = 8'd232 --> 15'h5238
    GF_constMul #(.dual_const(15'h691C)) data_alpha_pow_13(.mul_numA(Syndrome[13]),.prod(data_alpha_pow_j[13]));  //a^12 = 8'd205 --> 15'h691C
    GF_constMul #(.dual_const(15'h748E)) data_alpha_pow_14(.mul_numA(Syndrome[14]),.prod(data_alpha_pow_j[14]));  //a^13 = 8'd135 --> 15'h748E
    GF_constMul #(.dual_const(15'h3A47)) data_alpha_pow_15(.mul_numA(Syndrome[15]),.prod(data_alpha_pow_j[15]));  //a^14 = 8'd19  --> 15'h3A47
    GF_constMul #(.dual_const(15'h1D23)) data_alpha_pow_16(.mul_numA(Syndrome[16]),.prod(data_alpha_pow_j[16]));  //a^15 = 8'd38  --> 15'h1D23

	always @(posedge clk_in) begin
        if (Serial_machine_cnt == n) begin
            Scalc_done <= 1'b1;
        end
        else begin
            Scalc_done <= 1'b0;
        end
    end

	//parallel to serial for syndrome output
	reg  [m-1 : 0] Syndrome_shift_reg  [2*t : 1];
    always @(posedge sys_clk) begin
    	if (Serial_machine_cnt == 8'd1) begin
    		Syndrome_shift_reg [1]  <= Syndrome [1];
    		Syndrome_shift_reg [2]  <= Syndrome [2];
    		Syndrome_shift_reg [3]  <= Syndrome [3];
    		Syndrome_shift_reg [4]  <= Syndrome [4];
    		Syndrome_shift_reg [5]  <= Syndrome [5];
    		Syndrome_shift_reg [6]  <= Syndrome [6];
    		Syndrome_shift_reg [7]  <= Syndrome [7];
    		Syndrome_shift_reg [8]  <= Syndrome [8];
    		Syndrome_shift_reg [9]  <= Syndrome [9];
    		Syndrome_shift_reg [10] <= Syndrome [10];
    		Syndrome_shift_reg [11] <= Syndrome [11];
    		Syndrome_shift_reg [12] <= Syndrome [12];
    		Syndrome_shift_reg [13] <= Syndrome [13];
    		Syndrome_shift_reg [14] <= Syndrome [14];
    		Syndrome_shift_reg [15] <= Syndrome [15];
    		Syndrome_shift_reg [16] <= Syndrome [16];
    	end
    	else begin
    		Syndrome_shift_reg [1]  <= Syndrome_shift_reg [1];
    		Syndrome_shift_reg [2]  <= Syndrome_shift_reg [2];
    		Syndrome_shift_reg [3]  <= Syndrome_shift_reg [3];
    		Syndrome_shift_reg [4]  <= Syndrome_shift_reg [4];
    		Syndrome_shift_reg [5]  <= Syndrome_shift_reg [5];
    		Syndrome_shift_reg [6]  <= Syndrome_shift_reg [6];
    		Syndrome_shift_reg [7]  <= Syndrome_shift_reg [7];
    		Syndrome_shift_reg [8]  <= Syndrome_shift_reg [8];
    		Syndrome_shift_reg [9]  <= Syndrome_shift_reg [9];
    		Syndrome_shift_reg [10] <= Syndrome_shift_reg [10];
    		Syndrome_shift_reg [11] <= Syndrome_shift_reg [11];
    		Syndrome_shift_reg [12] <= Syndrome_shift_reg [12];
    		Syndrome_shift_reg [13] <= Syndrome_shift_reg [13];
    		Syndrome_shift_reg [14] <= Syndrome_shift_reg [14];
    		Syndrome_shift_reg [15] <= Syndrome_shift_reg [15];
    		Syndrome_shift_reg [16] <= Syndrome_shift_reg [16];
    	end
    end

    reg [4 : 0] shift_out_cnt;
    always @(posedge clk_in) begin
        if (Serial_machine_cnt == n) begin
            shift_out_cnt <= 5'd1;
        end
        else if ((shift_out_cnt > 5'd1) && (shift_out_cnt < 5'd16)) begin
            shift_out_cnt <= shift_out_cnt + 1'b1;
        end
        else begin
            shift_out_cnt <= shift_out_cnt;
        end
    end

    always @(*) begin
        if ((shift_out_cnt >= 5'd2) && (shift_out_cnt <= 5'd16)) begin
            Syndrome_out = Syndrome_shift_reg[shift_out_cnt];
        end
        else if (shift_out_cnt == 5'd1) begin
            Syndrome_out = Syndrome[1];
        end
        else begin
            Syndrome_out = 8'd0;
        end
    end
endmodule