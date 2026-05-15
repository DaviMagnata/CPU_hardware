module store_byte_logic (
    input  wire [31:0] memory_data_register, 
    input  wire [31:0] registerB,
    output wire [31:0] data_output
);

assign data_output = {memory_data_register[31:8], registerB[7:0]};

endmodule