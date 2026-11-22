module conv_encoder #(parameter N=3) 
(input wire clk, input wire reset, input wire [N-1:0] din, input wire sel,
output reg dout0, dout1, output reg [(2*N)-1:0] out);

// Shift register (Constraint length K = 3 ?? ???? ??? K-1 = 2?)
reg [1:0] shift_reg;

wire [N+1:0] temp;
assign temp = {din, shift_reg};
integer k;
always @(posedge clk or negedge reset) begin
        if (!reset) begin 
            shift_reg <= 2'b00;
            dout0     <= 1'b0;
            dout1     <= 1'b0; 
        end 
	else if (!sel) begin
		for(k = 0; k <N; k=k+1) begin
            // G1 = 1 + D + D^2  
            // G2 = 1 + D^2
            	dout0 <= temp[N+1-k] ^ temp[N-k] ^ temp[N-1-k];
            	dout1 <= temp[N+1-k] ^ temp[N-1-k];
            	out[((N - k) * 2 - 1) -: 2] <= {(temp[N+1-k] ^ temp[N-k] ^ temp[N-1-k]), (temp[N+1-k] ^ temp[N-1-k])};
		end
			shift_reg <= din[1:0];
        end
end

endmodule
