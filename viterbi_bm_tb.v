`timescale 1ns / 1ns
module viterbi_bm_tb;

parameter LLR_W = 5;
parameter BM_W  = LLR_W + 1;
reg clk = 0;
reg reset = 0;
always #5 clk = ~clk;

integer errors = 0;
integer i, j, s, b, t, x;

//BMU    
reg bm_en = 0;
reg  signed [LLR_W-1:0] llr0 = 0, llr1 = 0;
wire [BM_W-1:0] bm00, bm01, bm10, bm11;
wire bm_valid;

viterbi_bmu #(.LLR_W(LLR_W)) U_BMU (
 .clk(clk), .reset(reset), .bm_en(bm_en),
 .llr0(llr0), .llr1(llr1),
 .bm00(bm00), .bm01(bm01), .bm10(bm10), .bm11(bm11),
 .bm_valid(bm_valid)
);

// DUT 2 : BM_SEL (K=3) 
reg [1:0] ns3 = 0;
wire [1:0] p0_3, p1_3, cw0_3, cw1_3;
wire [BM_W-1:0] bb0_3, bb1_3;
wire db_3;

viterbi_bm_sel #(.K(3), .G0(3'b111), .G1(3'b101), .BM_W(BM_W)) U_SEL3 (
 .ns(ns3), .bm00(bm00), .bm01(bm01), .bm10(bm10), .bm11(bm11),
 .prev_s0(p0_3), .prev_s1(p1_3), .cw0(cw0_3), .cw1(cw1_3),
 .bm_b0(bb0_3), .bm_b1(bb1_3), .dec_bit(db_3)
);


// DUT 3 : BM_SEL (K=7)
reg [5:0] ns7 = 0;
wire [5:0] p0_7, p1_7;
wire [1:0] cw0_7, cw1_7;
wire [BM_W-1:0] bb0_7, bb1_7;
wire db_7;

viterbi_bm_sel #(.K(7), .G0(7'o171), .G1(7'o133), .BM_W(BM_W)) U_SEL7 (
 .ns(ns7), .bm00(bm00), .bm01(bm01), .bm10(bm10), .bm11(bm11),
 .prev_s0(p0_7), .prev_s1(p1_7), .cw0(cw0_7), .cw1(cw1_7),
 .bm_b0(bb0_7), .bm_b1(bb1_7), .dec_bit(db_7)
);


    function integer ref_cost;           
	input integer L;
        input integer e;                
        begin
            if (e == 0) ref_cost = (L < 0) ? -L : 0;
            else        ref_cost = (L > 0) ?  L : 0;
        end
    endfunction

    function integer ref_bm;
        input integer L0, L1;
        input integer cw;                 // {c0,c1}
        begin
            ref_bm = ref_cost(L0, (cw >> 1) & 1) + ref_cost(L1, cw & 1);
        end
    endfunction

    function integer parity;
        input integer v;
        integer k;
        begin
            parity = 0;
            for (k = 0; k < 32; k = k + 1) parity = parity ^ ((v >> k) & 1);
        end
    endfunction

    
   function integer enc_out;  
        input integer KK, GG0, GG1, st, ib;
        integer r;
        begin
            r = (ib << (KK-1)) | st;
            enc_out = (parity(r & GG0) << 1) | parity(r & GG1);
        end
    endfunction

    function integer enc_next;
        input integer KK, st, ib;
        begin
            enc_next = (ib << (KK-2)) | (st >> 1);
        end
    endfunction

    task check_bm;
        input integer L0, L1;
        begin
            if (bm00 !== ref_bm(L0,L1,0) || bm01 !== ref_bm(L0,L1,1) ||
                bm10 !== ref_bm(L0,L1,2) || bm11 !== ref_bm(L0,L1,3)) begin
                errors = errors + 1;
                if (errors < 10)
                    $display(" [ERR] L0=%0d L1=%0d : bm=%0d %0d %0d %0d, ref=%0d %0d %0d %0d",
                        L0, L1, bm00, bm01, bm10, bm11,
                        ref_bm(L0,L1,0), ref_bm(L0,L1,1), ref_bm(L0,L1,2), ref_bm(L0,L1,3));
            end
        end
    endtask

    // TEST2 K=3(? 4?)? K=7(? 64?)?? ?? ?·??·?? ??? ????
    integer found, e_before;
    task check_sel;
        input integer KK, GG0, GG1, nsv, pp0, pp1, ccw0, ccw1, bb0, bb1, dbit;
        begin
            found = 0;
            for (s = 0; s < (1 << (KK-1)); s = s + 1)
                for (b = 0; b < 2; b = b + 1)
                    if (enc_next(KK, s, b) == nsv) begin
                        found = found + 1;
                        if (s == pp0) begin
                            if (enc_out(KK,GG0,GG1,s,b) != ccw0 || b != dbit)
                                errors = errors + 1;
                        end else if (s == pp1) begin
                            if (enc_out(KK,GG0,GG1,s,b) != ccw1 || b != dbit)
                                errors = errors + 1;
                        end else
                            errors = errors + 1;    
                    end
            if (found != 2) errors = errors + 1;
            if (bb0 != ref_bm(llr0, llr1, ccw0) || bb1 != ref_bm(llr0, llr1, ccw1))
                errors = errors + 1;
        end
    endtask

    // TEST3 ?? ??? ??? ???? ?, ?? ?? ??? 0(??) ?? 12(???)? ????
    integer st_true, st_next, u, cw_true, nflip;
    integer L0v, L1v;

    initial begin
        $display("==== viterbi BM (distance) test start ====");
        #20 reset = 1;

        //------------------------- TEST1
        e_before = errors;
        for (i = -16; i < 16; i = i + 1)
            for (j = -16; j < 16; j = j + 1) begin
                @(negedge clk);
                llr0 = i; llr1 = j; bm_en = 1;
                @(negedge clk);
                bm_en = 0;
                if (bm_valid !== 1'b1) errors = errors + 1;
                check_bm(i, j);
            end
        @(negedge clk); llr0 = 7; llr1 = -7;
        @(negedge clk);
        if (bm_valid !== 1'b0) errors = errors + 1;
        check_bm(15, 15);                 
        $display("TEST1 BMU 1024 LLR pairs     : %s", (errors==e_before) ? "PASS" : "FAIL");

        //TEST2
        e_before = errors;
        @(negedge clk); llr0 = -9; llr1 = 4; bm_en = 1;
        @(negedge clk); bm_en = 0;
        for (t = 0; t < 4; t = t + 1) begin
            ns3 = t; #1;
            check_sel(3, 7, 5, ns3, p0_3, p1_3, cw0_3, cw1_3, bb0_3, bb1_3, db_3);
        end
        for (t = 0; t < 64; t = t + 1) begin
            ns7 = t; #1;
            check_sel(7, 'o171, 'o133, ns7, p0_7, p1_7, cw0_7, cw1_7, bb0_7, bb1_7, db_7);
        end
        $display("TEST2 trellis/BM select K=3,7 : %s", (errors==e_before) ? "PASS" : "FAIL");

        // K=3
        $display("  K=3 trellis (prev --in/c0c1--> next)");
        for (t = 0; t < 4; t = t + 1) begin
            ns3 = t; #1;
            $display("    %b --%b/%b--> %b      %b --%b/%b--> %b",
                     p0_3, db_3, cw0_3, ns3, p1_3, db_3, cw1_3, ns3);
        end

        //------------------------- TEST3
        e_before = errors;
        st_true = 0; nflip = 0;
        for (t = 0; t < 72; t = t + 1) begin
            u = $random & 1;
            cw_true = enc_out(3, 7, 5, st_true, u);
            st_next = enc_next(3, st_true, u);
            // BPSK LLR 
            L0v = ((cw_true >> 1) & 1) ? -12 : 12;
            L1v = ( cw_true & 1) ? -12 : 12;
            if (($random & 15) < 2) begin L0v = -L0v; nflip = nflip + 1; end

            @(negedge clk); llr0 = L0v; llr1 = L1v; bm_en = 1; ns3 = st_next;
            @(negedge clk); bm_en = 0; #1;
        
            if (p0_3 == st_true) x = bb0_3; else x = bb1_3;
            if (x != (((L0v>0) != (((cw_true>>1)&1)==0)) ? 12 : 0)) errors = errors + 1;
            st_true = st_next;
        end
        $display("TEST3 encoder->LLR->BM (72bit, %0d noisy) : %s", nflip,
                 (errors==e_before) ? "PASS" : "FAIL");

        $display("==== total errors = %0d  => %s ====", errors, (errors==0) ? "ALL PASS" : "FAIL");
        $finish;
    end

    // Vivado 
    initial begin
        $dumpfile("viterbi_bm_tb.vcd");
        $dumpvars(0, viterbi_bm_tb);
    end

endmodule