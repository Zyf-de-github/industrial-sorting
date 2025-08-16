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

//��������
uint8_t LevelNum; //��ƽ��־ֵ
uint8_t IRSNum; //�����־ֵ
uint8_t KeyNum; //����ֵ
uint8_t buzzer_flag;

//uint8_t PageNum; //ҳ��ֵ��1��6��

uint8_t PageNum = 1;
uint8_t language_state = 0;
uint8_t speed_state = 0;
uint8_t wifi_state = 0;
uint8_t lastPageNum = 1; 

uint8_t Page_GetNum(void);


//��������
void Key_Debounce(void)
{
    // ģ�ⰴ�������߼�
    // ������Ը���ʵ��Ӳ�����ʵ������
    Delay_ms(20); // ������һ����ʱ����
}

// ���ݰ�����ȡҳ��ֵ
uint8_t Page_GetNum(void)
{
    static uint8_t lastKeyNum = 0; // �����ϴεİ���ֵ

    // ��������
    Key_Debounce();

    // ��ⰴ�������¼�
    if (KeyNum != lastKeyNum)
    {
        lastKeyNum = KeyNum;
			  
			  OLED_Clear();

        // ���°���1����һҳ����PageNum+1��������һҳ
        if (KeyNum == 1)
        {
            PageNum += 1;
        }
        // ���°���2����һҳ����PageNum-1��������һҳ
        else if (KeyNum == 2)
        {
            PageNum -= 1;
        }
        // ���°���3�����أ���PageNum=1���������˵�
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

    // ȷ�� PageNum ����Ч��Χ��
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
		
		//��ȡ����ֵ
		KeyNum=Key_GetNum();

    // ���ݰ�������ҳ��ֵ
    Page_GetNum();

    // ��ʾ��ǰҳ��
    Page_Show(PageNum,language_state,speed_state,wifi_state);

    // ��ʱ�����ⰴ������
    Delay_ms(100); 
		
		if(GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_5) == 1)
		{
			continue;
		}
		
		//��ƽ״̬1 => ʶ������1 => ���1
	  if(LevelNum==1)
		{
			LED2_ON();//ָʾ��2����
			PWM_SetCompare1(1700); //���1ת��һ���Ƕ���������1
	    Delay_s(5); //�ӳ�һ��ʱ�䱣֤����1����
	    PWM_SetCompare1(2500); //���1ת��
			LED2_OFF(); //ָʾ��2Ϩ��
			LevelNum=0;
			buzzer_flag=1;
			//OLED_ShowString(2,1,"object_1"); //oled��Ļ��ʾ����1����
		}
		
		//��ƽ״̬2 => ʶ������2 => ���2
	  else if(LevelNum==2)
		{
			LED3_ON();//ָʾ��3����
			PWM_SetCompare2(1700); //���2ת��һ���Ƕ���������2
	    Delay_s(5); //�ӳ�һ��ʱ�䱣֤����2����
	    PWM_SetCompare2(2500); //���2ת��
			LED3_OFF(); //ָʾ��3Ϩ��
			LevelNum=0;
			buzzer_flag=1;
			//OLED_ShowString(2,1,"object_2"); //oled��Ļ��ʾ����2����
		}
		
		//��ƽ״̬3 => ʶ������3 => ���3
	  else if(LevelNum==3)
		{
			LED4_ON();//ָʾ��4����
	    Delay_s(5); //�ӳ�һ��ʱ�䱣֤����3����
			LED4_OFF(); //ָʾ��4Ϩ��
			LevelNum=0;
			buzzer_flag=1;
			//OLED_ShowString(2,1,"object_3"); //oled��Ļ��ʾ����3����
		}
		
		//�����Ӧ��������������ͷ��ʱ�����������죬ָʾ������
		if(IRSNum==1&&buzzer_flag==1)
		{
			for(int i=0;i<10;i++)
			{
				LED1_ON(); //ָʾ��1����
				Buzzer_ON(); //����������
				//OLED_ShowString(2,1,"Under detection");//oled��Ļ��ʾ���ڼ��
				Delay_ms(150); //�ӳ�400ms��
				Buzzer_OFF(); //�������ر�
				LED1_OFF(); //ָʾ����
			}
			buzzer_flag=0;
		}
		
	}
}
