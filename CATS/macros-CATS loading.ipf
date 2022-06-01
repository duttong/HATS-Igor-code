#pragma rtGlobals=1		// Use modern global access method.
//#include "macros-load met data"
#include "HATS ftp data"

function LoadALLCATS()
	
	SVAR siteLst = root:G_siteLst

	string site = StrMakeOrDefault("root:G_site", "brw")
	prompt site, "Which site", popup, "ALL DATA;" + siteLst
	DoPrompt "Loading CATS data", site
	if ( v_flag )
		return -1
	endif
	
	variable i
	string s
	
	if ( cmpstr(site, "ALL DATA") == 0 )

		for( i=0; i<ItemsInList(siteLst); i+=1)
			s = StringFromList(i, siteLst)
			Load_Data(site=s, dur=1)
			Load_Data(site=s, dur=2)
			Load_Data(site=s, dur=4)
		endfor
				
	else 
		Load_Data(site=site, dur=1)
		Load_Data(site=site, dur=2)
		Load_Data(site=site, dur=4)
	endif
	
end

function  Load_Data([site, dur])
	string site
	variable dur
	
	if ( ParamIsDefault(site) )
		site = StrMakeOrDefault("root:G_site", "brw")
		dur = NumMakeOrDefault("root:G_dur", 1)
		prompt site, "Which site", popup, "brw;sum;nwr;mlo;smo;spo;_ALL_"
		prompt dur, "Duration of data", popup, "Every Point;Daily Median;Weekly Median;Monthly Median"
		DoPrompt "Loading CATS data", site, dur
		if ( v_flag )
			return -1
		endif
	endif
		
	SVAR G_site = root:G_site
	NVAR G_dur = root:G_dur
	G_site = site
	G_dur = dur

	SetDataFolder root:
	
	load_DataFUNCT(site, "_ALL_", dur, 0)
	
	if ( cmpstr(site, "_ALL_") != 0 )
		TimeSyncCATSdata(site)
	endif

	// remove CATS monte carlo fits	
	SetDataFolder root:simulation:
	bat("Killwaves /Z @", "fx_*_Ca_*")

	SetDataFolder root:
end

function load_DataFUNCT( site, mol, dur, plt )
	string site, mol
	variable dur, plt

	SVAR stations = root:G_siteLst
	SVAR G_site = root:G_site
	SVAR G_mol = root:G_mol
	SVAR G_molLst = root:G_molLst
	NVAR G_dur = root:G_dur
	NVAR G_plt = root:G_plt

	string pstr, backmol, combtest

	PathInfo CATSdata
	if (V_flag == 0)
		NewPath /M="Path to CATS experiments" CATSdata
	endif
	
	// Handle recursive calls to function
	variable inc
	
	if (cmpstr(site,"_ALL_") == 0)
	
		// loop over station list
		for (inc = 0; inc<ItemsInList(stations); inc += 1)
			site = StringFromList(inc, stations, ";")
			Load_DataFUNCT(site, mol, dur, plt)
			TimeSyncCATSdata(site)
		endfor
	
	elseif (cmpstr(mol,"_ALL_") == 0)
	
		// loop of mol list
		for (inc=0; inc<ItemsInList(G_molLst); inc += 1)
			mol = StringFromList(inc, G_molLst, ";")
			Load_DataFUNCT(site, mol, dur, plt)
		endfor
	
	else		// main loop
	
		CATSdataFolder( 1 )
		pstr = DetermineExperiment( mol, site )
		
		if ( strlen(pstr) == 0 )
			return -1
		endif

		// test for combined data waves
		backmol = mol
		combtest = mol + "comb_best_conc_MonthlyY"
		loaddata /q/o/p=CATSdata /j=combtest pstr
		if ( exists(combtest) == 1 )
			mol = mol + "comb"
			killwaves $combtest
		endif

		string dfile, dfileN, tfile, tfileN, sfile, sfileN, nfile, nfileN, port, vfile, vfileN
		if (dur == 1)		// Every Point
			dfile = mol + "_best_conc_hourlyY"
			tfile = mol + "_date"
			sfile = mol + "_H_SD"
			nfile = ""
			port = mol + "_port"
			print "Loading hourly... " + site + "  " + mol
		elseif (dur == 2)		// daily median
			dfile = mol + "_best_conc_dailyY"
			tfile = mol + "_best_conc_dailyX"
			sfile = mol + "_best_conc_dailySD"
			nfile = mol + "_best_conc_dailyNum"
			print "Loading daily... " + site + "  " + mol
		elseif (dur == 3)		// Weekly median
			dfile = mol + "_best_conc_weeklyY"
			tfile = mol + "_best_conc_weeklyX"
			sfile = mol + "_best_conc_weeklySD"
			nfile = mol + "_best_conc_weeklyNum"
			print "Loading weekly... " + site + "  " + mol
		elseif (dur == 4)		// Monthly median
			dfile = mol + "_best_conc_MonthlyY"
			tfile = mol + "_best_conc_MonthlyX"
			sfile = mol + "_best_conc_MonthlySD"
			vfile = mol + "_best_conc_MonthlyVar"
			nfile = mol + "_best_conc_MonthlyNum"
			print "Loading monthly... " + site + "  " + mol
			// delete fitmat data so it is regenerated with the newly loaded data
			bat("Killwaves /Z @", "root:simulation:fx_*_Ca_"+site+"_*")
		endif
		dfileN = site + "_" + backmol
		tfileN = dfileN + "_time"
		sfileN = dfileN + "_SD"
		nfileN = dfileN + "_Num"
			
		string lfiles = dfile + ";" + tfile + ";" + sfile + ";" + nfile
		if (dur == 1)
			lfiles += port
		elseif (dur == 4)
			vfileN = dfileN + "_Var"
			lfiles += ";" + vfile
		endif

		loaddata /q/o/p=CATSdata /j=lfiles pstr
		
		if (exists(dfile) == 1)
			SetFormula $dfile, ""
			duplicate /o $dfile $dfileN
			killwaves $dfile
		endif
		if (exists(tfile) == 1)
			duplicate /d/o $tfile $tfileN
			killwaves $tfile
			SetScale d 0,0,"dat", $tfileN
		endif
		if (exists(sfile) == 1)
			duplicate /o $sfile $sfileN
			killwaves $sfile
		endif
		if (exists(vfile) == 1)
			duplicate /o $vfile $vfileN
			killwaves $vfile
		endif
		if (exists(nfile) == 1)
			duplicate /o $nfile $nfileN
			killwaves $nfile
		endif	

		mol = backmol
		
		if ((dur == 1) && (exists(port) == 1))
			duplicate /o $port $site + "_" + mol + "_port"
			killwaves $port
			port = site + "_" + mol + "_port"
		endif

		if (plt==1)
			plot_style($tfileN, $dfileN, mol, site)
		endif
		
		SetDataFolder root:
		
	endif
	
end

// Function will return the experiment in which the data is located
function /s DetermineExperiment( mol, site )
	string mol, site

	string pstr = ""
	
	// Figure out which file has the data.
	
	// Channel 1
	if ((cmpstr(mol, "N2O") == 0) + (cmpstr(mol, "SF6") == 0))
		pstr = site + " N2O & SF6"
	
	// Channel 2
	elseif (cmpstr(mol, "N2Oa") == 0)
		pstr = site + " N2O & SF6"
	elseif (cmpstr(mol, "F12") == 0)
		pstr = site + " F12"
	elseif (cmpstr(mol, "H1211") == 0)
		if ( (cmpstr(site, "MLO") == 0) + (cmpstr(site, "SPO") == 0) + (cmpstr(site, "SMO") == 0) )
			pstr = site + " H1211"
		elseif ((cmpstr(site, "BRW") == 0) + (cmpstr(site, "NWR") == 0) + (cmpstr(site, "SUM") == 0))
			pstr = site + " H1211 & CHCl3"
		endif
	elseif ((cmpstr(mol, "F11a") == 0) + (cmpstr(mol, "F113a") == 0))
		if (( (cmpstr(site, "SPO") == 0) || (cmpstr(site, "SMO") == 0) ) && (cmpstr(mol, "F11a") == 0))
			pstr = site + " F11"
		elseif (( (cmpstr(site, "SPO") == 0) || (cmpstr(site, "SMO") == 0) ) && (cmpstr(mol, "F113a") == 0))
			pstr = site + " F113"
		else
			pstr = site + " F11 & F113"
		endif
	
	// Channel 3
	elseif (cmpstr(mol, "H1211a") == 0)
		if ( (cmpstr(site, "MLO") == 0) + (cmpstr(site, "SPO") == 0) + (cmpstr(site, "SMO") == 0) )
			pstr = site + " H1211"
		elseif ((cmpstr(site, "BRW") == 0) + (cmpstr(site, "NWR") == 0))
			pstr = site + " H1211 & CHCl3"
		endif
	elseif (cmpstr(mol, "F12f") == 0)
		if ((cmpstr(site, "SUM") == 0))
			pstr = site + " F12 & H1211"
		else
			pstr = site + " F12"
		endif
	elseif ( (cmpstr(mol, "F11") == 0) + (cmpstr(mol, "F113") == 0) )
		if (( (cmpstr(site, "SPO") == 0) || (cmpstr(site, "SMO") == 0) ) && (cmpstr(mol, "F11") == 0))
			pstr = site + " F11"
		elseif (( (cmpstr(site, "SPO") == 0) || (cmpstr(site, "SMO") == 0) ) && (cmpstr(mol, "F113") == 0))
			pstr = site + " F113"
		else
			pstr = site + " F11 & F113"
		endif
	elseif (cmpstr(mol, "CHCl3") == 0)
		if ((cmpstr(site, "BRW") == 0) + (cmpstr(site, "NWR") == 0) + (cmpstr(site, "SUM") == 0))
			pstr = site + " H1211 & CHCl3"
		else
			pstr = site + " CHCl3, MC, CCl4"
		endif
	elseif ( (cmpstr(mol, "MC") == 0) + (cmpstr(mol, "CCl4") == 0) )
		if ((cmpstr(site, "BRW") == 0) + (cmpstr(site, "NWR") == 0) + (cmpstr(site, "SUM") == 0))
			pstr = site + " MC & CCl4"
		else
			pstr = site + " CHCl3, MC, CCl4"
		endif
	
	// Channel 4
	elseif ( (cmpstr(mol, "HCFC22") == 0) + (cmpstr(mol, "CH3Cl") == 0) + (cmpstr(mol, "CH3Br") == 0) )
		if ( cmpstr(site, "sum") == 0 )
			pstr = ""
		else
			pstr = site + " HCFC22, CH3Cl, CH3Br"
		endif
	elseif (cmpstr(mol, "F12cc") == 0)
		pstr = site + " F12"
		if ( cmpstr(site, "sum") == 0 )
			pstr = ""
		endif
	elseif (cmpstr(mol, "H1211cc") == 0)
		if ( (cmpstr(site, "MLO") == 0) + (cmpstr(site, "SPO") == 0) + (cmpstr(site, "SMO") == 0) )
			pstr = site + " H1211"
		elseif ((cmpstr(site, "BRW") == 0) + (cmpstr(site, "NWR") == 0))
			pstr = site + " H1211 & CHCl3"
		endif
		if ( cmpstr(site, "sum") == 0 )
			pstr = ""
		endif
	elseif ((cmpstr(mol, "OCS") == 0) + (cmpstr(mol, "HCFC142b") == 0) + (cmpstr(mol, "H1301") == 0) )
		pstr = site + " HCFC142b, OCS, H1301"
		if ( cmpstr(site, "sum") == 0 )
			pstr = ""
		endif
	endif

	// summit channel 1
	if ((cmpstr(mol, "H2") == 0) || (cmpstr(mol, "CH4") == 0) || (cmpstr(mol, "CO") == 0))
		if ( cmpstr(site, "SUM") == 0)	
			pstr = site + " H2, CH4 & CO"
		else
			pstr = ""
		endif
	endif

	if (strlen(pstr) == 0)
		return ""
	else
		return pstr + ".pxp alias"
	endif
	
end

function UnloadHourlyData()
	
	KillDataFolder root:hour

end

// split up MSD data by site
Function SplitMSDwaves(mol)
	string mol
	
	///  sites that are in the F11 file
	string site, sites = "alt;brw;cgo;hfm;kum;lef;mhd;mlo;nwr;psa;smo;spo;sum;ush;thd;wis;wlg"
	variable i
	
	wave /T sitewv = wave0
	wave datewv = wave1
	wave decday = wave2
	wave MR = wave3
	wave SD = wave4
	
	string sMR, sSD, sDate 
	
	for (i=0; i<ItemsInList(sites); i+=1)
		site = StringFromList(i, sites)
		sMR = "MSD_" + site + "_" + mol + "_Pair"
		sSD = sMR + "_sd"
		sDate = sMR + "_date"
		Extract /O MR, $sMR, cmpstr(sitewv, site) == 0
		Extract /O SD, $sSD, cmpstr(sitewv, site) == 0
		Extract /O datewv, $sDate, cmpstr(sitewv, site) == 0
		SetScale d 0,0,"dat", $sDate
		MSDmonthlyAvg(mol, site)
	endfor
	
end

Function LoadMSD_All()

	String mols = kMSDmols
	mols += kPERSEUSmols			// added 190624
	//String mols = kMSDcatsmols
	
	Variable i
	for(i=0; i<ItemsInList(mols);i+=1)
		LoadMSD(StringFromList(i, mols))
	endfor

end

// loader that uses the functions in "HATS ftp data.ipf"
Function LoadMSD(mol, [clip])
	string mol
	variable clip

	SetDataFolder root:MSD:	
	
	// load from clipboard
	if (ParamIsDefault(clip) == 0)
		ClipLoader_MSDsub_clipped("", mol, mol, "pairs")
	endif

	if (clip != 1)
		LoadMSDData(mol=mol, freq="pairs", useDF=2, plot=1)
	endif
	
	// rename waves
	string site, orgM, orgSD, orgT, orgDec, newM, newSD, newT
	string org_mol = mol
	variable i

	SetDataFolder root:msd
	
	// delete previous data
	string cmd = "MSD_*_" + mol + "*"
	bat("Killwaves /Z @", cmd)
	
	for(i=0; i<ItemsInList(kHATSsites); i+=1)
		site = StringFromList(i, kHATSsites)
		orgM = mol + "msd" + site + "m"
		orgsd = mol + "msd" + site + "sd"
		orgT = mol + "msd" + site + "_timeM"
		orgDec = mol + "msd" + site + "dec"
		if (WaveExists($orgM))
			if (cmpstr(mol, "CH3CCl3") == 0)
				mol = "MC"
			endif
			if (cmpstr(mol, "COS") == 0)
				mol = "OCS"
			endif
			newM = "MSD_" + site + "_" + mol + "_Pair"
			duplicate /o $orgM, $newM
			newSD = "MSD_" + site + "_" + mol + "_Pair_sd"
			duplicate /o $orgSD, $newSD
			newT = "MSD_" + site + "_" + mol + "_Pair_date"
			duplicate /o $orgT, $newT
			if (cmpstr(mol, "F11") == 0)
				wave mix = $newM
				wave sd = $newSD
				wave dt = $newT
				mix = SelectNumber(dt>date2secs(2010,1,1), NaN, mix)
				sd = SelectNumber(dt>date2secs(2010,1,1), NaN, sd)
			endif				
			MSDmonthlyAvg(mol, site)
			mol = org_mol
			killwaves /Z $orgM, $orgSD, $orgT, $orgDec
		endif
		
	endfor

	// deletes fit matrices, they need to be regenerated.	
	SetDataFolder root:simulation:
	bat("Killwaves /Z @", "fx_*_MSD_*")

	SetDataFolder root:

end

Function MSDmonthlyAVG(mol, site)
	string mol, site
	
	SetDataFolder root:MSD:
	wave pMR = $"MSD_" + site + "_" + mol + "_Pair"
	wave pSD = $"MSD_" + site + "_" + mol + "_Pair_sd"
	wave pTT = $"MSD_" + site + "_" + mol + "_Pair_date"
	string MRs = "MSD_" + site + "_" + mol
	string SDs = "MSD_" + site + "_" + mol + "_sd"
	string TTs = "MSD_" + site + "_" + mol + "_date"

	variable FirstYear = 1992, day, hour, pt1, pt2
	variable inc, minc = 0, yinc, num = (ReturnCurrentYear()-FirstYear+1)*12
	
	make /o/n=(num) $MRs/Wave=MR=Nan, $SDs/WAVE=SD=Nan
	make /o/d/n=(num) $TTs/Wave=TT=nan
	SetScale d 0,0,"dat", TT
	
	// Create exact time template wave and monthly averages
	//pt1 = Binarysearch(pTT, date2secs(Firstyear + yinc, minc, 1))
	for(inc=0; inc<num; inc += 1)
		minc += 1
		if (minc == 13)
			minc = 1
			yinc += 1
		endif
		day = ReturnMidDayOfMonth(FirstYear + yinc, minc)
		if (mod(day, 1) != 0)
			hour = 12
			day -= 0.5
		else
			hour = 0
		endif			
		TT[inc] = date2secs(FirstYear + yinc, minc, day) + 60*60*hour
		if (minc == 12)
			Extract /FREE pMR, mrtmp, pTT > date2secs(Firstyear + yinc, 12, 1)  && pTT <= date2secs(Firstyear + yinc + 1, 1, 1)
			Extract /FREE pSD, sdtmp, pTT > date2secs(Firstyear + yinc, 12, 1)  && pTT <= date2secs(Firstyear + yinc + 1, 1, 1)
		else
			Extract /FREE pMR, mrtmp, pTT > date2secs(Firstyear + yinc, minc, 1)  && pTT <= date2secs(Firstyear + yinc, minc+1, 1)
			Extract /FREE pSD, sdtmp, pTT > date2secs(Firstyear + yinc, minc, 1)  && pTT <= date2secs(Firstyear + yinc, minc+1, 1)
		endif
		MR[inc] = mean(mrtmp)
		//SD[inc] = mean(sdtmp)			// this is the mean of precisions. 
		// sdev of measurement (not weighted by pair precisions)  180921
		if (numpnts(mrtmp) > 0)
			Wavestats /Z/Q mrtmp
			SD[inc] = V_sdev/sqrt(V_npnts)
		else
			SD[inc] = nan
		endif
		// Use the larger value: sdev of measurement or mean precision. 180921
		SD[inc] = SelectNumber(SD[inc] > mean(sdtmp)/sqrt(numpnts(mrtmp)), mean(sdtmp)/sqrt(numpnts(mrtmp)), SD[inc])
		SD[inc] = SelectNumber(SD[inc] > 0.0001, SD[inc-1], SD[inc])			/// can't have a zero for SD (130314)
		
	endfor
	
	// trim off extra cells
	variable pt = FirstGoodPt(MR)
	DeletePoints 0, pt, MR, SD, TT
	pt = LastGoodPt(MR)
	DeletePoints pt+1, Inf, MR, SD, TT

end


Proc LoadECDflasksfromClip5(site, mol)
	string site = G_site, mol = G_mol
	prompt site, "Which site", popup, "brw;nwr;mlo;smo;spo;"
	prompt mol, "Which molecule", popup, G_molLst

	silent 1
	G_mol = mol
	G_site = site
//	LoadWave/A/J/D/W/K=0/V={"\t "," $",0,0}/L={0,0,0,1,0} "Clipboard"
	LoadWave/A/G/D "Clipboard"
	Flask5columRename(site, mol)
end

Proc LoadECDflasksfromClip6(site, mol)
	string site = G_site, mol = G_mol
	prompt site, "Which site", popup, "brw;nwr;mlo;smo;spo;"
	prompt mol, "Which molecule", popup, G_molLst

	silent 1
	G_mol = mol
	G_site = site
//	LoadWave/A/J/D/W/K=0/V={"\t "," $",0,0}/L={0,0,0,1,0} "Clipboard"
	LoadWave/A/G/D "Clipboard"
	Flask6columRename(site, mol)
end

Proc LoadCCGGflasksfromClip6(site, mol)
	string site = G_site, mol = G_mol
	prompt site, "Which site", popup, "brw;nwr;mlo;smo;spo;"
	prompt mol, "Which molecule", popup, G_molLst

	silent 1
	G_mol = mol
	G_site = site
//	LoadWave/A/J/D/W/K=0/V={"\t "," $",0,0}/L={0,0,0,1,0} "Clipboard"
	LoadWave/A/G/D "Clipboard"
	Flask6columRenameCCGG(site, mol)
end


// 220427 GSD
// load CCGG .csv file made with Jupyter notebook on catsdata
// using a subset of sites
function LoadCCGGfile(mol)
	string mol

	string s, sMR, sSD, sDate
	string file = "Macintosh HD:Users:gdutton:Data:CATS:Data Processing:ccgg_" + lowerStr(mol) + ".csv"
	variable i
	
	cd root:CCGG:
	
	String columnInfoStr = ""
	columnInfoStr += "C=1,F=-1,T=4,N=CCGG_" + mol + "_date;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_alt_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_alt_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_brw_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_brw_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_cgo_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_cgo_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_kum_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_kum_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_mhd_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_mhd_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_mlo_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_mlo_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_nwr_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_nwr_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_psa_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_psa_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_smo_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_smo_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_spo_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_spo_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_sum_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_sum_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_thd_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_thd_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_ush_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_ush_" + mol + "_sd;"
	
	LoadWave/O/A/Q/J/W/K=0/B=columnInfoStr/R={English,2,2,2,2,"Year-Month-DayOfMonth",40} file
	print "loaded from: " + file
	
	cd root:
	
end


// load CCGG shortened files
//    deprecated 220427 GSD (use .csv files generated by the Jupyter notebooks)
//function LoadCCGGfile(mol, site)
	string mol, site
	
	string file = lowerStr(site) + "_" + lowerStr(mol) + "_short.txt"
	
	string yyyySTR = site + "_" + mol + "_yyyy"
	string mmSTR = site + "_" + mol + "_mm"
	string mixSTR = site + "_" + mol
	string daySTR = site + "_" + mol + "_date"
	
	// load path
	PathInfo CCGGpath
	if (V_flag == 0)
		NewPath /M="Path to CCGG data" CCGGpath
		if (v_flag !=0)
			abort
		endif
	endif
	
	// Data folder
	NewDataFolder /O/S root:CCGG
	
	LoadWave/Q/A/G/P=CCGGpath/O file
	if (V_flag == 0)
		abort
	endif
	
	duplicate /o wave0 $yyyySTR/Wave=yyyy
	duplicate /o wave1 $mmSTR/Wave=mm
	duplicate /o wave5 $mixSTR/Wave=mix
	
	// filtering bad values and data earlier than 2001
	mix = SelectNumber(mix>-999, NaN, mix)
	mix = SelectNumber(yyyy>2000, NaN, mix)

	MakeCCGGmonthlymeans(mix, yyyy, mm, mol)

	killwaves /Z wave0, wave1, wave2, wave3, wave4, wave5, wave6
	killwaves /Z yyyy, dd, mm, hh, mn, flag, mix
	
	// delete the fit matrix files if they exists.  They need to be regenerated.
	SetDataFolder root:simulation:
	bat("Killwaves /Z @", "fx_*_CCGG_*")

	SetDataFolder root:

end

// makes monthly means and date waves
function MakeCCGGmonthlymeans(mix, yyyy, mm, mol)
	wave mix, yyyy, mm
	string mol
	
	string MDstr = "CCGG_" + NameOfWave(mix) + "_mn"
	string SDstr = "CCGG_" + NameOfWave(mix) + "_sd"
	string NUMstr = "CCGG_" + NameOfWave(mix) + "_num"
	string DDstr = "CCGG_" + NameOfWave(mix) + "_date"
	
	variable i,  minc, yinc, FY = yyyy[0], LY = yyyy[numpnts(yyyy)-1]
	
	Make/O/D/N=((LY+1-FY)*12) $DDstr/WAVE=DD
	Make /O/N=((LY+1-FY)*12) $MDstr/Wave=MD=nan, $SDstr/Wave=SD=nan, $NUMstr/Wave=NUM=0
	SetScale d 0,0,"dat", DD

	for(yinc=FY; yinc<=LY; yinc+=1)
		for(minc=1; minc<=12; minc+=1)
			DD[i] = date2secs(yinc, minc, 15)
			Extract /FREE mix, tmp, yyyy==yinc && mm==minc
			if (numpnts(tmp) > 0)
				Wavestats/Q tmp
				MD[i] = V_avg
				SD[i] =  V_sdev
				NUM[i] = round(V_npnts/2)		// divide by 2 for pairs
			endif
			i += 1
		endfor
	endfor
	
	// missing SD values occure if only one point is in the measurement
	// use default SD value 0.3 for N2O and 0.05 for SF6
	variable defval = Selectnumber(cmpstr(mol, "sf6")==0, 0.3, 0.05)
	SD = SelectNumber(((SD < defval) || (numtype(SD)==2)) && NUM > 0, SD, defval)

end


// For the mass spec files
function Flask3columRename(site, mol)
	string site, mol
	
	duplicate /o wave1, $"flasks_"+site+"_"+mol+"_date"
	duplicate /o wave2, $"flasks_"+site+"_"+mol
	duplicate /o wave3, $"flasks_"+site+"_"+mol+"_sd"

	killwaves wave0, wave1, wave2, wave3
	wave flaskD = $"flasks_"+site+"_"+mol+"_date"
	
	flaskD = (flaskD - 1904) * 60 * 60 * 24 * 365.25
	
	SetScale d 0,0,"dat", flaskD
end
	
// For the ECD data
function Flask5columRename(site, mol)
	string site, mol

	freplace(wave2, 0, nan)
	duplicate /o wave0, $"flasks_"+site+"_"+mol+"_YYYY"
	duplicate /o wave1, $"flasks_"+site+"_"+mol+"_mo"
	duplicate /o wave2, $"flasks_"+site+"_"+mol
	duplicate /o wave3, $"flasks_"+site+"_"+mol+"_sd"

	killwaves wave0, wave1, wave2, wave3, wave4
	
	string flaskD = "flasks_"+site+"_"+mol+"_date"
	wave flaskY = $"flasks_"+site+"_"+mol+"_YYYY"
	wave flaskM = $"flasks_"+site+"_"+mol+"_MO"
	
	duplicate /o flaskY, $flaskD
	wave flaskDwv = $flaskD
	flaskDwv = date2secs(flaskY, flaskM, 15)
	SetScale d 0,0,"dat", flaskDwv
end

// For the ECD data
function Flask6columRename(site, mol)
	string site, mol
	
	freplace(wave3, 0, nan)
	duplicate /o wave0, $"flasks_"+site+"_"+mol+"_YYYY"
	duplicate /o wave1, $"flasks_"+site+"_"+mol+"_mo"
//	duplicate /o wave2, $"flasks_"+site+"_"+mol
	duplicate /o wave3, $"flasks_"+site+"_"+mol
	duplicate /o wave4, $"flasks_"+site+"_"+mol+"_sd"
//	duplicate /o wave5, $"flasks_"+site+"_"+mol


	killwaves wave0, wave1, wave2, wave3, wave4, wave5
	
	string flaskD = "flasks_"+site+"_"+mol+"_date"
	wave flaskY = $"flasks_"+site+"_"+mol+"_YYYY"
	wave flaskM = $"flasks_"+site+"_"+mol+"_MO"
	
	duplicate /o flaskY, $flaskD
	wave flaskDwv = $flaskD
	flaskDwv = date2secs(flaskY, flaskM, 15)
	SetScale d 0,0,"dat", flaskDwv
end

// For the CCGG data
function Flask6columRenameCCGG(site, mol)
	string site, mol

	freplace(wave5, -999, nan)
	duplicate /o wave0, $site+"_ccg_"+mol+"_YYYY"
	duplicate /o wave1, $site+"_ccg_"+mol+"_mo"
	duplicate /o wave2, $site+"_ccg_"+mol+"_dd"
	duplicate /o wave3, $site+"_ccg_"+mol+"_hh"
	duplicate /o wave4, $site+"_ccg_"+mol+"_mm"
	duplicate /o wave5, $site+"_ccg_"+mol

	killwaves wave0, wave1, wave2, wave3, wave4, wave5
	
	string flaskD = site+"_ccg_"+mol+"_date"
	wave flaskY = $site+"_ccg_"+mol+"_YYYY"
	wave flaskM = $site+"_ccg_"+mol+"_mo"
	wave flaskDD = $site+"_ccg_"+mol+"_dd"
	wave flaskH = $site+"_ccg_"+mol+"_hh"
	wave flaskMM = $site+"_ccg_"+mol+"_mm"
	
	duplicate /o flaskY, $flaskD
	wave flaskDwv = $flaskD
	flaskDwv = date2secs(flaskY, flaskM, flaskDD) + flaskH*60*60 + flaskMM*60 
	SetScale d 0,0,"dat", flaskDwv
end

// load MM RITS Data from new ftp files
// 20100511
function LoadRITS(site, mol)
	string site, mol

	SetDataFolder root:RITS:
	string file = site + "_" + mol + "_MM.dat"
	
	LoadWave/A/Q/J/D/W/K=0/V={"\t, "," $",0,0}/L={45,46,0,0,0} "Macintosh HD:Users:geoff:Data:RITS:withheaders:" + file
	
	Wave MR = $mol+"rits"+site+"m"
	Wave dMR = $mol+"rits"+site+"sd"
	Wave nm = $mol+"rits"+site+"n"
	Wave YY = $mol+"rits"+site+"yr"
	Wave MO = $mol+"rits"+site+"mon"
	String MRn = "RITS_" + site + "_" + mol + "_new"
	String dMRn = "RITS_" + site + "_" + mol + "_new_sd"
	String nmn = "RITS_" + site + "_" + mol + "_new_num"
	String Tn = "RITS_" + site + "_" + mol + "_new_date"
	
	Duplicate /o MR, $MRn
	Duplicate /o dMR, $dMRn
	Duplicate /o nm, $nmn
	Duplicate /o YY, $Tn/Wave=RITSt
	
	RITSt = date2secs(YY, MO, ReturnMidDayOfMonth(YY, MO))
	
	Killwaves MR, dMR, nm, YY, MO	
	
	SetDataFolder root:
	
end

Function LoadAll_RITS()

	string sites = "brw;nwr;mlo;smo;spo", site
	string mols = "CCl4;F11;F12;MC;N2O", mol
	
	variable s, m
	for(s=0; s<ItemsInList(sites); s+=1)
		site = StringFromList(s, sites)
		for(m=0; m<ItemsInList(mols); m+=1)
			mol = StringFromList(m, mols)
			print "Working on " + site, mol
			LoadRITS(site, mol)
		endfor
	endfor

End

function LoadSurfaceO3()

	SVAR site = root:G_site
	SVAR sitelst = root:G_siteLst
	string sitesel = site
	
	Prompt sitesel, "Select site", popup, sitelst
	DoPrompt "Load Ozone", sitesel
	If (V_flag)
		return -1
	endif
	site = sitesel
	
	String file = site + ".o3.txt"						// o3 file
	String O3str = site + "_O3"
	String Tstr = "root:hour:" + site + "_time"		// CATS time wave
	variable i, pt

	if (exists(Tstr) == 0)
		abort "Load the " + site + " hourly data first."
	endif
	Wave T = $Tstr

	PathInfo O3data
	if (V_flag == 0)
		NewPath /M="Path to O3 data" O3data
	endif
	
	NewDataFolder /O/S root:O3
	
	LoadWave/Q/G/D/W/A/P=O3data file
	wave wave0, wave1, wave2, wave3, wave4, wave5

	// make time wave
	Make /d/o/n=(numpnts(wave0)) O3_time
	O3_time = date2secs(wave1, wave2, wave3) + wave4 * 60*60
	Duplicate /O wave5, $(site + "_O3_org")
	Duplicate /O O3_time $(site + "_O3_time_org")
	
	// sync with CATS data
	Make /o/n=(numpnts(T)) $O3str = NaN
	Wave O3 = $O3str
	for( i=0; i<numpnts(T); i+=1 )
		pt = BinarySearch(O3_time, T[i])
		if (( abs(T[i]-O3_time[pt]) <= 3*60*60 ) && ( pt >= 0 ))
			O3[i] = wave5[pt]
		endif
	endfor
	
	killwaves O3_time, wave0, wave1, wave2, wave3, wave4, wave5
	
	SetDataFolder root:
	
end

// load CCGG choose a mol
function LoadCCGGinSituData( )

	SVAR site = root:G_site
	SVAR mol = root:G_mol
	SVAR sitelst = root:G_siteLst
	string sitesel = site
	string molsel = "CH4"
	
	Prompt sitesel, "Select site", popup, sitelst
	Prompt molsel, "Select molecule", popup, molsel
	DoPrompt "Load CCGG", sitesel, molsel
	If (V_flag)
		return -1
	endif
	site = sitesel
	mol = molsel
	
	String file = site + "." + LowerStr(mol) + ".txt"			// data file
	String varstr = site + "_" + mol
	String varstrsd = varstr + "_sd"
	String Tstr = "root:hour:" + site + "_time"		// CATS time wave
	variable i, pt

	if (exists(Tstr) == 0)
		abort "Load the " + site + " hourly data first."
	endif
	Wave T = $Tstr

	string Path = mol + "data"
	PathInfo $Path
	if (V_flag == 0)
		NewPath /M="Path to " + mol + " data" $Path
	endif
	
	string DFold =  "root:" + mol
	NewDataFolder /O/S $DFold
	
	LoadWave/Q/G/D/W/A/P=$Path file
	wave wave0, wave1, wave2, wave3, wave4, wave5

	// make time wave
	string Tmol = mol + "_time"
	Make /d/o/n=(numpnts(wave0)) $Tmol
	wave Tvar = $Tmol
	Tvar = date2secs(wave0, wave1, wave2) + wave3 * 60*60
	Duplicate /O wave4, $(site + "_" + mol + "_org")
	Duplicate /O wave5, $(site + "_" + mol + "_sd_org")
	Duplicate /O Tvar $(site + "_" + mol + "_time_org")
	
	// sync with CATS data
	Make /o/n=(numpnts(T)) $varstr = NaN, $varstrsd = NaN
	Wave var = $varstr
	Wave varSD = $varstrsd
	for( i=0; i<numpnts(T); i+=1 )
		pt = BinarySearch(Tvar, T[i])
		if (( abs(T[i]-Tvar[pt]) <= 3*60*60 ) && ( pt >= 0 ))
			var[i] = wave4[pt]
			varSD[i] = wave5[pt]
		endif
	endfor
	
	killwaves Tvar, wave0, wave1, wave2, wave3, wave4, wave5
	
	SetDataFolder root:
	
end

Function LoadOtto_All()

	String mols = "F11;F12;F113;SF6;N2O;CCl4;MC", mol
	String site, orgM, orgsd, orgT, orgDec, orgJunk1, orgJunk2, orgN, newM, newSD, newN, newT
	Variable i, j
	
	for(i=0; i<ItemsInList(mols);i+=1)
		mol = StringFromList(i, mols)

		LoadOTTOdata(mol=mol, freq="monthly", useDF=2)

		SetDataFolder "root:otto:"
		for(j=0; j<ItemsInList(kHATSsites); j+=1)
			site = StringFromList(j, kHATSsites)
			orgM = mol + "otto" + site + "m"
			orgsd = mol + "otto" + site + "sd"
			orgT = mol + "otto" + site + "_timeM"
			orgDec = mol + "otto" + site + "dec"
			orgJunk1 = mol + "otto" + site + "mon"
			orgJunk2 = mol + "otto" + site + "yr"
			orgN = mol + "otto" + site + "n"			
			if (WaveExists($orgM))
				newM = "otto_" + site + "_" + mol 
				duplicate /o $orgM, $newM
				newSD = "otto_" + site + "_" + mol + "_sd"
				duplicate /o $orgSD, $newSD/Wave=SD
				newN = "otto_" + site + "_" + mol + "_num"
				duplicate /o $orgN, $newN
				newT = "otto_" + site + "_" + mol + "_date"
				duplicate /o $orgT, $newT
				killwaves /Z $orgM, $orgSD, $orgT, $orgDec, $orgJunk1, $orgJunk2, $orgN
				//if (cmpstr(mol, "CCl4")==0)
				//	SD = SelectNumber(SD>0.5,0.5,SD)
				//endif
			endif
		endfor
		
	endfor
	
	// delete the fit matrix files if they exists.  They need to be regenerated.
	SetDataFolder root:simulation:
	bat("Killwaves /Z @", "fx_*_OTTO_*")

	SetDataFolder root:
	
	// shift N2O
	ShiftOttoN2O()
	
	// remove F12 later than 2015
	RemoveOttoData("F12", date2secs(2014,1,1))
	
end


function RemoveOttoData(mol, cutdate)
	string mol
	variable /d cutdate
	
	string site, sites="alt;brw;sum;mhd;nwr;thd;mlo;kum;smo;cgo;psa;spo"
	variable i, pt
	string OP = "root:otto:"

	for(i=0; i<ItemsInList(sites); i+=1)
		site = StringFromList(i, sites)
		wave /Z MR = $OP + "otto_" + site + "_" + mol
		wave /Z MRd = $OP + "otto_" + site + "_" + mol + "_date"
		if (waveexists(MR))
			pt = BinarySearchInterp(MRd, cutdate)
			MR[pt,numpnts(MR)] = Nan
		endif		
	endfor

end	

// shift otto n2o data, the shifts were measured using the diffhistogram function 
function ShiftOttoN2O()

	string site, sites="alt;brw;sum;mhd;nwr;thd;mlo;kum;smo;cgo;psa;spo"
	variable shift = 0.59		//ppb
	variable shiftSMO = 1.30	// ppb
	variable i, pt
	variable /d cut = date2secs(2009,1,1)
	string OP = "root:otto:"
	
	for(i=0; i<ItemsInList(sites); i+=1)
		site = StringFromList(i, sites)
		wave /Z MR = $OP + "otto_" + site + "_N2O"
		wave /Z MRd = $OP + "otto_" + site + "_N2O_date"
		if (waveexists(MR))
			pt = BinarySearchInterp(MRd, cut)
			if (cmpstr(site, "smo") == 0)
				MR[0,pt] += shiftSMO
			else
				MR[0,pt] += shift
			endif
		endif		
	endfor

end



// loads reprocessed oldGC data
// 20110203
// added flag wave 20110719
Function Load_OldFlask_ave95(site, mol)
	string site, mol

	PathInfo oldGC
	If (!V_flag)
		NewPath/M="Path to old GC ave95.new data" oldGC
	endif
	
	String file = LowerStr(site) + "_" + LowerStr(mol) + "_ave95.new"
	String tstr = mol+site+"_time"
	String mrst = mol+site
	String sdst = mol+site+"sd"
	String nstr = mol+site+"_n"
	
	SetDataFolder root:oldGC
	LoadWave/Q/G/A=oldgc /P=oldGC file
	Wave oldgc0, oldgc1, oldgc2, oldgc3, oldgc4, oldgc5, oldgc6, oldgc7

	Make /D/O/n=(numpnts(oldgc0)) $tstr/Wave=tt=date2secs(oldgc0+1900, oldgc1,15)
	SetScale d 0,0,"dat", tt

	Duplicate /o oldgc3 $mrst/Wave=mr
	Duplicate /o oldgc4 $nstr/Wave=nn
	Duplicate /o oldgc6 $sdst/Wave=sd
	
	// filter and flagging  oldgc7 is flag wave
	sd = Selectnumber( (mr>0)&&(oldgc7!=1), NaN, sd)
	nn = Selectnumber( (mr>0)&&(oldgc7!=1), NaN, nn)
	mr = Selectnumber( (mr>0)&&(oldgc7!=1), NaN, mr)
		
	Killwaves /Z  oldgc0, oldgc1, oldgc2, oldgc3, oldgc4, oldgc5, oldgc6, oldgc7
	SetDataFolder root:

end

Function Load_OldFlask_ave95_ALL(mol)
	string mol
	
	String sites = "alt;brw;cgo;mlo;nwr;smo;spo;"
	Variable i
	
	for(i=0; i<ItemsInList(sites);i+=1)
		Load_OldFlask_ave95(upperstr(StringFromList(i, sites)), upperstr(mol))
	endfor
	
end
