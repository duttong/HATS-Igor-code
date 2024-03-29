#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=1		// Use modern global access method.
#include "macros-CATS sync"


Proc PlotTimeSeries(mol, dur, err, insitu)
	string mol = StrMakeOrDefault("root:G_mol", "N2O")
	variable dur = NumMakeOrDefault("root:G_dur", 1)
	variable err = NumMakeOrDefault("root:G_err", 1)
	variable insitu = NumMakeOrDefault("root:G_insitu", 1)
	prompt mol, "Which molecule", popup, root:G_molLst
	prompt dur, "Duration of data", popup, "Every Point;Daily Median;Weekly Median;Monthly Median"
	prompt err, "What kind of error bar", popup, "none;standard deviation"
	prompt insitu, "Which data set?", popup, "CATS only;CATS and RITS combined;CATS and RITS separate"

	silent 1; pauseupdate
	
	PlotTimeSeriesFUNCT(mol, dur, err, insitu)
	
end

function PlotTimeSeriesFUNCT(mol, dur, err, insitu)
	string mol
	variable dur, err, insitu
	
	SVAR G_mol = root:G_mol
	SVAR S_dur = root:S_dur
	NVAR G_err = root:G_err
	NVAR G_insitu = root:G_insitu
	NVAR G_dur = root:G_dur
	
	NVAR G_globalSta = root:plot:CB_GlobalStations 
	
	variable HIDE = 0
	if ( G_globalSta )
		HIDE = 2
	endif
	
	G_mol = mol
	G_err = err
	G_insitu = insitu
	G_dur = dur
	
	string DF = CATSdataFolder( 1 )
	
	if (insitu == 1)
		string brwY = "brw_" + mol, brwX = "brw_time"
		string sumY = "sum_" + mol, sumX = "sum_time"
		string nwrY = "nwr_" + mol, nwrX = "nwr_time"
		string mloY = "mlo_" + mol, mloX = "mlo_time"
		string smoY = "smo_" + mol, smoX = "smo_time"
		string spoY = "spo_" + mol, spoX = "spo_time"
		
	elseif (insitu == 2)
		RITSandCATScombFUNCT(mol)
		CATSdataFolder( 1 )
		brwY ="insitu_brw_" + mol
		brwX = brwY + "_date"
		sumY = "sum_" + mol
		sumX = "sum_time"
		nwrY = "insitu_nwr_" + mol
		nwrX = nwrY + "_date"
		mloY = "insitu_mlo_" + mol
		mloX = mloY + "_date"
		smoY =  "insitu_smo_" + mol
		smoX = smoY + "_date"
		spoY =  "insitu_spo_" + mol
		spoX = spoY + "_date"
		
	elseif (insitu == 3)
		RITSandCATSplot(mol)
		SetDataFolder root:
		abort
	endif
				
	if (err == 2)
		string brwSE = brwY + "_SD"
		string sumSE = sumY + "_SD"
		string nwrSE = nwrY + "_SD"
		string mloSE = mloY + "_SD"
		string smoSE = smoY + "_SD"
		string spoSE = spoY + "_SD"
	endif

	string com
	string nm = mol + "_" + S_dur + "_timeSeries"

	DoWindow /K $nm	
	Display /K=1/W=(30,50,863,558) 
	if (exists(brwY) == 1)
		AppendToGraph $brwY vs $brwX
		ModifyGraph marker($brwY)=19, hideTrace($brwY)=HIDE
	endif
	if (exists(sumY) == 1)
		AppendToGraph $sumY vs $sumX
		ModifyGraph marker($sumY)=19, rgb($sumY)=(30000,30000,1), hideTrace($sumY)=HIDE
	endif
	if (exists(nwrY) == 1)
		AppendToGraph $nwrY vs $nwrX
		ModifyGraph marker($nwrY)=19, rgb($nwrY)=(16385,49025,65535), hideTrace($nwrY)=HIDE
	endif
	if (exists(mloY) == 1)
		AppendToGraph $mloY vs $mloX
		ModifyGraph marker($mloY)=19, rgb($mloY)=(65535,43690,0), hideTrace($mloY)=HIDE
	endif
	if (exists(smoY) == 1)
		AppendToGraph $smoY vs $smoX
		ModifyGraph marker($smoY)=19, rgb($smoY)=(3,52428,1), hideTrace($smoY)=HIDE
	endif
	if (exists(spoY) == 1)
		AppendToGraph $spoY vs $spoX
		ModifyGraph marker($spoY)=19, rgb($spoY)=(1,4,52428), hideTrace($spoY)=HIDE
	endif
	DoWindow /C $nm

	ModifyGraph gFont="Georgia",gfSize=14,gmSize=2,wbRGB=(59151,59151,59151)
	ModifyGraph mode=4

	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	ModifyGraph msize=3
	if ( (cmpstr(mol,"N2O") == 0) + (cmpstr(mol,"N2Oa") == 0) )
		sprintf com, "\\f01%s (ppb)", mol
	else
		sprintf com, "\\f01%s (ppt)", mol
	endif
	Label left com
	Label bottom "\\f01Date"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	if (err != 1)
		sprintf com, "ErrorBars %s Y,wave=(%s,%s)",brwY, brwSE, brwSE; execute com
		sprintf com, "ErrorBars %s Y,wave=(%s,%s)",sumY, sumSE, sumSE; execute com
		sprintf com, "ErrorBars %s Y,wave=(%s,%s)",nwrY, nwrSE, nwrSE; execute com
		sprintf com, "ErrorBars %s Y,wave=(%s,%s)",mloY, mloSE, mloSE; execute com
		sprintf com, "ErrorBars %s Y,wave=(%s,%s)",smoY, smoSE, smoSE; execute com
		sprintf com, "ErrorBars %s Y,wave=(%s,%s)",spoY, spoSE, spoSE; execute com
	endif
	
	if ( exists(sumY) == 1)
		sprintf com, "\\JC\\s(%s) brw \\s(%s) sum \\s(%s) nwr \\s(%s) mlo \r\\s(%s) smo \\s(%s) spo ", brwY, sumY, nwrY, mloY, smoY, spoY
	else
		sprintf com, "\\JC\\s(%s) brw \\s(%s) nwr \\s(%s) mlo \r\\s(%s) smo \\s(%s) spo ", brwY, nwrY, mloY, smoY, spoY
	endif
		
	Legend/C/N=legend/J/S=3/X=66/Y=1 com
	
	SetDataFolder root:
	
end

function RITSandCATSplot( mol )
	string mol

	string com
	string new = mol + "_new"
//	string new = mol
	string RP = "root:RITS:"
	string CP = "root:month:"
	
	string RbrwY = "RITS_brw_" + new, RbrwX = RbrwY + "_date"
	string RnwrY = "RITS_nwr_" + new, RnwrX = RnwrY + "_date"
	string RmloY = "RITS_mlo_" + new, RmloX = RmloY + "_date"
	string RsmoY = "RITS_smo_" + new, RsmoX = RsmoY + "_date"
	string RspoY = "RITS_spo_" + new, RspoX = RspoY + "_date"

	string brwY = "brw_" + mol, brwX = "brw_time"
	string nwrY = "nwr_" + mol, nwrX = "nwr_time"
	string mloY = "mlo_" + mol, mloX = "mlo_time"
	string smoY = "smo_" + mol, smoX = "smo_time"
	string spoY = "spo_" + mol, spoX = "spo_time"
	
	string nm = mol + "_timeSeriesBOTH"
	
	DoWindow /K $nm
	Display /K=1/W=(721,115,1554,623) 
	DoWindow /C $nm

	// CATS
	SetDataFolder "root:month:"
	
	if (exists(CP+brwY) == 1)
		AppendToGraph $brwY vs $brwX
		ModifyGraph marker($brwY)=19
	endif
	if (exists(nwrY) == 1)
		AppendToGraph $nwrY vs $nwrX
		ModifyGraph marker($nwrY)=19, rgb($nwrY)=(16385,49025,65535)
	endif
	if (exists(mloY) == 1)
		AppendToGraph $mloY vs $mloX
		ModifyGraph marker($mloY)=19, rgb($mloY)=(65535,43690,0)
	endif
	if (exists(smoY) == 1)
		AppendToGraph $smoY vs $smoX
		ModifyGraph marker($smoY)=16, rgb($smoY)=(3,52428,1)
	endif
	if (exists(spoY) == 1)
		AppendToGraph $spoY vs $spoX
		ModifyGraph marker($spoY)=16, rgb($spoY)=(1,4,52428)
	endif
	
	SetDataFolder "root:RITS:"
	
	// RITS
	if (exists(RbrwY) == 1)
		AppendToGraph $RbrwY vs $RbrwX
		ModifyGraph marker($RbrwY)=8
	endif
	if (exists(RnwrY) == 1)
		AppendToGraph $RnwrY vs $RnwrX
		ModifyGraph marker($RnwrY)=8, rgb($RnwrY)=(16385,49025,65535)
	endif
	if (exists(RmloY) == 1)
		AppendToGraph $RmloY vs $RmloX
		ModifyGraph marker($RmloY)=8, rgb($RmloY)=(65535,43690,0)
	endif
	if (exists(RsmoY) == 1)
		AppendToGraph $RsmoY vs $RsmoX
		ModifyGraph marker($RsmoY)=5, rgb($RsmoY)=(3,52428,1)
	endif
	if (exists(RspoY) == 1)
		AppendToGraph $RspoY vs $RspoX
		ModifyGraph marker($RspoY)=5, rgb($RspoY)=(1,4,52428)
	endif
	
	ModifyGraph gFont="Georgia",gfSize=14,gmSize=2,wbRGB=(49151,65535,65535)
	ModifyGraph mode=4
	
	ModifyGraph msize=3
	ModifyGraph grid=1
	ModifyGraph mirror=1
	ModifyGraph axOffset(left)=-0.375
	ModifyGraph dateInfo(bottom)={0,0,0}
	
	if ( (cmpstr(mol,"N2O") == 0) || (cmpstr(mol,"N2Oa") == 0) )
		sprintf com, "\\f01%s (ppb)", mol
	else
		sprintf com, "\\f01%s (ppt)", mol
	endif
	Label bottom "\\f01Date"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	
	sprintf com, "\\JC\\f01CATS\\f00\r\\s(%s) brw \\s(%s) nwr \\s(%s) mlo \r\\s(%s) smo \\s(%s) spo \r\\f01RITS\\f00", brwY, nwrY, mloY, smoY, spoY
	Legend/N=text0_1/J/S=3/X=70.11/Y=5.71 com
	sprintf com, "\\s(%s) brw \\s(%s) nwr \\s(%s) mlo\r\\s(%s) smo \\s(%s) spo", RbrwY, RnwrY, RmloY, RsmoY, RspoY
	AppendText com
	
	SetDataFolder root:

end


function plot_style(xx, yy, mol, site)
	wave xx, yy
	string mol, site
	
	site = UpperStr(site)
//	string se = NameOfWave(yy) + "_se"
	string se = NameOfWave(yy) + "_sd"		// use standard deviations
	string nm = mol + "_" + site
	
	string Llab, com
	sprintf Llab, "\\f01%s -- %s", mol, site

	if (strlen(WinList(nm, ";", "")) == 0)
		Display /W=(244,86,922,487) yy vs xx
		DoWindow /C $nm
	else
		DoWindow /F $nm
	endif
	
	ModifyGraph gFont="Georgia",gfSize=14,gmSize=2,wbRGB=(65535,65534,49151)
	ModifyGraph mode=4
	ModifyGraph marker=19
	ModifyGraph msize=1
	ModifyGraph gaps=0
	ModifyGraph grid=1
	ModifyGraph mirror=1
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left Llab
	Label bottom "\\f01Date"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	if (exists(se) == 1)
		sprintf com, "ErrorBars %s Y,wave=(%s,%s)", NameOfWave(yy), se, se
		execute com
	endif
EndMacro

function makediffwvs(site, mol)
	string site, mol
	
	string catsSTR = site + "_" + mol
	string ritsSTR = "RITS_" + site + "_" + mol
	string flasksSTR = "flasks_" + site + "_" + mol
	string catsTSTR = site + "_" + mol + "_time"
	string ritsTSTR = "RITS_" + site + "_" + mol + "_date"
	string flasksTSTR
	if (cmpstr(mol, "f11") == 0)
		flasksTSTR =  "flasks_" + site + "_" + mol + "_date"		// for OTTO
	else
		flasksTSTR = "flasks_" + mol + "_time"					// for GCMS
	endif
	
	if (exists(catsSTR) != 1)
		abort catsSTR
	endif
	if (exists(ritsSTR) != 1)
		abort ritsSTR
	endif
	if (exists(flasksSTR) != 1)
		abort flasksSTR
	endif
	if (exists(catsTSTR) != 1)
		abort catsTSTR
	endif
	if (exists(ritsTSTR) != 1)
		abort ritsTSTR
	endif
	if (exists(flasksTSTR) != 1)
		abort flasksTSTR
	endif

	wave cats = $catsSTR
	wave rits = $ritsSTR
	wave flasks = $flasksSTR
	wave catsT = $catsTSTR
	wave ritsT = $ritsTSTR
	wave flasksT = $flasksTSTR
	
	string CmRstr = "CATS_RITS_diff_" + site + "_" + mol
	string CmFstr = "CATS_Flask_diff_" + site + "_" + mol
	string FmRstr = "Flask_RITS_diff_" + site + "_" + mol
	string CmRTstr = "CATS_RITS_diff_" + site + "_" + mol + "_date"
	string CmFTstr = "CATS_Flask_diff_" + site + "_" + mol + "_date"
	string FmRTstr = "Flask_RITS_diff_" + site + "_" + mol + "_date"
	string com
	
	make /d/o/n=200 $CmRstr=nan, $CmRTstr=nan, $FmRstr=NaN, $FmRTstr=NaN, $CmFstr=NaN, $CmFTstr=NaN
	
	wave CmR = $CmRstr
	wave CmF = $CmFstr
	wave FmR = $FmRstr
	wave CmRT = $CmRTstr
	wave CmFT = $CmFTstr
	wave FmRT = $FmRTstr
	
	SetScale d 0,0,"dat", CmRT
	SetScale d 0,0,"dat", CmFT
	SetScale d 0,0,"dat", FmRT
	
	variable  incR, incC, incF, inc2, inc3
	variable /d diff
	
	// Do CATS - RITS
	inc2= 0
	do
		incC = 0
		do
			diff = ritsT[incR] - catsT[incC]
			if  (diff == 0)
				CmRT[inc2] = ritsT[incR]
				CmR[inc2] = cats[incC] - rits[incR]
				incC = 5000
				inc2 += 1
			endif
			incC += 1
		while (incC < numpnts(cats))
		incR += 1
	while (incR < numpnts(rits))
	
	wavestats /Q CmR
	sprintf com,  "Diff CATS - RITS = %3.2f � %3.2f   (num pnts = %d)", V_avg, V_sdev, V_npnts
	print com
	
	// Do CATS - Flask
	inc2 = 0; incC = 0; incF = 0
	do
		incF = 0
		do
			diff = catsT[incC] - flasksT[incF]
			if  (abs(diff) < 60*60*24*16)
				CmFT[inc2] = catsT[incC]
				CmF[inc2] = cats[incC] - flasks[incF]
				incF = 5000
				inc2 += 1
			endif
			incF += 1
		while (incF < numpnts(flasks))
		incC += 1
	while (incC < numpnts(cats))

	wavestats /Q CmF
	sprintf com,  "Diff CATS - flasks = %3.2f � %3.2f   (num pnts = %d)", V_avg, V_sdev, V_npnts
	print com


	// Do Flasks - RITS
	inc2 = 0; incR = 0; incF = 0
	do
		incF = 0
		do
			diff = ritsT[incR] - flasksT[incF]
			if  (abs(diff) < 60*60*24*16)
				FmRT[inc2] = ritsT[incR]
				FmR[inc2] = flasks[incF] - rits[incR]
				incF = 5000
				inc2 += 1
			endif
			incF += 1
		while (incF < numpnts(flasks))
		incR += 1
	while (incR < numpnts(rits))

	wavestats /Q FmR
	sprintf com,  "Diff flasks - RITS = %3.2f � %3.2f   (num pnts = %d)", V_avg, V_sdev, V_npnts
	print com


	string win = site + "_" + mol + "_diff"
	variable TRUE=1
	if (TRUE)
		dowindow /k $win
		Display /W=(44,140,929,722) CmF vs CmFT
		dowindow /c $win
		AppendToGraph CmR vs CmRT
		AppendToGraph FmR vs FmRT
		ModifyGraph gFont="Georgia",gfSize=14,wbRGB=(57346,65535,49151)
		ModifyGraph mode=3
		sprintf com, "ModifyGraph marker(CATS_Flask_diff_%s_%s)=16,marker(CATS_RITS_diff_%s_%s)=19", site, mol, site, mol
		execute com
		sprintf com, "ModifyGraph marker(Flask_RITS_diff_%s_%s)=17", site, mol
		execute com
		sprintf com, "ModifyGraph rgb(CATS_Flask_diff_%s_%s)=(3,52428,1),rgb(CATS_RITS_diff_%s_%s)=(16385,28398,65535)", site, mol, site,mol
		execute com
		ModifyGraph grid=1
		ModifyGraph zero(left)=1
		ModifyGraph mirror=2
		ModifyGraph zeroThick(left)=3
		ModifyGraph dateInfo(bottom)={0,0,0}
		sprintf com, "Label left \"\f01%s Difference (ppt)\"", mol
		execute com
		Label bottom "\f01Date"
		SetAxis/A/N=1 left
		SetAxis/A/N=1 bottom
		sprintf com, "\\JC%s\r\\JL\\s(CATS_Flask_diff_%s_%s) CATS - Flasks \r\\s(CATS_RITS_diff_%s_%s) CATS - RITS\r\\s(Flask_RITS_diff_%s_%s) Flasks - RITS", UpperStr(site), site, mol, site, mol, site, mol
		Legend/N=text0/J/S=3/X=69.23/Y=2.33 com
	endif
	
end

Proc RITSandCATScomb(mol)
	string mol = StrMakeOrDefault("root:G_mol", "N2O")
	prompt mol, "Which molecule", popup, root:G_molLst
	
	root:G_mol = mol	
	
	RITSandCATScombFUNCT(mol)
	
end

	
// function only works with monthly means.	
function RITSandCATScombFUNCT(mol)
	string mol
	
	string sites = "brw;nwr;mlo;smo;spo;" , site
	string RPT = "root:RITS:"
	string CPT = "root:month:"
	variable inc, inc2, incC, incR, incComb, combfound, num = ItemsInList(sites, ";")
	variable /d diff
	
	NVAR dur = root:G_dur
	dur = 4		// monthly
	
	do
		site = StringFromList(inc, sites, ";")
// 		old RITS data
		wave R = $RPT + "RITS_" + site + "_" + mol
		wave Rsd = $RPT + "RITS_" + site + "_" + mol + "_sd"
		wave Rnm = $RPT + "RITS_" + site + "_" + mol + "_num"
		wave RT = $RPT + "RITS_" + site + "_" + mol + "_date"
//		new RITS data
//		if (exists(RP + "RITS_" + site + "_" + mol + "_new") == 0 )
//			return 0
//		endif
//		wave R = $RP + "RITS_" + site + "_" + mol + "_new"
//		wave Rsd = $RP + "RITS_" + site + "_" + mol + "_new_sd"
//		wave RT = $RP + "RITS_" + site + "_" + mol + "_new_date"
		wave C = $CPT + site + "_" + mol
		wave Csd = $CPT + site + "_" + mol + "_sd"
		wave Cnm = $CPT + site + "_" + mol + "_num"
		wave CT = $CPT + site + "_time"
		string combstr = "insitu_" + site + "_" + mol
		string combsdstr = "insitu_" + site + "_" + mol + "_sd"
		string combTstr = "insitu_" + site + "_" + mol + "_date"
		string combnumstr = "insitu_" + site + "_" + mol + "_num"
		
		CATSdataFolder( 1 )
		variable i, npt = (ReturnCurrentYear() + 1 - 1987) * 12, YYYY = 1987, MM = 1

		make /o/d/n=(npt) $combstr = nan, $combTstr = nan, $combsdstr = nan, $combnumstr = nan
		wave comb = $combstr
		wave combsd = $combsdstr
		wave combT = $combTstr
		wave combnum = $combnumstr
		
		variable /d T, T0
		variable RP, CP
		
		for ( i=0; i<npt; i+=1)
			T = date2secs(YYYY, MM, ReturnMidDayOfMonth(YYYY, MM))
			combT[i] = T
			
			Rp = BinarySearch(RT, T)	// RITS data is for day 1 of month
			Cp = BinarySearch(CT, T)
			
			if (( Rp <= -1 ) && ( Cp <= -1))
				comb[i] = NaN
				combSD[i] = NaN
				combNum[i] = NaN
			elseif ( (Rp > -1) && (Cp <= -1) )
				Rp = BinarySearchInterp(RT, T)
				comb[i] = R[Rp]
				combSD[i] = Rsd[Rp]
				combNum[i] = Rnm[Rp]
			elseif ( (Rp <= -1) && (Cp > -1) )
				Cp = BinarySearchInterp(CT, T)
				comb[i] = C[Cp]
				combSD[i] = Csd[Cp]
				combNum[i] = Cnm[Cp]
			else
				Rp = BinarySearchInterp(RT, T) 
				Cp = BinarySearchInterp(CT, T)
				if ( (numtype(R[Rp]) == 0) && (numtype(C[Cp]) == 2) )
					comb[i] = R[Rp]
					combSD[i] = Rsd[Rp]
					combNum[i] = Rnm[Rp]
				elseif ( (numtype(R[Rp]) == 2) && (numtype(C[Cp]) == 0) )
					comb[i] = C[Cp]
					combSD[i] = Csd[Cp]
					combNum[i] = Cnm[Cp]
				else
					comb[i] = (R[Rp]/Rsd[Rp]^2 + C[Cp]/Csd[Cp]^2) / ((1/Rsd[Rp])^2 + (1/Csd[Cp])^2)
					combSD[i] = ((1/Rsd[Rp])^2 + (1/Csd[Cp])^2) ^ (-0.5)
					combNum[i] = floor(((1/Rnm[Rp])^2 + (1/Cnm[Cp])^2) ^ (-0.5))
				endif
			endif
			
			MM += 1
			if ( MM > 12 )
				MM = 1
				YYYY += 1
			endif
			
		endfor

		SetScale d 0,0,"dat", combT
	//	killnan4(comb, combT, combsd, combnum)
				
		inc +=  1
			
	while (inc < num)
	
	SetDataFolder root:
	
end


function RITSloadRename(site, mol)
	string site, mol
	
	duplicate /o wave0, $"RITS_"+site+"_"+mol+"_yr"
	duplicate /o wave1, $"RITS_"+site+"_"+mol+"_mo"
	duplicate /o wave2, $"RITS_"+site+"_"+mol
	duplicate /o wave3, $"RITS_"+site+"_"+mol+"_sd"
	duplicate /o wave4, $"RITS_"+site+"_"+mol+"_num"
	
	killwaves wave0, wave1, wave2, wave3, wave4
	
	RITSdate(site, mol)
end



proc AppendInterpMeans() : GraphMarquee

	silent 1
	delayupdate
		
	string com
	string win = WinName(0,1)
	if (strsearch(win, "timeSeries", 0) == -1)
		abort "Can only run AppendInterpMeans on a _timeSeries plot"
	endif
	string mol = win[0, strsearch(win, "_", 0)-1]

	root:G_mol = mol
	//globalMeansWithHemisphersFUNCT(mol)
	Global_Mean_CATS(mol=mol)

	SetDataFolder root:month
		
	string brw = retInterpwave("brw", mol, 0), brwT = retInterpwave("brw", mol, 1)
	string nwr = retInterpwave("nwr", mol, 0), nwrT = retInterpwave("nwr", mol, 1)
	string mlo = retInterpwave("mlo", mol, 0), mloT = retInterpwave("mlo", mol, 1)
	string smo = retInterpwave("smo", mol, 0), smoT = retInterpwave("smo", mol, 1)
	string spo = retInterpwave("spo", mol, 0), spoT = retInterpwave("spo", mol, 1)
	
	sprintf com, "append root:interp:%s vs %s; 	ModifyGraph rgb(%s)=(65535,0,0)", brw, brwT, brw
	execute com

	sprintf com, "append root:interp:%s vs %s; 	ModifyGraph rgb(%s)=(16385,49025,65535)", nwr, nwrT, nwr
	execute com

	sprintf com, "append root:interp:%s vs %s; ModifyGraph rgb(%s)=(65535,49157,16385)", mlo, mloT, mlo
	execute com

	sprintf com, "append root:interp:%s vs %s; ModifyGraph rgb(%s)=(40969,65535,16385)", smo, smoT, smo
	execute com

	sprintf com, "append root:interp:%s vs %s; ModifyGraph rgb(%s)=(16385,16388,65535)", spo, spoT, spo
	execute com
	
	SetDataFolder root:

end

function /s  retInterpwave(site, mol, twave)
	string site, mol
	variable twave
	
	if (twave == 1)
		return  site + "_time"
	else 
		return  site + "_" + mol + "_I"
	endif
	
end


proc AppendGlobalMean(CATSw, errs) : GraphMarquee
	string CATSw 
	variable errs = 2
	prompt CATSw, "Which data set?", popup, "CATS;RITS+CATS"
	prompt errs, "Append error bars as well", popup, "yes;no"

	silent 1; delayupdate
	string com

	string win = WinName(0,1)
	if (strsearch(win, "timeSeries", 0) == -1)
		abort "Can only run AppendInterpMeans on a _timeSeries plot"
	endif
	string mol = win[0, strsearch(win, "_", 0)-1]
	
	root:G_mol = mol
	
	Global_Mean(insts=CATSw, prefix="insitu", mol=mol)
	
	string GDF = "root:global:"
	SetDataFolder $GDF
	
	string YY = "insitu_global_" + mol
	string XX = "insitu_" + mol + "_date"
	
	appendtograph $YY vs $XX
	sprintf com, "ModifyGraph lsize(%s)=3,rgb(%s)=(0,0,0)", YY, YY
	execute com
	
	if (errs == 1)
		sprintf com, "ErrorBars insitu_global_%s Y,wave=(insitu_global_%s_sd,insitu_global_%s_sd)", mol, mol, mol
		execute com
	endif

	SetDataFolder root:

end


function RITSdate(site, mol)
	string site, mol
	
	string base = "RITS_" + site + "_" + mol
	wave yr = $base + "_yr"
	wave mo = $base + "_mo"
	wave mr = $base 
	wave sd = $base + "_sd"
	wave num = $base + "_num"
	string  day = base + "_date"

	duplicate /o yr $day
	wave daywv = $day
	
	daywv = date2secs(yr, mo, 1)
	
	print day + " wave created"
end

Proc DisplayGrowthRate(mol, site, insts, prefix, diffsize, boxsize)
	string mol = StrMakeOrDefault("root:G_mol", "N2O")
	string site = StrMakeOrDefault("root:G_GRsite", "brw")
	string insts = "CATS"
	string prefix = "insitu"
	variable diffsize = NumMakeOrDefault("root:G_GRdiffsize", 12)
	variable boxsize = NumMakeOrDefault("root:G_GRboxsize", 3)
	prompt mol, "Which molecule", popup, root:G_molLst
	prompt site, "Which site", popup, "brw;nwr;mlo;smo;spo;NHem;SHem;Global"
	prompt insts, "Which data set?", popup, "CATS;CATS+RITS;CATS+RITS+OTTO;CATS+OTTO;CATS+RITS+OTTO+OldGC"
	Prompt prefix, "Name waves with the following prefix:"
	prompt diffsize, "Difference in months?"
	prompt boxsize, "Smooth box size?"
	
	silent 1
	G_mol = mol
	G_GRsite = site
	G_GRdiffsize = diffsize
	G_GRboxsize = boxsize
	
	DisplayGrowthRateFUNCT(mol, site, insts, prefix, diffsize, boxsize)
	
end

function DisplayGrowthRateFUNCT(mol, site, insts, prefix, diffsize, boxsize)
	string mol, site, insts, prefix
	variable  diffsize, boxsize

	string data, dataT, dispX, dispY, gr, grsd	
	
	Global_Mean(insts=insts, prefix=prefix, mol=mol)

	SetDataFolder root:global

	dataT = prefix + "_" + mol + "_date"
	if (cmpstr(site, "NHem") == 0)
		data = prefix + "_NH_" + mol
	elseif (cmpstr(site, "SHem") == 0)
		data = prefix + "_SH_" + mol
	elseif (cmpstr(site, "Global") == 0)
		data = prefix + "_Global_" + mol
	else
		data =  site + "_" + mol
		dataT =  data + "_time"
	endif

	GrowthRate($data, $dataT, diffsize, boxsize)
	gr = data + "_gr"
	grsd = data + "_grsd"
	
	DisplayGrowthRatePLOT(site, mol, $gr, $dataT, $grsd) 

	SetDataFolder root:
	
end


function DisplayGrowthRatePLOT(site, mol, gr, times, sd) 
	string site, mol
	wave gr, times, sd

	string com, plot = site + mol + "growthrate"
	
	DoWindow/K $plot	
	Display /K=1/W=(81,310,815,668) gr vs times
	DoWindow/C $plot	

	ModifyGraph gFont="Century Schoolbook",gfSize=16
	ModifyGraph mode=4
	ModifyGraph marker=19
	ModifyGraph rgb=(1,39321,19939)
	ModifyGraph gaps=0
	ModifyGraph grid=1
	ModifyGraph mirror=1
	ModifyGraph dateInfo(bottom)={0,0,0}
	if (cmpstr(mol, "N2O") == 0)
		Label left "Growth Rate (ppb / yr)"
	else
		Label left "Growth Rate (ppt / yr)"
	endif
	Label bottom "Date"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	sprintf com, "ErrorBars %s Y,wave=(%s,%s)", NameOfWave(gr), NameOfWave(sd), NameOfWave(sd)
	execute com
	sprintf com, "Legend/N=text0/J/X=74.84/Y=86.86 \"\\s(%s) %s\"", NameOfWave(gr), NameOfWave(gr)
	execute com
	
	sprintf com, "ErrorBars %s OFF ", NameOfWave(gr)
	execute com
	
End


Proc DisplayInterhemiDiff(mol, Insts, prefix, boxsize)
	string mol = StrMakeOrDefault("root:G_mol", "N2O")
	String Insts = StrMakeOrDefault("root:globalS_InstList", "CATS")
	String prefix = root:global:S_prefix
	variable boxsize = NumMakeOrDefault("root:G_IHDboxsize", 3)
	prompt mol, "Which molecule", popup, root:G_molLst
	prompt Insts, "Which data set?", popup, "CATS;CATS+RITS;CATS+RITS+OTTO;CATS+OTTO;CATS+RITS+OTTO+OldGC;CATS+RITS+OTTO+OldGC+CCGG"
	prompt prefix, "Prefix"
	prompt boxsize, "Smoothing box size?"
	
	silent 1
	root:G_mol = mol
	G_IHDboxsize = boxsize
	root:global:S_prefix = prefix
	
	DisplayInterhimDiffFUNCT(mol, Insts, prefix, boxsize)
	
end

function DisplayInterhimDiffFUNCT(mol, insts, prefix, boxsize)
	string mol, insts, prefix
	variable boxsize

	Global_Mean(insts=insts, prefix=prefix, mol=mol)

	string GDF = "root:global:"

	wave NH = $(GDF + prefix + "_NH_" + mol)
	wave SH = $(GDF +  prefix + "_SH_" + mol)
	wave dataT = $(GDF +  prefix + "_" + mol + "_date")
	
	SetDataFolder $GDF
	
	string IHDstr = "insitu_IHD_" + mol
	make /o/n=(numpnts(NH)) $IHDstr = NAN
	wave IHD = $IHDstr
	
	IHD = NH-SH
	
	if (boxsize > 0)
		Smooth boxsize, IHD
	endif

	DisplayInterhimDiffPLOT(mol, IHD, dataT)
	
	SetDataFolder root:

end

function DisplayInterhimDiffPLOT(mol, IHD, dataT)
	string mol
	wave IHD, dataT

	string com, plot = mol+"IHDplot"
	
	DoWindow/K $plot	
	Display /W=(124,246,746,569) IHD vs dataT
	DoWindow/C $plot	
	
	ModifyGraph lSize=2
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph font="Times"
	ModifyGraph fSize=16
	ModifyGraph dateInfo(bottom)={0,0,0}
	
	if (cmpstr(mol, "N2O") == 0)
		Label left "\\f01Interhemispheric Difference (ppb)"
	else
		Label left "\\f01Interhemispheric Difference (ppt)"
	endif
	Label bottom "\\f01Date"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom

	sprintf com, "Legend/N=text0/J \"\\s(%s) %s\"", NameOfWave(IHD), NameOfWave(IHD)
	execute com
	
End


Proc UpdateGlobalGrowthRates( skip )
	variable skip = 2
	prompt skip, "Skip Global Mean Calculations", popup, "yes;no"
	
	silent 1
	if ( skip == 2)
		Global_Mean_Stations("ritsnew;otto;cats;oldgc", "HATS", mol="F12")
		Global_Mean_Stations("ritsnew;otto;cats;oldgc", "HATS", mol="F11")
		Global_Mean_Stations("ritsnew;otto;cats;oldgc", "insitu", mol="F12")
		Global_Mean_Stations("ritsnew;otto;cats;oldgc", "insitu", mol="F11")
		Global_Mean_Stations("cats;otto", "insitu", mol="F113")
		Global_Mean_Stations("ritsnew;cats;otto", "insitu", mol="CCl4")
		Global_Mean_Stations("ritsnew;cats;otto", "insitu", mol="MC")
		Global_Mean_Stations("cats", "insitu", mol="HCFC22")
		Global_Mean_Stations("cats", "insitu", mol="HCFC142b")
		Global_Mean_Stations("cats", "insitu", mol="CHCl3")
		Global_Mean_Stations("cats", "insitu", mol="CH3Cl")
		Global_Mean_Stations("cats", "insitu", mol="h1211")
	
		// other
		Global_Mean_Stations("ritsnew;cats", "insitu", mol="N2O")
		Global_Mean_Stations("otto;cats", "insitu", mol="SF6")
	endif

	variable inc
	string mollst = "F12;F11;F113;MC;CCl4;CHCl3;HCFC22;HCFC142b;N2O;SF6"
	string mol, data, dataT, gr
	SetDataFolder root:global:

	do
		mol = GetStrFromList(mollst, inc, ";")
		data = "insitu_global_" + mol
		dataT ="insitu_" + mol + "_date"
		gr = data + "_gr"
		GrowthRate($data, $dataT, 12, 12)
		Smooth 3, $gr
		inc += 1
	while (inc < NumElementsInList(mollst, ";"))
	SetDataFolder root:
end
	
Proc PrintGlobalGrowthRates( year )
	variable year = ReturnCurrentYear()

	variable inc
	string mollst = "F12;F11;F113;MC;CCl4;CHCl3;HCFC22;HCFC142b;H1211;N2O;SF6"
	string mol, data, dataT, gr

	variable Yl = date2secs(year, 1, 1)
	variable Yh = date2secs(year+1, 1, 1)

	SetDataFolder root:global:
	do
		mol = StringFromList(inc, mollst)
		data = "insitu_global_" + mol
		dataT ="insitu_" + mol + "_date"
		gr = data + "_gr"
		GrowthRate($data, $dataT, 12, 12)
//		Smooth 6, $gr
		Extract /o $gr, grYear, ($dataT >= Yl) && ($dataT < Yh)
		WaveStats /Q grYear
		print mol + " avg growth rate = ", V_avg, "�", V_sdev
		inc += 1
	while (inc < NumElementsInList(mollst, ";"))
	
	killwaves grYear
	
	SetDataFolder root:

end

Proc CalculateTotalCl()

	silent 1; delayupdate

	RITSandCATScomb("F12")
	RITSandCATScomb("F11")
	RITSandCATScomb("MC")
	RITSandCATScomb("CCl4")
	GlobalMeansWithHemisphers("F12",2)
	GlobalMeansWithHemisphers("F11",2)
	GlobalMeansWithHemisphers("F113",1)
	GlobalMeansWithHemisphers("MC",2)
	GlobalMeansWithHemisphers("CCl4",2)
	GlobalMeansWithHemisphers("CHCl3",1)
	GlobalMeansWithHemisphers("HCFC22",1)
	GlobalMeansWithHemisphers("HCFC142b",1)
	GlobalMeansWithHemisphers("CH3Cl",1)
	GlobalMeansWithHemisphers("H1211",1)

	// used on total cl plot
	duplicate /o insitu_global_F12 insitu_global_F12_Cl
	duplicate /o insitu_global_F11 insitu_global_F11_Cl
	duplicate /o insitu_global_F113 insitu_global_F113_Cl
	duplicate /o insitu_global_MC insitu_global_MC_Cl
	duplicate /o insitu_global_CCl4 insitu_global_CCl4_Cl
	duplicate /o insitu_global_CHCl3 insitu_global_CHCl3_Cl
	duplicate /o insitu_global_HCFC22 insitu_global_HCFC22_Cl
	duplicate /o insitu_global_HCFC142b insitu_global_HCFC142b_Cl
	duplicate /o insitu_global_CH3Cl insitu_global_CH3Cl_Cl
	duplicate /o insitu_global_H1211 insitu_global_H1211_Cl
	
	insitu_global_F12_Cl *= 2
	insitu_global_F11_Cl *= 3
	insitu_global_F113_Cl *= 3
	insitu_global_CCl4_Cl *= 4
	insitu_global_MC_Cl *= 3
	insitu_global_CHCl3_Cl *= 3
	
	CalculateTotalClFUNCT()
	
	variable inc
	do
		if ( insitu_global_totalCl_date[inc] < insitu_global_F113_date[0] )
			insitu_global_totalCl[inc] = nan
		endif
		inc += 1
	while (inc < numpnts(insitu_global_totalCl_date))
		
end

function CalculateTotalClFUNCT()
	
	wave F12 = insitu_global_F12
	wave F11 = insitu_global_F11
	wave F113 = insitu_global_F113
	wave MC = insitu_global_MC				// CH3CCl3
	wave CCl4 = insitu_global_CCl4
	wave CHCl3 = insitu_global_CHCl3
	wave HCFC22 = insitu_global_HCFC22
	wave HCFC142b = insitu_global_HCFC142b
	wave CH3Cl = insitu_global_CH3Cl
	wave H1211 = insitu_global_H1211

	wave /d F12d = insitu_global_F12_date
	wave /d F11d = insitu_global_F11_date
	wave /d F113d = insitu_global_F113_date
	wave /d MCd = insitu_global_MC_date
	wave /d CCl4d = insitu_global_CCl4_date
	wave /d CHCl3d = insitu_global_CHCl3_date
	wave /d HCFC22d = insitu_global_HCFC22_date
	wave /d HCFC142bd = insitu_global_HCFC142b_date
	wave /d CH3Cld = insitu_global_CH3Cl_date
	wave /d H1211d = insitu_global_H1211_date
	
	duplicate /o F12, insitu_global_TotalCl
	duplicate /o F12d, insitu_global_TotalCl_date

	wave TotalCl = insitu_global_TotalCl
	wave /d TotalCld = insitu_global_TotalCl_date
	TotalCl = 0

	SumTotalCl( F12, F12d, totalCl, totalCld, 2 )
	SumTotalCl( F11, F11d, totalCl, totalCld, 3 )
	SumTotalCl( F113, F113d, totalCl, totalCld, 3 )
	SumTotalCl( MC, MCd, totalCl, totalCld, 3 )
	SumTotalCl( CCl4, CCl4d, totalCl, totalCld, 4 )
	SumTotalCl( CHCl3, CHCl3d, totalCl, totalCld, 3 )
	SumTotalCl( HCFC22, HCFC22d, totalCl, totalCld, 1 )
	SumTotalCl( HCFC142b, HCFC142bd, totalCl, totalCld, 1 )
	SumTotalCl( CH3Cl, CH3Cld, totalCl, totalCld, 1 )
	SumTotalCl( H1211, H1211d, totalCl, totalCld, 1 )
	
	// add 150 ppt for other unmeasured Cl compounds
	totalCl += 150

end

function SumTotalCl( mol, mold, totalCl, totalCld, mult )
	wave mol, mold, totalCl, totalCld
	variable mult
	
	variable inc = 0, pt
	do
		pt = BinarySearch(TotalCld, mold[inc])
		if (pt != -1)
			TotalCl[pt] += (mol[inc] * mult)
		endif
		inc += 1
	while (inc < numpnts(mold))
		
end

function GrowthRate(molwv, daywv, diffsize, smfc)
	wave molwv, daywv
	variable diffsize, smfc
	
	wave molsd = $(nameofwave(molwv) + "_sd")
	string grSTR = nameofwave(molwv) + "_gr"
	string grsdSTR = nameofwave(molwv) + "_grsd"
	make /n=(numpnts(molwv)) /o $grSTR/WAVE=gr = nan, $grsdSTR/WAVE=grsd =nan
	
	variable inc = 0
	variable /d year = 60*60*24*365.25
	variable /d diffinc = year/12 * diffsize
	variable /d day, day1
		
	for(inc=0; inc<numpnts(molwv); inc+=1)
		day = daywv[inc]
		day1 = day - diffinc
		
		Findlevel /q daywv, day1
		if (V_flag == 0)
			gr[inc] = molwv[inc]  - molwv[V_LevelX]
			grsd[inc] = Sqrt(molsd[inc]^2 + molsd[V_LevelX]^2)
		else
			gr[inc] = nan
			grsd[inc] = nan
		endif
	endfor
	
	if (smfc > 0)
		Smooth smfc, gr
	endif
	
end


// Function will sync the "other" waves to the "base" waves.  The 
// function will create new synced waves with the suffix "suf"
function SyncTwoDataSets(baseX, baseY, otherX, otherY, suf)
	wave/d  baseX, baseY, otherX, otherY
	string suf
	
	string newXst = NameOfWave(OtherX) + "_" + suf
	string newYst = NameOfWave(OtherY) + "_" + suf
	
	variable/d num = numpnts(baseX), inc = 0
	
	make /d/n=(num)/o $newXst = nan, $newYst = nan
	wave newX = $newXst
	wave newY = $newYst
	
	newX = baseX
	newY = nan
	newY = otherY[BinarySearchInterp(otherX, baseX)]
	
end

// Function with make a background wave (0.20 percentile) with suffix "suf"
function RunningBoxBackground(baseX, baseY, suf)
	wave/d baseX, baseY
	string suf

	string newYst = NameOfWave(baseY) + "_" + suf
	variable/d num = numpnts(baseX), inc = 0, lx, lp, rp, cnt
	variable boxSize = 60*60*24*10		// 10 days (in seconds)
	variable percentile = 0.20
	
	make /d/n=(num)/o  $newYst = nan
	make /o  box_tmp
	wave newY = $newYst 
	newY = nan
	
	do
		lx = baseX[inc]
		findlevel /Q baseX, lx+boxSize
		if (V_flag == 0)
			rp = V_levelX
			duplicate /s/o /R=[inc, rp] baseY, box_tmp
			Redimension /S box_tmp
			execute "xdelete /e=(nan) box_tmp"
			if (exists("box_tmp") == 0)
				newY[cnt] = nan
			else
				sort box_tmp, box_tmp
				findlevel /Q baseX, lx+(boxSize/2)
				cnt = V_levelX
				newY[cnt] = box_tmp[numpnts(box_tmp) * percentile]
			endif
		endif
		inc += 5
		if (mod(inc,10000) == 0)
			print inc
		endif
	while (inc < num)
	
	killwaves box_tmp

end

function SplitNightAndDay(dataY, dataX, gmtOffset)
	wave/d dataY, dataX
	variable gmtOffset
	
	variable inc, num=numpnts(dataX)
	string dayStr = NameOfWave(dataY) + "_day"
	string nightStr = NameOfWave(dataY) + "_night"
	
	duplicate /o dataY, $dayStr, $nightStr
	wave day = $dayStr
	wave night = $nightStr
	day = nan
	night = nan
	
	do
		if (AtNight(dataX[inc], gmtOffset) == 1)
			night[inc] = dataY[inc]
		else
			day[inc] = dataY[inc]
		endif
		inc += 1
	while (inc < num)
	
end

// Returns 1 if at night, 0 otherwise.
function AtNight(timeSecs, gmtOffset)
	variable/d timeSecs
	variable gmtOffset
	
	string timeStr = Secs2Time(timeSecs, 2)
	variable hour = str2num(StringFromList(0, timeStr, ":")) + gmtoffset
	//print hour
	if (hour > 23)
		hour -= 24
	elseif (hour < 0)
		hour += 24
	endif


	if ((hour < 8) + (hour >= 17))
		return 1
	else
		return 0
	endif
end



// set skip=1 to skip the prompt dialog and use presets.
function SeasonalPlot([skip])
	variable skip
	
	string mol, site

	// make data folder
	String savedDF= "root:"
	string DF = "root:Seasonal"
	if ( ! DataFolderExists(DF) )
		NewDataFolder $DF
	endif

	variable Y1 = NumMakeOrDefault("root:Seasonal:G_Y1", 1998)
	variable Y2 = NumMakeOrDefault("root:Seasonal:G_Y2", ReturnCurrentYear())
	variable det = NumMakeOrDefault("root:Seasonal:G_detrend", 1)
	NVAR /Z G_Y1 = root:Seasonal:G_Y1
	NVAR /Z G_Y2 = root:Seasonal:G_Y2
	NVAR /Z G_det = root:Seasonal:G_detrend
		
	SVAR G_mol = G_mol
	SVAR G_site = root:G_site
	SVAR mollst = root:G_molLst
	SVAR sites = root:G_siteLst
	mol = G_mol
	site = G_site
	
	prompt mol, "Which molecule", popup, mollst
	prompt site, "Which site", popup, sites
	prompt det, "Detrend Method", popup, "poly 3;line;exp"
	prompt Y1, "First year to include"
	prompt Y2, "Last year to include"
	if ( !skip )
		DoPrompt "Enter data", mol, site, det, Y1, Y2
		if (V_flag)
			return -1
		endif
	endif

	G_mol = mol
	G_site = site
	G_Y1 = Y1
	G_Y2 = Y2
	G_det = det

	variable i
	string Xdat, Ydat, SD
	string Xsea, Ysea, SDsea
	Xsea = site + "_" + mol + "_seasonalX"
	Ysea = site + "_" + mol + "_seasonalY"
	SDsea = site + "_" + mol + "_seasonalSD"
	wave global = $"root:insitu_global_" + mol
	wave globalX = $"root:insitu_global_" + mol + "_date"
	wave globalSD = $"root:insitu_global_" + mol + "_SD"
	variable /d normX = date2secs(2007, 1, 1)
	variable nor = global[BinarySearch(globalX, normX)]
	
	// Select the data
	Ydat = "root:" + site + "_" + mol
	if (exists(Ydat+"comb"))
		Xdat = "root:" + site + "_" + mol + "comb_time"
		Ydat = "root:" + site + "_" + mol + "comb"
		SD = "root:" + site + "_" + mol + "comb_SD"
	else
		Xdat = "root:" + site + "_" + mol + "_time"
		SD = "root:" + site + "_" + mol + "_SD"
	endif
	
	SetDataFolder $DF

	wave XdatWv = $Xdat
	wave YdatWv = $Ydat
	wave SDdatWv = $SD
	
	Extract /o XdatWv, SubsetX, ((XdatWv > date2secs(Y1, 1,1)) && (XdatWv <= date2secs(Y2,12,31)))
	Extract /o YdatWv, SubsetY, ((XdatWv > date2secs(Y1, 1,1)) && (XdatWv <= date2secs(Y2,12,31)))
	Extract /o SDdatWv, SubsetSD, ((XdatWv > date2secs(Y1, 1,1)) && (XdatWv <= date2secs(Y2,12,31)))
	SetScale d 0,0,"dat", SubsetX

	DoWindow /K Detrended
	display /K=1 SubsetY vs SubsetX
	ModifyGraph mode=3,rgb=(3,52428,1)
	DoWindow /C Detrended

	// detrend 
	if (det == 2)
		CurveFit/Q/NTHR=0 line,  SubsetY /X=SubsetX /W=SubsetSD /I=1 /D
	elseif (det == 3 )
		CurveFit/Q/NTHR=0 exp_XOffset,  SubsetY /X=SubsetX /W=SubsetSD /I=1 /D
//		CurveFit/Q/NTHR=0 exp_XOffset,  Global /X=GlobalX /W=GlobalSD /I=1 /D
	else
		CurveFit/NTHR=0 poly 3,  SubsetY /X=SubsetX /W=SubsetSD /I=1 /D
//		CurveFit/Q/NTHR=0 poly 3,  Global /X=GlobalX /W=GlobalSD /I=1 /D
	endif
	wave coef = W_coef
	wave W_fitConstants = W_fitConstants
	wave fit_SubsetY

	duplicate /o SubsetX, $Xsea
	duplicate /o SubsetX, SeasonalX_YYYY
	duplicate /o SubsetY, $YSea
	duplicate /o SubsetSD, $SDsea
	wave XseaWv = $Xsea
	wave YseaWv = $Ysea
	wave SDseaWv = $SDsea

	// convert date wave to fraction of year
	XseaWv = (XdatWv - date2secs(str2num(secs2date(XdatWv,-1)[6,10]),1,1)) / (60*60*24*365)	
	SetScale d 0,0,"", XseaWv
	
	if (det == 2)
		YseaWv = (SubsetY - (coef[0]+coef[1]*SubsetX))
	elseif ( det == 3 )
		YseaWv = (SubsetY - (coef[0]+coef[1]*exp(-(SubsetX-W_fitConstants[0])/coef[2])))
	else
		YseaWv = (SubsetY - poly(coef, SubsetX))		// detrended Y data
	endif
	YseaWv = YseaWv / nor  * 100						// relative scale in percent
	
	Sort XseaWv, XseaWv, YseaWv, SDseaWV, SeasonalX_YYYY
	KillNaN4(XseaWv, YseaWv, SDseaWV, SeasonalX_YYYY)

	string win = site + "_" + mol + "_SeasonalTrend"
	DoWindow /K $win
	Display /K=1/W=(662,292,1448,750) YseaWv vs XseaWv
	DoWindow /C $win
	
	K2=2*Pi
	//Make/O/T/N=2 T_Constraints
	//T_Constraints[0] = {"K3 > 0","K3 < 6.28319"}
	CurveFit/B=(numpnts(YseaWv)) /H="0010"/NTHR=0/TBOX=768 sin  YseaWv /X=XseaWv /W=SDseaWv /I=1 /D  /F={0.950000,7}
	string fit = "fit_" + Ysea

	ModifyGraph mode($Ysea)=3
	ModifyGraph marker($Ysea)=8
	ModifyGraph msize($Ysea)=2
	ModifyGraph lSize($fit)=2
	ModifyGraph rgb($Ysea)=(3,52428,1)
	
	Label left "Detrended " + mol
	Label bottom "Fraction of year"
	
	SetDataFolder $savedDF

end

function SeasonalCycles()

	SVAR G_mol = G_mol
	SVAR G_site = G_site
	SVAR mollst = root:G_molLst
	string mol = G_mol
	variable reload = 1
	
	prompt mol, "Which molecule", popup, mollst
	prompt reload, "Load data?", popup, "No;Yes"
	DoPrompt "Enter data", mol, reload
	if (V_flag)
		return -1
	endif

	G_mol = mol
	
	// load data
	if ( reload == 2 )
		load_DataFUNCT("_ALL_",mol,4,2)
//		globalMeansWithHemisphersFUNCT(mol)
		Global_Mean(insts="cats;", prefix="insitu", mol=mol)
		load_DataFUNCT("_ALL_", mol,1,2)
	endif
	
	// seasonal cycle plots
	G_site = "brw"; SeasonalPlot(skip=1); DoWindow /K $(G_site + "_" + mol + "_SeasonalTrend")
//	G_site = "sum"; SeasonalPlot(skip=1); DoWindow /K $(G_site + "_" + mol + "_SeasonalTrend")
	G_site = "nwr"; SeasonalPlot(skip=1); DoWindow /K $(G_site + "_" + mol + "_SeasonalTrend")
	G_site = "mlo"; SeasonalPlot(skip=1); DoWindow /K $(G_site + "_" + mol + "_SeasonalTrend")
	G_site = "smo"; SeasonalPlot(skip=1); DoWindow /K $(G_site + "_" + mol + "_SeasonalTrend")
	G_site = "spo"; SeasonalPlot(skip=1); DoWindow /K $(G_site + "_" + mol + "_SeasonalTrend")
	
	SetDataFolder root:Seasonal:
	
	string brw = "fit_brw_" + mol + "_seasonalY"
	string sum = "fit_sum_" + mol + "_seasonalY"
	string nwr = "fit_nwr_" + mol + "_seasonalY"
	string mlo = "fit_mlo_" + mol + "_seasonalY"
	string smo = "fit_smo_" + mol + "_seasonalY"
	string spo = "fit_spo_" + mol + "_seasonalY"
	string win = mol + "_Seasonal_Cycles"
	
	DoWindow /K $win
	Display /K=1/W=(58,60,756,498) $brw, $nwr, $mlo, $smo, $spo
	DoWindow /C $win

	ModifyGraph rgb($brw)=(0,0,65535),rgb($nwr)=(0,43690,65535)
	ModifyGraph rgb($smo)=(65535,43690,0),rgb($spo)=(0,0,0)

//	if ( (cmpstr(mol,"N2O") == 0) || (cmpstr(mol,"N2Oa") == 0) )
//		Label left "N2O (ppb)"
//	else
//		Label left mol + " (ppt)"
//	endif		
	Label left mol + " (percent)"
	Label bottom "Fraction of Year"
	SetAxis/A/N=1 left
	
	string led 
	sprintf led, "\\s(%s) brw \\s(%s) nwr \\s(%s) mlo \r\\s(%s) smo \\s(%s) spo", brw, nwr, mlo, smo, spo
	Legend/C/N=text0/J/X=0.99/Y=-0.80 led
	
	SetDataFolder root:
	
end

