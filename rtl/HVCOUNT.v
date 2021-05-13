`timescale 1ns/ 1ps

module  HVCOUNT#(
    parameter IMG_W   = 200,
    parameter IMG_H   = 164,
    parameter cnt_x0  = 16 ,  
    parameter cnt_x1  = 10 ,
    parameter cnt_y0  = 5  ,
    parameter cnt_y1  = 5  ,
    parameter pixel   = 500
    
)(

    input                            clk        ,
    input                            rst_n      ,
    input [23:0]                     i_binary   ,
    input                            i_hsync    ,
    input                            i_vsync    ,
    input                            i_de       ,
                                                
    output [23:0]                    o_binary   ,
    output signed       [31:0]       mid_y      ,
    output signed       [31:0]       mid_x      ,
    output reg signed   [31:0]       p_sum      ,
    output                           o_hsync    ,
    output                           o_vsync    , 
    output                           o_de                

);



reg [10:0]              hcnt         ;
reg [10:0]              vcnt         ;
reg [23:0]              cnt_delete   ;
reg [9:0]               hcount_begin ;
reg [9:0]               vcount_begin ;
reg [9:0]               hcount_end   ;
reg [9:0]               vcount_end   ;
reg                     delay_de_1   ;
reg                     delay_hsync_1;
reg                     delay_vsync_1;
wire                    flag0        ;
wire                    flag1        ;
reg [10:0]              x0           ;
reg [10:0]              y0           ;
reg [10:0]              x1           ;
reg [10:0]              y1           ;
reg [23:0]              i_binary_r   ;
reg                     flag_delete  ;
reg signed [31:0]       mid_yr       ;
reg signed [31:0]       mid_xr       ;





assign flag0    =(x0<hcnt && hcnt<x1)?1'b1:1'b0;
assign flag1    =(y0<vcnt && vcnt<y1)?1'b1:1'b0;
assign o_binary =i_binary_r;
assign o_de     =delay_de_1;
assign o_hsync  =delay_hsync_1;
assign o_vsync  =delay_vsync_1;
assign mid_y    =mid_yr;
assign mid_x    =mid_xr;




/********************************************************************************************/

/***************************************timing***********************************************/


always@(posedge  clk)begin
    delay_de_1   <=i_de;
    delay_hsync_1<=i_hsync;
    delay_vsync_1<=i_vsync;
end




/********************************************************************************************/

/***************************************Horizontal and vertical counting****************** **/


always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin 
        hcnt<=11'd0;
    end 
    else if (hcnt==IMG_W-1'b1)begin 
        hcnt<=11'd0;
    end 
    else if(i_de==1'b1)begin 
        hcnt<=hcnt+1'b1;
    end 
    else begin 
        hcnt<=11'd0;
    end 
end 


always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin 
        vcnt<=11'd0;
    end 
    else if ( hcnt==IMG_W-1'b1) begin
        if(vcnt==IMG_H-1'b1 )begin 
            vcnt<=11'd0;
        end 
        else begin 
            vcnt<=vcnt+1'b1;
        end 
     end
end 



/********************************************************************************************/

/***************************************Horizontal and vertical effective counting********* */


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin 
        hcount_begin<=10'd0;
    end 
    else if (i_de==1'b1)begin
        if(hcount_begin==cnt_x0)begin 
            hcount_begin<=cnt_x0;
        end 
        else if(i_binary==24'd0)begin 
            hcount_begin<=hcount_begin+1'b1;
        end 
        else begin 
            hcount_begin<=10'd0;
        end 
    end
    else begin 
        hcount_begin<=10'd0;
    end 
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin 
        vcount_begin<=10'd0;
    end 
    else if(vcnt!=IMG_H-1'b1 )begin
        if (vcount_begin==cnt_y0)begin 
            vcount_begin<=cnt_y0;
        end 
        else if (hcnt==IMG_W-1'b1)begin
            if (hcount_begin==cnt_x0 )begin 
                vcount_begin<=vcount_begin+1'b1;
            end 
            else begin 
                vcount_begin<=10'd0;
            end 
        end
    end
    else begin 
         vcount_begin<=10'd0;
    end 
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin 
        hcount_end<=10'd0;
    end 
    else if (hcount_begin==cnt_x0)begin
        if(hcount_end==cnt_x1)begin 
            hcount_end<=cnt_x1;
        end 
        else if(i_binary==24'hffffff)begin 
            hcount_end<=hcount_end+1'b1;
        end 
        else begin 
            hcount_end<=10'd0;
        end 
    end
    else begin 
        hcount_end<=10'd0;
    end 
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin 
        vcount_end<=10'd0;
    end 
    else if (vcount_begin==cnt_y0  )begin
        if(vcount_end==cnt_y1)begin
            vcount_end<=cnt_y1;
        end 
        else if (hcnt==IMG_W-1'b1)begin
             if (hcount_begin==10'd0)begin 
                vcount_end<=vcount_end+1'b1;
             end 
            else begin 
                vcount_end<=10'd0;
            end 
        end
    end
    else begin 
        vcount_end<=10'd0;
    end 
end





/********************************************************************************************/

/****************************Minimum permissible pixel point*********************************/

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin 
        cnt_delete<=24'd0;
    end 
    else if (vcnt==IMG_H-1'b1 && hcnt==IMG_W-1'b1 )begin
        cnt_delete<=24'd0;
    end 
    else if(i_binary==24'h000000)begin 
        cnt_delete<=cnt_delete+1'b1;
    end 
end


always@(posedge clk or negedge rst_n )begin
    if(!rst_n)begin 
        flag_delete<=1'b0;
    end 
    else if( vcnt==IMG_H-3'd5 && hcnt==IMG_W-4'd10)begin
        if(cnt_delete<pixel)begin 
            flag_delete<=1'b1;
        end             
        else begin 
            flag_delete<=1'b0; 
        end 
    end
end


/********************************************************************************************/

/***************Identify the four points that make up the rectangular object*****************/


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        x0<=11'd0;
        y0<=11'd0;
        x1<=11'd0;
    end 
    else if (vcount_begin==cnt_y0-1'b1)begin
        if(hcount_begin==cnt_x0-1'b1)begin
            x0<=hcnt-cnt_x0+1'b1;
            y0<=vcnt-cnt_y0+1'b1;
        end
        else if(hcount_end==cnt_x1-1'b1)begin
            x1<=hcnt-cnt_x1+1'b1;
        end
    end
    else if (flag_delete==1'b1)begin
        x0<=11'd0;
        y0<=11'd0;
        x1<=11'd0;
    end
end



always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        y1<=11'd0;
    end 
    else if(vcount_end==cnt_y1-1'b1  )begin
        y1<=vcnt-cnt_y1+1'b1;
    end
    else if(flag_delete==1'b1)begin 
        y1<=11'd0;
    end 
end





/********************************************************************************************/

/****************************Draw the object and center coordinates**************************/



always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin 
        i_binary_r<=24'd0;
    end 
    else if (flag0==1'b1 && (vcnt==y0 || vcnt==y1))begin 
            i_binary_r<=24'hff0000;
    end 
    else if (flag1==1'b1 &&(hcnt==x0 || hcnt==x1))begin 
            i_binary_r<=24'hff0000;
    end 
    else if ( vcnt==mid_y && hcnt==mid_x)begin 
            i_binary_r<=24'hff0000;
    end 
    else begin 
        i_binary_r<=i_binary;
    end 
end




/********************************************************************************************/

/*****************Determine the object center coordinates and the number of pixels********* */



always@(posedge clk or negedge rst_n)begin
   if(!rst_n)begin      
       mid_yr<=32'd0;
       mid_xr<=32'd0;
       p_sum <=32'd0;
   end 
   else begin
       mid_yr <= (y1+y0)>>1; 
       mid_xr <= (x0+x1)>>1; 
       p_sum  <= (x1-x0)*(y1-y0);
   end 
   
 end 

 



endmodule
