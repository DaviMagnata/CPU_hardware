module UnidadeControle (

    input wire clk,
    input wire rst,
    input wire [5:0] Opcode, // IR[31-26]
    
    // Sinais de Saída 
    output reg [2:0] IorD,
    output reg Wr,
    output reg AluSrcA,
    output reg [1:0] AluSrcB,
    output reg [2:0] AluOp,
    output reg [2:0] PcSource,
    output reg PCWrite,
    output reg IRWrite,
    output reg AWrite,
    output reg BWrite,
    output reg ALUOutWrite,
    output reg WriteMDR,
    output reg [1:0] RegDst,
    output reg [2:0] MenToReg, 
    output reg RegWrite,
    output reg MenWriteSrc, 
    output reg PCWriteCond
);

    typedef enum reg [4:0] {
        FETCH_1, FETCH_2, FETCH_3, 
        DECODE,
        LW_1, LW_2, LW_3, LW_4, LW_5,
        SW_1, SW_2, SW_3,
        BEQ_1,BEQ_2,BEQ_3,
        BNE_1,BNE_2,BNE_3,
    } state_t;

    state_t state, next_state;

    // --- 1. Lógica de Transição de Estado (Sequencial) ---
    always @(posedge clk or posedge rst) begin
        if (rst) 
            state <= FETCH_1;
        else 
            state <= next_state;
    end

    // --- 2. Lógica do Próximo Estado (Combinacional) ---
    always @(*) begin
        case (state)
            // Ciclo de Busca (PC+4)
            FETCH_1: next_state = FETCH_2;
            FETCH_2: next_state = FETCH_3;
            FETCH_3: next_state = DECODE;

            // Decodificação (Opcodes em Hexadecimal)
            DECODE: begin
                case (Opcode)
                    6'h23:   next_state = LW_1; // Load Word
                    6'h2b:   next_state = SW_1; // Store Word
                    6'h4:   next_state = BEQ_1; // BEQ
                    6'h5:   next_state = BNE_1; // BNE
                    default: next_state = FETCH_1; // Se não implementado, reseta
                endcase
            end

            // Caminho Load Word (5 ciclos)
            LW_1: next_state = LW_2;
            LW_2: next_state = LW_3;
            LW_3: next_state = LW_4; // Ciclo de espera de memória
            LW_4: next_state = LW_5;
            LW_5: next_state = FETCH_1;

            // Caminho Store Word (3 ciclos)
            SW_1: next_state = SW_2;
            SW_2: next_state = SW_3;
            SW_3: next_state = FETCH_1;

            // Caminho BEQ (3 ciclos)
            BEQ_1: next_state = BEQ_2;
            BEQ_2: next_state = BEQ_3;
            BEQ_3: next_state = FETCH_1;

            // Caminho BNE (3 ciclos)
            BNE_1: next_state = BNE_2;
            BNE_2: next_state = BNE_3;
            BNE_3: next_state = FETCH_1;

            default: next_state = FETCH_1;
        endcase
    end

    // --- 3. Lógica de Saída (Os sinais de controle das "bolinhas") ---
    always @(*) begin
        // Reset padrão de todos os sinais (Evita latches)
        IorD = 3'b000; Wr = 0; AluSrcA = 0; AluSrcB = 2'b00;
        AluOp = 3'b000; PcSource = 3'b000; PCWrite = 0; IRWrite = 0;
        AWrite = 0; BWrite = 0; ALUOutWrite = 0; WriteMDR = 0;
        RegDst = 2'b00; MenToReg = 3'b000; RegWrite = 0; MenWriteSrc = 0; PCWriteCond=0;

        case (state)
            // --- FETCH ---
            FETCH_1: begin
                IorD = 3'b000;
                Wr   = 0;
            end

            FETCH_2: begin
                AluSrcA  = 0;
                AluSrcB  = 2'b11; // Constante 4
                AluOp    = 3'b001; // Soma
                PcSource = 3'b010;
                PCWrite  = 1;
            end

            FETCH_3: begin
                IRWrite = 1;
            end

            // --- DECODE ---
            DECODE: begin
                // No multiciclo puro, o decode costuma apenas preparar
                // Mas no seu desenho o decode já encaminha
            end

            // --- LOAD WORD ---
            LW_1: AWrite = 1;

            LW_2: begin
                AluSrcA = 1;
                AluSrcB = 2'b01; // Imediato
                AluOp = 3'b001;  // Soma endereço
                ALUOutWrite = 1;
            end

            LW_3: begin
                Wr = 0;
                IorD = 3'b100; // Endereço vem da ALUOut
            end

            LW_4: WriteMDR = 1;

            LW_5: begin
                RegDst = 2'b00;
                MenToReg = 3'b000;
                RegWrite = 1;
            end

            // --- STORE WORD ---
            SW_1: begin
                AWrite = 1;
                BWrite = 1;
            end

            SW_2: begin
                AluSrcA = 1;
                AluSrcB = 2'b01;
                AluOp = 3'b001;
                ALUOutWrite = 1;
            end

            SW_3: begin
                Wr = 1;
                IorD = 3'b100;
                MenWriteSrc = 0; // Vem do Reg B
            end

            // --- BEQ ---
            BEQ_1: begin
                AWrite = 1;
                BWrite = 1;
                AluSrcA= 0;
                AluSrcB= 2'b10;
                AluOp  = 3'b001; 
                ALUOutWrite = 1;
            end

            BEQ_2: begin
                ALUOutWrite = 0;
                AluSrcA = 1;
                AluSrcB = 2'b00;
                AluOp = 3'b010;
            end

            BEQ_3: begin
                PCWriteCond = 1;
                PcSource = 3'b011;
            end

            // --- BNE ---
            BNE_1: begin
                AWrite = 1;
                BWrite = 1;
                AluSrcA= 0;
                AluSrcB= 2'b10;
                AluOp  = 3'b001; 
                ALUOutWrite = 1;
            end

            BNE_2: begin
                ALUOutWrite = 0;
                AluSrcA = 1;
                AluSrcB = 2'b00;
                AluOp = 3'b010;
            end

            BNE_3: begin
                PCWriteCond = 1;
                PcSource = 3'b011;
            end

        endcase
    end

endmodule