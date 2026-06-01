module mult #(
    parameter WIDTH = 8,
    parameter MODE = 0 // 0 - unsigned, 1 - signed
) (
    input logic [WIDTH-1:0] in_x,
    input logic [WIDTH-1:0] in_y,
    output logic [WIDTH*2-1:0] out
);

generate
    if (MODE == 1)
        assign out = $signed(in_x) * $signed(in_y);
    else
        assign out = in_x * in_y;
endgenerate

endmodule