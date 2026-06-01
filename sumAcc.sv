module sumAcc #(
    parameter WIDTH = 8,
              N = 4,
              ACC_WIDTH  = 2 * WIDTH + $clog2(N),
              MODE = 0 // 0 - unsigned, 1 - signed
) (
  input logic  [2*WIDTH-1:0] in_x,
  input logic  [ACC_WIDTH-1:0] in_accum,
  output logic  [ACC_WIDTH-1:0] out
);

//Размерность до ACC_WIDTH вручную
logic [ACC_WIDTH-1:0] in_y;

//Размерность + Выходы
generate
    if (MODE == 1) begin
        assign in_y = {{(ACC_WIDTH - 2*WIDTH){in_x[2*WIDTH-1]}}, in_x};
        assign out = $signed(in_accum) + $signed(in_y);
        end 
    else begin
        assign in_y = {{(ACC_WIDTH - 2*WIDTH){1'b0}}, in_x};
        assign out = in_accum + in_y;
        end
endgenerate

endmodule