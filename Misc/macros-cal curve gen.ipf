// *** Updated 070223 to modernize global variable definitions (added NVAR and SVAR).  GSD.


Window CalCurvePanel() : Panel
	PauseUpdate; Silent 1		| building window...
	
	
	// Create Globals
	NumMakeOrDefault("root:G_currMolMode", 1)
	NumMakeOrDefault("root:S_CalDateMode", 0)
	NumMakeOrDefault("root:S_baseCylMode", WhichListItem(S_baseCyl, G_gravCyls, S_baseCyl))
	NumMakeOrDefault("root:G_NormFitMode", 3)
	NumMakeOrDefault("root:G_CalCurveMode", 4)
	NumMakeOrDefault("root:G_onlyNorm", 0)
	NumMakeOrDefault("root:G_makeCalCurve", 0)

	DoWindow /K CalCurvePanel
	NewPanel /W=(162,65,684,333) as "Cal Curve Panel"
	DoWindow /C CalCurvePanel
	setwindow CalCurvePanel hook=CalCurvePanelHOOK
	
	ModifyPanel cbRGB=(49151,65535,65535)
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (16385,28398,65535)
	DrawRect 50,117,471,215
	SetDrawEnv fillfgc= (49151,53155,65535)
	DrawRect 50,47,470,108
	SetDrawEnv arrow= 1
	DrawLine 265,18,290,18
	DrawLine 420,19,456,19
	SetDrawEnv arrow= 1
	DrawLine 456,19,456,41
	SetDrawEnv arrow= 1
	DrawLine 135,18,169,18

	CheckBox onlyNorm,pos={56,124},size={85,20},proc=CalCurve_CheckProc,title="Only Norm",value=G_onlyNorm
	CheckBox makeCalMatrix,pos={57,157},size={124,20},proc=CalCurve_CheckProc,title="Make Cal Matrix",value=G_makeCalCurve
	PopupMenu mol,pos={56,54},size={83,19},proc=CalCurve_PopMenuProc,title="Molecule"
	PopupMenu mol,mode=G_currMolMode,value= #"S_molLst"
	PopupMenu normCyl,pos={287,54},size={142,19},proc=CalCurve_PopMenuProc,title="Norm  Cyl"
	PopupMenu normCyl,mode=S_baseCylMode,value= #"G_gravCyls"
	PopupMenu Rsuffix,pos={56,81},size={156,19},proc=CalCurve_PopMenuProc,title="Working Group Suffix"
	PopupMenu Rsuffix,mode=G_RsuffixMode,value= #"G_RsuffixLst"
	PopupMenu NormFit,pos={146,125},size={208,19},proc=CalCurve_PopMenuProc,title="Normalize Fit Function"
	PopupMenu NormFit,mode=G_NormFitMode,value= #"S_driftMethods"
	PopupMenu CalCurve,pos={57,189},size={365,19},proc=CalCurve_PopMenuProc,title="Calibration Curve Function"
	PopupMenu CalCurve,mode=G_CalCurveMode,value= #"S_calcurveMethods"
	PopupMenu CalDate,pos={187,157},size={175,19},proc=CalCurve_PopMenuProc,title="Calibration Date"
	PopupMenu CalDate,mode=S_CalDateMode,value= #"S_calDateLst"
	Button DoIt,pos={409,129},size={50,30},proc=CalCurve_ButtonProc,title="Do it!"
	Button KillGraphs,pos={305,224},size={166,20},proc=CalCurve_ButtonProc,title="Remove All Graphs"
	Button ReLoad,pos={173,9},size={89,20},proc=CalCurve_ButtonProc,title="Load Data"
	Button MakeGrav,pos={296,10},size={121,20},proc=CalCurve_ButtonProc,title="Make Grav Wave"
	Button CreatePath,pos={49,9},size={84,20},proc=CalCurve_ButtonProc,title="Create Path"
	Button AddDate,pos={51,222},size={185,20},proc=CalCurve_ButtonProc,title="Add Calibration Date"
	
EndMacro

Function CalCurvePanelHOOK(infoStr)
	String infoStr
	
	NVAR G_currMolMode = G_currMolMode
	SVAR S_mol = S_mol
	NVAR S_baseCylMode = S_baseCylMode
	SVAR S_baseCyl = S_baseCyl
	NVAR G_RsuffixMode = G_RsuffixMode
//	SVAR G_Rsuffix = G_Rsuffix
	NVAR S_CalDateMode = S_CalDateMode
	SVAR S_CalDate = S_CalDate
	SVAR S_calDateLst = S_calDateLst
	NVAR G_NormFitMode = G_NormFitMode
	NVAR G_CalCurveMode = G_CalCurveMode
	SVAR S_molLst = S_molLst
	SVAR G_gravCyls = G_gravCyls
//	SVAR G_RsuffixLst = G_RsuffixLst
		
	if (strsearch(infoStr, "EVENT:activate", 0) != -1)
		G_currMolMode = WhichListItem(S_mol, S_molLst)+1
		S_baseCylMode = WhichListItem(S_baseCyl, G_gravCyls)+1
		S_CalDateMode = WhichListItem(S_CalDate, S_calDateLst)+1
		if (S_CalDateMode == -1)
			S_CalDateMode = 0
		endif

		PopupMenu mol,mode=G_currMolMode
		PopupMenu normCyl,mode=S_baseCylMode
		PopupMenu NormFit, mode=G_NormFitMode
//		PopupMenu Rsuffix,mode=G_RsuffixMode
		PopupMenu CalCurve, mode=G_CalCurveMode
		PopupMenu CalDate,mode=S_CalDateMode
	endif		
	
end

Function CalCurve_ButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	if (cmpstr(ctrlName, "DoIt") == 0)
	
		if (exists("G_date") != 2)
			execute "setDate()"
		endif
	
		SVAR mol = S_mol
		SVAR Rsuffix = G_Rsuffix
		SVAR baseCyl = S_baseCyl
		SVAR suffix = S_CalDate
		NVAR onlyNorm = G_onlyNorm
		NVAR driftFit = G_NormFitMode
		NVAR makeCalCurve = G_CalCurveMode
	
		// Kill old covariance waves
		bat("killwaves @", "CM_K*")
		
		if (cmpstr(IgorInfo(1),"Untitled") == 0)
			abort "This experiment MUST be saved as a PACKED experiment before proceeding. "
		endif
		
		MakeCalCurveFUNCT (mol, Rsuffix, baseCyl, suffix, onlyNorm, driftFit, makeCalCurve)
	
		// Don't need these!
		bat("killwaves @", "CM_K*")
	
	elseif (cmpstr(ctrlName, "KillGraphs") == 0)
		RemoveDisplayedGraphs()
	
	elseif (cmpstr(ctrlName, "CreatePath") == 0)
		execute "NewPathName()"
	
	elseif (cmpstr(ctrlName, "MakeGrav") == 0)
		execute "InsertGravValues()"

	elseif (cmpstr(ctrlName, "ReLoad") == 0)
		execute "LoadMolDBFromPath()"

	elseif (cmpstr(ctrlName, "AddDate") == 0)
		execute "SetDate()"
	endif

End

proc SetDate(enterDate)
	string enterDate=StrMakeOrDefault("root:S_CalDate", "YYMMDD")
	prompt enterDate, "Enter the calibration date (YYMMDD format)."
	
	silent 1
	
	S_CalDate = enterDate
       variable /G G_date=1
       
       print "Calibration Date changed to " + S_CalDate

	S_calDateLst = AddListItem(S_CalDate, S_calDateLst)
	S_CalDateMode = WhichListItem(S_CalDate, S_calDateLst)+1
	PopupMenu CalDate,mode=S_CalDateMode

end

Function CalCurve_PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName, popStr
	Variable popNum

	if (cmpstr(ctrlName, "mol") == 0)
		NVAR G_currMolMode = G_currMolMode
		G_currMolMode = popNum
		SVAR S_mol = S_mol
		S_mol = popStr
		PopupMenu mol, mode=G_currMolMode
	endif 

	if (cmpstr(ctrlName, "normCyl") == 0)
		NVAR S_baseCylMode = S_baseCylMode
		S_baseCylMode = popNum
		SVAR S_baseCyl = S_baseCyl
		S_baseCyl = popStr
		PopupMenu normCyl, mode=S_baseCylMode
	endif 

	if (cmpstr(ctrlName, "Rsuffix") == 0)
		NVAR G_RsuffixMode = G_RsuffixMode
		G_RsuffixMode = popNum
		SVAR G_Rsuffix = G_Rsuffix
		G_Rsuffix = popStr
		PopupMenu Rsuffix, mode=G_RsuffixMode
	endif 

	if (cmpstr(ctrlName, "NormFit") == 0)
		NVAR G_NormFitMode = G_NormFitMode
		G_NormFitMode = popNum
		PopupMenu NormFit, mode=G_NormFitMode
	endif 

	if (cmpstr(ctrlName, "CalCurve") == 0)
		NVAR G_CalCurveMode = G_CalCurveMode
		G_CalCurveMode = popNum
		PopupMenu CalCurve, mode=G_CalCurveMode
	endif 

	if (cmpstr(ctrlName, "calDate") == 0)
		NVAR S_CalDateMode = S_CalDateMode
		S_CalDateMode = popNum
		SVAR S_CalDate = S_CalDate
		S_CalDate = popStr
		PopupMenu CalDate, mode=S_CalDateMode
	endif 

End

Function CalCurve_CheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR G_onlyNorm = G_onlyNorm
	NVAR G_makeCalCurve = G_makeCalCurve
	
	if (cmpstr(ctrlName, "onlyNorm") == 0)
		if (G_onlyNorm == 1)
			G_onlyNorm = 0
		else
			G_onlyNorm = 1
		endif
	endif

	if (cmpstr(ctrlName, "makeCalMatrix") == 0)
		if (G_makeCalCurve == 1)
			G_makeCalCurve = 0
		else
			G_makeCalCurve = 1
		endif
	endif
	
End

proc NewPathName(pth)
	string pth="NewPath"
	prompt pth, "New path name."
	
	silent 1
	string com
	
	PathInfo $pth
	if (V_Flag == 1)
		abort "That path name is already used."
	endif
	S_path = pth
	
	sprintf com, "NewPath /Q/M=\"Path to NOAHchrom data.\" %s", pth
	execute com
	
end

Macro LoadMolDBFromPath(mol, Rsuffix, pathNm, type)
	string mol="ALL MOLS", Rsuffix=G_Rsuffix
	string pathNm=StrMakeOrDefault("root:G_PathNm", "Igor")
	string type=StrMakeOrDefault("root:G_RespType", "_resp")
	prompt mol,"molecule", popup, "ALL MOLS;" + S_molLst
	prompt Rsuffix, "suffix to add to loaded waves (don't leave blank)"
	prompt pathNm, "Path name", popup, PathList("*",";","")
	prompt type, "Response wave names", popup, "_resp;_respArea;_respHght"
	
	silent 1;pauseupdate
	string com
	
	if (cmpstr(Rsuffix,"") == 0)
		abort "You can't leave the suffix blank."
	endif
	
	if (cmpstr(mol, "ALL MOLS") == 0)
		sprintf com, "lbat(\"LoadmolDBfrompath(\\\"@\\\",\\\"%s\\\",\\\"%s\\\",\\\"%s\\\")\", S_molLst)", Rsuffix, pathNm, type
		execute com
	else
		S_mol=mol
		G_Rsuffix = Rsuffix
		G_PathNm = pathNm
		G_RespType = type
		
		G_RsuffixLst = AddElementToList(Rsuffix, G_RsuffixLst, ";")
		
		string slp = "selpos"
//		LoadWave/H/O/Q/P=$PathNm slp+".bwav"
	
		string resp = mol + type
		string load = slp + ";" + resp
//		LoadWave/H/O/Q/P=$PathNm resp+".bwav"
		LoadData /O/P=$PathNm /J=load
		sprintf com, "Note %s, \"Response from NOAHchrom %s%s wave.\"", resp, mol, type;  execute com
		
		killwaves /f/z $(mol + "_resp" + Rsuffix + "_bak")
		
		if (cmpstr(type,"_resp" + Rsuffix) != 0)
			killwaves /f/z $(mol + "_resp" + Rsuffix)
			rename $resp, $(mol + "_resp" + Rsuffix)
			if (cmpstr(Rsuffix,"") != 0)
				killwaves /f/z $("selpos" + Rsuffix)
				rename $slp, $("selpos" + Rsuffix)
			endif
		endif		
		
		freplace($(mol + "_resp" + Rsuffix),-1,NaN)
		freplace($(mol + "_resp" + Rsuffix),0,NaN)
	endif
	
end

Macro InsertGravValues(mol, Rsuffix, p1, p2, p3, p4)
	string Rsuffix=G_Rsuffix
	string  p1= G_selpos1, p2 = G_selpos2, p3 = G_selpos3, p4 = G_selpos4, mol
	prompt mol, "molecule", popup, "ALL MOLS;" + S_molLst
	prompt Rsuffix, "Suffix associated to data."
	prompt p1, "Selpos 1 cylinder", popup, G_gravCyls
	prompt p2, "Selpos 2 cylinder", popup, G_gravCyls
	prompt p3, "Selpos 3 cylinder", popup, G_gravCyls
	prompt p4, "Selpos 4 cylinder", popup, G_gravCyls
	
	silent 1
	pauseupdate	
	
	if (cmpstr(mol, "ALL MOLS") == 0)
		string com
		sprintf com, "InsertGravValues(\"@\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\")", Rsuffix, p1, p2, p3, p4
		lbat(com, S_molLst)
	else
		G_Rsuffix = Rsuffix
		G_selpos1 = p1
		G_selpos2 = p2
		G_selpos3 = p3
		G_selpos4 = p4
		
		string grav = mol + "_grav" + Rsuffix
		string sel = "selpos" + Rsuffix
		
		make /o/n=(numpnts($sel)) $grav=NaN
		
		InsertGravValuesFUNCT(mol, Rsuffix, $p1, $p2, $p3, $p4, $grav, $sel)
	endif
	
end

function InsertGravValuesFUNCT(mol, Rsuffix, p1, p2, p3, p4, grav, sel)
	string Rsuffix, mol
	wave p1, p2, p3, p4, grav, sel

	SVAR S_KLMmolLst = S_KLMmolLst

	variable n = numpnts(sel), inc
	variable gravPos = WhichListItem(mol, S_KLMmolLst)
	if (gravPos < 0) 
		abort "Molecule " + mol + " was not found in the S_KLMmolLst"
	endif
	
	do
		if (sel[inc] == 1)
			grav[inc] = p1[gravPos]
		else
		if (sel[inc] == 2)
			grav[inc] = p2[gravPos]
		else
		if (sel[inc] == 3)
			grav[inc] = p3[gravPos]
		else
		if (sel[inc] == 4)
			grav[inc] = p4[gravPos]
		endif
		endif
		endif
		endif
		inc += 1
	while (inc < n)
	
end


//function MakeFitPramWave(mol, coef, sigma, cov, sufx)
	string mol, sufx
	wave coef, sigma, cov
	
	string fprmStr = mol + "_Fprm_" + sufx
	make /o/n=5 $fprmStr
	
	wave fprm = $fprmStr
	
	fprm[0] = coef[2]
	fprm[1] = sigma[2]
	fprm[2] = coef[1]
	fprm[3] = sigma[1]
	fprm[4] = cov[2]

end

function ReturnConcFromFitPram(fitwv, resp, CalConc, offset)
	wave fitwv
	variable resp, CalConc, offset
	
	variable a, b, c
	a = fitwv[0]
	b = fitwv[2] - 2*fitwv[0]*CalConc
	c = fitwv[0]*CalConc^2 - fitwv[2]*CalConc + offset - resp
	
	return QuadSolution(a, b, c, "+")
end
	
	
| y = a (x - conc)^2 + b (x - conc) + 1
function /d ForceThruOne_Fit(w, x)
	wave /d w
	variable /d x
	
	NVAR G_conc = G_conc
	NVAR G_offset = G_offset
	
	return w[2]*(x - G_conc)^2 + w[1]*(x - G_conc) + G_offset + w[0]
end

| y = a (x - conc)^3 + b (x - conc)^2 + c (x - conc) + 1
function /d ForceThruOne_Fit_3prm(w, x)
	wave /d w
	variable /d x
	
	NVAR G_conc = G_conc
	NVAR G_offset = G_offset
	
	return w[3]*(x-G_conc)^3 + w[2]*(x - G_conc)^2 + w[1]*(x - G_conc) + G_offset + w[0]
end

Function FitForcedThruOneERR (param,  conc, prt)
	variable conc, prt
	wave param
	
	variable a = param[0], b = param[2]
	variable errA = param[1], errB = param[3], errAB = param[4], ERRtotal
	
	variable Aout = ( (x - conc)^2 * errA )^2
	variable Bout = ( (x - conc) * errB )^2
	variable ABout = 2*(x - conc)^3 * errAB
	
	ERRtotal = Sqrt(Aout + Bout + ABout)
	
	if (prt == 1)
		printf "Aout=%g  Bout=%g  ABout=%g\r", Aout, Bout, ABout
	endif
	
	return ERRtotal
end

Window ACATSCalCylinders() : Table
	PauseUpdate; Silent 1		| building window...
	
	MakeTextWaveFromList(S_KLMmolLst, "KLMmolecules", ";")
	Edit/W=(3,46,636,403) KLMmolecules,KLM1223,KLM1441,KLM1492,KLM1493,KLM1496,KLM1500,KLM1566,KLM1574 as "ACATS CalCylinders"
	ModifyTable width=60
EndMacro

Window LACECalCylinders() : Table
	PauseUpdate; Silent 1		| building window...
	
	MakeTextWaveFromList(S_KLMmolLst, "KLMmolecules", ";")
	Edit/W=(260,41,654,398) KLMmolecules,KLM1551,KLM1554,KLM1570,AAL15901 as "LACE CalCylinders"
	ModifyTable width=60
EndMacro

//Function /D Linear_Fit (w, x)
	Wave /D w; Variable /D x
	
	return w[1]*x + w[0]
end

//Function /D Poly3_Fit (w, x)
	Wave /D w; Variable /D x
	
	return w[2]*x^2 + w[1]*x + w[0]
end

//Function /D Poly4_Fit (w, x)
	Wave /D w; Variable /D x
	
	return w[3]*x^3 + w[2]*x^2 + w[1]*x + w[0]
end

//Function /d Gauss_Fit (w, x)
	wave /d w
	variable /d x
	
	return w[0] + w[1]*exp(-((x - w[2])/w[3])^2)
end


Function MakeCalCurveFUNCT (mol, Rsuffix, baseCyl, suffix, onlyNorm, drift, calCurveFit)
	string mol, Rsuffix, baseCyl, suffix
	variable onlyNorm, drift, calCurveFit

	SVAR S_KLMmolLst = S_KLMmolLst
	
	variable molIdx = WhichListItem(mol, S_KLMmolLst)
	NumMakeOrDefault("root:G_NormWaveSD", 0)
	NVAR G_NormWaveSD = G_NormWaveSD
//	NVAR V_sdev = V_sdev
	
	if (molIdx < 0) 
		abort "Molecule " + mol + " was not found in the S_KLMmolLst"
	endif
		
	string respStr = mol + "_resp" + Rsuffix
	if (exists(respStr) != 1)
		print respStr + " does not exist."
		abort
	endif
	wave resp = $respStr
	string respNote = lowerstr(Note($respStr)), respType
	string respB = mol + "_resp" + Rsuffix + "_bak"
	string gravStr = mol + "_grav" + Rsuffix
	wave grav = $gravStr
	string coef = mol + "_coef" + Rsuffix
	string sigma = mol + "_sigma" + Rsuffix
	string fit = "fit_" + respStr, fitprm
	variable n = numpnts(resp), inc=0, doFit=0
	string com
	make /o/n=0 $fit
	wave fitwv = $fit
	
	// Figure out what resp type is used
	if (strsearch(respNote, "_resparea", 0) != -1)
		respType = "a"
	endif
	if (strsearch(respNote, "_resphght", 0) != -1)
		respType = "h"
	endif
	if (strsearch(respNote, "_resp ", 0) != -1)
		respType = ""
	endif
	
	if (calCurveFit==1)
		fitprm = mol + "_CM_" + suffix + respType + "_line"
	endif
	if (calCurveFit==2)
		fitprm = mol + "_CM_" + suffix + respType + "_poly3"
	endif
	if (calCurveFit==3)
		fitprm = mol + "_CM_" + suffix + respType + "_poly4"
	endif
	if (calCurveFit==4)
		fitprm = mol + "_CM_" + suffix + respType + "_poly3frc"
	endif
	if (calCurveFit==5)
		fitprm = mol + "_CM_" + suffix + respType + "_poly4frc"
	endif
	
	wave S_baseCyl=$baseCyl
	NVAR G_conc = G_conc
	G_conc = S_baseCyl[molidx]
	
	//Backup resp if not done
	if (exists(respB) == 1)
		wave respBwv = $(mol + "_resp" + Rsuffix + "_bak")
		resp = respBwv
	else
		duplicate resp $respB
	endif
	
	// Set up the NormWave and NormWave_div (divided by fit). 
	duplicate /o resp NormWave
	do	//filter out the base cylinder points and normalize
		If (grav[inc] != G_conc)
			NormWave[inc] = NaN
		endif
		inc += 1
	while (inc < n)
	freplace(NormWave, -1, NaN)
	duplicate /o NormWave, NormWave_Div,Res_NormWave
	Res_NormWave=nan
	
	sprintf com, "DoWindow/K %sCalCurve%s", mol,Rsuffix; execute com
	DoWindow/K NormWindow
	display NormWave
	ModifyGraph mode=3, marker=19, gFont="Times", gfSize=14, gmSize=2, grid=1, mirror=1
	sprintf com, "Label left \"%s Base Cal. Resp.\";Label bottom \"Injection Number\"", mol
	execute com
	DoWindow/C NormWindow

	CurveFit/Q line, NormWave /D /R		// Insures that the W_coef and W_sigma waves exist.
	wave W_coef = $"W_coef"
	wave W_sigam = $"W_sigma"
	
	variable reNorm = 1		// Allways renorm
	if (reNorm)
		if (drift==1)
			wavestats /q NormWave
			NormWave_Div /= V_avg
			resp /= V_avg
		endif
		if (drift==2)
			CurveFit/Q line, NormWave /D /R
			NormWave_Div /= (W_coef[0]+W_coef[1]*x)
			resp /= (W_coef[0]+W_coef[1]*x)
		endif
		if (drift >= 3)
			CurveFit/Q poly drift, NormWave /D /R
			NormWave_Div /= poly(W_coef,x)
			resp /= poly(W_coef,x)
		endif
		wavestats /q NormWave_Div
		G_NormWaveSD = V_sdev
	endif
	wavestats /q NormWave
	Res_NormWave = Res_NormWave/V_avg * 100
	freplace(Res_NormWave, 0, nan)
	ModifyGraph rgb(Res_NormWave)=(0,0,65535)
	sprintf com, "1-\\F'Symbol's\\F'Times' residual: %f%", G_NormWaveSD*100
	Textbox/N=res/F=0/A=MC/X=17.78/Y=-40.14 com

	//Make graphs
	if (!onlyNorm)
		Display /W=(5,272,400,480) resp vs grav
		ModifyGraph mode=3, marker=19, gFont="Times", gfSize=14, gmSize=2, grid=1, mirror(left)=1,fStyle=1
		SetAxis/A/N=1/E=1 left
		SetAxis/A/N=1/E=1 bottom
		sprintf com, "DoWindow/C %sCalCurve%s", mol, Rsuffix; execute com
		sprintf com, "Label left \"%s Norm. Resp.\";Label bottom \"%s Mixing Ratio\"",mol, mol; execute com
	else
		return 1
	endif

	DoUpdate

	// Check if the normalization worked.  If it did do the cal curve fit.
	wavestats/Q resp
	if (V_sdev > 0.1) 
		doFit = 1
	endif
	wavestats/Q grav
	if (V_sdev > 0.1)
		doFit = 1
	else
		doFit = 0
	endif

	if (doFit)
		if ((calCurveFit == 4) + (calCurveFit == 5))
			execute "ChangeFixedPoint()"
		endif
		
		string ResStr = "Res_" + mol + "_resp" + Rsuffix
		make /o/n=(numpnts(resp)) $ResStr=NaN
		wave fitPrmWv = $fitprm
		wave res = $ResStr
		
		if (calCurveFit == 1)	// Linear
			make /o W_coef = {0.1,0.1}
			sprintf com, "FuncFit/M Linear_Fit W_coef %s /X=%s /D /R ", respStr, gravStr; execute com
			MakeFitMatrix(numpnts(W_coef), mol, fitPrm, baseCyl, "Linear, created:  " + date())
			sprintf com, "\\Z09Resp = %g x %s %g\\Z14 ", W_coef[1], Psign(W_coef[0]), abs(W_coef[0])
			Textbox/N=text0/F=0/A=MC/X=4.92/Y=-42.96 com
		endif
		if (calCurveFit == 2)	// Poly 3
			sprintf com, "CurveFit/M/Q poly 3, %s /X=%s /D/R ",respStr, gravStr; execute com
			MakeFitMatrix(numpnts(W_coef), mol, fitPrm, baseCyl, "Poly 3, created:  " + date())
			sprintf com, "\\Z09Resp = %g x\\S2\\M\\Z09 %s %g x %s %g\\Z14 ", W_coef[2], Psign(W_coef[1]), abs(W_coef[1]), Psign(W_coef[0]), abs(W_coef[0])
			Textbox/N=text0/F=0/A=MC/X=4.92/Y=-42.96 com
		endif
		if (calCurveFit == 3)	// Poly 4
			sprintf com, "CurveFit/M/Q poly 4, %s /X=%s /D/R ", respStr, gravStr; execute com
			MakeFitMatrix(numpnts(W_coef), mol, fitPrm, baseCyl, "Poly 4, created:  " + date())
			sprintf com, "\\Z09Resp = %g x\\S3\\M\\Z09 %s %g x\\S2\\M\\Z09 %s %g x %s %g\\Z14 ", W_coef[3], Psign(W_coef[2]), abs(W_coef[2]), Psign(W_coef[1]), abs(W_coef[1]), Psign(W_coef[0]), abs(W_coef[0])
			Textbox/N=text0/F=0/A=MC/X=4.92/Y=-42.96 com
		endif
		if (calCurveFit == 4)	// Poly 3 (forced thru a point)
			make /o W_coef = {0,1,0.001}
			FuncFit/Q/M/H="100" ForceThruOne_Fit W_coef resp /X=grav /D/R 
			NVAR G_offset = G_offset
			MakeFitMatrix(numpnts(W_coef), mol, fitPrm, baseCyl, "Poly 3 (forced thru ["+num2str(G_conc)+","+num2str(G_offset)+"]), created:  " + date())
			if (G_conc != 0)
				sprintf com, "\\Z09Resp = %g * (x - %3.1f)\\S2\\M\\Z09 %s %g * (x - %3.1f) %s %g\\Z14 ", W_coef[2], G_conc, Psign(W_coef[1]), abs(W_coef[1]), G_conc, Psign(G_offset), abs(G_offset)
			else
				sprintf com, "\\Z09Resp = %g x\\S2\\M\\Z09 %s %g x %s %g\\Z14 ", W_coef[2], Psign(W_coef[1]), abs(W_coef[1]), Psign(G_offset), abs(G_offset)
			endif
			Textbox/N=text0/F=0/A=MC/X=4.92/Y=-42.96 com
		endif
		if (calCurveFit == 5) 	// Poly 4 (forced thru 0)
			make /o W_coef = {0,1,0.001,0.0001}
			FuncFit/Q/M/H="1000" ForceThruOne_Fit_3prm W_coef resp /X=grav /D/R 
			MakeFitMatrix(numpnts(W_coef), mol, fitPrm, baseCyl, "Poly 4 (forced thru ["+num2str(G_conc)+","+num2str(G_offset)+"]), created:  " + date())
			if (G_conc != 0)
				sprintf com, "\\Z09Resp = %g * (x - %3.1f)\\S3\\M\\Z09 %s %g * (x - %3.1f)\\S2\\M\\Z09 %s %g * (x - %3.1f) %s %g\\Z14 ", W_coef[3], G_conc, Psign(W_coef[2]), abs(W_coef[2]), G_conc, Psign(W_coef[1]), abs(W_coef[1]), G_conc, Psign(G_offset), abs(G_offset)
			else
				sprintf com, "\\Z09Resp = %g x\\S3\\M\\Z09 %s %g x\\S2\\M\\Z09 %s %g x %s %g\\Z14 ", W_coef[3], Psign(W_coef[2]), abs(W_coef[2]), Psign(W_coef[1]), abs(W_coef[1]), Psign(G_offset), abs(G_offset)
			endif
			Textbox/N=text0/F=0/A=MC/X=4.92/Y=-42.96 com
		endif			

		getAxis /Q bottom
		SetScale/I x (V_min),(V_max),"", fitwv
		if ((calCurveFit == 1) + (calCurveFit == 2))
			fitwv = poly(W_coef,x)
		endif
		if (calCurveFit == 4)
			fitwv = ForceThruOne_Fit(W_coef,x)
		endif
		if (calCurveFit == 5)
			fitwv = ForceThruOne_Fit_3prm(W_coef,x)
		endif
		Legend/N=legnd/J/X=59/Y=32 "\\s(Res_"+mol+"_resp"+Rsuffix+") % Residual "

		res *= 100
		SetAxis/A/E=2 Res_Left
		Label Res_Left " "
		ModifyGraph zero(Res_Left)=1, fSize(Res_Left)=10,fStyle(Res_Left)=0
		sprintf com, "ModifyGraph rgb(Res_%s_resp%s)=(0,0,65535),marker(Res_%s_resp%s)=8", mol, Rsuffix, mol, Rsuffix
		execute com		
		
	endif
end

function/s Psign (num)
	variable num
	
	if (sign(num) >= 0)
		return "+"
	else
		return "-"
	endif
end

// conc is the X point, offset is the Y point
proc ChangeFixedPoint(conc, offset)
	variable conc=NumMakeOrDefault("root:G_conc", 0)
	variable offset=NumMakeOrDefault("root:G_offset", 0)
	prompt conc, "X set point (usually in concentration)"
	prompt offset, "Y set point (usually in Norm Resp units)"
	
	silent 1
	G_conc = conc
	G_offset = offset
end

function MakeFitMatrix(numRows, mol, fitPrm,  baseCyl, comment)
	variable numRows
	string fitPrm, mol, baseCyl, comment
	
	NVAR G_makeCalCurve = G_makeCalCurve
	NVAR G_NormWaveSD = G_NormWaveSD
	
	if (G_makeCalCurve == 1)
		wave W_coef = $"W_coef"
		variable inc = 1
		string com
		
		make /o/n=(numRows, numRows+1) $fitPrm
		wave fitPrmWv = $fitPrm
		sprintf com, "%s\rNormalized to cylinder: %s (1-sigma: %f)\r", comment, baseCyl, G_NormWaveSD
		Note fitPrmWv, com
		
		fitPrmWv[][0] = W_coef[p]
		do
			wave covWv = $("CM_K" + num2str(inc-1))
			fitPrmWv[][inc] = covWv[p]
			inc += 1
		while (inc <= numRows)
	
		sprintf com, "NewDataFolder/O root:%s_Calcurves", mol
		execute com
		sprintf com, "duplicate /o root:%s, root:%s_Calcurves:%s", fitPrm, mol, fitPrm
		execute com
		killwaves /z $fitPrm
	endif
	
end

proc DisplayMolList()
	printf "S_molLst = %s\r", S_molLst
end

Proc ConcatinatetwoDBs(suffix1, suffix2, suffixN)
	string suffix1, suffix2, suffixN="New"
	prompt suffix1, "First suffix"
	prompt suffix2, "Second suffix"
	prompt suffixN, "New suffix (don't leave blank)."
	
	silent 1
	
	if (cmpstr(suffixN, "") == 0)
		abort "You left the New suffix blank.  Try again."
	endif
	
	string selpos1 = "selpos" + suffix1
	string selpos2 = "selpos" + suffix2
	string selposN = "selpos" + suffixN
	variable numMols = NumElementsInList(S_molLst, ";"), molInc
	string mol, resp, grav
	
	if (exists(selpos1) != 1)
		abort "The suffix: "+suffix1+" does not appear to be valid."
	endif
	if (exists(selpos2) != 1)
		abort "The suffix: "+suffix2+" does not appear to be valid."
	endif
	
	G_RsuffixLst = AddElementToList(suffixN, G_RsuffixLst, ";")
	
	make /o/n=0 $selposN
	con(selposN, selpos1)
	con(selposN, selpos2)
	
	do
		mol = GetStrFromList(S_molLst, molInc, ";")
		resp = mol + "_resp"
		grav = mol + "_grav"
		if (exists(resp + suffix1) == 1)
			make /o/n=0 $(resp + suffixN)
			con(resp+suffixN, resp+suffix1)
			con(resp+suffixN, resp+suffix2)
			Note $(resp+suffixN) Note($(resp+suffix1))
			make /o/n=0 $(grav + suffixN)
			con(grav+suffixN, grav+suffix1)
			con(grav+suffixN, grav+suffix2)
		endif
		molInc += 1
	while(numMols > molInc) 
end

Proc DisplayCalCurve(CM, rangeLO, rangeHI, NewAppend)
	string CM
	variable rangeLO=0, rangeHI=300, NewAppend=1
	prompt CM, "Cal Matrix Name"
	prompt rangeLO, "X min"
	prompt rangeHI, "X max"
	prompt NewAppend, "New plot or append to top plot", popup, "New;Append"
	
	silent 1
	
	variable Forced=0, forceX, forceY
	string mol = CM[0, strsearch(CM, "_CM", 0)-1]
	string CMfullpath = "root:"+mol+"_Calcurves:" + CM
	variable Degrees = DimSize($CMfullpath, 0)
	string CurveName = CM[strsearch(CM, "_CM", 0)+4, strlen(CM)-1]
	string CurveNote = Note($CMfullpath)
	string NormCyl = CurveNote[strsearch(CurveNote, "Normalized to cylinder:", 0)+strlen("Normalized to cylinder:")+1, 1000]
	string fit = "fit_" + mol + "_" + CurveName
	string com
	
	if (strsearch(CurveNote, "[", 0) != -1)
		Forced = 1
		forceX = str2num(CurveNote[strsearch(CurveNote, "[", 0)+1, strsearch(CurveNote, ",", 0)-1])
		forceY = str2num(CurveNote[strsearch(CurveNote, ",", 0)+1, strsearch(CurveNote, "]", 0)-1])
	endif
	
	make /o/n=200 $fit
	SetScale/I x rangeLO,rangeHI,"", $fit
	
	if (Degrees==2)					//linear
		$fit = $CMfullpath[0][0] + x*$CMfullpath[1][0]
	endif
	if ((Degrees==3)*(Forced==0))		//poly 3
		$fit = $CMfullpath[0][0] + x*$CMfullpath[1][0] + x*x*$CMfullpath[2][0]
	endif
	if ((Degrees==3)*(Forced==1))		//poly 3 (forced)
		$fit =  $CMfullpath[2][0] * (x - forceX)^2 + $CMfullpath[1][0] * (x - forceX) + forceY
	endif
	if ((Degrees==4)*(Forced==0))		//poly 4
		$fit = $CMfullpath[0][0] + x*$CMfullpath[1][0] + x*x*$CMfullpath[2][0] + x*x*x*$CMfullpath[3][0]
	endif
	if ((Degrees==4)*(Forced==1))		//poly 4 (forced)
		$fit = $CMfullpath[3][0] * (x - forceX)^3 + $CMfullpath[2][0] * (x - forceX)^2 + $CMfullpath[1][0] * (x - forceX) + forceY
	endif
	
	If (NewAppend == 1)
		Display /W=(212,58,607,266) $fit
		ModifyGraph grid=1, mirror=2
		Label left "Norm Resp"
		Label bottom "Mol Mixing Ratio"
		SetAxis/A/N=1 left
		SetAxis/A/N=1 bottom
		sprintf com, "\\JC\\f01%s\\f00 Cal Curve: %s\rNormalized to: \\f01%s2\\f00", mol, CurveName, NormCyl
		Textbox/N=Norm/S=3/A=MC/X=-20.13/Y=33.12 com
	else
		append $fit
	endif
		
end
