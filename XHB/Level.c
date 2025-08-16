#include "stm32f10x.h"                  // Device header
#include "Delay.h"

void Level_Init(void)
{
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB, ENABLE);
	
	GPIO_InitTypeDef GPIO_InitStructure;
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPD;
	GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6 | GPIO_Pin_7 ;
	GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
	GPIO_Init(GPIOB, &GPIO_InitStructure);
}

//��ƽ��ȡ
//��ȡ�������ŵĵ�ƽ��������ֵ�ƽ״̬�ֱ��Ӧ���ּ����
uint8_t Level_GetNum(void)
{
	uint8_t LevelNum = 0;
	if (GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_6) == 1 && (GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_7) == 1))
	{
		LevelNum=1;
	}
	if (GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_6) == 0 && (GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_7) == 0))
	{
		LevelNum=2;
	}
	if (GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_6) == 1 && (GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_7) == 0))
	{
		LevelNum=3;
	}

  /*if (GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_12) == 1)
	{
		Delay_ms(20);
		while (GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_12) == 1);
		Delay_ms(20);
		KeyNum = 4;
	}	*/
	
	return LevelNum;
}
