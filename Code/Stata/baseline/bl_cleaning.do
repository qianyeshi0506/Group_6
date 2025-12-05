**********************************************************************
* 			Baseline: Clean data
*										  
***********************************************************************
*																	  
*	PURPOSE: 								  
*																	  
*	OUTLINE: 	PART 1: Import the data	 	  
*				PART 2: Format string & numerical variables	
*				PART 3: Save the data  
***********************************************************************
* 	PART 1: 	Import the data			  
***********************************************************************
import delimited "F:\Onedrive映射\1kcl\ESG\7QQMM906 Environmental Economics\Group Assessment\Raw Data\NO2_Meteo_ALL_Data_2022-2024.csv"

***********************************************************************
* 	PART 2: 	Format string & numerical variables		  			
***********************************************************************

***********************************************************************
* 	PART :  Date
***********************************************************************
gen date_numeric = date(date, "YMD") if !missing(date)
format date_numeric %td
drop date
rename date_numeric date

***********************************************************************
* 	PART :  area_fe
***********************************************************************
encode sitecode, generate(sitenum)


***********************************************************************
* 	PART 3: Save the data 
***********************************************************************
save "data_after_cleaning.dta", replace