// ============================================================
// 5-STAGE RV32I IN-ORDER PIPELINE
// I-TYPE ARITHMETIC INSTRUCTIONS
//
// Example:
// ADDI x5, x1, 10
//
// IF -> ID -> EX -> MEM -> WB
// ============================================================


// ============================================================
// 1. INSTRUCTION FETCH
// ============================================================

module if_stage (
    input  logic        clk,
    input  logic        rst,

    output logic [31:0] pc,
    output logic [31:0] instruction
);

    logic [31:0] instr_mem [0:255];

    initial begin
        $readmemh("program.hex", instr_mem);
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'h00000000;
        else
            pc <= pc + 32'd4;
    end

    assign instruction = instr_mem[pc[9:2]];

endmodule


// ============================================================
// 2. IF / ID PIPELINE REGISTER
// ============================================================

module if_id_reg (
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] pc_in,
    input  logic [31:0] instr_in,

    output logic [31:0] pc_out,
    output logic [31:0] instr_out
);

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin
            pc_out    <= 32'd0;
            instr_out <= 32'd0;
        end
        else begin
            pc_out    <= pc_in;
            instr_out <= instr_in;
        end

    end

endmodule


// ============================================================
// 3. ID STAGE
// ============================================================

module id_stage (
    input  logic [31:0] instr,

    output logic [4:0]  rs1,
    output logic [4:0]  rd,

    output logic [2:0]  funct3,

    output logic [31:0] immediate,

    output logic        reg_write,
    output logic        alu_src,
    output logic [3:0]  alu_control,

    output logic [31:0] rs1_data
);

    logic [31:0] regfile [0:31];

    // --------------------------------------------------------
    // Instruction fields
    // --------------------------------------------------------

    assign rs1    = instr[19:15];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];


    // --------------------------------------------------------
    // Register read
    // --------------------------------------------------------

    assign rs1_data = (rs1 == 5'd0) ? 32'd0 : regfile[rs1];


    // --------------------------------------------------------
    // Immediate generation
    //
    // I-type immediate = instruction[31:20]
    // Sign extended to 32 bits
    // --------------------------------------------------------

    assign immediate = {{20{instr[31]}}, instr[31:20]};


    // --------------------------------------------------------
    // Control + ALU operation
    // --------------------------------------------------------

    always_comb begin

        reg_write  = 1'b0;
        alu_src    = 1'b0;
        alu_control = 4'b0000;

        // I-type arithmetic opcode = 0010011
        if (instr[6:0] == 7'b0010011) begin

            reg_write = 1'b1;
            alu_src   = 1'b1;

            case (funct3)

                3'b000:
                    alu_control = 4'b0000;   // ADDI

                3'b111:
                    alu_control = 4'b0010;   // ANDI

                3'b110:
                    alu_control = 4'b0011;   // ORI

                3'b100:
                    alu_control = 4'b0100;   // XORI

                default:
                    alu_control = 4'b0000;

            endcase

        end

    end

endmodule


// ============================================================
// 4. ID / EX PIPELINE REGISTER
// ============================================================

module id_ex_reg (
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] rs1_data_in,
    input  logic [31:0] immediate_in,

    input  logic [4:0]  rd_in,

    input  logic        reg_write_in,
    input  logic        alu_src_in,
    input  logic [3:0]  alu_control_in,

    output logic [31:0] rs1_data_out,
    output logic [31:0] immediate_out,

    output logic [4:0]  rd_out,

    output logic        reg_write_out,
    output logic        alu_src_out,
    output logic [3:0]  alu_control_out
);

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            rs1_data_out    <= 32'd0;
            immediate_out   <= 32'd0;

            rd_out          <= 5'd0;

            reg_write_out   <= 1'b0;
            alu_src_out     <= 1'b0;
            alu_control_out <= 4'b0000;

        end
        else begin

            rs1_data_out    <= rs1_data_in;
            immediate_out   <= immediate_in;

            rd_out          <= rd_in;

            reg_write_out   <= reg_write_in;
            alu_src_out     <= alu_src_in;
            alu_control_out <= alu_control_in;

        end

    end

endmodule


// ============================================================
// 5. EX STAGE
// ============================================================

module ex_stage (
    input  logic [31:0] rs1_data,
    input  logic [31:0] immediate,

    input  logic        alu_src,
    input  logic [3:0]  alu_control,

    output logic [31:0] alu_result
);

    logic [31:0] alu_b;


    // --------------------------------------------------------
    // ALU input B MUX
    // --------------------------------------------------------

    always_comb begin

        if (alu_src)
            alu_b = immediate;
        else
            alu_b = 32'd0;

    end


    // --------------------------------------------------------
    // ALU
    // --------------------------------------------------------

    always_comb begin

        case (alu_control)

            4'b0000:
                alu_result = rs1_data + alu_b;   // ADDI

            4'b0010:
                alu_result = rs1_data & alu_b;   // ANDI

            4'b0011:
                alu_result = rs1_data | alu_b;   // ORI

            4'b0100:
                alu_result = rs1_data ^ alu_b;   // XORI

            default:
                alu_result = 32'd0;

        endcase

    end

endmodule


// ============================================================
// 6. EX / MEM PIPELINE REGISTER
// ============================================================

module ex_mem_reg (
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] alu_result_in,
    input  logic [4:0]  rd_in,

    input  logic        reg_write_in,

    output logic [31:0] alu_result_out,
    output logic [4:0]  rd_out,

    output logic        reg_write_out
);

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            alu_result_out <= 32'd0;
            rd_out         <= 5'd0;

            reg_write_out  <= 1'b0;

        end
        else begin

            alu_result_out <= alu_result_in;
            rd_out         <= rd_in;

            reg_write_out  <= reg_write_in;

        end

    end

endmodule


// ============================================================
// 7. MEM STAGE
// ============================================================

module mem_stage (
    input  logic [31:0] alu_result_in,

    output logic [31:0] result_out
);

    // I-type arithmetic does not access data memory.

    assign result_out = alu_result_in;

endmodule


// ============================================================
// 8. MEM / WB PIPELINE REGISTER
// ============================================================

module mem_wb_reg (
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] result_in,
    input  logic [4:0]  rd_in,

    input  logic        reg_write_in,

    output logic [31:0] result_out,
    output logic [4:0]  rd_out,

    output logic        reg_write_out
);

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            result_out    <= 32'd0;
            rd_out        <= 5'd0;

            reg_write_out <= 1'b0;

        end
        else begin

            result_out    <= result_in;
            rd_out        <= rd_in;

            reg_write_out <= reg_write_in;

        end

    end

endmodule


// ============================================================
// 9. WRITE BACK
// ============================================================

module wb_stage (
    input  logic        clk,

    input  logic        reg_write,
    input  logic [4:0]  rd,
    input  logic [31:0] write_data,

    output logic [31:0] wb_data
);

    assign wb_data = write_data;

endmodule


// ============================================================
// 10. TOP MODULE
// ============================================================

module rv32_i_type_pipeline (
    input logic clk,
    input logic rst
);

    // --------------------------------------------------------
    // IF
    // --------------------------------------------------------

    logic [31:0] pc_if;
    logic [31:0] instr_if;


    // --------------------------------------------------------
    // IF / ID
    // --------------------------------------------------------

    logic [31:0] pc_id;
    logic [31:0] instr_id;


    // --------------------------------------------------------
    // ID
    // --------------------------------------------------------

    logic [4:0]  rs1_id;
    logic [4:0]  rd_id;

    logic [2:0]  funct3_id;

    logic [31:0] immediate_id;
    logic [31:0] rs1_data_id;

    logic        reg_write_id;
    logic        alu_src_id;

    logic [3:0]  alu_control_id;


    // --------------------------------------------------------
    // ID / EX
    // --------------------------------------------------------

    logic [31:0] rs1_data_ex;
    logic [31:0] immediate_ex;

    logic [4:0]  rd_ex;

    logic        reg_write_ex;
    logic        alu_src_ex;

    logic [3:0]  alu_control_ex;


    // --------------------------------------------------------
    // EX
    // --------------------------------------------------------

    logic [31:0] alu_result_ex;


    // --------------------------------------------------------
    // EX / MEM
    // --------------------------------------------------------

    logic [31:0] alu_result_mem;
    logic [4:0]  rd_mem;

    logic        reg_write_mem;


    // --------------------------------------------------------
    // MEM
    // --------------------------------------------------------

    logic [31:0] mem_result;


    // --------------------------------------------------------
    // MEM / WB
    // --------------------------------------------------------

    logic [31:0] result_wb;
    logic [4:0]  rd_wb;

    logic        reg_write_wb;


    // ========================================================
    // IF
    // ========================================================

    if_stage IF (
        .clk         (clk),
        .rst         (rst),

        .pc          (pc_if),
        .instruction (instr_if)
    );


    // ========================================================
    // IF → ID
    // ========================================================

    if_id_reg IF_ID (
        .clk       (clk),
        .rst       (rst),

        .pc_in     (pc_if),
        .instr_in  (instr_if),

        .pc_out    (pc_id),
        .instr_out (instr_id)
    );


    // ========================================================
    // ID
    // ========================================================

    id_stage ID (
        .instr        (instr_id),

        .rs1          (rs1_id),
        .rd           (rd_id),

        .funct3       (funct3_id),

        .immediate    (immediate_id),

        .reg_write    (reg_write_id),
        .alu_src      (alu_src_id),
        .alu_control  (alu_control_id),

        .rs1_data     (rs1_data_id)
    );


    // ========================================================
    // ID → EX
    // ========================================================

    id_ex_reg ID_EX (
        .clk             (clk),
        .rst             (rst),

        .rs1_data_in     (rs1_data_id),
        .immediate_in    (immediate_id),

        .rd_in           (rd_id),

        .reg_write_in    (reg_write_id),
        .alu_src_in      (alu_src_id),
        .alu_control_in  (alu_control_id),

        .rs1_data_out    (rs1_data_ex),
        .immediate_out   (immediate_ex),

        .rd_out          (rd_ex),

        .reg_write_out   (reg_write_ex),
        .alu_src_out     (alu_src_ex),
        .alu_control_out (alu_control_ex)
    );


    // ========================================================
    // EX
    // ========================================================

    ex_stage EX (
        .rs1_data     (rs1_data_ex),
        .immediate    (immediate_ex),

        .alu_src      (alu_src_ex),
        .alu_control  (alu_control_ex),

        .alu_result   (alu_result_ex)
    );


    // ========================================================
    // EX → MEM
    // ========================================================

    ex_mem_reg EX_MEM (
        .clk             (clk),
        .rst             (rst),

        .alu_result_in   (alu_result_ex),
        .rd_in           (rd_ex),

        .reg_write_in    (reg_write_ex),

        .alu_result_out  (alu_result_mem),
        .rd_out          (rd_mem),

        .reg_write_out   (reg_write_mem)
    );


    // ========================================================
    // MEM
    // ========================================================

    mem_stage MEM (
        .alu_result_in (alu_result_mem),
        .result_out    (mem_result)
    );


    // ========================================================
    // MEM → WB
    // ========================================================

    mem_wb_reg MEM_WB (
        .clk             (clk),
        .rst             (rst),

        .result_in       (mem_result),
        .rd_in           (rd_mem),

        .reg_write_in    (reg_write_mem),

        .result_out      (result_wb),
        .rd_out          (rd_wb),

        .reg_write_out   (reg_write_wb)
    );


    // ========================================================
    // WB
    // ========================================================

    wb_stage WB (
        .clk        (clk),

        .reg_write  (reg_write_wb),
        .rd         (rd_wb),
        .write_data (result_wb),

        .wb_data    (result_wb)
    );

endmodule
