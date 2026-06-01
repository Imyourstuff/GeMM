module gemmMock #(
    parameter WIDTH = 32,
    parameter N = 4,
    parameter ACC_WIDTH = 2*WIDTH + $clog2(N)
)(
    input  logic                clk,
    input  logic                reset,
    input  logic                start,
    
    output logic [7:0]          b_out_1,
    output logic [7:0]          b_out_3,
    output logic                b_valid
);

    logic signed [5:0] tick;
    
    always @(posedge clk or posedge reset) begin
        if (reset) tick <= -12;  // Начальное смещение
        else if (start) tick <= tick + 1;
    end
    
    always @(*) begin
        b_out_1 = 8'd0;
        b_out_3 = 8'd0;
        b_valid = 0;
        
        // Диапазон загрузки: t = -11 ... -2
        if (tick >= -11 && tick <= -2) begin
            b_valid = 1;
            
            // Вход 1: левая половина (строки 2, затем 1)
            if (tick >= -9 && tick <= -6) begin
                // Вторая строка: b21, b22, b23, b24
                b_out_1 = 8'(20 + (-tick - 9));  // 21, 22, 23, 24
            end
            else if (tick >= -5 && tick <= -2) begin
                // Первая строка: b11, b12, b13, b14
                b_out_1 = 8'(10 + (-tick - 5));  // 11, 12, 13, 14
            end
            
            // Вход 3: правая половина (строки 4, затем 3) ← ИСПРАВЛЕНО
            if (tick >= -11 && tick <= -8) begin
                // Четвёртая строка: b41, b42, b43, b44
                b_out_3 = 8'(40 + (-tick - 11));  // 41, 42, 43, 44
            end
            else if (tick >= -7 && tick <= -4) begin
                // Третья строка: b31, b32, b33, b34
                b_out_3 = 8'(30 + (-tick - 7));   // 31, 32, 33, 34
            end
        end
    end
endmodule