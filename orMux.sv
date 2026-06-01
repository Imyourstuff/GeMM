module orMux #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] in_x,
    input logic [WIDTH-1:0] in_y,
    output logic [WIDTH-1:0] out
);

assign out = in_x | in_y;

endmodule