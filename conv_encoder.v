
module conv_encoder #(parameter N=3)
(
    input wire clk,
    input wire reset,
    input wire [N-1:0] din,
    input wire sel,
    input wire err_sw,

    output reg dout0,
    output reg dout1,
    output reg [(2*N)-1:0] out
);

// K = 3, Memory = 2
reg [1:0] temp;
reg [1:0] next_temp;

reg [(2*N)-1:0] next_out;

integer k;

// Combinational Logic
always @(*) begin
    	next_temp = temp;
    	next_out = {(2*N){1'b0}};

   	for (k=0; k<N; k=k+1) begin
        	// G1 = 1 + D + D^2
        	next_out[(2*N-1)-(2*k)] = din[N-1-k] ^ next_temp[1] ^ next_temp[0];
        	// G2 = 1 + D^2
       		next_out[(2*N-2)-(2*k)] = din[N-1-k] ^ next_temp[0];
       		// Update temporary shift register
        	next_temp = {din[N-1-k], next_temp[1]};
    	end
	if (err_sw) begin
        	next_out[(2*N-1) - 2*1] = ~next_out[(2*N-1) - 2*1]; // N=3일 때 next_out[3]
    	end
end

// Sequential Logic
always @(posedge clk or negedge reset) begin

    if (!reset) begin
        temp <= 2'b00;
        out <= {(2*N){1'b0}};
        dout0 <= 1'b0;
        dout1 <= 1'b0;
    end

    else if (!sel) begin

        temp <= next_temp;
        out <= next_out;

        dout0 <= next_out[1];
        dout1 <= next_out[0];

    end

end

endmodule
