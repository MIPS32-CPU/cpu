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
    input wire [31:0] load_data_i,
    input wire in_delay_slot_i,
    input wire [31:0] exceptionType_i,
    input wire [31:0] pc_i,
    
    
    input wire [31:0] CP0_status_i,
	input wire [31:0] CP0_cause_i,
	input wire [31:0] CP0_epc_i,
	input wire [31:0] CP0_ebase_i,
	input wire [31:0] CP0_index_i,
	input wire [31:0] CP0_random_i,
	input wire [31:0] CP0_entrylo0_i,
	input wire [31:0] CP0_entrylo1_i,
	input wire [31:0] CP0_entryhi_i,
	
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
	output wire [31:0] CP0_index_o,
	output wire [31:0] CP0_random_o,
	output wire [31:0] CP0_entrylo0_o,
	output wire [31:0] CP0_entrylo1_o,
	output wire [31:0] CP0_entryhi_o,
	output reg tlbwi, tlbwr
);
	wire addressError;
	reg [31:0] epc, status, cause, ebase, index, entrylo0, entrylo1, entryhi;
	
	assign in_delay_slot_o = in_delay_slot_i;
	assign pc_o = pc_i;
	
	assign CP0_ebase_o = ebase;
	assign CP0_epc_o = epc;
	assign CP0_index_o = index;
	assign CP0_random_o = CP0_random_i;
	assign CP0_entrylo0_o = entrylo0;
	assign CP0_entrylo1_o = entrylo1;
	assign CP0_entryhi_o = entryhi;
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
			index <= 32'b0;
			entrylo0 <= 32'b0;
			entrylo1 <= 32'b0;
			entryhi <= 32'b0;
		end else if(WB_write_CP0_i == 1'b1) begin
			status <= CP0_status_i;
			epc <= CP0_epc_i;
			ebase <= CP0_ebase_i;
			cause <= CP0_cause_i;
			index <= CP0_index_i;
			entrylo0 <= CP0_entrylo0_i;
			entrylo1 <= CP0_entrylo1_i;
			entryhi <= CP0_entryhi_i;
			
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
				
				`INDEX: begin
					index <= {28'b0, WB_write_CP0_data_i[3:0]};
				end
				
				`ENTRYLO0: begin
					entrylo0 <= {2'b0, WB_write_CP0_data_i[29:0]};
				end 
				
				`ENTRYLO1: begin
					entrylo1 <= {2'b0, WB_write_CP0_data_i[29:0]};
				end
				
				`ENTRYHI: begin
					entryhi <= {WB_write_CP0_data_i[31:13], 5'b0, WB_write_CP0_data_i[7:0]};
				end
				
				default:begin
				end
			endcase
		end else begin
			status <= CP0_status_i;
			epc <= CP0_epc_i;
			ebase <= CP0_ebase_i;
			cause <= CP0_cause_i;
			index <= CP0_index_i;
			entrylo0 <= CP0_entrylo0_i;
			entrylo1 <= CP0_entrylo1_i;
			entryhi <= CP0_entryhi_i;
		end
	end
	
	always @(*) begin
		if(rst == 1'b1) begin
			exceptionType_o <= 32'b0;
		end else begin
			if((status[12] & cause[12] == 1'b1) 
			&& (status[1] == 1'b0) 
			&& (status[0] == 1'b1)) begin
				exceptionType_o <= 32'h00000001;
			end else if((status[15] & cause[15] == 1'b1) 
				&& (status[1] == 1'b0) 
				&& (status[0] == 1'b1)) begin
					exceptionType_o <= 32'h10;
			end else if((status[14] & cause[14] == 1'b1) 
				&& (status[1] == 1'b0) 
				&& (status[0] == 1'b1)) begin
					exceptionType_o <= 32'h11;
			end else if((status[13] & cause[13] == 1'b1) 
				&& (status[1] == 1'b0) 
				&& (status[0] == 1'b1)) begin
					exceptionType_o <= 32'h12;	
			end else if((status[11] & cause[11] == 1'b1) 
				&& (status[1] == 1'b0) 
				&& (status[0] == 1'b1)) begin
					exceptionType_o <= 32'h13;	
			end else if(addressError == 1'b1) begin
				if(ramOp_i == `MEM_LW ||  ramOp_i == `MEM_LH ||
				   ramOp_i == `MEM_LHU) begin
					exceptionType_o <= 32'h4;
				end else if(ramOp_i == `MEM_SW || ramOp_i == `MEM_SH) begin
					exceptionType_o <= 32'h5;
				end else begin
					exceptionType_o <= 32'b0;
				end
			end else if(exceptionType_i[8] == 1'b1) begin
				exceptionType_o <= 32'h8;
			end else if(exceptionType_i[10] == 1'b1) begin
				exceptionType_o <= 32'h9;
			end else if(exceptionType_i[9] == 1'b1) begin
				exceptionType_o <= 32'ha;
			end else if(exceptionType_i[11] == 1'b1) begin
				exceptionType_o <= 32'hc;
			end else if(exceptionType_i[12] == 1'b1) begin
				exceptionType_o <= 32'he;
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
            ramAddr_o <= 32'b0;
            storeData_o <= 32'b0;
            write_CP0_o <= 1'b0;
            write_CP0_addr_o <= 5'b0;
            tlbwi <= 1'b0;
            tlbwr <= 1'b0;
            
        end else begin
            HI_data_o <= HI_data_i;
            LO_data_o <= LO_data_i;
            writeEnable_o <= writeEnable_i;
            writeAddr_o <= writeAddr_i;
            writeHILO_o <= writeHILO_i;
            ramAddr_o <= LO_data_i;
            storeData_o <= storeData_i;
            write_CP0_o <= write_CP0_i;
            write_CP0_addr_o <= write_CP0_addr_i;
            
            if(exceptionType_i[13] == 1'b1) begin
            	tlbwi <= 1'b1;
            	tlbwr <= 1'b0;
            end else if(exceptionType_i[14] == 1'b1) begin
            	tlbwr <= 1'b1;
            	tlbwi <= 1'b0;
            end else begin
            	tlbwr <= 1'b0;
                tlbwi <= 1'b0;
            end
            
            if(ramOp_o != `MEM_NOP) begin
            	LO_data_o <= load_data_i;
            end
        end
    end
endmodule