`timescale 1ns/1ps

module tb_primitives;

    localparam WIDTH = 8;
    localparam N = 4;
    localparam ACC_WIDTH = 2*WIDTH + $clog2(N);

    logic clk;
    logic reset;

    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    // dff задержка
    logic dff_d, dff_q;
    dffMy test_dff (
        .clk(clk), .reset(reset), .d_in(dff_d), .q_out(dff_q)
    );

    //Инвертор
    logic not_in, not_out;
    notA test_not (
        .a(not_in), .out(not_out)
    );

    // Gate
    logic [WIDTH-1:0] and_in, and_out;
    logic and_pass;
    andMux #(.WIDTH(WIDTH)) test_and (
        .in(and_in), .pass(and_pass), .out(and_out)
    );

    // Мультиплексирующее ИЛИ
    logic [WIDTH-1:0] or_x, or_y, or_out;
    orMux #(.WIDTH(WIDTH)) test_or (
        .in_x(or_x), .in_y(or_y), .out(or_out)
    );

    //Регистр со сбросом
    logic [WIDTH-1:0] regx_d, regx_q;
    regX #(.WIDTH(WIDTH)) test_regx (
        .clk(clk), .reset(reset), .d_in(regx_d), .q_out(regx_q)
    );

    //Модуль регистра с разрешением на запись
    logic [WIDTH-1:0] re_d, re_q;
    logic re_en;
    regEnable #(.WIDTH(WIDTH)) test_re (
        .clk(clk), .reset(reset), .enable(re_en), .d_in(re_d), .q_out(re_q)
    );

    //Линия регистров
    logic [WIDTH-1:0] chain_d, chain_q;
    regChain #(.WIDTH(WIDTH), .N(N)) test_chain (
        .clk(clk), .reset(reset), .d_in(chain_d), .q_out(chain_q)
    );

    //Умножитель
    logic [WIDTH-1:0] mult_x, mult_y;
    logic [2*WIDTH-1:0] mult_out;
    mult #(.WIDTH(WIDTH), .MODE(0)) test_mult (
        .in_x(mult_x), .in_y(mult_y), .out(mult_out)
    );

    //Регистр
    logic [ACC_WIDTH-1:0] racc_d, racc_q;
    regAcc #(.WIDTH(WIDTH), .N(N), .ACC_WIDTH(ACC_WIDTH)) test_racc (
        .clk(clk), .reset(reset), .d_in(racc_d), .q_out(racc_q)
    );

    //Сумматор
    logic [2*WIDTH-1:0] sum_x;
    logic [ACC_WIDTH-1:0] sum_acc_in, sum_out;
    sumAcc #(.WIDTH(WIDTH), .N(N), .ACC_WIDTH(ACC_WIDTH), .MODE(0)) test_sum (
        .in_x(sum_x), .in_accum(sum_acc_in), .out(sum_out)
    );

    initial begin
        reset = 1;
        #5;
        reset = 0;

        dff_d = 1;
        #2; // 1 такт
        assert (dff_q == 1) else $error("FAILED: dffMy not '1'");
        dff_d = 0;
        #2;
        assert (dff_q == 0) else $error("FAILED: dffMy not '0'");
        $display("[PASS] dffMy");

        not_in = 0; #2;
        assert (not_out == 1) else $error("FAILED: notA(0) != 1");
        not_in = 1; #2;
        assert (not_out == 0) else $error("FAILED: notA(1) != 0");
        $display("[PASS] notA ");

        and_in = 8'd42;
        and_pass = 1; #2;
        assert (and_out == 8'd42) else $error("FAILED: andMux no data when pass=1");
        and_pass = 0; #2;
        assert (and_out == 8'd0)  else $error("FAILED: andMux output not 0 when pass=0");
        $display("[PASS] andMux.");

        or_x = 8'd10; or_y = 8'd0; #10
        assert (or_out == 8'd10) else $error("FAILED: orMux choose not in_x");
        or_x = 8'd0;  or_y = 8'd20; #10
        assert (or_out == 8'd20) else $error("FAILED: orMux choose not in_y");
        $display("[PASS] orMux.");

        regx_d = 8'd99;
        #10; // 1 такт
        assert (regx_q == 8'd99) else $error("FAILED: regX didn't save");
        reset = 1; #10;
        assert (regx_q == 8'd0)  else $error("FAILED: regX didn't reset");
        reset = 0;
        $display("[PASS] regX.");

        re_en = 1; re_d = 8'd77;
        #10;
        assert (re_q == 8'd77) else $error("FAILED: regEnable when enable=1");
        re_en = 0; re_d = 8'd88;
        #10;
        assert (re_q == 8'd77) else $error("FAILED: regEnable changed when enable=0");
        $display("[PASS] regEnable.");

        chain_d = 8'd11; #2; // Такт 1
        chain_d = 8'd22; #2; // Такт 2
        chain_d = 8'd33; #2; // Такт 3
        chain_d = 8'd44; #2; // Такт 4 (данные '11' должны выйти)
        assert (chain_q == 8'd11) else $error($sformatf("FAILED: regChain delay. Awaited 11, got %0d", chain_q));
        chain_d = 8'd55; #2; // Такт 5 (данные '22' должны выйти)
        assert (chain_q == 8'd22) else $error($sformatf("FAILED: regChain delay. Wanted 22, got %0d", chain_q));
        $display("[PASS] regChain.");

        mult_x = 8'd6;
        mult_y = 8'd7;
        #10; // Комбинационная логика
        assert (mult_out == 16'd42) else $error($sformatf("FAILED: mult. Wanted 42, got %0d", mult_out));
        $display("[PASS] mult.");
    
        racc_d = 18'd100; #10;
        racc_d = 18'd200; #10;
        racc_d = 18'd300; #10;
        racc_d = 18'd400; #10; // Выход должен быть 400
        assert (racc_q == 18'd400) else $error($sformatf("FAILED: regAcc. 400, got %0d", racc_q));
        $display("[PASS] regAcc.");

        sum_x = 16'd50;
        sum_acc_in = 18'd150;
        #10; // Комбинационная логика
        assert (sum_out == 18'd200) else $error($sformatf("FAILED: sumAcc. Wanted 200, got %0d", sum_out));
        $display("[PASS] sumAcc.");

        #20;
        $finish;
    end

    initial begin
        $dumpfile("tb_primitives.vcd");
        $dumpvars(0, tb_primitives);
    end

endmodule