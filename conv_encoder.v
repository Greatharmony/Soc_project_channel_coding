module conv_encoder #(parameter N=3) 
(input wire clk, input wire reset, input wire [N-1:0]din ,
output reg [N-1:0] dout0, output reg [N-1:0] dout1);

// Shift register (Constraint length K = 3 ?? ???? ??? K-1 = 2?)
reg [1:0] shift_reg;
// temp: ?? ?? (N??)? ?? ?? (2??)? ?? ?? ??
wire [N+1:0] temp;
assign temp = {din, shift_reg};
integer k;
always @(posedge clk or negedge reset) begin
        if (!reset) begin //???
            shift_reg <= 2'b00;
            dout0     <= {N{1'b0}};
            dout1     <= {N{1'b0}}; //N???? 0
        end 
	else begin
		for(k = 0; k <N; k=k+1) begin
            // ?? ???(Generator polynomials)? ?? XOR ??
            // G1 = 1 + D + D^2  
            // G2 = 1 + D^2
            	dout0[N-1-k] <= temp[N+1-k] ^ temp[N-k] ^ temp[N-1-k];
            	dout1[N-1-k] <= temp[N+1-k] ^ temp[N-1-k];
		end
        end
	shift_reg <= din[1:0];
end

endmodule
