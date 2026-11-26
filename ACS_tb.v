`timescale 1ns / 1ns

module acs_tb;

    localparam PM_W = 8;
    localparam BM_W = 6;
    localparam SW   = 2;

    reg               clk;
    reg               rst;
    reg               acs_en;
    reg  [SW-1:0]     ns;
    reg  [SW-1:0]     prev_s0;
    reg  [SW-1:0]     prev_s1;
    reg  [BM_W-1:0]   bm_b0;
    reg  [BM_W-1:0]   bm_b1;

    wire [PM_W-1:0]   surv_pm;
    wire [SW-1:0]     surv_state;
    wire              surv_sel;
    wire              acs_valid;
    wire [SW-1:0]     best_state;
    wire [PM_W-1:0]   best_pm;

    integer           fd;

    acs #(PM_W, BM_W, SW) dut (
        clk,
        rst,
        acs_en,
        ns,
        prev_s0,
        prev_s1,
        bm_b0,
        bm_b1,
        surv_pm,
        surv_state,
        surv_sel,
        acs_valid,
        best_state,
        best_pm
    );

    always #5 clk = ~clk;

    // posedge clk?? ??? ??? ??? ??
    always @(posedge clk) begin
        #1;
        if (fd != 0) begin
            $fdisplay(fd, "Time=%0t ns | rst=%b | en=%b | ns=%0d | s0=%0d(bm=%0d) s1=%0d(bm=%0d) => surv_pm=%0d surv_st=%0d sel=%b valid=%b | best_st=%0d best_pm=%0d",
                      $time, rst, acs_en, ns, prev_s0, bm_b0, prev_s1, bm_b1,
                      surv_pm, surv_state, surv_sel, acs_valid, best_state, best_pm);
        end
    end

    initial begin
        clk     = 1'b0;
        rst     = 1'b0;
        acs_en  = 1'b0;
        ns      = 2'd0;
        prev_s0 = 2'd0;
        prev_s1 = 2'd0;
        bm_b0   = 6'd0;
        bm_b1   = 6'd0;

        fd = $fopen("acsresult.txt", "w");

        #20;
        @(negedge clk);
        rst = 1'b1;

        // 1. ?? ??(pm0=0, pm1..3=INF): state 0 -> ns=0 (b0=3), ns=2 (b0=5)
        @(negedge clk);
        acs_en  = 1'b1;
        ns      = 2'd0;
        prev_s0 = 2'd0;
        prev_s1 = 2'd1; // INF ??
        bm_b0   = 6'd3;
        bm_b1   = 6'd1;

        @(negedge clk);
        ns      = 2'd2;
        prev_s0 = 2'd0;
        prev_s1 = 2'd2; // INF ??
        bm_b0   = 6'd5;
        bm_b1   = 6'd0;

        // 2. ?? ??: pm0(3)? pm2(5)? ?????? ? ?? ??
        // ns=1: prev_s0=0 (3+4=7), prev_s1=2 (5+1=6) -> prev_s1(surv_sel=1) ??
        @(negedge clk);
        ns      = 2'd1;
        prev_s0 = 2'd0;
        prev_s1 = 2'd2;
        bm_b0   = 6'd4;
        bm_b1   = 6'd1;

        // ns=3: prev_s0=0 (3+2=5), prev_s1=2 (5+0=5) -> ??? ? prev_s0(surv_sel=0) ??
        @(negedge clk);
        ns      = 2'd3;
        prev_s0 = 2'd0;
        prev_s1 = 2'd2;
        bm_b0   = 6'd2;
        bm_b1   = 6'd0;

        // 3. acs_en ???? ? acs_valid=0 ??
        @(negedge clk);
        acs_en = 1'b0;

        #20;
        $fclose(fd);
        fd = 0;
        $stop;
    end

endmodule