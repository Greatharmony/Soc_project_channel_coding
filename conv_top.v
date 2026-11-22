module conv_top(input clk, reset, sel, bm_btn, input[2:0] din, output [6:0] seg, output [7:0] digit);

wire pls_sel, pls_bm;
wire dout0, dout1;
wire [5:0] out;
wire bm_en;

localparam N=3, LLR_W = 5, BM_W =  6, K = 3;
localparam [2:0] G0 = 3'b111;
localparam [2:0] G1 = 3'b101;

wire signed [LLR_W-1:0] llr0;
wire signed [LLR_W-1:0] llr1;
wire bm_valid;
wire [BM_W-1:0] bm00, bm01, bm10, bm11;

wire [K-2:0] ns; // 앞단/테스트벤치에서 연결할 다음 상태 신호
wire [K-2:0] prev_s0, prev_s1;
wire [1:0] cw0, cw1;
wire [BM_W-1:0] bm_b0, bm_b1;
wire dec_bit;

assign bm_en = pls_bm;

button BT0(clk, reset, sel, pls_sel);
button BT1(clk, reset, bm_btn, pls_bm);

conv_encoder #(N) U1 (clk, reset, din, pls_sel, dout0, dout1, out);
viterbi_bmu #(LLR_W, BM_W) BM1 (clk, reset, bm_en,llr0, llr1, bm00, bm01, bm10,bm11, bm_valid);
viterbi_bm_sel # (K, G0, G1, BM_W) BMS1 (ns, bm00,bm01, bm10, bm11, prev_s0, prev_s1,cw0, cw1,     
bm_b0, bm_b1, dec_bit);

conv_Display DP0 (clk, reset, pls_bm, out, seg, digit);

assign llr0 = dout1 ? -5'sd8 : 5'sd8;
assign llr1 = dout0 ? -5'sd8 : 5'sd8;
endmodule