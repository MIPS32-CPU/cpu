module IF_ID(
    input wire clk,
    input wire rst,
    input wire [31:0] pc_i,
    input wire [31:0] inst_i,
    input wire [5:0] stall,
    input wire flush,
    input wire [31:0] exceptionType_i,
    
    output reg [31:0] pc_o,
    output reg [31:0] inst_o,
    output reg [31:0] exceptionType_o
);
	
	
    always @ (posedge clk) begin
        if(rst == 1'b1) begin
            pc_o <= 32'b0;
            inst_o <= 32'b0;
            exceptionType_o <= 32'b0;
        end else if(flush == 1'b1) begin
			pc_o <= 32'b0;
			inst_o <= 32'b0;
			exceptionType_o <= 32'b0;
        end else if(stall[2] == 1'b0 && stall[1] == 1'b1) begin
        	pc_o <= pc_i;
        	inst_o <= 32'b0;
        	exceptionType_o <= exceptionType_i;
        end else if(stall[1] == 1'b0) begin
            pc_o <= pc_i;
            inst_o <= inst_i;
            exceptionType_o <= exceptionType_i;
        end
    end
endmodule
   
    