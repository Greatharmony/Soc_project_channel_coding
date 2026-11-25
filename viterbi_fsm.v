//아직 수정중
module viterbi_fsm #(
    parameter K = 3,
    parameter FRAME_BITS = 6,
    parameter PAIR_W = $clog2(FRAME_BITS + 1)
)
(
    input wire clk,
    input wire reset,
    input wire start,
    input wire bm_valid,

    // Path control
    output reg path_init,
    output reg path_acs_en,
    output reg commit_en,
    output reg fin_en,

    // BMU control
    output reg bm_en,

    // ACS control
    output reg acs_en,
    output reg [K-2:0] state_idx,

    // Path index
    output reg [PAIR_W-1:0] pair,

    // Decoder status
    output reg done
);

localparam NS = 1 << (K-1);

// FSM states
localparam IDLE        = 4'd0;
localparam INIT        = 4'd1;
localparam BM_START    = 4'd2;
localparam BM_WAIT     = 4'd3;
localparam ACS_CALC    = 4'd4;
localparam PATH_UPDATE = 4'd5;
localparam STATE_NEXT  = 4'd6;
localparam COMMIT      = 4'd7;
localparam PAIR_NEXT   = 4'd8;
localparam DONE        = 4'd9;

reg [3:0] state, next_state;

// 1. State Register


always @(posedge clk or negedge reset) begin

    if (!reset)
        state <= IDLE;

    else
        state <= next_state;

end

// 2. Next State Logic


always @(*) begin

    next_state = state;

    case (state)

        IDLE: begin
            if (start)
                next_state = INIT;
        end

        INIT:
            next_state = BM_START;

        BM_START:
            next_state = BM_WAIT;

        BM_WAIT: begin
            if (bm_valid)
                next_state = ACS_CALC;
        end

        ACS_CALC:
            next_state = PATH_UPDATE;

        PATH_UPDATE:
            next_state = STATE_NEXT;

        STATE_NEXT: begin
            if (state_idx == NS-1)
                next_state = COMMIT;
            else
                next_state = ACS_CALC;
        end

        COMMIT:
            next_state = PAIR_NEXT;

        PAIR_NEXT: begin
            if (pair == FRAME_BITS-1)
                next_state = DONE;
            else
                next_state = BM_START;
        end

        DONE: begin
            if (!start)
                next_state = IDLE;
        end

        default:
            next_state = IDLE;

    endcase

end


// 3. Output Logic
always @(*) begin

    path_init   = 1'b0;
    path_acs_en = 1'b0;
    commit_en   = 1'b0;
    fin_en      = 1'b0;

    bm_en       = 1'b0;
    acs_en      = 1'b0;
    done        = 1'b0;

    case (state)

        INIT: begin
            path_init = 1'b1;
        end

        BM_START: begin
            bm_en = 1'b1;
        end

        ACS_CALC: begin
            acs_en = 1'b1;
        end

        PATH_UPDATE: begin
            path_acs_en = 1'b1;
        end

        COMMIT: begin
            commit_en = 1'b1;
        end

        DONE: begin
            done = 1'b1;
            fin_en = 1'b1;
        end

    endcase

end

// 4. Counter Control

always @(posedge clk or negedge reset) begin

    if (!reset) begin
        state_idx <= 0;
        pair <= 0;
    end

    else begin

        if (state == INIT) begin
            state_idx <= 0;
            pair <= 0;
        end

        else if (state == STATE_NEXT) begin

            if (state_idx < NS-1)
                state_idx <= state_idx + 1'b1;

        end

        else if (state == PAIR_NEXT) begin

            if (pair < FRAME_BITS-1) begin
                pair <= pair + 1'b1;
                state_idx <= 0;
            end

        end

    end

end

endmodule
