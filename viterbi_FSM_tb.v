`timescale 1ns / 1ns

module viterbi_fsm_tb;

    localparam K          = 3;
    localparam FRAME_BITS = 6;
    localparam PAIR_W     = $clog2(FRAME_BITS + 1);

    reg               clk;
    reg               reset;
    reg               start;
    reg               bm_valid;

    wire              path_init;
    wire              path_acs_en;
    wire              commit_en;
    wire              fin_en;
    wire              bm_en;
    wire              acs_en;
    wire [K-2:0]      state_idx;
    wire [PAIR_W-1:0] pair;
    wire              done;

    integer           fd;

    viterbi_fsm #(K, FRAME_BITS, PAIR_W) dut (
        clk,
        reset,
        start,
        bm_valid,
        path_init,
        path_acs_en,
        commit_en,
        fin_en,
        bm_en,
        acs_en,
        state_idx,
        pair,
        done
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        #1;
        if (fd != 0) begin
            $fdisplay(fd, "Time=%0t ns | rst=%b start=%b bm_vld=%b | pair=%0d st_idx=%0d | init=%b bm_en=%b acs_en=%b p_en=%b cmt=%b done=%b fin=%b",
                      $time, reset, start, bm_valid, pair, state_idx,
                      path_init, bm_en, acs_en, path_acs_en, commit_en, done, fin_en);
        end
    end

    initial begin
        clk      = 1'b0;
        reset    = 1'b0;
        start    = 1'b0;
        bm_valid = 1'b0;

        fd = $fopen("fsmresult.txt", "w");

        #20;
        @(negedge clk);
        reset = 1'b1;

        @(negedge clk);
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        while (!done) begin
            @(posedge clk);
            #1;
            if (dut.state == 4'd3) begin
                @(negedge clk);
                bm_valid = 1'b1;
                @(negedge clk);
                bm_valid = 1'b0;
            end
        end

        #20;
        $fclose(fd);
        fd = 0;
        $stop;
    end

endmodule
