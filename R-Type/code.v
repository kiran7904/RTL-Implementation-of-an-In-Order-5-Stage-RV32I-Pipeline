module simple_rtype_cpu (
    input  wire clk,
    input  wire rst
);

    // Program Counter
    reg [31:0] pc;

    // Instruction memory
    reg [31:0] instr_mem [0:31];

    // Register file
    reg [31:0] regs [0:31];

    // Current instruction
    wire [31:0] instruction;

    // R-type fields
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;

    // Register values
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    // ALU result
    wire [31:0] alu_result;

    // Instruction fetch
    assign instruction = instr_mem[pc[6:2]];

    // Decode
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd  = instruction[11:7];

    // Register read
    assign rs1_data = regs[rs1];
    assign rs2_data = regs[rs2];

    // ADD operation
    assign alu_result = rs1_data + rs2_data;

    // PC and register write
    always @(posedge clk) begin
        if (rst) begin
            pc <= 32'h00000000;
        end
        else begin

            // Write ALU result to destination register
            if (rd != 5'd0)
                regs[rd] <= alu_result;

            // Next instruction
            pc <= pc + 32'd4;
        end
    end

endmodule
