clear all
set more off

* ============================================================
* DATASET_FILTERED.dta
* ============================================================
* Bilateral country-year gravity dataset with EPU, lags, and
* remoteness indexes. Sample: EPU countries, 2004–2019,
* 3-year intervals. REER excluded.
* ============================================================


* ============================================================
* 1. COUNTRY NAME HARMONIZATION
* ============================================================
capture program drop harmonize_country
program define harmonize_country
    replace country = "USA"                if country == "US" | country == "United States"
    replace country = "United Kingdom"     if country == "UK"
    replace country = "Rep. of Korea"      if country == "Korea"
    replace country = "Russian Federation" if country == "Russia"
end


* ============================================================
* 2. EPU DATA PREPARATION
* ============================================================
import excel "$ROOT/Original_Datasets/EPU_index_dataset.xlsx", firstrow clear

destring Year, replace
drop AB AC AD AE AF AG AH AI AJ GEPU_current GEPU_ppp SCMPChina MainlandChina
duplicates drop Year Month, force

foreach c in Australia Brazil Canada Chile China France Germany Greece India ///
             Ireland Italy Japan Korea Mexico Pakistan Russia Singapore ///
             Spain Sweden UK US {
    rename `c' EPU_`c'
}

reshape long EPU_, i(Year Month) j(country) string
rename EPU_ epu
drop if missing(epu)

rename Year year
destring year, replace force
drop if year < 2003 | year >= 2020

harmonize_country
collapse (mean) epu, by(country year)

gen cname_i = country
gen cname_j = country

save "$ROOT/Modified_Datasets/EPU.dta", replace


* ============================================================
* 3. MERGE EPU INTO GRAVITY DATA
* ============================================================
use "$ROOT/Original_Datasets/Gravity_M2IT.dta", clear

merge m:1 year cname_i using "$ROOT/Modified_Datasets/EPU.dta", keepusing(epu) nogen
rename epu epu_i

merge m:1 year cname_j using "$ROOT/Modified_Datasets/EPU.dta", keepusing(epu) nogen
rename epu epu_j

drop if missing(epu_i) | missing(epu_j)


* ============================================================
* 4. PANEL IDENTIFIERS
* ============================================================
egen exp_time = group(cname_i year)
egen imp_time = group(cname_j year)
egen pair_id  = group(cname_i cname_j)


* ============================================================
* 5. VARIABLE TRANSFORMATIONS
* ============================================================
drop if missing(trade)

gen lngdp_i  = ln(gdp_i)
gen lngdp_j  = ln(gdp_j)
gen ln_distw = ln(distw)
gen lnepu_i  = ln(epu_i)
gen lnepu_j  = ln(epu_j)
gen lnpop_i  = ln(pop_i)
gen lnpop_j  = ln(pop_j)

gen both_wto = (wto_o == 1 & wto_d == 1)
gen both_eu  = (eu_o  == 1 & eu_d  == 1)


* ============================================================
* 6. LAG CONSTRUCTION
* ============================================================

preserve
keep cname_i year lnepu_i
duplicates drop
bysort cname_i (year): gen lnepu_i_l2 = lnepu_i[_n-2]
bysort cname_i (year): gen lnepu_i_l4 = lnepu_i[_n-4]
tempfile lag_i
save `lag_i'
restore
merge m:1 cname_i year using `lag_i', keepusing(lnepu_i_l2 lnepu_i_l4) nogen

preserve
keep cname_j year lnepu_j
duplicates drop
bysort cname_j (year): gen lnepu_j_l2 = lnepu_j[_n-2]
bysort cname_j (year): gen lnepu_j_l4 = lnepu_j[_n-4]
tempfile lag_j
save `lag_j'
restore
merge m:1 cname_j year using `lag_j', keepusing(lnepu_j_l2 lnepu_j_l4) nogen

preserve
keep cname_i cname_j year rta
duplicates drop
bysort cname_i cname_j (year): gen rta_l2 = rta[_n-2]
bysort cname_i cname_j (year): gen rta_l4 = rta[_n-4]
tempfile lag_rta
save `lag_rta'
restore
merge m:1 cname_i cname_j year using `lag_rta', keepusing(rta_l2 rta_l4) nogen


* ============================================================
* 7. REMOTENESS INDEXES
* ============================================================

* Outward remoteness
preserve
keep cname_i cname_j year distw gdp_j
drop if cname_i == cname_j

gen lndist = ln(distw)
bysort cname_i year: egen sum_gdp_j = total(gdp_j)
gen w_gdp_j = gdp_j / sum_gdp_j
gen rem_comp_o = w_gdp_j * lndist
bysort cname_i year: egen remoteness_o = total(rem_comp_o)

keep cname_i year remoteness_o
duplicates drop
tempfile rem_o
save `rem_o'
restore
merge m:1 cname_i year using `rem_o', nogen

* Inward remoteness
preserve
keep cname_i cname_j year distw gdp_i
drop if cname_i == cname_j

gen lndist = ln(distw)
bysort cname_j year: egen sum_gdp_i = total(gdp_i)
gen w_gdp_i = gdp_i / sum_gdp_i
gen rem_comp_i = w_gdp_i * lndist
bysort cname_j year: egen remoteness_i = total(rem_comp_i)

keep cname_j year remoteness_i
duplicates drop
tempfile rem_i
save `rem_i'
restore
merge m:1 cname_j year using `rem_i', nogen


* ============================================================
* 8. FINAL SAMPLE AND SAVE
* ============================================================
keep if inlist(year, 2004, 2007, 2010, 2013, 2016, 2019)

save "$ROOT/Final_Datasets/Dataset_Filtered.dta", replace
