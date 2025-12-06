**********************************************************************
* 			Baseline: Descriptive statistics
*												  
***********************************************************************
*																	  
*	PURPOSE: 								  
*																	  
*	OUTLINE: 	PART 1: Descriptive statistics  
*				PART 2: Export the file
*				Part 3: Descriptive Statistics by Site Type (Comparison View)
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

logout, save(Descriptive statistics) word replace: tabstat ln_NO2 cloudfraction temperature windspeed winddirection pressure rh precipitation ln_cloudfraction is_holiday, s(count mean sd min max) f(%12.3f)
	

*======================================================================
* Part 3: Descriptive Statistics by Site Type (Comparison View)
*======================================================================
* Purpose: Generate a comparison table where columns are site types and cells report Mean (SD)
*----------------------------------------------------------------------

* 1. Prepare variable list
local vars ln_NO2 temperature windspeed winddirection pressure rh precipitation ln_cloudfraction is_holiday

* 2. Loop to calculate statistics for each site type and store them
eststo clear // Clear previous stored estimates
levelsof sitetype, local(sites) // Get all unique site type names

foreach t in `sites' {
    * Handle spaces in names (e.g., Urban Background -> Urban_Background) for storage naming
    local store_name = subinstr("`t'", " ", "_", .)
    
    * Calculate descriptive statistics for this specific site type
    quietly estpost summarize `vars' if sitetype == "`t'"
    
    * Store the results, setting the column title as the site type name
    eststo `store_name', title("`t'")
}

* 3. Export table (Word/RTF format)
esttab _all using "$output/Table2_Desc_by_SiteType.rtf", ///
    replace ///
    main(mean %9.3f) aux(sd %9.3f) ///  // Display format: Mean (Standard Deviation)
    label ///                           // Use variable labels instead of variable names
    nostar ///                          // No significance stars for descriptive statistics
    title("Table 2: Descriptive Statistics by Site Type") ///
    mtitle ///                          // Use the Title of each column (i.e., the site type)
    addnote("Notes: Table reports Mean and Standard Deviation (in parentheses)." ///
            "Sample includes all observations from 2022-2024.")
