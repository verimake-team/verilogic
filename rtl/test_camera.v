`timescale 1ns/ 1ps

/*******************************************************************************************
**********************************run on the Anlogic FPGA***********************************
*******************************************************************************************/
/*
Date:2021413
Author: Mengru Lin
*/

/*******************************************************************************************
*__      __       _ __  __       _          __   __                   _             _      *
*\ \    / /      (_)  \/  |     | |         \ \ / /       /\         | |           (_)     *
* \ \  / /__ _ __ _| \  / | __ _| | _____    \ V /       /  \   _ __ | | ___   __ _ _  ___ *
*  \ \/ / _ \ '__| | |\/| |/ _` | |/ / _ \    > <       / /\ \ | '_ \| |/ _ \ / _` | |/ __|*
*   \  /  __/ |  | | |  | | (_| |   <  __/   / . \     / ____ \| | | | | (_) | (_| | | (__ *
*    \/ \___|_|  |_|_|  |_|\__,_|_|\_\___|  /_/ \_\   /_/    \_\_| |_|_|\___/ \__, |_|\___|*
*                                                                              __/ |       *
*                                                                             |___/        *
*******************************************************************************************/



module test_camera
(
    input   wire        clk_24m     ,
    input   wire        rst_n       ,
    input   wire        cam_pclk    ,
    input   wire        cam_href    ,
    input   wire        cam_vsync   ,
    inout   wire        cam_soid    ,
    input   wire [7:0]  cam_data    ,
    input   wire        i2c_scl     ,
    inout   wire        i2c_sda     ,
    
    output 	reg  [7:0]  vga_r       ,
    output 	reg  [7:0]  vga_g       ,
    output 	reg  [7:0]  vga_b       ,
    output 	wire        vga_clk     ,
    output 	wire        cam_pwdn    ,
    output 	wire        cam_rst     ,
    output 	wire        cam_soic    ,
    output 	wire        cam_xclk    ,
    output 	reg         th_hsync    ,
    output 	reg         th_vsync

 ) ;

//pll
wire                  clk_lcd        ;
wire                  clk_cam        ;
wire                  clk_sccb       ;  
//camera                    
wire                  camera_wrreq   ;
wire                  camera_wclk    ;
wire [15:0]           camera_wrdat   ;
wire [19:0]           camera_addr    ;
wire                  init_ready     ;
wire                  sda_oe         ;
wire                  sda            ;
wire                  sda_in         ;
wire                  scl            ;
//lcd display
wire [10:0]           hsync_cnt      ;
wire [10:0]           vsync_cnt      ;
wire                  vga_rden       ;
wire                  vga_rden0      ;
wire [15:0]	          vga_rddat      ;//lcd read
wire [15:0]	          vga_rdaddr     ;   
wire                  vga_den        ;
wire                  vga_hsync      ;
wire                  vga_vsync      ;
wire                  vga_pwm        ;//backlight,set to high
//ycbcr
wire [23:0]           o_rgb          ;
wire [23:0]           o_ycbcr        ;
reg  [15:0]           o_rgb0         ;
wire                  o_hsync        ;
wire                  o_vsync        ;
wire                  o_de           ;
wire                  o_de0          ;
wire [23:0]           i_rgb          ;
//threshold
wire [23:0]           th_binary      ; 
wire                  th_hsyncr      ;
wire                  th_vsyncr      ;
wire                  th_de          ;
//HVCOUNT
reg  signed [31:0]    x_error        ;
reg  signed [31:0]    h_error        ;
wire                  cnt_hsyncr     ;
wire                  cnt_vsyncr     ;
wire [23:0]           cnt_binary     ; 
wire [31:0]           mid_x          ;
wire [31:0]           p_sum          ;
//iic
wire [7:0]            datax0         ;
wire [7:0]            datax1         ;
wire [7:0]            datax2         ;
wire [7:0]            datax3         ;
wire [7:0]            datah0         ;
wire [7:0]            datah1         ;
wire [7:0]            datah2         ;
wire [7:0]            datah3         ;
reg  [3:0]            data_count     ;
reg  [7:0]            iic_data=8'd0  ;
wire [7:0]            iic_datar      ;
wire                  wr_data_vaild  ;


assign cam_soid    = (sda_oe == 1'b1) ? sda : 1'bz;
assign sda_in      = cam_soid;
assign cam_soic    = scl;
assign cam_pwdn    = 1'b0;
assign cam_rst     = rst_n;
assign i_rgb[23:16]= {vga_rddat[15:11],3'd0};
assign i_rgb[15:8] = {vga_rddat[10:5] ,2'd0};
assign i_rgb[7:0]  = {vga_rddat[4:0]  ,3'd0};
assign iic_datar   = iic_data;
assign datax0      = x_error[ 7: 0];
assign datax1      = x_error[15: 8];
assign datax2      = x_error[23:16];
assign datax3      = x_error[31:24];
assign datah0      = h_error[ 7: 0];
assign datah1      = h_error[15: 8];
assign datah2      = h_error[23:16];
assign datah3      = h_error[31:24];




always @(posedge clk_lcd or negedge rst_n)begin
    if(!rst_n)begin
        vga_r   <=8'd0;
        vga_g   <=8'd0;
        vga_b   <=8'd0;
        th_hsync<=1'b0;
        th_vsync<=1'b0;
    end
    else begin
        th_hsync<=cnt_hsyncr;
        th_vsync<=cnt_vsyncr;
        if(th_de==1'b1)begin
            vga_r<=cnt_binary[23:16];
            vga_g<=cnt_binary[15:8];
            vga_b<=cnt_binary[7:0];
        end
        else if(o_de==1'b1)begin
            vga_r<=o_rgb[23:16];
            vga_g<=o_rgb[15:8];
            vga_b<=o_rgb[7:0];
        end
        else begin
            vga_r<=8'd0;
            vga_g<=8'd0;
            vga_b<=8'd0;
        end
    end
end



always@(posedge clk_lcd or negedge rst_n)begin
   if(!rst_n)begin      
       x_error<=32'd0;
   end 
   else begin
       x_error<=(mid_x-7'd100);
   end 
 
end 



always@(posedge clk_lcd or negedge rst_n)begin
   if(!rst_n)begin      
       h_error<=32'd0;
   end 
   else begin
      h_error<=(p_sum-2000);
 
   end
end 
 
 
 
always@(posedge wr_data_vaild or negedge rst_n)begin
    if (!rst_n)begin
       data_count <=4'd0 ;
    end 
    else if (data_count == 4'd9)begin
       data_count <=4'd0 ;
    end 
    else begin 
       data_count <= data_count+1'b1 ; 
    end 
end 



always@(*) begin 
    case (data_count) 
        4'd0 :   iic_data  =8'b10101010;   //The frame head 1:AA
        4'd1 :   iic_data  =8'b10101110;   //The frame head 2:AE
        4'd2 :   iic_data  = datax0;
        4'd3 :   iic_data  = datax1;
        4'd4 :   iic_data  = datax2;
        4'd5 :   iic_data  = datax3;
        4'd6 :   iic_data  = datah0;
        4'd7 :   iic_data  = datah1;
        4'd8 :   iic_data  = datah2;
        4'd9 :   iic_data  = datah3;
        default: iic_data=8'd0;
    endcase 
end 
 


ip_pll u_pll(
    .refclk      (clk_24m     ),    //24M
    .clk0_out    (clk_lcd     ),    //lcd clk24M
    .clk1_out    (clk_cam     ),    //12m,for cam xclk
    .clk2_out    (clk_sccb    )     //4m,for sccb init
);



camera_reader u_camera_reader
(
    .clk        (clk_cam        ),
    .reset_n    (rst_n          ),
    .csi_xclk   (cam_xclk       ),
    .csi_pclk   (cam_pclk       ),
    .csi_data   (cam_data       ),
    .csi_vsync  (!cam_vsync     ),
    .csi_hsync  (cam_href       ),
    .data_out   (camera_wrdat   ),
    .wrreq      (camera_wrreq   ),
    .wrclk      (camera_wclk    ),
    .wraddr     (camera_addr    )
);



camera_init u_camera_init
(
    .clk        (clk_sccb   ),
    .reset_n    (rst_n      ),
    .ready      (init_ready ),
    .sda_oe     (sda_oe     ),
    .sda        (sda        ),
    .sda_in     (sda_in     ),
    .scl        (scl        )
);



img_cache u_img_cache  
( 
    //write 32800*(5+6+5)
    .dia        (camera_wrdat           ), 
    .addra      (camera_addr            ), 
    .cea        (camera_wrreq           ), 
    .clka       (camera_wclk            ), 
    .rsta       (!rst_n                 ), 
    //read 32800*(5+6+5)   
    .dob        (vga_rddat              ), 
    .addrb      (vga_rdaddr             ), 
    .ceb        (vga_rden || vga_rden0  ),
    .clkb       (clk_lcd                ), 
    .rstb       (!rst_n                 )
);




lcd_sync 
#(
    .IMG_W      (200        ),
    .IMG_H      (164        ),
    .IMG_X      (0          ),
    .IMG_Y      (1          )
)
u_vga_sync
(
    .clk        (clk_lcd    ),
    .rest_n     (rst_n      ),
    .lcd_clk    (vga_clk    ),
    .lcd_pwm    (vga_pwm    ),
    .lcd_hsync  (vga_hsync  ), 
    .lcd_vsync  (vga_vsync  ), 
    .lcd_de     (vga_den    ),
    .hsync_cnt  (hsync_cnt  ),
    .vsync_cnt  (vsync_cnt  ),
    .img_ack    (vga_rden   ),
    .img_ack0   (vga_rden0  ),
    .addr       (vga_rdaddr )
);



rgb2ycbcr u_rgb2ycbcr(
    .pixelclk   (clk_lcd   ),
    .i_rgb      (i_rgb     ),
    .i_hsync    (vga_hsync ),
    .i_vsync    (vga_vsync ),
    .i_de       (vga_rden  ),
    .i_de0      (vga_rden0 ),
                
    .o_rgb      (o_rgb     ),
    .o_ycbcr    (o_ycbcr   ),
    .o_hsync    (o_hsync   ),
    .o_vsync    (o_vsync   ), 
    .o_de0      (o_de      ),
    .o_de       (o_de0     ) 
);


threshold_binary#(
        .DW       (24        ),
        .Y_TH     (150       ),//ºìÉ«
        .Y_TL     (40        ),
        .CB_TH    (155       ),
        .CB_TL    (100       ),
        .CR_TH    (240       ),
        .CR_TL    (160       )
        /* .Y_TH     (135       ),//À¶É«
        .Y_TL     (50        ),
        .CB_TH    (245       ),
        .CB_TL    (155       ),
        .CR_TH    (140       ),
        .CR_TL    (80        )
        */      
)u_threshold_binary(
    .pixelclk     (clk_lcd   ),
    .reset_n      (rst_n     ),
    .i_ycbcr      (o_ycbcr   ),
    .i_hsync      (o_hsync   ),
    .i_vsync      (o_vsync   ),
    .i_de         (o_de0     ),
                  
                  
    .o_binary     (th_binary ),
    .o_hsync      (th_hsyncr ),
    .o_vsync      (th_vsyncr ),   
    .o_de         (th_de     )                                                                                            
);


HVCOUNT #(
    .IMG_W      (200        ),
    .IMG_H      (164        ),
    .cnt_x0     (16         ),  
    .cnt_x1     (16         ),
    .cnt_y0     (5          ),
    .cnt_y1     (5          ),
    .pixel      (500        )

)u_HVCOUNT(

   .clk      (clk_lcd    ),
   .rst_n    (rst_n      ),
   .i_binary (th_binary  ),
   .i_hsync  (th_hsyncr  ),
   .i_vsync  (th_vsyncr  ),
   .i_de     (th_de      ),
    
   .o_binary (cnt_binary ),
   .o_hsync  (cnt_hsyncr ),
   .o_vsync  (cnt_vsyncr ),
   .mid_x    (mid_x      ),
   .p_sum    (p_sum      ),
   .o_de     (cnt_de     )

);


I2C_slave  u_iic(
    .CLCK       (clk_lcd      ),
               
    .indata     (iic_datar    ),
    .SCL        (i2c_scl      ),
    .SDA        (i2c_sda      ),
    .flag       (wr_data_vaild)

);


endmodule
