module mux_zero_alu (
    input  wire seletor,
    input  wire data_input,
    output wire data_output
);

assign data_output = (seletor) ? ~data_input : data_input;

endmodule