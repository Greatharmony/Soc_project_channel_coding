`timescale 1ns / 1ns

module conv_encoder_tb;

// N ?? ??? ??
localparam N = 5;

reg clk;
reg reset;
reg [N-1:0] din;
wire [N-1:0] dout0;
wire [N-1:0] dout1;

integer i;

conv_encoder #(N) U1 (clk, reset, din, dout0, dout1);

always #5 clk = ~clk;

initial begin
	clk   = 0;
        reset = 0;
        din   = {N{1'b0}};

        #20;
        reset = 1;

        // 10?? ?? N?? ?? ??? ??
        for (i = 0; i < 10; i = i + 1) begin
            @(negedge clk);
            din = $random; // N?? ?? ?? ?? N??? ?? ???
	end

        // ???? ???(Flush)? ?? 0 ??
	@(negedge clk);
		din = {N{1'b0}};
		#30;
        	$finish;
end

    // ?? ????
initial begin
        $monitor("Time=%0t ns | N=%0d | reset=%b | din=%b | dout0=%b, dout1=%b", 
                 $time, N, reset, din, dout0, dout1);
end
endmodule