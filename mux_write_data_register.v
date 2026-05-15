module mux_write_data_register (
    
    input  wire [3:0] seletor,
    input  wire [31:0] data_0,
    input  wire [31:0] data_1,
    input  wire [31:0] data_2,
    input  wire [31:0] data_3,
    input  wire [31:0] data_4,
    input  wire [31:0] data_5,
    input  wire [31:0] data_6,
    input  wire [31:0] data_7,
    output wire [31:0] data_output
);

assign data_output = (seletor == 4'd0) ? data_0 :
                     (seletor == 4'd1) ? data_1 :
                     (seletor == 4'd2) ? data_2 :
                     (seletor == 4'd3) ? data_3 :
                     (seletor == 4'd4) ? data_4 :
                     (seletor == 4'd5) ? data_5 :
                     (seletor == 4'd6) ? data_6 :
                     (seletor == 4'd7) ? data_7 :
                     (seletor == 4'd8) ? 32'd227 :
                     32'b0;

endmodule