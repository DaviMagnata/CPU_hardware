module shift_left_imediato(
    input [31:0] data_input, 
    output [31:0] data_output
);

    assign data_output = data_input << 2;

endmodule