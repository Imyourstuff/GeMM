module gemm_driver #(
    parameter N = 4,
    parameter WIDTH = 8,
    parameter ACC_WIDTH = 2*WIDTH + $clog2(N)
)(
    input logic                clk,
    input logic                reset,
    input logic [WIDTH-1:0] A [0:N-1][0:N-1],
    input logic [WIDTH-1:0] B [0:N-1][0:N-1],
    output logic [ACC_WIDTH-1:0] c_out,
    output logic [9:0]          tick
);

    logic alpha;
    logic beta;
    logic [16:0] cnt;
    
    // Counter
    always_ff @(posedge clk or posedge reset) begin
        if (reset) cnt <= 0;
        else cnt <= cnt + 1;
    end

    assign tick = cnt;

    logic [WIDTH-1:0] a_in;
    logic [WIDTH-1:0] b_in_1;
    logic [WIDTH-1:0] b_in_3;    
    
    gemmArray #(
        .WIDTH(WIDTH),
        .N(N),
        .ACC_WIDTH(ACC_WIDTH),
        .MODE(0)
    ) array (
        .clk(clk),
        .reset(reset),
        .a_in(a_in),
        .b_in_1(b_in_1),
        .b_in_3(b_in_3),
        .c_in('0), //Зануляем на вход в массив
        .alpha(alpha),
        .beta(beta),
        .c_out(c_out)
    );

    //Поток А левого умножителя
    always_ff @(posedge clk or posedge reset) begin
        if (reset) a_in <= '0;
        else if (cnt > 0 && cnt <= N*N)
            a_in <= A[(cnt-1) / N][(N - (cnt % N)) % N];
        else
            a_in <= '0;
    end

    //Поток для Б первого левого умножителя
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            b_in_1 <= '0; 
        else if (cnt < 2*N)
            b_in_1 <= B[((N + 1) / 2) - (cnt / N)][cnt % N];
        else 
            b_in_1 <= '0;
    end

    // Поток управляющих данных:
    always_ff @(posedge clk or posedge reset) begin 
        if (reset) begin
            alpha <=0;
            beta <=0; 
        end
        else if ((cnt / N == 1) && (cnt % N == 0)) begin
            alpha <= 1;
            beta <= 1;
        end
        else if (cnt < N*N/2) begin
            alpha <= 1;
            beta <= 0;
        end
        else if (cnt % N == 0) begin
            alpha <= 0;
            beta <= 1;
        end
        else begin
            alpha <= 0;
            beta <= 0;
        end
    end

    // Поток для крайнего правого умножителя
    always_ff @(posedge clk or posedge reset) begin 
        if (reset) b_in_3 <= '0;
        else if (cnt >= N - 1) 
            b_in_3 <= B[(N / 2) + (cnt - N + 1)/N][ (cnt - N + 1) %N];
        else b_in_3 <= '0;
    end
endmodule