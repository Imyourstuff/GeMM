module processingElement #(
    parameter   WIDTH = 8,
                N = 4,
                ACC_WIDTH  = 2 * WIDTH + $clog2(N),
				MODE = 0,
                ID = 0
) (
    input logic clk, 
    input logic reset,
    input logic alpha, 
    input logic beta,
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    input logic [ACC_WIDTH-1:0] c,

    output logic [WIDTH-1:0] a_j2,
    output logic [WIDTH-1:0] b_j2,
    output logic alpha_j1,
    output logic beta_j1,
    output logic [ACC_WIDTH-1:0] c_j1
);

//Цепочка регистров R1
//Рассчитываем количество регистров в R1 исходя из порядкового номера
localparam N1 = (ID < ((N + 1) / 2)) ? (N + 1) : (N - 1);
regChain #(.WIDTH(WIDTH), .N(N1)) r1 (
    .clk(clk),
    .reset(reset),
    .d_in(b),
    .q_out(b_j2)
);

logic [WIDTH-1:0] and1_or1;

andMux #(.WIDTH(WIDTH)) and1 (
    .in(b),
    .pass(alpha),
    .out(and1_or1)
);

logic [WIDTH-1:0] or1_r2;
logic [WIDTH-1:0] and2_or1;

orMux #(.WIDTH(WIDTH)) or1 (
    .in_x(and1_or1),
    .in_y(and2_or1),
    .out(or1_r2)
);

logic [WIDTH-1:0] reg2_1_out;

//Первый регистр группы R2 отдельно
//Нужен выход с него в умножитель
regX #(.WIDTH(WIDTH)) r2_1 (
    .clk(clk),
    .reset(reset),
    .d_in(or1_r2),
    .q_out(reg2_1_out)
);

logic [WIDTH-1:0] r2_and2;

regChain #(.WIDTH(WIDTH), .N(N-1)) r2 (
    .clk(clk),
    .reset(reset),
    .d_in(reg2_1_out),
    .q_out(r2_and2)
);

logic not1_and2;

notA n1 (.a(alpha), .out(not1_and2));

andMux #(.WIDTH(WIDTH)) and2 (
    .in(r2_and2),
    .pass(not1_and2),
    .out(and2_or1)
);

//Линия задержек для Aj из двух регистров
//Попробую тоже в regChain запихать хотя мб лучше раздельно
regChain #(.WIDTH(WIDTH), .N(2)) r34 (
    .reset(reset),
    .clk(clk),
    .d_in(a),
    .q_out(a_j2)
);

logic and3_reg5;

logic [WIDTH-1:0] reg5_mult;
//Тут не от clk а от and с clk
//and(and3_reg5, clk, beta) заменено на enable
regEnable #(.WIDTH(WIDTH)) r5 (
    .reset(reset),
    .clk(clk),
    .enable(beta),
    .d_in(a),
    .q_out(reg5_mult)
);

logic [2*WIDTH-1:0] mult_to_sum;

mult #(.WIDTH(WIDTH), .MODE(MODE)) m1 (
    .in_x(reg5_mult),
    .in_y(reg2_1_out),
    .out(mult_to_sum)
);

logic [ACC_WIDTH-1:0] r6_sum;

regAcc #(.WIDTH(WIDTH), .N(N), .ACC_WIDTH(ACC_WIDTH)) r6 (
    .clk(clk),
    .reset(reset),
    .d_in(c),
    .q_out(r6_sum)
);

sumAcc #(.WIDTH(WIDTH), .N(N), .ACC_WIDTH(ACC_WIDTH), .MODE(MODE)) s1 (
    .in_x(mult_to_sum),
    .in_accum(r6_sum),
    .out(c_j1)
);

//Не хочет создавать просто dff
dffMy d1(
    .clk(clk),
    .reset(reset),
    .d_in(alpha),
    .q_out(alpha_j1)
);

dffMy d2(
    .clk(clk),
    .reset(reset),
    .d_in(beta),
	.q_out(beta_j1)
);

endmodule