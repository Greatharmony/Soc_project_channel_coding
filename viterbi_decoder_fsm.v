`timescale 1ns / 1ns
module viterbi_decoder #(
    parameter FRAME_BITS = 72,            //payload+CRC
    parameter K          = 3,              
    parameter G0         = 3'b111,        
    parameter G1         = 3'b101,         
    parameter LLR_W      = 5,
    parameter BM_W       = LLR_W + 1,
    parameter PM_W       = 12,
    parameter PAIR_W     = 7              
    input  wire clk,
    input  wire reset,          
    input  wire start,          
    input  wire in_valid,     
    input  wire signed [LLR_W-1:0] llr0,           
    input  wire signed [LLR_W-1:0] llr1,     
    output wire in_ready,   
    output wire busy,          
    output wire done,           
    output reg  frame_valid,    
    output reg  [FRAME_BITS-1:0] decoded_frame,  // restored payload + CRC
    output reg  [K-2:0] final_state,   
    output reg  [PM_W-1:0] final_metric 
);

parameter NS = 1 << (K-1);       

//state num
parameter[3:0] S_IDLE   = 4'd0, S_INIT   = 4'd1, S_WAIT   = 4'd2,   // WAIT_PAIR
S_BM     = 4'd3,
S_ACS    = 4'd4,
S_SEL    = 4'd5,   // SELECT_BEST
S_COMMIT = 4'd6,
S_FINAL  = 4'd7,   // FINALIZE
S_DONE   = 4'd8;

reg [3:0] state, next_state;
reg [PAIR_W-1:0] pair;          // commit llr pair num (present)
reg [K-2:0] state_idx;     // state num that acs is holding
reg [K-2:0] srh_idx;       // SELECT_BEST state num
reg  signed [LLR_W-1:0] llr0_q, llr1_q;// llr pair they got

wire accept = in_valid && in_ready; 
wire last_idx  = (state_idx == NS-1);
wire last_srh  = (srh_idx == NS-1);
wire last_pair = (pair == FRAME_BITS-1);


// FSM state register
always @(posedge clk or negedge reset) begin
	if (!reset) state <= S_IDLE;
        else state <= next_state;
    end

// FSM nest state decision
always @(*) begin
        next_state = state;                                   
        case (state)
            S_IDLE  : if (start)    next_state = S_INIT;
            S_INIT  :               next_state = S_WAIT;
            S_WAIT  : if (accept)   next_state = S_BM;
            S_BM    :               next_state = S_ACS;
            S_ACS   : if (last_idx) next_state = S_SEL;      
            S_SEL   : if (last_srh) next_state = S_COMMIT;   
            S_COMMIT:               next_state = last_pair ? S_FINAL : S_WAIT;
            S_FINAL :               next_state = S_DONE;
            S_DONE  :               next_state = start ? S_INIT : S_IDLE; 
            default :               next_state = S_IDLE;
        endcase
    end


//FSM control signal
    assign in_ready  = (state == S_WAIT);
    assign busy = (state != S_IDLE) && (state != S_DONE);  
    assign done = (state == S_DONE);

    wire   pm_init  = (state == S_INIT);    // ? ??: PM/path initialize
    wire   bm_en = (state == S_BM);      // ? viterbi_bmu
    wire   acs_en = (state == S_ACS);     // ? ??: state_idx ?? 1? ACS
    wire   sel_en = (state == S_SEL);     // ? ??: srh_idx ?? 1? ??
    wire   sel_first = (srh_idx == 0);       // ? ??: ?? ?? (? ??)
    wire   commit_en = (state == S_COMMIT);  // ? ??: new PM/?? ? ??? ??
    wire   fin_en = (state == S_FINAL);   // ? ??: ?? ?? ??


// counter/LLR latch
always @(posedge clk or negedge reset) begin
        if (!reset) begin
            pair      <= {PAIR_W{1'b0}};
            state_idx <= {(K-1){1'b0}};
            srh_idx   <= {(K-1){1'b0}};
            llr0_q    <= {LLR_W{1'b0}};
            llr1_q    <= {LLR_W{1'b0}};
        end else begin
            if (pm_init) begin
                pair      <= {PAIR_W{1'b0}};
                state_idx <= {(K-1){1'b0}};
                srh_idx   <= {(K-1){1'b0}};
            end
            if (commit_en) pair      <= pair + 1'b1;
            if (acs_en)    state_idx <= state_idx + 1'b1;
            if (sel_en)    srh_idx   <= srh_idx + 1'b1;
            if (accept) begin               
                llr0_q <= llr0;
                llr1_q <= llr1;
            end
        end
    end


// path compute
wire [BM_W-1:0] bm00, bm01, bm10, bm11;
wire bm_valid;                  // for debug

    viterbi_bmu #(.LLR_W(LLR_W), .BM_W(BM_W)) u_bmu (
        .clk      (clk),
        .reset    (reset),
        .bm_en    (bm_en),
        .llr0     (llr0_q),
        .llr1     (llr1_q),
        .bm00     (bm00),
        .bm01     (bm01),
        .bm10     (bm10),
        .bm11     (bm11),
        .bm_valid (bm_valid)
    );

wire [K-2:0] prev_s0, prev_s1;
wire [1:0] cw0, cw1;
wire [BM_W-1:0] bm_b0, bm_b1;
wire dec_bit;

    viterbi_bm_sel #(.K(K), .G0(G0), .G1(G1), .BM_W(BM_W)) u_bm_sel (
        .ns       (state_idx),
        .bm00     (bm00),
        .bm01     (bm01),
        .bm10     (bm10),
        .bm11     (bm11),
        .prev_s0  (prev_s0),
        .prev_s1  (prev_s1),
        .cw0      (cw0),
        .cw1      (cw1),
        .bm_b0    (bm_b0),
        .bm_b1    (bm_b1),
        .dec_bit  (dec_bit)
    );

    // ?? ??? ???? ?
    wire                  decision;     // ? ? ? : 1 ?? prev_s1 ?? ? (???? 0)
    wire [K-2:0]          best_state;   // ? ? ?, ?? : ???? ?? ??
    wire [PM_W-1:0]       best_metric;  // ? ? ??    : ? ??? ????
    wire [FRAME_BITS-1:0] path_bits;    // ? ? ??    : best_state ? ?? ??

    //******************************************************************
    // [?? ?? ?] ???? : viterbi_acs
    //   ?? ?? : ?? /* */ ? ?? ????? ???,
    //               ? ?? "???" assign 3?? ??
    //   ??
    //     - pm_init  : PM[0]=0, ??? INF(4095)
    //     - acs_en   : ?? ?? ??? decision ??,
    //                  new_PM[state_idx] = min(PM[prev_s0]+bm_b0, PM[prev_s1]+bm_b1)
    //                  (??? ??, PM ? old/new ? ?)
    //     - sel_en   : sel_first ? new_PM[srh_idx] ? ????? ??,
    //                  ??? ? ?? ?? best_state/best_metric ??
    //     - commit_en: new_PM ? PM
    //******************************************************************
    /*
    viterbi_acs #(.K(K), .BM_W(BM_W), .PM_W(PM_W)) u_acs (
        .clk         (clk),
        .reset       (reset),
        .pm_init     (pm_init),
        .acs_en      (acs_en),
        .state_idx   (state_idx),
        .prev_s0     (prev_s0),
        .prev_s1     (prev_s1),
        .bm_b0       (bm_b0),
        .bm_b1       (bm_b1),
        .decision    (decision),
        .sel_en      (sel_en),
        .sel_first   (sel_first),
        .srh_idx     (srh_idx),
        .best_state  (best_state),
        .best_metric (best_metric),
        .commit_en   (commit_en)
    );
    */
    assign decision    = 1'b0;                 // ??? (?? ?? ? ??? ??)
    assign best_state  = {(K-1){1'b0}};        // ??? (?? ?? ? ??? ??)
    assign best_metric = {PM_W{1'b0}};         // ??? (?? ?? ? ??? ??)

    //******************************************************************
    // [?? ?? ?] ?? ?? : viterbi_path
    //   ?? ?? : ?? /* */ ? ?? ????? ???,
    //               ? ?? "???" assign 1?? ??
    //   ??
    //     - path_init(pm_init) : ?? ?? ???
    //     - acs_en  : new_path[state_idx] = path[decision ? prev_s1 : prev_s0]
    //                 ? dec_bit ? pair ?? ??? ??
    //     - commit_en : new_path ? path
    //     - fin_en ?? ?? path_bits ? best_state ? 72??? ?? ??? ?
    //       (path_bits[0] = ?? ??? ??)
    //******************************************************************
    /*
    viterbi_path #(.K(K), .FRAME_BITS(FRAME_BITS), .PAIR_W(PAIR_W)) u_path (
        .clk         (clk),
        .reset       (reset),
        .path_init   (pm_init),
        .acs_en      (acs_en),
        .state_idx   (state_idx),
        .prev_s0     (prev_s0),
        .prev_s1     (prev_s1),
        .decision    (decision),
        .dec_bit     (dec_bit),
        .pair        (pair),
        .commit_en   (commit_en),
        .best_state  (best_state),
        .fin_en      (fin_en),
        .path_bits   (path_bits)
    );
    */
    assign path_bits = {FRAME_BITS{1'b0}};     // ??? (?? ?? ? ??? ??)


//final output register
always @(posedge clk or negedge reset) begin
        if (!reset) begin
            frame_valid   <= 1'b0;
            decoded_frame <= {FRAME_BITS{1'b0}};
            final_state   <= {(K-1){1'b0}};
            final_metric  <= {PM_W{1'b0}};
        end else begin
            if (!busy && start)
                frame_valid <= 1'b0;          
            if (fin_en) begin
                frame_valid   <= 1'b1;
                decoded_frame <= path_bits;
                final_state   <= best_state;
                final_metric  <= best_metric;
            end
        end
    end

endmodule