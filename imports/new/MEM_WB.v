module MEM_WB(
    input wire clk,
    input wire rst,
    input wire [4:0] writeAddr_i,
    input wire writeEnable_i,
    input wire [1:0] writeHILO_i,
    input wire [31:0] HI_data_i,
    input wire [31:0] LO_data_i,
    input wire [5:0] stall,
    input wire write_CP0_i,
    input wire [4:0] write_CP0_addr_i,
    input wire flush,
    
    output reg [4:0] writeAddr_o,
    output reg writeEnable_o,
    output reg [1:0] writeHILO_o,
    output reg [31:0] HI_data_o,
    output reg write_CP0_o,
    output reg [4:0] write_CP0_addr_o,
    output reg [31:0] LO_data_o
);

    always @ (posedge clk) begin
        if (rst == 1'b1) begin 
            HI_data_o <= 32'b0;
            LO_data_o <= 32'b0;
            writeEnable_o <= 1'b0;
            writeAddr_o <= 5'b0;
            writeHILO_o <= 2'b00;
            write_CP0_o <= 1'b0;
            write_CP0_addr_o <= 5'b0;
        end else if(flush == 1'b1) begin
        	HI_data_o <= 32'b0;
			LO_data_o <= 32'b0;
			writeEnable_o <= 1'b0;
			writeAddr_o <= 5'b0;
			writeHILO_o <= 2'b00;
			write_CP0_o <= 1'b0;
			write_CP0_addr_o <= 5'b0;
        end else if(stall[4] == 1'b1 && stall[5] == 1'b0) begin
        	HI_data_o <= 32'b0;
			LO_data_o <= 32'b0;
			writeEnable_o <= 1'b0;
			writeAddr_o <= 5'b0;
			writeHILO_o <= 2'b00;
			write_CP0_o <= 1'b0;
			write_CP0_addr_o <= 5'b0;
        end else if(stall[4] == 1'b0) begin
            HI_data_o <= HI_data_i;
            LO_data_o <= LO_data_i;
            writeEnable_o <= writeEnable_i;
            writeAddr_o <= writeAddr_i;
            writeHILO_o <= writeHILO_i;
            write_CP0_o <= write_CP0_i;
            write_CP0_addr_o <= write_CP0_addr_i;
        end
    end
endmodule