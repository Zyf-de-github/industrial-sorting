#include "stm32f10x.h"                  // Device header

void IRSensor_Init(void)
{
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB, ENABLE);
	
	GPIO_InitTypeDef GPIO_InitStructure;
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;
	GPIO_InitStructure.GPIO_Pin = GPIO_Pin_8 ;
	GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
	GPIO_Init(GPIOA, &GPIO_InitStructure);
}

//红外检测模块
//检测到对应引脚为低电平，即红外检测有物体靠近时，检测值变为1
uint8_t IRSensor_Get(void)
{
	uint8_t IRSNum=0;
	if(GPIO_ReadInputDataBit(GPIOA, GPIO_Pin_8)==0)
	{
	    IRSNum=1;
  }
	return IRSNum;
}

