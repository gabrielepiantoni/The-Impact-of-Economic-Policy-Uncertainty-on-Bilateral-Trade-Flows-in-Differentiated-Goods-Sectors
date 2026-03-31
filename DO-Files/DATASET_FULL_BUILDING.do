clear all
set more off

* ============================================================
* GRAVITY_M2IT_EPU2.dta
* ============================================================
* Bilateral gravity dataset preserving the full support of
* Gravity_M2IT.dta. The dataset is augmented with EPU variables
* only. Both REER and NER are excluded by construction.
* ============================================================


* ============================================================
* 1. LOAD BASE GRAVITY DATA
* ============================================================
use "$ROOT/Original_Datasets/Gravity_M2IT.dta", clear


* ============================================================
* 2. MERGE MACRO VARIABLES
* ============================================================

* --- Economic Policy Uncertainty (EPU) ---
merge m:1 year cname_i using "$ROOT/Modified_Datasets/EPU.dta", keepusing(epu)
rename epu epu_i
drop _merge

merge m:1 year cname_j using "$ROOT/Modified_Datasets/EPU.dta", keepusing(epu)
rename epu epu_j
drop _merge


* ============================================================
* 3. PANEL IDENTIFIERS
* ============================================================
egen exp_time = group(cname_i year)
egen imp_time = group(cname_j year)
egen pair_id  = group(cname_i cname_j)


* ============================================================
* 4. VARIABLE TRANSFORMATIONS
* ============================================================
drop if missing(trade)

gen lngdp_i  = ln(gdp_i)
gen lngdp_j  = ln(gdp_j)
gen ln_distw = ln(distw)

gen lnepu_i  = ln(epu_i) if epu_i > 0
gen lnepu_j  = ln(epu_j) if epu_j > 0

gen lnpop_i  = ln(pop_i)
gen lnpop_j  = ln(pop_j)

gen both_wto = (wto_o == 1 & wto_d == 1)
gen both_eu  = (eu_o  == 1 & eu_d  == 1)


* ============================================================
* 5. LAG CONSTRUCTION
* ============================================================

* Exporter EPU lags
preserve
keep cname_i year lnepu_i
duplicates drop
bysort cname_i (year): gen lnepu_i_l2 = lnepu_i[_n-2]
bysort cname_i (year): gen lnepu_i_l4 = lnepu_i[_n-4]
tempfile lag_i
save `lag_i'
restore
merge m:1 cname_i year using `lag_i', keepusing(lnepu_i_l2 lnepu_i_l4)
drop _merge

* Importer EPU lags
preserve
keep cname_j year lnepu_j
duplicates drop
bysort cname_j (year): gen lnepu_j_l2 = lnepu_j[_n-2]
bysort cname_j (year): gen lnepu_j_l4 = lnepu_j[_n-4]
tempfile lag_j
save `lag_j'
restore
merge m:1 cname_j year using `lag_j', keepusing(lnepu_j_l2 lnepu_j_l4)
drop _merge

* RTA lags
preserve
keep cname_i cname_j year rta
duplicates drop
bysort cname_i cname_j (year): gen rta_l2 = rta[_n-2]
bysort cname_i cname_j (year): gen rta_l4 = rta[_n-4]
tempfile lag_rta
save `lag_rta'
restore
merge m:1 cname_i cname_j year using `lag_rta', keepusing(rta_l2 rta_l4)
drop _merge


* ============================================================
* 6. SAVE FINAL DATASET
* ============================================================
save "$ROOT/Final_Datasets/GRAVITY_M2IT_EPU2.dta", replace
