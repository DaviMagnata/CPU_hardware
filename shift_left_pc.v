module shift_left_pc(
  input wire [31:0] register_PC,
  input wire [4:0] instruction_rs,        
  input wire [4:0] instruction_rt,        
  input wire [15:0] instruction_imediato, 
  output wire [31:0] output_data
);

  assign output_data = {register_PC[31:28], instruction_rs, instruction_rt, instruction_imediato, 2'b00};

endmodule