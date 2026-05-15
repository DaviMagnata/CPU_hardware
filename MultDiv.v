module MultDiv(
    input wire clk,
    input wire reset,
    input wire [31:0] A,
    input wire [31:0] B,
    input wire set_type,
    input wire start,
    output reg [31:0] hi,
    output reg [31:0] lo,
    output reg div_zero,
    output reg ready
);

    reg [5:0] count;
    reg [64:0] product;         
    reg [63:0] dividend;        
    reg signed [31:0] s_divisor; 
    reg busy;

    // Fios auxiliares
    reg [64:0] next_product;
    reg [63:0] next_dividend;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            {hi, lo, div_zero, ready, busy, count} <= 0;
            product <= 65'b0;
            dividend <= 64'b0;
            s_divisor <= 32'b0;
        end else if (start && !busy) begin
            busy <= 1'b1;
            ready <= 1'b0;
            count <= 6'd0;
            
            if (set_type) begin // Multiplicação
                product <= {32'b0, A, 1'b0};
                s_divisor <= B;
                div_zero <= 1'b0;
            end else begin // Divisão
                if (B == 32'b0) begin
                    div_zero <= 1'b1;
                    busy <= 1'b0;
                    ready <= 1'b1;
                end else begin
                    div_zero <= 1'b0;
                    dividend <= {32'b0, (A[31] ? -A : A)};
                    s_divisor <= (B[31] ? -B : B);
                end
            end
        end else if (busy) begin
            if (set_type) begin : STEP_BOOTH
                // Lógica de Booth
                case (product[1:0])
                    2'b01:   next_product = { (product[64:33] + s_divisor), product[32:0] };
                    2'b10:   next_product = { (product[64:33] - s_divisor), product[32:0] };
                    default: next_product = product;
                endcase
                
                // Shift aritmético manual (Preserva o bit 64)
                product <= {next_product[64], next_product[64:1]};
                
                if (count == 6'd31) begin
                    // O resultado de Booth após o shift do ciclo 31
                    // deve considerar o valor que acabou de ser calculado
                    hi <= {next_product[64], next_product[64:34]}; 
                    lo <= next_product[33:2];
                    busy <= 1'b0;
                    ready <= 1'b1;
                end

            end else begin : STEP_DIV
                next_dividend = dividend << 1;
                if (next_dividend[63:32] >= s_divisor) begin
                    next_dividend[63:32] = next_dividend[63:32] - s_divisor;
                    next_dividend[0] = 1'b1;
                end
                dividend <= next_dividend;

                if (count == 6'd31) begin
                    lo <= (A[31] ^ B[31]) ? -next_dividend[31:0] : next_dividend[31:0];
                    hi <= A[31] ? -next_dividend[63:32] : next_dividend[63:32];
                    busy <= 1'b0;
                    ready <= 1'b1;
                end
            end
            count <= count + 1;
        end
    end
endmodule