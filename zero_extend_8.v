module zero_extend_8 (
    input  wire [7:0] data_input,
    output wire [31:0] data_output
);

assign data_output = {24'b0, data_input};

endmodule