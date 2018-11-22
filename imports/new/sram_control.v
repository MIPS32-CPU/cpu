`include<defines.v>

module sram_control (
	input wire clk50,
	input wire rst,
	input wire [19:0] ramAddr_i,
	input wire [31:0] storeData_i,
	input wire [3:0] ramOp_i,
	
	output reg [31:0] loadData_o,
	output reg WE_n_o,
	output reg OE_n_o,
	output reg CE_n_o,
	output reg [3:0] be_n_o,
	output reg [19:0] ramAddr_o,
	output reg success_o,
	
	inout wire [31:0] data_io
);	
	reg [31:0] data_io_reg;
	reg [2:0] state, nstate;
	reg write;
	assign data_io = write  ? data_io_reg : 32'bz;
	
	parameter IDLE = 3'b00,
			  WRITE = 3'b10,
			  READ = 3'b11,
			  WRITEEND = 3'b100,
			  WRITE2 = 3'b101,
			  WRITE3 = 3'b110;
			  
	always @(posedge clk50 or posedge rst) begin
		if(rst == 1'b1) begin
			state <= IDLE;
		end else begin
			state <= nstate;
		end
	end
		
    always @(*) begin
        data_io_reg <= storeData_i;
    	if(rst == 1'b1 || ramOp_i == 4'b0) begin
    	    write <=  1'b0;
			WE_n_o <= 1'b1;
			CE_n_o <= 1'b1;
			OE_n_o <= 1'b1;
			be_n_o <= 4'b1111;
			ramAddr_o <= 20'b0;
			loadData_o <= 32'b0;
			success_o <= 1'b0;
			nstate <= IDLE;
		end else begin
			ramAddr_o <= ramAddr_i;
			OE_n_o <= 1'b0;
            CE_n_o <= 1'b0;
			case(state) 
				IDLE: begin
				    write  <= 1'b0;
					WE_n_o <= 1'b1;
					be_n_o <= 4'b0000;
					loadData_o <= 32'b0;
					success_o <= 1'b0;
					
					case(ramOp_i) 
						`MEM_LW: begin
							nstate <= READ;
						end
						`MEM_SW: begin
							nstate <= WRITE;
						end
						
						`MEM_SB: begin
							nstate <= WRITE;
						end
						
						`MEM_SH: begin
							nstate <= WRITE;
						end
						
						`MEM_LB: begin
							nstate <= READ;
						end
						
						`MEM_LH: begin
							nstate <= READ;
						end
						
						`MEM_LBU: begin
							nstate <= READ;
						end
						
						`MEM_LHU: begin
							nstate <= READ;
						end

						default: begin
							nstate <= IDLE;
						end
					endcase
				end
				
				
				READ: begin
                                
                    case(ramOp_i) 
                        `MEM_LB: begin
                            loadData_o <= {{24{data_io[31]}}, data_io[31:24]};
                        end
                        
                        `MEM_LBU: begin
                            loadData_o <= {24'b0, data_io[31:24]};
                        end
                                                
                        `MEM_LH: begin
                            loadData_o <= {{16{data_io[31]}}, data_io[31:16]};
                        end
                        
                        `MEM_LHU: begin
                            loadData_o <= {16'b0, data_io[31:16]};
                        end
                        
                        default: begin
                            loadData_o <= data_io;
                        end
                    endcase
                
                    write <= 1'b0;
                    WE_n_o <= 1'b1;
                    be_n_o <= 4'b0000;
                    success_o <= 1'b1;
                    nstate <= IDLE;
                
                end
				
				
				WRITE: begin
				    WE_n_o <= 1'b0;
				    case(ramOp_i)
                        `MEM_SW: begin
                            be_n_o <= 4'b0;
                        end

                        `MEM_SH: begin
                            be_n_o <= 4'b0011;
                        end

                        `MEM_SB: begin
                            be_n_o <= 4'b0111;
                        end
                        
                        default: begin
                            be_n_o <=4'b0;
                        end
                    endcase
                    
                    write <= 1'b1;
                    loadData_o <= 32'b0;
                    success_o <= 1'b0;
				    nstate <= WRITE2;
				end
				
				WRITE2: begin
				    write <= 1'b1;
				    WE_n_o <= 1'b1;
				    be_n_o <= 4'b1111;
				    loadData_o <= 32'b0;
                    success_o <= 1'b0;
				    nstate <= WRITEEND;
				end
				
				WRITEEND: begin
					success_o <= 1'b1;
					WE_n_o <= 1'b1;
                    be_n_o <= 4'b0000;
                    loadData_o <= 32'b0;
					write <= 1'b0;
					nstate <= IDLE;
				end
				
				default: begin
				    write  <= 1'b0;
				    WE_n_o <= 1'b1;
                    be_n_o <= 4'b0000;
                    loadData_o <= 32'b0;
                    success_o <= 1'b0;
                    nstate <= IDLE;
				end
			
			endcase
		end			
    end
	 
endmodule	
