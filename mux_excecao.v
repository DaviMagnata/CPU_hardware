module mux_excecao(
    input wire       [1:0]       seletor,
    output wire      [31:0]      data_output
);

    assign data_output = (seletor == 2'b00) ? 32'b00000000000000000000000011111101 :
                      (seletor == 2'b01) ? 32'b00000000000000000000000011111110 :
                      (seletor == 2'b10) ? 32'b00000000000000000000000011111111 :
                      32'b0;
    
endmodule