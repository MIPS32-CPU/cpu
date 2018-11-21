module MemControl(
	input wire clk,
	input wire rst,
	input wire [31:0] storeData_i,
	input wire [3:0] memOp_i,
	input wire [31:0] virtualAddr_i,
	input wire [31:0] loadData_i,
	
	output reg [31:0] storeData_o,
	output reg [3:0] memOp_o,
	output reg [31:0] virtualAddr_o,
	output reg [31:0] loadData_o,
	output reg pauseRequest //pause the pipline
);

	always @(*) begin
		if(rst == 1'b1) begin
			storeData_o <= 32'b0;
			memOp_o <= 4'b0;
			virtualAddr_o <= 32'b0;
			loadData_o <= 32'b0;
			pauseRequest <= 1'b0;
		end else begin
			
		end
	end
endmodule