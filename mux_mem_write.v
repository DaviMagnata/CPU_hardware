module mux_mem_write (
    input  wire [1:0] seletor,
    input  wire [31:0] data_0,
    input  wire [31:0] data_1,
    input  wire [31:0] data_2,
    input  wire [31:0] data_3,
    output wire [31:0] data_output
);

assign data_output = (seletor == 2'd0) ? data_0 :
                     (seletor == 2'd1) ? data_1 :
                     (seletor == 2'd2) ? data_2 :
                     (seletor == 2'd3) ? data_3 :
                     32'b0;

endmodule