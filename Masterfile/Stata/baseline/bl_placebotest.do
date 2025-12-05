**********************************************************************
* 			Baseline: Placebo Test
*												  
***********************************************************************
*																	  
*	PURPOSE: 	Conduct a permutation test (Placebo Test) to validate the 
*       		robustness of the DID results. This creates a "null distribution"
*      			of coefficients by randomly shuffling the treatment variable
*       		and checks if the actual coefficient is an outlier.						  
*																	  
*	OUTLINES:	PART 0: Import data
*				PART 1: Baseline regression & Permutation test
*				PART 2: Visualization (Density Plot)
*				PART 3: Export results  
*																  
*	Authors:  	Qianye Shi, Victoria Podovsovnik
*	Research support: 
*	ID variable: 		  					  
*	Requires: 	  										  
***********************************************************************
* 	PART 0: 	import data		  
***********************************************************************
use "data_after_cleaning.dta", clear

***********************************************************************
* 	PART 1: 	Main Regression & Permutation Test
***********************************************************************

* 1. Run the baseline DID regression to get the actual coefficient
*    - Dependent var: ln_NO2
*    - Fixed Effects: site (sitenum), day-of-week (dow), month
*    - Standard Errors: Clustered by site
reghdfe ln_NO2 treatment_post temp windspeed winddirection pressure rh precipitation ln_cloudfraction is_holiday, absorb(sitenum dow month) vce(cluster sitenum)
estimates store main_did


* 2. Run the Permutation Test
*    - Randomly shuffles 'treatment_post' variable 588 times (reps)
*    - Re-estimates the regression each time
*    - Saves the beta coefficients and standard errors to 'stimulations.dta'
*    - seed(1008) ensures replicability

// ssc install permute // Uncomment if not installed

permute treatment_post beta=_b[treatment_post] se=_se[treatment_post] df=e(df_r), reps(588) seed(1008) saving("stimulations.dta"): reghdfe ln_NO2 treatment_post temp windspeed winddirection pressure rh precipitation ln_cloudfraction is_holiday, absorb(sitenum dow month ) vce(cluster sitenum)

* Load the simulation results containing the placebo coefficients
use "stimulations.dta", clear

***********************************************************************
* 	PART 2: 	Visualization (Density Plot)
***********************************************************************
// ssc install dpplot // Uncomment if not installed

* Change delimiter to semicolon for cleaner multi-line graph code
#delimit ;

dpplot beta, 
  
    xline(-0.0961978, lcolor(cranberry) lpattern(dash) lwidth(medthick))
    xline(0, lcolor(gs6) lpattern(solid) lwidth(medium))
    
    color(navy%50) recast(area)
    lcolor(navy) lwidth(medium)

    xtitle("2×2 DD Estimate", size(small))
    xlabel(-0.10(0.02)0.10, format(%4.2f) labsize(vsmall))
    

    ytitle("Density", size(small))
    ylabel(0(50)150, format(%3.0f) labsize(vsmall) angle(horizontal) nogrid)
    

    legend(order(1 "Placebo estimates" 
                 2 "True effect (β̂=-0.096)" 
                 3 "Null (β=0)")
           position(2) ring(0) cols(1) size(vsmall)
           region(lcolor(gs12) fcolor(white%90) lwidth(vthin))
           symxsize(*.6) rowgap(*.5))
    

    note("Notes: Dashed line shows actual treatment effect; solid line indicates null hypothesis.",size(vsmall))

    graphregion(color(white) margin(small))
    plotregion(lcolor(black) lwidth(thin) margin(small))
    
    scheme(s1mono) ;

#delimit cr

***********************************************************************
* 	PART 3: 	Export Figures
***********************************************************************
* Save the graph in PNG and EPS formats
graph export "placebo_paper.png", replace width(2400) height(1800)
graph export "placebo_paper.eps", replace
