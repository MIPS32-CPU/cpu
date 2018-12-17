`include<defines.v>
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/12/17 11:24:03
// Design Name: 
// Module Name: flashcontrol
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module flashcontrol(
    input wire clk,
	input wire rst,
	input wire [2:0] ramOp_i,
	input wire [15:0] ramData_i,
	input wire [22:0] ramAddr_i,
	input wire [15:0] storeData_i,
	
	input wire [3:0] EX_ramOp_i,
    input wire [31:0] EX_ramAddr_i,
    input wire EX_tlbmiss_i,
	
	output reg [22:0] ramAddr_o,
	output reg [15:0] writeData_o,
	output reg flashEnable_o,
	output reg writeEnable_o,
	output reg busEnable_o,
	output reg readEnable_o,
	output reg [31:0] ramData_o,
	output reg pauseRequest_o
);
    wire load;
	wire base_read, ext_read;
	wire base, ext;
	wire addressError;
	assign addressError = (EX_ramOp_i == `MEM_LW) && (EX_ramAddr_i[1:0] != 2'b0) ||
						  (EX_ramOp_i == `MEM_LH) && (EX_ramAddr_i[0] != 1'b0) ||
						  (EX_ramOp_i == `MEM_LHU) && (EX_ramAddr_i[0] != 1'b0);
	assign load = (EX_ramOp_i != `MEM_NOP && addressError == 1'b0 && EX_tlbmiss_i == 1'b0 && EX_ramAddr_i[31:8] != 32'hBFD003F) ? 1'b1 : 1'b0;
	assign base = (EX_ramAddr_i < 32'h80400000) && (EX_ramAddr_i >= 32'h80000000);
	//assign base = 1'b0;
	assign ext = ~base;
	assign base_read = load && base; 
	assign ext_read = load && ext;

    reg [2:0] state, nstate, pstate;
    reg [31:0] loadData_reg;
    parameter IDLE = 4'd0,
                READ1 = 4'd1,
                READ2 = 4'd2,
                READ3 = 4'd3,
                READ3_EXT = 4'd4,
                READ4 = 4'd5;
                
    always @(posedge clk) begin
        if(rst == 1'b1) begin
            state <= IDLE;
            pstate <= IDLE;
            loadData_reg <= 32'b0;
        end else begin
            state <= nstate;
            pstate <= state;
            if(state == READ4) begin
                loadData_reg <= ramData_o;
            end
        end
    end
    
    always @(*) begin
            if(rst == 1'b1) begin
                ramAddr_o <= ramAddr_i;
                writeData_o <= 16'b0;
                flashEnable_o <= 1'b1;//1:disable 0:enable?
                writeEnable_o <= 1'b1;
                busEnable_o <= 1'b1;
                readEnable_o <= 1'b1;
                ramData_o <= 32'b0;
                pauseRequest_o <= 1'b0;
                nstate <= IDLE;
            end else begin
                case(state) 
                    IDLE: begin
                        ramAddr_o <= ramAddr_i;
                        writeData_o <= 16'b0;
                        flashEnable_o <= 1'b1;
                        writeEnable_o <= 1'b1;
                        busEnable_o <= 1'b1;
                        readEnable_o <= 1'b1;
                        pauseRequest_o <= 1'b0;
                        
                        if(pstate == READ4) begin
                            ramData_o <= loadData_reg;
                        end else begin
                            ramData_o <= 32'b0;
                        end
                        
                        if(base_read == 1'b1) begin
                            nstate <= READ1;
                        end else begin
                            nstate <= IDLE;
                        end
                    end
                    
                    
                    READ1: begin
                        ramAddr_o <= ramAddr_i;
                        writeData_o <= 16'h00FF;//change to read mode
                        flashEnable_o <= 1'b0;//flash enable
                        writeEnable_o <= 1'b0;//writeEnable reset
                        busEnable_o <= 1'b1;
                        readEnable_o <= 1'b1;
                        pauseRequest_o <= 1'b0;     
                        
                        nstate <= READ2;
                        
                    end
                    
                    READ2: begin
                        ramAddr_o <= ramAddr_i;
                        writeData_o <= 16'h00FF;//keep
                        flashEnable_o <= 1'b0;//flash enable
                        writeEnable_o <= 1'b1;//writeEnable set
                        busEnable_o <= 1'b1;
                        readEnable_o <= 1'b1;
                        pauseRequest_o <= 1'b0;     
                        
                        nstate <= READ3;
                        
                    end
                    
                    READ3: begin
                        ramAddr_o <= ramAddr_i;
                        writeData_o <= 16'bz;//prepare to read
                        flashEnable_o <= 1'b0;//flash enable
                        writeEnable_o <= 1'b1;
                        busEnable_o <= 1'b1;
                        readEnable_o <= 1'b0;//readEnable reset
                        pauseRequest_o <= 1'b1;//wait    
                        case(ramOp_i) 
                            `MEM_LB: begin
                                ramData_o <= {{16{writeData_o[15]}}, writeData_o[15:0]};
                            end
                            
                            `MEM_LBU: begin
                                ramData_o <= {16'b0, writeData_o[15:0]};
                            end
                                                    
                            `MEM_LH: begin
                                ramData_o <= {{16{writeData_o[15]}}, writeData_o[15:0]};
                            end
                            
                            `MEM_LHU: begin
                                 ramData_o <= {16'b0, writeData_o[15:0]};
                            end
                            
                            default: begin
                                 ramData_o <= {16'b0, writeData_o[15:0]};
                            end
                        endcase
                        nstate <= READ3_EXT;
                        
                    end
                    
                    READ3_EXT: begin
                        if(ext_read == 1'b1)begin
                            nstate <= READ4;
                        end else begin
                            nstate <= READ3_EXT;
                        end
                    end
                    
                    READ4: begin
                        ramAddr_o <= ramAddr_i;
                        flashEnable_o <= 1'b0;//flash enable
                        writeEnable_o <= 1'b1;
                        busEnable_o <= 1'b1;
                        readEnable_o <= 1'b1;//readEnable set
                        pauseRequest_o <= 1'b1;//wait    
                        
                        loadData_reg <= ramData_o;//save data
                        
                        nstate <= IDLE;
                    end
            endcase           
        end
    end
endmodule
