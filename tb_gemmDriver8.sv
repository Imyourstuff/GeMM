`timescale 1ns/1ps

module tb_gemmDriver;

localparam WIDTH = 32;
localparam N = 8;
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

    // Матрица А
    for (int i=0; i<N; i=i+1)
        for (int j=0; j<N; j=j+1)
            A_test[i][j] = 0;

    A_test[0][0] = 1; A_test[0][1] = 2;
    A_test[1][0] = 2; A_test[1][1] = 1;
    A_test[2][2] = 1; A_test[2][3] = 2;
    A_test[3][2] = 2; A_test[3][3] = 1;
    A_test[4][4] = 1; A_test[4][5] = 2;
    A_test[5][4] = 2; A_test[5][5] = 1;
    A_test[6][6] = 1; A_test[6][7] = 2;
    A_test[7][6] = 2; A_test[7][7] = 1;


    //Матрица B
    B_test[0][0]=1; B_test[0][1]=2; B_test[0][2]=3; B_test[0][3]=4;
    B_test[0][4]=5; B_test[0][5]=6; B_test[0][6]=7; B_test[0][7]=8;
    B_test[1][0]=1; B_test[1][1]=2; B_test[1][2]=3; B_test[1][3]=4;
    B_test[1][4]=5; B_test[1][5]=6; B_test[1][6]=7; B_test[1][7]=8;
    B_test[2][0]=1; B_test[2][1]=2; B_test[2][2]=3; B_test[2][3]=4;
    B_test[2][4]=5; B_test[2][5]=6; B_test[2][6]=7; B_test[2][7]=8;
    B_test[3][0]=1; B_test[3][1]=2; B_test[3][2]=3; B_test[3][3]=4;
    B_test[3][4]=5; B_test[3][5]=6; B_test[3][6]=7; B_test[3][7]=8;
    B_test[4][0]=1; B_test[4][1]=2; B_test[4][2]=3; B_test[4][3]=4;
    B_test[4][4]=5; B_test[4][5]=6; B_test[4][6]=7; B_test[4][7]=8;
    B_test[5][0]=1; B_test[5][1]=2; B_test[5][2]=3; B_test[5][3]=4;
    B_test[5][4]=5; B_test[5][5]=6; B_test[5][6]=7; B_test[5][7]=8;
    B_test[6][0]=1; B_test[6][1]=2; B_test[6][2]=3; B_test[6][3]=4;
    B_test[6][4]=5; B_test[6][5]=6; B_test[6][6]=7; B_test[6][7]=8;
    B_test[7][0]=1; B_test[7][1]=2; B_test[7][2]=3; B_test[7][3]=4;
    B_test[7][4]=5; B_test[7][5]=6; B_test[7][6]=7; B_test[7][7]=8;

    $display("Матрица A:");
    for (int i = 0; i < N; i++)
        $display(
            "A[%0d] = %0d %0d %0d %0d %0d %0d %0d %0d",
            i,
            A_test[i][0], A_test[i][1], A_test[i][2], A_test[i][3],
            A_test[i][4], A_test[i][5], A_test[i][6], A_test[i][7]
        );

    $display("Матрица B:");
    for (int i = 0; i < N; i++)
        $display(
            "B[%0d] = %0d %0d %0d %0d %0d %0d %0d %0d",
            i,
            B_test[i][0], B_test[i][1], B_test[i][2], B_test[i][3],
            B_test[i][4], B_test[i][5], B_test[i][6], B_test[i][7]
        );

    // Ресет
    #20;
    reset = 1;
    #20;
    reset = 0;

    local_tick = 0;

    #10;
    wait (tick >= T_LAST);
    #50;

    $display("Тест завершён на такте %0d", local_tick);

    $finish;
end

//Итоговая матрица
logic signed [ACC_WIDTH-1:0] C_result [0:N-1][0:N-1];

integer offset;
integer row;
integer col;

always @(posedge clk) begin
    if (!reset) begin

        if (tick >= T_FIRST && tick <= T_LAST) begin

            offset = tick - 17;
            row = offset / N;
            col = offset % N;

            C_result[row][col] = c_out;

            $display(
                "Значение. Такт=%0d С[%0d][%0d] = %0d",
                tick, row, col, c_out
            );
        end

        if (tick >= 81) begin
            $display("Завершено на такте %0d", tick);

            for (int i = 0; i < N; i++)
                $display(
                    "C[%0d] = %0d %0d %0d %0d %0d %0d %0d %0d", i,
                    C_result[i][0], C_result[i][1],
                    C_result[i][2], C_result[i][3],
                    C_result[i][4], C_result[i][5],
                    C_result[i][6], C_result[i][7]
                );
        end
    end
end

initial begin
    $dumpfile("tb_gemmDriver.vcd");
    $dumpvars(0, tb_gemmDriver);
end


endmodule
