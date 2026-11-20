`timescale 1ns/1ns
module viterbi_path #(parameter K =3, parameter FRAME_BITS = 6, parameter PAIR_W = $clog2(FRAME_BITS +1))
(input wire clk, input wire reset, 
//decoder fsm
input wire path_init,
input wire acs_en, 
input wire [K-2: 0] state_idx, //what ACS is doing right now
input wire [PAIR_W-1:0] pair, //what pair are we now?
input wire commit_en,
input wire fin_en, //final
//viterbi_bm_sel
input wire [K-2:0] prev_s0, 
input wire [K-2:0] prev_s1,
input wire dec_bit,
//acs
input wire decision,
input wire [K-2:0] best_state, 
//output
output wire [FRAME_BITS-1:0] path_bits
);

parameter NS = 1 << (K-1);

reg [FRAME_BITS-1:0] path [0:NS-1];
reg [FRAME_BITS-1:0] npath [0:NS-1];

wire [FRAME_BITS-1:0] note0 = path[prev_s0];
wire [FRAME_BITS-1:0] note1 = path[prev_s1];
wire [FRAME_BITS-1:0] chosen = decision ? note1:note0;

wire [FRAME_BITS-1:0] slot     = {{(FRAME_BITS-1){1'b0}}, 1'b1} << pair;
wire [FRAME_BITS-1:0] new_note = (chosen & ~slot) | ({FRAME_BITS{dec_bit}} & slot);

integer i;
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		for(i=0; i<NS; i= i+1) begin
			path[i] <= {FRAME_BITS{1'b0}};
			npath[i] <= {FRAME_BITS{1'b0}};
		end
	end else if (path_init) begin
		for(i=0; i<NS; i= i+1) begin
			path[i] <= {FRAME_BITS{1'b0}};
			npath[i] <= {FRAME_BITS{1'b0}};
		end
	end else begin
		if (acs_en)
			npath[state_idx] <= new_note;
            	if (commit_en)
                	for (i = 0; i < NS; i = i + 1)
                    		path[i] <= npath[i];
        	end
    	end	
assign path_bits = path[best_state];
wire unused_fin = fin_en;
endmodule