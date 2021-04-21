
module I2C_slave(

    input               CLCK       , 
    input               SCL        , 
    inout               SDA        ,
    input [7:0]         indata     ,
    
    output reg          flag
);


parameter slaveaddress = 7'b0010010;//´Ó»úµØÖ·
parameter valuecnt     = 4'b1010   ; //Count of bytes to be sent, send read value twice




reg [2:0]           SDASynch     = 3'b000 ;
reg                 start        = 1'b0   ;
reg                 stop         = 1'b0   ;
reg [2:0]           SCLSynch     = 3'b000 ;   
reg                 incycle      = 1'b0   ;
reg [7:0]           bitcount     = 8'd0   ;
reg [6:0]           address      = 7'd0   ;
reg [7:0]           datain       = 8'd0   ;
reg                 rw           = 1'b0   ;
reg                 addressmatch = 1'b0   ;
reg                 sdadata      = 1'bz   ; 
reg [3:0]           currvalue    = 4'd0   ;
wire                SDA_synched           ;
wire                SCL_posedge           ;
wire                SCL_negedge           ;




assign  SDA_synched = SDASynch[0] & SDASynch[1] & SDASynch[2];
assign  SCL_posedge = (SCLSynch[2:1] == 2'b01);  
assign  SCL_negedge = (SCLSynch[2:1] == 2'b10);  
assign  SDA         =  sdadata;





//Sample registers to send to requesting device
always @(posedge CLCK) begin 
    SCLSynch <= {SCLSynch[1:0], SCL};
end 




//Synch SDA to the CPLD clock
always @(posedge CLCK) begin 
    SDASynch <= {SDASynch[1:0], SDA};
end 


//Detect start and stop

always@(negedge SDA)begin 
    start <= SCL;
end


always@(posedge SDA)begin 
    stop <= SCL;
end 


always @(posedge start or posedge stop)begin 
    if (start)begin
        if (incycle == 1'b0)begin 
            incycle <= 1'b1;
        end 
    end
    else if (stop)begin
        if (incycle == 1'b1)begin 
            incycle <= 1'b0;
        end 
    end
end 

//Address and incomming data handling

always @(posedge SCL_posedge or negedge incycle)begin 
	if (~incycle)begin
		bitcount <= 8'd0;
	end
	else begin
		bitcount = bitcount + 1'b1;
		
		if (bitcount < 8)
			address[7 - bitcount] <= SDA_synched;
		
		if (bitcount == 8)begin
			rw           <= SDA_synched;
			addressmatch <= (slaveaddress == address) ? 1'b1 : 1'b0;
		end
			
		if ((bitcount > 9) & (~rw))
			datain[17 - bitcount] <= SDA_synched;
	end
end 





//ACK's and out going data
always @(posedge SCL_negedge) begin 
    //ACK's
    if (((bitcount == 8'd8) | ((bitcount == 8'd17) & ~rw)) & (addressmatch))begin
        sdadata  <= 1'b0;
        currvalue<= 4'd0;
        flag     <= 1'b0;
    end
    //Data
    else if ((bitcount >= 8'd9) & (rw) & (addressmatch) & (currvalue < valuecnt))begin
        //Send Data  
        if (((bitcount - 8'd9) - (currvalue * 9)) == 4'd8)begin
            //Release SDA so master can ACK/NAK
            sdadata   <= 1'bz;
            currvalue <= currvalue + 1'b1;
            flag      <= 1'b1;
        end
        else begin
            sdadata <= indata[7 - ((bitcount - 8'd9) - (currvalue * 9))]; //Modify this to send actual data, currently echoing incomming data valuecnt times
            flag    <=1'b0;
        end
    end
    //Nothing (cause nothing tastes like fresca)
    else begin 
        sdadata <= 1'bz;
    end 
end 
	

endmodule