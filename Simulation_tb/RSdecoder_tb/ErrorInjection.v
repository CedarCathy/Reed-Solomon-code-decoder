module ErrorInjection(
    input  wire         clk_out125M,
    input  wire         sys_rst_n,
    input  wire [7 : 0] intlv_out,
    input  wire         intlv_out_sync,
    
    output wire [7 : 0] intlv_out_err
    );
    reg [16:0] error_cnt;
    reg [14:0] init_cnt;
    localparam init_loc = 457;
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if((sys_rst_n == 1'b0) || (intlv_out_sync == 1'b0))begin
            init_cnt <= 15'd0;
        end
        else begin
            if(init_cnt < init_loc)begin
                init_cnt <= init_cnt + 1'b1;
            end
            else begin
                init_cnt <= init_loc + 1'b1;
            end
        end
    end
    localparam error_num = 17'd130560;
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if((sys_rst_n == 1'b0) || (intlv_out_sync == 1'b0))begin
            error_cnt <= 17'd0;
        end
        else if(init_cnt >= init_loc) begin
            if(error_cnt < error_num)begin
                error_cnt <= error_cnt + 1'b1;
            end
            else begin
                error_cnt <= error_num + 1'b1;
            end
        end
        else begin
            error_cnt <= 17'd0;
        end
    end
    reg err_flag;
    always @(posedge clk_out125M or negedge sys_rst_n) begin
        if((sys_rst_n == 1'b0) || (intlv_out_sync == 1'b0))begin
            err_flag <= 1'b0;
        end
        else if((error_cnt >= 17'd1) && (error_cnt <= error_num))begin
            err_flag <= 1'b1;
        end
        else begin
            err_flag <= 1'b0;
        end
    end
    assign intlv_out_err = (err_flag)?8'd0:intlv_out;
endmodule
