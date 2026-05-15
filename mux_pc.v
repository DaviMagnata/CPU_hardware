module mux_pc (
    input  wire [2:0] seletor,
    input  wire [31:0] data_0,
    input  wire [31:0] data_1,
    input  wire [31:0] data_2,
    input  wire [31:0] data_3,
    input  wire [31:0] data_4,
    input  wire [31:0] data_5,
    input  wire [31:0] data_6,
    output wire [31:0] data_output
);

assign data_output = (seletor == 3'd0) ? data_0 :
                     (seletor == 3'd1) ? data_1 :
                     (seletor == 3'd2) ? data_2 :
                     (seletor == 3'd3) ? data_3 :
                     (seletor == 3'd4) ? data_4 :
                     (seletor == 3'd5) ? data_5 :
                     (seletor == 3'd6) ? data_6 :
                     32'b0;

endmodule