`timescale 1ns / 1ns

module viterbi_bmu #(parameter LLR_W = 5,parameter BM_W  = LLR_W + 1)
(input wire clk, input wire reset, input wire bm_en, input wire signed [LLR_W-1:0] llr0, input wire signed [LLR_W-1:0] llr1,
output reg [BM_W-1:0] bm00, output reg [BM_W-1:0] bm01, output reg [BM_W-1:0] bm10, output reg [BM_W-1:0] bm11,
output reg bm_valid
);
wire signed [BM_W-1:0] l0_ext = {{(BM_W-LLR_W){llr0[LLR_W-1]}}, llr0};
wire signed [BM_W-1:0] l1_ext = {{(BM_W-LLR_W){llr1[LLR_W-1]}}, llr1};
wire l0_neg = llr0[LLR_W-1];     
wire l1_neg = llr1[LLR_W-1];

wire [BM_W-1:0] l0_abs = l0_neg ? (-l0_ext) : l0_ext;
wire [BM_W-1:0] l1_abs = l1_neg ? (-l1_ext) : l1_ext;

// bit cost: cost Mux block
wire [BM_W-1:0] c0_e0 =  l0_neg ? l0_abs : {BM_W{1'b0}}; 
wire [BM_W-1:0] c0_e1 = !l0_neg ? l0_abs : {BM_W{1'b0}};  
wire [BM_W-1:0] c1_e0 =  l1_neg ? l1_abs : {BM_W{1'b0}};
wire [BM_W-1:0] c1_e1 = !l1_neg ? l1_abs : {BM_W{1'b0}};

// expected output distance
wire [BM_W-1:0] bm00_c = c0_e0 + c1_e0;
wire [BM_W-1:0] bm01_c = c0_e0 + c1_e1;
wire [BM_W-1:0] bm10_c = c0_e1 + c1_e0;
wire [BM_W-1:0] bm11_c = c0_e1 + c1_e1;

   
// register output 
always @(posedge clk or negedge reset) begin
	if (!reset) begin
            bm00 <= {BM_W{1'b0}};
            bm01 <= {BM_W{1'b0}};
            bm10 <= {BM_W{1'b0}};
            bm11 <= {BM_W{1'b0}};
            bm_valid <= 1'b0;
        end else begin
            bm_valid <= bm_en;
            if (bm_en) begin
                bm00 <= bm00_c;
                bm01 <= bm01_c;
                bm10 <= bm10_c;
                bm11 <= bm11_c;
            end
        end
    end

endmodule
