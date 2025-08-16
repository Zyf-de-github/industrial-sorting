#include "stm32f10x.h"                  // Device header
#include "Delay.h"
#include "OLED.h"
#include "Key.h"
#include "PWM.h"
#include "LED.h"
#include "IRSensor.h"
#include "Buzzer.h"
#include "Level.h"

#include <stdint.h>

//声明变量
uint8_t LevelNum; //电平标志值
uint8_t IRSNum; //红外标志值
uint8_t KeyNum; //按键值
uint8_t buzzer_flag;

//uint8_t PageNum; //页面值（1—6）

uint8_t PageNum = 1;
uint8_t language_state = 0;
uint8_t speed_state = 0;
uint8_t wifi_state = 0;
uint8_t lastPageNum = 1; 

uint8_t Page_GetNum(void);


//按键消抖
void Key_Debounce(void)
{
    // 模拟按键消抖逻辑
    // 这里可以根据实际硬件情况实现消抖
    Delay_ms(20); // 假设有一个延时函数
}

// 根据按键获取页面值
uint8_t Page_GetNum(void)
{
    static uint8_t lastKeyNum = 0; // 保存上次的按键值

    // 按键消抖
    Key_Debounce();

    // 检测按键按下事件
    if (KeyNum != lastKeyNum)
    {
        lastKeyNum = KeyNum;
			  
			  OLED_Clear();

        // 按下按键1（下一页），PageNum+1，进入下一页
        if (KeyNum == 1)
        {
            PageNum += 1;
        }
        // 按下按键2（上一页），PageNum-1，进入上一页
        else if (KeyNum == 2)
        {
            PageNum -= 1;
        }
        // 按下按键3（返回），PageNum=1，返回主菜单
        else if (KeyNum == 3)
        {
					if(PageNum==4)
            language_state += 1;
					else if(PageNum==5)
						speed_state += 1;
					else if(PageNum==6)
						wifi_state += 1;
        }
    }

    // 确保 PageNum 在有效范围内
    if (PageNum < 1)
    {
        PageNum = 1;
    }
    else if (PageNum > 7)
    {
        PageNum = 7;
    }

    return PageNum;
}


int main(void)
{
	PWM_Init();
	Key_Init();
	LED_Init();
	OLED_Init();
	IRSensor_Init();
	Buzzer_Init();
	Level_Init();
	Wifi_Init();
	buzzer_flag=1;
	
	while (1)
	{

		LevelNum=Level_GetNum();
		IRSNum=IRSensor_Get();
		
		//获取按键值
		KeyNum=Key_GetNum();

    // 根据按键更新页面值
    Page_GetNum();

    // 显示当前页面
    Page_Show(PageNum,language_state,speed_state,wifi_state);

    // 延时，避免按键抖动
    Delay_ms(100); 
		
		if(GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_5) == 1)
		{
			continue;
		}
		
		//电平状态1 => 识别到物体1 => 舵机1
	  if(LevelNum==1)
		{
			LED2_ON();//指示灯2亮起
			PWM_SetCompare1(1700); //舵机1转动一定角度拦截物体1
	    Delay_s(5); //延迟一定时间保证物体1落下
	    PWM_SetCompare1(2500); //舵机1转回
			LED2_OFF(); //指示灯2熄灭
			LevelNum=0;
			buzzer_flag=1;
			//OLED_ShowString(2,1,"object_1"); //oled屏幕显示物体1名称
		}
		
		//电平状态2 => 识别到物体2 => 舵机2
	  else if(LevelNum==2)
		{
			LED3_ON();//指示灯3亮起
			PWM_SetCompare2(1700); //舵机2转动一定角度拦截物体2
	    Delay_s(5); //延迟一定时间保证物体2落下
	    PWM_SetCompare2(2500); //舵机2转回
			LED3_OFF(); //指示灯3熄灭
			LevelNum=0;
			buzzer_flag=1;
			//OLED_ShowString(2,1,"object_2"); //oled屏幕显示物体2名称
		}
		
		//电平状态3 => 识别到物体3 => 舵机3
	  else if(LevelNum==3)
		{
			LED4_ON();//指示灯4亮起
	    Delay_s(5); //延迟一定时间保证物体3落下
			LED4_OFF(); //指示灯4熄灭
			LevelNum=0;
			buzzer_flag=1;
			//OLED_ShowString(2,1,"object_3"); //oled屏幕显示物体3名称
		}
		
		//红外感应到有物体在摄像头下时，蜂鸣器鸣响，指示灯亮起
		if(IRSNum==1&&buzzer_flag==1)
		{
			for(int i=0;i<10;i++)
			{
				LED1_ON(); //指示灯1亮起
				Buzzer_ON(); //蜂鸣器鸣响
				//OLED_ShowString(2,1,"Under detection");//oled屏幕显示正在检测
				Delay_ms(150); //延迟400ms后
				Buzzer_OFF(); //蜂鸣器关闭
				LED1_OFF(); //指示灯灭
			}
			buzzer_flag=0;
		}
		
	}
}
