module EX_MEM(
    input wire clk,
    input wire rst,
    input wire [31:0] HI_data_i,
    input wire [31:0] LO_data_i,
    input wire [4:0] writeAddr_i,
    input wire writeEnable_i,
    input wire [1:0] writeHILO_i,
    input wire [5:0] stall,
    input wire [3:0] ramOp_i,
    input wire [31:0] storeData_i,
    input wire [31:0] pc_i,
    input wire in_delay_slot_i,
    input wire [31:0] exceptionType_i,
    input wire write_CP0_i,
    input wire [4:0] write_CP0_addr_i,
    input wire flush,
    
    output reg [4:0] writeAddr_o,
    output reg writeEnable_o,
    output reg [1:0] writeHILO_o,
    output reg [31:0] HI_data_o,
    output reg [31:0] LO_data_o,
    output reg [3:0] ramOp_o,
    output reg [31:0] storeData_o,
    output reg in_delay_slot_o,
    output reg [31:0] exceptionType_o,
    output reg write_CP0_o,
    output reg [4:0] write_CP0_addr_o,
    output reg [31:0] pc_o
);

    always @ (posedge clk) begin
        if (rst == 1'b1) begin 
            HI_data_o <= 32'b0;
            LO_data_o <= 32'b0;
            writeEnable_o <= 1'b0;
            writeAddr_o <= 5'b0;
            writeHILO_o <= 2'b00;
            ramOp_o <= `MEM_NOP;
            storeData_o <= 32'b0;
            in_delay_slot_o <= 1'b0;
            pc_o <= 32'b0;
            exceptionType_o <= 32'b0;
            write_CP0_o <= 1'b0;
            write_CP0_addr_o <= 5'b0;
        end else if(flush == 1'b1) begin
        	HI_data_o <= 32'b0;
			LO_data_o <= 32'b0;
			writeEnable_o <= 1'b0;
			writeAddr_o <= 5'b0;
			writeHILO_o <= 2'b00;
			ramOp_o <= `MEM_NOP;
			storeData_o <= 32'b0;
			in_delay_slot_o <= 1'b0;
			pc_o <= 32'b0;
			exceptionType_o <= 32'b0;
			write_CP0_o <= 1'b0;
			write_CP0_addr_o <= 5'b0;
        end else if(stall[3] == 1'b1 && stall[4] == 1'b0) begin
        	HI_data_o <= 32'b0;
			LO_data_o <= 32'b0;
			writeEnable_o <= 1'b0;
			writeAddr_o <= 5'b0;
			writeHILO_o <= 2'b00;
			ramOp_o <= `MEM_NOP;
			storeData_o <= 32'b0;
			in_delay_slot_o <= 1'b0;
			pc_o <= 32'b0;
			exceptionType_o <= 32'b0;
			write_CP0_o <= 1'b0;
			write_CP0_addr_o <= 5'b0;
			
        end else if(stall[3] == 1'b0) begin
            HI_data_o <= HI_data_i;
            LO_data_o <= LO_data_i;
            writeEnable_o <= writeEnable_i;
            writeAddr_o <= writeAddr_i;
            writeHILO_o <= writeHILO_i;
            ramOp_o <= ramOp_i;
            storeData_o <= storeData_i;
            in_delay_slot_o <= in_delay_slot_i;
            pc_o <= pc_i;
            exceptionType_o <= exceptionType_i;
            write_CP0_o <= write_CP0_i;
           	write_CP0_addr_o <= write_CP0_addr_i;
        end
    end
endmodule
    