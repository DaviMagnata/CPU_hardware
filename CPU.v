module CPU(
    input wire clk,
    input wire reset
);

wire[31:0] pc_out;
wire[31:0] mux_ad_mem_out;
wire[31:0] mux_mem_write_out;
wire[31:0] memory_out;
wire[31:0] temp_register_out;
wire[31:0] mem_data_reg_out;
wire[4:0] mux_write_register_out;
wire[31:0] mux_write_data_register_out;
wire[31:0] reg_out_1;
wire[31:0] reg_out_2;
wire[31:0] reg_a_out;
wire[31:0] reg_b_out;
wire[31:0] mux_alu_a_out;
wire[31:0] mux_alu_b_out;
wire[31:0] ALU_out;
wire[31:0] ALUout_out;
wire[31:0] EPC_out;
wire[31:0] mux_pc_out;
wire[31:0] zero_extend_memdata_out;
wire[31:0] zero_extend_alu_out;
wire[31:0] sign_extend_out;
wire[31:0] shift_left_imediato_out;
wire[31:0] DM_hi;
wire[31:0] DM_lo;
wire[31:0] hi_out;
wire[31:0] lo_out;
wire[31:0] byte_logic_out;
wire[31:0] mux_in_shift_out;
wire[31:0] mux_N_shift_out;
wire[31:0] ShiftReg_out;
wire[31:0] zero_extend_8_out;
wire [5:0] IR_31_26; 
wire [4:0] IR_25_21;
wire [4:0] IR_20_16;
wire [15:0] IR_15_0;
wire [25:0] IR_25_0;
assign IR_25_0 = {IR_25_21, IR_20_16, IR_15_0};
wire[31:0] mux_excecao_out;
wire[31:0] shift_left_pc_out;

wire [2:0] PCSource;
wire WritePC;
wire[2:0] IorD;
wire Wr;
wire PcWriteCond;
wire IRWrite;
wire [2:0] RegDst;
wire [3:0] MenToReg;
wire RegWrite;
wire AWrite;
wire BWrite;
wire ALUSrcA;
wire [1:0] ALUSrcB;
wire [2:0] ALUControl_out;
wire Overflow_out;
wire Negativo;
wire z_out;
wire Igual_out;
wire Maior_out;
wire Menor_out;
wire ALUOutWrite;
wire WriteEPC;
wire WriteMDR;
wire ready_MD;
wire set_type_MD;
wire startMD;
wire div_zero_MD;
wire WriteHigh;
wire WriteLow;
wire Write_Temp_Reg;
wire ShiftIN;
wire [1:0] ErrorType;
wire [2:0] ShiftType;
wire [1:0] ShiftAmount;
wire [1:0] MenWriteSrc;
wire mux_zero_alu_out;

Registrador pc(
    .Clk(clk),
    .Reset(reset),
    .Load(WritePC),
    .Entrada(mux_pc_out),
    .Saida(pc_out)
);

Memoria Mem(
    .Address(mux_ad_mem_out),
    .Clock(clk),
    .Wr(Wr),
    .Datain(mux_mem_write_out),
    .Dataout(memory_out)
);

Instr_reg Registrador_instrucoes(
    .Clk(clk),
    .Reset(reset),
    .Load_ir(IRWrite),
    .Entrada(memory_out),
    .Instr31_26(IR_31_26),
    .Instr25_21(IR_25_21),
    .Instr20_16(IR_20_16),
    .Instr15_0(IR_15_0)
);

mux_write_register Write_Register_M(
    .seletor(RegDst),
    .data_0(IR_20_16),
    .data_2(IR_15_0[15:11]),
    .data_output(mux_write_register_out)
);

mux_write_data_register Data_register_M(
    .seletor(MenToReg),
    .data_0(mem_data_reg_out),
    .data_1(ShiftReg_out),
    .data_2(hi_out),
    .data_3(lo_out),
    .data_4(zero_extend_alu_out),
    .data_5(ALUout_out),
    .data_6(zero_extend_8_out),
    .data_7(pc_out),
    .data_output(mux_write_data_register_out)
);

Banco_reg Registradores(
    .Clk(clk),
    .Reset(reset),
    .RegWrite(RegWrite),
    .ReadReg1(IR_25_21),
    .ReadReg2(IR_20_16),
    .WriteReg(mux_write_register_out),
    .WriteData(mux_write_data_register_out),
    .ReadData1(reg_out_1),
    .ReadData2(reg_out_2)
);

Registrador A(
    .Clk(clk),
    .Reset(reset),
    .Load(AWrite),
    .Entrada(reg_out_1),
    .Saida(reg_a_out)
)
;

Registrador B(
    .Clk(clk),
    .Reset(reset),
    .Load(BWrite),
    .Entrada(reg_out_2),
    .Saida(reg_b_out)
);

mux_alu_a mux_a(
    .seletor(ALUSrcA),
    .data_0(pc_out),
    .data_1(reg_a_out),
    .data_output(mux_alu_a_out)
);

mux_alu_b mux_b (
.seletor(ALUSrcB),
.data_0(reg_b_out),
.data_1(sign_extend_out),
.data_2(shift_left_imediato_out),
.data_output(mux_alu_b_out)
);

ula32 ALU(
    .A(mux_alu_a_out),
    .B(mux_alu_b_out),
    .Seletor(ALUControl_out),
    .S(ALU_out),
    .Overflow(Overflow_out),
    .Negativo(Negativo),
    .z(z_out),
    .Igual(Igual_out),
    .Maior(Maior_out),
    .Menor(Menor_out)

);

Registrador ALUOut(
    .Clk(clk),
    .Reset(reset),
    .Load(ALUOutWrite),
    .Entrada(ALU_out),
    .Saida(ALUOut_out)
);

Registrador EPC(
    .Clk(clk),
    .Reset(reset),
    .Load(WriteEPC),
    .Entrada(ALU_out),
    .Saida(EPC_out)
);

Registrador Mem_data_reg(
    .Clk(clk),
    .Reset(reset),
    .Load(WriteMDR),
    .Entrada(memory_out),
    .Saida(mem_data_reg_out)
);



Registrador Temp_register(
    .Clk(clk),
    .Reset(reset),
    .Load(Write_Temp_Reg),
    .Entrada(memory_out),
    .Saida(temp_register_out)
);

zero_extend_LT extendLT(
    .data_input(Menor_out),
    .data_output(zero_extend_alu_out)
);

MultDiv MultDiv(
    .clk(clk),
    .reset(reset),
    .A(reg_a_out),
    .B(reg_b_out),
    .set_type(set_type_MD),
    .start(startMD),
    .hi(DM_hi),
    .lo(DM_lo),
    .div_zero(div_zero_MD),
    .ready(ready_MD)
);

Registrador hi(
    .Clk(clk),
    .Reset(reset),
    .Load(WriteHigh),
    .Entrada(DM_hi),
    .Saida(hi_out)
);

Registrador lo(
    .Clk(clk),
    .Reset(reset),
    .Load(WriteLow),
    .Entrada(DM_lo),
    .Saida(lo_out)
);

store_byte_logic byte_logic(
    .memory_data_register(mem_data_reg_out),
    .registerB(reg_b_out),
    .data_output(byte_logic_out)
);


mux_in_shift_reg shift_in_mux(
    .seletor(ShiftIN),
    .data_0(reg_b_out),
    .data_1(IR_15_0),
    .data_output(mux_in_shift_out)
);

mux_N_shift_reg shift_N_mux(
    .seletor(ShiftAmount),
    .data_0(mem_data_reg_out),
    .data_2(IR_15_0[10:6]),
    .data_output(mux_N_shift_out)
);

RegDesloc ShiftReg(
    .Clk(clk),
    .Reset(reset),
    .Shift(ShiftType),
    .N(mux_N_shift_out),
    .Entrada(mux_in_shift_out),
    .Saida(ShiftReg_out)
);

sign_extend sign_extend(
    .data_input(IR_15_0),
    .data_output(sign_extend_out)
);

shift_left_imediato shift_l_imediato(
    .data_input(sign_extend_out),
    .data_output(shift_left_imediato_out)
);

zero_extend_8 zero_extend_8(
    .data_input(mem_data_reg_out[7:0]),
    .data_output(zero_extend_8_out)
);

mux_excecao mux_excecao(
    .seletor(ErrorType),
    .data_output(mux_excecao_out)
);

shift_left_pc shift_left_pc(
    .register_PC(pc_out),
    .instruction_rs(IR_25_21),
    .instruction_rt(IR_20_16),
    .instruction_imediato(IR_15_0),
    .output_data(shift_left_pc_out)
);

mux_pc mux_pc(
    .seletor(PCSource),
    .data_0(reg_a_out),
    .data_1(shift_left_pc_out),
    .data_2(ALU_out),
    .data_3(ALUout_out),
    .data_4(EPC_out),
    .data_5(zero_extend_8_out),
    .data_6(mem_data_reg_out),
    .data_output(mux_pc_out)
);

mux_ad_mem mux_ad_mem(
    .seletor(IorD),
    .data_0(pc_out),
    .data_1(reg_a_out),
    .data_2(reg_b_out),
    .data_3(mux_excecao_out),
    .data_4(ALUout_out),
    .data_output(mux_ad_mem_out)
);

mux_mem_write mux_mem_write(
    .seletor(MenWriteSrc),
    .data_0(reg_b_out),
    .data_1(temp_register_out),
    .data_2(mem_data_reg_out),
    .data_3(byte_logic_out),
    .data_output(mux_mem_write_out)
);

mux_zero_alu mux_zero_alu(
    .seletor(IR_31_26[0]),
    .data_input(z_out),
    .data_output(mux_zero_alu_out)
);

endmodule