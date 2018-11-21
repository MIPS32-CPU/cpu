`include<defines.v>

module MMU(
	input wire clk,
	input wire rst,
	input wire [31:0] data_ramAddr_i,
	input wire [31:0] inst_ramAddr_i,
	input wire [3:0] ramOp_i,
	input wire [31:0] storeData_i,
	input wire [31:0] load_data_i,
	input wire [31:0] load_inst_i,
	
	output reg [3:0] ramOp_o,
	output reg [31:0] load_data_o,
	output reg [31:0] load_inst_o,
	output reg [31:0] storeData_o,
	output reg [19:0] instAddr_o,
	output reg [19:0] dataAddr_o
);
	always @(*) begin 
		if(rst == 1'b1) begin
			ramOp_o <= `MEM_NOP;
			load_data_o <= 32'b0;
			load_inst_o <= 32'b0;
			storeData_o <= 32'b0;
			instAddr_o <= 20'b0;
			dataAddr_o <= 20'b0;
		end else begin
			ramOp_o <= ramOp_i;
			load_data_o <= load_data_i;
			load_inst_o <= load_inst_i;
			
			storeData_o <= storeData_i;
			instAddr_o <= inst_ramAddr_i[21:2];
			dataAddr_o <= data_ramAddr_i[21:2];
		end
	end
endmodule