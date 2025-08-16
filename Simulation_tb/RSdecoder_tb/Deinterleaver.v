`timescale 1ns / 1ps
module Deinterleaver(
    input  wire         clk_out125M,
    input  wire         sys_rst_n,
    input  wire [7 : 0] data_deintlv_out,
    input  wire         deintlv_start,
    
    output reg  [7 : 0] deintlv_out,
    output wire         RSdecode_start
);
    localparam STATE_IDLE  = 6'b00_0001;
    localparam STATE_W1    = 6'b00_0010;
    localparam STATE_R1W2  = 6'b00_0100;
    localparam STATE_W1R2  = 6'b00_1000;
    localparam STATE_R1    = 6'b01_0000;
    localparam STATE_R2    = 6'b10_0000;
    reg [5:0] curr_state;
    reg [5:0] next_state;
    reg chunk_deintlv_end;
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
                if(deintlv_start == 1'b1)begin
                    next_state = STATE_W1;
                end
                else begin
                    next_state = STATE_IDLE;
                end
            end
            STATE_W1 :begin
                if((chunk_deintlv_end == 1'b1) && (deintlv_start == 1'b1))begin
                    next_state = STATE_R1W2;
                end
                else if ((chunk_deintlv_end == 1'b1) && (deintlv_start == 1'b0)) begin
                    next_state = STATE_R1;
                end
                else begin
                    next_state = STATE_W1;
                end
            end
            STATE_R1W2 :begin
                if((chunk_deintlv_end == 1'b1) && (deintlv_start == 1'b1))begin
                    next_state = STATE_W1R2;
                end
                else if ((chunk_deintlv_end == 1'b1) && (deintlv_start == 1'b0)) begin
                    next_state = STATE_R2;
                end
                else begin
                    next_state = STATE_R1W2;
                end
            end
            STATE_W1R2 :begin
                if((chunk_deintlv_end == 1'b1) && (deintlv_start == 1'b1))begin
                    next_state = STATE_R1W2;
                end
                else if ((chunk_deintlv_end == 1'b1) && (deintlv_start == 1'b0)) begin
                    next_state = STATE_R1;
                end
                else begin
                    next_state = STATE_W1R2;
                end
            end
            STATE_R1:begin
                if(chunk_deintlv_end == 1'b1)begin
                    next_state = STATE_IDLE;
                end
                else begin
                    next_state = STATE_R1;
                end
            end
            STATE_R2:begin
                    if(chunk_deintlv_end == 1'b1)begin
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
    reg [14:0] deintlv_cnt;//解交织过程控制，0~1019计数，交织深度1020
    localparam deintlv_symbol_num = 11'd1020;
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            deintlv_cnt <= 10'd0;
        end
        else if(curr_state != STATE_IDLE)begin
            if((curr_state == STATE_W1) && (dpram1_wren == 1'b0) == 1'b1)begin
                deintlv_cnt <= 10'd0;//deintlv_cnt对齐解交织开始时刻，有最高优先级
            end
            else begin
                if ((deintlv_cnt >= 1'b0) && (deintlv_cnt < deintlv_symbol_num - 1'b1)) begin
                    deintlv_cnt <= deintlv_cnt + 1'b1;
                end
                else if (deintlv_cnt == intlv_symbol_num - 1'b1) begin
                    deintlv_cnt <= 10'd0;
                end
                else begin
                    deintlv_cnt <= deintlv_cnt;
                end
            end
        end
        else begin
            deintlv_cnt <= deintlv_cnt;
        end
    end
    //段解交织结束信号
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if (sys_rst_n == 1'b0) begin
            chunk_deintlv_end <= 1'b0;
        end
        else if (deintlv_cnt == deintlv_symbol_num - 2'd3) begin
            chunk_deintlv_end <= 1'b1;
        end
        else begin
            chunk_deintlv_end <= 1'b0;
        end
    end
    //解交织地址生成
    localparam deintlv_num = 8'd4;
    //1020 = 4*3*5*17
    reg [4:0] deintlv_cnt1;//17进制 0~16计数
    reg cout1;//计数器1向计数器2的进位
    reg [2:0] deintlv_cnt2;//5进制 0~4计数
    reg cout2;//计数器2向计数器3的进位
    reg [1:0] deintlv_cnt3;//3进制 0~2计数
    reg cout3;//计数器3向计数器4的进位
    reg [6:0] deintlv_cnt4;//64进制 0~63计数
    wire [14:0] deintlv_addr;
    reg [14:0] prod1;
    reg [14:0] prod2;
    reg [14:0] prod3;
    wire [14:0] prod4;
    assign prod4 = {10'd0,deintlv_cnt4};
    assign deintlv_addr = prod1 + prod2 + prod3 + prod4;
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            deintlv_cnt1 <= 5'd0;
            cout1 <= 1'b0;
            prod1 <= 15'd0;
        end
        else if(curr_state != STATE_IDLE)begin
            if((curr_state == STATE_W1) && (dpram1_wren == 1'b0) == 1'b1)begin
                deintlv_cnt1 <= 5'd0;
                cout1 <= 1'b0;
                prod1 <= 15'd0;
            end
            else if(deintlv_cnt == deintlv_symbol_num - 1'b1)begin
                deintlv_cnt1 <= 5'd0;
                cout1 <= 1'b0;
                prod1 <= 15'd0;
            end
            else begin
                if((deintlv_cnt1 < 5'd15) && (deintlv_cnt1 >= 5'd0) == 1'b1)begin
                    deintlv_cnt1 <= deintlv_cnt1 + 1'b1;
                    cout1 <= 1'b0;
                    prod1 <= prod1 + 15'd60;//4*3*5
                end
                else if(deintlv_cnt1 == 5'd15)begin
                    deintlv_cnt1 <= deintlv_cnt1 + 1'b1;
                    cout1 <= 1'b1;
                    prod1 <= prod1 + 15'd60;//4*3*5
                end
                else if (deintlv_cnt1 == 5'd16)begin
                    deintlv_cnt1 <= 5'd0;
                    cout1 <= 1'b0;
                    prod1 <= 10'd0;
                end
                else begin
                    deintlv_cnt1 <= 5'd0;
                    cout1 <= 1'b0;
                    prod1 <= 10'd0;
                end
            end
        end
        else begin
            deintlv_cnt1 <= deintlv_cnt1;
            cout1 <= 1'b0;
            prod1 <= prod1;
        end
    end
    //5进制计数
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            deintlv_cnt2 <= 3'd0;
            prod2 <= 15'd0;
        end
        else if((curr_state == STATE_W1) && (dpram1_wren == 1'b0) == 1'b1)begin
            deintlv_cnt2 <= 3'd0;
            prod2 <= 15'd0;
        end
        else if(deintlv_cnt == deintlv_symbol_num - 1'b1)begin
            deintlv_cnt2 <= 3'd0;
            prod2 <= 15'd0;
        end
        else if (cout1 == 1'b1) begin
            if((deintlv_cnt2 <= 3'd3) && (deintlv_cnt2 >= 3'd0))begin
                deintlv_cnt2 <= deintlv_cnt2 + 1'b1;
                prod2 <= prod2 + 15'd12;//4*3
            end
            else if (deintlv_cnt2 == 3'd4) begin
                deintlv_cnt2 <= 3'd0;
                prod2 <= 15'd0;
            end
            else begin
                deintlv_cnt2 <= 3'd0;
                prod2 <= 15'd0;
            end
        end
        else begin
            deintlv_cnt2 <= deintlv_cnt2;
            prod2 <= prod2;
        end
    end
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            cout2 <= 1'b0;
        end
        else if ((deintlv_cnt1 == 5'd15) && (deintlv_cnt2 == 3'd4)) begin
            cout2 <= 1'b1;
        end
        else begin
            cout2 <= 1'b0;
        end
    end
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            deintlv_cnt3 <= 2'd0;
            prod3 <= 15'd0;
        end
        else if((curr_state == STATE_W1) && (dpram1_wren == 1'b0) == 1'b1)begin
            deintlv_cnt3 <= 2'd0;
            prod3 <= 15'd0;
        end
        else if(deintlv_cnt == deintlv_symbol_num - 1'b1)begin
            deintlv_cnt3 <= 2'd0;
            prod3 <= 15'd0;
        end
        else if(cout2 == 1'b1)begin
            if((deintlv_cnt3 <= 8'd1) && (deintlv_cnt3 >= 2'd0))begin
                deintlv_cnt3 <= deintlv_cnt3 + 1'b1;
                prod3 <= prod3 + 15'd4;
            end
            else if (deintlv_cnt3 == 8'd2) begin
                deintlv_cnt3 <= 2'd0;
                prod3 <= 15'd0;
            end
            else begin
                deintlv_cnt3 <= 2'd0;
                prod3 <= 15'd0;
            end
        end
        else begin
            deintlv_cnt3 <= deintlv_cnt3;
            prod3 <= prod3;
        end
    end
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            cout3 <= 1'b0;
        end
        else if ((deintlv_cnt1 == 5'd15) && (deintlv_cnt2 == 3'd4) && (deintlv_cnt3 == 2'd2)) begin
            cout3 <= 1'b1;
        end
        else begin
            cout3 <= 1'b0;
        end
    end
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)begin
            deintlv_cnt4 <= 7'd0;
        end
        else if((curr_state == STATE_W1) && (dpram1_wren == 1'b0) == 1'b1)begin
            deintlv_cnt4 <= 7'd0;
        end
        else if(deintlv_cnt == deintlv_symbol_num - 1'b1)begin
            deintlv_cnt4 <= 7'd0;
        end
        else if(cout3 == 1'b1)begin
            if((deintlv_cnt4 <= deintlv_num - 2'd2) && (deintlv_cnt4 >= 2'd0))begin
                deintlv_cnt4 <= deintlv_cnt4 + 1'b1;
            end
            else if (deintlv_cnt4 == deintlv_num - 1'd1) begin
                deintlv_cnt4 <= 7'd0;
            end
            else begin
                deintlv_cnt4 <= 7'd0;
            end
        end
        else begin
            deintlv_cnt4 <= deintlv_cnt4;
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
    intlv_dpram deintlv_dpram_U1(
        .clka(clk_out125M),
        .ena(dpram1_en),
        .wea(dpram1_wren),
        .addra(deintlv_cnt),
        .dina(data_deintlv_out),
        .clkb(clk_out125M),
        .enb(rd_en1),
        .addrb(deintlv_addr),
        .doutb(dpram1_out)
    );
    intlv_dpram deintlv_dpram_U2(
        .clka(clk_out125M),
        .ena(dpram2_en),
        .wea(dpram2_wren),
        .addra(deintlv_cnt),
        .dina(data_deintlv_out),
        .clkb(clk_out125M),
        .enb(rd_en2),
        .addrb(deintlv_addr),
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
            deintlv_out <= 8'd0;
        end
        else if ((rd_flag1 || rd_flag2) == 1'b1) begin
            if(rd_flag1 == 1'b1)begin
                deintlv_out <= dpram1_out;
            end
            else begin
                deintlv_out <= dpram2_out;
            end
        end
        else begin
            deintlv_out <= 8'd0;
        end
    end
    //检测数据流的结束标志
    reg [12:0] end_state;
    localparam END_STATE_IDLE = 11'b000_0000_0001;
    localparam END_STATE_0    = 11'b000_0000_0010;
    localparam END_STATE_1    = 11'b000_0000_0100;
    localparam END_STATE_2    = 11'b000_0000_1000;
    localparam END_STATE_3    = 11'b000_0001_0000;
    localparam END_STATE_4    = 11'b000_0010_0000;
    localparam END_STATE_5    = 11'b000_0100_0000;
    localparam END_STATE_6    = 11'b000_1000_0000;
    localparam END_STATE_7    = 11'b001_0000_0000;
    localparam END_STATE_8    = 11'b010_0000_0000;
    localparam END_STATE_9    = 11'b100_0000_0000;
    reg RS_end_symbol;
    always @(posedge clk_out125M) begin
        case (end_state)
            END_STATE_IDLE:begin
                if(RSdecode_start == 1'b0)begin
                    end_state <= END_STATE_0;
                end
                else begin
                    end_state <= END_STATE_IDLE;
                end
                RS_end_symbol <= 1'b0;
            end 
            END_STATE_0:begin
                if(deintlv_out == 8'd0)begin
                    end_state <= END_STATE_1;
                end
                else begin
                    end_state <= END_STATE_0;
                end
                RS_end_symbol <= 1'b0;
            end    
            END_STATE_1:begin
                if(deintlv_out == 8'd0)begin
                    end_state <= END_STATE_2;
                end
                else begin
                    end_state <= END_STATE_0;
                end
                RS_end_symbol <= 1'b0;
            end    
            END_STATE_2:begin
                if(deintlv_out == 8'd0)begin
                    end_state <= END_STATE_3;
                end
                else begin
                    end_state <= END_STATE_0;
                end
                RS_end_symbol <= 1'b0;
            end    
            END_STATE_3:begin
                if(deintlv_out == 8'd0)begin
                    end_state <= END_STATE_4;
                end
                else begin
                    end_state <= END_STATE_0;
                end
                RS_end_symbol <= 1'b0;
            end    
            END_STATE_4:begin
                if(deintlv_out == 8'd0)begin
                    end_state <= END_STATE_5;
                end
                else begin
                    end_state <= END_STATE_0;
                end
                RS_end_symbol <= 1'b0;
            end
            END_STATE_5:begin
                if(deintlv_out == 8'd0)begin
                    end_state <= END_STATE_6;
                end
                else begin
                    end_state <= END_STATE_0;
                end
                RS_end_symbol <= 1'b0;
            end
            END_STATE_6:begin
                if(deintlv_out == 8'd0)begin
                    end_state <= END_STATE_7;
                end
                else begin
                    end_state <= END_STATE_0;
                end
                RS_end_symbol <= 1'b0;
            end
            END_STATE_7:begin
                if(deintlv_out == 8'd0)begin
                    end_state <= END_STATE_8;
                end
                else begin
                    end_state <= END_STATE_0;
                end
                RS_end_symbol <= 1'b0;
            end
            END_STATE_8:begin
                if(deintlv_out == 8'd0)begin
                    end_state <= END_STATE_9;
                end
                else begin
                    end_state <= END_STATE_0;
                end
                RS_end_symbol <= 1'b0;
            end
            END_STATE_9:begin
                if(sys_rst_n == 1'b0)begin
                    end_state <= END_STATE_IDLE;
                end
                else begin
                    end_state <= END_STATE_9;
                end
                RS_end_symbol <= 1'b1;
            end   
            default:begin
                end_state <= END_STATE_IDLE;
                RS_end_symbol <= 1'b0;
            end
        endcase
    end
    reg [1:0] RSdecode_start_reg;
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if (sys_rst_n == 1'b0) begin
            RSdecode_start_reg[1:0] <= 2'b11;
        end
        else if ((dpram1_rden || dpram2_rden) == 1'b1) begin
            RSdecode_start_reg[0] <= 1'b0;
            RSdecode_start_reg[1] <= RSdecode_start_reg[0];
        end
        else begin
            RSdecode_start_reg[1:0] <= 2'b11;
        end
    end
    reg [1:0] RSdecode_start_broaden;
    always @(posedge clk_out125M) begin
        RSdecode_start_broaden[0] <= RSdecode_start_reg[1];
        RSdecode_start_broaden[1] <= RSdecode_start_broaden[0];
    end
    assign RSdecode_start = RSdecode_start_reg[1] & RSdecode_start_broaden[1] | RS_end_symbol;
endmodule 