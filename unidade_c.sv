module UnidadeControle (

    input wire clk,
    input wire rst,
    input wire [5:0] Opcode, // IR[31-26]
    input wire [5:0] Funct,
    input wire overflow,      
    input wire div_zero,
    input wire ready,   
    
    // Sinais de Saída
    output reg start,          // Dispara o MultDiv
    output reg set_type,       // 1 para Mul, 0 para Div
    output reg Write_High,     // Escreve no registrador HI do Datapath
    output reg Write_Low,      // Escreve no registrador LO do Datapath 
    output reg WriteTR,     
    output reg ShiftIN, 
    output reg EPCWrite,
    output reg [1:0] ShiftAmount,
    output reg [2:0] ShiftType, 
    output reg [2:0] IorD,
    output reg Wr,
    output reg AluSrcA,
    output reg [1:0] AluSrcB,
    output reg [2:0] AluOp,
    output reg [2:0] PCSource,
    output reg PCWrite,
    output reg IRWrite,
    output reg AWrite,
    output reg BWrite,
    output reg ALUOutWrite,
    output reg WriteMDR,
    output reg [1:0] RegDst,
    output reg [3:0] MenToReg, 
    output reg RegWrite,
    output reg [1:0] MenWriteSrc, 
    output reg [1:0] ErrorType,  
    output reg PCWriteCond
);

    typedef enum reg [6:0] {
        FETCH_1, FETCH_2, FETCH_3, 
        DECODE,
        LW_1, LW_2, LW_3, LW_4, LW_5,
        SW_1, SW_2, SW_3,
        BEQ_1,BEQ_2,BEQ_3,
        BNE_1,BNE_2,BNE_3,
        R_TYPE,
        AND_1,AND_2,AND_3,
        ADD_1,ADD_2,ADD_3,
        SUB_1,SUB_2,SUB_3,
        XCHG_1,XCHG_2,XCHG_3,XCHG_4,XCHG_5,
        SLT_1,SLT_2,
        SRA_1,SRA_2,SRA_3,
        SLL_1,SLL_2,SLL_3,
        MFLO_1,
        MFHI_1,
        JR_1,JR_2,
        LUI_1,LUI_2,LUI_3,
        LB_1,LB_2,LB_3,LB_4,LB_5,
        SRAM_1,SRAM_2,SRAM_3,SRAM_4,SRAM_5,SRAM_6,
        ADDI_1,ADDI_2,ADDI_3,
        SB_1,SB_2,SB_3,SB_4,SB_5,
        J_1,
        JAL_1,JAL_2,
        EXCEPTION_OVERFLOW,EXCEPTION_ZERO,EXCEPTION_OPCODE,EXCEPTION_2,EXCEPTION_3,EXCEPTION_4, 
        MUL_1, DIV_1, ESPERA_MD
    } state_t;

    state_t state, next_state;

    reg [1:0] error_type_reg;

    // --- 1. Lógica de Transição de Estado (Sequencial) ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= FETCH_1;
            error_type_reg <= 2'b00;
        end
        else begin
            state <= next_state;

            if (next_state == EXCEPTION_OVERFLOW) error_type_reg <= 2'b00;
            if (next_state == EXCEPTION_ZERO)     error_type_reg <= 2'b10;
            if (next_state == EXCEPTION_OPCODE)   error_type_reg <= 2'b01;
        end
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
                    6'hf:   next_state = LUI_1;
                    6'h20:  next_state = LB_1;
                    6'h1:   next_state = SRAM_1;
                    6'h8:   next_state = ADDI_1;
                    6'h28:  next_state = SB_1;
                    6'h2:   next_state = J_1;
                    6'h3:   next_state = JAL_1;
                    6'h00: next_state = R_TYPE; // R-Type 
                    default: next_state = EXCEPTION_OPCODE; // Se não implementado, reseta
                endcase
            end

            // Decodificação do Tipo R via Funct
            R_TYPE: begin
                case (Funct)
                    6'h20: next_state = ADD_1; // ADD
                    6'h24: next_state = AND_1; // AND
                    6'h22: next_state = SUB_1; //SUB
                    6'h12: next_state = MFLO_1; //MFLO
                    6'h10: next_state = MFHI_1; //MFHI
                    6'h8: next_state = JR_1; //JR
                    6'h5: next_state = XCHG_1; //XCHG
                    6'h2a: next_state = SLT_1; //SLT
                    6'h3: next_state = SRA_1; //SRA
                    6'h0: next_state = SLL_1; //SLL
                    6'h1a: next_state = DIV_1; //DIV
                    6'h18: next_state = MUL_1; //MUL   
                    default: next_state = FETCH_1; // Se não implementado, reseta
                endcase
            end

            MUL_1: next_state = ESPERA_MD;
            DIV_1: next_state = ESPERA_MD;

            ESPERA_MD: begin
                if (div_zero) 
                    next_state = EXCEPTION_ZERO; // Se dividir por zero, dá erro imediatamente
                else if (ready) 
                    next_state = FETCH_1;      // Terminou? Salva e volta pro início
                else  
                    next_state = ESPERA_MD;    // Se busy=1 e ready=0, fica parado aqui esperando
            end
            
            // Caminho SLT (2 ciclos)
            SLT_1: next_state = SLT_2; SLT_2: next_state = FETCH_1;
            // Caminho SRA (3 ciclos)
            SRA_1: next_state = SRA_2;SRA_2: next_state = SRA_3;SRA_3: next_state = FETCH_1;
            // Caminho SLL (3 ciclos)
            SLL_1: next_state = SLL_2;SLL_2: next_state = SLL_3;SLL_3: next_state = FETCH_1;
            // Caminho XCHG (5 ciclos)
            XCHG_1: next_state = XCHG_2; XCHG_2: next_state = XCHG_3; XCHG_3: next_state = XCHG_4; XCHG_4: next_state = XCHG_5; XCHG_5: next_state = FETCH_1;
            // Caminho MFLO (1 ciclo)
            MFLO_1: next_state = FETCH_1;
            // Caminho MFHI (1 ciclo)
            MFHI_1: next_state = FETCH_1;
            // Caminho JR (2 ciclos)
            JR_1: next_state = JR_2; JR_2: next_state = FETCH_1;
            // Caminho SUB (3 ciclos)
            SUB_1: next_state = SUB_2;
            SUB_2: next_state = (overflow) ? EXCEPTION_OVERFLOW : SUB_3;
            SUB_3: next_state = FETCH_1;
            // Caminho AND (3 ciclos)
            AND_1: next_state = AND_2;AND_2: next_state = AND_3;AND_3: next_state = FETCH_1;
            // Caminho ADD (3 ciclos)
            ADD_1: next_state = ADD_2;
            ADD_2: next_state = (overflow) ? EXCEPTION_OVERFLOW : ADD_3;
            ADD_3: next_state = FETCH_1;
            // Caminho Load Word (5 ciclos)
            LW_1: next_state = LW_2; LW_2: next_state = LW_3; LW_3: next_state = LW_4; LW_4: next_state = LW_5; LW_5: next_state = FETCH_1;
            // Caminho Store Word (3 ciclos)
            SW_1: next_state = SW_2; SW_2: next_state = SW_3;SW_3: next_state = FETCH_1;
            // Caminho BEQ (3 ciclos)
            BEQ_1: next_state = BEQ_2;BEQ_2: next_state = BEQ_3;BEQ_3: next_state = FETCH_1;
            // Caminho BNE (3 ciclos)
            BNE_1: next_state = BNE_2;BNE_2: next_state = BNE_3;BNE_3: next_state = FETCH_1;
            // Caminho LUI (3 ciclos)
            LUI_1: next_state = LUI_2;LUI_2: next_state = LUI_3;LUI_3: next_state = FETCH_1;
            // Caminho LB (5 ciclos)
            LB_1: next_state = LB_2;LB_2: next_state = LB_3;LB_3: next_state = LB_4;LB_4: next_state = LB_5;LB_5: next_state = FETCH_1;
            // Caminho SRAM (6 ciclos)
            SRAM_1:  next_state = SRAM_2;SRAM_2: next_state = SRAM_3;SRAM_3: next_state = SRAM_4;
            SRAM_4: next_state = SRAM_5;SRAM_5: next_state = SRAM_6;SRAM_6: next_state = FETCH_1;
            // Caminho ADDI (3 Ciclos)
            ADDI_1: next_state = ADDI_2;
            ADDI_2: next_state = (overflow) ? EXCEPTION_OVERFLOW : ADDI_3;
            ADDI_3: next_state = FETCH_1;
            // Caminho SB (5 Ciclos)
            SB_1: next_state = SB_2;SB_2: next_state = SB_3;SB_3: next_state = SB_4;SB_4: next_state = SB_5;SB_5: next_state = FETCH_1; 
            // Caminho J (1 ciclo)
            J_1: next_state = FETCH_1;
            // Caminho JAL(2 ciclos)
            JAL_1: next_state = JAL_2; JAL_2: next_state = FETCH_1;
            // Caminho Exceção
            EXCEPTION_OVERFLOW: next_state = EXCEPTION_2; 
            EXCEPTION_ZERO: next_state = EXCEPTION_2; 
            EXCEPTION_OPCODE: next_state = EXCEPTION_2; 
            EXCEPTION_2: next_state = EXCEPTION_3; EXCEPTION_3: next_state = EXCEPTION_4;EXCEPTION_4: next_state = FETCH_1;

            default: next_state = FETCH_1;
        endcase
    end

    // --- 3. Lógica de Saída (Os sinais de controle das "bolinhas") ---
    always @(*) begin
        // Reset padrão de todos os sinais (Evita latches)
        IorD = 3'b000; Wr = 0; AluSrcA = 0; AluSrcB = 2'b00;
        AluOp = 3'b000; PCSource = 3'b000; PCWrite = 0; IRWrite = 0;
        AWrite = 0; BWrite = 0; ALUOutWrite = 0; WriteMDR = 0;
        RegDst = 2'b00; MenToReg = 4'b0000; RegWrite = 0; MenWriteSrc = 2'b00; PCWriteCond=0;
        ShiftType = 3'b000; ShiftIN = 1'b0; ShiftAmount = 2'b00;
        start = 0; set_type = 0; Write_High = 0; Write_Low = 0;
        WriteTR = 0; EPCWrite = 0; ErrorType = 2'b00;

        case (state)
            // --- FETCH ---
            FETCH_1: begin
                IorD = 3'b000; Wr   = 0;
            end

            FETCH_2: begin
                AluSrcA = 0; AluSrcB = 2'b11; AluOp = 3'b001; PCSource = 3'b010; PCWrite  = 1;
            end

            FETCH_3: begin
                IRWrite = 1;
            end

            // --- DECODE ---
            DECODE: begin

            end

            // --- MULTIPLICAÇÃO ---
            MUL_1: begin
                AWrite = 1;BWrite = 1;set_type = 1; start = 1;    
            end

            // --- DIVISÃO ---
            DIV_1: begin
                AWrite = 1;BWrite = 1;set_type = 0; start = 1;    
            end

            ESPERA_MD: begin
                // Mantém o set_type correto baseado na instrução atual
                if (Opcode == 6'h00 && Funct == 6'h1a) begin // Código padrão do DIV
                    set_type = 0;
                end else begin
                    set_type = 1;
                end

                if (ready && !div_zero) begin
                    Write_High = 1;
                    Write_Low = 1;
                end
            end


            // --- LOAD WORD ---
            LW_1: AWrite = 1;

            LW_2: begin
                AluSrcA = 1; AluSrcB = 2'b01; AluOp = 3'b001; ALUOutWrite = 1;
            end

            LW_3: begin
                Wr = 0; IorD = 3'b100; 
            end

            LW_4: WriteMDR = 1;

            LW_5: begin
                RegDst = 2'b00; MenToReg = 4'b0000; RegWrite = 1;
            end

            // --- STORE WORD ---
            SW_1: begin
                AWrite = 1; BWrite = 1;
            end

            SW_2: begin
                AluSrcA = 1; AluSrcB = 2'b01;AluOp = 3'b001;ALUOutWrite = 1;
            end

            SW_3: begin
                Wr = 1; IorD = 3'b100; MenWriteSrc = 2'b00;
            end

            // --- BEQ ---
            BEQ_1: begin
                AWrite = 1;BWrite = 1;AluSrcA= 0;AluSrcB= 2'b10;AluOp  = 3'b001; ALUOutWrite = 1;
            end

            BEQ_2: begin
                ALUOutWrite = 0;AluSrcA = 1;AluSrcB = 2'b00;AluOp = 3'b010;
            end

            BEQ_3: begin
                PCWriteCond = 1;PCSource = 3'b011;
            end

            // --- BNE ---
            BNE_1: begin
                AWrite = 1; BWrite = 1; AluSrcA= 0;AluSrcB= 2'b10; AluOp  = 3'b001; ALUOutWrite = 1;
            end

            BNE_2: begin
                ALUOutWrite = 0; AluSrcA = 1; AluSrcB = 2'b00; AluOp = 3'b010;
            end

            BNE_3: begin
                PCWriteCond = 1; PCSource = 3'b011;
            end

            // --- LUI ---
            LUI_1: begin 
                ShiftType = 3'b001;
            end

            LUI_2: begin 
                ShiftIN = 1; ShiftAmount = 2'b01; ShiftType = 3'b010;
            end

            LUI_3: begin 
                MenToReg = 4'b0001;RegWrite = 1;RegDst = 2'b00;
            end

            // --- LB ---
            LB_1:begin 
                AWrite = 1;
            end

            LB_2: begin 
                AluSrcA = 1;AluSrcB = 2'b01;AluOp = 3'b001;ALUOutWrite = 1;
            end

            LB_3: begin 
                Wr =0;IorD = 3'b100;
            end

            LB_4: begin 
                WriteMDR = 1;
            end

            LB_5: begin 
                RegDst =2'b00;MenToReg = 4'b0110;RegWrite = 1;
            end

            // --- SRAM ---
            SRAM_1: begin 
                AWrite = 1;BWrite = 1;
            end

            SRAM_2: begin 
                AluSrcA = 1;AluSrcB = 2'b01;AluOp = 3'b001;ALUOutWrite = 1;
            end

            SRAM_3: begin 
                IorD = 3'b100;Wr= 0;
            end

            SRAM_4: begin 
                WriteMDR = 1;ShiftType = 3'b001;
            end

            SRAM_5: begin 
                ShiftIN = 0;ShiftAmount= 2'b00;ShiftType = 3'b100;
            end

            SRAM_6: begin 
                MenToReg = 4'b0001;RegWrite = 1;RegDst = 2'b00;
            end

            // --- ADDI --- 
            ADDI_1: begin 
                AWrite = 1;
            end
            
            ADDI_2: begin 
                AluSrcA = 1;AluSrcB = 2'b01;AluOp = 3'b001;ALUOutWrite = 1;
            end

            ADDI_3: begin 
                RegDst = 2'b00;MenToReg = 4'b0101;RegWrite = 1;
            end

            // --- SB ---
            
            SB_1: begin 
                AWrite = 1;BWrite = 1;
            end

            SB_2: begin 
                AluSrcA = 1;AluSrcB = 2'b01;AluOp = 3'b001;ALUOutWrite = 1;
            end

            SB_3: begin 
                Wr = 0;IorD = 3'b100;
            end

            SB_4: begin 
                WriteMDR = 1;
            end

            SB_5: begin 
                Wr = 1;IorD = 3'b100;MenWriteSrc = 2'b11;
            end

            // --- J ---
            J_1: begin 
                PCWrite = 1;PCSource = 3'b001;
            end

            // --- JAL ---
            JAL_1: begin 
                MenToReg = 4'b0111;RegDst = 2'b01;RegWrite = 1;
            end

            JAL_2: begin 
                PCWrite = 1;PCSource = 3'b001;
            end

            // --- SUB ---
            SUB_1: begin
                AWrite = 1; BWrite = 1;
            end

            SUB_2: begin
                AluSrcA = 1; AluSrcB = 2'b00; AluOp = 3'b010; ALUOutWrite = 1;
            end

            SUB_3: begin
                RegDst= 2'b10; MenToReg = 4'b0101; RegWrite = 1;
            end

            // --- ADD ---
            ADD_1: begin
                AWrite = 1; BWrite = 1;
            end

            ADD_2: begin
                AluSrcA = 1; AluSrcB = 2'b00; AluOp = 3'b001; ALUOutWrite = 1;
            end

            ADD_3: begin
                RegDst= 2'b10; MenToReg = 4'b0101; RegWrite = 1;
            end

            // --- AND ---
            AND_1: begin
                AWrite = 1; BWrite = 1;
            end

            AND_2: begin
                AluSrcA = 1; AluSrcB = 2'b00; AluOp = 3'b011; ALUOutWrite = 1;
            end

            AND_3: begin
                RegDst= 2'b10; MenToReg = 4'b0101; RegWrite = 1;
            end

            // --- SRA ---
            SRA_1: begin
                ShiftType = 3'b001; BWrite = 1;
            end

            SRA_2: begin
                ShiftIN=0; ShiftAmount=2'b10; ShiftType = 3'b100;
            end

            SRA_3: begin
                RegDst= 2'b10; MenToReg = 4'b0001; RegWrite = 1;
            end

            // --- SLL ---
            SLL_1: begin
                ShiftType = 3'b001; BWrite = 1;
            end

            SLL_2: begin
                ShiftIN=0; ShiftAmount=2'b10; ShiftType = 3'b010;
            end

            SLL_3: begin
                RegDst= 2'b10; MenToReg = 4'b0001; RegWrite = 1;
            end

            SLT_1: begin
                AWrite = 1; BWrite = 1;
            end

            SLT_2: begin
                AluSrcA = 1; AluSrcB = 2'b00; AluOp = 3'b111; RegDst= 2'b10; MenToReg = 4'b0100; RegWrite = 1;
            end

            JR_1: begin
                AWrite = 1;
            end

            JR_2: begin
                PCSource = 3'b000; PCWrite = 1;
            end

            MFLO_1: begin
                RegWrite = 1; RegDst = 2'b10; MenToReg = 4'b0010;
            end

            MFHI_1: begin
                RegWrite = 1; RegDst = 2'b10; MenToReg = 4'b0011;
            end

            XCHG_1: begin
                AWrite = 1; BWrite = 1;
            end

            XCHG_2: begin
                IorD=3'b001; Wr = 0;
            end

            XCHG_3: begin
                WriteMDR=1;IorD=3'b010; Wr = 0;
            end

            XCHG_4: begin
                WriteTR=1;IorD=3'b001; Wr = 1;MenWriteSrc=2'b01;
            end

            XCHG_5: begin
                IorD=3'b010; Wr = 1;MenWriteSrc=2'b10;
            end

            EXCEPTION_ZERO: begin
                AluSrcA=0;AluSrcB=2'b01;AluOp=3'b010;EPCWrite=1;
            end
            
            EXCEPTION_OPCODE: begin
                AluSrcA=0;AluSrcB=2'b01;AluOp=3'b010;EPCWrite=1;
            end
            
            EXCEPTION_OVERFLOW: begin
                AluSrcA=0;AluSrcB=2'b01;AluOp=3'b010;EPCWrite=1;
            end

            EXCEPTION_2: begin
                Wr=0;IorD=3'b011;ErrorType=error_type_reg;
            end

            EXCEPTION_3: begin
                WriteMDR=1;
            end

            EXCEPTION_4: begin
                PCSource=3'b101;PCWrite=1;
            end


        endcase
    end

endmodule