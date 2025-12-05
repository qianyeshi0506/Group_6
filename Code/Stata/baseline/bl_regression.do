**********************************************************************
* 			Baseline: Regression analysis
*												  
***********************************************************************
*																	  
*	PURPOSE: 								  
*																	  
*	OUTLINE: 	PART 1: Main DID	  
*				PART 2: Heterogeneity analysis by Site Type		  
*				PART 3: Export table  
*																  
*	Authors:  	Qianye Shi, Victoria Podovsovnik
*	Research support: 
*	ID variable: 		  					  
*	Requires: 	  										  
***********************************************************************
* 	PART 1: 	Main DID		  
***********************************************************************
use "data_after_cleaning.dta", replace

//Penal 
xtset sitenum date

//Regression result
reghdfe ln_NO2 treatment_post temp windspeed winddirection pressure rh precipitation ln_cloudfraction is_holiday ,absorb(sitenum dow month) vce(cluster sitenum)

***********************************************************************
* 	PART 2: 	Heterogeneity analysis by Site Type	  
***********************************************************************

* 1.Main DID
reghdfe ln_NO2 treatment_post temperature windspeed winddirection pressure rh precipitation ln_cloudfraction is_holiday, absorb(sitenum dow month) vce(cluster sitenum)
estimates store main_did

* 2. Heterogeneity by Site Type
foreach type in "Roadside" "Urban Background" "Kerbside" "Suburban" "Industrial" {
    quietly reghdfe ln_NO2 treatment_post temp windspeed winddirection pressure rh precipitation ln_cloudfraction is_holiday,  absorb(sitenum dow month) vce(cluster sitenum), if sitetype == "`type'"
    
    estimates store `=subinstr("`type'", " ", "_", .)'
}

***********************************************************************
* 	PART 3: 	Export table	  
***********************************************************************
esttab main_did Roadside Urban_Background Kerbside Suburban Industrial 
    using "full_regression_table1.rtf", 
    replace rtf 
    keep(treatment_post temperature windspeed winddirection pressure rh precipitation ln_cloudfraction ls_holiday) 
    order(treatment_post temperature windspeed winddirection pressure rh precipitation ln_cloudfraction ls_holiday) 
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) 
    mtitles("All Sites" "Roadside" "Urban BG" "Kerbside" "Suburban" "Industrial") 
    mgroups("Main did" "Heterogeneity by Site Type", 
            pattern(1 1 0 0 0 0) 
            prefix(\multicolumn{@span}{c}{) suffix(}) 
            span erepeat(\cmidrule(lr){@span})) 
    title("Table: DID Estimates and Heterogeneity by Site Type") 
    addnote("Standard errors clustered at site level in parentheses." 
            "All models include site, month, and day-of-week fixed effects." 
            "* p<0.10, ** p<0.05, *** p<0.01") 
    stats(N r2, fmt(%9.0fc %9.3f) 
          labels("Observations" "R-squared"))
    label