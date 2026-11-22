module button (input clk, reset, btn, output wire pls);

reg btn1 = 1'b0;
reg btn2 = 1'b0;
reg btn3 = 1'b0;

always @(posedge clk) begin
    if(!reset) begin
        btn1 <= 1'b0;
        btn2 <= 1'b0;
        btn3 <= 1'b0;
    end
    else begin     
        btn1 <= btn;
        btn2 <= btn1;
        btn3 <= btn2;
    end
end

assign pls = btn2 & !btn3;

endmodule

