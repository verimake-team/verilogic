/*
 * @Descripttion: 
 * @version: 
 * @Author: Mengru Lin
 * @Date: 2021-03-13 
 * @LastEditors: Mengru Lin
 * @LastEditTime: 2021-04-13
 */ 
//###################################################################################################
//# Arduino Code
//###################################################################################################
#include <Arduino.h>
#include <U8x8lib.h>
#include <MsTimer2.h>
#include <Wire.h>

#define BAUD_RATE 115200
#define CHAR_BUF 128

#define L 0
#define R 1
#define PWMMAX 255

#define dirPin_L 9
#define pwmPin_L 10
#define dirPin_R 5
#define pwmPin_R 6

#define SPEEDLMIN 40
#define SPEEDRMIN 20




U8X8_SSD1306_128X32_UNIVISION_SW_I2C u8x8(/* clock=*/ 13, /* data=*/ 11, /* reset=*/ U8X8_PIN_NONE);

double  x_error=0;
double  h_error=0;

int speedl =0;
int speedr =0;

char buff[CHAR_BUF] = {0};

static unsigned char state = 0;

void setSpeed(char LorR,int speed){
    if(LorR==0){
        if(speed>0){
            digitalWrite(dirPin_L,0);
            analogWrite(pwmPin_L,speed);
        }
        else{
            digitalWrite(dirPin_L,1);
            analogWrite(pwmPin_L,PWMMAX+speed);
        }
    }
    else if(LorR==1){
       if(speed>0){
            digitalWrite(dirPin_R,0);
            analogWrite(pwmPin_R,speed);
        }
        else{
            digitalWrite(dirPin_R,1);
            analogWrite(pwmPin_R,PWMMAX+speed);
        }
    }
    else return;    
}


void Openmv_Receive_Data(char data)//接收Openmv传过来的数据
{
 
    switch (state)
    {
    case 0:
        if(data==(char)0xAA){          //帧头1
            state=1;
            }
        else {
            state=0;
        }
        break;
    case 1:
        if(data==(char)0xAE) state=2;  //帧头2
        else state=0;
        break;

    case 2:
        buff[0]=data;
        state=3;
        
        break;

    case 3:
        buff[1]=data;
        state=4;
        
        break;

    case 4:
        buff[2]=data;
        state=5;
        
        break;
    
    case 5:
        buff[3]=data;
        state=6;
        
        break;

    case 6:
        buff[4]=data;
        state=7;
        
        break;

    case 7:
        buff[5]=data;
        state=8;
        
        break;

    case 8:
        buff[6]=data;
        state=9;
        
        break;

    case 9:
        buff[7]=data;
        state=0;
        
        break;

    default:
        state=0;
        break;
    }
}

void timeHandle(){
    sei();
    // Serial.println("time in");
    char inChar=0;
    Wire.requestFrom(0x12, 10); //从机地址，字节个数
    while(Wire.available()){
        
        inChar=Wire.read();
        // Serial.print(state);
        Openmv_Receive_Data(inChar);
    }
    
    x_error=((0x000000FF&(long)buff[0])|(((long)buff[1])<<8)|(((long)buff[2])<<16)|(((long)buff[3])<<24));
    h_error=((0x000000FF&(long)buff[4])|(((long)buff[5])<<8)|(((long)buff[6])<<16)|(((long)buff[7])<<24));
    // Serial.print(x_error);
    // Serial.println(h_error);
}

void setup() {
    

    Serial.begin(BAUD_RATE);
    Wire.begin();
    delay(1000); 

    // Serial.println(sizeof(long));
    u8x8.begin();
    u8x8.setPowerSave(0);
    u8x8.setFont(u8x8_font_chroma48medium8_r );//u8x8_font_chroma48medium8_r);
    u8x8.setCursor(0,0);
    u8x8.print("hello");

    MsTimer2::set(60,timeHandle);
    MsTimer2::start();


}



void loop() {

    if(x_error==-100 && h_error==-2000 ){       //搜索目标
        setSpeed(L, 255*0.2);
        setSpeed(R,-255*0.2);
    }
    else if(h_error>-2000 && h_error<1500) {   //向前
       // setSpeed(L,0.001475*x_error*x_error+0.1275*x_error+49 );
        //setSpeed(R,0.001275*x_error*x_error-0.1275*x_error+51 );
        //setSpeed(L,0.001475*x_error*x_error+0.1275*x_error+74 );
        //setSpeed(R,0.001275*x_error*x_error-0.1275*x_error+76 );

         setSpeed(L,0.001475*x_error*x_error+0.1275*x_error+64 );
         setSpeed(R,0.001275*x_error*x_error-0.1275*x_error+66 );
  }
    else if(h_error>1700) {                   //退后
        setSpeed(L,0.00255*x_error*x_error+0.255*x_error-102 );
        setSpeed(R,0.00255*x_error*x_error-0.255*x_error-102 );
  }
    else {
        setSpeed(L,0);
        setSpeed(R,0);
  }

}
