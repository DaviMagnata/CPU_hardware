module mux_write_register (
    input wire   [2:0]      seletor,
    input wire   [4:0]      data_0,
    input wire   [4:0]      data_2,
    output wire  [4:0]      data_output
);
    
    assign data_output = (seletor == 3'b00) ? data_0:
                      (seletor == 3'b01) ? 5'b11111:
                      (seletor == 3'b10) ? data_2:
                      (seletor == 3'b11) ? 5'b11101:
                      5'b00000;

endmodule