module mux_in_shift_reg (
    input wire                 seletor,
    input wire    [31:0]       data_0,
    input wire    [15:0]       data_1,
    output wire   [31:0]       data_output
);

    assign data_output = (seletor) ? {16'b0, data_1} : data_0;

endmodule