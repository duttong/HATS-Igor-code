#pragma rtGlobals=1		// Use modern global access method

Function InitNormVars()

	SetDataFolder root:
	
	if (exists("root:S_currPeak") != 2 )
		String /G root:S_currPeak = ""
	endif
	SVAR /Z mol = root:S_currPeak

	if ( !DataFolderExists("norm") )
		NewDataFolder root:norm
	endif

	if (exists("root:norm:S_normPeak") != 2)
		String /G root:norm:S_normPeak = mol
	endif
	SVAR normPeak = root:norm:S_normPeak
	normPeak = mol
	
	if (exists("root:norm:V_calssv") != 2)
		Variable /G root:norm:V_calssv = 1
	endif
	NVAR calssv = root:norm:V_calssv
	
	if (exists("root:norm:S_calssvLst") != 2)
		String /G root:norm:S_calssvLst = num2str(calssv)
	endif
	if (exists("root:norm:V_displayNorm") != 2)
		Variable /G root:norm:V_displayNorm = 0
	endif
	if (exists("root:norm:V_oldFirstChrom") != 2)
		Variable /G root:norm:V_oldFirstChrom = 0
	endif
	if (exists("root:norm:V_oldLastChrom") != 2)
		Variable /G root:norm:V_oldLastChrom = 0
	endif
	
	// add DB_calval wave to DB if it does not exist
	if (exists("root:DB:DB_calval") == 0)
		wave DBchan = root:DB:DB_chan
		Setdatafolder db
		make /n=(numpnts(DBchan)) DB_calval = 1
		Setdatafolder root:
	endif
	// add DB_manERR wave to DB if it does not exits
	if (exists("root:DB:DB_manERR") == 0)
		wave DBchan = root:DB:DB_chan
		Setdatafolder db
		make /n=(numpnts(DBchan)) DB_manERR = 0
		Setdatafolder root:
	endif
	
	SVAR calssvLst = root:norm:S_calssvLst
	if (strlen(calssvLst) <= 0)
		calssvLst = num2str(calssv)
	endif

end

Function InitNormDB()
	
	string DBmeth = "root:DB:DB_normMeth"
	string DBsm = "root:DB:DB_normSmooth"
	string DBfst = "root:DB:DB_normFirst"
	string DBlst = "root:DB:DB_normLast"
	wave DBmols = root:DB:DB_mols
	
	if (exists(DBmeth) != 1)
		make /n=(numpnts(DBmols)) $DBmeth = 1
	endif
	if (exists(DBsm) != 1)
		make /n=(numpnts(DBmols)) $DBsm = 3
	endif
	if (exists(DBfst) != 1)
		make /n=(numpnts(DBmols)) $DBfst = 0
	endif
	if (exists(DBlst) != 1)
		make /n=(numpnts(DBmols)) $DBlst = 1
	endif
	
	if (numpnts(DBmols) != numpnts($DBsm))
		abort "The normalization database waves are not the same size as the DB waves.  Perhapse a peak was added."
	endif

end

Function CreateNormPanel()

	InitNormVars()
	InitNormDB()

	SVAR mol = root:norm:S_normPeak
	NVAR calssvPos = root:norm:V_calssv
	wave DBmeth = root:DB:DB_normMeth
	wave DBsm = root:DB:DB_normSmooth
	wave DBfst = root:DB:DB_normFirst
	wave DBlst = root:DB:DB_normLast
	wave DBcalval = root:DB:DB_calval
	string com
	variable DBrow = returnMolDBrow(mol)
	
	if (numtype(calssvPos) == 2)
		calssvPos = str2num(StringFromList(0,selposLst( 0 )))
	endif

	DoWindow NormPanel
	if (V_flag == 1)
		DoWindow /F NormPanel
		abort
	endif		
	
	DetrendResp(mol, 1)
	wave respC = $("root:norm:" + mol + "_respCal")
	wave selpos = root:selpos

	Display /K=1/W=(481,64,1170,682) as "Detrend Panel"
	DoWindow /C NormPanel
	ModifyGraph margin(left)=100
	ShowInfo

	DetrendPlot( mol )
	NORMpopMenuProc("calssv",calssvPos+1,num2str(calssvPos))

	ControlBar 110

	UpdateMolButtonsNormPanel()
	// turn one mol button on
	sprintf com, "CheckBox box_%s value=1", mol
	execute com

	K9 += 100
	Button getpoints,pos={K9+152,30},size={74,62},proc=NORMbuttonProc,title="Get Points\rfrom\rCursors"
	Button getpoints,help={"Updates \"first\" and \"last\" points with cursor positions."}
	Button getpoints,font="Arial",fSize=12,fColor=(65535,60076,49151)
	Button recalc,pos={K9+232,30},size={74,62},proc=NORMbuttonProc,title="Recalc &\rredraw"
	Button recalc,help={"Recalculates normalization."}
	Button recalc,font="Arial",fSize=12,fColor=(65535,54611,49151)
	Button export,pos={K9+312,30},size={74,62},proc=NORMbuttonProc,title="Export\rNormalized\rWaves"
	Button export,help={"Saves ALL normalized waves to a specified path."}
	Button export,font="Arial",fSize=12,fColor=(65535,32768,32768)
	SetVariable firstPoint,pos={K9+25,3},size={118,20},proc=NORMsetVarProc,title="Start Chrom"
	SetVariable firstPoint,font="Arial",fSize=14
	SetVariable lastPoint,pos={K9+26,25},size={117,20},proc=NORMsetVarProc,title="Stop Chrom"
	SetVariable lastPoint,font="Arial",fSize=14
	SetVariable smoothfact,pos={K9-21,73},size={163,20},proc=NORMsetVarProc,title="Smoothing Factor"
	SetVariable smoothfact,font="Arial",fSize=14
	ValDisplay resSD,pos={90,103},size={138,19},title="residual s.d."
	ValDisplay resSD,labelBack=(65535,65535,65535),font="Arial",fSize=14
	ValDisplay resSD,format="%3.2f",frame=0
	ValDisplay resSD,limits={0,0,0},barmisc={0,1000},bodyWidth= 60,value= #"K10"
	PopupMenu detrendmeth,pos={K9-7,49},size={150,21},proc=NORMpopMenuProc,title="Method"
	PopupMenu detrendmeth,font="Arial",fSize=14
	PopupMenu detrendmeth,bodyWidth= 100,value= #"\"Binomial Smooth;Linear Interp;Linear Fit;Poly 3;Poly 4;Poly 5;Poly 6;Poly 7;Poly 8;Poly 9;Poly 10;Poly 11;Poly 12;Poly 13;Poly 14\""
	CheckBox displayNorm,pos={K9+392,38},size={83,45},proc=NORMcheckProc,title="Display\rNormalized\rData"
	CheckBox displayNorm,help={"When checked, normalized cal and air data are displayed."}
	CheckBox displayNorm,font="Arial",fSize=12,variable=root:norm:V_displayNorm
	Button cursorInfo,pos={12,541},size={63,37},proc=NORMbuttonProc,title="Cursor\rInfo"
	Button cursorInfo title="Cursor\rInfo",size={63,37},proc=NORMbuttonProc
	Button cursorInfo font="Arial",fSize=12,fColor=(65535,60076,49151)
	Button cursorInfo help={"Displays chromatogram information about cursor points."}

	PopupMenu calssv,pos={K9+182,4},size={134,21},proc=NORMpopMenuProc,title="Detrend selpos"
	PopupMenu calssv,help={"Detend data using this stream select position (selpos wave)."}
	PopupMenu calssv,font="Arial",fSize=14
	PopupMenu calssv,bodyWidth= 70,mode=1,value= #"selposLst( 0 )"
	SetVariable calval,pos={K9+322,4},size={112,20},proc=NORMsetVarProc,title="Cal value"
	SetVariable calval,font="Arial",fSize=14
	
	SetVariable firstPoint,limits={returnMINchromNum(1),returnMAXchromNum(1),1},bodyWidth= 50
	SetVariable lastPoint,limits={returnMINchromNum(1),returnMAXchromNum(1),1},bodyWidth= 50
	SetVariable smoothfact,limits={1,300,1},value= DBsm[DBrow],bodyWidth= 50
	PopupMenu detrendmeth,mode=DBmeth[DBrow]
	PopupMenu calssv, mode=WhichListItem(num2str(calssvPos), selposLst( 1 ))+1
	SetVariable calval,limits={0,3000,0},value=DBcalval[DBrow],bodyWidth= 50

	SetWindow NormPanel, hook(gsdhook)=NormPanelWindowHook

End

// Updated to modern hook method GSD 210709
Function NormPanelWindowHook(s)
	STRUCT WMWinHookStruct &s

	Variable hookResult = 0

	switch(s.eventCode)
		case 0:				// Activate
			// Handle activate
			NORMrefresh()
			break

		case 1:				// Deactivate
			// Handle deactivate
			break

		// And so on . . .
	endswitch

	return hookResult		// 0 if nothing done, else 1
End

Function NORMrefresh()

	SVAR mol = root:norm:S_normPeak
	NVAR displayNorm = root:norm:V_displayNorm
	wave /t DBmols = root:DB:DB_mols
	wave DBsm = root:DB:DB_normSmooth
	string com
	variable minc
	variable DBrow = returnMolDBrow(mol)

	// turn all off 
	for(minc=0; minc<numpnts(DBmols); minc+=1 )
		sprintf com, "CheckBox box_%s value=0", DBmols[minc]
		execute com
	endfor
	sprintf com, "CheckBox box_%s value=1", mol
	execute com	

	DetrendResp( mol, 1 )
	if ( displayNorm == 1 )
		NormalizationPlot( mol )
	else	
		DetrendPlot( mol )
	endif
	RefreshDetrendPanel()
	
End

Function RefreshDetrendPanel()

	SVAR mol = root:norm:S_normPeak
	NVAR oldF = root:norm:V_oldFirstChrom
	NVAR oldL = root:norm:V_oldLastChrom
	wave DBmeth = root:DB:DB_normMeth
	wave DBsm = root:DB:DB_normSmooth
	wave DBfst = root:DB:DB_normFirst
	wave DBlst = root:DB:DB_normLast
	wave DBcalval = root:DB:DB_calval
	string com
	variable DBrow = returnMolDBrow(mol)
	
	variable cal = DBcalval[DBrow]
	
	SelectSelpos()

	wave respC = $("root:norm:" + mol + "_respCal")
	wave residC = $("root:norm:" + mol + "_respCalRes")
	wave selpos = root:selpos

	oldF = DBfst[DBrow]
	oldL = DBlst[DBrow]
	SetVariable firstPoint,limits={returnMINchromNum(1),returnMAXchromNum(1),1},value=DBfst[DBrow],bodyWidth= 50
	SetVariable lastPoint,limits={returnMINchromNum(1),returnMAXchromNum(1),1},value= DBlst[DBrow],bodyWidth= 50
	SetVariable smoothfact,value= DBsm[DBrow]
	
	if (WhichListItem(mol + "_respCal", TraceNameList("", ";", 1)) != -1 )
		// Detrend Plot is displayed
		if (numtype(ChromNum2CalPnt(DBfst[DBrow])) == 2)
			Cursor /K A
		else
			Cursor /A=1 A, $(mol + "_respCal"), ChromNum2CalPnt(DBfst[DBrow])-1
		endif
		if (numtype(ChromNum2CalPnt(DBlst[DBrow])) == 2  )
			Cursor /K B
		else
			Cursor B, $(mol + "_respCal"), ChromNum2CalPnt(DBlst[DBrow])-1
		endif
		
		if (WaveExists(residC) && (numpnts(residC) > 1))
			wavestats /Q residC
			K10 = V_sdev / cal
			ValDisplay resSD, format="%3.2f", value=K10
		endif
		
		Button getpoints disable=0
		SetVariable firstPoint disable=0
		SetVariable lastPoint disable=0
		
	elseif (WhichListItem(mol + "_normCal", TraceNameList("", ";", 1)) != -1 )
		// Normalize plot is displayed
		if (exists("root:norm:" + mol + "_normCal") == 1)
			wave normC = $("root:norm:" + mol + "_normCal")
			wavestats /Z/Q normC
			K10 = V_sdev / cal
			ValDisplay resSD, format="%2.5f", value=K10
		endif
		
		Button getpoints disable=2
		SetVariable firstPoint disable=2
		SetVariable lastPoint disable=2
		
	elseif (WhichListItem("trap1cal", TraceNameList("", ";", 1)) != -1 )
		// PANTHER MSD Detrend waves

		if (WaveExists(root:norm:trap1respCres) && (numpnts(root:norm:trap1respCres) > 1))
			wavestats /Q root:norm:trap1respCres
			K10 = V_sdev / cal
			if (WaveExists(root:norm:trap2respCres) && (numpnts(root:norm:trap2respCres) > 1))
				wavestats /Q root:norm:trap2respCres
				K10 = (K10 + V_sdev / cal)/2		// I didn't weight the sdevs by num (oh well)
			endif
			ValDisplay resSD, format="%3.2f", value=K10
		endif

		Button getpoints disable=2
		SetVariable firstPoint disable=2
		SetVariable lastPoint disable=2
		
	elseif (WhichListItem("trap1normC", TraceNameList("", ";", 1)) != -1 )
		// PANTHER MSD norm waves

		if (WaveExists(root:norm:trap1normC) && (numpnts(root:norm:trap1normC) > 1))
			wavestats /Q root:norm:trap1normC
			K10 = V_sdev / cal
			if (WaveExists(root:norm:trap2normC) && (numpnts(root:norm:trap2normC) > 1))
				wavestats /Q root:norm:trap2normC
				K10 = (K10 + V_sdev / cal)/2		// I didn't weight the sdevs by num (oh well)
			endif
			ValDisplay resSD, format="%2.5f", value=K10
		endif

		Button getpoints disable=2
		SetVariable firstPoint disable=2
		SetVariable lastPoint disable=2
		
	endif
	
	// smooth factor on or off?
	if (DBmeth[DBrow] == 1)
		SetVariable smoothfact disable=0
	else
		SetVariable smoothfact disable=1
	endif
	PopupMenu detrendmeth,mode=DBmeth[DBrow]
	SetVariable calval,value=DBcalval[DBrow]

end

Function UpdateMolButtonsNormPanel()
	variable xstart = 25, ystart = 10, xsize = 100, ysize = 14
	variable yinc = 15, xinc = 80
	variable MAXmolsincolumn = 6
	
	String savedDF= GetDataFolder(1)
	setDataFolder root:DB
	
	wave /t DBmols = DB_mols
	wave DBchan = DB_chan
	NVAR chans = root:V_chans
	
	variable inc, ch, xloc, yloc, chinc
	string boxname
	
	xloc = -70
	for (inc=0; inc<numpnts(DBmols); inc+= 1)
		boxname = "box_" + DBmols[inc]
		ch = DBchan[inc]
		if (mod(inc,MAXmolsincolumn) == 0 ) 
			xloc += xinc
		endif
		yloc = ystart + mod(inc,MAXmolsincolumn) * yinc
		CheckBox $boxname,pos={xloc,yloc},size={xsize,ysize},proc=NORMcheckProc,title=DBmols[inc]
		CheckBox $boxname,help={"When checked, the calibration response will be normilized."}
		CheckBox $boxname,font="Arial",fSize=12,value= 0,mode=1
	endfor

	setDataFolder savedDF
	
	K9 = xloc
	
end

function DetrendAllPeaks( applycal )
	variable applycal

	SVAR currPeak = root:S_currPeak
	string orgPeak = currPeak

	wave /t DBmols = root:DB:DB_mols
	variable i
	string mol

	for(i=0; i<numpnts(DBmols); i+= 1)
		mol = DBmols[i]
		currPeak = mol
		DetrendResp(mol, applycal)
	endfor

	currPeak = orgPeak
	SelectSelpos()
end


// copies resp, selpos, and tsecs to the root:norm data folder
// detrends the calibration data selected by calssv
function DetrendResp(mol, applycal)
	string mol
	variable applycal

	NVAR calssv = root:norm:V_calssv
	SVAR calssvLst = root:norm:S_calssvLst
	SVAR nPeak = root:norm:S_normPeak
	SVAR currPeak = root:S_currPeak
	SVAR /Z PANtype = root:S_PANTHERtype
	
	wave DBmeth = root:DB:DB_normMeth
	wave DBsm = root:DB:DB_normSmooth
	wave DBfst = root:DB:DB_normFirst
	wave DBlst = root:DB:DB_normLast
	wave DBcalval = root:DB:DB_calval
	if (! WaveExists($"root:DB:DB_manERR") )
		make /n=(numpnts(DBmeth)) root:DB:DB_manERR = 0
	endif
	wave DBmanERR = root:DB:DB_manERR
	variable DBrow = returnMolDBrow(mol)
	variable smfact = DBsm[DBrow]
	variable firstTime, i
	
	nPeak = mol		// update S_normPeak with mol (used by ChromNum2CalPnt)
	currPeak = mol

	SetDataFolder root:

	if ( ! WaveExists($("root:" + mol + "_resp")) )
		MakePeakResWaves( mol, 0 )
	endif

	SelectSelpos()

	wave resp = $("root:" + mol + "_resp")
	wave selposOrg = root:selpos
	wave tsecs = root:tsecs_1904
	wave flagBad = $("root:" + mol + "_flagBad")

	string respC, respA, selposStr, tsecsC, tsecsA, smRespC, smTsecsC, resC
	string normC, normA, normTsecsC, normTsecsA, tsecsOldC, TsecsExportStr, normPeak
	string npath = "root:norm:"

	selposStr 		= npath + "selposAll"
	respC 			= npath+mol + "_respCal"
	tsecsC 			= npath+mol + "_tsecsCal"
	respA 			= npath+mol + "_respAir"
	tsecsA 			= npath+mol + "_tsecsAir"
	TsecsExportStr 	= npath+mol + "_TsecsExportStr"
	smRespC 		= npath+mol + "_respCalSm"
	smTsecsC 		= npath+mol + "_tsecsCalSm"
	resC 			= npath+mol + "_respCalRes"
	normPeak 		= npath+mol + "_norm"
	normC 			= npath+mol + "_normCal"
	normA 			= npath+mol + "_normAir"
	normTsecsC 	= npath+mol + "_normTsecsCal"
	normTsecsA 	= npath+mol + "_normTsecsAir"

	make /n=(numpnts(resp))/o $respC = NaN, $respA = NaN
	duplicate /o selposOrg, $selposStr
	duplicate /o tsecs, $tsecsC, $tsecsA, $TsecsExportStr

	wave respCwv = $respC
	wave tsecsCwv = $tsecsC
	wave respAwv = $respA
	wave tsecsAwv = $tsecsA
	wave selpos = $selposStr
	wave TsecsExport = $TsecsExportStr
	wave /Z W_coef = root:norm:W_coef
	
	SetDataFolder root:norm
	make /o/n=0 W_coef

	// stip out Cals and Airs also remove flagged "bad" data
	variable SelposInc = ItemsInList(calssvLst, ",")
	for (i=0; i<SelposInc; i+=1 )
		calssv = str2num(StringFromList(i, calssvLst, ","))
		respCwv = SelectNumber(selpos == calssv, respCwv, resp)
		respAwv = SelectNumber(selpos != calssv, respAwv, resp)
	endfor
	respCwv = SelectNumber(flagBad == 1, respCwv, NaN)
	respAwv = SelectNumber(flagBad == 1, respAwv, NaN)
	
	// If PANTHER MSD then filter trap one (1 & 3 ) or trap two (11 & 13)
	if ( SVAR_Exists(PANtype) )
		DetrendResp_PANTHER_MSD(mol, applycal)
	endif

	RemoveNaNsXY(respCwv, tsecsCwv)
	RemoveNaNsXY(respAwv, tsecsAwv)
	
	// fix the first guesses of DB_normFirst & DB_normLast (when the DB wave is created it is set to 1)
	if (DBfst[DBrow] <= 0 )
		DBfst[DBrow] = NextCal(0,1)
	endif
	if ( DBlst[DBrow] <= 1 )
		DBlst[DBrow] = NextCal(MAXCHROMS,-1)
	endif
	// make sure the DBfst and DBlst are on cals
	DBfst[DBrow] = NextCal(DBfst[DBrow],0)
	DBlst[DBrow] = NextCal(DBlst[DBrow],0)
	
	// make waves
	Duplicate/O tsecsCwv, $smTsecsC, $normTsecsC
	Duplicate/O tsecsAwv, $normTsecsA
	Duplicate/O respCwv,$smRespC, $normC
	Duplicate/O respAwv, $normA
	wave smRespCwv = $smRespC
	wave smTsecsCwv = $smTsecsC
	wave normCwv = $normC
	wave normAwv = $normA
	wave normTsecsCwv = $normTsecsC
	wave normTsecsAwv = $normTsecsA
	normCwv = NaN
	normAwv = NaN
		
	// remove points from start and end that are not used.
	Deletepoints ChromNum2CalPnt(DBlst[DBrow]), numpnts(smRespCwv), smRespCwv, smTsecsCwv
	Deletepoints 0, ChromNum2CalPnt(DBfst[DBrow])-1, smRespCwv, smTsecsCwv

	// residual wave
	Make /n=(numpnts(smRespCwv))/O $resC=NaN
	wave resCwv = $resC
	
	if ( DBmeth[DBrow] == 1)			// binomial smooth
		Smooth /E=3 smfact, smRespCwv
		normCwv = respCwv / ( smRespCwv[BinarySearchInterp(smTsecsCwv, tsecsCwv)] )
		normAwv = respAwv / ( smRespCwv[BinarySearchInterp(smTsecsCwv, tsecsAwv)] )
		
	elseif ( DBmeth[DBrow] == 2)		// linear interpolatioon
		normCwv = 1
		normAwv = respAwv / ( smRespCwv[BinarySearchInterp(smTsecsCwv, tsecsAwv)] )
		
	elseif ( DBmeth[DBrow] == 3)		// linear fit
		CurveFit /Q line smRespCwv /X=smTsecsCwv
		smRespCwv = W_coef[0] + W_coef[1]*smTsecsCwv
		normCwv = respCwv / (W_coef[0] + W_coef[1]*tsecsCwv)
		normAwv = respAwv / (W_coef[0] + W_coef[1]*tsecsAwv)
		
	elseif ( DBmeth[DBrow] >=4 )		// polynomial fits
		firstTime = smTsecsCwv[0]
		smTsecsCwv -= firstTime
		if (numpnts(smRespCwv) != 0 )
			CurveFit /Q poly DBmeth[DBrow]-1, smRespCwv /X=smTsecsCwv
			smRespCwv = poly(W_coef, smTsecsCwv)
			smTsecsCwv += firstTime
			normCwv = respCwv / (poly(W_coef, TsecsCwv-firstTime))
			normAwv = respAwv / (poly(W_coef, TsecsAwv-firstTime))
		endif
	endif
	
	// mult by calval if NOT export (for graph)
	if (applycal)
		normCwv *= DBcalval[DBrow]
		normAwv *= DBcalval[DBrow]
	endif
	
	// residual wave
	resCwv = respCwv[ChromNum2CalPnt(DBfst[DBrow])-1+p] - smRespCwv
	
	// NaN norm cal & air data before and after selected start and stop points and...
	// make a single _norm wave with both cal and air data
	// this is the wave that is exported
	variable /D inc, timeF, timeL, index
	timeF = tsecsCwv[ChromNum2CalPnt(DBfst[DBrow])-1]
	timeL = tsecsCwv[ChromNum2CalPnt(DBlst[DBrow])-1]
	make /o/n=(numpnts(resp)) $normPeak=nan
	wave nor = $normPeak
	for (inc=0; inc<numpnts(tsecsAwv); inc += 1)
		if (( tsecsAwv[inc] < timeF ) || ( tsecsAwv[inc] > timeL ))
			normAwv[inc] = nan
		endif
		index = BinarySearch(TsecsExport, tsecsAwv[inc])
		nor[index] = normAwv[inc]
	endfor
	for (inc=0; inc<numpnts(tsecsCwv); inc += 1)
		if (( tsecsCwv[inc] < timeF ) || ( tsecsCwv[inc] > timeL ))
			normCwv[inc] = nan
		endif
		index = BinarySearch(TsecsExport, tsecsCwv[inc])
		nor[index] = normCwv[inc]
	endfor

	// If PANTHER MSD and 3,13 selpos is selected, merge both traps
	if ( SVAR_Exists(PANtype) && (ItemsInList(calssvLst, ",") > 1))
		if ( cmpstr(PANtype, "MSD") == 0 )
			wave t1norm = root:norm:trap1norm
			wave t2norm = root:norm:trap2norm
			wave t1c = root:norm:trap1normC
			wave t2c = root:norm:trap2normC
			nor = NaN
			nor = SelectNumber(numtype(t1norm)==0, nor, t1norm)
			nor = SelectNumber(numtype(t2norm)==0, nor, t2norm)
			duplicate /o t1c, ttt1c
			duplicate /o t2c, ttt2c
			normCwv = NaN
			ConcatenateWaves("ttt1c", "ttt2c")
			duplicate /o ttt1c, normCwv
			killwaves ttt1c, ttt2c
		endif
	endif
	
	// add comments to Norm wave note if the DB_manERR wave is <= 0 otherwise use the number in DB_manERR
	if ( DBmanERR[DBrow] <= 0 )
		wavestats /Z/Q normCwv
		Note nor, "Precision of cal: " + num2str(V_sdev*100) + "%"
	else
		Note nor, "Precision of cal: " + num2str(DBmanERR[DBrow]) + "%"
	endif
	
	Killwaves /Z TsecsExport
	SetDataFolder root:
	
end

// extra detrend code for the PANTHER msd two trap system.  This should be called from DetrendResp function.
function DetrendResp_PANTHER_MSD(mol, applycal)
	string mol
	variable applycal

	SVAR /Z PANtype = root:S_PANTHERtype

	if ( cmpstr(PANtype, "MSD") != 0 )
		return 0
	endif

	wave DBmeth = root:DB:DB_normMeth
	wave DBsm = root:DB:DB_normSmooth
	wave DBfst = root:DB:DB_normFirst
	wave DBlst = root:DB:DB_normLast
	wave DBcalval = root:DB:DB_calval
	wave DBmanERR = root:DB:DB_manERR
	variable DBrow = returnMolDBrow(mol)
	variable smfact = DBsm[DBrow]
	
	NVAR calssv = root:norm:V_calssv
	SVAR calssvLst = root:norm:S_calssvLst
	SVAR nPeak = root:norm:S_normPeak
	
	string respC, respA, selposStr, tsecsC, tsecsA, smRespC, smTsecsC, resC
	string normC, normA, normTsecsC, normTsecsA, tsecsOldC, TsecsExportStr, normPeak
	string npath = "root:norm:"

	wave selpos 	= root:selpos
	wave respCwv 	= $(npath+mol + "_respCal")
	wave tsecsCwv 	= $(npath+mol + "_tsecsCal")
	wave respAwv 	= $(npath+mol + "_respAir")
	wave tsecsAwv 	= $(npath+mol + "_tsecsAir")
	smRespC 		= npath+mol + "_respCalSm"
	smTsecsC 		= npath+mol + "_tsecsCalSm"
	resC 			= npath+mol + "_respCalRes"
	normPeak 		= npath+mol + "_norm"
	normC 			= npath+mol + "_normCal"
	normA 			= npath+mol + "_normAir"
	normTsecsC 	= npath+mol + "_normTsecsCal"
	normTsecsA 	= npath+mol + "_normTsecsAir"

	if (ItemsInList(calssvLst, ",") == 1)
		if ( str2num(calssvLst) < 10 )		// trap 1
			respCwv = SelectNumber(selpos >= 10, respCwv, NaN)
			respAwv = SelectNumber(selpos >= 10, respAwv, NaN)
		else									// trap 2
			respCwv = SelectNumber(selpos < 10, respCwv, NaN)
			respAwv = SelectNumber(selpos < 10, respAwv, NaN)
		endif
		
	elseif (cmpstr(calssvLst, "3,13") == 0)
		// norm both trap channels separately and then combine
		// this done with two recursive calls to this function (DetrenResp)
		string calssvLst_save = calssvLst
		variable DBfst_save = DBfst[DBrow]
		variable DBlst_save = DBlst[DBrow]

		// span all chroms for this detrend method
		variable ch = ReturnChannel(mol)
		
		// trap 1 == 3
		calssvLst = "3"
		DBfst[DBrow] = NextCal(1,1)
		DBlst[DBrow] = NextCal(MAXCHROMS,-1)
		DetrendResp(mol, applycal)
		// save waves
		duplicate /o respCwv, root:norm:trap1cal
		duplicate /o respAwv, root:norm:trap1air
		duplicate /o tsecsCwv, root:norm:trap1calTsecs
		duplicate /o tsecsAwv, root:norm:trap1airTsecs
		duplicate /o $smRespC, root:norm:trap1smRespC
		duplicate /o $smTsecsC, root:norm:trap1smTsecsC
		duplicate /o $resC, root:norm:trap1respCres
		duplicate /o $normC, root:norm:trap1normC
		duplicate /o $normA, root:norm:trap1normA
		duplicate /o $normTsecsC, root:norm:trap1normTsecsC
		duplicate /o $normTsecsA, root:norm:trap1normTsecsA
		duplicate /o $normPeak, root:norm:trap1norm
		
		// trap 2 = 13
		calssvLst = "13"
		DBfst[DBrow] = NextCal(1,1)
		DBlst[DBrow] = NextCal(MAXCHROMS,-1)
		DetrendResp(mol, applycal)
		duplicate /o respCwv, root:norm:trap2cal
		duplicate /o respAwv, root:norm:trap2air
		duplicate /o tsecsCwv, root:norm:trap2calTsecs
		duplicate /o tsecsAwv, root:norm:trap2airTsecs
		duplicate /o $smRespC, root:norm:trap2smRespC
		duplicate /o $smTsecsC, root:norm:trap2smTsecsC
		duplicate /o $resC, root:norm:trap2respCres
		duplicate /o $normC, root:norm:trap2normC
		duplicate /o $normA, root:norm:trap2normA
		duplicate /o $normTsecsC, root:norm:trap2normTsecsC
		duplicate /o $normTsecsA, root:norm:trap2normTsecsA
		duplicate /o $normPeak, root:norm:trap2norm
		
		// restore to original values
		calssvLst = calssvLst_save
		DBfst[DBrow] = DBfst_save
		DBlst[DBrow] = DBlst_save
		
	endif
end

Function NORMcheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	SVAR mol = root:norm:S_normPeak
	NVAR displayNorm = root:norm:V_displayNorm
	wave /t DBmols = root:DB:DB_mols
	wave DBsm = root:DB:DB_normSmooth
	string com
	variable minc
	variable DBrow = returnMolDBrow(mol)

	if ( cmpstr(ctrlName, "displayNorm") == 0 )
		displayNorm = checked
	else	
		// turn all off 
		for(minc=0; minc<numpnts(DBmols); minc+=1 )
			sprintf com, "CheckBox box_%s value=0", DBmols[minc]
			execute com
		endfor
		sprintf com, "CheckBox %s value=1", ctrlName
		execute com	
	
		mol = StringFromList(1, ctrlName, "_")
		SetDBvars(mol)
	
	endif

	DetrendResp( mol, 1 )
	if ( displayNorm == 1 )
		NormalizationPlot( mol )
	else	
		DetrendPlot( mol )
	endif

End

Function DetrendPlot( mol )
	string mol
	
	SVAR calssvLst = root:norm:S_calssvLst
	SVAR /Z PANtype = root:S_PANTHERtype
	
	if ( SVAR_Exists(PANtype) )
		if ( cmpstr(calssvLst, "3,13") == 0 )
			DetrendPlot_PANTHER_MS(mol)
			return 1
		endif
	endif
	
	string npath = "root:norm:", com
	SetDataFolder $npath

	string resp =  (mol + "_respCal")
	string tsecs = (mol + "_tsecsCal")
	string smo = (mol + "_respCalSm")
	string tsecsSm = (mol + "_tsecsCalSm")
	string res = (mol + "_respCalRes")
	wave AS = $("root:AS:CH" + num2str(ReturnChannel(mol)) + "_All")

	variable i
	string traces = TraceNameList("NormPanel", ";", 1)
	// Leave resp, smo and res if on figure
	traces = RemoveFromList(resp, traces)
	traces = RemoveFromList(smo, traces)
	traces = RemoveFromList(res, traces)
	// remove any remaining traces
	for(i=0; i<ItemsInList(traces); i+=1)
		RemoveFromGraph $StringFromList(i, traces)
	endfor

	if (exists(resp) != 1)
		abort
	endif
	
	// remove msd detrend legend if present
	Legend/K/N=msdLegend

	traces = TraceNameList("NormPanel", ";", 1)
	if (WhichListItem(resp, traces) == -1)
	
		AppendToGraph $resp vs $tsecs 
		AppendToGraph $smo vs $tsecsSm
		AppendToGraph/L=Res_Left $res vs $tsecsSm
		
		ModifyGraph gfSize=14,wbRGB=(65535,65534,49151),cbRGB=(65535,65533,32768)
		ModifyGraph mode($resp)=3,mode($res)=3
		ModifyGraph marker($resp)=16,marker($res)=19
		ModifyGraph lSize($smo)=2
		ModifyGraph rgb($smo)=(0,0,0),rgb($res)=(3,52428,1)
		ModifyGraph msize($resp)=3,msize($res)=3
	
		ModifyGraph grid(Res_Left)=1
		ModifyGraph grid(left)=2
		ModifyGraph zero(Res_Left)=1
		ModifyGraph mirror=2
		ModifyGraph lblPos(left)=81,lblPos(Res_Left)=79
		ModifyGraph lblLatPos(left)=2,lblLatPos(Res_Left)=-4
		ModifyGraph freePos(Res_Left)=0
		ModifyGraph axisEnab(left)={0,0.75}
		ModifyGraph axisEnab(Res_Left)={0.8,1}
		ModifyGraph dateInfo(bottom)={0,0,0}
		Label left "\\Z16Response "
		Label bottom "Date & Time"
		Label Res_Left "\\Z16Residual"
		SetAxis/A/N=1 left
		SetAxis/A/N=1 bottom
		SetAxis/A/E=2 Res_Left
	
		SetDataFolder root:
	endif
	
	// Save axis scaling
	GetAxis /Q left

	RefreshDetrendPanel( )

end

function DetrendPlot_PANTHER_MS( mol )
	string mol
	
	string com
	sprintf com, "RemoveFromGraph %s", TraceNameList("", " ", 1)
	execute com

	if (Exists("root:norm:trap1cal") != 1)
		abort "not found"
	endif
	
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:norm:
	Legend/K/N=msdLegend
	AppendToGraph trap1cal vs trap1calTsecs
	AppendToGraph trap2cal vs trap2calTsecs
	AppendToGraph trap1smRespC vs trap1smTsecsC
	AppendToGraph trap2smRespC vs trap2smTsecsC
	AppendToGraph/L=Res_Left trap1respCres vs trap1calTsecs
	AppendToGraph/L=Res_Left trap2respCres vs trap2calTsecs
	SetDataFolder fldrSav0
	ModifyGraph mode(trap1cal)=3,mode(trap2cal)=3,mode(trap1respCres)=3,mode(trap2respCres)=3
	ModifyGraph marker(trap1cal)=16,marker(trap2cal)=16,marker(trap1respCres)=16,marker(trap2respCres)=16
	ModifyGraph lSize(trap1smRespC)=2,lSize(trap2smRespC)=2
	ModifyGraph rgb(trap2cal)=(1,4,52428),rgb(trap1smRespC)=(0,0,0),rgb(trap2smRespC)=(0,0,0)
	ModifyGraph rgb(trap2respCres)=(1,4,52428)
	ModifyGraph msize(trap1cal)=3,msize(trap2cal)=3,msize(trap1respCres)=3,msize(trap2respCres)=3
	ModifyGraph grid(left)=1,grid(Res_Left)=1
	ModifyGraph mirror=2
	ModifyGraph lblPos(left)=70
	ModifyGraph lblPos(left)=81,lblPos(Res_Left)=79
	ModifyGraph lblLatPos(left)=2,lblLatPos(Res_Left)=-4
	ModifyGraph freePos(Res_Left)=0
	ModifyGraph axisEnab(left)={0,0.75}
	ModifyGraph axisEnab(Res_Left)={0.8,1}
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left "\\Z16Response "
	Label bottom "Date & Time"
	Label Res_Left "\\Z16Residual"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	SetAxis/A/E=2 Res_Left
	Legend/N=msdLegend/J/X=-3.39/Y=-2.11 "\\Z10\\s(trap1cal) trap1\\s(trap2cal) trap2 "

	SetDataFolder fldrSav0
	
	// Save axis scaling
	GetAxis /Q left

	RefreshDetrendPanel( )

end


Function NormalizationPlot( mol )
	string mol
	
	SVAR calssvLst = root:norm:S_calssvLst
	SVAR /Z PANtype = root:S_PANTHERtype

	if ( SVAR_Exists(PANtype) )
		if ( cmpstr(calssvLst, "3,13") == 0 )
			NormalizationPlot_PANTHER_MS(mol)
			return 1
		endif
	endif

	string npath = "root:norm:"
	SetDataFolder $npath

	string normC =  (mol + "_normCal")
	string tsecsC = (mol + "_normTsecsCal")
	string normA =  (mol + "_normAir")
	string tsecsA = (mol + "_normTsecsAir")

	variable i
	string traces = TraceNameList("NormPanel", ";", 1)
	// Leave normC and normA on figure if present
	traces = RemoveFromList(normC, traces)
	traces = RemoveFromList(normA, traces)
	// remove remaining traces from figure
	for(i=0; i<ItemsInList(traces); i+=1)
		RemoveFromGraph $StringFromList(i, traces)
	endfor

	if (exists(normC) != 1)
		abort
	endif

	Legend/K/N=msdLegend
	traces = TraceNameList("NormPanel", ";", 1)
	if (WhichListItem(normC, traces) == -1)
		AppendToGraph $normC vs $tsecsC 
		AppendToGraph $normA vs $tsecsA
	
		SetDataFolder root:	
	
		ModifyGraph marker($normC)=19,marker($normA)=8, msize=2, mode=4
		ModifyGraph rgb($normA)=(16385,16388,65535)
		ModifyGraph grid(left)=1
		ModifyGraph mirror=2
		ModifyGraph dateInfo(bottom)={0,0,0}
		Label left "Normalized Response"
		Label bottom "Date & Time"
		SetAxis/A/N=1 left
		SetAxis/A/N=1 bottom
	endif
	
	RefreshDetrendPanel( )

end

Function NormalizationPlot_PANTHER_MS( mol )
	string mol
	
	string com
	sprintf com, "RemoveFromGraph %s", TraceNameList("", " ", 1)
	execute com
	
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:norm:

	if (exists("trap1normC") != 1)
		abort
	endif
	
	Legend/K/N=msdLegend
	AppendToGraph trap1normC vs trap1normTsecsC
	AppendToGraph trap2normC vs trap2normTsecsC
	AppendToGraph trap1normA vs trap1normTsecsA
	AppendToGraph trap2normA vs trap2normTsecsA
	SetDataFolder fldrSav0
	ModifyGraph msize=2, mode=4
	ModifyGraph marker(trap1normC)=16,marker(trap2normC)=16,marker(trap1normA)=8,marker(trap2normA)=8
	ModifyGraph rgb(trap2normC)=(1,4,52428),rgb(trap2normA)=(1,4,52428)
	ModifyGraph msize(trap1normC)=3,msize(trap2normC)=3
	ModifyGraph dateInfo(bottom)={0,0,0}
	ModifyGraph grid(left)=1
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	Legend/N=msdLegend/J/X=-3.39/Y=-2.11 "\\Z10\\s(trap1normC) trap1\\s(trap2normC) trap2 "

	RefreshDetrendPanel( )

end


Function NORMsetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	SVAR mol = root:norm:S_normPeak
	NVAR displayNorm = root:norm:V_displayNorm
	NVAR oldF = root:norm:V_oldFirstChrom
	NVAR oldL = root:norm:V_oldLastChrom
	wave DBsm = root:DB:DB_normSmooth
	wave DBfst = root:DB:DB_normFirst
	wave DBlst = root:DB:DB_normLast
	variable DBrow = returnMolDBrow(mol)

	strswitch ( ctrlName )

		case "firstPoint":
			DBfst[DBrow] = NextCal( oldF, varNum-oldF )
			Cursor A, $(mol + "_respCal"), ChromNum2CalPnt(DBfst[DBrow])
			break

		case "lastPoint":
			DBlst[DBrow] =  NextCal( oldL, varNum-oldL )
			Cursor B, $(mol + "_respCal"), ChromNum2CalPnt(DBlst[DBrow])
			break
			
		case "smoothfact":
			DBsm[DBrow] = varNum
			break
			
	endswitch

	DetrendResp( mol, 1 )
	if ( displayNorm == 1 )
		NormalizationPlot( mol )
	else	
		DetrendPlot( mol )
	endif

End

Function NORMbuttonProc(ctrlName) : ButtonControl
	String ctrlName
	
	SVAR mol = root:norm:S_normPeak
	NVAR displayNorm = root:norm:V_displayNorm
	NVAR oldF = root:norm:V_oldFirstChrom
	NVAR oldL = root:norm:V_oldLastChrom
	wave DBsm = root:DB:DB_normSmooth
	wave DBfst = root:DB:DB_normFirst
	wave DBlst = root:DB:DB_normLast
	variable DBrow = returnMolDBrow(mol)
	
	strswitch ( ctrlName )

		case "getpoints":
			DBfst[DBrow] =Min(CalPnt2ChromNum(Pcsr(A)+1), CalPnt2ChromNum(Pcsr(B)+1))
			DBlst[DBrow] =Max(CalPnt2ChromNum(Pcsr(A)+1), CalPnt2ChromNum(Pcsr(B)+1))
			oldF = DBfst[DBrow]
			oldL = DBlst[DBrow]
			DetrendResp( mol, 1 )
			if ( displayNorm == 1 )
				NormalizationPlot( mol )
			else	
				DetrendPlot( mol )
			endif
			break

		case "recalc":
			DetrendResp( mol, 1 )
			if ( displayNorm == 1 )
				NormalizationPlot( mol )
			else	
				DetrendPlot( mol )
			endif
			break
			
		case "export":
			ExportNormData()
			if ( displayNorm == 1 )
				NormalizationPlot( mol )
			else	
				DetrendPlot( mol )
			endif
			break
			
		case "cursorInfo":
			NormCsrTag("A")
			NormCsrTag("B")
			break

	endswitch

End

Function NORMpopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	SVAR mol = root:norm:S_normPeak
	SVAR calssvLst = root:norm:S_calssvLst
	NVAR calssv = root:norm:V_calssv
	NVAR displayNorm = root:norm:V_displayNorm
	wave DBmeth = root:DB:DB_normMeth
	variable DBrow = returnMolDBrow(mol)

	strswitch ( ctrlName )
		case "detrendmeth":
			DBmeth[DBrow] = popNum
			break
			
		case "calssv":
			if ( ItemsInList(popStr, ",") == 1 )
				calssv = str2num(popStr)
			else
				calssv = -1
			endif
			calssvLst = popStr
			break
	endswitch
	
	DetrendResp( mol, 1 )
	if ( displayNorm == 1 )
		NormalizationPlot( mol )
	else	
		DetrendPlot( mol )
	endif

End

// function is used to return cursor point info from Detrend or Norm plots
// csr is either "A" or "B"
function NormCsrTag( csr )
	string csr
	
	SVAR mol = root:norm:S_normPeak
	wave AS = $("root:AS:CH" + num2str(ReturnChannel(mol)) + "_All")
	wave tsecs = root:tsecs_1904
	string respCstr =  (mol + "_respCal")
	string csrw, tsecsXstr, chromNum
	
	SetDataFolder root:norm
	if (cmpstr(csr,"A") == 0)
		csrw = CsrWave(A)
		tsecsXstr = CsrXWave(A)
	else
		csrw = CsrWave(B)
		tsecsXstr = CsrXWave(B)
	endif

	// not a good trace name?
	if ( (strsearch(csrw, "resp", 0, 2) == -1) && (strsearch(csrw, "norm", 0, 2) == -1) )
		return 0
	endif
	if ( strsearch(tsecsXstr, "tsecs", 0, 2) == -1 )
		return 0
	endif

	wave tsecsX = $tsecsXstr

//print /d csr, csrw, tsecsXstr, pcsr(A), tsecsX(pcsr(A)), BinarySearch(tsecs, tsecsX(pcsr(A)))
	
	if (cmpstr(csr,"A") == 0)
		chromNum = num2str(AS[BinarySearch(tsecs, tsecsX(pcsr(A)))])
		Tag/C/N=csrApoint/X=5.00/Y=-15.00 $csrw, pcsr(A),"chrom #: " + chromNum
	else
		chromNum = num2str(AS[BinarySearch(tsecs, tsecsX(pcsr(B)))])
		Tag/C/N=csrBpoint/X=-5.00/Y=-15.00 $csrw, pcsr(B),"chrom #: " + chromNum
	endif
	
	SetDataFolder root:
	
end


function ExportNormData()

	SVAR nPeak = root:norm:S_normPeak		// peak being displayed
	SVAR flightDate = root:S_date
	SVAR currPeak = root:S_currPeak
	currPeak = nPeak

	wave /t DBmols = root:DB:DB_mols
	wave DBrespMeth = root:DB:DB_respMeth
	
	variable i, DBrow
	string mol, shortdate = flightDate[2,strlen(flightDate)-1]
	string selposStr = "selpos_" + shortdate
	string tsecsStr= "tsecs_" + shortdate
	string normpath = "root:norm:"
	
	string orgPeak = nPeak

	// create/check export path
	PathInfo NormFiles
	if ( V_flag == 0 )
		NewPath /Q/M="Where would you like the normalized data to be saved?" NormFiles
		PathInfo NormFiles
	endif
	if ( V_flag == 0 )
		abort
	endif
	
	// check the Selpos Table
	string SelposVal_str = "root:DB:SelposVal"
	string SelposExp_str = "root:DB:SelposExport"
	if (exists(selposVal_str) == 0 )
		SelposTable()
		DoUpdate
		abort "The selpos table was not created yet.  Edit this table and then redo the normalized data export."
	endif
	wave SelposVal = $SelposVal_str
	wave SelposExp = $SelposExp_str
	wave Selpos = root:selpos
	variable ssvinc
 
	DetrendAllPeaks( 0 )
	
	// export GC selpos
	if (WaveExists($"root:selposPAN"))
		wave selposGC = root:selposGC
		selpos = selposGC
	endif

	duplicate /O root:selpos $selposStr
	duplicate /O root:tsecs $tsecsStr
	Save/C/O/P=NormFiles $selposStr as selposStr + ".ibw"
	Save/C/O/P=NormFiles $tsecsStr as tsecsStr + ".ibw"

	// export PAN selpos
	if (WaveExists($"root:selposPAN"))
		wave selposPAN = root:selposPAN
		wave selposGC = root:selposGC
		selpos = selposPAN
		selposStr = "selposPAN_" + shortdate
		duplicate /O root:selpos $selposStr
		Save/C/O/P=NormFiles $selposStr as selposStr + ".ibw"
		selpos = selposGC
	endif

	killwaves $selposStr, $tsecsStr
	
	for(i=0; i<numpnts(DBmols); i+= 1)
	 	mol = DBmols[i]
	 	currPeak = mol
	 	
		wave normWv = $("root:norm:" + mol + "_norm")
		DBrow = returnMolDBrow(mol)
		if (DBrespMeth[DBrow] == 0 )
			mol = mol + "_hght_" + shortdate
		else
			mol = mol + "_area_" + shortdate
		endif
	
		duplicate /O normWv $(normpath + mol)
		wave SaveMol = $(normpath + mol)
		
		// nan out selpos values not used for export (where SelposExp[ssvinc] = 0)
		for( ssvinc=0; ssvinc<numpnts(SelposVal); ssvinc +=1)
			if ( SelposExp[ssvinc] == 0 )
				if ( cmpstr(currPeak, "PAN") == 0 )
					SaveMol = SelectNumber(selposPAN == SelposVal[ssvinc], SaveMol, NaN)
				else
					SaveMol = SelectNumber(selpos == SelposVal[ssvinc], SaveMol, NaN)
				endif
			endif
		endfor
		
		Save/C/O/P=NormFiles SaveMol as mol + ".ibw"

	endfor
	
	// reset to original peak
	nPeak = orgPeak
	currPeak = orgPeak
	DetrendResp(nPeak, 1)

end

// returns either NaN if chrnum is not a cal, or the cal number counting from 1 (and excluding cals marked with the bad flag).
function ChromNum2CalPnt( chrnum )
	variable chrnum
	
	SVAR calssvLst = root:norm:S_calssvLst
	SVAR mol = root:norm:S_normPeak
	
	wave selpos = root:selpos
	wave bad = $("root:" + mol + "_flagBad")
	wave resp = $("root:" + mol + "_resp")

	variable i, ch, ResRow, calcount
	ch = ReturnChannel(mol)
	ResRow = ReturnResRowNumber( ch, chrnum )
	
	// check to see if chrnum is a valid cal in the calssvLst
	if (WhichListItem(num2str(selpos[ResRow]), calssvLst, ",") == - 1)
		return NaN
	endif
	if (bad[ResRow] != 0 )
		return NaN
	endif
	
	// if resp is blank
	Wavestats /Q resp
	if ( V_npnts == 0 )
		return 0
	endif
	
	// count cal injections upto chrnum
	for (i=0; i<=ResRow; i+= 1)
		if (WhichListItem(num2str(selpos[i]), calssvLst, ",") != - 1)
			if (( bad[i] == 0 ) && ( numtype(resp[i]) == 0 ))
				calcount += 1
			endif
		endif
	endfor
	
	return calcount
	
end

function CalPnt2ChromNum( point )
	variable point
	
	SVAR calssvLst = root:norm:S_calssvLst
	SVAR mol = root:norm:S_normPeak
	
	wave AS = $("root:AS:CH" + num2str(ReturnChannel(mol)) + "_All")
	wave selpos = root:selpos
	wave bad = $("root:" + mol + "_flagBad")
	wave resp = $("root:" + mol + "_resp")
	
	variable i, calcount

	// count cal injections upto chrnum
	for (i=0; i<numpnts(selpos); i+= 1)
		if (WhichListItem(num2str(selpos[i]), calssvLst, ",") != - 1)
			// don't count cals that are flagged bad
			if (( bad[i] == 0 ) && ( numtype(resp[i]) == 0 ))
				calcount += 1
			endif
		endif
		if ( calcount == point )
			return AS[i]
		endif
	endfor
	
	return NaN
	
end

// NextCal will return the next good cal chrom number.  It determines the cal ssv positions from the S_calssvLst
// up =1 for next cal > chrnum
// up = -1 for next cal < chrnum
// up = 0 for next closest cal to chrnum
function NextCal( chrnum, up )
	variable chrnum, up
	
	SVAR calssvLst = root:norm:S_calssvLst
	SVAR mol = root:norm:S_normPeak
	
	// no calssv list
	if (strlen(calssvLst) <= 0)
		return 0
	endif
	
	variable i, ch, ResRow, calcount
	wave AS = $("root:AS:CH" + num2str(ReturnChannel(mol)) + "_All")
	wave selpos = root:selpos
	wave bad = $("root:" + mol + "_flagBad")
	wave resp = $("root:" + mol + "_resp")

	// if resp is empty then return 1
	WaveStats /Q resp
	if ( V_npnts == 0 )
		return 0
	endif

	// Handle large chrnum
	if ( chrnum > AS[(numpnts(selpos)-1)])
		chrnum = AS[(numpnts(selpos)-1)]
	endif
	
	// handle NaN as an input
	if ( numtype(chrnum) == 2 )
		chrnum = returnMINchromNum(1)
	endif
	if ( numtype(up) == 2 )
		up = 1
	endif
	
	ch = ReturnChannel(mol)
	ResRow = ReturnResRowNumber( ch, chrnum )
	
	// not a good chrnum (usually from a poor first guess)
	if ( numtype(ResRow) == 2 )
		chrnum = returnMINchromNum(1)
		ResRow = ReturnResRowNumber( ch, chrnum )
	endif
	
	// return nearest cal chrom num
	if ( up == 0 )
		// if chrnum is in calssvLst return chrnum otherwise find nearest cal to chrnum
		if (WhichListItem(num2str(selpos[ResRow]), calssvLst, ",") != - 1)
			// don't count cals that are flagged bad  or have resp of NaN
			if (( bad[ResRow] == 0 ) && ( numtype(resp[ResRow]) == 0))
				return AS[ResRow]
			else
				return NextCal(chrnum+1, 0)
			endif
		else
			variable lowCal = NextCal(chrnum, -1)
			variable highCal = NextCal(chrnum, 1)
			if ((chrnum-lowCal) < (highCal - chrnum))
				return lowCal
			else
				return highCal
			endif
		endif
	endif
	
	// count cal injections upto chrnum
	for (i=ResRow+up; i<numpnts(selpos) && (i >= 0); i+= up)
		if (WhichListItem(num2str(selpos[i]), calssvLst, ",") != - 1)
			// don't count cals that are flagged bad or have resp of NaN
			if (( bad[i] == 0 ) && ( numtype(resp[i]) == 0))
				return AS[i]
			endif
		endif
	endfor
	
	// handle edges
	if (i<0)
		return NextCal( AS[0], -up )
	elseif (i >= numpnts(selpos))
		return NextCal( AS[numpnts(selpos)-1], -up )
	else
		return NextCal( AS[i]-up, -up )
	endif
	
end