module data_generate(
    input  wire         clk_in,
    input  wire         sys_rst_n,
    input  wire         data_generate_start,
    input  wire         locked,

    output reg          sync,
    output reg  [7 : 0] data_generated,
    output              data_or_eval
    );
    reg [7:0] generate_cnt;
    reg generate_en;
    always @(posedge clk_in or negedge sys_rst_n)begin
        if(sys_rst_n == 1'b0)begin
            generate_cnt <= 8'd0;
            generate_en <= 1'b0;
        end
        else if((generate_cnt >= 8'd1) & (generate_cnt <= 8'd239))begin
            generate_en <= 1'b1;
            generate_cnt <= generate_cnt + 1'b1;
        end
        else if((generate_cnt > 8'd239) & (generate_cnt < 8'd255))begin
            generate_en <= 1'b0;
            generate_cnt <= generate_cnt + 1'b1;
        end
        else if(generate_cnt == 8'd255)begin
            generate_en <= 1'b0;
            generate_cnt <= 8'd1;
        end
        else begin
            if(data_generate_start == 1'b1)begin
                generate_cnt <= generate_cnt + 1'b1;
            end
            else begin
                generate_cnt <= generate_cnt;
            end
        end
    end
    localparam LFSR_ORDER = 8;
    reg [7:0] lfsr_reg [LFSR_ORDER:1];
    wire [7:0] feedback_result;
    assign feedback_result = lfsr_reg[8] ^ lfsr_reg[6] ^ lfsr_reg[5] ^ lfsr_reg[4];
    always @(posedge clk_in or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            lfsr_reg[8] <= 8'b0110_1100;
            lfsr_reg[7] <= 8'b0010_1001;
            lfsr_reg[6] <= 8'b0101_1010;
            lfsr_reg[5] <= 8'b0111_1111;
            lfsr_reg[4] <= 8'b1001_1010;
            lfsr_reg[3] <= 8'b1111_0000;
            lfsr_reg[2] <= 8'b1101_0111;
            lfsr_reg[1] <= 8'b1110_0110;
        end
        else if (data_generate_start == 1'b1) begin
            lfsr_reg[8] <= feedback_result;
            lfsr_reg[7] <= lfsr_reg[8];
            lfsr_reg[6] <= lfsr_reg[7];
            lfsr_reg[5] <= lfsr_reg[6];
            lfsr_reg[4] <= lfsr_reg[5];
            lfsr_reg[3] <= lfsr_reg[4];
            lfsr_reg[2] <= lfsr_reg[3];
            lfsr_reg[1] <= lfsr_reg[2];
        end
        else begin
            lfsr_reg[8] <= 8'b0110_1100;
            lfsr_reg[7] <= 8'b0010_1001;
            lfsr_reg[6] <= 8'b0101_1010;
            lfsr_reg[5] <= 8'b0111_1111;
            lfsr_reg[4] <= 8'b1001_1010;
            lfsr_reg[3] <= 8'b1111_0000;
            lfsr_reg[2] <= 8'b1101_0111;
            lfsr_reg[1] <= 8'b1110_0110;
        end
    end
    localparam frame_num = 14'd16321;//64*255+1
    reg [13:0] frame_cnt;
    always @(posedge clk_in or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            frame_cnt <= 14'd1;
        end
        else if (generate_cnt == 8'd255) begin
            if(frame_cnt < frame_num)begin
                frame_cnt <= frame_cnt + 1'b1;
            end
            else if(frame_cnt == frame_num) begin
                frame_cnt <= frame_cnt;
            end
        end
        else begin
            frame_cnt <= frame_cnt;
        end
    end
    reg sync_reg;
    always @(posedge clk_in or negedge sys_rst_n)begin
        if(sys_rst_n == 1'b0)begin
            sync_reg <= 1'b0;
            sync <= 1'b0;
        end
        else if(data_generate_start == 1'b1) begin
            if(frame_cnt == frame_num)begin
                sync_reg <= 1'b0;
                sync <= 1'b0;
            end
            else begin
                sync_reg <= 1'b1;
                sync <= sync_reg;
            end
        end
        else begin
            sync_reg <= 1'b0;
            sync <= 1'b0;
        end
    end
    assign data_or_eval = (frame_cnt == frame_num)?1'b0:generate_en;
    always @(posedge clk_in) begin
        if(frame_cnt < frame_num)begin
            //data: 1~239
            data_generated <= generate_cnt;
            //random data
            //data_generated <= lfsr_reg[1];
        end
        else begin
            data_generated <= 8'd0;
        end
    end
endmodule
