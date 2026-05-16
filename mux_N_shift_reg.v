module mux_N_shift_reg (
    input wire    [1:0]        seletor,
    input wire    [4:0]       data_0,
    input wire    [4:0]        data_2,
    output wire   [4:0]       data_output
);

    assign data_output = (seletor == 2'b00) ? data_0 :
                         (seletor == 2'b01) ? 5'b10000 :
                         (seletor == 2'b10) ? data_2 :
                         5'b0;

endmodule