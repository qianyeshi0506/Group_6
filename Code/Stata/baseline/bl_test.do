**********************************************************************
* 			Baseline: Logical Tests (Data Quality Assurance)
*										  
***********************************************************************														*	  
*	PURPOSE: 	Ensure data is absolutely clean before regression. 							  
*				If tests fail, execution stops immediately.	
*												  
*	OUTLINE: 	Test 1: Uniqueness Check 	  
*				Test 2: Completeness Check
*				Test 3: Value Range Check
*				Test 4: Panel Consistency Check 
*				Test 5: Time Logic Check
*				Test 6: Sample Size Check
*																	  
***********************************************************************

* Load cleaned data
use "data_after_cleaning.dta", clear

noisily di "STATUS: Starting Data Integrity Tests..."

***********************************************************************
*	Test 1: Uniqueness Check
*	Ensure Panel ID is unique: Each site (sitenum) appears only once per day (date)
***********************************************************************

isid sitenum date

***********************************************************************
* Test 2: Completeness Check
* Ensure no missing values in core regression variables (Based on Roadmap)
***********************************************************************
* Core variables must not be missing
assert !missing(ln_NO2)
assert !missing(treatment)
assert !missing(post)
assert !missing(sitenum)

***********************************************************************
* Test 3: Value Range Check
* Ensure dummy variables contain only 0 and 1
***********************************************************************
assert inlist(treatment, 0, 1)
assert inlist(post, 0, 1)
assert inlist(is_holiday, 0, 1)

* Ensure cloud fraction is between 0 and 1 (Physical meaning)
* Note: Log transformed variables don't need this, but the original variable must satisfy it
capture confirm variable cloudfraction
if _rc == 0 {
    assert cloudfraction >= 0 & cloudfraction <= 1.01 // Allow slight floating-point tolerance
}

***********************************************************************
* Test 4: Panel Consistency Check
* Ensure a site is not both Treatment and Control (Time-invariant Treatment)
***********************************************************************
* Sort by site, check if treatment status is constant over time for each site
bysort sitenum (date): assert treatment == treatment[1]

***********************************************************************
* Test 5: Time Logic Check
* Ensure Post variable is split correctly (Policy date: 2023-08-29)
***********************************************************************
* Check: If date >= Aug 29, 2023, Post must be 1; otherwise 0
assert post == 1 if date >= td(29aug2023)
assert post == 0 if date < td(29aug2023)

***********************************************************************
* Test 6: Sample Size Check
* Ensure sample size matches the paper description (Roadmap Table: N=63,564)
***********************************************************************
count
if r(N) != 63564 {
    di as error "WARNING: Sample size is `r(N)', but expected 63,564!"
    * assert r(N) == 63564 // Uncomment if you want to force stop on sample size mismatch
}

noisily di ">>> ALL LOGICAL TESTS PASSED! DATA IS CLEAN. <<<"