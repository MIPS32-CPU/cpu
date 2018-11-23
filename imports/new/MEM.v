`include<defines.v>
module MEM(
    input wire clk,
    input wire rst,
    input wire [4:0] writeAddr_i,
    input wire writeEnable_i,
    input wire [1:0] writeHILO_i,
    input wire [31:0] HI_data_i,
    input wire [31:0] LO_data_i,
    input wire write_CP0_i,
    input wire [4:0] write_CP0_addr_i,
    
    input wire [31:0] storeData_i,
    input wire [3:0] ramOp_i,
    input wire success_i,
    input wire [31:0] load_data_i,
    input wire in_delay_slot_i,
    input wire [31:0] exceptionType_i,
    input wire [31:0] pc_i,
    
    input wire [31:0] CP0_status_i,
	input wire [31:0] CP0_cause_i,
	input wire [31:0] CP0_epc_i,
	input wire [31:0] CP0_ebase_i,
	
	input wire WB_write_CP0_i,
	input wire [4:0] WB_write_CP0_addr_i,
	input wire [31:0] WB_write_CP0_data_i,

    output reg [4:0] writeAddr_o,
    output reg writeEnable_o,
    output reg [1:0] writeHILO_o,
    output reg [31:0] HI_data_o,
    output reg [31:0] LO_data_o,
    
    output reg [3:0] ramOp_o,
    output reg [31:0] ramAddr_o,
 	output reg [31:0] storeData_o,
 	output reg write_CP0_o,
 	output reg [4:0] write_CP0_addr_o,
 	output reg [31:0] exceptionType_o,
 	output wire [31:0] CP0_epc_o,
	output wire in_delay_slot_o,
	output wire [31:0] pc_o,
	output wire [31:0] CP0_ebase_o,
    
    output reg pauseRequest
);
	wire addressError;
	reg [31:0] epc,status,cause,ebase;
	
	assign in_delay_slot_o = in_delay_slot_i;
	assign pc_o = pc_i;
	
	assign CP0_ebase_o = ebase;
	assign CP0_epc_o = epc;
	assign addressError = (ramOp_i == `MEM_LW) && (LO_data_i[1:0] != 2'b0) ||
						  (ramOp_i == `MEM_LH) && (LO_data_i[0] != 1'b0) ||
						  (ramOp_i == `MEM_LHU) && (LO_data_i[0] != 1'b0) ||
						  (ramOp_i == `MEM_SW) && (LO_data_i[1:0] != 2'b0) ||
						  (ramOp_i == `MEM_SH) && (LO_data_i[0] != 1'b0);
	
	always @(*) begin
		if(rst == 1'b1) begin
			epc <= 32'b0;
			status <= 32'b0;
			cause <= 32'b0;
			ebase <= 32'b0;
		end else if(WB_write_CP0_i == 1'b1) begin
			status <= CP0_status_i;
			epc <= CP0_epc_i;
			ebase <= CP0_ebase_i;
			cause <= CP0_cause_i;
			
			case(WB_write_CP0_addr_i) 
				`STATUS: begin
					status <= WB_write_CP0_data_i;
				end 
				
				`EPC: begin
					epc <= WB_write_CP0_data_i;
				end
				
				`EBASE: begin
					ebase <= WB_write_CP0_data_i;
				end
				
				`CAUSE: begin
					cause <= {CP0_cause_i[31:24], WB_write_CP0_data_i[23:22], CP0_cause_i[21:10], WB_write_CP0_data_i[9:8], CP0_cause_i[7:0]};
				end
			endcase
		end else begin
			status <= CP0_status_i;
			epc <= CP0_epc_i;
			ebase <= CP0_ebase_i;
			cause <= CP0_cause_i;
		end
	end
	
	always @(*) begin
		if(rst == 1'b1) begin
			exceptionType_o <= 32'b0;
		end else begin
			/*if((cause[15:8] & cause[15:8] != 8'b0) 
			&& (status[1] == 1'b0) 
			&& (status[0] == 1'b1)) begin
				exceptionType_o <= 32'h00000001;
			end else*/ 
			if(addressError == 1'b1) begin
				if(ramOp_i == `MEM_LW ||  ramOp_i == `MEM_LH ||
				   ramOp_i == `MEM_LHU) begin
					exceptionType_o <= 32'h00000004;
				end else if(ramOp_i == `MEM_SW || ramOp_i == `MEM_SH) begin
					exceptionType_o <= 32'h00000005;
				end else begin
					exceptionType_o <= 32'b0;
				end
			end else if(exceptionType_i[8] == 1'b1) begin
				exceptionType_o <= 32'h00000008;
			end else if(exceptionType_i[10] == 1'b1) begin
				exceptionType_o <= 32'h00000009;
			end else if(exceptionType_i[9] == 1'b1) begin
				exceptionType_o <= 32'h0000000a;
			end else if(exceptionType_i[11] == 1'b1) begin
				exceptionType_o <= 32'h0000000c;
			end else if(exceptionType_i[12] == 1'b1) begin
				exceptionType_o <= 32'h0000000e;
			end else if(exceptionType_i[31] == 1'b1) begin
				exceptionType_o <= 32'h4;
			end else begin
				exceptionType_o <= 32'b0;
			end
		end
	end
	
	always @(*) begin
		if(rst == 1'b1) begin
			ramOp_o <= `MEM_NOP;
		end else if(exceptionType_o == 32'b0) begin
			ramOp_o <= ramOp_i;
		end else begin
			ramOp_o <= `MEM_NOP;
		end
	end
	    
    always @ (*) begin
        if (rst == 1'b1) begin 
            HI_data_o <= 32'b0;
            LO_data_o <= 32'b0;
            writeEnable_o <= 1'b0;
            writeAddr_o <= 5'b0;
            writeHILO_o <= 2'b00;
            //ramOp_o <= `MEM_NOP;
            ramAddr_o <= 32'b0;
            storeData_o <= 32'b0;
            pauseRequest <= 1'b0;
            write_CP0_o <= 1'b0;
            write_CP0_addr_o <= 5'b0;
            
        end else begin
            HI_data_o <= HI_data_i;
            LO_data_o <= LO_data_i;
            writeEnable_o <= writeEnable_i;
            writeAddr_o <= writeAddr_i;
            writeHILO_o <= writeHILO_i;
            //ramOp_o <= ramOp_i;
            ramAddr_o <= LO_data_i;
            storeData_o <= storeData_i;
            write_CP0_o <= write_CP0_i;
            write_CP0_addr_o <= write_CP0_addr_i;
            
            
            if(ramOp_i == `MEM_NOP) begin
            	pauseRequest <= 1'b0;
            end else if(success_i == 1'b0) begin
            	pauseRequest <= 1'b1;
            end	else begin
            	pauseRequest <= 1'b0;
            	LO_data_o <= load_data_i;
            end
        end
    end
endmodule