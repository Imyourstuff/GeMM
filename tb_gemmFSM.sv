`timescale 1ns/1ps

module tb_gemmFSM;
    localparam WIDTH = 32;
    localparam N = 4;
    localparam ACC_WIDTH = 2*WIDTH + $clog2(N);

    logic clk;
    logic reset;

    logic     opcode;
    logic [15:0] cmd_addr;
    logic [WIDTH-1:0] a_data;
    logic [WIDTH-1:0] b_data;

    // Статус и результаты
    logic        done;
    logic        c_valid;
    logic [ACC_WIDTH-1:0] c_out;

    int cnt = 0;

    // Матрицы для инициализации (как в оригинале)
    logic [WIDTH-1:0] A_test [0:N-1][0:N-1];
    logic [WIDTH-1:0] B_test [0:N-1][0:N-1];

    gemmFSM #(
        .WIDTH(WIDTH),
        .N(N),
        .ACC_WIDTH(ACC_WIDTH)
    ) driver (
        .clk(clk),
        .reset(reset),
        .opcode(opcode),
        .cmd_addr(cmd_addr),
        .a_data(a_data),
        .b_data(b_data),
        .done(done),
        .c_valid(c_valid),
        .c_out(c_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (!reset)
            cnt <= cnt + 1;
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

        $display("Matrix A:");
        for (int i = 0; i < N; i++)
            $display("  A[%0d] = %0d %0d %0d %0d", i, 
                     A_test[i][0], A_test[i][1], A_test[i][2], A_test[i][3]);
        
        $display("Matrix B:");
        for (int i = 0; i < N; i++)
            $display("  B[%0d] = %0d %0d %0d %0d", i,
                     B_test[i][0], B_test[i][1], B_test[i][2], B_test[i][3]);

        #20;
        reset = 1;
        #20;
        reset = 0;
        cmd_addr = 0;
        cnt = 0;
        #60;

        opcode = 1'b0;
        #20;
        $display("\nLoading Matrixes...");
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                cmd_addr  <= i * N + j;
                b_data <= B_test[i][j];
                a_data <= A_test[i][j];
                #10;
            end
        end

        $display("MEM_A:");
        for(int i=0;i<N;i++) begin
            for(int j=0;j<N;j++)
                $write("%0d ", driver.mem_A[i][j]);
            $display("");
        end

        $display("MEM_B:");
        for(int i=0;i<N;i++) begin
            for(int j=0;j<N;j++)
                $write("%0d ", driver.mem_B[i][j]);
            $display("");
        end

        #60;
    
        $display("\nST_COMPUTE...");
        opcode  <= 1'b1;
        #10;

        // Ждём завершения
        wait (done);
        #80;

        $display("\nEnded on tact %0d", cnt);
        $finish;
    end

    logic signed [ACC_WIDTH-1:0] C_result [0:N-1][0:N-1];
    integer result_cnt = 0;

    integer row;
    integer col;
    always @(posedge clk) begin
        if (!reset) begin
            if (c_valid) begin
                row = result_cnt / N;
                col = result_cnt % N;
                if (row < N) begin
                    C_result[row][col] = c_out;
                end
                result_cnt = result_cnt + 1;
            end

            if (done) begin
                $display("\n[DONE] tick=%0d", cnt);
                for (int i = 0; i < N; i++)
                    $display("  C[%0d] = %0d %0d %0d %0d", i, 
                        C_result[i][0], C_result[i][1], C_result[i][2], C_result[i][3]);
                    $finish;
            end
        end
    end

    initial begin
        $dumpfile("tb_gemmFSM.vcd");
        $dumpvars(0, tb_gemmFSM);
    end

endmodule