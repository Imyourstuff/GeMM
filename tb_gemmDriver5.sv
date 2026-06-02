`timescale 1ns/1ps

module tb_gemmDriver;
    localparam WIDTH = 8;
    localparam N = 5;
    localparam ACC_WIDTH = 2*WIDTH + $clog2(N); // Для N=5: 16 + 3 = 19 бит
    
    // Универсальные формулы таймингов (работают для любого N)
    localparam int T_FIRST = 11;     // Для N=5: 5 * 2 - 1 = 9
    localparam int T_LAST  = 37;   // Для N=5: 75 / 2 = 37 (с запасом)

    logic clk;
    logic reset;

    logic [ACC_WIDTH-1:0] c_out;
    logic [N*2-1:0] tick;

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

    always @(posedge clk)
    if (!reset)
        $display("tick=%0d c_out=%0d", tick, c_out);

    initial begin
        // --------------------------------------------------------
        // Матрица A (блочная диагональ: два блока 2x2 и один 1x1)
        // --------------------------------------------------------
        for (int i=0; i<N; i=i+1)
            for (int j=0; j<N; j=j+1)
                A_test[i][j] = 0;

        A_test[0][0] = 1; A_test[0][1] = 2;
        A_test[1][0] = 2; A_test[1][1] = 1;
        
        A_test[2][2] = 1; A_test[2][3] = 2;
        A_test[3][2] = 2; A_test[3][3] = 1;
        
        A_test[4][4] = 1; // Последний элемент

        // --------------------------------------------------------
        // Матрица B (все строки одинаковые для простой проверки)
        // --------------------------------------------------------
        for (int i=0; i<N; i=i+1) begin
            B_test[i][0] = 1; B_test[i][1] = 2; B_test[i][2] = 3; 
            B_test[i][3] = 4; B_test[i][4] = 5;
        end

        // --------------------------------------------------------
        // Вывод матриц в консоль
        // --------------------------------------------------------
        $display("Матрица A:");
        for (int i = 0; i < N; i++)
            $display("  A[%0d] = %0d %0d %0d %0d %0d", i, 
                     A_test[i][0], A_test[i][1], A_test[i][2], A_test[i][3], A_test[i][4]);
        
        $display("Матрица B:");
        for (int i = 0; i < N; i++)
            $display("  B[%0d] = %0d %0d %0d %0d %0d", i,
                     B_test[i][0], B_test[i][1], B_test[i][2], B_test[i][3], B_test[i][4]);

        // --------------------------------------------------------
        // Reset и запуск
        // --------------------------------------------------------
        #20;
        reset = 1;
        #20;
        reset = 0;
        local_tick = 0;
        #10;
        
        $display("Запуск вычислений (ожидание до такта %0d)...", T_LAST);
        
        // Ждем завершения всех вычислений
        wait (tick >= T_LAST);
        #50;
        
        $display("Тест завершён на такте %0d", local_tick);
        $finish;
    end

    // --------------------------------------------------------
    // Сбор результатов
    // --------------------------------------------------------
    logic signed [ACC_WIDTH-1:0] C_result [0:N-1][0:N-1];

    integer offset;
    integer row;
    integer col;
    
    always @(posedge clk) begin
        if (!reset) begin

            // ✅ КРИТИЧЕСКИ ВАЖНО: offset считается от T_FIRST, а не от жесткой цифры
            if (tick >= T_FIRST && tick <= T_LAST) begin
                offset = tick - T_FIRST; 
                row = offset / N;
                col = offset % N;
                
                // Защита от выхода за границы массива
                if (row < N) begin
                    C_result[row][col] = c_out;
                end
            end

            // Вывод результатов после завершения
            if (tick > T_LAST) begin
                $display("\n[DONE] tick=%0d", tick);
                $display("Результат C (ожидаем: 3 6 9 12 15 для строк 0-3, и 1 2 3 4 5 для строки 4):");
                for (int i = 0; i < N; i++)
                    $display("  C[%0d] = %0d %0d %0d %0d %0d", i, 
                        C_result[i][0], C_result[i][1], C_result[i][2], C_result[i][3], C_result[i][4]);
            end
        end
    end

    // --------------------------------------------------------
    // Дамп волн для GTKWave
    // --------------------------------------------------------
    initial begin
        $dumpfile("tb_gemmDriver.vcd");
        $dumpvars(0, tb_gemmDriver);
    end

endmodule