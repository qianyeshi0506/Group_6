
import delimited "/Users/irenepodovsovnik/Downloads/NO2_Meteo_ALL_Data_2022-2024.csv"

//Treat
gen Inner_ULEZ=1 if region=="Inner"
drop Inner_ULEZ 
gen treatment=1 if region=="Inner"
replace treatment=0 if treatment==.

//numeric date
gen date_numeric = date(date, "YMD") if !missing(date)
format date_numeric %td
drop date
rename date_numeric date

//Post
gen post=0
replace post=1 if date >= date("2023-08-29", "YMD")

//Interation term
gen treatment_post= treatment*post

//ln_NO2
gen ln_NO2= ln(no2) if no2>0
drop ln_NO2 
gen ln_NO2= ln(no2)


//Sitenum
encode sitecode, generate(sitenum)

//In_cloud
gen ln_cloudfraction=ln(cloudfraction)
drop if cloudfraction==.
drop if ln_cloudfraction ==.


//Is holiday?
gen is_holiday = 0
replace is_holiday = 1 if date == date("2023-01-02", "YMD") |date == date("2023-04-10", "YMD") | date == date("2023-05-01", "YMD") |date == date("2023-05-08", "YMD") | date == date("2023-05-29", "YMD") |date == date("2023-08-28", "YMD") |date == date("2023-12-25", "YMD") |date == date("2023-12-26", "YMD")

replace is_holiday = 1 if date == date("2024-01-01", "YMD") |date == date("2024-03-29", "YMD") |date == date("2024-04-01", "YMD") |date == date("2024-05-06", "YMD") |date == date("2024-05-27", "YMD") |date == date("2024-08-26", "YMD") |date == date("2024-12-25", "YMD") |date == date("2024-12-26", "YMD")

 replace is_holiday = 1 if date == date("2022-08-29", "YMD") |date == date("2022-09-19", "YMD") |date == date("2022-12-26", "YMD") |date == date("2022-12-27", "YMD")
 
label variable is_holiday "UK Bank Holiday (0=No, 1=Yes)"

//time dummy
gen year = year(date)
gen month = month(date)
gen dow = dow(date)
gen doy = doy(date)
reghdfe ln_NO2 treatment_post temp windspeed winddirection pressure rh precipitation ln_cloudfraction is_holiday ,absorb(sitenum dow month) vce(cluster sitenum)

//Winsor
ssc install winsor2
winsor2 ln_NO2 temp windspeed winddirection pressure rh precipitation ln_cloudfraction, cuts(1 99) replace

//Drop
drop if missing(ln_NO2)|missing(temperature)|missing(windspeed)|missing(winddirection)|missing(pressure)|missing(rh)|missing(precipitation)|missing(ln_cloudfraction)

//penal 
xtset sitenum date

//regression result
reghdfe ln_NO2 treatment_post temp windspeed winddirection pressure rh precipitation ln_cloudfraction is_holiday ,absorb(sitenum dow month) vce(cluster sitenum)

//Paralle trend test
//Judgement
gen judgment= ym(year(date), month(date)) - ym(2023, 8)

//pre_* & las_*
forvalues i = 11(-1)1 {
    gen pre_`i'=(judgment ==-`i' & treatment ==1)
}
gen current = ( judgment ==0 & treatment ==1)
forvalues i = 11(-1)1 {
    gen las_`i' = (judgment ==`i' & treatment ==1)
}

