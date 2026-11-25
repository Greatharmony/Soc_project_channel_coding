module acs #(parameter PM_W = 8, BM_W = 6, SW = 2) 
// K=3 기준 상태 비트폭 (2^(K-1) = 4상태 -> 2비트)
(
    	input clk, rst, acs_en,
    	input [SW-1:0] ns,
    	input [SW-1:0] prev_s0, //두개의 이전 상태
    	input [SW-1:0] prev_s1,
    	input [BM_W-1:0] bm_b0, //두 경로의 branch metric
    	input [BM_W-1:0] bm_b1,
    	output reg [PM_W-1:0] surv_pm,  // 선택된 생존 경로 메트릭
    	output reg [SW-1:0] surv_state,  // 선택된 이전 상태
    	// 0: 경로0 선택, 1: 경로1 선택 / valid
        output reg surv_sel, acs_valid
	output reg [SW-1:0] best_state //최소 path metric을 가진 상태
	output reg [PM_W-1:0] best_pm
);

localparam [PM_W-1:0] INF = {PM_W{1'b1}}; //초기 path는 무한대로 설정
reg [PM_W-1:0] pm0, pm1, pm2, pm3;

reg [PM_W-1:0] prev_pm0_sel; //이전 상태의 path metric 선택
reg [PM_W-1:0] prev_pm1_sel;
reg [PM_W-1:0] cand0_pm;
reg [PM_W-1:0] cand1_pm;
reg [PM_W-1:0] win_pm;
reg [SW-1:0]   win_state;
reg            win_sel;

//이전 상태의 path metric 선택
 always @(*) begin
 	case (prev_s0)
            	2'd0: prev_pm0_sel = pm0;
            	2'd1: prev_pm0_sel = pm1;
            	2'd2: prev_pm0_sel = pm2;
            	default: prev_pm0_sel = pm3;
        endcase

        case (prev_s1)
            	2'd0: prev_pm1_sel = pm0;
            	2'd1: prev_pm1_sel = pm1;
            	2'd2: prev_pm1_sel = pm2;
            	default: prev_pm1_sel = pm3;
        endcase

 end

// 2. Candidate Path Metric 계산
always @(*) begin
        // 이전 경로가 INF이면 INF 유지
        if (prev_pm0_sel == INF)
            	cand0_pm = INF;
        else
            	cand0_pm = prev_pm0_sel + {{(PM_W-BM_W){1'b0}}, bm_b0};

        if (prev_pm1_sel == INF)
            	cand1_pm = INF;
        else
            	cand1_pm = prev_pm1_sel + {{(PM_W-BM_W){1'b0}}, bm_b1};
end

// 3. 두 경로 중 생존 경로 선택
always @(*) begin

        if (cand0_pm <= cand1_pm) begin //더 작은 경로 선택
            	win_pm    = cand0_pm;
            	win_state = prev_s0;
            	win_sel   = 1'b0;
        end
        else begin
            	win_pm    = cand1_pm;
            	win_state = prev_s1;
            	win_sel   = 1'b1;
        end
end
// 4. 전체 상태 중 최소 Path Metric 검색
always @(*) begin
        best_pm = pm0; //초기 best를 pm0로 놓고 비교하기
        best_state = 0;

        if (pm1 < best_pm) begin
            	best_pm = pm1;
            	best_state = 1;
        end
        if (pm2 < best_pm) begin
            	best_pm    = pm2;
            	best_state = 2;
        end
        if (pm3 < best_pm) begin
            	best_pm    = pm3;
            	best_state = 3;
        end
end

// 5. Sequential Logic
 
always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // 초기 상태는 0번 상태만 유효
            	pm0 <= 0;
            	pm1 <= INF;
            	pm2 <= INF;
            	pm3 <= INF;

            	surv_pm    <= 0;
            	surv_state <= 0;
            	surv_sel   <= 0;
            	acs_valid  <= 0;
        end
        else if (acs_en) begin

            // 생존 경로 결과 저장
            	surv_pm    <= win_pm;
            	surv_state <= win_state;
            	surv_sel   <= win_sel;
	
            	acs_valid <= 1'b1;

            // 현재 도착 상태의 Path Metric 갱신
            case (ns)
                	2'd0: pm0 <= win_pm;
                	2'd1: pm1 <= win_pm;
                	2'd2: pm2 <= win_pm;
                	default: pm3 <= win_pm;
            endcase
        end
        else begin
            acs_valid <= 1'b0;
        end
    end
endmodule
