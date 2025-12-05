*********************************************************************
* 			Baseline:Import + merge data
*												  
***********************************************************************
*																	  
*	PURPOSE: 								  
*																	  
*	OUTLINE: 	PART 1: import + merge sitetype	  
*				PART 2: save the data
*																  
*	Authors:  	Qianye Shi, Victoria Podovsovnik
*	Research support: 
*	ID variable: 		  					  
*	Requires: 	 
***********************************************************************
* 	PART 1:  import + merge sitetype	  			
***********************************************************************

use "data_after_cleaning.dta", clear

//merge datasets
merge m:1 sitecode using "sitetype_sitename.dta"

encode sitetype, generate(siteype_num)

tab siteype_num

***********************************************************************
* 	PART 2:  save the data	
***********************************************************************

save "data_after_cleaning.dta", replace


