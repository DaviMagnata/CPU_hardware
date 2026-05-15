module sign_extend(

    input wire [15:0] data_input,
    output wire [31:0] data_output
);
    
    assign data_output = {{16{data_input[15]}}, data_input};
    
endmodule