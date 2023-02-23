#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.0
#pragma version=1.2

// version 1.2 added Dry mole fraction option for the exchange file.  GSD 20100701

Strconstant kDFCM = "root:CM"			// cal matrix data folder
Strconstant kDFTmp = "root:Tmp"		// temporary waves data folder
Strconstant kDFCal = "root:Cals"			// cal tanks (KLM, AAL, ALM)
Strconstant kDFpan = "root:Panel"		// panel variables, etc.
Strconstant kDFDB = "root:CurveDB"	// curve database
constant kMissingConc = 9999
constant kMissingPrec = 999

menu "Macros"
	"Update Exchange File Molecule Table", XC_molTable()
	"-"
	"Post Processing Panel/1", ppp()
	"ICARTT Panel/2", ICARTT_Data_panel()
	"-"
	"Display All Cal Cylinders", ViewCalCylinders()
	"-"
	"Cleanup Experiment"
end

Function MolTable()

	Wave /Z/T Molecules = root:Molecules
	String molLst = StrMakeOrDefault("root:S_molLst", "N2O;SF6;F11;F113")
	
	DoWindow /K MolTbl
	Edit/K=1/W=(5,42,204,351) Molecules as "Molecules"
	DoWindow /C MolTbl
	ModifyTable format(Point)=1,style(Molecules)=1
	
	SetWindow MolTbl,hook(MolTable)= UpdateTableHooks
end

function FlightTable()

	Wave /Z/T Flights = root:Flights
	String fltLst = StrMakeOrDefault("root:S_flightLst", "")

	SetWaveLock 0, Flights
	
	DoWindow /K flightTbl
	Edit/K=1/W=(5,42,204,351) Flights as "Flights"
	DoWindow /C flightTbl
	ModifyTable format(Point)=1,style(Flights)=1
	
	SetWindow flightTbl,hook(flightTbl)= UpdateTableHooks
end

// function is designed for the "new" calibration experiments
Function LoadCalibrationMatrices()
	
	// Find Cal file
	Open /R/D/T=".pxp" /M="Locate a Calibration Experiment"  K0
	String expName = S_filename
	if ( strlen(expName) == 0 )
		return -1
	endif
	
	NewDataFolder /O/S $kDFCM
	LoadData/Q/O/L=1/S="CalMatrix" expName
	SetDataFolder root:
	MakeCalCurveLists()
	Print "Calibration Matrices loaded from: " + expName
	
	// Added TankList setwavelock code.  171107
	NewDataFolder /O/S $kDFCal
	if (WaveExists(TankList) != 0)
		SetWaveLock 0, TankList
	endif
	
	// load all cal cylinders
	SetDataFolder root:
	LoadData/Q/O/L=1/S="CalCylinders" /T=Cals expName	
	
	KillDataFolder /Z $kDFTmp
	
end

function MakeCalCurveLists()

	SVAR mollst = root:S_molLst
	variable i
	string callstchk, mol
	
	SetDatafolder $kDFCM

	for (i=0; i<ItemsInList(mollst); i+=1 )
		mol = StringFromList(i, mollst)
		callstchk = mol + "_calCurveLst"
		if (exists(callstchk) == 0 )
			string /G $callstchk
		endif
		SVAR calLst = $callstchk

		string base = mol + "_CM_"			// base name of a cal matrix
		string CMlst = WaveList(base + "*", ";", "")
		
		CMlst = ReplaceString(base, CMlst, "")
		CMlst = SortList(CMlst)

		if (exists(mol + "_calCurves") == 1)
			Wave /Z/T CMlstWv = $mol + "_calCurves"
			SetWaveLock 0, CMlstWv
			MakeTextWaveFromList(CMlst, mol + "_calCurves", ";")
			SetWaveLock 1, CMlstWv
		else
			MakeTextWaveFromList(CMlst, mol + "_calCurves", ";")
			Wave /Z/T CMlstWv = $mol + "_calCurves"
			SetWaveLock 1, CMlstWv
		endif
		
		calLst = CMlst
	endfor
	
	SetDatafolder root:
	UpdateCalDB()
	SetDatafolder root:

end

Function LoadRespData()

	Wave /T Molecules = root:Molecules
	Wave /T Flights = root:Flights
	Wave MolSel = root:MoleculesSel
	Wave FltSel = root:FlightsSel
	SVAR molLst = root:S_molLst
	SVAR fltLst = root:S_FlightLst
	
	Variable NOSel_mol, NOSel_flt, i
	String loadList, filesList, file, tsecsList, dateList, mol, grepmols, grepflts, tmp
	
	// Define path to resp waves
	PathInfo respPath
	if ( ! V_flag )
		NewPath /M="Locate path to flight response waves." respPath
	endif
	
	// Check to see if anything is selected
	Wavestats /M=1/Q MolSel
	NOSel_mol = V_avg==0 ? 1 : 0
	Wavestats /M=1/Q/Z FltSel
	NOSel_flt = V_avg==0 ? 1 : 0
	if ( numpnts(FltSel) == 0 )
		NOSel_flt = 1
	endif

	loadList = ""
	filesList = IndexedFile(respPath,-1,".ibw")
	tsecsList = GrepList(filesList, "(?i)tsecs*")
	dateList = ReplaceString("tsecs_", tsecsList, "")
	dateList = ReplaceString(".ibw", dateList, "")				// list of dates in respPath
	
	if ( NOSel_mol )
		// grep expression to pick out mols in mollst
		grepmols = "(?i)(" + ReplaceString(";", molLst, "_|")		
		MolSel = 1
	else
		// grep expression to pick out selected molecules
		grepmols = "(?i)(" + ReplaceString(";", ReturnSelectedMolecules(), "_|")		
	endif
	grepmols += "selpos_|tsecs_)"								// include selpos and tsecs
	
	// No flights selected in lists
	if ( NOSel_flt )
		if (ItemsInList(dateList) > 1 )
			String WhichDate
			Prompt WhichDate, "Load data for which date?", popup, "ALL DATES;" + dateList
			DoPrompt "Loading Flight Data", WhichDate
			if (V_flag)
				return -1
			endif
			if ( cmpstr(WhichDate, "ALL DATES") == 0 )
				tmp = ReturnSelectedFlights()
				tmp = tmp[0, strlen(tmp)-2]		// remove ;
				grepflts = "(" + ReplaceString(";", tmp, "|") + ")"
				loadList = GrepList(filesList, grepflts)
				loadList = GrepList(loadList, grepmols)
				for (i=0; i<ItemsInList(dateList); i+=1 )
					AddDateToFlightWave(StringFromList(i, dateList))
				endfor
				FltSel = 1
			else
				loadList = GrepList(filesList, "_"+WhichDate)
				loadList = GrepList(loadList, grepmols)
				AddDateToFlightWave(WhichDate)
			endif
		else
			loadList = GrepList(filesList, "_"+StringFromList(0,dateList))
			loadList = GrepList(loadList, grepmols)
			AddDateToFlightWave(StringFromList(0,dateList))
		endif
		loadList = GrepList(loadList, grepmols)
		
	else
		tmp = ReturnSelectedFlights()
		tmp = tmp[0, strlen(tmp)-2]		// remove ;
		grepflts = "(" + ReplaceString(";", tmp, "|") + ")"
		loadList = GrepList(filesList, grepflts)
		loadList = GrepList(loadList, grepmols)

	endif
	
	// /load waves
	for (i=0; i<ItemsInList(loadList); i+=1 )
		file = StringFromList(i, loadList)
		LoadWave/H/P=respPath/O file
	endfor
	
end

// dt = date
// will add a date to the flight wave if it is not allready in the list
function AddDateToFlightWave( dt )
	string dt

	Wave /T Flights = root:Flights
	Wave FltSel = root:FlightsSel
	SVAR fltLst = root:S_flightLst
	variable i
	
	for ( i=0; i<numpnts(Flights); i+=1)
		if ( cmpstr(dt, Flights[i]) == 0 )
			FltSel = 0
			FltSel[i] = 1
			return 0
		endif
	endfor
	
	InsertPoints numpnts(Flights), 1, Flights, FltSel
	
	Flights[numpnts(Flights)-1] = dt
	FltSel[numpnts(Flights)-1] = 1
	
	Sort Flights, Flights, FltSel
	
	fltLst = WaveToList("Flights", ";")

	return 1
	
end

function/S ReturnSelectedFlights()

	Wave /T Flights = root:Flights
	Wave FltSel = root:FlightsSel
	variable i
	string lst=""

	for ( i=0; i<numpnts(Flights); i+=1 )
		if ( FltSel[i] == 1 )
			lst = AddListItem(Flights[i], lst)
		endif
	endfor
	
	return SortList(lst)

end

function/S ReturnSelectedMolecules()

	Wave /T Molecules = root:Molecules
	Wave MolSel = root:MoleculesSel
	variable i
	string lst=""

	for ( i=0; i<numpnts(Molecules); i+=1 )
		if ( MolSel[i] == 1 )
			lst = AddListItem(Molecules[i], lst)
		endif
	endfor
	
	return lst

end


// function called from post processing panel
function ApplyCalCurves()

	string mols = ReturnSelectedMolecules(), mol
	string flts = ReturnSelectedFlights(), flt
	
	if ((ItemsInList(mols) < 1 ) || (ItemsInList(flts) < 1 ))
		abort "You need to select one or more molecules and flights from their lists."
	endif
	
	variable f, m, frow
	string curve, resp
	
	for(f=0; f<ItemsInList(flts); f+=1)
		flt = StringFromList(f, flts)
		frow = ReturnFlightRow(flt)
		
		for (m=0; m<ItemsInList(mols); m+=1 )
			mol = StringFromList(m, mols)
			resp = ReturnRespType( mol )
			Wave /Z/T DBwv = $kDFDB + ":" + mol + "_" + resp + "_curveDB"
			if ( WaveExists(DBwv) )
				curve = DBwv[frow]
				Wave CM = $kDFCM + ":" + mol + "_CM_" + curve
				ApplyCalMatrix(flt, mol, resp, CM)
			else
				Print "еее No cal matrices loaded for " + mol + " еее"
				beep
			endif
		endfor
			
	endfor

end


function ApplyCalMatrix(flt, mol, r, CM)
	string flt, mol, r
	wave CM
	
	string respstr = mol + "_" + r + "_" + flt
	string concstr = mol + "_" + r + "_conc_" + flt
	string precstr = mol + "_" + r + "_prec_" + flt
	if ( exists(respstr) == 0 )
		return -1
	endif
	
	NVAR makeplots = $kDFpan + ":G_makeplots"
	
	String NT = note(CM)
	String Fit = StringByKey("FIT", NT)
	String NCyl = StringByKey("NCYL", NT)
	String Cday = StringByKey("CDAY", NT)
	Variable err = NumberByKey("ERR", NT)
//	Variable pts = NumberByKey("PTS", NT)
//	Variable RLO = NumberByKey("RLO", NT)
//	Variable RHI = NumberByKey("RHI", NT)

	Variable CalVal = ReturnCalValue(mol, NCyl)
	
	Wave resp = $respstr
	Make /o/n=(numpnts(resp)) $concstr = nan, $precstr = nan
	Wave conc = $concstr
	Wave prec = $precstr
	
	// flight cal error
	String FltNT = note(resp)
	Variable FltCalErr
	FltCalERR = str2num(FltNT[strsearch(FltNT,"cal: ", 0)+5, strsearch(FltNT, "%", 0)]) * CalVal/100
	
	conc = NumSolveCalCurve(CM, resp)
	// precision =  conf bands + residual error from cal curve + residual from normalized cal during flight
	prec = Sqrt(ConfBand(CM, conc)^2 + (CalVal*err)^2 + FltCalERR^2)
	
	if ( makeplots )
		FlightPlot( flt, mol, r, CM )
	endif
	
end

function FlightPlot( flt, mol, r, CM )
	string flt, mol, r
	Wave CM

	String /G S_unit =  "ppt"
	SVAR /Z unit = S_unit
	
	String NT = note(CM)
	String Fit = StringByKey("FIT", NT)
	String Cday = StringByKey("CDAY", NT)
	
	String tsecs = "tsecs_" + flt
	String respstr = mol + "_" + r + "_" + flt
	String concstr = mol + "_" + r + "_conc_" + flt
	String precstr = mol + "_" + r + "_prec_" + flt
	String txt, win = mol + "_" + flt+r+"_plot"
	
	if ( (exists(tsecs) == 0 ) || (exists(respstr) == 0 ) )
		return -1
	endif
	
	// if win is displayed already then save it's location and redisplay.
	if ( GrepString(Winlist("*_plot", ";", "WIN:1"), win) )
		GetWindow $win wsize
		DoWindow /k $win
		Display /K=1/W=(V_left, V_top, V_right, V_bottom) $concstr vs $tsecs as flt + " " + mol + " " + r
	else
		DoWindow /k $win
		Display /K=1/W=(457,46,1153,377) $concstr vs $tsecs as flt + " " + mol + " " + r
		AutoPositionWindow /M=1
	endif
	DoWindow /c $win
	AppendToGraph $concstr vs $tsecs

	ModifyGraph margin(top)=29
	ModifyGraph mode($concstr)=2,mode($concstr#1)=3
	ModifyGraph marker=19
	ModifyGraph rgb($concstr#1)=(39321,1,1)
	ModifyGraph msize=2
	ModifyGraph gaps($concstr)=0
	ModifyGraph grid=1
	ModifyGraph mirror=2
	
	Sprintf txt, "\\f01%s (%s)", FullMolName(mol), unit
	Label left txt
	Label bottom "\\f01Time of Day (s)"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	ErrorBars $concstr Y,wave=($precstr,$precstr)
	
	Sprintf txt, "Flight: \\f01%s\\f00 using \\f01%s\\f00.  Cal. Matrix: \\f01%s_%s\\f00", flt, r, Cday, Fit
	TextBox/C/N=info/F=0/A=MC/X=-24.34/Y=55.94 txt

	Wavestats /Q $precstr
	Sprintf txt, "Avg precision: \\f01%05.3f %s\\f00", V_avg, unit

	TextBox/C/N=text0/F=0/A=MC/X=37.50/Y=56.32 txt
	
end

Function CorrelationPlot()

	NVAR dspC = $kDFpan + ":G_dispmodeC"
	NVAR dspP = $kDFpan + ":G_dispprec"

	string mols = ReturnSelectedMolecules(), mol
	string flts = ReturnSelectedFlights(), flt

	if ((ItemsInList(mols) != 2 ) || (ItemsInList(flts) < 1 ))
		abort "Select two molecules and at least one flight from the lists."
	endif
	
	String win, txt, molX, molY, rX, rY, dataX, dataY, dataXsd, dataYsd, repY
	variable f, frow
	
	Prompt molX, "Select molecule for X-axis", popup, mols
	DoPrompt ReplaceString(";", mols, " ") + "Correlation plot", molX
	if (V_flag)
		return -1
	endif
	molY = ReplaceString(";", RemoveFromList(molX, mols), "")
	
	// handle two different resp types if need be
	rX = ReturnRespType( molX )
	rY = ReturnRespType( molY )
	
	win = "CorrPlot_" + molY+rY+"vs"+molX+rX + Num2str(dspC)
	DoWindow /k $win
	Display /K=1/W=(35,44,658,521) as "Flight Corr Plot: " + molY + " v " + molX
	DoWindow /c $win
	
	// Make color table wave
	//NewDataFolder /O/S $kDFtmp
	//ColorTab2Wave Rainbow16
	SetDataFolder $kDFpan
	if (exists("color_table") == 0 )
		Make /n=(12,3) color_table
		color_table[0][0]= {65535,0,0,65535,16385,32764,65535,16385,49157,49157,0,0}
		color_table[0][1]= {0,65535,0,32764,65535,16385,49157,65535,16385,0,49157,0}
		color_table[0][2]= {0,0,65535,16385,32764,65535,16385,49157,65535,0,0,49157}
	endif
	wave ctab = $kDFpan + ":color_table"
	variable clen = DimSize(ctab, 0)
	SetDataFolder root:
	
	for(f=0; f<ItemsInList(flts); f+=1)
		flt = StringFromList(f, flts)
		frow = ReturnFlightRow(flt)
		if ( dspC )
			dataX = molX + "_" + rX + "_conc_" + flt
			dataY = molY + "_" + rY + "_conc_" + flt
			repY = molY + "_" + rY + "_conc_"
		else
			dataX = molX + "_" + rX + "_" + flt
			dataY = molY + "_" + rY + "_" + flt
			repY = molY + "_" + rY + "_"
		endif
		
		AppendToGraph $dataY vs $dataX
		ModifyGraph rgb($dataY) = (ctab(mod(f,clen))[0], ctab(mod(f,clen))[1], ctab(mod(f,clen))[2])
		ModifyGraph marker($dataY) = floor(f/5)
		
		if ((dspP) && (dspC))
			dataXsd = molX + "_" + rX + "_prec_" + flt
			dataYsd = molY + "_" + rY + "_prec_" + flt
			ErrorBars $dataY XY,wave=($dataXsd,$dataXsd),wave=($dataYsd,$dataYsd)
		endif
		
	endfor
	
	SVAR /Z unit = root:S_unit
	if ( dspC )
		sprintf txt, "\f01%s (%s)", FullMolName(molY), unit
		Label left txt
		sprintf txt, "\f01%s (%s)", FullMolName(molX), unit
		Label bottom txt
	else
		sprintf txt, "\f01%s\f00 (normalized resp)", FullMolName(molY)
		Label left txt
		sprintf txt, "\f01%s\f00 (normalized resp)", FullMolName(molX)
		Label bottom txt
	endif
	
	ModifyGraph mode=3, msize=2, grid=1,mirror=2
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom

	Legend	
	String box_name=StringFromList(0,ListMatch(AnnotationList(""),"text*"))
	String old_text=StringByKey("TEXT",AnnotationInfo("",box_name,1))
	old_text = ReplaceString(") "+repY, old_text, ")")
	TextBox/C/N=$box_name /X=86.4 /Y=0 "\Z10"+old_text
	
end

function TimeSeriesPlot()

	NVAR dspC = $kDFpan + ":G_dispmodeC"
	NVAR dspP = $kDFpan + ":G_dispprec"

	string mols = ReturnSelectedMolecules(), mol1, mol2 = ""
	string flts = ReturnSelectedFlights(), flt
	
	if ((ItemsInList(mols) > 2 ) || (ItemsInList(mols) == 0 ) || (ItemsInList(flts) < 1 ))
		abort "Select one ore two molecules and at least one flight from the lists."
	endif

	String /G S_unit =  "ppt"
	SVAR /Z unit = S_unit

	variable both = ItemsInList(mols) == 2 ? 1 : 0
	variable f, m
	String tsecs, resp1, resp2, conc1, conc2, prec1, prec2, txt, win, r1, r2, Y1, Y2

	// make a plot for each flight selected.
	for (f=0; f<ItemsInList(flts); f+=1 )
		flt = StringFromList(f, flts)
		tsecs = "tsecs_" + flt

		mol1 = StringFromList(0, mols)
		r1 = ReturnRespType(mol1)
		resp1 = mol1 + "_" + r1 + "_" + flt
		conc1 = mol1 + "_" + r1 + "_conc_" + flt
		prec1 = mol1 + "_" + r1 + "_prec_" + flt
		if ( both )
			mol2 = StringFromList(1, mols)
			r2 = ReturnRespType(mol2)
			resp2 = mol2 + "_" + r2 + "_" + flt
			conc2 = mol2 + "_" + r2 + "_conc_" + flt
			prec2 = mol2 + "_" + r2 + "_prec_" + flt
			win = mol1+mol2 + "_" + flt+r1+r2+"_timeseries"
		else
			win = mol1+ "_" + flt+r1+"_timeseries"
		endif
	
		// abort if missing data
		if ( (exists(tsecs) == 0 ) || (exists(resp1) == 0 ) )
			return -1
		endif
		if (( both ) && (exists(resp2) == 0 ) )
			return -1
		endif
		
		Y1 = resp1
		if ( dspC )
			Y1 = conc1
		endif
		
		if ( both )
			Y2 = resp2
			if ( dspC )
				Y2 = conc2
			endif
		endif
		
		
		// if win is displayed already then save it's location and redisplay.
		if ( GrepString(Winlist("*_timeseries", ";", "WIN:1"), win) )
			GetWindow $win wsize
			DoWindow /k $win
			Display /K=1/W=(V_left, V_top, V_right, V_bottom) $Y1 vs $tsecs as flt + " " + mol1 + " " + mol2 + " timeseries"
		else
			DoWindow /k $win
			Display /K=1/W=(457,46,1153,377) $Y1 vs $tsecs as flt + " " + mol1 + " " + r1
			AutoPositionWindow /M=1
		endif
		DoWindow /c $win

		if ( both && dspC )
			AppendToGraph /R $conc2 vs $tsecs
		elseif (( both ) && ( !dspC ))
			AppendToGraph /R $resp2 vs $tsecs
		endif
	
		if ( both )
			ModifyGraph grid(bottom)=1
			ModifyGraph mirror(bottom)=2
			ModifyGraph rgb($Y2)=(0,0,65535)
		else
			ModifyGraph grid=1, mirror=2
		endif

		ModifyGraph margin(top)=29
		ModifyGraph mode=4,marker=19
		ModifyGraph msize=2
		ModifyGraph gaps=0

		if (dspP && dspC)
			ErrorBars $conc1 Y,wave=($prec1,$prec1)
		endif
		if ( both  && dspP && dspC )
			ErrorBars $conc2 Y,wave=($prec2,$prec2)
		endif

		if ( dspC )
			Sprintf txt, "\\K(65535,0,0)\\f01%s (%s)", FullMolName(mol1), unit
		else
			Sprintf txt, "\\K(65535,0,0)\\f01%s\\f00 Normalized Response (%s)", FullMolName(mol1), r1
		endif		
		Label left txt
		Label bottom "\\f01Time of Day (s)"
		SetAxis/A/N=1 left
		
		if (( both ) && ( dspC ))
			Sprintf txt, "\\K(0,0,65535)\\f01%s (%s)", FullMolName(mol2), unit
			Label right txt
			SetAxis /A/N=1 right
		elseif (( both ) && ( !dspC ))
			Sprintf txt, "\\K(0,0,65535)\\f01%s\\f00 Normalized Response (%s)", FullMolName(mol2), r2
			Label right txt
			SetAxis /A/N=1 right
		endif		
		
		Sprintf txt, "Flight: \\f01%s\\f00", flt
		TextBox/C/N=info/F=0/A=MC/X=-41.99/Y=55.89 txt
	
	endfor
	
	

end

// numerically finds solution to cal curve.
function NumSolveCalCurve(CM, resp)
	wave CM
	variable resp

	// bail if resp = nan
	if ( numtype(resp) != 0 )
		return NaN
	endif
	
	String NT = note(CM)
	String curve = StringByKey("FIT", NT)
//	String NCyl = StringByKey("NCYL", NT)
//	String Cday = StringByKey("CDAY", NT)
//	Variable err = NumberByKey("ERR", NT)
//	Variable pts = NumberByKey("PTS", NT)
	Variable RLO = NumberByKey("RLO", NT)
	Variable RHI = NumberByKey("RHI", NT)

	if ( GrepString(curve, "poly3frc") )
		FUNCREF FC_CalCurveFuncs f = $"FC_Poly3frc"
	elseif ( GrepString(curve, "poly4frc") )
		FUNCREF FC_CalCurveFuncs f = $"FC_Poly4frc"
	else
		FUNCREF FC_CalCurveFuncs f = $"FC_" + curve
	endif

	variable /d delta, tol = 0.0001, itr
	variable /d i, c = RHI, stp, dir
	
	NewDataFolder /S/O $kDFTmp
	make /o/n=(DimSize(CM,0)) coef = CM[p][0]
	Wave coef = coef
	SetDataFolder root:

	delta = f(coef, c) - resp
	stp = abs(delta) * (RHI-RLO)
	do
		if ( delta > 0 )
			c -= stp
			stp /= (dir == 1) ? 2 : 1
			dir = -1
		else
			c += stp
			stp /= (dir == -1) ? 2 : 1
			dir = 1
		endif

		if ( c < -10 )		// conc way too low
			c = 0
			stp /= 2
		elseif (c > RHI * 4)		// conc way to high
			c = RHI 
			stp /= 2
		endif

		delta = f(coef, c) - resp

		itr += 1
		if ( itr > 100 )
			return NaN
		endif
	while( abs(delta) > tol )	

	return c

end

// solves using BinarySearch
// much slower than the num solution
function GraphSolveCalCurve(CM, resp)
	wave CM
	variable resp

	// bail if resp = nan
	if ( numtype(resp) != 0 )
		return NaN
	endif
	
	String NT = note(CM)
	String curve = StringByKey("FIT", NT)
	Variable RLO = NumberByKey("RLO", NT)
	Variable RHI = NumberByKey("RHI", NT)
	variable c
	
	if ( GrepString(curve, "poly3frc") )
		FUNCREF FC_CalCurveFuncs f = $"FC_Poly3frc"
	elseif ( GrepString(curve, "poly4frc") )
		FUNCREF FC_CalCurveFuncs f = $"FC_Poly4frc"
	else
		FUNCREF FC_CalCurveFuncs f = $"FC_" + curve
	endif

	NewDataFolder /S/O $kDFTmp
	make /o/n=(DimSize(CM,0)) coef = CM[p][0]
	Wave coef = coef
	SetDataFolder root:

	Make /o/n=500 fit
	SetScale/I x RLO,RHI,"", fit
	fit = f(coef,x)
	c = pnt2x(fit, BinarySearchInterp(fit, resp))

	return c

end

// returns confidance limit for a givin concentration
Function ConfBand(CM, cc)
	wave CM
	variable cc

	String NT = note(CM)
	String curve = StringByKey("FIT", NT)
//	String NCyl = StringByKey("NCYL", NT)
//	String Cday = StringByKey("CDAY", NT)
//	Variable err = NumberByKey("ERR", NT)
	Variable pts = NumberByKey("PTS", NT)
	Variable RLO = NumberByKey("RLO", NT)
	Variable RHI = NumberByKey("RHI", NT)
	Variable conflevel = 0.68		// 1-sigma

	NewDataFolder /S/O $kDFTmp
	make /o/n=(DimSize(CM,0)) coef = CM[p][0]
	make /o/n=(DimSize(CM,0), DimSize(CM,1)-1) covar = CM[p][q+1]
	Wave coef, covar
	Duplicate /D/O coef, epsilon, dyda
	Wave epsilon, dyda
	epsilon = 1e-6
	SetDataFolder root:
	
	calcDerivs(cc, coef, dyda, epsilon, curve)

	variable i = 0, j, temp, tp
	variable YVar = 0
	Variable LpEnd = numpnts(coef)
	Variable DegFree = pts - 2
	
	for ( i=0; i < LpEnd; i+=1 )
		temp = 0
		for ( j=0; j < LpEnd; j+=1 )
			temp += covar[j][i]*dyda[j]
		endfor
		YVar += temp*dyda[i]
	endfor
	
	tP = StudentT(confLevel, DegFree)
	
	return tP*sqrt(YVar)
	
end

Function calcDerivs(xx, params, dyda, epsilon, curve)
	Variable xx
	Wave params, dyda, epsilon
	string curve
	
	Duplicate/O params, theP

	if ( GrepString(curve, "poly3frc") )
		FUNCREF FC_CalCurveFuncs f = $"FC_Poly3frc"
	elseif ( GrepString(curve, "poly4frc") )
		FUNCREF FC_CalCurveFuncs f = $"FC_Poly4frc"
	else
		FUNCREF FC_CalCurveFuncs f = $"FC_" + curve
	endif
	
	Variable yhat = f(params, xx)
	Variable i = 0
	Variable LpEnd = numpnts(params)
	do
		theP = params
		theP[i] = params[i]-epsilon[i]
		yhat = f(theP, xx)
		theP[i] = params[i]+epsilon[i]
		dyda[i] = (yhat - f(theP, xx))/(2*epsilon[i])
		i += 1
	while (i < LpEnd)
	
	Killwaves theP
end


// Cal curve function definitions used for FUNCREF
Function FC_CalcurveFuncs( w, x )
	Wave w
	variable x
	
end

Function FC_line(w,x)
	Wave w
	variable x
	return w[0] + w[1]*x 
end

Function FC_Poly3(w,x)
	Wave w
	variable x
	return w[0] + w[1]*x + w[2]*x*x
end

Function FC_Poly4(w,x)
	Wave w
	variable x
	return w[0] + w[1]*x + w[2]*x^2 + w[3]*x^3
end


Function FC_Poly3frc(w,x)
	Wave w
	variable x
	return w[0] + w[1]*(x-w[3]) + w[2]*(x-w[3])^2
end

Function FC_Poly4frc(w,x)
	Wave w
	variable x
	return w[0] + w[1]*(x-w[4]) + w[2]*(x-w[4])^2 + w[3]*(x-w[4])^3
end


function ReturnFlightRow( flt )
	string flt

	Wave /T Flights = root:Flights
	variable i

	for (i=0; i<numpnts(Flights); i+=1 )
		if ( cmpstr(flt, Flights[i]) == 0 )
			return i
		endif	
	endfor
	
	return -1
	
end


Function/S FullMolName(mol)
	string mol
	
	SetDataFolder root:
	String /G S_unit = "ppt"
	
	if (GrepString(mol, "N2O|n2o"))
		S_unit = "ppb"
		return "N2O"
	elseif (GrepString(mol, "SF6|sf6"))
		return "SF6"
	elseif (GrepString(mol, "F113|f113"))
		return "CFC-113"
	elseif (GrepString(mol, "F11|f11"))
		return "CFC-11"
	elseif (GrepString(mol, "F12|f12"))
		return "CFC-12"
	elseif (GrepString(mol, "HCFC22|hcfc22"))
		return "HCFC-22"
	elseif (GrepString(mol, "142b"))
		return "HCFC-142b"
	elseif (GrepString(mol, "MC|mc"))
		return "CH3CCl3"
	elseif (GrepString(mol, "CCl4|ccl4"))
		return "CCl4"
	elseif (GrepString(mol, "CHCl3|chcl3"))
		return "CHCl3"
	elseif (GrepString(mol, "CCl4|ccl4"))
		return "CCl4"
	elseif (GrepString(mol, "CH3Cl|ch3cl"))
		return "CH3Cl"
	elseif (GrepString(mol, "CH3Br|ch3br"))
		return "CH3Br"
	elseif (GrepString(mol, "1211"))
		return "halon-1211"
	elseif (GrepString(mol, "COS|cos|OCS|ocs"))
		return "COS"
	elseif (GrepString(mol, "CO|co"))
		S_unit = "ppb"
		return "CO"
	elseif (GrepString(mol, "H2|h2"))
		S_unit = "ppb"
		return "H2"
	elseif (GrepString(mol, "CH4|ch4"))
		S_unit = "ppb"
		return "CH4"
	elseif (GrepString(mol, "H2O|h2o"))
		S_unit = "ppm"
		return "H2O"
	else
		return ""
	endif	

end

function DisplayACalCurve()

	String /G S_unit = "ppt"
	SVAR unit = S_unit

	string CM, lst = ""
	string mols = ReturnSelectedMolecules()
	Variable i
	Variable NewAppend = 1
	String TopGraph = StringFromList(0, WinList("*", ";", "WIN:1"))
	if ( GrepString(TopGraph, "CalCurves") )
		NewAppend = 2
	endif
	
	NewDataFolder /S/O $kDFCM
	for ( i=0; i<ItemsInList(mols); i+=1 )
		lst += Wavelist(StringFromList(i, mols) + "_CM_*", ";", "")
	endfor
	prompt CM, "Cal Matrix Name", popup, SortList(lst)
	prompt NewAppend, "New plot or append to top plot", popup, "New;Append"
	if ( NewAppend == 1 )
		DoPrompt "Display Calibration Curves", CM
	else
		DoPrompt "Display Calibration Curves", CM, NewAppend
	endif
	if ((V_Flag) || ( cmpstr(CM, "_none_") == 0 ))
		return -1								// User canceled
	endif

	Wave CMwv = $CM
	SetDataFolder root:
	
	String mol = CM[0, strsearch(CM, "_CM_", 0)-1]
	String NT = note(CMwv)
	String curve = StringByKey("FIT", NT)
	String NCyl = StringByKey("NCYL", NT)
	String Cday = StringByKey("CDAY", NT)
	Variable err = NumberByKey("ERR", NT)
	Variable pts = NumberByKey("PTS", NT)
	Variable RLO = NumberByKey("RLO", NT)
	Variable RHI = NumberByKey("RHI", NT)

	string fitstr = "calcv_" + mol + "_" + curve + "_" + Cday
	string UCstr = "calcvUC_" + mol + "_" + curve + "_" + Cday
	string LCstr = "calcvLC_" + mol + "_" + curve + "_" + Cday
	string txt, win = mol + "CalCurves"
	string title = mol + " Cal. Curves"

	// use the plot's limits if larger
	if ( NewAppend == 2)
		GetAxis /Q bottom
		RLO = min(RLO, V_min)
		RHI = min(RHI, V_max)
	endif

	NewDataFolder /S/O $kDFtmp
	Make /o/n=(DimSize(CMwv, 0)) cal_coef
	Make /n=200/o $fitstr, $UCstr, $LCstr
	wave fit = $fitstr
	wave UC = $UCstr
	wave LC = $LCstr
	SetScale/I x RLO,RHI,"", fit, UC, LC
	
	// fill in cal_coef wave
	for ( i=0; i<DimSize(CMwv, 0); i+=1 )
		cal_coef[i] = CMwv[i][0]
	endfor

	if ( GrepString(curve, "poly3frc") )
		FUNCREF FC_CalCurveFuncs f = $"FC_Poly3frc"
	elseif ( GrepString(curve, "poly4frc") )
		FUNCREF FC_CalCurveFuncs f = $"FC_Poly4frc"
	else
		FUNCREF FC_CalCurveFuncs f = $"FC_" + curve
	endif
	
	fit = f(cal_coef, x)
	UC = ConfBand(CMwv, fit)
	LC = fit - UC
	UC += fit
	
	// make display
	if ( NewAppend == 1)		// new plot
		Display /K=1/W=(491,44,886,252) fit, UC, LC as title
		DoWindow /C $win
		ModifyGraph grid=1,mirror=2
		Label left "Norm. Response"
		FullMolName(mol)
		Label bottom FullMolName(mol) + " (" + unit + ")"
		sprintf txt, "\\s(%s) %s", fitstr, ReplaceString("calcv_", fitstr, "")
		Legend/C/N=legd/J/X=47.91/Y=1.91txt
		AutoPositionWindow /M=1
	else
		ChooseColor
		DoWindow /F $win
		txt = StringByKey("TEXT", AnnotationInfo("", "legd",1))
		sprintf txt, "%s\r\\s(%s) %s", txt, fitstr, ReplaceString("calcv_", fitstr, "")
		AppendToGraph fit, UC, LC
		ModifyGraph rgb($fitstr)=(V_Red, V_Green, V_Blue)
		ModifyGraph rgb($UCstr)=(V_Red, V_Green, V_Blue)
		ModifyGraph rgb($LCstr)=(V_Red, V_Green, V_Blue)
		Legend/C/N=legd/J/X=47.91/Y=1.91 txt
	endif

	ModifyGraph lstyle($UCstr)=1, lstyle($LCstr)=1
	
	DoWindow /F $win
	
	Killwaves cal_coef
	
	SetDataFolder root:
	
end


Window CalCylinders() : Table
	PauseUpdate; Silent 1		| building window...
	
	SetDataFolder $kDFCal
	
	string str= wavelist("KLM*",";","") + wavelist("ALM*",";","")
	MakeTextWaveFromList(root:S_KLMmolLst, "TankMols", ";")
	Edit/K=1/W=(3,46,636,403) TankMols as "All Cal Cylinders"
	lbat("AppendtoTable @", str)
	ModifyTable width=60
	
	SetDataFolder root:

End

// kills waves in the tmp data folder
proc CleanupExperiment()

	NewDataFolder /O/S $kDFTmp
	
	bat("killwaves /Z @", "*")
	
	SetDataFolder root:
	
end


function UpdateTableHooks(s )
	STRUCT WMWinHookStruct &s	
	
	SVAR molLst = root:S_molLst
	SVAR fltLst = root:S_flightLst
	
	if (cmpstr(s.winName, "MolTbl") == 0 )
		if (( cmpstr(s.eventName, "deactivate") == 0 ) || ( cmpstr(s.eventName, "kill") == 0 ) )
			SetDataFolder root:
			molLst = WaveToList("Molecules", ";")
			Wave /T Molecules = root:Molecules
			Make/O/U/W/N=(numpnts(Molecules)) MoleculesSel = 0
			UpdateCalDB()
		endif
	elseif (cmpstr(s.winName, "flightTbl") == 0 )
		if (( cmpstr(s.eventName, "deactivate") == 0 ) || ( cmpstr(s.eventName, "kill") == 0 ))
			SetDataFolder root:
			fltLst = WaveToList("Flights", ";")
			Wave /T Flights = root:Flights
			Make/O/U/W/N=(numpnts(Flights)) FlightsSel = 0
			UpdateCalDB()
			SetWaveLock 1, Flights
		endif
	endif

end

// maintains the Cal curve Database for each flight
function UpdateCalDB()

	SVAR molLst = root:S_molLst
	SVAR fltLst = root:S_flightLst
	
	if (( ItemsInList(fltLst) == 0 ) || ( ItemsInList(molLst) == 0 ))
		SetDataFolder root:
		return -1
	endif

	string mol, DB, item, curve = ""
	variable i, numflts = ItemsInList(fltLst)

	// list of loaded data
	string respdata, respMols = ""
	respdata = WaveList("*hght*", ";", "") + WaveList("*area*", ";", "")
	respdata = GrepList(respdata, "(?i)(hght_\d|area_\d)")
	
	// remove flight dates
	for ( i=0; i<ItemsInList(respdata); i+=1 )
		item = StringFromList(i, respdata)
		respMols += item[0, strsearch(item, "_", strlen(item), 1)-1] + ";"
	endfor
	respMols = UniqueList(respMols)
	
	NewDataFolder /O/S $kDFDB

	// make if not there
	for ( i=0; i<ItemsInList(respMols); i+=1 )
		item = StringFromList(i, respMols)
		mol = item[0, strsearch(item, "_", 0)-1]
		SVAR /Z curveLst = $kDFCM + ":" + mol + "_calCurveLst"
		curve = StringFromList(0, curveLst)
		DB = item + "_curveDB"
		if ( exists(DB) == 0 )
			make /t/n=(numflts) $DB = curve
		endif	
	endfor
	
	// lengthen if another flight was added
	for ( i=0; i<ItemsInList(respMols); i+=1 )
		item = StringFromList(i, respMols)
		wave DBwv = $item + "_curveDB"
		if (numpnts(DBwv) < numflts )
			InsertPoints numpnts(DBwv), numflts-numpnts(DBwv), DBwv
		elseif (numpnts(DBwv) > numflts )
			beep
			Print "-- It appears the " + item + "_curveDB" + " wave is larger than the number of flights.  You will need to manually edit this wave."
		endif
	endfor	
	
	SetDataFolder root:

end

function CalCurveTable()

	string mols = ReturnSelectedMolecules()
	string mol, win, title, resp, curveDBstr, curvesStr
	variable i

	UpdateCalDB()

	for (i=0; i<ItemsInList(mols); i+=1 )
		
		mol = StringFromList(i, mols)
		resp = ReturnRespType(mol)
		win = mol + "_" + resp + "_calcurveTable"
		title = "Assign " + mol + " " + resp + " cal curves"
		curveDBstr = mol + "_" + resp + "_curveDB"
		curvesStr = mol + "_calCurves"

		SetDataFolder root:	
		DoWindow /K $win
		if ( exists(kDFDB + ":" + curveDBstr) == 0)
			return -1
		endif
		Edit/K=1/W=(13,461,459,693)  Flights,$kDFDB + ":" + curveDBstr,$kDFCM + ":" + curvesStr as title
		DoWindow /C $win
		ModifyTable format(Point)=1,width(Point)=44,style(Flights)=1,width(Flights)=96
		ModifyTable rgb($kDFDB + ":" + curveDBstr)=(1,26214,0), width($kDFDB + ":" + curveDBstr)=128
		ModifyTable rgb($kDFCM + ":" + curvesStr)=(52428,1,1),width($kDFCM + ":" + curvesStr)=134
		AutoPositionWindow /E/M=0 $win
	endfor

end

function/S ReturnRespType( mol )
	string mol

	SetDataFolder root:

	string resp
	variable H, A
	
	if ( strlen(WaveList(mol + "_hght_*", ";", "")) > 0 )
		H = 1
		resp = "hght"
	endif
	if ( strlen(WaveList(mol + "_area_*", ";", "")) > 0 )
		A = 1
		resp = "area"
	endif
	
	if ( A && H )
		prompt resp, "Choose a response type", popup, "hght;area"
		DoPrompt "Both Area and Hight responses loaded for " + mol, resp
		if (V_flag)
			abort "Aborted"
		endif
	elseif ( A+H == 0 )
		Print "еее No response data for " + mol + " is loaded.  Using: hght"
		beep
		resp = "hght"
	endif
	
	return resp
			
end

// returns the assigned cal tank value for a given tank
Function ReturnCalValue(mol, tank)
	string mol, tank
	
	SetDataFolder $kDFCal
	if (exists("KLMmolecules") == 1)
		rename KLMmolecules TankMols
	endif
	if (exists("KLMlist") == 1)
		rename KLMlist TankList
	endif
	Wave /T tanks = $kDFCal + ":TankList"
	String tanklst = WaveToList("TankList", ";")
	SetDataFolder root:
	
	// blank
	if (( Numpnts(tanks) == 0 ) || ( strlen(tank) == 0 ))
		return NaN
	endif
	
	if ( WhichListItem(tank, tanklst) == -1 )
		Abort "Bad cal tank name: " + tank
	endif
	
	Wave /T KLMmols = $kDFCal + ":TankMols"
	Wave KLM = $kDFCal + ":" + tank
	Variable i
	
	for( i=0; i<numpnts(KLMmols); i+=1 )
		if ( cmpstr(KLMmols[i], mol) == 0 )
			return KLM[i]
		endif
	endfor

	return NaN	
	
end

// displays all cal cylinders in the Cal cylinder folder
function ViewCalCylinders()

	String win = "AllCalCyls"
	variable i

	SetDataFolder $kDFCal
	if (exists("KLMmolecules") == 1)
		rename KLMmolecules TankMols
	endif
	Wave /T mols = TankMols
	String Cals = ReplaceString("TankList;", WaveList("*",";",""), "")
	String tank
	
	DoWindow /K $win
	Edit /K=1/W=(5,44,866,456) mols as "All Cal Cylinders"
	DoWindow /C $win

	for ( i=0; i<ItemsInList(Cals); i+=1 )
		tank = StringFromList(i, Cals)
		AppendToTable $tank
	endfor
	ModifyTable format(Point)=1,width(Point)=38,style(TankMols)=1
	
	SetDataFolder root:
	
end

function WriteExchangeFiles()

	string flights = ReturnSelectedFlights()
	variable i
	
	if ( ItemsInList(flights) == 0 )
		abort "Select at least one flight to create and exchange file."
	endif
	
	for ( i=0; i<ItemsInList(flights); i+=1 )
		WriteAnExchangeFile( StringFromList(i, flights) )
	endfor
end

function WriteAnExchangeFile( fltdate )
	string fltdate

	STRUCT XC_struct xcs
	GetXCstructure(xcs)
	
	Wave tsecs = $"tsecs_" + fltdate

	string file, orgfltdate, txt1="", txt2="", mol 
	variable len, NumMols = ItemsInList(xcs.xcMolLst)
	variable i, m, comloc, FH, molrow, sig
	
	// make temporary wave to save resp types
	Make /O/T/N=(NumMols) resps
	for (m=0; m<NumMols; m+=1 )
		mol = StringFromList(m, xcs.xcMolLst)
		resps[m] = ReturnRespType( mol )
	endfor
	
	PathInfo ExchangeFilePath
	if (V_flag == 0)
		NewPath /M="Where would you like to save the exchange files?" ExchangeFilePath
	endif
	if (V_flag != 0)
		return -1
	endif
	
	// find last line in comment wave...
	for ( i=numpnts(xcs.comments); i>0; i-=1 )
		if ( strlen(xcs.comments[i]) > 0 )
			comloc = i+1
			break
		endif
	endfor

	// quick and dirty Y2K fix
	orgfltdate = fltdate
	if ( strlen(fltdate) == 6 )
		fltdate = "20" + fltdate
	endif

	file = xcs.xcPrefix + fltdate + xcs.xcSuffix
	len = 12 + 2*NumMols + comloc + 3		// length of 1001 header
	
	Close /A
	Open /C="R*ch" /P=ExchangeFilePath FH file
	
	fprintf FH, "%d 1001\r", len
	fprintf FH, xcs.participants + "\r"
	fprintf FH, xcs.affiliation + "\r"
	fprintf FH, xcs.instrument + "\r"
	fprintf FH, xcs.mission + "\r"
	fprintf FH, "1 1\r"
	fprintf FH, "%s %s %s   ", fltdate[0,3], fltdate[4,5], fltdate[6,7]
	fprintf FH, "%s %s %s\r", StringFromList(2, Secs2Date(DateTime,-1), "/")[0,3], StringFromList(1, Secs2Date(DateTime,-1), "/"), StringFromList(0, Secs2Date(DateTime,-1), "/")
	fprintf FH, "0 \r"
	fprintf FH, "ELAPSED TIME IN SECONDS FROM 00:00:00  GMT ON SAMPLE DATE\r"
	fprintf FH,  num2str(NumMols*2) + "\r"
	
	// scale factor and missing data lines
	// scale factor hard coded to 1.0
	for ( i=0; i<NumMols; i+=1 )
		txt1 += "1.0 1.0 "
		txt2 += num2str(kMissingConc) + " " + num2str(kMissingPrec) + " "
	endfor
	fprintf FH, txt1 + "\r"
	fprintf FH, txt2 + "\r"

	// write descriptive 1001 variable names
	for ( i=0; i<NumMols; i+=1 )
		mol = StringFromList(i, xcs.xcMolLst)
		molrow = XC_ReturnMolRow( mol )
		txt1 = xcs.fullmols[molrow]
		if (xcs.useDMF)
			fprintf FH, "%-18s DRY MOLE FRACTION MIXING RATIO  (%s)\r", txt1, upperstr(xcs.units[molrow])
		else
			fprintf FH, "%-18s MIXING RATIO  (%s)\r", txt1, upperstr(xcs.units[molrow])
		endif
		fprintf FH, "%-18s ERROR 1-s     (%s)\r", txt1, upperstr(xcs.units[molrow])
	endfor	
	
	// The comment lines
	fprintf FH, num2str(comloc) + "\r"
	for ( i=0; i<comloc; i+=1 )
		txt1 = xcs.comments[i]
		fprintf FH, "%s\r", txt1
	endfor
	
	// data header 
	txt1 = "GMTs_PM "
	for ( i=0; i<NumMols; i+=1 )
	// modified by fred for Wolfsy formatt.  Basicaly changing the Molequle header names from that in the database.
		mol = StringFromList(i, xcs.xcMolLst)
	//	mol = StringFromList(i, xcs.xcMolLst_Wolfsy)
		txt1 += mol + " " + mol + "e "
	//     txt1 += mol + "_PM " + mol + "e_PM "
	endfor
	fprintf FH, "1\r%s\r", txt1
	
	// Make data matrix 
	MakeFlightDataMatrix( tsecs, NumMols, orgfltdate )
	Wave FlightDataMatrix, FlightDataMatrixAvgs
	
	// write data
	for ( i=0; i<numpnts(tsecs); i+=1 )
		if ( numtype(FlightDataMatrixAvgs[i]) == 0 )
			fprintf FH, "%06d ", tsecs[i]
			for ( m=0; m<NumMols; m+=1 )
				mol = StringFromList(m, xcs.xcMolLst)
				sig = xcs.sigfigs[XC_ReturnMolRow(mol)]
				if (FlightDataMatrix[i][2*m] == kMissingConc )
					fprintf FH, "%d %d ",  kMissingConc, kMissingPrec
				else
					sprintf txt1, "0.%d", sig
					txt1 = "%" + txt1 + "f"
					txt2 = txt1 + " " + txt1 + " "
					fprintf FH, txt2,  FlightDataMatrix[i][2*m], FlightDataMatrix[i][2*m+1]
				endif
			endfor
			fprintf FH, "\r"
		endif
			
	endfor
	
	Close FH
	
	Killwaves resps, FlightDataMatrix, FlightDataMatrixAvgs
end

// creates a data matrix of all the conc and prec data that will be writen to the exchange file
function MakeFlightDataMatrix( tsecs, NumMols, fltdate )
	wave tsecs
	variable NumMols
	string fltdate

	STRUCT XC_struct xcs
	GetXCstructure(xcs)

	variable i, m
	string mol
	Wave /T resps
	Variable PANTHER = 0
	if ( GrepString(xcs.Instrument, "PANTHER") == 1 )
		PANTHER = 1
	endif
	
	// combine all conc and prec data into a matrix
	Make /O/N=(numpnts(tsecs), NumMols*2) FlightDataMatrix = NaN
	for ( m=0; m<NumMols; m+=1 )
		mol = StringFromList(m, xcs.xcMolLst)
		if (xcs.useDMF)
			if ( exists(mol + "_" + resps[m] + "_concDMF_" + fltdate) == 0 )
				Make /O/n=(numpnts(tsecs)) $(mol + "_" + resps[m] + "_concDMF_" + fltdate) = NaN, $(mol + "_" + resps[m] + "_prec_" + fltdate) = NaN
			endif
			Wave conc = $mol + "_" + resps[m] + "_concDMF_" + fltdate
		else
			if ( exists(mol + "_" + resps[m] + "_conc_" + fltdate) == 0 )
				Make /n=(numpnts(tsecs)) $(mol + "_" + resps[m] + "_conc_" + fltdate) = NaN, $(mol + "_" + resps[m] + "_prec_" + fltdate) = NaN
			endif
			Wave conc = $mol + "_" + resps[m] + "_conc_" + fltdate
		endif
		Wave prec = $mol + "_" + resps[m] + "_prec_" + fltdate

		// If PANTHER make sure only the selpos 1 and 11 are exported
		if ( PANTHER )
			for (i=0; i<numpnts(conc); i+=1 )
				if ( cmpstr(mol, "PAN") == 0 )
					Wave selpos = $"selposPAN_" + fltdate
				else
					Wave selpos = $"selpos_" + fltdate
				endif				
				if (( selpos[i] == 1 ) || ( selpos[i] == 11 ))
					FlightDataMatrix[i][2*m] = conc[i]
					FlightDataMatrix[i][2*m+1] = prec[i]
				endif
			endfor
		else
			FlightDataMatrix[][2*m] = conc[p]
			FlightDataMatrix[][2*m+1] = prec[p]
		endif

	endfor
	
	Make /O/N=(numpnts(tsecs)) FlightDataMatrixAvgs
	Make /O/N=(NumMols*2) TTT
	
	// make a 1D wave that has a number or a nan, nan means no data for all mols
	for ( i=0; i<numpnts(tsecs); i+=1 )
		TTT = FlightDataMatrix[i][p]
		WaveStats/Q/M=1 TTT
		FlightDataMatrixAvgs[i] = V_avg		// will be NAN if all cells in a row are NaN
	endfor
	Killwaves TTT
	
	// fill in missing values
	for ( i=0; i<numpnts(tsecs); i+=1 )
		if ( numtype(FlightDataMatrixAvgs[i]) == 0 )
			// missing data for conc wave
			for ( m=0; m<NumMols*2; m+=2 )
				if ( numtype(FlightDataMatrix[i][m]) != 0 )
					FlightDataMatrix[i][m] = kMissingConc
				endif
			endfor
			// missing data for prec wave
			for ( m=1; m<NumMols*2; m+=2 )
				if ( numtype(FlightDataMatrix[i][m]) != 0 )
					FlightDataMatrix[i][m] = kMissingPrec
				endif
			endfor
		endif
	endfor
		
end

function XC_ReturnMolRow( mol )
	string mol

	STRUCT XC_struct xcs
	GetXCstructure(xcs)

	variable i

	for ( i=0; i<numpnts(xcs.shortmols); i+=1 )
		if ( cmpstr(mol, xcs.shortmols[i]) == 0 )
			return i
		endif	
	endfor
	
	return -1	
end

function XC_ReturnSigFig( mol )
	string mol

	STRUCT XC_struct xcs
	GetXCstructure(xcs)

	variable i

	for ( i=0; i<numpnts(xcs.shortmols); i+=1 )
		if ( cmpstr(mol, xcs.shortmols[i]) == 0 )
			return xcs.sigfigs[i]
		endif	
	endfor
	
	return 2
end


function MakeStationery()

	DoAlert 1, "Delete all data and create an Igor stationery?"
	if (V_flag == 2)
		return -1
	endif
	
	// close everything
	variable i
	string win, wins = WinList("*", ";", "VISIBLE:1")
	for (i=0; i<ItemsInList(wins); i+=1 )
		win = StringFromList(i, wins)
		if ( strsearch(win, ".i", 0)  == -1 )
			DoWindow /K $win
		endif
	endfor
	
	NewDataFolder /O Sta
	MoveWave Molecules root:Sta:
	MoveWave MoleculesSel root:Sta:
	Killwaves /A/Z
	MoveWave root:Sta:Molecules root:
	MoveWave root:Sta:MoleculesSel root:
	KillDataFolder root:Sta

	Make /o/n=0  FlightsSel
	Make /o/T/n=0  Flights

	KillDataFolder /Z $kDFTmp
	KillDataFolder /Z $kDFDB
	
	NewDataFolder /O/S $kDFCM
	SetDataFolder $kDFCM
	SetWaveLock 0, allinCDF
	SetDataFolder root:
	KillDataFolder $kDFCM
	
	Killvariables /A/Z
	Killstrings /A/Z
	String /G S_flightLst, S_molLst
	SVAR molLst = S_molLst
	molLst = WaveToList("Molecules", ";")
	
	// delete ICARTT data
	SetDataFolder root:ICARTT:UCATS_O3
	Killwaves /Z Start_UTC, Stop_UTC, O3_UO3, O3e_UO3
	SetDataFolder root:ICARTT:UCATS_H2O
	Killwaves /Z Start_UTC,Stop_UTC,H2O_UWV,H2Oe_UWV
	SetDataFolder root:ICARTT:UCATS_GC
	Killwaves /Z Start_UTC,Stop_UTC,N2O,N2Oe,SF6,SF6e,CH4,CH4e,H2,H2e,CO,COe 
	SetDatafolder root:
	
	KillPath/A/Z
	
	execute "ppp()"
	
	DoAlert 1, "Do you want to save this experiment as an Igor stationary?"
	if ( V_flag == 1)
		DoIgorMenu "File", "Save Experiment As"
	endif

end