#include "stm32f10x.h"
#include "OLED.h"


void Page_Show(uint8_t PageNum)
{
   if (PageNum < 1)
	 {
		 PageNum =1;
	 }		 
   if (PageNum == 1)
	 {
		 OLED_ShowString(1,16,"Menu");
		 OLED_ShowString(17,1,"Watch");
		 OLED_ShowString(33,1,"Mode");
		 OLED_ShowString(41,1,"Language");
     OLED_ShowString(49,1,"Speed");
		 OLED_ShowString(57,1,"Wi-Fi");
	 }
	 
	 else if (PageNum == 2)
	 {
		 OLED_ShowString(1,16,"Watch");
		 OLED_ShowString(17,1,"=>State:");
		 OLED_ShowString(41,1,"=>Result:");
	 }
	 
	 else if (PageNum == 3)
	 {
		 OLED_ShowString(1,16,"Mode");
		 OLED_ShowString(17,1,"=>Basic");
		 OLED_ShowString(33,1,"=>Advanced");
	 }
	 
	 else if (PageNum == 4)
	 {
		 OLED_ShowString(1,16,"Language");
		 OLED_ShowString(17,1,"=>Chinese");
		 OLED_ShowString(33,1,"=>English");
	 }
	 
	 else if (PageNum == 5)
	 {
		 OLED_ShowString(1,16,"Speed");
		 OLED_ShowString(17,1,"=>Speed_1");
		 OLED_ShowString(33,1,"=>Speed_2");
		 OLED_ShowString(41,1,"=>Speed_3");
     OLED_ShowString(49,1,"=>Speed_4");
		 OLED_ShowString(57,1,"=>Speed_5");
	 }
	 
	 else if (PageNum == 6)
	 {
		 OLED_ShowString(1,16,"Wi-Fi");
		 OLED_ShowString(17,1,"=>Wi-Fi is connected.");
		 OLED_ShowString(41,1,"=>Wi-Fi is not connected.");
	 }

}


