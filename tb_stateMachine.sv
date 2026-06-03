`timescale 1ns/1ps

module tb_stateMachine;
    localparam N = 4;
    localparam WIDTH = 8;
    localparam ACC_WIDTH = 2*WIDTH + $clog2(N);

    logic clk, rst;
    logic        req, ack, rvalid, busy, done;
    logic [1:0]  cmd;
    logic [15:0] addr;
    logic [WIDTH-1:0]    wdata;
    logic [ACC_WIDTH-1:0] rdata;

    logic [ACC_WIDTH-1:0] val;

    stateMachine #(
        .N(N), .WIDTH(WIDTH), .ACC_WIDTH(ACC_WIDTH)
    ) ctrl (
        .clk(clk), .rst(rst),
        .req(req), .cmd(cmd), .addr(addr), .wdata(wdata),
        .rdata(rdata), .rvalid(rvalid), .ack(ack),
        .busy(busy), .done(done)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    // Задача: отправить команду и дождаться ack
    task send(input logic [1:0] c, input logic [15:0] a, input logic [WIDTH-1:0] w);
        req = 1; cmd = c; addr = a; wdata = w;
        @(posedge clk);
        while (!ack) @(posedge clk);
        req = 0;
        @(posedge clk);
    endtask

    // Задача: прочитать элемент C
    function automatic logic [ACC_WIDTH-1:0] read_C(input int i, input int j);
        send(2'b11, i * N + j, 0);
        return rdata;
    endfunction

    initial begin
        rst = 1;
        #20; rst = 0; #10;

        // ============================================================
        // ТЕСТ 1: Блочная A × одинаковые строки B
        // Ожидаемый результат: каждая строка C = [3, 6, 9, 12]
        // ============================================================
        $display("=== ТЕСТ 1: Блочная матрица ===");

        // Загрузка A (блочная [1,2;2,1] на диагонали)
        send(2'b00, 0*4+0, 1); send(2'b00, 0*4+1, 2);
        send(2'b00, 1*4+0, 2); send(2'b00, 1*4+1, 1);
        send(2'b00, 2*4+2, 1); send(2'b00, 2*4+3, 2);
        send(2'b00, 3*4+2, 2); send(2'b00, 3*4+3, 1);

        // Загрузка B (все строки [1,2,3,4])
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++)
                send(2'b01, i*N+j, j+1);

        // Старт
        send(2'b10, 0, 0);
        wait (done);
        #10;

        // Чтение и проверка результата
        for (int i = 0; i < N; i++) begin
            $write("  C1[%0d] =", i);
            for (int j = 0; j < N; j++) begin
                logic [ACC_WIDTH-1:0] val = read_C(i, j);
                $write(" %0d", val);
                assert (val == 3*(j+1))
                    else $error("Тест1: C[%0d][%0d]=%0d, ожидалось %0d", i, j, val, 3*(j+1));
            end
            $display("");
        end

        // ============================================================
        // ТЕСТ 2: Единичная A × константная B=2
        // Ожидаемый результат: каждая строка C = [2, 2, 2, 2]
        // ============================================================
        $display("\n=== ТЕСТ 2: Единичная матрица ===");

        // Перезагрузка A (единичная)
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++)
                send(2'b00, i*N+j, (i==j) ? 1 : 0);

        // Перезагрузка B (все элементы = 2)
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++)
                send(2'b01, i*N+j, 2);

        // Старт
        send(2'b10, 0, 0);
        wait (done);
        #10;

        // Чтение и проверка результата
        for (int i = 0; i < N; i++) begin
            $write("  C2[%0d] =", i);
            for (int j = 0; j < N; j++) begin
                val = read_C(i, j);
                $write(" %0d", val);
                assert (val == 2)
                    else $error("Тест2: C[%0d][%0d]=%0d, ожидалось 2", i, j, val);
            end
            $display("");
        end

        $display("\n✅ ВСЕ ТЕСТЫ ПРОЙДЕНЫ!");
        #20; $finish;
    end

    initial begin
        $dumpfile("tb_fsm.vcd");
        $dumpvars(0, tb_fsm);
    end
endmodule