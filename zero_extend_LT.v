module zero_extend_LT (
    input  wire data_input,
    output wire [31:0] data_output
);

assign data_output = {31'b0, data_input};

endmodule