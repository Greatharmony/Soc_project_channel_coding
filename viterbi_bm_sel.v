// viterbi_bm_sel.v : choosing branch metric (trellis + expected output)

module viterbi_bm_sel #(parameter K = 3,parameter G0 = 3'b111, parameter G1 = 3'b101, parameter BM_W = 6)
(input wire [K-2:0] ns, input wire [BM_W-1:0] bm00, input  wire [BM_W-1:0] bm01, input  wire [BM_W-1:0] bm10, input  wire [BM_W-1:0] bm11,
output wire [K-2:0] prev_s0, output wire [K-2:0] prev_s1, output wire [1:0] cw0, output wire [1:0] cw1,     
output wire [BM_W-1:0] bm_b0, output wire [BM_W-1:0] bm_b1,  
output wire dec_bit
);
//window block: mem + new_block
wire [K-1:0] win0 = {ns, 1'b0};
wire [K-1:0] win1 = {ns, 1'b1};

//codeword block: count num of 1 when passing G0, G1 
//if 1 num is odd == 1, even == 0
assign cw0 = { ^(win0 & G0), ^(win0 & G1) };
assign cw1 = { ^(win1 & G0), ^(win1 & G1) };

//prev state block
assign prev_s0 = win0[K-2:0];
assign prev_s1 = win1[K-2:0];
assign dec_bit = ns[K-2];

function [BM_W-1:0] pick_bm;
	input [1:0] cw;
	input [BM_W-1:0] b00, b01, b10, b11;
	begin
            case (cw)
                2'b00:   pick_bm = b00;
                2'b01:   pick_bm = b01;
                2'b10:   pick_bm = b10;
                default: pick_bm = b11;
            endcase
        end
    endfunction
//two mux block 
    assign bm_b0 = pick_bm(cw0, bm00, bm01, bm10, bm11);
    assign bm_b1 = pick_bm(cw1, bm00, bm01, bm10, bm11);

endmodule
