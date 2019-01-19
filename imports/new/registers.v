module registers(
    input wire clk,
    input wire rst,
    input wire readEnable1_i,
    input wire readEnable2_i,
    input wire[4:0] readAddr1_i,
    input wire[4:0] readAddr2_i,
    input wire writeEnable_i,
    input wire[4:0] writeAddr_i,
    input wire[31:0] writeData_i,
    
    output reg[31:0] readData1_o,
    output reg[31:0] readData2_o,
    output wire[7:0] led_o,
    output wire[3:0] dpy0_o,
    output wire[3:0] dpy1_o
);
    reg[31:0] register[31:0];
    
    assign led_o = register[4][7:0];
    assign dpy0_o = register[19][3:0];
    assign dpy1_o = register[19][7:4];
    
    //write Registers
    always @ (posedge clk) begin
        if(rst == 1'b0) begin
            if(writeEnable_i == 1'b1 && writeAddr_i != 5'b0) begin
                register[writeAddr_i] <= writeData_i;
            end
        end
    end
    
    //read Register_1
    always @ (*) begin
        if(rst == 1'b1) begin
            readData1_o <= 32'b0;
        end else if(readEnable1_i == 1'b0) begin
            readData1_o <= 32'b0;
        end else if(readAddr1_i == 5'b0) begin
            readData1_o <= 32'b0;
        end else if(readAddr1_i == writeAddr_i && writeEnable_i == 1'b1) begin
        	readData1_o <= writeData_i;
        end else begin
            readData1_o <= register[readAddr1_i];
        end
    end
    
    //read Register_2
    always @ (*) begin
		if(rst == 1'b1) begin
			readData2_o <= 32'b0;
		end else if(readEnable2_i == 1'b0) begin
			readData2_o <= 32'b0;
		end else if(readAddr2_i == 5'b0) begin
			readData2_o <= 32'b0;
		end else if(readAddr2_i == writeAddr_i && writeEnable_i == 1'b1) begin
			readData2_o <= writeData_i;
		end else begin
			readData2_o <= register[readAddr2_i];
		end
     end
     
endmodule            
  