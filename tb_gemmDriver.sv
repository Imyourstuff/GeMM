`timescale 1ns/1ps

module tb_gemmDriver;
    localparam WIDTH = 8;
    localparam N = 4;
    localparam ACC_WIDTH = 2*WIDTH + $clog2(N);
    localparam T_FIRST = 2*N + 1;
    localparam T_LAST  = N*N + 2*N;
    localparam MODE = 1;

    logic clk;
    logic reset;

    logic [ACC_WIDTH-1:0] c_out;
    logic [N*2-1:0] tick;

    int local_tick = 0;

    logic [WIDTH-1:0] A_test [0:N-1][0:N-1];
    logic [WIDTH-1:0] B_test [0:N-1][0:N-1];

    gemmDriver #(
        .WIDTH(WIDTH),
        .N(N),
        .ACC_WIDTH(ACC_WIDTH),
        .MODE(MODE)
    ) driver (
        .clk    (clk),
        .reset  (reset),
        .A      (A_test),
        .B      (B_test),
        .c_out  (c_out),
        .tick   (tick)
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Счётчик тактов для отладки
    always @(posedge clk) begin
        if (!reset) local_tick <= local_tick + 1;
    end

    initial begin
        
        A_test[0][0] = 10; A_test[0][1] = 2; A_test[0][2] = 3; A_test[0][3] = 4;
        A_test[1][0] = 8; A_test[1][1] = 2; A_test[1][2] = 3; A_test[1][3] = 4;
        A_test[2][0] = 0; A_test[2][1] = 0; A_test[2][2] = 22; A_test[2][3] = 2;
        A_test[3][0] = 0; A_test[3][1] = 0; A_test[3][2] = 2; A_test[3][3] = 44;

        B_test[0][0] = 44; B_test[0][1] = 2; B_test[0][2] = 3; B_test[0][3] = 4;
        B_test[1][0] = 44; B_test[1][1] = 2; B_test[1][2] = 3; B_test[1][3] = 4;
        B_test[2][0] = 44; B_test[2][1] = 2; B_test[2][2] = 3; B_test[2][3] = 4;
        B_test[3][0] = 44; B_test[3][1] = 2; B_test[3][2] = 3; B_test[3][3] = 4;

        // Вывод матриц в консоль для проверки
        $display("Матрица A:");
        for (int i = 0; i < N; i++)
            $display("  A[%0d] = %0d %0d %0d %0d", i, 
                     A_test[i][0], A_test[i][1], A_test[i][2], A_test[i][3]);
        
        $display("Матрица B:");
        for (int i = 0; i < N; i++)
            $display("  B[%0d] = %0d %0d %0d %0d", i,
                     B_test[i][0], B_test[i][1], B_test[i][2], B_test[i][3]);

        // Сброс
        #20;
        reset = 1;
        #20;
        reset = 0;
        local_tick = 0;
        #10;
        
        $display("Запуск вычислений...");
        
        wait (tick >= T_LAST);
        #50;
        
        $display("Тест завершён на такте %0d", local_tick);
        $finish;
    end

    logic signed [ACC_WIDTH-1:0] C_result [0:N-1][0:N-1];

    integer offset;
    integer row;
    integer col;
    always @(posedge clk) begin
        if (!reset) begin

            if (tick >= T_FIRST && tick <= T_LAST) begin
                offset = tick - 9;
                row = offset / N;
                col = offset % N;
                C_result[row][col] = $signed(c_out);
            end

            if (tick >= T_LAST) begin
                $display("[DONE] tick=%0d", tick, c_out);
                for (int i = 0; i < N; i++)
                    $display("  A[%0d] = %0d %0d %0d %0d", i, 
                        C_result[i][0], C_result[i][1], C_result[i][2], C_result[i][3]);
            end
        end
        
    end

    initial begin
        $dumpfile("tb_gemmDriver.vcd");
        $dumpvars(0, tb_gemmDriver);
    end

endmodule