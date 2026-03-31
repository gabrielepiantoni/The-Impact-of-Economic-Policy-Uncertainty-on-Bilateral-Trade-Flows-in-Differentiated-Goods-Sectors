use "$ROOT/Final_Datasets/Dataset_Filtered.dta", clear


* ============================================================
* TRADITIONAL GRAVITY ESTIMATION
* ============================================================
* PPML gravity regressions without exporter-time and importer-time
* fixed effects. Estimation run separately for total trade and
* BEC components (capital, intermediate, consumption goods).
* ============================================================

cap erase "$ROOT/Results/Traditional_Gravity.xls"

local trade_vars "trade cap inter conso"

foreach var of local trade_vars {

    ppmlhdfe `var' ///
        lngdp_i lngdp_j ///
        ln_distw ///
        lnepu_i lnepu_i_l2 lnepu_i_l4 ///
        lnepu_j lnepu_j_l2 lnepu_j_l4 ///
        rta lnpop_i lnpop_j ///
        wto_o wto_d ///
        contig ///
        comcol ///
        col ///
        remoteness_o remoteness_i ///
        if cname_i != cname_j, ///
        cluster(pair_id)

    outreg2 using "$ROOT/Results/Traditional_Gravity.xls", ///
        excel append ctitle(`var') dec(3) se nocons
}
