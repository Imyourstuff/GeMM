`timescale 1ns/1ps

module tb_gemmDriver;
    localparam WIDTH = 8;
    localparam N = 4;
    localparam ACC_WIDTH = 2*WIDTH + $clog2(N);

    logic clk;
    logic reset;

    logic [ACC_WIDTH-1:0] c_out;
    logic [9:0] tick;

    int local_tick = 0;

    logic [WIDTH-1:0] A_test [0:N-1][0:N-1];
    logic [WIDTH-1:0] B_test [0:N-1][0:N-1];

    gemm_driver #(
        .WIDTH(WIDTH),
        .N(N),
        .ACC_WIDTH(ACC_WIDTH)
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
        $display("========================================");
        $display("Тест драйвера GEMM (N=%0d)", N);
        $display("========================================");
        
        // Матрица A (тестовые значения)
        A_test[0][0] = 1; A_test[0][1] = 2; A_test[0][2] = 0; A_test[0][3] = 0;
        A_test[1][0] = 2; A_test[1][1] = 1; A_test[1][2] = 0; A_test[1][3] = 0;
        A_test[2][0] = 0; A_test[2][1] = 0; A_test[2][2] = 1; A_test[2][3] = 2;
        A_test[3][0] = 0; A_test[3][1] = 0; A_test[3][2] = 2; A_test[3][3] = 1;

        // Матрица B (тестовые значения)
        B_test[0][0] = 1; B_test[0][1] = 2; B_test[0][2] = 3; B_test[0][3] = 4;
        B_test[1][0] = 1; B_test[1][1] = 2; B_test[1][2] = 3; B_test[1][3] = 4;
        B_test[2][0] = 1; B_test[2][1] = 2; B_test[2][2] = 3; B_test[2][3] = 4;
        B_test[3][0] = 1; B_test[3][1] = 2; B_test[3][2] = 3; B_test[3][3] = 4;

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
        
        // Ждём завершения (T_LAST = 22 для N=4)
        wait (tick >= 24);
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
            // valid: такты 7..22 для N=4
            if (tick >= 9 && tick <= 24) begin
                $display("[VALID] tick=%0d: c_out=%0d", tick, c_out);
                offset = tick - 9;
                row = offset / N;
                col = offset % N;
                C_result[row][col] = c_out;
            end
            // done: такт >= 22
            if (tick >= 24) begin
                $display("[DONE] tick=%0d", tick, c_out);
                for (int i = 0; i < N; i++)
                    $display("  A[%0d] = %0d %0d %0d %0d", i, 
                        C_result[i][0], C_result[i][1], C_result[i][2], C_result[i][3]);
            end
        end
        
    end

    // Дамп волн для GTKWave
    initial begin
        $dumpfile("tb_gemmDriver.vcd");
        $dumpvars(0, tb_gemmDriver);
    end

endmodule