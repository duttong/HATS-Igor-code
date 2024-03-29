#pragma rtGlobals=1		// Use modern global access method.
#include <Readback ModifyStr>

// the _flagtype wave is the following.
constant NO_FLAG = NaN
constant FLAG_MANUAL = 1
constant FLAG_STATISTICAL = 2
constant FLAG_IDL = 3
constant FLAG_DELTA = 4
constant FLAG_LOWFLOW = 5
constant FLAG_REDICULOUS = 9

constant SSV_CAL1 = 2
constant SSV_AIR1 = 4
constant SSV_CAL2 = 6
constant SSV_AIR2 = 8

function AppendFlaggedData()

	SVAR mol = G_mol
	mol = MolFromGraph()
	
	string flg = mol + "_best_conc_flg"
	string type = mol + "_flagtype"
	string d = mol + "_date"
	
	variable hide = GetNumFromModifyStr(TraceInfo("", flg, 0), "hideTrace", "", 0)
	if (numtype(hide) == 2)		// trace not on graph
		AppendToGraph $flg vs $d
		ModifyGraph mode($flg)=3
		ModifyGraph textMarker($flg)={$type,"Courier New Bold",1,0,5,0.00,0.00}
		ModifyGraph rgb($flg)=(65535,0,1)
	else
		hide = hide == 0
		ModifyGraph hideTrace($flg)=hide
	endif
		
	GetAxis /Q left
	SetAxis left V_min, V_max
	GetAxis /Q bottom
	SetAxis bottom V_min, V_max
	
end


// does not use manual flag
proc FlagLowSampFlow( mol, lowflow )
	string mol=StrMakeOrDefault("root:G_mol", "F11")
	variable lowflow = 40
	prompt mol, "Molecule", popup, G_loadMol
	prompt lowflow, "Flag if sample loop flow is below"

	silent 1; pauseupdate

	G_mol = mol

	FlagLowSampFlowFUNCT( mol, lowflow )

end

function FlagLowSampFlowFUNCT ( mol, lowflow )
	string mol
	variable lowflow
	
	SVAR site = G_site3
	wave flag = $(mol + "_flag")
	wave ftype = $mol + "_flagtype"
	wave flow = $(mol + "_sampflow")
	wave day = $(mol + "_date" )
	variable inc = 0, n=numpnts(flag), flaginc = 0
	
	do
		if ( flow[inc] < lowflow )
			if ( cmpstr(site,"brw") == 0)		// don't flag brw data between 11/10/99 and 3/30/00 (no flow controller)
				if ( (day[inc] < date2secs( 1999, 10, 20 ) ) || (day[inc] > date2secs( 2000, 3, 30 ) ) )
					flag[inc] = nan
					ftype[inc] = FLAG_LOWFLOW
					flaginc += 1
				endif					// flow meter broken at brw
				if ( (day[inc] < date2secs( 2011, 5, 1 ) ) || (day[inc] > date2secs( 2012, 1, 1 ) ) )
					flag[inc] = nan
					ftype[inc] = FLAG_LOWFLOW
					flaginc += 1
				endif
			elseif ( cmpstr(site, "spo") == 0)	
				if ( day[inc] > date2secs( 1999, 1, 1 ) )
					flag[inc] = nan
					ftype[inc] = FLAG_LOWFLOW
					flaginc += 1
				endif
			else
				flag[inc] = nan
				ftype[inc] = FLAG_LOWFLOW
				flaginc += 1
			endif			
		endif
		inc += 1
	while ( inc < n )
	
	print "Flagged ", flaginc, " points below ", lowflow, "cc/min."
	
end


// There are two figures that this function should be called from, either?
//  the cal flagging figure (waves like c1 or c2) or
//  the best_conc figure.
function FlagInsideBoxFAST() :GraphMarquee

	string mol = MolFromGraph()
	string wvs = StringFromList(0, TraceNameList("", ";", 1))
	Wave wv = $wvs
	
	NVAR G_recalcSD
		
	// best_conc figure
	if (strsearch(wvs, "hourlyY", 0) > -1 )

		FlagInsideBoxFUNCT (wv, mol, 2)
	
	elseif(strlen(wvs) == 2)

		SVAR attrib = G_attrib
		wave flag = $mol + "_flag"
		wave man = $mol + "_manflag"
		wave ftype = $mol + "_flagtype"
		wave flg = $mol + "_best_conc_flg"
		wave day = $mol + "_date"
		wave resp = $mol + "_" + attrib

		G_recalcSD = 1

		GetMarquee /K left, bottom	
		
		// Check to see if the wave is plotted as and XY pair.
		// check for XY pairing
		if ( WaveExists(XWaveRefFromTrace("", wvs)) )
			wave wvx = XWaveRefFromTrace("", wvs)
			Extract /FREE/INDX/O wv, cpnts, ( (wvx > V_left) && (wvx < V_right) && (wv < V_top) && (wv > V_bottom) )
		else
			return 0
		endif
		
		Variable i, pt
		for(i = 0; i<numpnts(cpnts); i+=1)
			pt = BinarySearch(day, wvx[cpnts[i]])
			man[pt] = NaN
			ftype[pt] = FLAG_MANUAL
			flg[pt] = wv[pt]
			flag[pt] = NaN
			resp[pt] = NaN

			wv[cpnts[i]] = NaN
		endfor
		
		CreateCalRatios(mol, attrib)
	
	else
		return 0
	endif

end

proc FlagInsideBoxFAST_old () : GraphMarquee

	variable flagtype = 2
	string mol = MolFromGraph()
	string wv = SelectFlagWave(TraceNameList("", ";", 1))
	string suffix = wv[strsearch(wv,"_",0)+1,200]
	
	Silent 1; pauseupdate
	G_flagwhichwv = wv
	G_flagtype = flagtype
	
	if (cmpstr(suffix,"date") == 0)
		abort "Can't flag _date waves"
	endif
	
	if (strsearch(WinName(0,1), "ratio", 0) != -1 )
		G_recalcSD = 1
	endif

	FlagInsideBoxFUNCT ($wv, mol, flagtype)
	
end


proc FlagInsideBox (wv, flagtype) : GraphMarquee
	string wv = SelectFlagWave(WaveList("*", ";","WIN:"))
	variable flagtype=NumMakeOrDefault("root:G_flagtype", 2)
	prompt wv, "Which wave?", popup SortList(WaveList("*", ";","WIN:"),";",1)
	prompt flagtype, "Which flag type?", popup "statistical flag;manual flag"
	string mol = wv[0,strsearch(wv,"_",0)-1]
	string suffix = wv[strsearch(wv,"_",0)+1,200]
	
	silent 1; pauseupdate
	G_flagwhichwv = wv
	G_flagtype = flagtype
	G_mol = mol
	
	if (cmpstr(suffix,"date") == 0)
		abort "Can't flag _date waves"
	endif
	
	if (strsearch(WinName(0,1), "ratio", 0) != -1 )
		G_recalcSD = 1
	endif

	FlagInsideBoxFUNCT ($wv, mol, flagtype)
	
end

// this function was missing??? GSD 20200319
function /S SelectFlagWave(wvlst)
	string wvlst
	
	variable i
	string wvname
	
	for(i=0; i<ItemsInList(wvlst); i+=1)
		wvname = StringFromList(i, wvlst)
		if (strsearch(wvname, "hourlyY", 0) > 0)
			return wvname
		endif
	endfor
	
end

function FlagInsideBoxFUNCT (wv, mol, flagtype)
	wave wv
	string mol
	variable flagtype

	wave flag = $mol + "_flag"
	wave man = $mol + "_manflag"
	wave ftype = $mol + "_flagtype"
	wave /Z flg = $mol + "_best_conc_flg"
	string wvStr = NameOfWave(wv)
	variable i
	
	GetMarquee /K left, bottom	
	
	// Check to see if the wave is plotted as and XY pair.
	// check for XY pairing
	if ( WaveExists(XWaveRefFromTrace("", wvStr)) )
		wave wvx = XWaveRefFromTrace("", wvStr)
		Extract /FREE/INDX/O wv, JunkY, ( (wvx > V_left) && (wvx < V_right) && (wv < V_top) && (wv > V_bottom) )
	else
		Extract /FREE/INDX/O wv, JunkY, ( (pnt2x(wv, p) > V_left) && (pnt2x(wv,p) < V_right) && (wv < V_top) && (wv > V_bottom) )
	endif
	
	for(i = 0; i<numpnts(JunkY); i+=1)
		if ( flagtype == 2 )
			man[JunkY[i]] = NaN
			ftype[JunkY[i]] = FLAG_MANUAL
			flg[JunkY[i]] = wv[JunkY[i]]
			wv[JunkY[i]] = NaN
		endif
		flag[JunkY[i]] = NaN
	endfor
	
	//wv = wv * flag
	
end


// Function will calculate stats on dayBox days and flag the "sig" outliers
function FlagEveryNDays(wvY, wvX, flagWv, sig, days)
	wave wvY, wvX, flagWv
	variable sig, days
	
	variable dayBox =  days	// number of days in a box
	variable daySecs = dayBox * 60 * 60 * 24
	variable num = numpnts(wvY)
	variable /d lx, lp, rx, rp, inc2
	
	string mol = (NameOfWave(flagWv))[0,strsearch(NameOfWave(flagWv),"_",0)-1]
	wave ftype = $mol + "_flagtype"
	
	lp = 0
	lx = wvX[lp]
	do	
		rx = lx + daySecs
		rp = BinarySearch(wvX, rx)
		
		Wavestats /Q /R=(lp, rp) wvY
		
		// Now flag outliers
		inc2 = lp
		do
		 	if (( wvY[inc2] > (V_avg + sig*V_adev) ) || ( wvY[inc2] <= (V_avg - sig*V_adev) ))
		 		flagWv[inc2] = NaN
		 		ftype[inc2] = FLAG_STATISTICAL
		 	endif
			inc2 += 1
		while (inc2 <= rp)
		
		lx += 1*60*60*24		// step one day
		lp = BinarySearch(wvX, lx)
	
	while (lp != -2)
	
end

// Function will calculate stats on dayBox days and flag the "sig" outliers
Function NaNEveryNDays(wvY, wvX,  sig, days)
	wave wvY, wvX
	variable sig, days
	
	variable daySecs = days * 60 * 60 * 24
	variable step = SelectNumber(days/4 > 1, 1, days/4)
	variable num = numpnts(wvY)
	variable /d lx, lp, rx, rp, inc2
	
	lp = 0
	lx = wvX[lp]

	do	
		rx = lx + daySecs
		rp = BinarySearch(wvX, rx)
		
		Wavestats /Q /R=[lp, rp] wvY
		K3 = sig*V_sdev		// use variable to speed up calc a little
		
		// Now NAN outliers
		// the selectnumber approach is slower.
		//wvY[lp, rp] = SelectNumber((wvY>(V_avg+sig*V_sdev)) || (wvY <= (V_avg-sig*V_sdev)), wvY, NaN)
		for(inc2=lp; inc2<=rp; inc2+=1)
		 	if (( wvY[inc2] > (V_avg + K3) ) || ( wvY[inc2] <= (V_avg - K3) ))
		 		wvY[inc2] = NaN
		 	endif
		 endfor
		
		lx += step * 60*60*24		// step
		lp = BinarySearch(wvX, lx)
	
	while (lp != -2)
	
end



// sets the manual flag
proc FlagDateRange () : GraphMarquee
	silent 1; pauseupdate
	string mol = MolFromGraph()
	string wv = mol + "_best_conc_hourlyY"

	G_mol = mol
	GetMarquee /K left, bottom
	FlagDateRangeFUNCT(V_left, V_right, 1)
end

function FlagDateRangeFUNCT(minVal, maxVal, toflag)
	variable /d minVal, maxVal
	variable toflag
	
	SVAR mol = root:G_mol
	variable pl, pr, i

	wave flag = $mol + "_flag"
	wave man = $mol + "_manflag"
	wave ftype = $mol + "_flagtype"
	wave flg = $mol + "_best_conc_flg"
	wave conc = $mol + "_best_conc_hourlyY"
	wave /d dateWv = $mol + "_date"
	
	// left side
	FindLevel /P dateWv, minVal
	if (V_flag)
		return 0
	else 
		pl = floor(V_levelX)
	endif
	
	// right side
	FindLevel /P/R=[pl] dateWv, maxVal
	if (V_flag)
		return 0
	else 
		pr = ceil(V_levelX)
	endif
	
	for (i=pl; i<pr; i+=1)
		if ( toflag == 1 )
			flg[i] = numtype(flg[i]) == 0 ? flg[i] :  conc[i] 
			flag[i] = NaN
			conc[i] = NaN
			man[i] = NaN
			ftype[i] = FLAG_MANUAL
		else 
			flag[i] = 1
			ftype[i] = NO_FLAG
			conc[i] = flg[i]
			flg[i] = NaN
			man[i] = 1
		endif				
	endfor

end

// will not unflag manual flags!
proc UnFlagDateRange () : GraphMarquee
	silent 1; pauseupdate
	string wv = GetStrFromList(WaveList("*", ";","WIN:"), 1, ";")
	string mol = wv[0,strsearch(wv,"_",0)-1]
	string flagSTR = mol + "_flag"
	variable /D V_left, V_right
	
	if (exists(flagSTR) != 1)
		make /n=(numpnts($wv)) $flagSTR = 1
	endif
	
	GetMarquee left, bottom	
	
	FlagDateRangeFUNCT($flagSTR, $mol+"_date", V_left, V_right, 0)
end

// rewritten 130227
function FlagPort() :GraphMarquee

	Variable selpos
	Prompt selpos, "Which SSV port?", popup, "2;4 (red);6;8 (blue);"
	DoPrompt "Flagging based on SSV port number", selpos
	if (V_flag==1)
		abort
	endif
	
	String win = WinName(0,1)
	if (strsearch(win, "Weekly_", 0) == -1)
		abort "Can only use FlagPort on Best_Conc figure"
	endif
	String mol = win[strsearch(win, "_", 0)+1, strsearch(win, "_ALL",0)-1]
	
	Wave /Z ssv = $mol + "_port"
	Wave /Z conc = $mol + "_best_conc_hourlyY"
	Wave /Z concflag = $mol + "_best_conc_flg"
	Wave /Z day = $mol + "_date"
	Wave /Z flag = $mol + "_flag"
	Wave /Z flagman = $mol + "_manflag"
	Wave /Z flagtype = $mol + "_flagtype"

	GetMarquee left, bottom
	selpos *= 2	// to account for the list in the popup
	
	concflag = SelectNumber((day>V_left) && (day <= V_right) && (ssv == selpos), concflag, conc)
	conc = SelectNumber((day > V_left) && (day <= V_right) && (ssv == selpos), conc, NaN)
	flag = SelectNumber((day > V_left) && (day <= V_right) && (ssv == selpos), flag, NaN)
	flagman = SelectNumber((day > V_left) && (day <= V_right) && (ssv == selpos), flagman, NaN)
	flagtype = SelectNumber((day > V_left) && (day <= V_right) && (ssv == selpos), flagtype, FLAG_MANUAL)
	
end


function SetManFlagToPermFlag([mol])
	string mol

	SVAR Gmol = root:G_mol
	if (ParamIsDefault(mol))
		mol = Gmol
	endif
		
	wave flag = $mol + "_manflag"
	wave /d day = $mol + "_date"
	wave /d Pflag = $mol + "_permflag"
	
	Extract /O day, Pflag, numtype(flag)==2

	print "There are now", numpnts(Pflag), "permenant flagged points for " + mol
	
end


function PreserveFlags(mol)
	string mol

	wave flag = $mol + "_flag"
	wave man = $mol + "_manflag"
	wave ftype = $mol + "_flagtype"
	wave/d Pflag = $mol + "_permflag"
	wave/d day = $mol + "_date"
	
	variable inc, pinc

	for (pinc=0; pinc < numpnts(Pflag); pinc+=1)
		inc = BinarySearch(day, Pflag[pinc])
		flag[inc] = nan
		man[inc] = nan
		ftype[inc] = FLAG_MANUAL
	endfor	
	
end

// function flags points that are WAY out of range.
function FlagRediculous(conc, mol, attrib)
	wave conc
	string mol, attrib
	
	wave flag = $(mol + "_flag")
	wave ftype = $mol + "_flagtype"
	wave hstd = $(mol + "_hstd_conc")
	wave day = $(mol + "_date")
	WaveStats /M=1/Q hstd
	variable rediculous = V_max * 4
	variable i
	
	if ( rediculous > -100 ) 
		//print "    Flagging mixing ratios > abs(" + num2str(rediculous) + ")"
		
		Extract /FREE/INDX/O conc, toflagIDX, conc > rediculous || conc < -rediculous
		
		for (i=0; i<numpnts(toflagIDX); i+=1 )
			flag[toflagIDX[i]] = NaN
			ftype[toflagIDX[i]] = FLAG_REDICULOUS
		endfor
	endif	
end

// only unflags air ports (not cals)
function UnFlagInsideBox()  : GraphMarquee
	
	String win = WinName(0,1)
	if (strsearch(win, "Weekly_", 0) == -1)
		abort
	endif
	String mol = win[strsearch(win, "_", 0)+1, strsearch(win, "_ALL",0)-1]

	wave conc = $mol + "_best_conc_hourlyY"
	wave ssv = $mol + "_port"
	wave flag = $mol + "_flag"
	wave man = $mol + "_manflag"
	wave ftype = $mol + "_flagtype"
	wave flg = $mol + "_best_conc_flg"
	string wvStr = NameOfWave(wv)
	variable i
	
	GetMarquee /K left, bottom	
	
	// Check to see if the wave is plotted as and XY pair.
	// check for XY pairing
	
	if ( WaveExists(XWaveRefFromTrace("", wvStr)) )
		wave wvx = XWaveRefFromTrace("", wvStr)
		Extract /FREE/INDX/O flg, JunkY, ( (wvx > V_left) && (wvx < V_right) && (flg < V_top) && (flg > V_bottom) )
	else
		Extract /FREE/INDX/O flg, JunkY, ( (pnt2x(flg, p) > V_left) && (pnt2x(flg,p) < V_right) && (flg < V_top) && (flg > V_bottom) )
	endif
	
	
	for(i = 0; i<numpnts(JunkY); i+=1)
		//if ( (ssv[JunkY[i]] == SSV_AIR1) || (ssv[JunkY[i]] == SSV_AIR2) )
			man[JunkY[i]] = 1
			ftype[JunkY[i]] = NO_FLAG
			conc[JunkY[i]] = flg[JunkY[i]]
			flg[JunkY[i]] = NaN
			flag[JunkY[i]] = 1
		//endif
	endfor
	
end
