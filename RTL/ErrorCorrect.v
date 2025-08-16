module ErrorCorrect#(
    parameter n = 255,  //data frame length
    parameter k = 239,  //valid message length
    parameter t = 8,    //this decoder can only correct errors less than 8
    parameter m = 8     //data width
)
(
    input  wire           clk_in,
    input  wire           sys_rst_n,
    input  wire [m-1 : 0] data_shifted,
    input  wire [m-1 : 0] Error_approx,
    input  wire [m-1 : 0] Error_approx_latch,
    input  wire [  3 : 0] end_operation_cnt,
    input  wire           Error_Symbol,
    input  wire           End_Error_Symbol,

    output reg  [m-1 : 0] data_out
    );

    reg [m-1 : 0] Serial_machine_cnt;
    always @(posedge sys_clk) begin
        if(sys_rst_n == 1'b0)begin
            Serial_machine_cnt <= 8'd0;
        end
        else if(end_operation_cnt == 4'd14)begin
            Serial_machine_cnt <= 8'd1;
        end
        else if((Serial_machine_cnt >= 8'd1) && (Serial_machine_cnt <= 8'd254))begin
            Serial_machine_cnt <= Serial_machine_cnt + 1'b1;
        end
        else begin
            Serial_machine_cnt <= 8'd0;
        end
    end
    always@(posedge sys_clk or negedge sys_rst_n)begin
        if(sys_rst_n == 1'b0)begin
            data_out <= 8'd0;
        end
        else if((Serial_machine_cnt >= 8'd1) && (Serial_machine_cnt <= 8'd254)) begin
            if(Error_symbol == 1'b1)begin
                data_out <= data_shifted ^ Error_approx;
            end
            else begin
                data_out <= data_shifted;
            end
        end
        else if (Serial_machine_cnt == 8'd255) begin
            if(End_Error_symbol == 1'b1)begin
                data_out <= data_shifted ^ Error_approx_latch;
            end
            else begin
                data_out <= data_shifted;
            end
        end
        else begin
            data_out <= 8'd0;
        end
    end
endmodule
