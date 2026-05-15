module mux_alu_b (
    input wire    [1:0]        seletor,
    input wire    [31:0]       data_0,
    input wire    [31:0]       data_1,
    input wire    [31:0]       data_2,
    output wire   [31:0]       data_output
);

    assign data_output = (seletor == 2'b00) ? data_0:
                      (seletor == 2'b01) ? data_1:
                      (seletor == 2'b10) ? data_2:
                      (seletor == 2'b11) ? 32'b00000000000000000000000000000100:
                      32'b0;



endmodule