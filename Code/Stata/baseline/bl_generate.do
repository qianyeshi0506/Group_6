**********************************************************************
* 			Baseline: Generate variables
*												  
***********************************************************************
*																	  
*	PURPOSE: 								  
*																	  
*	OUTLINE: 	PART 1: Create derived variables
					* Treat
					* Post
					* Interation term
					* Is holiday
					* Time dummy
*				PART 2: Transform variables
					* Winsorisations
					* Log transformation
*				PART 3：Check and remove missing values													  
*																	  
*	Authors:  	Qianye Shi, Victoria Podovsovnik
*	Research support: 
*	ID variable: 		  					  
*	Requires: 	   	  										  
***********************************************************************
* 	PART 0: 	Import the data			  
***********************************************************************
import delimited "F:\Onedrive\1kcl\ESG\7QQMM906 Environmental Economics\Group Assessment\Raw Data\NO2_Meteo_ALL_Data_2022-2024.csv"


***********************************************************************
* 	PART 1 :  Treat
***********************************************************************

gen Inner_ULEZ=1 if region=="Inner"
drop Inner_ULEZ 
gen treatment=1 if region=="Inner"
replace treatment=0 if treatment==.

***********************************************************************
* 	PART 1 :  Post
***********************************************************************
gen post=0
replace post=1 if date >= date("2023-08-29", "YMD")

***********************************************************************
* 	PART 1 :  Interation term
***********************************************************************
gen treatment_post= treatment*post

***********************************************************************
* 	PART 1 :  Is holiday
***********************************************************************
gen is_holiday = 0
replace is_holiday = 1 if date == date("2023-01-02", "YMD") |date == date("2023-04-10", "YMD") | date == date("2023-05-01", "YMD") |date == date("2023-05-08", "YMD") | date == date("2023-05-29", "YMD") |date == date("2023-08-28", "YMD") |date == date("2023-12-25", "YMD") |date == date("2023-12-26", "YMD")

replace is_holiday = 1 if date == date("2024-01-01", "YMD") |date == date("2024-03-29", "YMD") |date == date("2024-04-01", "YMD") |date == date("2024-05-06", "YMD") |date == date("2024-05-27", "YMD") |date == date("2024-08-26", "YMD") |date == date("2024-12-25", "YMD") |date == date("2024-12-26", "YMD")

 replace is_holiday = 1 if date == date("2022-08-29", "YMD") |date == date("2022-09-19", "YMD") |date == date("2022-12-26", "YMD") |date == date("2022-12-27", "YMD")
 
label variable is_holiday "UK Bank Holiday (0=No, 1=Yes)"

***********************************************************************
* 	PART 1 :  Time Dummy
***********************************************************************
gen year = year(date)
gen month = month(date)
gen dow = dow(date)
reghdfe ln_NO2 treatment_post temp windspeed winddirection pressure rh precipitation ln_cloudfraction is_holiday ,absorb(sitenum dow month) vce(cluster sitenum)

***********************************************************************
* 	PART 2 :  Log transformation
***********************************************************************
//ln_NO2
gen ln_NO2= ln(no2) if no2>0
drop ln_NO2 
gen ln_NO2= ln(no2)

//In_cloud
gen ln_cloudfraction=ln(cloudfraction)
drop if cloudfraction==.
drop if ln_cloudfraction ==.

***********************************************************************
* 	PART 2 :  Winsorisations
***********************************************************************
ssc install winsor2
winsor2 ln_NO2 temp windspeed winddirection pressure rh precipitation ln_cloudfraction, cuts(1 99) replace

***********************************************************************
* 	PART 3:  Check and remove missing values		  
***********************************************************************
drop if missing(ln_NO2)|missing(temperature)|missing(windspeed)|missing(winddirection)|missing(pressure)|missing(rh)|missing(precipitation)|missing(ln_cloudfraction)

***********************************************************************
* 	PART : 	Save the data			  
***********************************************************************
save "data_after_cleaning.dta", replace