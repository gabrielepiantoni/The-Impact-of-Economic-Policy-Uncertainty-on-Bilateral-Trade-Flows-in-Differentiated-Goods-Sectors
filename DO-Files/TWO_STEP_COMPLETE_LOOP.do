* ============================================================
* LOOP OVER DEPENDENT VARIABLES
* ============================================================

local depvars "trade inter conso cap"

foreach y of local depvars {

    * =====================
    * FIRST STAGE: PPML
    * =====================

    use "$ROOT/Final_Datasets/Dataset_Full.dta", clear

    ppmlhdfe `y' rta if cname_i != cname_j, ///
        absorb(fe_exp=exp_time fe_imp=imp_time pair_id_fixed=pair_id, savefe) ///
        cluster(pair_id)

    outreg2 using "$ROOT/Results/First_stage_`y'.xls", ///
        excel replace ///
        ctitle(PPML_`y') ///
        dec(3) se nocons ///
        addtext("Exporter × Year FE","Yes", ///
                "Importer × Year FE","Yes", ///
                "Pair Fixed Effects","Yes") ///
        addstat("Pseudo R-squared", e(r2_p), ///
                "Observations", e(N), ///
                "Number of pairs", e(N_clust))

    save "$ROOT/Modified_Datasets/Gravity_M2IT_EPU_FE_`y'.dta", replace


    * =====================
    * SECOND STAGE: EXPORTER
    * =====================

    use "$ROOT/Modified_Datasets/Gravity_M2IT_EPU_FE_`y'.dta", clear

    preserve
    keep cname_i year fe_exp wto_o lnepu_i lnepu_i_l2 lnepu_i_l4 lnpop_i lngdp_i remoteness_o
    duplicates drop cname_i year, force
    tempfile fe_exporter
    save `fe_exporter'
    restore

    use `fe_exporter', clear
    egen id_i = group(cname_i)
    xtset id_i year

    cap erase "$ROOT/Results/SecondStage_Exporter_`y'.xls"

    reg fe_exp lngdp_i lnepu_i lnepu_i_l2 lnepu_i_l4 remoteness_o ///
        wto_o lnpop_i i.year, vce(cluster id_i)

    outreg2 using "$ROOT/Results/SecondStage_Exporter_`y'.xls", ///
        excel replace ///
        ctitle(Exporter_`y') ///
        dec(3) pval nocons ///
        addstat("Observations", e(N), ///
                "Number of countries", e(N_clust))


    * =====================
    * SECOND STAGE: IMPORTER
    * =====================

    use "$ROOT/Modified_Datasets/Gravity_M2IT_EPU_FE_`y'.dta", clear

    preserve
    keep cname_j year fe_imp lnepu_j lnepu_j_l2 lnepu_j_l4 lnpop_j wto_d lngdp_j remoteness_i
    duplicates drop cname_j year, force
    tempfile fe_importer
    save `fe_importer'
    restore

    use `fe_importer', clear
    egen id_j = group(cname_j)
    xtset id_j year

    cap erase "$ROOT/Results/SecondStage_Importer_`y'.xls"

    reg fe_imp lngdp_j lnepu_j lnepu_j_l2 lnepu_j_l4  remoteness_i ///
        wto_d lnpop_j i.year, vce(cluster id_j)

    outreg2 using "$ROOT/Results/SecondStage_Importer_`y'.xls", ///
        excel replace ///
        ctitle(Importer_`y') ///
        dec(3) pval nocons ///
        addstat("Observations", e(N), ///
                "Number of countries", e(N_clust))
}
