`timescale 1ns / 1ps
module Interleaver(
    input  wire         clk_out125M,
    input  wire         sys_rst_n,
    input  wire [7 : 0] RScode_in,
    input  wire         intlv_start,
    
    output reg  [7 : 0] intlv_out,
    output reg          next_intlv_start
    );
    reg [7:0] RScode_reg;
    always @(posedge clk_out125M) begin
        RScode_reg <= RScode_in;
    end
    localparam STATE_IDLE  = 6'b00_0001;
    localparam STATE_W1    = 6'b00_0010;
    localparam STATE_R1W2  = 6'b00_0100;
    localparam STATE_W1R2  = 6'b00_1000;
    localparam STATE_R1    = 6'b01_0000;
    localparam STATE_R2    = 6'b10_0000;
    reg [5:0] curr_state;
    reg [5:0] next_state;
    reg chunk_intlv_end;
    always @(posedge clk_out125M or negedge sys_rst_n)begin
        if(sys_rst_n == 1'b0)begin
            curr_state <= STATE_IDLE;
        end
        else begin
            curr_state <= next_state;
        end
    end
    always @(*)begin
        case(curr_state)
            STATE_IDLE :begin
                if(intlv_start == 1'b1)begin
                    next_state = STATE_W1;
                end
                else begin
                    next_state = STATE_IDLE;
                end
            end
            STATE_W1 :begin
                if((chunk_intlv_end == 1'b1) && (intlv_start == 1'b1))begin
                    next_state = STATE_R1W2;
                end
                else if ((chunk_intlv_end == 1'b1) && (intlv_start == 1'b0)) begin
                    next_state = STATE_R1;
                end
                else begin
                    next_state = STATE_W1;
                end
            end
            STATE_R1W2 :begin
                if((chunk_intlv_end == 1'b1) && (intlv_start == 1'b1))begin
                    next_state = STATE_W1R2;
                end
                else if ((chunk_intlv_end == 1'b1) && (intlv_start == 1'b0)) begin
                    next_state = STATE_R2;
                end
                else begin
                    next_state = STATE_R1W2;
                end
            end
            STATE_W1R2 :begin
                if((chunk_intlv_end == 1'b1) && (intlv_start == 1'b1))begin
                    next_state = STATE_R1W2;
                end
                else if ((chunk_intlv_end == 1'b1) && (intlv_start == 1'b0)) begin
                    next_state = STATE_R1;
                end
                else begin
                    next_state = STATE_W1R2;
                end
            end
            STATE_R1:begin
                if(chunk_intlv_end == 1'b1)begin
                    next_state = STATE_IDLE;
                end
                else begin
                    next_state = STATE_R1;
                end
            end
            STATE_R2:begin
                    if(chunk_intlv_end == 1'b1)begin
                        next_state = STATE_IDLE;
                    end
                    else begin
                        next_state = STATE_R2;
                    end
                end
            default:begin
                next_state = STATE_IDLE;
            end
        endcase 
    end
    reg dpram1_wren;
    reg dpram1_rden;
    reg dpram2_wren;
    reg dpram2_rden;
    reg dpram1_en;
    reg dpram2_en;
    always @(posedge clk_out125M)begin
        case(curr_state)
            STATE_IDLE:begin
                dpram1_wren <= 1'b0;
                dpram1_rden <= 1'b0;
                dpram2_wren <= 1'b0;
                dpram2_rden <= 1'b0;
                dpram1_en <= 1'b0;
                dpram2_en <= 1'b0;
            end
            STATE_W1:begin
                dpram1_wren <= 1'b1;
                dpram1_rden <= 1'b0;
                dpram2_wren <= 1'b0;
                dpram2_rden <= 1'b0;
                dpram1_en <= 1'b1;
                dpram2_en <= 1'b0;
            end
            STATE_R1W2:begin
                dpram1_wren <= 1'b0;
                dpram1_rden <= 1'b1;
                dpram2_wren <= 1'b1;
                dpram2_rden <= 1'b0;
                dpram1_en <= 1'b1;
                dpram2_en <= 1'b1;
            end
            STATE_W1R2:begin
                dpram1_wren <= 1'b1;
                dpram1_rden <= 1'b0;
                dpram2_wren <= 1'b0;
                dpram2_rden <= 1'b1;
                dpram1_en <= 1'b1;
                dpram2_en <= 1'b1;
            end
            STATE_R1:begin
                dpram1_wren <= 1'b0;
                dpram1_rden <= 1'b1;
                dpram2_wren <= 1'b0;
                dpram2_rden <= 1'b0;
                dpram1_en <= 1'b1;
                dpram2_en <= 1'b0;
            end
            STATE_R2:begin
                dpram1_wren <= 1'b0;
                dpram1_rden <= 1'b0;
                dpram2_wren <= 1'b0;
                dpram2_rden <= 1'b1;
                dpram1_en <= 1'b0;
                dpram2_en <= 1'b1;
            end
            default:begin
                dpram1_wren <= 1'b0;
                dpram1_rden <= 1'b0;
                dpram2_wren <= 1'b0;
                dpram2_rden <= 1'b0;
                dpram1_en <= 1'b0;
                dpram2_en <= 1'b0;
            end
        endcase 
    end
    reg [14:0] intlv_cnt;//交织过程控制，0~16319计数，交织深度16320
    localparam intlv_symbol_num = 11'd1020;
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            intlv_cnt <= 15'd0;
        end
        else if(curr_state != STATE_IDLE)begin
            if((curr_state == STATE_W1) && (dpram1_wren == 1'b0) == 1'b1)begin
                intlv_cnt <= 15'd0;//intlv_cnt对齐交织开始时刻，有最高优先级
            end
            else begin
                if ((intlv_cnt >= 1'b0) && (intlv_cnt < intlv_symbol_num - 1'b1)) begin
                    intlv_cnt <= intlv_cnt + 1'b1;
                end
                else if (intlv_cnt == intlv_symbol - 1'b1) begin
                    intlv_cnt <= 15'd0;
                end
                else begin
                    intlv_cnt <= intlv_cnt;
                end
            end
        end
        else begin
            intlv_cnt <= intlv_cnt;
        end
    end
    //段交织结束信号
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if (sys_rst_n == 1'b0) begin
            chunk_intlv_end <= 1'b0;
        end
        else if (intlv_cnt == intlv_symbol_num - 2'd3) begin
            chunk_intlv_end <= 1'b1;
        end
        else begin
            chunk_intlv_end <= 1'b0;
        end
    end
    //交织地址生成
    localparam intlv_frame_num = 8'd4;
    //1020 = 17*5*3*4 
    reg [6:0] intlv_cnt1;//64进制 0~63计数
    reg cout1;//计数器1向计数器2的进位
    reg [1:0] intlv_cnt2;//3进制 0~2计数
    reg cout2;//计数器2向计数器3的进位
    reg [2:0] intlv_cnt3;//5进制 0~4计数
    reg cout3;//计数器3向计数器4的进位
    reg [4:0] intlv_cnt4;//17进制 0~16计数
    
    wire [14:0] intlv_addr;
    reg [14:0] prod1;
    reg [14:0] prod2;
    reg [14:0] prod3;
    wire [14:0] prod4;
    assign prod4 = {10'd0,intlv_cnt4};
    assign intlv_addr = prod1 + prod2 + prod3 + prod4;
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            intlv_cnt1 <= 7'd0;
            cout1 <= 1'b0;
            prod1 <= 15'd0;
        end
        else if(curr_state != STATE_IDLE)begin
            if((curr_state == STATE_W1) && (dpram1_wren == 1'b0) == 1'b1)begin
                intlv_cnt1 <= 7'd0;
                cout1 <= 1'b0;
                prod1 <= 15'd0;
            end
            else if(intlv_cnt == intlv_symbol_num - 1'b1)begin
                intlv_cnt1 <= 7'd0;
                cout1 <= 1'b0;
                prod1 <= 15'd0;
            end
            else begin
                if((intlv_cnt1 >= 1'b0) && (intlv_cnt1 < intlv_frame_num - 2'd2))begin
                    intlv_cnt1 <= intlv_cnt1 + 1'b1;
                    cout1 <= 1'b0;
                    prod1 <= prod1 + 15'd255;//17*5*3
                end
                else if (intlv_cnt1 == intlv_frame_num - 2'd2) begin
                    intlv_cnt1 <= intlv_cnt1 + 1'b1;
                    cout1 <= 1'b1;
                    prod1 <= prod1 + 15'd255;//17*5*3
                end
                else if (intlv_cnt1 == intlv_frame_num - 1'b1) begin
                    intlv_cnt1 <= 7'd0;
                    cout1 <= 1'b0;
                    prod1 <= 15'd0;
                end
                else begin
                    intlv_cnt1 <= 2'd0;
                    cout1 <= 1'b0;
                    prod1 <= 15'd0;
                end
            end
        end
        else begin
            intlv_cnt1 <= intlv_cnt1;
            cout1 <= 1'b0;
            prod1 <= prod1;
        end
    end
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            intlv_cnt2 <= 2'd0;
            prod2 <= 15'd0;
        end
        else if((curr_state == STATE_W1) && (dpram1_wren == 1'b0) == 1'b1)begin
            intlv_cnt2 <= 2'd0;
            prod2 <= 15'd0;
        end
        else if(intlv_cnt == intlv_symbol_num - 1'b1)begin
            intlv_cnt2 <= 2'd0;
            prod2 <= 15'd0;
        end
        else if (cout1 == 1'b1) begin
            if((intlv_cnt2 <= 2'd1) && (intlv_cnt2 >= 2'd0))begin
                intlv_cnt2 <= intlv_cnt2 + 1'b1;
                prod2 <= prod2 + 15'd85;
            end
            else if (intlv_cnt2 == 2'd2) begin
                intlv_cnt2 <= 2'd0;
                prod2 <= 15'd0;
            end
            else begin
                intlv_cnt2 <= 2'd0;
                prod2 <= 15'd0;
            end
        end
        else begin
            intlv_cnt2 <= intlv_cnt2;
            prod2 <= prod2;
        end
    end
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            cout2 <= 1'b0;
        end
        else if ((intlv_cnt1 == intlv_num - 2'd2) && (intlv_cnt2 == 2'd2)) begin
            cout2 <= 1'b1;
        end
        else begin
            cout2 <= 1'b0;
        end
    end
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            intlv_cnt3 <= 3'd0;
            prod3 <= 15'd0;
        end
        else if((curr_state == STATE_W1) && (dpram1_wren == 1'b0) == 1'b1)begin
            intlv_cnt3 <= 3'd0;
            prod3 <= 15'd0;
        end
        else if(intlv_cnt == intlv_symbol_num - 1'b1)begin
            intlv_cnt3 <= 3'd0;
            prod3 <= 15'd0;
        end
        else if(cout2 == 1'b1)begin
            if((intlv_cnt3 <= 3'd3) && (intlv_cnt3 >= 3'd0))begin
                intlv_cnt3 <= intlv_cnt3 + 1'b1;
                prod3 <= prod3 + 15'd17;
            end
            else if (intlv_cnt3 == 3'd4) begin
                intlv_cnt3 <= 3'd0;
                prod3 <= 15'd0;
            end
            else begin
                intlv_cnt3 <= 3'd0;
                prod3 <= 15'd0;
            end
        end
        else begin
            intlv_cnt3 <= intlv_cnt3;
            prod3 <= prod3;
        end
    end
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            cout3 <= 1'b0;
        end
        else if ((intlv_cnt1 == intlv_num - 2'd2) && (intlv_cnt2 == 2'd2) && (intlv_cnt3 == 3'd4)) begin
            cout3 <= 1'b1;
        end
        else begin
            cout3 <= 1'b0;
        end
    end
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            intlv_cnt4 <= 15'd0;
        end
        else if((curr_state == STATE_W1) && (dpram1_wren == 1'b0) == 1'b1)begin
            intlv_cnt4 <= 15'd0;
        end
        else if(intlv_cnt == intlv_symbol_num - 1'b1)begin
            intlv_cnt4 <= 15'd0;
        end
        else if(cout3 == 1'b1)begin
            if((intlv_cnt4 < 5'd16) && (intlv_cnt4 >= 5'd0))begin
                intlv_cnt4 <= intlv_cnt4 + 1'b1;
            end
            else if (intlv_cnt4 == 5'd16) begin
                intlv_cnt4 <= 15'd0;
            end
            else begin
                intlv_cnt4 <= 15'd0;
            end
        end
        else begin
            intlv_cnt4 <= intlv_cnt4;
        end
    end
    wire [7:0] dpram1_out;
    wire [7:0] dpram2_out;

    reg [1:0] dpram1_rden_delay;
    reg [1:0] dpram2_rden_delay;
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            dpram1_rden_delay <= 2'b0;
            dpram2_rden_delay <= 2'b0;
        end
        else begin
            dpram1_rden_delay <= {dpram1_rden_delay[0],dpram1_rden};
            dpram2_rden_delay <= {dpram2_rden_delay[0],dpram2_rden};
        end
    end
    wire rd_en1;
    wire rd_en2;
    assign rd_en1 = dpram1_rden_delay[1] || dpram1_rden;
    assign rd_en2 = dpram2_rden_delay[1] || dpram2_rden;

    intlv_dpram intlv_dpram_U1(
        .clka(clk_out125M),
        .ena(dpram1_en),
        .wea(dpram1_wren),
        .addra(intlv_cnt),
        .dina(RScode_reg),
        .clkb(clk_out125M),
        .enb(rd_en1),
        .addrb(intlv_addr),
        .doutb(dpram1_out)
    );
    intlv_dpram intlv_dpram_U2(
        .clka(clk_out125M),
        .ena(dpram2_en),
        .wea(dpram2_wren),
        .addra(intlv_cnt),
        .dina(RScode_reg),
        .clkb(clk_out125M),
        .enb(rd_en2),
        .addrb(intlv_addr),
        .doutb(dpram2_out)
    );
    reg rd_flag1;
    reg rd_flag2;

    reg delay_reg1;
    reg delay_reg2;
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            rd_flag1 <= 1'b0;
            rd_flag2 <= 1'b0;

            delay_reg1 <= 1'b0;
            delay_reg2 <= 1'b0;
        end
        else begin
            delay_reg1 <= dpram1_rden;
            rd_flag1 <= delay_reg1;
            
            delay_reg2 <= dpram2_rden;
            rd_flag2 <= delay_reg2;
        end
    end
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            intlv_out <= 8'd0;
        end
        else if ((rd_flag1 || rd_flag2) == 1'b1) begin
            if(rd_flag1 == 1'b1)begin
                intlv_out <= dpram1_out;
            end
            else begin
                intlv_out <= dpram2_out;
            end
        end
        else begin
            intlv_out <= 8'd0;
        end
    end
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if (sys_rst_n == 1'b0) begin
            next_intlv_start <= 1'b0;
        end
        else if ((dpram1_rden || dpram2_rden) == 1'b1) begin
            next_intlv_start <= 1'b1;
        end
        else begin
            next_intlv_start <= next_intlv_start;
        end
    end
endmodule
