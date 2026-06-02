`timescale 1ns/1ps

module tb_gemmDriver;

    localparam WIDTH = 32;
    localparam N = 16;
    localparam ACC_WIDTH = 2*WIDTH + $clog2(N);
    localparam T_FIRST = 2*N + 1;
    localparam T_LAST  = N*N + 2*N;

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

    always @(posedge clk) begin
        if (!reset)
            local_tick <= local_tick + 1;
    end


    initial begin
        for (int i=0; i<N; i=i+1)
            for (int j=0; j<N; j=j+1)
                A_test[i][j] = 0;

        for (int k=0; k<N/2; k=k+1) begin
            A_test[2*k][2*k]   = 1; A_test[2*k][2*k+1]   = 2;
            A_test[2*k+1][2*k] = 2; A_test[2*k+1][2*k+1] = 1;
        end

        for (int i=0; i<N; i=i+1) begin
            B_test[i][0]=1;  B_test[i][1]=2;  B_test[i][2]=3;  B_test[i][3]=4;
            B_test[i][4]=5;  B_test[i][5]=6;  B_test[i][6]=7;  B_test[i][7]=8;
            B_test[i][8]=9;  B_test[i][9]=10; B_test[i][10]=11; B_test[i][11]=12;
            B_test[i][12]=13; B_test[i][13]=14; B_test[i][14]=15; B_test[i][15]=16;
        end

        $display("Матрица A:");
        for (int i = 0; i < N; i++)
            $display(
                "A[%02d] = %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d",
                i,
                A_test[i][0], A_test[i][1], A_test[i][2], A_test[i][3],
                A_test[i][4], A_test[i][5], A_test[i][6], A_test[i][7],
                A_test[i][8], A_test[i][9], A_test[i][10], A_test[i][11],
                A_test[i][12], A_test[i][13], A_test[i][14], A_test[i][15]
            );

        $display("\nМатрица B:");
        for (int i = 0; i < N; i++)
            $display(
                "B[%02d] = %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d",
                i,
                B_test[i][0], B_test[i][1], B_test[i][2], B_test[i][3],
                B_test[i][4], B_test[i][5], B_test[i][6], B_test[i][7],
                B_test[i][8], B_test[i][9], B_test[i][10], B_test[i][11],
                B_test[i][12], B_test[i][13], B_test[i][14], B_test[i][15]
            );

        #20;
        reset = 1;
        #20;
        reset = 0;

        local_tick = 0;
        #10;

        $display("\nЗапуск вычислений...");

        wait (tick >= T_LAST);

        #50;

        $display("\nТест завершён на такте %0d", local_tick);

        $finish;
    end

    logic signed [ACC_WIDTH-1:0] C_result [0:N-1][0:N-1];

    integer offset;
    integer row;
    integer col;

    always @(posedge clk)
    if (!reset)
        $display("tick=%0d c_out=%0d", tick, c_out);

    always @(posedge clk) begin
        if (!reset) begin
            if (tick >= T_FIRST && tick <= T_LAST) begin

                offset = tick - T_FIRST;
                row = offset / N;
                col = offset % N;

                if (row < N) begin
                    C_result[row][col] = c_out;
                end
            end

            if (tick > T_LAST) begin

                $display("\n[DONE] tick=%0d", tick);

                for (int i = 0; i < N; i++)
                    $display(
                        "C[%02d] = %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d",
                        i,
                        C_result[i][0], C_result[i][1],
                        C_result[i][2], C_result[i][3],
                        C_result[i][4], C_result[i][5],
                        C_result[i][6], C_result[i][7],
                        C_result[i][8], C_result[i][9],
                        C_result[i][10], C_result[i][11],
                        C_result[i][12], C_result[i][13],
                        C_result[i][14], C_result[i][15]
                    );
            end
        end
    end

    initial begin
        $dumpfile("tb_gemmDriver.vcd");
        $dumpvars(0, tb_gemmDriver);
    end

endmodule