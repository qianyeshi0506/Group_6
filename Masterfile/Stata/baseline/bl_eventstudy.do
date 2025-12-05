**********************************************************************
* 			Baseline: Event Study
*												  
***********************************************************************
*																	  
*	PURPOSE: 								  
*																	  
*	OUTLINE: 	PART 1: generate the variables	  
*				PART 2: Run the regression	  
*				PART 3: Export table  
*																  
*	Authors:  	Qianye Shi, Victoria Podovsovnik
*	Research support: 
*	ID variable: 		  					  
*	Requires: 	  										  
***********************************************************************
* 	PART 0: 	import data		  
***********************************************************************
use "F:\Onedrive映射\1kcl\ESG\7QQMM906 Environmental Economics\Group Assessment\data after cleaning\data_after_cleaning.dta", replace   

***********************************************************************
* 	PART 1: 	generate the variables	  
*********************************************************************** 

*judgment variable
gen judgment= ym(year(date), month(date)) - ym(2023, 8)   

gen pre_1 = ( judgment < 0 & treatment  ==1)   

drop pre_1   

ssc install coefplot   

   

*Variables generated 11 periods prior to policy implementation   

forvalues i = 11(-1)1 {   

    gen pre_`i'=(judgment ==-`i' & treatment ==1)   

}   

*current variable   

gen current = ( judgment ==0 & treatment ==1)   

*Variables in the 11 periods following the policy   

forvalues i = 11(-1)1 {   

    gen las_`i' = (judgment ==`i' & treatment ==1)   

}   

*intersection 
gen time = judgment  

gen treatment_time = treatment * time     

     
***********************************************************************
* 	PART 2: 	Run the regression	  
*********************************************************************** 
*Note: We omit pre_1 as the baseline period instead of including it in the regression 

reghdfe ln_NO2 treatment_post temp windspeed winddirection pressure rh precipitation ln_cloudfraction is_holiday pre_11 pre_10 pre_9 pre_8 pre_7 pre_6 pre_5 pre_4 pre_3 pre_2 current las_1 las_2 las_3 las_4 las_5 las_6 las_7 las_8 las_9 las_10 las_11 , absorb(sitenum dow month) vce(cluster sitenum)   

   
***********************************************************************
* 	PART 3: 	Install the necessary commands   
***********************************************************************

// ssc install parmest, replace   

// ssc install coefplot, replace   

   
***********************************************************************
* 	PART 4: 	Extract and save the coefficients  
***********************************************************************

parmest, saving("event_study_coef.dta", replace)   

   
***********************************************************************
* 	PART 5: 	Processing coefficient data   
***********************************************************************
use "event_study_coef.dta", clear   

// Only retain the coefficients relevant to the event study.  

keep if regexm(parm, "^pre_|^current|^las_")   

// Generate relative time variables  
gen rel_time = .   
 
//Pre-policy periods 

forvalues i = 2/11 {   

    replace rel_time = -`i' if parm == "pre_`i'"   

}   
   
// The baseline period pre_1 (not included in the regression, add manually)   

// Current   

replace rel_time = 0 if parm == "current"   
   
//Post-policy period  

forvalues i = 1/11 {   

    replace rel_time = `i' if parm == "las_`i'"   

}   
   
// Delete possible duplicate or invalid rows   

drop if rel_time == .   

***********************************************************************
* 	PART 6: 	Manually add the base period
***********************************************************************

set obs `=_N + 1'   

replace rel_time = -1 in `=_N'   

replace estimate = 0 in `=_N'   

replace stderr = 0 in `=_N'   

replace min95 = 0 in `=_N'   

replace max95 = 0 in `=_N'   

   
***********************************************************************
* 	PART 7: 	Calculate the confidence interval (90%)
***********************************************************************

gen ci_upper = estimate + 1.65*stderr   

gen ci_lower = estimate - 1.65*stderr   
   
// For the baseline period, ensure that the confidence interval is also 0.  

replace ci_upper = 0 if rel_time == -1   

replace ci_lower = 0 if rel_time == -1   
  
// sort  

sort rel_time   
   
***********************************************************************
* 	PART 8: 	 Drawing
***********************************************************************

twoway (rcap ci_upper ci_lower rel_time, lcolor(gs10) lwidth(medium)) ///
       (scatter estimate rel_time, mcolor(black) msymbol(O) msize(medium)) ///
       (line estimate rel_time, lcolor(black) lwidth(medthick)), ///
       xline(-0.5, lpattern(dash) lcolor(gs8) lwidth(medium)) ///
       yline(0, lpattern(dash) lcolor(gs8) lwidth(thin)) ///
       xlabel(-11(1)11, labsize(small) nogrid) ///
       ylabel(, labsize(small) format(%4.2f) nogrid) ///
       xtitle("Relative Time (Treatment Period = 0)", size(medsmall)) ///
       ytitle("Treatment Effect", size(medsmall)) ///
       graphregion(color(white)) bgcolor(white) ///
       legend(off) ///
       title("")

   
***********************************************************************
* 	PART 9: 	Export Image  
***********************************************************************
graph export "event_study.png", replace width(2400) height(1800)   

graph export "event_study.pdf", replace 