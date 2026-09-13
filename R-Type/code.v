// ============================================================
// 5-STAGE RV32I IN-ORDER PIPELINE
// R-TYPE INSTRUCTIONS
//
// Pipeline:
// IF -> ID -> EX -> MEM -> WB
// ============================================================


// ============================================================
// 1. IF STAGE
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
    output logic [4:0]  rs2,
    output logic [4:0]  rd,

    output logic [2:0]  funct3,
    output logic [6:0]  funct7,

    output logic        reg_write,
    output logic [3:0]  alu_control,

    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);

    logic [31:0] regfile [0:31];

    // --------------------------------
    // Instruction fields
    // --------------------------------

    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign rd     = instr[11:7];

    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];


    // --------------------------------
    // Register file reads
    // --------------------------------

    assign rs1_data = (rs1 == 0) ? 32'd0 : regfile[rs1];
    assign rs2_data = (rs2 == 0) ? 32'd0 : regfile[rs2];


    // --------------------------------
    // R-type control
    // --------------------------------

    always_comb begin

        reg_write  = 1'b0;
        alu_control = 4'b0000;

        // R-type opcode = 0110011
        if (instr[6:0] == 7'b0110011) begin

            reg_write = 1'b1;

            case (funct3)

                3'b000: begin
                    if (funct7 == 7'b0000000)
                        alu_control = 4'b0000;   // ADD

                    else if (funct7 == 7'b0100000)
                        alu_control = 4'b0001;   // SUB
                end

                3'b111:
                    alu_control = 4'b0010;       // AND

                3'b110:
                    alu_control = 4'b0011;       // OR

                3'b100:
                    alu_control = 4'b0100;       // XOR

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
    input  logic [31:0] rs2_data_in,

    input  logic [4:0]  rd_in,
    input  logic [3:0]  alu_control_in,
    input  logic        reg_write_in,

    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,

    output logic [4:0]  rd_out,
    output logic [3:0]  alu_control_out,
    output logic        reg_write_out
);

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin
            rs1_data_out    <= 32'd0;
            rs2_data_out    <= 32'd0;
            rd_out          <= 5'd0;
            alu_control_out <= 4'd0;
            reg_write_out   <= 1'b0;
        end

        else begin
            rs1_data_out    <= rs1_data_in;
            rs2_data_out    <= rs2_data_in;
            rd_out          <= rd_in;
            alu_control_out <= alu_control_in;
            reg_write_out   <= reg_write_in;
        end

    end

endmodule


// ============================================================
// 5. EX STAGE
// ============================================================

module ex_stage (
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,

    input  logic [3:0]  alu_control,

    output logic [31:0] alu_result
);

    always_comb begin

        case (alu_control)

            4'b0000:
                alu_result = rs1_data + rs2_data;   // ADD

            4'b0001:
                alu_result = rs1_data - rs2_data;   // SUB

            4'b0010:
                alu_result = rs1_data & rs2_data;   // AND

            4'b0011:
                alu_result = rs1_data | rs2_data;   // OR

            4'b0100:
                alu_result = rs1_data ^ rs2_data;   // XOR

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

    // R-type does not access data memory.
    // Therefore the ALU result simply passes through.

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
// 9. WB STAGE
// ============================================================

module wb_stage (
    input logic        clk,

    input logic        reg_write,
    input logic [4:0]  rd,
    input logic [31:0] write_data,

    output logic [31:0] wb_data
);

    assign wb_data = write_data;

endmodule


// ============================================================
// 10. TOP MODULE
// ============================================================

module rv32_rtype_pipeline (
    input logic clk,
    input logic rst
);

    // --------------------------------------------------------
    // IF signals
    // --------------------------------------------------------

    logic [31:0] pc_if;
    logic [31:0] instr_if;


    // --------------------------------------------------------
    // IF/ID signals
    // --------------------------------------------------------

    logic [31:0] pc_id;
    logic [31:0] instr_id;


    // --------------------------------------------------------
    // ID signals
    // --------------------------------------------------------

    logic [4:0] rs1_id;
    logic [4:0] rs2_id;
    logic [4:0] rd_id;

    logic [2:0] funct3_id;
    logic [6:0] funct7_id;

    logic [31:0] rs1_data_id;
    logic [31:0] rs2_data_id;

    logic        reg_write_id;
    logic [3:0]  alu_control_id;


    // --------------------------------------------------------
    // ID/EX signals
    // --------------------------------------------------------

    logic [31:0] rs1_data_ex;
    logic [31:0] rs2_data_ex;

    logic [4:0] rd_ex;
    logic [3:0] alu_control_ex;

    logic reg_write_ex;


    // --------------------------------------------------------
    // EX signals
    // --------------------------------------------------------

    logic [31:0] alu_result_ex;


    // --------------------------------------------------------
    // EX/MEM signals
    // --------------------------------------------------------

    logic [31:0] alu_result_mem;
    logic [4:0]  rd_mem;
    logic        reg_write_mem;


    // --------------------------------------------------------
    // MEM signals
    // --------------------------------------------------------

    logic [31:0] mem_result;


    // --------------------------------------------------------
    // MEM/WB signals
    // --------------------------------------------------------

    logic [31:0] wb_result;
    logic [4:0]  rd_wb;
    logic        reg_write_wb;


    // ========================================================
    // MODULE CONNECTIONS
    // ========================================================


    // IF
    if_stage IF (
        .clk         (clk),
        .rst         (rst),
        .pc          (pc_if),
        .instruction (instr_if)
    );


    // IF → ID
    if_id_reg IF_ID (
        .clk      (clk),
        .rst      (rst),

        .pc_in    (pc_if),
        .instr_in (instr_if),

        .pc_out   (pc_id),
        .instr_out(instr_id)
    );


    // ID
    id_stage ID (
        .instr        (instr_id),

        .rs1          (rs1_id),
        .rs2          (rs2_id),
        .rd           (rd_id),

        .funct3       (funct3_id),
        .funct7       (funct7_id),

        .reg_write    (reg_write_id),
        .alu_control  (alu_control_id),

        .rs1_data     (rs1_data_id),
        .rs2_data     (rs2_data_id)
    );


    // ID → EX
    id_ex_reg ID_EX (
        .clk             (clk),
        .rst             (rst),

        .rs1_data_in     (rs1_data_id),
        .rs2_data_in     (rs2_data_id),

        .rd_in           (rd_id),
        .alu_control_in  (alu_control_id),
        .reg_write_in    (reg_write_id),

        .rs1_data_out    (rs1_data_ex),
        .rs2_data_out    (rs2_data_ex),

        .rd_out          (rd_ex),
        .alu_control_out (alu_control_ex),
        .reg_write_out   (reg_write_ex)
    );


    // EX
    ex_stage EX (
        .rs1_data    (rs1_data_ex),
        .rs2_data    (rs2_data_ex),

        .alu_control (alu_control_ex),

        .alu_result  (alu_result_ex)
    );


    // EX → MEM
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


    // MEM
    mem_stage MEM (
        .alu_result_in (alu_result_mem),
        .result_out    (mem_result)
    );


    // MEM → WB
    mem_wb_reg MEM_WB (
        .clk            (clk),
        .rst            (rst),

        .result_in      (mem_result),
        .rd_in          (rd_mem),
        .reg_write_in   (reg_write_mem),

        .result_out     (wb_result),
        .rd_out         (rd_wb),
        .reg_write_out  (reg_write_wb)
    );


    // WB
    wb_stage WB (
        .clk        (clk),
        .reg_write  (reg_write_wb),
        .rd         (rd_wb),
        .write_data (wb_result),
        .wb_data    (wb_result)
    );

endmodule
