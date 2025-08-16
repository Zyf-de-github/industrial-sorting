#include "stm32f10x.h"                  // Device header

void Buzzer_Init(void)
{
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);
	
	GPIO_InitTypeDef GPIO_InitStructure;
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
	GPIO_InitStructure.GPIO_Pin = GPIO_Pin_10;
	GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
	GPIO_Init(GPIOA, &GPIO_InitStructure);
	
	GPIO_SetBits(GPIOA, GPIO_Pin_10);
}

//·äÃùÆ÷ÃùÏì
void Buzzer_ON(void)
{
	GPIO_ResetBits(GPIOA, GPIO_Pin_10);
}

//·äÃùÆ÷¹Ø±Õ
void Buzzer_OFF(void)
{
	GPIO_SetBits(GPIOA, GPIO_Pin_10);
}

//·äÃùÆ÷×´Ì¬×ª»»
void Buzzer_Turn(void)
{
	if (GPIO_ReadOutputDataBit(GPIOB, GPIO_Pin_10) == 0)
	{
		GPIO_SetBits(GPIOA, GPIO_Pin_10);
	}
	else
	{
		GPIO_ResetBits(GPIOA, GPIO_Pin_10);
	}
}
