`timescale 1ns/ 1ps

module camera_reader
(
    input   wire        clk           ,
    input   wire        reset_n       ,
    input   wire        csi_pclk      ,
    input   wire [7:0]  csi_data      ,
    input   wire        csi_vsync     ,
    input   wire        csi_hsync     ,
    
    output  wire        csi_xclk      ,
    output  reg  [15:0] data_out=16'd0,
    output  wire        wrreq         ,
    output  wire        wrclk         ,
    output  reg  [19:0] wraddr
);
                      
                      
reg [19:0]            pixel_counter =20'd0;
reg                   vsync_passed  =1'b0 ;
reg                   write_pixel   =1'b0 ;
reg [7:0]             subpixel            ;
reg [15:0]            current_pixel       ;
reg                   wrclk1        =1'b0 ;


assign csi_xclk = (reset_n ==1'b1) ? clk :1'b0;
assign wrreq    = (write_pixel ==1'b1) && pixel_counter >20'd2 ? wrclk1 :1'b0;
assign wrclk    = csi_pclk;



always@(posedge csi_pclk)begin
    wrclk1 <= ~wrclk1;
end


always@(negedge wrclk1)begin
    if(csi_hsync ==1'b1)begin
        write_pixel <=1'b1;
    end
    else begin 
        write_pixel <= 1'b0;
    end
end


always@(posedge wrreq )begin
    data_out <= current_pixel;
end


always@(posedge csi_pclk or negedge reset_n)begin
    if(reset_n == 1'b0)begin
        pixel_counter <= 20'd0;
        vsync_passed  <=1'b0;
    end
    else begin
        if(csi_vsync == 1'b1)begin
            pixel_counter <=20'd0;
            vsync_passed  <=1'b1;
            wraddr        <=20'd0;
        end
        else if(csi_hsync == 1'b1 && vsync_passed ==1'b1)begin
                if(pixel_counter[0] == 1'b0)begin
                    pixel_counter <= pixel_counter + 1'b1;
                    subpixel      <= csi_data;
                end
                else begin
                    current_pixel <= { subpixel, csi_data };
                    pixel_counter <= pixel_counter + 1'b1;
                    wraddr        <= wraddr + 1'b1;
                end
            end
        else begin
                if(write_pixel ==1'b1)begin
                    pixel_counter <= pixel_counter + 1'b1;
                end 
                else begin 
                    pixel_counter <= 20'd0;
                end 
        end
    end
end



endmodule
