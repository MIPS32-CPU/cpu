module vga_control(
    input wire clk,
    input wire rst,
    
    // VGA
    output wire[2:0] video_red,
    output wire[2:0] video_green,
    output wire[1:0] video_blue,
    output wire video_hsync,
    output wire video_vsync,
    output wire video_clk,
    output wire video_de
    );
    
    //图像输出演示，分辨率800x600@75Hz，像素时钟为50MHz
    wire [11:0] hdata;
    wire [11:0] vdata;
    reg[2:0] red;
    reg[2:0] green;
    reg[1:0] blue;
    
    assign video_red = red;
    assign video_green = green;
    assign video_blue = blue;
    // assign video_red = hdata < 266 ? 3'b111 : 0; //红色竖条
    // assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //绿色竖条
    // assign video_blue = hdata >= 532 ? 2'b11 : 0; //蓝色竖条
    assign video_clk = clk;
    
    vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
      .clk(clk), 
      .hdata(hdata), //横坐标
      .vdata(vdata), //纵坐标
      .hsync(video_hsync),
      .vsync(video_vsync),
      .data_enable(video_de)
    );

    reg ena;
    reg[0:0] wea;
    reg[18:0] addra;
    reg[7:0] dina;
    wire[7:0] douta;
    
    blk_mem_gen_0 your_instance_name (
      .clka(clk),    // input wire clka
      .ena(ena),      // input wire ena
      .wea(wea),      // input wire [0 : 0] wea
      .addra(addra),  // input wire [18 : 0] addra
      .dina(dina),    // input wire [7 : 0] dina
      .douta(douta)  // output wire [7 : 0] douta
    );
    
    always @ (posedge clk) begin
        if (rst == 1'b1) begin
            red = 3'b0;
            green = 3'b0;
            blue = 2'b0;
        end
        else begin
            red = douta[7:5];
            green = douta[4:2];
            blue = douta[1:0];
        end
    end
    
    always @ (posedge clk) begin
        if (rst == 1'b1) begin
            ena <= 1'b0;
            wea <= 1'b0;
            dina <= 8'b0;
        end
        else begin
            ena <= 1'b1;
            wea <= 1'b0;
            dina <= 8'b0;
        end
    end
    
    wire[11:0] hh;
    wire[11:0] vv;
    assign hh = (hdata == 1039) ? 0 : hdata + 1;
    assign vv = (hdata == 1039) ? vdata + 1: vdata;
    
    reg good;
    
    always @ (posedge clk) begin
        if (rst == 1'b1) begin
            addra <= 1'b0;
            good <= 1'b0;
        end
        else if (good == 1'b0) begin
            if (hh < 800 && vv < 600) begin
                good <= 1'b1;
                addra <= vv * 800 + hh + 2;
            end
            else begin
                good <= 1'b0;
                addra <= 1'b0;
            end
        end
        else begin
            if (hh < 800 && vv < 600) begin
                addra <= addra + 1;
            end
            else begin
                addra <= addra;
            end
        end
    end
    
endmodule
