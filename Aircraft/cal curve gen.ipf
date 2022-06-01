#pragma rtGlobals=1		// Use modern global access method.

menu  "macros"
	"Cal Curve Panel /1", /Q
	"-"
	"Update Grav Waves", MakeGravWaves()
	"Display A Cal Curve"
	"-"
	
end


// DataFolder paths
Strconstant kDFCals = "root:CalCylinders"
Strconstant kDFCM = "root:CalMatrix"
Strconstant kDFTmp = "root:Tmp"
Strconstant kDFpan = "root:panel"

Proc InitGlobals ()

	string /G S_molLst = "F11;F113;CHCl3;MC;CT;N2O;SF6;F12;H1211;H2;CH4"

	StrMakeOrDefault("root:S_CalDate","YYMMDD")
	StrMakeOrDefault("root:S_CalDates","")
	StrMakeOrDefault("root:S_mol","F11")
	
	Make /n=0/T CalDates
	
	// panel variables and waves
	NewDataFolder /O/S $kDFpan
	StrMakeOrDefault("S_driftMethods", "divide by mean;linear;poly 3;poly 4;poly 5;poly 6;poly 7;poly 8")
	StrMakeOrDefault("S_calcurveMethods", "linear;poly 3;poly 4;poly 3 (forced 0);poly 3 (forced 1);poly 4 (forced 0);poly 4 (forced 1)")
	MakeTextWaveFromList(S_driftMethods, "DriftMethods", ";")
	MakeTextWaveFromList(S_calcurveMethods, "CalCurveMethods", ";")
	MakeTextWaveFromList(root:S_molLst, "Molecules", ";")
	String /G S_SelposCyls = ""
	
	if (exists("selposAssignment") == 0 )
		Make /o/n=12 selposAssignment = p+1
		Make /o/t/n=12 selposCyls = ""
		SetWaveLock 1, selposAssignment
	endif

	SetDataFolder root:
	
	NewDataFolder /O $kDFCM
	NewDataFolder /O $kDFTmp
	
	NewDataFolder /O/S $kDFCals
	string /G S_KLMlst
	MakeCalTanksWave()
	
end


// Makes a text wave of all of the ALM and KLM waves listed in the cal cylinder folder
// also updates the string S_KLMlst
function/S MakeCalTanksWave()

	SetDataFolder $kDFCals
	
	// rename from old nameing scheme
	if ( exists("KLMlist") == 1 )
		SetWaveLock 0, KLMlist
		rename KLMlist TankList
	endif
	
	SVAR KLMlst = S_KLMlst
	
	string cals = wavelist("*", ";", "")
	cals = ReplaceString("TankMols;", cals, "")
	cals = ReplaceString("TankList;", cals, "")
	cals = SortList(cals)
	variable n = ItemsInList(cals)
	
	if (exists("TankList") == 1)
		SetWaveLock 0, TankList
	endif
	MakeTextWaveFromList(cals, "TankList", ";")
	SetWaveLock 1, TankList
	
	KLMlst = cals
	
	SetDataFolder root:
	
	return KLMlst

end

Window MolTable() : Table
	PauseUpdate; Silent 1		// building window...
	
	string win = "MoleculeTable"
	
	SetDataFolder $kDFpan
	
	DoWindow /K $win
	Edit/K=1/W=(5,44,223,395) Molecules as "Molecules"
	ModifyTable format(Point)=1,font(Molecules)="Arial",size(Molecules)=12,width(Molecules)=101,style=1
	DoWindow /C $win
	
	SetWindow $win,hook(MolTable)= UpdateTableHooks
	
	SetDataFolder root:

EndMacro

// Updates the S_molLst string with the Molecules wave
// also creats the _pansel waves used for saving norm meth and cal curve meth
Function MakeMolLst()
	
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:
	SVAR mollst = root:S_molLst
	Wave /T caldates = root:Caldates
	variable i
	string mol, pansel

	mollst = WaveToList(kDFpan+":Molecules", ";")
	wave molwv = $kDFpan+":Molecules"
	
	SetDataFolder $kDFpan
	for( i=0; i<numpnts(molwv); i+=1 )
		mol = StringFromList(i, mollst)
		pansel = mol + "_pansel"
		if (exists(pansel) == 0)
			Make/N=(1, 2) $pansel = 0
			wave pn = $pansel
			pn[0][0] = 2		// set some default values (2= poly 3 for norm)
			pn[0][1] = 1		// 1 = poly 3 for cal curve
		endif
	endfor
	
	// delete unused _pansel waves
	string lst = wavelist("*_pansel", ";", "")
	for( i=0; i<ItemsInList(lst); i+=1 )
		pansel = StringFromList(i, lst)
		mol = StringFromList(0, pansel, "_")
		if (FindListItem(mol, mollst) == -1 )
			killwaves /Z $pansel
		endif	
	endfor

	SetDataFolder fldrSav
end

function UpdateTableHooks(s )
	STRUCT WMWinHookStruct &s	
	
	if (cmpstr(s.winName, "MoleculeTable") == 0 )
		if (( cmpstr(s.eventName, "deactivate") == 0 ) || ( cmpstr(s.eventName, "kill") == 0 ))
			MakeMolLst()
		endif
	elseif (cmpstr(s.winName, "SelposAssignTable") == 0 )
		if (( cmpstr(s.eventName, "deactivate") == 0 ) || ( cmpstr(s.eventName, "kill") == 0 ))
			SetDataFolder $kDFpan 
			string /G S_SelposCyls = ReturnSelposCylLst()
			string /G S_NormCyl = StringFromList(0, S_SelposCyls)
			SetDataFolder root:
			PopupMenu NormCyl, popvalue=S_NormCyl, mode=1
		endif
	elseif (cmpstr(s.winName, "AllCalCyls") == 0 )
		if (( cmpstr(s.eventName, "deactivate") == 0 ) || ( cmpstr(s.eventName, "kill") == 0 ))
			MakeCalTanksWave()
		endif
	endif

	
end

Window SelposAssigns() : Table
	PauseUpdate; Silent 1		// building window...
	string win = "SelposAssignTable"
	DoWindow /K $win
	MakeCalTanksWave()
	string KLM = ":"+kDFCals+":TankList"
	SetDataFolder $kDFPan
	Edit/K=1/W=(21,59,443,514) selposAssignment,selposCyls as "Selpos Assignments"
	SetDataFolder $kDFCals
	AppendtoTable TankList
	SetWaveLock 1, TankList
	ModifyTable style(TankList)=1,width(TankList)=130,rgb(TankList)=(65535,16385,16385)
	SetDataFolder $kDFPan
	ModifyTable format(Point)=1,style(selposAssignment)=1,width(selposAssignment)=46
	ModifyTable style(selposCyls)=1,width(selposCyls)=130,rgb(selposCyls)=(2,39321,1)
	DoWindow /C $win

	SetWaveLock 1, selposAssignment,
	SetWindow $win,hook(SelposTable)= UpdateTableHooks

EndMacro

Function/S ReturnSelposCylLst()
	Wave/T selposCyls =  $kDFpan + ":selposCyls"

	variable i
	string itm, lst=""
	for( i=0; i<numpnts(selposCyls); i+=1 )
		itm = ReplaceString(" ", selposCyls[i], "")
		if ( strlen(itm) > 0 )
			lst += itm + ";"
		endif
	endfor
	
	return lst
end

// loads _resp, selpos and tsecs waves from integrator
Function LoadIntegrationResults()
	
	SVAR molLst = root:S_molLst

	string mol="ALL MOLS"
	string type=StrMakeOrDefault("root:S_RespType", "_resp")
	prompt mol,"molecule", popup, "ALL MOLS;" + molLst
	prompt type, "Response wave names", popup, "_resp;_respArea;_respHght"
	
	DoPrompt "Loading Integration Results", mol, type
	if (V_flag)
		return -1
	endif
	
	SVAR S_mol = root:S_mol
	S_mol = mol
	
	StrMakeOrDefault("root:S_CalDates", "")
	SVAR CalDates = root:S_CalDates
	
	variable i
	string respStr, flagStr, tmpMol
	
	// Find integration experiment
	Open /R/D/T=".pxp" /M="Locate Integration Experiment"  K0
	String expName = S_filename
	if ( strlen(expName) == 0 )
		abort "Aborted LoadIntegrationResults()"
	endif
	
	// load config text wave from integrator to use the date.
	// load DB_mols to list of molecules in integrator
	NewDataFolder /O/S $kDFTmp
	LoadData/Q/O/L=1/J="config" expName
	LoadData/Q/O/L=1/S="DB"/J="DB_mols" expName
	String IntMolLst = WaveToList("DB_mols", ";")
	Wave /t config 
	SetDataFolder root:
	
	String /G S_CalDate = config[4]
//	String /G S_Instrument = config[1]		// if needed?

	// Load selpos and resp data then rename
	if ( cmpstr(mol, "ALL MOLS") == 0 )
		for( i=0; i<ItemsInList(molLst); i+=1 )
			tmpMol = StringFromList(i, molLst)
			if ( FindListItem(tmpMol, IntMolLst, ";", 0, 0) != -1 )		// is the mol in the integration exp?
				respStr = tmpMol + type
				flagStr = tmpMol + "_flagBad"
				LoadData/Q/O/L=1/J=respStr expName
				LoadData/Q/O/L=1/J=flagStr expName
				Wave resp = $respStr
				Wave flag = $flagStr
				infReplace(resp)
				gReplace(flag, 1, NaN)
				gReplace(flag, 0, 1)
				resp *= flag
				Duplicate /O resp, $respStr + "_" + S_CalDate
				Killwaves resp, flag
				print tmpMol + " loaded from " + expName
			else
				print tmpMol + " is not in " + expName + " experiment!"
			endif
		endfor
		LoadData/Q/O/L=1/J="selpos" expName
		LoadData/Q/O/L=1/J="tsecs" expName
		Wave selpos, tsecs
		Duplicate /O selpos, $"selpos_" + S_CalDate
		Duplicate /O tsecs, $"tsecs_" + S_CalDate
		Killwaves selpos, tsecs
	else
		if ( FindListItem(mol, IntMolLst, ";", 0, 0) != -1 )
			respStr = mol + type
			flagStr = mol + "_flagBad"
			LoadData/O/L=1/J=respStr expName
			LoadData/O/L=1/J=flagStr expName
			LoadData/Q/O/L=1/J="selpos" expName
			LoadData/Q/O/L=1/J="tsecs" expName
			Wave resp = $respStr
			Wave selpos, tsecs
			Wave flag = $flagStr
			infReplace(resp)
			gReplace(flag, 1, NaN)
			gReplace(flag, 0, 1)
			resp *= flag
			Duplicate /O resp, $respStr + "_" + S_CalDate
			Duplicate /O selpos, $"selpos_" + S_CalDate
			Duplicate /O tsecs, $"tsecs_" + S_CalDate
			Killwaves selpos, resp, tsecs, flag
			print mol + " loaded from " + expName
		else
			print mol + " is not in " + expName + " experiment!"
			return -1
		endif
	endif

	// add cal date to S_CalDates string
	if ( WhichListItem(S_CalDate, CalDates) == -1 )
		CalDates = SortList(AddListItem(S_CalDate, CalDates))
	endif
	MakeTextWaveFromList(CalDates, "CalDates", ";")
	
	MakeGravWaves( caldate=S_CalDate )
	
	if ( cmpstr(mol, "ALL MOLS") == 0 )
		S_mol = StringFromList(0, molLst)
		wave PS = $kDFpan + ":" + S_mol + "_pansel"
		ListBox MolLst,selRow= 0
		ListBox DriftMethods,selRow= PS[ReturnCalDateRow()][0]
		ListBox CalCurveMethod,selRow= PS[ReturnCalDateRow()][1]
	endif
	
	ListBox  CalDates,listWave=root:CalDates,mode= 1,selRow= Return_CalDateRow()

	Killwaves config

end

// makes all grave waves for a given date.
function MakeGravWaves([caldate])
	string  caldate
	
	SVAR S_CalDate = root:S_CalDate
	SVAR CalDates = root:S_CalDates
	
	if ( ParamIsDefault(caldate) )
		caldate = S_CalDate
		Prompt caldate, "Make grav waves for which date?", popup, CalDates
		DoPrompt "Making grav waves", caldate
		if (V_flag)
			return -1
		endif
		S_CalDate = caldate
	endif
	
	String resps = Wavelist("*resp*_*", ";", "")
	Wave selpos = $"selpos_" + caldate
	Variable i, j
	String tank
		
	// increment over all resp waves found
	for( i=0; i<ItemsInList(resps); i+=1 )
		String rr = StringFromList(i, resps)
		String mol = StringFromList(0, rr, "_")
		String gg = mol + "_grav_" + caldate
		make /o/n=(numpnts(selpos)) $gg = NaN
		Wave resp = $rr
		Wave grav = $gg
		for( j=0; j<numpnts(selpos); j+=1 )
			tank = ReturnSelposCylinder(selpos[j])
			grav[j] = ReturnCalValue(mol, tank)
		endfor
	endfor

end

// returns the tank assigned to a given selpos position
Function /T ReturnSelposCylinder(selpos)
	variable selpos

	Wave SSVassn = $kDFpan + ":selposAssignment"
	Wave /T SSVcyls =  $kDFpan + ":selposCyls"
	Variable i

	for( i=0; i<numpnts(SSVassn); i+=1 )
		if ( SSVassn[i] == selpos )
			return SSVcyls[i]
		endif		
	endfor	

	return ""

end

// returns a list of selpos assignments for a cylinder
Function/T ReturnCylinderSelposLst(cyl)
	string cyl

	Wave SSVassn = $kDFpan + ":selposAssignment"
	Wave /T SSVcyls =  $kDFpan + ":selposCyls"
	Variable i
	String lst = ""

	for( i=0; i<numpnts(SSVassn); i+=1 )
		if ( cmpstr(cyl, SSVcyls[i]) == 0 )
			lst += Num2Str(SSVassn[i]) + ";"
		endif
	endfor

	return lst

end

// returns the assigned cal tank value for a given tank
Function ReturnCalValue(mol, tank)
	string mol, tank
	
	SVAR tanklst = $kDFCals + ":S_KLMlst"
	
	// blank
	if ( StrLen(tank) == 0 )
		return NaN
	endif
	
	if ( WhichListItem(tank, tanklst) == -1 )
		Abort "Bad cal tank name: " + tank
	endif
	
	Wave /T KLMmols = $kDFCals + ":TankMols"
	Wave KLM = $kDFCals + ":" + tank
	Variable i
	
	for( i=0; i<numpnts(KLMmols); i+=1 )
		if ( cmpstr(KLMmols[i], mol) == 0 )
			return KLM[i]
		endif
	endfor

	return NaN	
	
end

// replaces infinaties with NaN
function infReplace(wv)
	wave wv
	wv = SelectNumber(numtype(wv) == 1, wv[p], Nan)
end

function DisplayACalCurve()

	SVAR /Z unit = root:S_unit

	string CM
	Variable NewAppend = 1
	String TopGraph = StringFromList(0, WinList("*", ";", "WIN:1"))
	if ( GrepString(TopGraph, "CalCurves") )
		NewAppend = 2
	endif
	
	NewDataFolder /S/O $kDFCM
	prompt CM, "Cal Matrix Name", popup, SortList(Wavelist("*_CM_*", ";", ""))
	prompt NewAppend, "New plot or append to top plot", popup, "New;Append"
	if ( NewAppend == 1 )
		DoPrompt "Display Calibration Curves", CM
	else
		DoPrompt "Display Calibration Curves", CM, NewAppend
	endif
	if (V_Flag)
		return -1								// User canceled
	endif

	Wave CMwv = $CM
	SetDataFolder root:
	
	Variable i
	String mol = CM[0, strsearch(CM, "_CM_", 0)-1]
	String NT = note(CMwv)
	String curve = StringByKey("FIT", NT)
	String NCyl = StringByKey("NCYL", NT)
	String Cday = StringByKey("CDAY", NT)
	Variable err = NumberByKey("ERR", NT)
	Variable pts = NumberByKey("PTS", NT)
	Variable RLO = NumberByKey("RLO", NT)
	Variable RHI = NumberByKey("RHI", NT)

	String Norm = mol + "_norm_" + Cday
	String Grav = mol + "_grav_" + Cday
	
	string fitstr = "calcv_" + mol + "_" + curve + "_" + Cday
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
	Make /n=200/o $fitstr
	wave fit = $fitstr
	SetScale/I x RLO,RHI,"", fit
	
	// fill in cal_coef wave
	for ( i=0; i<DimSize(CMwv, 0); i+=1 )
		cal_coef[i] = CMwv[i][0]
	endfor
	
	if ( cmpstr(curve, "line") == 0 )
		fit = cal_coef[0] + cal_coef[1] * x
	elseif ( GrepString(curve, "poly3frc") )
		fit = poly3_force(cal_coef, x)
	elseif ( GrepString(curve, "poly4frc") )
		fit = poly4_force(cal_coef, x)
	elseif ( GrepString(curve, "poly") )
		fit = poly(cal_coef, x) 
	endif
	
	// make display
	if ( NewAppend == 1)		// new plot
		Display /K=1 fit as title
		DoWindow /C $win
		ModifyGraph grid=1,mirror=2
		Label left "Norm. Response"
		Label bottom FullMolName(mol) + " (" + unit + ")"
		Legend/C/N=legd /X=40.51/Y=1.91
		AutoPositionWindow /M=1
	else
		ChooseColor
		DoWindow /F $win
		AppendToGraph fit
		ModifyGraph rgb($fitstr)=(V_Red, V_Green, V_Blue)
	endif
	
	DoWindow /F $win
	if (! GrepString(TraceNameList("", ";", 1), norm))
		AppendToGraph $"root:"+norm vs $"root:"+grav
		ModifyGraph mode($norm)=3,marker($norm)=8
		ModifyGraph msize($norm)=2,rgb($norm)=(0,0,0)
	endif
	
	Killwaves cal_coef
	
	SetDataFolder root:
	
end


// displays all cal cylinders in the Cal cylinder folder
function ViewCalCylinders()

	String win = "AllCalCyls"
	variable i
	
	MakeCalTanksWave()
	
	SetDataFolder $kDFCals
	SVAR Cals = S_KLMlst
	
	// renames KLMmol.. from old nameing scheme
	if ( exists("KLMmolecules") == 1 )
		rename KLMmolecules TankMols
		Cals = ReplaceString("KLMmolecules;", Cals, "")
	endif
	Wave /T mols = TankMols
	string tank
	
	DoWindow /K $win
	Edit /K=1/W=(5,44,866,456) mols as "All Cal Cylinders"
	DoWindow /C $win

	for ( i=0; i<ItemsInList(Cals); i+=1 )
		tank = StringFromList(i, Cals)
		AppendToTable $tank
	endfor
	ModifyTable format(Point)=1,width(Point)=38,style(TankMols)=1
	
	SetDataFolder root:
	
	SetWindow $win,hook(KLMtable)= UpdateTableHooks

end

function AddCalCylinder()

	string tank = "ALM07000"
	Prompt tank, "Tank name"
	DoPrompt "Enter a new cal cylinder", tank
	if (V_flag)
		return -1
	endif
	String win = "AddCalCyl"

	SetDataFolder $kDFCals
	SVAR Cals = S_KLMlst
	Wave /T mols = TankMols

	if (strlen(GrepList(Cals, tank)) > 0)
		abort "Tank " + tank + " already in CalCylinders data folder!"
	endif
	
	Make /N=(numpnts(mols)) $tank = Nan
	
	DoWindow /K $win
	Edit/K=1/W=(5,44,267,429) mols as "Adding Tank " +tank
	DoWindow /C $win
	AppendToTable $tank	
	ModifyTable format(Point)=1,width(Point)=38,style(TankMols)=1
	
	SetDataFolder root:
	
	MakeCalTanksWave()

end

function DelCalCylinder()

	SetDataFolder $kDFCals
	SVAR Cals = S_KLMlst
	Wave /T mols = TankMols
	
	string tank 
	Prompt tank, "Tank name", popup, Cals
	DoPrompt "Deleting cal cylinder from database", tank
	if (V_flag)
		SetDataFolder root:
		return -1
	endif
	DoAlert 1, "Delete " + Tank + " from experiment?"
	if (V_flag == 2)
		SetDataFolder root:
		abort "Delete Aboarted!!"
	endif
	
	DoWindow /K AllCalCyls
	Killwaves $tank
	print Tank + " tank deleted from cal tank database."

	SetDataFolder root:
	
	MakeCalTanksWave()

end


/// NOT DONE YET
function UpdateCalWaves()

	SetDataFolder $kDFCals
	
	SVAR Cals = S_KLMlst
	Wave /T mols = TankMols
	string tankStr

	tankStr = StringFromList(1, Cals)
	wave tank = $kDFCals + ":" + tankStr
	
	if (numpnts(mols) > numpnts(tank))
		print "bigger", numpnts(mols), numpnts(tank), tankStr
	endif
	
	SetDataFolder root:

end

Function ReturnCalDateRow()
		
	SVAR CalDate = root:S_CalDate
	
	Wave /T CalDates = root:CalDates
	
	variable i
	for ( i=0; i<numpnts(CalDates); i+=1 )
		if ( cmpstr(CalDate, CalDates[i]) == 0 )
			return i
		endif
	endfor
	return 0
end

Function /T ReturnCurveMethod( mol )
	string mol
	
	if ( strlen(mol) == 0 )
		return ""
	endif

	Wave pansel = $kDFpan + ":" + mol + "_pansel"
	Variable CurvMeth = pansel[ReturnCalDateRow()][1]
	String curve
	
	Switch ( CurvMeth )
		case 0:		//line
			curve = "line"
			break
		case 1:		// poly 3
			curve = "poly3"
			break
		case 2: 		// poly 4
			curve = "poly4"
			break
		case 3: 		// poly 3 (constrained at zero)
			curve = "poly3frc0"
			break
		case 4: 		// poly 3 (constrained at 1)
			curve = "poly3frc1"
			break
		case 5: 		// poly 4 (constrained at zero)
			curve = "poly4frc0"
			break
		case 6: 		// poly 4 (constrained at 1)
			curve = "poly4frc1"
			break
			
	EndSwitch
	
	return curve

end

function NormalizeData()

	SVAR DAY = root:S_CalDate
	SVAR mol = root:S_mol
	SVAR NCyl = root:S_NormCyl
	
	SetDatafolder root:
	
	Wave pansel = $kDFpan + ":" + mol + "_pansel"
	
	String NselposLst = ReturnCylinderSelposLst(NCyl), sel
	Variable NormMeth = pansel[ReturnCalDateRow()][0]
	Variable i
	
	String winNorm1 = mol + "NormCyl" + DAY
	String winNorm2 = mol + "Norm" + DAY

	// find the correct _resp or _respArea or _respHght wave	
	string molwvstr = StringFromList(0, wavelist(mol + "_resp*" + DAY, ";", ""))
	Wave molWv = $molwvstr
	Wave selpos = $"selpos_" + DAY
	Wave tsecs = $"tsecs_" + DAY
	
	// make Norm wave
	String NormStr = mol + "_norm_" + DAY
	Duplicate /o molWv, $NormStr
	Wave NormWv = $NormStr	
	
	// extract data for selpos to normalize to
	String OneSelRespSTR = mol + "_NormCyl_" + DAY
	String OneSelTsecsSTR = mol + "_NormCylT_" + DAY
	Make/O/N=(numpnts(molWv)) $OneSelRespSTR = NaN, $OneSelTsecsSTR = NaN
	Wave OneSelResp = $OneSelRespSTR
	Wave OneSelTsecs = $OneSelTsecsSTR
	for (i=0; i<numpnts(molWv); i+=1 )
		sel = num2str(selpos[i])
		if ( ( numtype(molwv[i]) == 0 ) && ( FindListItem(sel, NselposLst) > -1 ) )
			OneSelResp[i] = molWv[i]
			OneSelTsecs[i] = tsecs[i]
		endif
	endfor
	KillNaN(OneSelResp, OneSelTsecs)
		
	// normalizing fit plot
	DoWindow /K $winNorm1
	Display /K=1 /W=(23,44,418,330) OneSelResp vs OneSelTsecs as mol + " Normalized " + DAY + " selpos=" + NselposLst
	DoWindow /C $winNorm1
	Label left "Resp."
	Label bottom "Tsecs (s)"
	ModifyGraph mode=3,marker=16
	ModifyGraph grid=1,mirror=2
	
	// Nan out existing residual wave
	String ResSTR = "Res_" + OneSelRespSTR
	if (exists(ResSTR) == 1)
		Wave res = $ResStr
		res = Nan
	endif
	
	switch (NormMeth)
		case 0:  // divide by mean
			WaveStats /Q OneSelResp
			NormWv /= V_avg
			make /O/N=(numpnts(OneSelResp)) $("Res_" + OneSelRespSTR) = NaN
			Wave Ress = $"Res_" + OneSelRespSTR
			Ress = OneSelResp - V_avg
			AppendToGraph /L=Res_Left Ress vs OneSelTsecs
			ModifyGraph axisEnab(left)={0,0.75},axisEnab(Res_Left)={0.8,1}
			ModifyGraph mode=3
			ModifyGraph freePos(Res_Left)=0
			break
			
		case 1: // linear fit
			CurveFit/Q/X=1/NTHR=0 line  OneSelResp /X=OneSelTsecs /D /R
			Wave coef = W_coef
			NormWv /= coef[0] + coef[1]*tsecs
			break
			
		default:
			variable deg = NormMeth+1
			CurveFit/Q/X=1/NTHR=0 poly deg,  OneSelResp /X=OneSelTsecs /D /R 
			Wave coef = W_coef
			NormWv /= poly(coef, tsecs)
			break
	
	endswitch
	
	// Nan data before the first normcylinder selpos and after the last
	Extract /O/Indx NormWv, bound, (( FindListItem(num2str(selpos), NselposLst) > -1 ) && (numtype(molWv) == 0))
	if ( numpnts(bound) > 0 )
		NormWv[0,bound[0]-1] = NaN
		NormWv[bound[numpnts(bound)-1]+1, numpnts(NormWv)] = NaN
	endif
	Killwaves /Z bound
	
	ModifyGraph margin(top)=36
	ModifyGraph grid(Res_Left)=0
	ModifyGraph zero(Res_Left)=1
	ModifyGraph rgb($"Res_" + OneSelRespSTR)=(0,0,65535), marker($"Res_" + OneSelRespSTR) = 19
	string txt
	FullMolName(mol)
	SVAR unit = S_unit

	Wave res = $"Res_" + OneSelRespSTR
	Wavestats /Q res
	K0 = V_sdev	// save this
	Wavestats /Q OneSelResp

	K10 = K0/V_avg * 100
	sprintf txt, "Mean residual: %5.3f%s (%3.3f %s)", K10,  "%", ReturnCalValue(mol, NCyl)*K10/100, unit
	TextBox/C/N=meanres/F=0/A=MC/X=15/Y=59.62 txt
	Label Res_Left "Residual"
	ModifyGraph lblPosMode(Res_Left)=1
	
	// all normalized responses plot
	DoWindow /K $winNorm2
	Display /K=1 /W=(23,355,417,639) NormWv vs tsecs as mol + " Normalized Data: " + DAY
	DoWindow /C $winNorm2
	Label left "Norm. Resp."
	Label bottom "Tsecs (s)"
	ModifyGraph mode=3,marker=19,rgb=(0,0,65535)
	ModifyGraph grid=1,mirror=2
	ModifyGraph margin(top)=36
	ModifyGraph zColor($NormStr)={$"selpos_" + DAY,*,*,Rainbow,0}
	sprintf txt, "Norm Cylinder: \\f01%s\f00 \\Z09(%s = %5.2f)", NCyl, mol, ReturnCalValue(mol, NCyl)
	TextBox/C/N=NormCyl/F=0/A=MC/X=12/Y=60.19 txt
		
end

function FlaggingPlot()

	SVAR DAY = root:S_CalDate
	SVAR mol = root:S_mol
	
	// find the correct _resp or _respArea or _respHght wave	
	string molwvstr = StringFromList(0, wavelist(mol + "_resp*" + DAY, ";", ""))
	Wave molWv = $molwvstr
	String SelposSTR = "selpos_" + DAY
	Wave selpos = $SelposSTR
	Wave tsecs = $"tsecs_" + DAY
	String win = mol + "ResponsePlot"

	DoWindow /K $win
	Display /K=1/W=(14,81,760,504) molWv vs tsecs as mol + " Response on " + DAY
	DoWindow /C $win
	ModifyGraph margin(top)=50
	ModifyGraph mode=3
	ModifyGraph marker=19
	ModifyGraph rgb=(13107,13107,13107)
	ModifyGraph zColor($molwvstr)={$SelposSTR,*,*,Rainbow}
	ModifyGraph grid=1
	ModifyGraph mirror=2
	Label left "Response"
	Label bottom "Tsecs"
	TextBox/C/N=text0/F=0/A=MC/X=-0.96/Y=59.01 "\\Z14Use the \\f01NaNinMarquee\\f00 function to remove outliers."

end

function NaN_CalData () : GraphMarquee

	string wvlst = TraceNameList("", ";", 1)
	if ( ItemsInList(wvlst) > 1 )
		Prompt wvlst, "NaN point on which wave?", popup, wvlst
		DoPrompt "NaNStatsInMarquee wave choice", wvlst
		if (V_flag)
			return -1
		endif
	else
		wvlst = StringFromList(0, wvlst)
	endif

	variable i, pt
	variable NormCyl = 0
	// was function called on the normCyl plot?
	if ( GrepString(wvlst, "NormCyl") )
		NormCyl = 1
	endif
	
	string mol, DAY
	SplitString/E=("^(\w+)_\w+_(\d+)$") wvlst, mol, DAY
	if ( ( strlen(mol) < 1) || ( strlen(DAY) < 1 ) )
		abort "Should only Flag_CalData on resp or norm waves."
	endif
	
	wave wv = TraceNameToWaveRef("", wvlst)
	wave resp = $mol + "_resp_" + DAY
	wave norm = $mol + "_norm_" + DAY

	GetMarquee /K left, bottom
	
	// check for XY pairing
	if ( WaveExists(XWaveRefFromTrace("", wvlst)) )
		wave wvx = XWaveRefFromTrace("", wvlst)
		Extract /INDX/O wv, JunkY, ( (wvx > V_left) && (wvx < V_right) && (wv < V_top) && (wv > V_bottom) )
	else
		Extract /INDX/O wv, JunkY, ( (pnt2x(wv, p) > V_left) && (pnt2x(wv,p) < V_right) && (wv < V_top) && (wv > V_bottom) )
	endif

	if ( NormCyl )
		variable T, pt2
		Wave NormCylY = $mol + "_normCyl_" + DAY
		Wave NormCylX = $mol + "_normCylT_" + DAY
		Wave Tsecs = $"tsecs_" + DAY
		for ( i=0; i<numpnts(junkY); i+=1 )
			pt = junkY[i]		// find T in resp wave
			T = NormCylX[pt]
			pt2 = BinarySearch(Tsecs, T)
			NormCylY[pt] = NaN
			resp[pt2] = NaN
			norm[pt2] = NaN
		endfor
	else
		for ( i=0; i<numpnts(junkY); i+=1 )
			pt = junkY[i]
			resp[pt] = NaN
			norm[pt] = NaN
		endfor
	endif
	
//	killwaves /Z junkY
	
end


Function/S FullMolName(mol)
	string mol
	
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


Function CalCurve()

	SVAR DAY = root:S_CalDate
	SVAR mol = root:S_mol
	SVAR NCyl = root:S_NormCyl
	SVAR /Z unit = root:S_unit
	
	Wave pansel = $kDFpan + ":" + mol + "_pansel"
	Variable CurvMeth = pansel[ReturnCalDateRow()][1]
	
	String txt, curve, win = mol + "CalCurvePlot" + DAY
	String NormSTR = mol + "_norm_" + DAY
	String GravSTR = mol + "_grav_" + DAY
	String ResSTR = "Res_" + NormSTR
	
	DoWindow /K $win
	Display /K=1/W=(423,358,1122,720) $NormSTR vs $GravSTR as mol + " Calibration Curve"
	DoWindow /C $win
	SetAxis/A/N=1
	DoUpdate
	
	// Nan out existing residual wave
	if (exists(ResSTR) == 1)
		Wave res = $ResStr
		res = Nan
	endif
	
	Switch ( CurvMeth )
		case 0:		//line
			CurveFit/Q/X=1/M=2/NTHR=0/TBOX=792 line  $NormSTR  /X=$GravSTR  /D /R /F={0.950000, 1}
			Make /o/n=(2,2) M_covar = 0
			Wave /Z/D sigma = root:W_sigma
			M_covar[0][0] = sigma[0]^2
			M_covar[1][1] = sigma[1]^2
			curve = "line"
			break
			
		case 1:		// poly 3
			CurveFit/Q/X=1/M=2/NTHR=0/TBOX=792 poly 3,  $NormSTR  /X=$GravSTR  /D /R /F={0.950000, 1}
			curve = "poly3"
			break
			
		case 2: 		// poly 4
			CurveFit/Q/X=1/M=2/NTHR=0/TBOX=792 poly 4,  $NormSTR  /X=$GravSTR  /D /R /F={0.950000, 1}
			curve = "poly4"
			break
			
		case 3: 		// poly 3 (constrained at zero)
			SetAxis/A/E=1 left;	SetAxis/A/E=1 bottom
			DoUpdate
			CurveFit/Q/X=1/M=2/NTHR=0 poly 3,  $NormSTR  /X=$GravSTR
			wave coef = W_coef
			InsertPoints 3, 1, coef
			coef[0] = 0
			coef[3] = 0
			FuncFit/Q/X=1/H="1001"/M=2/NTHR=0/TBOX=792 Poly3_force coef  $NormSTR /X=$GravSTR  /D /R /F={0.950000, 1}
			curve = "poly3frc0"
			break
		
		case 4: 		// poly 3 (constrained at 1)
			SetAxis/A/E=1 left;	SetAxis/A/E=1 bottom
			DoUpdate
			CurveFit/Q/X=1/M=2/NTHR=0 poly 3,  $NormSTR  /X=$GravSTR
			wave coef = W_coef
			InsertPoints 3, 1, coef
			coef[0] = 1
			coef[3] = ReturnCalValue(mol, NCyl)
			FuncFit/Q/X=1/H="1001"/M=2/NTHR=0/TBOX=792 Poly3_force coef  $NormSTR /X=$GravSTR  /D /R /F={0.950000, 1}
			curve = "poly3frc1"
			break

		case 5: 		// poly 4 (constrained at zero)
			SetAxis/A/E=1 left;	SetAxis/A/E=1 bottom
			DoUpdate
			CurveFit/Q/X=1/M=2/NTHR=0 poly 4,  $NormSTR  /X=$GravSTR
			wave coef = W_coef
			InsertPoints 4, 1, coef
			coef[0] = 0
			coef[4] = 0
			FuncFit/Q/X=1/H="10001"/M=2/NTHR=0/TBOX=792 Poly4_force coef  $NormSTR /X=$GravSTR  /D /R /F={0.950000, 1}
			curve = "poly4frc0"
			break
		
		case 6: 		// poly 4 (constrained at 1)
			CurveFit/Q/X=1/M=2/NTHR=0 poly 4,  $NormSTR  /X=$GravSTR
			wave coef = W_coef
			InsertPoints 4, 1, coef
			coef[0] = 1
			coef[4] = ReturnCalValue(mol, NCyl)
			FuncFit/Q/X=1/H="10001"/M=2/NTHR=0/TBOX=792 Poly4_force coef  $NormSTR /X=$GravSTR  /D /R /F={0.950000, 1}
			curve = "poly4frc1"
			break
			
	EndSwitch
	Wave coef = root:W_coef
	Wave covar = root:M_covar
	
	String UCSTR = "UC_" + NormSTR
	String LCSTR = "LC_" + NormSTR
	String fitSTR = "fit_" + NormSTR
	String TexBox = "CF_" + NormSTR
	
	ModifyGraph margin(top)=43
	ModifyGraph mode($NormSTR)=3,mode($ResSTR)=3
	ModifyGraph marker($NormSTR)=19,marker($ResSTR)=19
	ModifyGraph lStyle($UCSTR)=1,lStyle($LCSTR)=1
	ModifyGraph rgb($NormSTR)=(2,39321,1),rgb($fitSTR)=(0,0,0)
	ModifyGraph rgb($ResSTR)=(0,0,65535)
	ModifyGraph grid(left)=1,grid(bottom)=1
	ModifyGraph zero(Res_Left)=1
	ModifyGraph mirror=2
	ModifyGraph lblPosMode(Res_Left)=1
	ModifyGraph lblPos(left)=58
	ModifyGraph freePos(Res_Left)=0
	ModifyGraph axisEnab(left)={0,0.75}
	ModifyGraph axisEnab(Res_Left)={0.8,1}
	Label left "Norm. Resp."
	Label bottom FullMolName(mol) + " Mixing Ratio (" + unit + ")"
	Label Res_Left "Residual"
	TextBox/C/N=$TexBox /X=54.24/Y=25.82
	Button CalMatrix,pos={74,7},size={127,23},proc=Cal_ButtonProc,title="Save Cal Matrix?"
	Button CalMatrix,fSize=12,fColor=(49163,65535,32768)
	ModifyGraph lowTrip(Res_Left)=0.01	
	ModifyGraph margin(left)=72
	
	// save the standard deviation of the residuals to a global variable in root:tmp
	// this variable is used if/when the cal matrix is saved.
	Wavestats /Q $ResSTR
	string varstr = kDFTmp + ":G_" + mol + "_" + curve + "_" + DAY + "_sdev"
	string coefstr = kDFTmp + ":W_" + mol + "_" + curve + "_" + DAY + "_coef"
	string covarstr = kDFTmp + ":M_" + mol + "_" + curve + "_" + DAY + "_covar"
	Variable /G $varstr
	NVAR Gsdev = $varstr
	Gsdev = V_sdev
	Duplicate /o coef, $coefstr
	Duplicate /o covar, $covarstr

	sprintf txt, "\\Z10%s Cal Curve: \\f01%s\\f00\rMean residual: %5.3f%s (%3.3f %s)", mol, DAY, V_sdev*100, "%", ReturnCalValue(mol, NCyl)*V_sdev, unit
	TextBox/C/N=comment/F=0/X=3.66/Y=-13.81 txt

	Killwaves M_covar
end

Function Poly3_force(w,x):fitfunc
	Wave w
	variable x
	return w[0] + w[1]*(x-w[3]) + w[2]*(x-w[3])^2
end

Function Poly4_force(w,x):fitfunc
	Wave w
	variable x
	return w[0] + w[1]*(x-w[4]) + w[2]*(x-w[4])^2 + w[3]*(x-w[4])^3
end

// saves a calibration curve matrix to the kDFCM Data folder
Function MakeCalMatrix()

	string trace = StringFromList(0, TraceNameList("", ";", 1))
	string mol = StringFromList(0, trace, "_")
	string DAY = StringFromList(2, trace, "_")

	SVAR NCyl = root:S_NormCyl
	
	string name = ReturnCurveMethod( mol )
	string errstr = kDFTmp + ":G_" + mol + "_" + name + "_" + DAY + "_sdev"
	string coefstr = kDFTmp + ":W_" + mol + "_" + name + "_" + DAY + "_coef"
	string covarstr = kDFTmp + ":M_" + mol + "_" + name + "_" + DAY + "_covar"
	
	NVAR err = $errstr
	Wave coef = $coefstr
	Wave COV = $covarstr
	Wave norm = $mol + "_norm_" + DAY

	String CMstr = mol + "_CM_" + DAY + "_" + name
	Variable i

	NewDataFolder /O/S $kDFCM
	Duplicate /O COV, $CMstr
	Wave CM = $CMstr
	InsertPoints/M=1 0,1, CM
	
	for ( i=0; i<numpnts(coef); i+=1 )
		CM[i][0] = coef[i]
	endfor
	
	WaveStats /Q norm
	
	GetAxis /Q bottom
	
	/// need to add to wave note
	string txt
	sprintf txt "%s Normalized to cylinder: %s (1-sigma: %f), numpnts = %d", name, NCyl, err, V_npnts
	// this is an key encoded line used for the DisplayCalCurve functions
	sprintf txt "%s\n;FIT:%s;CDAY:%s;NCYL:%s;ERR:%f;PTS:%d;RLO:%.2f;RHI:%.2f", txt, name, DAY, NCyl, err, V_npnts, V_min, V_max
	Note CM, txt
	
	SetDataFolder root:
	
	Button CalMatrix,title="Saved!", disable=2, fColor=(65535,54607,32768)
	
	Killwaves /Z coef, COV
	Killvariables /Z err
	
end


function MakeStationery()

	DoAlert 1, "Delete all data and create stationery?"
	if (V_flag == 2)
		return -1
	endif
	
	SVAR S_CalDate = root:S_caldate
	SVAR S_CalDates = root:S_caldates
	S_CalDate = ""
	S_CalDates = ""
	
	MoveWindow /C 10, 500, 800, 650
	
	RemoveDisplayedObjects()
	
	KillDataFolder /Z $kDFCM
	KillDataFolder /Z $kDFTmp
	
	SetDataFolder root:
	variable i
	string wv, lst = Wavelist("*", ";", "")
	
	// kill waves
	for (i=0; i<ItemsInList(lst); i+=1 )
		wv = StringFromList(i, lst)
		Killwaves /Z $wv
	endfor
	
	// kill variables
	lst =  Variablelist("V_*", ";",6)
	for (i=0; i<ItemsInList(lst); i+=1 )
		wv = StringFromList(i, lst)
		killvariables /Z $wv
	endfor
	
	make /t/n=0 CalDates
	
	
	DoWindow /K CalCurvePanel
	execute "CalCurvePanel()"
	
	DoAlert 1, "Do you want to save this experiment as an Igor stationary?"
	if ( V_flag == 1)
		DoIgorMenu "File", "Save Experiment As"
	endif

end

Function DataTable()

	SVAR mol = root:S_mol
	SVAR day = root:S_CalDate

	String tsecs = "tsecs_" + day
	String resp = mol + "_resp_" + day
	String selpos = "selpos_" + day
	String grav = mol + "_grav_" + day
	String norm = mol + "_norm_" + day
	String win = mol + "DataTable"
	
	DoWindow /k $win
	if (exists(norm) == 1 )
		Edit/K=1/W=(5,44,512,591) $tsecs,$resp,$selpos,$grav,$norm as mol + " Data Table"
	else
		Edit/K=1/W=(5,44,512,591) $tsecs,$resp,$selpos,$grav as mol + " Data Table"
	endif
	ModifyTable format(Point)=1
	DoWindow /c $win
	
End
