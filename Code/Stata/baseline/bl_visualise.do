**********************************************************************
* 			Baseline: Visualise baseline data
*											  
***********************************************************************
*																	  
*	PURPOSE: 								  
*																	  
*	OUTLINE: 	PART 1: Time Series Evolution of NO2 (Weekly Aggregation)		  
*				PART 2: Cross-Sectional Comparisons (Inner vs. Outer London)			  
*				PART 3: Facet Grid Plot (Time Series by Site Type) 
*				PART 4: DiD Group Comparison (Pre/Post x Treatment/Control)	  
*				PART 5: Scatter Plots of Key Relationships (Binned Means)  						  
*																	  
*	Authors:  	
*	ID variable: 		  					  
*	Requires: 	  							

*======================================================================
* 	Part 1: Time Series Evolution of NO2 (Weekly Aggregation)
*======================================================================
* Objective: Display the evolution of NO2 concentration over time for
*            treatment and control g aroups.
* Strategy:  Aggregate to weekly means to eliminate high-frequency daily
*            noise, visually highlighting trend differences pre/post policy.
*----------------------------------------------------------------------

* 1. Prepare Data
use "data_after_cleaning.dta", clea

* Set plot scheme (Concise black & white style preferred by top journals)
set scheme s1mono
graph set window fontface "Times New Roman" // Set serif font (if supported)

* 2. Generate Weekly Time Variable (Weekly Aggregation)
* Daily data volatility is high; plotting it directly creates a messy "EKG" look.
* Top journals typically display trends smoothed at the weekly or monthly level.
gen week = wofd(date)
format week %tw

* 3. Calculate Mean NO2 Concentration by Week and Group
collapse (mean) mean_no2=ln_NO2, by(week treatment)

* 4. Prepare Labels and Auxiliary Lines
* Policy date: August 29, 2023 -> Convert to the corresponding week
local policy_date = wofd(date("2023-08-29", "YMD"))

* Define labels
label define trt_lab 0 "Control (Outer London)" 1 "Treatment (Inner London)"
label values treatment trt_lab

* 5. Plotting (Time Series Plot)
* Tip: Overlay two line plots, setting different patterns and colors for each.
twoway (line mean_no2 week if treatment == 1, /// Treatment: Solid line, black
            lcolor(black) lwidth(medium) lpattern(solid)) ///
       (line mean_no2 week if treatment == 0, /// Control: Dashed line, gray
            lcolor(gs8) lwidth(medium) lpattern(dash)), ///
       /// --- Auxiliary Lines and Annotations ---
       xline(`policy_date', lcolor(black) lwidth(thin) lpattern(shortdash)) /// Vertical policy line
       text(-9.5 `policy_date' "ULEZ Expansion", place(e) size(small)) /// Add text annotation
       /// --- Axes and Titles ---
       xtitle("Date (Weekly Average)", size(medium)) ///
       ytitle("Log NO2 Concentration (µg/m³)", size(medium)) ///
       title("Evolution of NO2 Concentration Over Time") ///
       subtitle("Treatment vs. Control Groups (2022-2024)") ///
       /// --- Legend Settings ---
       legend(order(1 "Treatment (Inner London)" 2 "Control (Outer London)") ///
              ring(0) pos(7) region(lcolor(none)) rows(2)) /// Legend inside bottom-left, no border
       /// --- Overall Region ---
       graphregion(color(white)) ///
       ylabel(, angle(0) format(%9.1f))

* 6. Export High-Resolution Images
* PNG for preview (Word), EPS/PDF for submission (LaTeX)
graph export "$output/Fig_TimeSeries_Trend.png", replace width(3000)
graph export "$output/Fig_TimeSeries_Trend.pdf", replace


*======================================================================
* 	Part 2: Cross-Sectional Comparisons (Inner vs. Outer London)
*======================================================================
* Objective: Compare NO2 levels between the Treatment (Inner) and 
* Control (Outer) regions.
* Context:   Since the dataset is London-only, "Regional Comparison" 
* refers to the spatial split defined by the ULEZ boundary.
*----------------------------------------------------------------------

* 1. Prepare Data
use "data_after_cleaning.dta", clear

* Set Academic Style
set scheme s1mono
graph set window fontface "Times New Roman"

* Label the Treatment variable for clarity in graphs
label define trt_lbl 0 "Outer London (Control)" 1 "Inner London (Treated)"
label values treatment trt_lbl

*----------------------------------------------------------------------
* Figure A: Bar Chart with 95% Confidence Intervals (Region Comparison)
* Purpose: Show the statistical difference in means between regions.
*----------------------------------------------------------------------
graph bar ln_NO2, over(treatment, label(labsize(small))) ///
    asyvars bar(1, fcolor(gs12) lcolor(black)) bar(2, fcolor(gs6) lcolor(black)) ///
    blabel(bar, format(%9.2f) pos(center) color(white)) ///
    ytitle("Mean Log NO2 Concentration (µg/m³)") ///
    title("Regional Comparison: Inner vs. Outer London") ///
    subtitle("Average NO2 Levels with 95% Confidence Intervals") ///
    legend(off) ///
    graphregion(color(white)) ///
    name(Fig_Region_Bar, replace)

* Note: To add explicit Error Bars to a bar chart requires 'twoway bar' + 'rcap'.
* The code below generates a publication-quality version with CI.

preserve
    collapse (mean) mean_no2=ln_NO2 (sd) sd_no2=ln_NO2 (count) n=ln_NO2, by(treatment)
    gen ci_hi = mean_no2 + 1.96 * (sd_no2 / sqrt(n))
    gen ci_lo = mean_no2 - 1.96 * (sd_no2 / sqrt(n))

    twoway (bar mean_no2 treatment, barwidth(0.5) fcolor(gs12) lcolor(black)) ///
           (rcap ci_hi ci_lo treatment, lcolor(black)), ///
           xlabel(0 "Outer London" 1 "Inner London", valuelabel) ///
           ytitle("Mean Log NO2 Concentration") ///
           xtitle("Region") ///
           title("Cross-Sectional Comparison of NO2 Levels") ///
           note("Error bars indicate 95% Confidence Intervals.") ///
           graphregion(color(white))
           
    graph export "$output/Fig_CrossSection_Region_Bar.png", replace width(2400)
restore

*----------------------------------------------------------------------
* Figure B: Kernel Density Estimate (Distributional Differences)
*----------------------------------------------------------------------
twoway (kdensity ln_NO2 if treatment == 1, lcolor(black) lpattern(solid) lwidth(medium)) ///
       (kdensity ln_NO2 if treatment == 0, lcolor(gs8) lpattern(dash) lwidth(medium)), ///
       ytitle("Density", size(small)) ///                    
       xtitle("Log NO2 Concentration", size(small)) ///      
       ylabel(, labsize(small)) ///                         
       xlabel(, labsize(small)) ///                         
       title("Distribution of NO2: Inner vs. Outer London", size(medium)) /// 
       legend(label(1 "Inner London (Treated)") label(2 "Outer London (Control)") ///
              size(small) ///                               
              ring(0) pos(2) region(lcolor(none))) ///
       graphregion(color(white))

graph export "$output/Fig_CrossSection_Region_Density.png", replace width(2400)

*======================================================================
* 	Part 3: Facet Grid Plot (Time Series by Site Type)
*======================================================================
* Objective: Compare the evolution of NO2 levels between Inner and Outer
* London across different monitoring site types.
* Method:    Use 'by(siteype_num)' to create a wrap/facet grid layout.
*----------------------------------------------------------------------

*======================================================================
* 	Part 4 : DiD Group Comparison (Pre/Post x Treatment/Control)
*======================================================================
* Objective: Visualise the Difference-in-Differences setup.
* Compare mean NO2 levels across 4 groups:
* 1. Control Group (Pre)
* 2. Control Group (Post)
* 3. Treated Group (Pre)
* 4. Treated Group (Post)
*----------------------------------------------------------------------

* 1. Prepare Data
use "data_after_cleaning.dta", clear
set scheme s1mono
graph set window fontface "Times New Roman"

* 2. Calculate Means and Confidence Intervals (2x2 Groups)
collapse (mean) mean_no2=ln_NO2 (sd) sd_no2=ln_NO2 (count) n=ln_NO2, by(treatment post)

* Calculate 95% CI
gen se = sd_no2 / sqrt(n)
gen ci_hi = mean_no2 + 1.96 * se
gen ci_lo = mean_no2 - 1.96 * se

* 3. Generate Plotting Coordinates
* We need 4 bars. To create a visual gap between regions, we skip pos 3.
* Outer London (Control): Pos 1 (Pre), Pos 2 (Post)
* Inner London (Treated): Pos 4 (Pre), Pos 5 (Post)
gen bar_pos = .
replace bar_pos = 1 if treatment==0 & post==0
replace bar_pos = 2 if treatment==0 & post==1
replace bar_pos = 4 if treatment==1 & post==0
replace bar_pos = 5 if treatment==1 & post==1

* 4. Plotting (Color by Time Period)
twoway ///
    /* --- Pre-Policy Bars (Light Grey) --- */ ///
    (bar mean_no2 bar_pos if post==0, ///
        barwidth(0.8) fcolor(gs12) lcolor(black)) ///
    /* --- Post-Policy Bars (Black) --- */ ///
    (bar mean_no2 bar_pos if post==1, ///
        barwidth(0.8) fcolor(black) lcolor(black)) ///
    /* --- Error Bars (CI) --- */ ///
    (rcap ci_hi ci_lo bar_pos, lcolor(black)), ///
    /// --- Axis Settings ---
    xlabel(1.5 "Outer London (Control)" 4.5 "Inner London (Treated)", /// 
           noticks labsize(medium)) /// X-axis labels Regions only
    xtitle("") ///
    ytitle("Mean Log NO2 Concentration") ///
    title("Impact of ULEZ Expansion: Pre vs. Post") ///
    /// --- Legend Settings (The Fix) ---
    legend(order(1 "Pre-Policy (Before Aug 2023)" 2 "Post-Policy (After Aug 2023)") ///
           ring(0) pos(1) region(lcolor(black)) rows(2)) /// Legend inside top-right
    graphregion(color(white))

* 5. Export
graph export "$output/Fig_DiD_Bar_Corrected.png", replace width(2400)


*======================================================================
* Part 5 : Scatter Plots of Key Relationships (Binned Means)
*======================================================================
* Objective: Explore relationships between NO2 and meteorological controls.
* Strategy:  Use 'Binned Scatter' approach. Instead of plotting 60k+ points,
* we group x-axis variables into bins and plot the mean y-axis.
* This reveals the true underlying relationship (Linear/Non-linear).
*----------------------------------------------------------------------

* 1. Prepare Data
use "data_after_cleaning.dta", clear
set scheme s1mono
graph set window fontface "Times New Roman"

*----------------------------------------------------------------------
* Plot A: NO2 vs. Wind Speed (The Dispersion Effect)
* Expectation: Negative Correlation (Higher wind -> Lower pollution)
*----------------------------------------------------------------------
preserve
    * 1. Create 50 bins for Windspeed
    * xtile cuts the variable into N groups of equal size
    xtile wind_bin = windspeed, nq(50)
    
    * 2. Calculate means within each bin
    collapse (mean) mean_no2=ln_NO2 (mean) mean_wind=windspeed, by(wind_bin)
    
    * 3. Plot Scatter + Linear Fit
    twoway (scatter mean_no2 mean_wind, ///
                msymbol(circle_hollow) mcolor(black) msize(medium)) /// 
           (lfit mean_no2 mean_wind, ///
                lcolor(black) lwidth(medium)), ///
           ytitle("Mean Log NO2 Concentration") ///
           xtitle("Wind Speed (m/s)") ///
           title("Relationship: NO2 vs. Wind Speed") ///
           subtitle("Binned Scatter Plot (n=50 bins)") ///
           legend(order(1 "Binned Means" 2 "Linear Fit") ring(0) pos(1)) ///
           note("Each point represents the average of ~1,200 observations.") ///
           graphregion(color(white))
           
    graph export "$output/Fig_Scatter_Wind_NO2.png", replace width(2400)
restore

*----------------------------------------------------------------------
* Plot B: NO2 vs. Temperature (The Chemical/Emission Effect)
* Expectation: Often Positive or U-shaped
*----------------------------------------------------------------------
preserve
    * 1. Create 50 bins for Temperature
    xtile temp_bin = temperature, nq(50)
    
    * 2. Calculate means
    collapse (mean) mean_no2=ln_NO2 (mean) mean_temp=temperature, by(temp_bin)
    
    * 3. Plot Scatter + Quadratic Fit (qfit)
    * We use qfit because temperature effects are often non-linear
    twoway (scatter mean_no2 mean_temp, ///
                msymbol(circle_hollow) mcolor(black) msize(medium)) ///
           (qfit mean_no2 mean_temp, ///
                lcolor(black) lwidth(medium)), ///
           ytitle("Mean Log NO2 Concentration") ///
           xtitle("Temperature (K)") ///
           title("Relationship: NO2 vs. Temperature") ///
           subtitle("Binned Scatter Plot (n=50 bins)") ///
           legend(order(1 "Binned Means" 2 "Quadratic Fit") ring(0) pos(4)) ///
           graphregion(color(white))
           
    graph export "$output/Fig_Scatter_Temp_NO2.png", replace width(2400)
restore
