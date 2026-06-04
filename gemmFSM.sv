module gemmFSM #(
    parameter N = 4,
    parameter WIDTH = 32,
    parameter ACC_WIDTH = 2*WIDTH + $clog2(N)
)(
    input  logic                clk,
    input  logic                reset,

    input  logic                opcode,     // 0 = WRITE, 1 = Начать вычисления
    input  logic [15:0]         cmd_addr,
    input  logic [WIDTH-1:0]    a_data,
    input  logic [WIDTH-1:0]    b_data,

    output logic                done,
    output logic                c_valid,

    output logic [ACC_WIDTH-1:0] c_out
);

    logic [WIDTH-1:0] mem_A [0:N-1][0:N-1];
    logic [WIDTH-1:0] mem_B [0:N-1][0:N-1];

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_WRITE,
        ST_COMPUTE
    } state_t;

    localparam OP_WRITE = 1'b0;
    localparam OP_COMPUTE = 1'b1;
    state_t state;
    state_t next_state;

    logic [15:0] cnt;

    localparam T_FIRST = 2*N + 1;
    localparam T_LAST  = N*N + 2*(N-1) + 2;

    //Вроде проверил
    always_ff @(posedge clk) begin
        next_state <= state;
        case(state)
            ST_IDLE: begin
                if (opcode == OP_WRITE)
                    next_state <= ST_WRITE;
            end
            ST_WRITE: begin
                if (opcode == OP_WRITE)
                    next_state <= ST_WRITE;
                else if (opcode == OP_COMPUTE) begin
                    next_state <= ST_COMPUTE;
                end
            end
            ST_COMPUTE: begin
                if (cnt >= T_LAST)
                    next_state <= ST_IDLE;
            end
        endcase
    end

    //Переключение счётчика тактов исходя из STATE
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= ST_IDLE;
            cnt <= 0;
        end
        else begin
            state <= next_state;
            //Если сейчас считаем то счётчик увеличивается
            if (state == ST_COMPUTE)
                if (cnt < T_LAST)
                    cnt <= cnt + 1;
            //Если не считаем, то сбрасываем такты
        end
    end

    //Параллельно записываем a и b в два потока
    always_ff @(posedge clk) begin
        if (state == ST_WRITE && cmd_addr < N * N)
            mem_A[cmd_addr / N][cmd_addr % N] <= a_data;
    end
    
    always_ff @(posedge clk) begin
        if (state == ST_WRITE && cmd_addr < N * N)
            mem_B[cmd_addr / N][cmd_addr % N] <= b_data;
    end

    //Драйвер для флага завершения вычислений
    always_ff @(posedge clk) begin
        if (reset)
            done <= 1'b0;
        else if (cnt >= T_LAST)
            done <= 1'b1;
    end

    assign c_valid = (state == ST_COMPUTE) && (cnt >= T_FIRST) && (cnt <= T_LAST);

    logic [WIDTH-1:0] a_in;
    logic [WIDTH-1:0] b_in_1;
    logic [WIDTH-1:0] b_in_3;

    logic alpha;
    logic beta;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            a_in <= '0;
        else if (state == ST_COMPUTE && cnt <= N*N)
            a_in <= mem_A[(cnt - 1) / N][N - 1 - (cnt - 1) % N];
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            b_in_1 <= '0;
        else if (state == ST_COMPUTE && cnt < N*N/2)
            b_in_1 <= mem_B[((N+1)/2) - (cnt/N)][cnt%N];
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            b_in_3 <= '0;
        else if (state == ST_COMPUTE && cnt >= N-1 && cnt <= N*N/2 + N - 1)
            b_in_3 <= mem_B[(N/2) + (cnt-N+1)/N][(cnt-N+1)%N];
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            alpha <= 0;
            beta <= 0;
        end
        else if (state == ST_COMPUTE) begin
            if ((cnt/N == 1) && (cnt%N == 0)) begin
                alpha <= 1;
                beta  <= 1;
            end
            else if (cnt < N*N/2) begin
                alpha <= 1;
                beta  <= 0;
            end
            else if (cnt%N == 0) begin
                alpha <= 0;
                beta  <= 1;
            end else begin
                alpha <= 0;
                beta <= 0;
            end
        end
    end

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
        .c_in('0),

        .alpha(alpha),
        .beta(beta),
        .c_out(c_out)
    );

endmodule