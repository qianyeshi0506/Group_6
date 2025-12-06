***********************************************************************
* MASTER FILE: London ULEZ Expansion Analysis (Group 6)
* Project: Impact of Environmental Policy on NO2 Concentration
***********************************************************************
*
*	PURPOSE: 	
*		This script serves as the "Command Center" for the entire project.
*		It runs all analysis steps in a sequential, reproducible manner:
*		from raw data cleaning to final regression tables and plots.
*
*	AUTHORS: 	Qianye Shi, Victoria Podovsovnik
*	VERSION: 	Stata 17
*
*	CONTENTS:
*		PART 1: Environment Settings & Package Management
*		PART 2: Dynamic Path Configuration (User-agnostic setup)
*		PART 3: Data Preparation Pipeline (Clean -> Merge -> Generate)
*		PART 4: Descriptive Statistics (Summary Tables)
*		PART 5: Causal Inference (Event Study & DiD Regression)
*		PART 6: Robustness Checks (Placebo Tests)
*
***********************************************************************

*======================================================================
* PART 1: Set standard settings & install packages
*======================================================================
* 1.1 Environment Setup
version 17              // Enforce Stata version 17 to ensure backward compatibility.
clear all               // Clear memory to prevent conflicts with previous data.
set more off            // Disable the "more" pause to allow continuous execution.
set varabbrev off       // Disable variable abbreviation to avoid ambiguity/errors.
set scheme s1mono       // Set graphical scheme to "s1mono" (clean, black & white) 
                        // suitable for academic publication.

* 1.2 Automated Package Installation
* This block checks if required user-written commands are installed.
* If not, it installs them automatically from SSC.
local packages winsor2 reghdfe ftools estout coefplot parmest dpplot
foreach p of local packages {
	capture which `p'         // Check if package exists
	if _rc != 0 {             // If return code is not 0 (package missing)
		display as result "Installing package: `p'..."
		ssc install `p', replace
	}
}

*======================================================================
* PART 2: Prepare dynamic folder paths & globals
*======================================================================
* This section allows multiple users to run the same code without changing paths.
* It detects the computer's username (`c(username)`) and sets the root directory accordingly.

if "`c(username)'" == "Administrator" { 
	* Example for a generic administrator account
	global root "C:/Users/Administrator/Documents/ULEZ_Project"
}
else if "`c(username)'" == "ninja" { 
	* USER: Please update "Your_Actual_Username" with your machine's username.
	* USER: Update the path below to your local project folder.
	global root "F:/Onedrive映射/1kcl/ESG/7QQMM906 Environmental Economics/Group Assessment"
}
else {
	* Safety catch: Stops execution if the user is not recognized.
	display as error "Error: User `c(username)' not configured in Master File Part 2."
	exit
}

* Define global macros for sub-directories to keep code clean.
global code 	"$root/Code"      // Location of do-files
global data 	"$root/Data"      // Location of datasets (Raw & Clean)
global output 	"$root/Output"    // Location for saving Tables & Figures

*======================================================================
* PART 3: Data Preparation Pipeline
*======================================================================
* The flags `if (1)` allow you to toggle sections on/off. 
* Set to `if (0)` to skip a section (e.g., if cleaning is already done).

* 3.1 Data Cleaning
* TASK: Import raw CSVs, handle missing values, and standardize formats.
if (1) {
	noisily display as text ">>> Step 3.1: Running Data Cleaning..."
	do "$code/bl_cleaning.do"
}

* 3.2 Data Merging
* TASK: Merge pollution data with meteorological data and site classifications.
if (1) {
	noisily display as text ">>> Step 3.2: Running Data Merge..."
	do "$code/bl_merge.do"
}

* 3.3 Variable Generation
* TASK: Construct key analysis variables:
* - Log transformation of NO2 (ln_NO2)
* - DiD indicators: Treatment (Inner London), Post (After Aug 2023)
* - Interaction term: treatment * post
* DEPENDENCY: Must run AFTER merge.
if (1) {
	noisily display as text ">>> Step 3.3: Generating Variables..."
	do "$code/bl_generate.do"
}

*======================================================================
* PART 4: Descriptive Statistics
*======================================================================
* TASK: Generate Summary Statistics Table (e.g., Mean, SD, Min, Max).
* OUTPUT: Saves formatted tables to the Output folder.
if (1) {
	noisily display as text ">>> Step 4: Generating Descriptive Statistics..."
	do "$code/bl_descriptive statistics.do"
}

*======================================================================
* PART 5: Main Analysis
*======================================================================

* 5.1 Event Study (Parallel Trends Test)
* TASK: Estimate dynamic treatment effects (Leads and Lags).
* PURPOSE: To visually verify the "Parallel Trends" assumption required for DiD.
* OUTPUT: Saves "event_study.png" to the Output folder.
if (1) {
	noisily display as text ">>> Step 5.1: Running Event Study..."
	do "$code/bl_eventstudy.do"
}

* 5.2 Main Regression Analysis
* TASK: Run Difference-in-Differences (DiD) models using `reghdfe`.
* Includes heterogeneity analysis by Site Type (Roadside, Urban, etc.).
* OUTPUT: Saves regression tables (e.g., "full_regression_table1.rtf").
if (1) {
	noisily display as text ">>> Step 5.2: Running Main Regressions..."
	do "$code/bl_regression.do"
}

*======================================================================
* PART 6: Robustness Checks
*======================================================================

* 6.1 Placebo Test
* TASK: Conduct a Permutation Test (randomly assigning treatment).
* NOTE: This step is computationally intensive (e.g., 500+ repetitions).
* Set `if (0)` during drafting/debugging to save time.
if (1) {
	noisily display as text ">>> Step 6: Running Placebo Test..."
	do "$code/bl_placebotest.do"
}

* End of execution
display as result ">>> MASTER FILE EXECUTION COMPLETED SUCCESSFULLY. <<<"
***********************************************************************