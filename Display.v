module conv_Display (
    input            clk,
    input            rst,
    input            proc_pls,
    input      [5:0] out,
    output reg [6:0] seg,
    output reg [7:0] digit
);
    reg [13:0] count;
    reg        clk_10000;
    reg        show_proc; // 0이면 맨처음 이진수, 누르면(1) process 뜨게 

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            count <= 14'd0;
            clk_10000 <= 1'b0;
        end else if (count == 14'd9999) begin
            count <= 14'd0;
            clk_10000 <= ~clk_10000;
        end else begin
            count <= count + 14'd1;
        end
    end
    //process 부분
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            show_proc <= 1'b0;
        end else if (proc_pls) begin
            show_proc <= ~show_proc;
        end
    end

    // Active-Low digit 스캔 (오른쪽부터 6자리: out[0] ~ out[5])
    always @(posedge clk_10000 or negedge rst) begin
        if (!rst) begin
            digit <= 8'b11111110;
        end else begin
            case (digit)
                8'b11111110: digit <= 8'b11111101;
                8'b11111101: digit <= 8'b11111011;
                8'b11111011: digit <= 8'b11110111;
                8'b11110111: digit <= 8'b11101111;
                8'b11101111: digit <= 8'b11011111;
                8'b11011111: digit <= 8'b10111111;
                8'b10111111: digit <= 8'b01111111;
                8'b01111111: digit <= 8'b11111110;
                default:     digit <= 8'b11111110;
            endcase
        end
    end
    reg bit_val;
    reg bit_en;
    reg [6:0] proc_seg;
    
    always @(*) begin
        bit_en  = 1'b1;
        bit_val = 1'b0;
        case (digit)
            8'b11111110: bit_val = out[0]; // dout0[0]
            8'b11111101: bit_val = out[1]; // dout0[1]
            8'b11111011: bit_val = out[2]; // dout0[2]
            8'b11110111: bit_val = out[3]; // dout1[0]
            8'b11101111: bit_val = out[4]; // dout1[1]
            8'b11011111: bit_val = out[5]; // dout1[2]
            default: bit_en = 1'b0;
        endcase
    end

    // show_proc == 1 일 때 process출력 
    always @(*) begin
        case (digit)
            8'b10111111: proc_seg = 7'b0011000; // P
            8'b11011111: proc_seg = 7'b1111010; // r
            8'b11101111: proc_seg = 7'b1100010; // o
            8'b11110111: proc_seg = 7'b0110001; // c
            8'b11111011: proc_seg = 7'b0110000; // e
            8'b11111101: proc_seg = 7'b0100100; // s
            8'b11111110: proc_seg = 7'b0100100; // s
            default:     proc_seg = 7'b1111111; // OFF
        endcase
    end

    // 최종 seg 출력 (두가지 경우)
    always @(*) begin
        if (show_proc) begin
            seg = proc_seg;
        end else if (!bit_en) begin
            seg = 7'b1111111; // 미사용 자리 OFF
        end else if (bit_val == 1'b1) begin
            seg = 7'b1001111; // 1
        end else begin
            seg = 7'b0000001; // 0
        end
    end
endmodule