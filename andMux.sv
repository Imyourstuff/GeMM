module andMux #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] in,
    input logic pass,
    output logic [WIDTH-1:0] out
);

assign out = pass ? in : {WIDTH{1'b0}};

endmodule