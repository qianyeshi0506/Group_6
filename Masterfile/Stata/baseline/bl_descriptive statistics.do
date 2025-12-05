**********************************************************************
* 			Baseline: Descriptive statistics
*												  
***********************************************************************
*																	  
*	PURPOSE: 								  
*																	  
*	OUTLINE: 	PART 1: Descriptive statistics  
*				PART 2: Export the file	 
*																  
*	Authors:  	Qianye Shi, Victoria Podovsovnik
*	Research support: 
*	ID variable: 		  					  
*	Requires: 	  										  
***********************************************************************
* 	PART 1: 	Descriptive statistics		  
***********************************************************************
use "data_after_cleaning.dta", replace

tabstat ln_NO2 treatment post treatment_post cloudfraction temperature windspeed winddirection pressure rh precipitation ln_cloudfraction is_holiday, 

***********************************************************************
* 	PART 2: 	Export the file		  
***********************************************************************
//Save to a folder(!!!!!!you need to replace it with your asset path!!!!!!!!!!).
cd"F:\Onedrive映射\1kcl\ESG\7QQMM906 Environmental Economics\Group Assessment"

logout, save(mytable1) word replace: 
    tabstat ln_NO2 cloudfraction temperature windspeed winddirection 
    pressure rh precipitation ln_cloudfraction is_holiday, 
    by(siteype_num) s(count mean sd min max) f(%12.3f)
	
table (siteype_num) (ln_NO2), 
    nformat(%12.3f) 
    sformat("N=%s" count) 
    sformat("Mean=%s" mean) 
    sformat("SD=%s" sd) 
    sformat("Min=%s" min) 
    sformat("Max=%s" max)