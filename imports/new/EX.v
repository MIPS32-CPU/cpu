`include<defines.v>
module EX(
    input wire clk,
    input wire rst,
    input wire [4:0] ALUop_i,
    input wire [31:0] oprand1_i,
    input wire [31:0] oprand2_i,
    input wire [4:0] writeAddr_i,
    input wire writeEnable_i,
    input wire [1:0] writeHILO_i,
    input wire signed_i,
    input wire [63:0] result_div_i,
    input wire success_i,
    input wire [31:0] inst_i,
    input wire [31:0] pc_i,
    input wire in_delay_slot_i,
    input wire [31:0] exceptionType_i,
    input wire write_CP0_i,
    input wire [4:0] write_CP0_addr_i,
    
    output reg [4:0] writeAddr_o,
    output reg writeEnable_o,
    output reg [1:0] writeHILO_o,
    output reg [31:0] HI_data_o,
    output reg [31:0] LO_data_o,
    
    output reg signed_o,
    output reg [31:0] dividend_o,
    output reg [31:0] divider_o,
    output reg start_o,
    
    output reg pauseRequest,
    
    output reg [31:0] storeData_o,
    output reg [3:0] ramOp_o,
    output reg in_delay_slot_o,
    output wire [31:0] exceptionType_o,
    output reg write_CP0_o,
    output reg [4:0] write_CP0_addr_o,
    output reg [31:0] pc_o
);
    reg [32:0] temp;
    wire ovassert;
    assign exceptionType_o = {exceptionType_i[31:12], ovassert, exceptionType_i[10:8], 8'b0};
	assign ovassert = (ALUop_i == `ALU_ADD) && (signed_i == 1'b1) && (oprand1_i[31] ^ LO_data_o[31]) && (oprand2_i[31] ^ LO_data_o[31]) || 
					  (ALUop_i == `ALU_SUB) && (signed_i == 1'b1) && (oprand1_i[31] ^ LO_data_o[31]) && (oprand1_i[31] ^ oprand2_i[31]); 

    always @ (*) begin
        temp <= {1'b0, oprand1_i} - {1'b0, oprand2_i};
        if(rst == 1'b1) begin
            writeAddr_o <= 5'b0;
            writeEnable_o <= 1'b0;
            writeHILO_o <= 2'b00;
            HI_data_o <= 32'b0;
            LO_data_o <= 32'b0;
            signed_o <= 1'b0;
            dividend_o <= 32'b0;
            divider_o <= 32'b0;
            start_o <= 32'b0;
            storeData_o <= 32'b0;
            pc_o <= 32'b0;
            ramOp_o <= `MEM_NOP;
            in_delay_slot_o <= 1'b0;
            //ovassert <= 1'b0;
            write_CP0_o <= 1'b0;
            write_CP0_addr_o <= 5'b0;
            pauseRequest <= 1'b0;
            
            
        end else begin
        	//assgin the default values
			writeAddr_o <= writeAddr_i;
			writeEnable_o <= writeEnable_i;
			writeHILO_o <= writeHILO_i;
			pc_o <= pc_i;
			HI_data_o <= 32'b0;
			LO_data_o <= 32'b0;
			signed_o <= 1'b0;
			dividend_o <= 32'b0;
			divider_o <= 32'b0;
			start_o <= 32'b0;
            storeData_o <= 32'b0;
			ramOp_o <= `MEM_NOP;
			pauseRequest <= 1'b0;
			in_delay_slot_o <= in_delay_slot_i;
			write_CP0_o <= write_CP0_i;
			write_CP0_addr_o <= write_CP0_addr_i;
			
            case (ALUop_i)
				`ALU_MOV: begin
					if(writeHILO_i == 2'b10) begin
						HI_data_o <= oprand1_i;
					end else if(writeHILO_i == 2'b01) begin
						LO_data_o <= oprand1_i;
					end else begin
						LO_data_o <= oprand1_i;
					end
				end

				`ALU_ADD: begin
					{HI_data_o, LO_data_o} <= {oprand1_i[31], oprand1_i} + {oprand2_i[31], oprand2_i};
				end

				`ALU_SUB: begin
					{HI_data_o, LO_data_o} <= {oprand1_i[31], oprand1_i} - {oprand2_i[31], oprand2_i};
				end

				`ALU_AND: begin
					{HI_data_o, LO_data_o} <= oprand1_i & oprand2_i;
				end

                `ALU_OR: begin
					{HI_data_o, LO_data_o} <= oprand1_i | oprand2_i;
			 	end
			 	
				`ALU_XOR: begin
					{HI_data_o, LO_data_o} <= oprand1_i ^ oprand2_i;
			 	end

				`ALU_NOR: begin
					{HI_data_o, LO_data_o} <= ~(oprand1_i | oprand2_i);
			 	end
                
                `ALU_SLL: begin
					{HI_data_o, LO_data_o} <= oprand1_i << oprand2_i;
				end

				`ALU_SRL: begin
					{HI_data_o, LO_data_o} <= oprand1_i >> oprand2_i;
				end

				`ALU_SRA: begin
					{HI_data_o, LO_data_o} <= ($signed(oprand1_i)) >>> oprand2_i;
				end

				`ALU_BAJ: begin
					{HI_data_o, LO_data_o} <= oprand2_i;
				end

				`ALU_SLT: begin
					if(signed_i == 1'b1) begin
						if(oprand1_i[31] == 1'b1 && oprand2_i[31] == 1'b0) begin
							LO_data_o <= 1'b1;
						end else if(oprand1_i[31] == 1'b0 && oprand2_i[31] == 1'b1) begin
							LO_data_o <= 1'b0;
						end else begin
							LO_data_o <= (oprand1_i < oprand2_i);
						end
					end else begin
						LO_data_o <= temp[32];
					end

				end

                `ALU_MULT: begin
					if(signed_i == 1'b1) begin
                		{HI_data_o, LO_data_o} <= ($signed(oprand1_i)) * ($signed(oprand2_i));
					end else begin
						{HI_data_o, LO_data_o} <= {1'b0, oprand1_i} * {1'b0, oprand2_i};
					end
                end
                
                `ALU_DIV: begin
                	if(success_i == 1'b0) begin
                		dividend_o <= oprand1_i;
                		divider_o <= oprand2_i;
                		signed_o <= signed_i;
                		start_o <= 1'b1;
                		pauseRequest <= 1'b1;
                	end else if(success_i == 1'b1) begin
                		start_o <= 1'b0;
                		pauseRequest <= 1'b0;
                		{HI_data_o, LO_data_o} <= result_div_i;
               		end 
               	end
               	
               	`ALU_SW: begin
               		storeData_o <= oprand2_i;
               		LO_data_o <= oprand1_i + {{16{inst_i[15]}}, inst_i[15:0]};
               		ramOp_o <= `MEM_SW;
               	end
               	
               	`ALU_SB: begin
               		storeData_o <= oprand2_i;
               		LO_data_o <= oprand1_i + {{16{inst_i[15]}}, inst_i[15:0]};
               		ramOp_o <= `MEM_SB;
               	end
               	
               	`ALU_SH: begin
					storeData_o <= oprand2_i;
					LO_data_o <= oprand1_i + {{16{inst_i[15]}}, inst_i[15:0]};
					ramOp_o <= `MEM_SH;
				end
               	               	
               	`ALU_LW: begin
               		LO_data_o <= oprand1_i + oprand2_i;
               		ramOp_o <= `MEM_LW;
               	end	
               	
				`ALU_LB: begin
					LO_data_o <= oprand1_i + oprand2_i;
					ramOp_o <= `MEM_LB;
				end	

				`ALU_LH: begin
					LO_data_o <= oprand1_i + oprand2_i;
					ramOp_o <= `MEM_LH;
				end	
				
				`ALU_LBU: begin
					LO_data_o <= oprand1_i + oprand2_i;
					ramOp_o <= `MEM_LBU;
				end	
				
				`ALU_LHU: begin
					LO_data_o <= oprand1_i + oprand2_i;
					ramOp_o <= `MEM_LHU;
				end
               	
                default: begin
                    pauseRequest <= 1'b0;
                end
            endcase
        end
    end
endmodule
                