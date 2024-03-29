#pragma rtGlobals=1		// Use modern global access method.
//#include "Procs-PR crossplot"



// Used only for intial settings!!!
proc ConcPostProcInit()
	silent 1
	string /g S_molLst="F11;F113;MC;CT;N2O;SF6;F12;H1211;H2;CH4"
	string S_STRAT2 = "951020;951024;951026;951031;951102;951105;951107;951109;"
	string S_STRAT3 = "960126;960129;960201;960202;960205;960208;960212;960213;960215;"
	string S_STRAT4 = "960718;960722;960725;960730;960801;960803;960805;960807;960808;960810;"
	string /g S_flightLst = S_STRAT2 + S_STRAT3 + S_STRAT4
	string /g S_mission = "STRAT"
	
	// Setup dependencies
	MakeTextWaveFromList(S_molLst, "Molecules", ";")
	S_molLst := WaveToList(NameOfWave(Molecules), ";")
	MakeTextWaveFromList(S_flightLst, "Flights", ";")
	S_flightLst := WaveToList(NameOfWave(Flights), ";")
	
	MoleculeList2Wave(2)
	FlightList2Wave(2)
end

Proc DisplayCalCurveList(mol, disp)
	string mol=StrMakeOrDefault("root:S_LoadMol", "F11")
	variable disp=1
	prompt mol, "Which molecule?", popup, WaveToList("molecules", ";")
	prompt disp, "Display new table?", popup, "Yes;No"
	
	silent 1
	
	string curveLst = kDFCM + ":" + mol + "_calCurveLst"
	string curveWv = mol + "_calCurves"
	string com

//	SortList(curveLst)
	
	if (exists(curveLst) == 2)
		sprintf com, "MakeTextWaveFromList(%s, \"%s\", \";\")", curveLst, curveWv; execute com
		sort $curveWv, $curveWv
		if (disp==1)
			DoWindow /K $mol+"_curves"
			Edit/K=1/W=(50,50,279,519) $curveWv as mol+"_curves"
			ModifyTable width(Point)=40,width($mol+"_calCurves")=160
			DoWindow /C $mol+"_curves"
		endif
	else
		if (disp==1)
			abort "There are no calibration matrices loaded for " + mol + "."
		else
			print "There are no calibration matrices loade for " + mol + "."
		endif
	endif
end	

Proc DisplayCalCurveDB(mol, attrib, disp)
	string mol=StrMakeOrDefault("root:S_LoadMol", "F11")
	string attrib=StrMakeOrDefault("root:S_attrib", "Area")
	variable disp=1
	prompt mol, "Which molecule?", popup, WaveToList("molecules", ";")
	prompt attrib, "Which response?", popup, "Area;Hght"
	prompt disp, "Display Table?", popup, "Yes;No"

	silent 1
	S_attrib = attrib
	S_LoadMol = mol
	
	string curveDB = mol + "_" + attrib + "_curveDB"
	
	if (exists(curveDB) != 1)
		make /t/n=(numpnts(flights)) $curveDB=""	// Make the cal curve data base wave.
		DisplayCalCurveList(mol, 0)					// Creates the '_calCurves wave.
		if (exists(mol+"_calCurves") == 1)			
			$curveDB = $(mol+"_calCurves")[0]		// Intial value for wave.
		endif
	endif

	if (disp==1)
		DoWindow/K $mol+attrib+curveDB
		Edit/K=1/W=(195,42,525,591) Flights,$curveDB as mol+" Cal Curve DB"
		ModifyTable alignment(Flights)=1
		ModifyTable alignment($curveDB)=1, width($curveDB)=150
		DoWindow/C $mol+attrib+curveDB
	endif
end

proc ApplyCalCurvesOld(mol, flight, attrib, disp)
	string mol=StrMakeOrDefault("root:S_LoadMol", "F11")
	string flight=StrMakeOrDefault("root:S_LoadFlight", GetStrFromList(S_flightLst, 1, ";"))
	string attrib=StrMakeOrDefault("root:S_attrib", "Hght")
	variable disp=NumMakeOrDefault("root:G_disp", 1)
	prompt mol, "Which molecule?", popup, "ALL MOLS;"+WaveToList("molecules", ";")
	prompt flight, "Which flight?", popup, "ALL DATES;"+WaveToList("flights", ";")
	prompt attrib, "What type of response?", popup, "_both_;Area;Hght"
	prompt disp, "Make a plot?", popup, "Yep;Nope"

	silent 1
	G_disp = disp
	S_LoadMol = mol
	S_LoadFlight = flight
	S_attrib = attrib
	
	ApplyCalCurvesFUNCT(mol, flight, attrib, disp)
	
end
	
function ApplyCalCurvesFUNCT(mol, flight, attrib, disp)
	string mol, flight, attrib
	variable disp

	SVAR S_LoadFlight = S_LoadFlight
	SVAR S_flightLst = S_flightLst
	
	string com
	wave/t Flights, Molecules
	Variable FltInc, MolInc

	// handle recursion
	if (cmpstr(mol,"ALL MOLS") == 0)
		if (cmpstr(flight, "ALL DATES") == 0)
			for( FltInc = 0; FltInc < numpnts(flights); FltInc += 1 )
				for( MolInc = 0; MolInc < numpnts(Molecules); MolInc += 1 )
					ApplyCalCurvesFUNCT(Molecules[MolInc], flights[FltInc], attrib, disp)
				endfor
			endfor
		else
			for( MolInc = 0; MolInc < numpnts(Molecules); MolInc += 1 )
				ApplyCalCurvesFUNCT(Molecules[MolInc], flight, attrib, disp)
			endfor
		endif
		return 0
	elseif (cmpstr(flight, "ALL DATES") == 0)
		for( FltInc = 0; FltInc < numpnts(flights); FltInc += 1 )
			ApplyCalCurvesFUNCT(mol, flights[FltInc], attrib, disp)
		endfor
		return 0
	endif

	if (cmpstr(attrib, "_both_") == 0)
		ApplyCalCurvesFUNCT(mol, flight, "Area", disp)
		ApplyCalCurvesFUNCT(mol, flight, "Hght", disp)
	else

		String curveDB = mol + "_" + attrib + "_curveDB"
		wave/t curveDBwv = $curveDB
		
		if (exists(curveDB) != 1)
			print "DisplayCalCurveDB(\"" + mol + "\",\"" + attrib + "\", 2)"
			print "You haven't created the " + mol + " cal. curve data base.  Using defaults!"
		endif
		
		if (numpnts(Flights) != numpnts(curveDBwv))
			sprintf com, "The \"Flight\" and \"%s\" waves aren't the same length.  Proceed?", curveDB
			DoAlert 1, com
			if (V_flag != 1)
				execute "DisplayCalCurveDB(\"" + mol + "\",\"" + attrib + "\", 1)"
				abort
			endif
		endif

		variable flightIndex = WhichListItem(flight, S_flightLst, ";")
		string curve = kDFCM + ":" + mol + "_CM_" + curveDBwv[flightIndex]
		string resp = mol + "_" + attrib + "_" + flight
		string conc = mol + "_" + attrib + "_conc_" + flight
		string prec = mol + "_" + attrib + "_prec_" + flight
		
		if (exists(resp) != 1)
			print "Wave: " + resp + " does not exist!  Did you load it?"
		endif
		
		if ((exists(resp) == 1) && (strlen(curveDBwv[flightIndex]) == 0))
			make/o/n=(numpnts($resp)) $conc=NaN
			make/o/n=(numpnts($resp)) $prec=NaN
		endif
		
		if ((exists(curve) == 1) && (exists(resp) == 1))
			make/o/n=(numpnts($resp)) $conc=NaN
			make/o/n=(numpnts($resp)) $prec=NaN
			ApplyCurve(mol, $curve, $resp, $conc, $prec)
			if (disp==1)
				ConcPlotFUNCT(mol, attrib, flight)
			endif
		endif
		
	endif
	
end


function ApplyCurve (mol, curveWv, respWv, concWv, precWv)
	string mol
	wave curveWv, respWv, concWv, precWv
	
	variable Degrees = DimSize(curveWv, 1)-1
	variable strtPt, midPt, endPt, a, b, c, d, aERR, bERR, cERR, dERR, abERR, acERR, bcERR, yERR, flightyERR, Sx, Sy
	string calCyl
	variable calCylVal
	string calNote = Note(curveWv)
	string respNote = Note(respWv)
	string com
	
	SVAR S_molLst = root:S_molLst
	SVAR KLMmolLst = root:S_KLMmolLst

	make /o/n=0 coefWv, errWv
	wave coefWv, errWv
	
	// Figure out the cal cylinder
	strtPt = strsearch(calNote, ":", 0) +1
	strtPt = strsearch(calNote, ":", strtPt) +1
	endPt = strsearch(calNote, "(", strtPt) -1
	calCyl = calNote[strtPt+1, endPt-1]
	if(exists(kDFCal+":"+calCyl)!=1)
		 abort "The Wave Containing Normalizing Cal Cylinder Values Cannot Be Found:  Did you import it from the Cal Expt?"		
	endif
	wave calCylwv = $kDFCal+":"+calCyl
	variable pos = WhichListItem(mol, KLMmolLst, ";")
	calCylVal = calCylwv[pos]
	
	// Cal yERR
	strtPt = strsearch(calNote, ":", endPt) +1
	endPt = strsearch(calNote, ")", strtPt) -1
	yERR = str2num(calNote[strtPt, endPt])
	
	// Read in precision error estimate from wave note.
	strtPt = strsearch(respNote, ":", 0) + 1
	strtPt = strsearch(respNote, ":", strtPt) + 1
	if(strtPt!=0)
		endPt = strsearch(respNote, ":", strtPt) - 1
	else
		strtPt = strsearch(respNote, ":", 0) + 1
		endPt = strsearch(respNote, "%", strtPt) - 1	
	endif
	flightyERR = str2num(respNote[strtPt, endPt])/100			// div by 100 for the percent

	if (Degrees == 2)	// Linear
		a = curveWv[1][0]; aERR = SQRT(curveWv[1][2])
		b = curveWv[0][0]; bERR = SQRT(curveWv[0][1])
		abERR = curveWv[1][1]
		concWv = (respWv - b) / a
		precWv = sqrt(((1/a * yERR)^2 + (1/a * bERR)^2 + ((respWv - b)/a^2 * aERR)^2 + abERR/a^2) + (flightyERR*calCylVal)^2)
		print (respWv[80] - b)/a, (1/a * yERR)^2, (bERR/a)^2, ((respWv[80] - b)/a^2 * aERR)^2 + abERR/a^2, (flightyERR*calCylVal)^2
		Note concWv, "Cal curved used (" + NameOfWave(curveWv) + "):\r\t" + calNote
		
	elseif (Degrees == 3)	// Poly 3
		
		c = curveWv[0][0]; cERR = SQRT(curveWv[0][1])
		b = curveWv[1][0]; bERR = SQRT(curveWv[1][2])
		a = curveWv[2][0]; aERR = SQRT(curveWv[2][3])
		abERR = curveWv[2][2]
		acERR = curveWv[2][1]
		bcERR = curveWv[0][2]
		make /o coefWv = {c, b, a}
		make /o errWv = {cERR, bERR, aERR}
		
		strtPt = strsearch(calNote,"[",0)
		if (strtPt == -1)		// Poly 3 (no forced points)
			concWv = QuadSolution(a, b, c-respWv, "+")
			print QuadSolutionERR(coefWv, errWv, abERR, acERR, bcERR, respWv[701], yERR, "+", 1)
			print (flightyERR*calCylVal)
			precWv = sqrt(QuadSolutionERR(coefWv, errWv, abERR, acERR, bcERR, respWv, yERR, "+", 0)^2 + (flightyERR*calCylVal)^2)
		else						// Poly 3 (forced through a point)
			endPt = strsearch(calNote,"]", strtPt)
			midPt = strsearch(calNote,",", strtPt)
			Sx = str2num(calNote[strtPt+1, midPt])
			Sy = str2num(calNote[midPt+1, endPt])
			
			// Do a little check.  The calCylVal should be equal to Sx
			//if (abs(calCylVal - Sx) > 0.01 )
			//	sprintf com,  "This Cal curve was normalized to %g, but that is not the value of %s = %g.", Sx, calCyl, calCylVal
			//	abort com
			//endif
	
			precWv = sqrt(Poly3ForcedERR(a, b, Sx, Sy, aERR, bERR, abERR, respWv, yERR, "+")^2 + (flightyERR*calCylVal)^2)
			a = a
			c = Sx*(a*Sx -b) + Sy			// old b
			b = b - 2*a*Sx
			concWv = QuadSolution(a, b, c-respWv, "+")
		endif
		Note concWv, "Cal curved used (" + NameOfWave(curveWv) + "):\r\t" + calNote
	
	elseif (Degrees == 4)	// Poly 4
		string NormCyl
		variable GuessConc, GuessConcInc, RespIntended, RespGuess, PrevDirection = -1
		variable numResp = numpnts(respWv), RespInc = 0, NormCylConc
		SVAR KLMmolLst = S_KLMmolLst

		d = curveWv[0][0]
		c = curveWv[1][0]
		b = curveWv[2][0]
		a = curveWv[3][0]

		strtPt = strsearch(calNote,":", 0)+1
		strtPt = strsearch(calNote,":", strtPt)+1
		endPt = strsearch(calNote, "(", strtPt)-1
		NormCyl = calNote[strtPt+1, endPt-1]
		if (exists(NormCyl) != 1)
			abort "Sorry, this experiment needs a cal tank wave called: " + NormCyl +"."
		endif
		wave NormCylWv = $NormCyl
		
		NormCylConc = NormCylWv[WhichListItem(mol, KLMmolLst, ";")]
		
		strtPt = strsearch(calNote,"[",0)
		if (strtPt == -1)	// Poly 4 (no forced points)
			do
				RespIntended = respWv[RespInc]
				if (numtype(RespIntended) == 0)
					GuessConc = RespIntended*NormCylConc
					GuessConcInc = GuessConc/10
					PrevDirection = -1
					do
						RespGuess = a*GuessConc^3 + b*GuessConc^2 + c*GuessConc + d
						if (RespGuess < RespIntended)
							if (PrevDirection == 1)
								GuessConcInc *= 0.20
							endif
							GuessConc += GuessConcInc
							PrevDirection = 0
						else
							if (PrevDirection == 0)
								GuessConcInc *= 0.20
							endif
							GuessConc -= GuessConcInc 
							PrevDirection = 1
						endif
					while (GuessConcInc > 0.0001)
					concWv[RespInc] = GuessConc
				else
					concWv[RespInc] = NaN
				endif
				RespInc += 1
			while (RespInc < numResp)
		else			// Poly 4 (forced through a point)
			endPt = strsearch(calNote,"]", strtPt)
			midPt = strsearch(calNote,",", strtPt)
			Sx = str2num(calNote[strtPt+1, midPt])
			Sy = str2num(calNote[midPt+1, endPt])
			do
				RespIntended = respWv[RespInc]
				if (numtype(RespIntended) == 0)
					GuessConc = RespIntended*NormCylConc
					GuessConcInc = GuessConc/10
					PrevDirection = -1
					do
						RespGuess = a*(GuessConc-Sx)^3 + b*(GuessConc-Sx)^2 + c*(GuessConc-Sx) + Sy
						if (RespGuess < RespIntended)
							if (PrevDirection == 1)
								GuessConcInc *= 0.20
							endif
							GuessConc += GuessConcInc
							PrevDirection = 0
						else
							if (PrevDirection == 0)
								GuessConcInc *= 0.20
							endif
							GuessConc -= GuessConcInc 
							PrevDirection = 1
						endif
					while (GuessConcInc > 0.0001)
					concWv[RespInc] = GuessConc
				else
					concWv[RespInc] = NaN
				endif
				RespInc += 1
			while (RespInc < numResp)
		endif
	endif
	
	Killwaves /Z coefWv, errWv
	
end

function Poly3ForcedERR(a, b, Sx, Sy, aERR, bERR, abERR, respWv, yERR, sgn)
	variable a, b, Sx, Sy, aERR, bERR, abERR, respWv, yERR
	string sgn

end

proc ConcPlot(mol, attrib, flight)
	string mol=S_loadMol, attrib=S_attrib, flight=S_LoadFlight, units = "ppt"
	prompt mol, "Molecule?", popup, S_molLst
	prompt attrib, "Area or Hight concentration", popup, "Area;Hght"
	prompt flight, "Which flight?", popup, S_flightLst

	PauseUpdate; Silent 1		| building window...
	
	S_LoadFlight = flight
	S_LoadMol = mol
	S_attrib = attrib
	
	ConcPlotFUNCT(mol, attrib, flight)
end

function ConcPlotFUNCT(mol, attrib, flight)
	string mol, attrib, flight
	
	SVAR S_mission = S_mission
	
	string concWv = mol + "_" + attrib + "_conc_" + flight
	string precWv = mol + "_" + attrib + "_prec_" + flight
	string tsecsWv = "tsecs_" + flight
	string PlotName = flight + ": " + mol + " " + attrib + " Mixing Ratio"
	if (exists(concWv) == 1)
		string concWvNote = note($concWv)
	else
		print "You haven't calculated concentration for " + mol + "_" + attrib + "_" + flight + "."
		abort
	endif
	string calCurve = concWvNote[strsearch(concWvNote, "(", 0)+1, strsearch(concWvNote, ")", 0)-1]
	string com
	
	DoWindow/K $mol+"_"+flight+"_"+attrib+"_Plot"
	Display /K=1/W=(5,42,555,332) $concWv vs $tsecsWv as PlotName
	ModifyGraph gFont="Times",gfSize=14
	ModifyGraph mode=3, marker=19, grid=2, mirror=2, msize=2
	ErrorBars $concWv Y,wave=($precWv,$precWv)
	Label left "\\Z14" + FullMolName(mol)
	Label bottom "\\Z14Flight Time (kGMT seconds)"
	SetAxis/A/N=1 left
	sprintf com, "\\Z14\\f01%s:  %s\\f00", flight, S_mission
	Textbox/N=text0/F=0/S=3/B=1/A=MC/X=-17.29/Y=40.36 com
	sprintf com, "\\Z12Mixing ratio calculated from \\f01%s\\f00 response.\r   Cal curve: \\Z10%s", attrib, calCurve
	AppendText com
	DoWindow/C $mol+"_"+flight+"_"+attrib+"_Plot"
	
end



//*****************************  Exchange File Stuff ********************************//
function MakeExchageFiles() : Panel

	SVAR S_molLst = S_molLst
	
	string separator=";", mol, com
	variable numMols = NumElementsInList(S_molLst, separator), inc, oneRow=25

	StrMakeOrDefault("root:S_submitDate", "ALL DATES")
	StrMakeOrDefault("root:S_Mission", "STRAT")
	StrMakeOrDefault("root:S_Instrument", "ACATS IV, ER-2")
	StrMakeOrDefault("root:S_MF", "ppt;ppb;ppm;")
	
	if (exists("SubmitMethod") != 1)
		make /n=(numMols) SubmitMethod = 1
	endif
	
	DoWindow /K Submit_Panel
	NewPanel /W=(456,57,800,280+numMols*oneRow) as "Submit Panel"
	DoWindow /C Submit_Panel
	
	execute "ModifyPanel cbRGB=(65535,49151,55704)"
	SetDrawLayer UserBack
	SetDrawEnv fsize= 14,fstyle= 17
	DrawText 76,27,"Method"
	SetDrawEnv fsize= 14,fstyle= 17
	DrawText 174,26,"Sig Figs"
	SetDrawEnv fsize= 14,fstyle= 17
	DrawText 272,25,"Conc."

	SetDrawEnv fillfgc= (65535,16385,55749)
	DrawRect 93,70+numMols*oneRow,267,210+numMols*oneRow
	
	do
		mol = StringFromList(inc, S_molLst, separator)
		SetDrawEnv fstyle= 1
		DrawText 14,47+inc*oneRow, mol
		CheckBox $mol+"area",pos={60,30+inc*oneRow},size={50,20},proc=Submit_CheckProc,title="Area",value= (SubmitMethod[inc]==0)
		CheckBox $mol+"hght",pos={115,30+inc*oneRow},size={50,20},proc=Submit_CheckProc,title="Hght",value=(SubmitMethod[inc]==1)
	
		sprintf com, "%s_sigFigs", mol
		if (exists(com) != 2)
			sprintf com, "variable /g %s_sigFigs=1", mol; execute com
		endif
		SetVariable $mol+"sig",pos={189,31+inc*oneRow},size={50,17},title=" ", format="%d",limits={0,5,1},value=$mol+"_sigFigs"
		
		sprintf com, "%s_MC", mol
		if (exists(com) != 2)
			sprintf com, "variable /g %s_MC=1", mol; execute com
		endif
		sprintf com, "PopupMenu %s_MF,pos={270,%d},size={46,19},proc=Submit_PopMenuProc,mode=%s_MC,value=#S_MF", mol, 30+inc*oneRow, mol
		execute com
		inc += 1
	while (inc < numMols)
	
	Button Participants,pos={122,73+numMols*oneRow},size={123,20},proc=Submit_ButtonProc,title="Set participants"
	Button Comment,pos={131,94+numMols*oneRow},size={102,20},proc=Submit_ButtonProc,title="Set Comment"
	Button FlightComments,pos={127,115+numMols*oneRow},size={115,20},proc=SetFlightComment,title="Flight comments"
	Button MakeSubmit,pos={115,180+numMols*oneRow},size={136,20},proc=Submit_ButtonProc,title="Make Submit File"

	SetVariable mission,pos={122,139+numMols*oneRow},size={121,17},title="Mission", value=S_Mission
	SetVariable Instrument,pos={100,159+numMols*oneRow},size={163,17},title="Instrument", value=S_Instrument

	PopupMenu SubmitDates,pos={91,40+numMols*oneRow},size={155,19},proc=Submit_PopMenuProc,title="Submit Date: "
	PopupMenu SubmitDates,mode=1,value= "ALL DATES;"+S_flightLst

	setwindow Submit_Panel, hook=Submit_Hook
	
End

function Submit_Hook(infoStr)
	String infoStr

	if (strsearch(infoStr, "EVENT:activate", 0) > 0)
		SVAR S_molLst = S_molLst
		string separator=";", mol, com
		variable numMols = NumElementsInList(S_molLst, separator), inc, oneRow=25
		wave SubmitMethod = $"SubmitMethod"
		do
			mol = StringFromList(inc, S_molLst, separator)
			CheckBox $(mol+"area"),value=(SubmitMethod[inc]==0)
			CheckBox $(mol+"hght"),value=(SubmitMethod[inc]==1)
			inc += 1
		while (inc < numMols)
	endif
End

Function Submit_PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	if (cmpstr(ctrlName, "SubmitDates") == 0)
		SVAR S_submitDate = S_submitDate
		S_submitDate = popStr
	else
		string mol = ctrlName[0, strlen(ctrlName)-4], com
		sprintf com, "%s_MC = %d", mol, popNum
		execute com
	endif

End

Function Submit_CheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	variable last, molPos, area
	string mol, otherCtrlName
	SVAR S_molLst = S_molLst
	wave SubmitMethod = $"SubmitMethod"
	if (strsearch(ctrlName, "area", 0) > 0)
		last = strsearch(ctrlName, "area", 0)-1
		Area = 1
		otherCtrlName = "hght"
	else
		last = strsearch(ctrlName, "hght", 0)-1
		Area = 0
		otherCtrlName = "area"
	endif

	mol = ctrlName[0,last]
	molPos = ReturnListPosition(S_molLst, mol, ";")
	
	if ((area)*(checked))
		SubmitMethod[molPos] = 0
		CheckBox $(mol+otherCtrlName),value=0
	endif
	if ((area)*(!checked))
		SubmitMethod[molPos] = 1
		CheckBox $(mol+otherCtrlName),value=1
	endif
	if ((!area)*(checked))
		SubmitMethod[molPos] = 1
		CheckBox $(mol+otherCtrlName),value=0
	endif
	if ((!area)*(!checked))
		SubmitMethod[molPos] = 0
		CheckBox $(mol+otherCtrlName),value=1
	endif

End

Function Submit_ButtonProc(ctrlName) : ButtonControl
	String ctrlName

	if (cmpstr(ctrlName, "Participants") == 0)
		execute "EditParticipants()"
	endif

	if (cmpstr(ctrlName, "Comment") == 0)
		execute "EditComments()"
	endif
	
	if (cmpstr(ctrlName, "MakeSubmit") == 0)
		
		wave SubmitMethod = $"SubmitMethod"
		wave comments = $"comments"
		SVAR S_molLst = S_molLst,S_submitDate = S_submitDate,S_Participants = S_Participants,S_flightLst = S_flightLst
		variable NumLines
		
		if (cmpstr(S_submitDate, "ALL DATES") == 0)
			variable numFlights = NumElementsInList(S_flightLst, ";"), inc=0
			string flight
			
			do
				flight = StringFromList(inc, S_flightLst)
				NumLines = SubmitCheck(flight)
				//Write_SubmitFile(flight, S_molLst, S_Participants, comments, NumLines)
				PRsubmit(flight, S_molLst, S_Participants, comments, NumLines)
				inc += 1
			while (inc < NumFlights)
		else
			NumLines = SubmitCheck(S_submitDate)
			//Write_SubmitFile(S_submitDate, S_molLst, S_Participants, comments, NumLines)
			PRsubmit(S_submitDate, S_molLst, S_Participants, comments, NumLines)
		endif
	endif

End

function SubmitCheck(flight)
	string flight
	
	wave SubmitMethod = $"SubmitMethod"
	SVAR S_molLst = S_molLst
	SVAR S_submitDate = S_submitDate
	SVAR S_Participants = S_Participants
	
	variable inc, numMols = NumElementsInList(S_molLst, ";"), numlines, numlinesOLD
	string mol, conc, prec, attrib, tsecs

	// Check to see if all columns are there.
	do
		mol = StringFromList(inc,S_molLst)
		attrib = ReturnAttrib(SubmitMethod[inc])
		conc = mol + "_" + attrib + "_conc_" + flight
		prec = mol + "_" + attrib + "_prec_" + flight
		tsecs = "Tsecs_" + flight
		if (exists(tsecs) != 1)
			abort tsecs + " does not exist, can't make exchange file for " + flight + "."
		endif
		if (exists(conc) != 1)
			abort conc + " does not exist, can't make exchange file for " + flight + "."
		endif
		if (exists(prec) != 1)
			abort prec + " does not exist, can't make exchange file for " + flight + "."
		endif
		numlines = numpnts($conc)
		if (numlinesOLD == 0)
			numlinesOLD = numlines
		endif
		if (numlines != numlinesOLD)
			abort "The submit waves are not all the same length!"
		endif
		inc += 1
	while (inc < numMols)
	
	return NumLines
	
end


function/S ReturnAttrib (val)
	variable val
	
	if (val==0)
		return "Area"
	else
		return "Hght"
	endif
end
		

Function Write_SubmitFile(flight, molLst, people, comments, numlines)
	string flight, molLst, people
	wave/t comments
	variable numlines
	
	// Missing Values
	variable Mconc = 9999
	variable Mprec = 999,StartTime=Ticks
	
	SVAR S_Instrument = S_Instrument
	SVAR S_Participants = S_Participants
	SVAR S_Mission = S_Mission
	wave SubmitMethod = $"SubmitMethod"
	
	string mol, scale="", missing="", header = "GMTs ", attrib, conc, prec, tsecs, sigSTR, sigERRstr, DataLine, com
	variable handle, inc, lineinc
	variable NumMols = NumElementsInList(molLst, ";")
	variable NumCols = NumMols * 2
	variable NumComLines = NumComLinesFUNCT(comments)
	
	PathInfo ExchangeFilePath
	if (V_flag == 0)
		NewPath /M="Where would you like the exchange files?" ExchangeFilePath
	endif
	
	// Open exchange file.
	if (strsearch(UpperStr(S_Instrument), "ACATS", 0) >= 0)
		Open /C="R*ch"/P=ExchangeFilePath handle "GC"+flight+".EA1"
	else
		if (strsearch(UpperStr(S_Instrument), "LACE", 0) >= 0)
			Open /C="R*ch"/P=ExchangeFilePath handle "GC"+flight+".BA1"
		else
			abort "Could not find LACE or ACATS in the S_Instrument string."
		endif
	endif

	printf "Flight: %s started.\r", flight
	
	fprintf handle, "%d 1001\r", 15 + NumCols + NumComLines
	fprintf handle, S_Participants + "\r"
	fprintf handle, "U.S. DEPT OF COMMERCE, NOAA / CMDL / NITROUS OXIDE AND HALOCOMPOUNDS DIVISION\r"
	fprintf handle, S_Instrument + "\r"
	fprintf handle, S_Mission + "\r"
	fprintf handle, "1 1\r"
	fprintf handle, "%10s   %10s\r", "19"+flight[0,1]+" "+flight[2,3]+" "+flight[4,5], ACATSdate2(date())
	fprintf handle, "0 \r"
	fprintf handle, "ELAPSED TIME IN SECONDS FROM 00:00:00  GMT ON SAMPLE DATE\r"
	fprintf handle,  num2str(NumCols) + "\r"

	// The scale factors and missing value lines
	inc = 0
	do 
		scale += "1.0 1.0 "
		missing += "9999 999 "
		inc += 1
	while (inc < NumMols)
	fprintf handle, scale + "\r"
	fprintf handle, missing + "\r"
	
	// Molecule and error list and prepare header
	inc = 0
	do
		mol = StringFromList(inc, molLst)
		header += mol + " " + mol + "e "
		fprintf handle, "%-18s %-13s (%s)\r", FullMolName(mol), "MIXING RATIO", ReturnConcType(mol)
		fprintf handle, "%-18s %-13s (%s)\r", FullMolName(mol), "ERROR 1-sd", ReturnConcType(mol)
		inc += 1
	while (inc < NumMols)
	
	// The comment lines
	fprintf handle, num2str(NumComLines) + "\r"
	inc = 0
	do
		fprintf handle, "%s\r", comments[inc]
		inc += 1
	while (inc < NumComLines)
	
	// The data header
	fprintf handle, num2str(1) + "\r"
	fprintf handle, header + "\r"	
	
	// Print the Data
	inc = 0
	lineInc = 0
	do
		// Check for good row
		inc = 0
		do
			mol = StringFromList(inc, molLst)
			attrib = ReturnAttrib(SubmitMethod[inc])
			conc = mol + "_" + attrib + "_conc_" + flight
			wave concWv = $conc
			if (numtype(concWv[lineinc]) == 0 )
				// Write the data.
				tsecs = "Tsecs_" + flight
				wave tsecsWv = $tsecs
				sprintf DataLine, "%d ", tsecsWv[lineInc]
				inc = 0
				do
					mol = StringFromList(inc, molLst)
					attrib = ReturnAttrib(SubmitMethod[inc])
					conc = mol + "_" + attrib + "_conc_" + flight
					prec = mol + "_" + attrib + "_prec_" + flight
					wave concWv = $conc
					wave precWv = $prec
					sigSTR = ReturnSigStr(3, mol)
					sigERRstr = ReturnSigStr(0, mol)
					
					// Look for missing values
					if (numtype(concWv[lineInc]) == 2)
						sprintf com, "%d %d ", Mconc, Mprec
						DataLine += com			
					else
						sprintf com, "%s %s ", sigSTR, sigERRstr
						sprintf com, com, concWv[lineInc], precWv[lineInc]
						DataLine += com
					endif
						
					inc += 1
				while (inc < NumMols)
				inc = 0
				break
			endif
			inc += 1
		while (inc < NumMols)

		if (inc == 0) 
			fprintf handle, DataLine + "\r"	
		endif
		lineInc += 1
	while (lineInc < numLines)

	close handle
	printf "Flight: %s done in %2.2f seconds, old style.\r", flight,(Ticks-StartTime)/60.15

end

function/s ReturnSigStr(tens, mol)
	variable tens
	string mol
	
	string com
	sprintf com, "K0 = %s_SigFigs", mol
	execute com
		
	sprintf com, "%s%d.%sf", "%", tens, num2str(K0)
	return com
			
end
	


function/s ReturnConcType(mol)
	string mol
	
	string com
	sprintf com, "K0 = %s_MC", mol
	execute com

	if (K0 == 1)
		return "PPT"
	endif
	if (K0 == 2)
		return "PPB"
	endif
	if (K0 == 3)
		return "PPM"
	endif
end

function NumComLinesFUNCT(comments)
	wave/t comments
	
	variable inc, comLen = Numpnts(comments), lines
	do
		if (strlen(comments[inc]) > 0)
			lines += 1
		endif
		inc += 1
	while (inc < comLen)
	return lines
end
		
function/S ACATSdate2(today)
	String today
	today=date()
	String month, year, day
	variable index,len
	String Months="Jan;Feb;Mar;Apr;May;Jun;Jul;Aug;Sep;Oct;Nov;Dec;"
	String Month2Num="01;02;03;04;05;06;07;08;09;10;11;12"
	
	index = strsearch(today,",",0)
	if (index == -1)
		DoAlert 0, "String search failed: " + today
		return "YYYY MM DD"
	endif
	
	index += 2
	
	month = today[index,index+2]
	
	len = strsearch(today," ",index)
	if (len == -1)
		DoAlert 0, "String search failed: \"" + today[index + 4,strlen(today)-1] + "\""
		return "YYYY MM DD"
	endif
	
	index = strsearch(Months,month,0)
	if (index == -1)
		DoAlert 0, "String search failed: " + Months
		return "YYYY MM DD"
	endif
	
	index = floor((index + 1) / 4) * 3
	month = Month2Num[index,index+1]
	
	sprintf day,"%02d",str2num(today[len+1,len+2])
	
	index = strsearch(today,",",len)
	if (index == -1)
		DoAlert 0, "String search failed: \"" + today[len,strlen(today)-1] + "\""
		return "YYYY MM DD"
	endif
	
	year = today[index + 2,index + 6]
	
	return year + " " + month + " " + day
end

*****************************************************

//PAR, 2/10/1998
//This function writes the Submit file faster than the "Write_SubmitFile"
//A change is made to the "Submit_ButtonProc" to use "PRsubmit"

Function PRsubmit(flight, molLst, people, comments, numlines)
	string flight, molLst, people
	wave/t comments
	variable numlines
	
	// Missing Values
	variable Mconc = 9999,Mprec = 999,StartTime=Ticks
	
	SVAR S_Instrument = S_Instrument,S_Participants = S_Participants,S_Mission = S_Mission
	wave SubmitMethod = $"SubmitMethod"
		
	string mol, scale="", missing="", header = "GMTs ", attrib, conc, prec, tsecs, sigSTR, sigERRstr, DataLine, com
	variable handle, inc, MolPos
	variable NumMols = NumElementsInList(molLst, ";")
	variable NumCols = NumMols * 2
	variable NumComLines
	variable AddedFlightComment=0
			
		if(cmpstr(GetFlightComment(flight),"")!=0)
			NumComLines = NumComLinesFUNCT(comments)
			comments[NumComLines]=GetFlightComment(flight)
			AddedFlightComment=1 
		endif
			
	NumComLines = NumComLinesFUNCT(comments)
	
	PathInfo ExchangeFilePath
	if (V_flag == 0)
		NewPath /M="Where would you like the exchange files?" ExchangeFilePath
	endif
	
	// Open exchange file.
	if (strsearch(UpperStr(S_Instrument), "ACATS", 0) >= 0)
		Open /C="R*ch"/P=ExchangeFilePath handle "GC20"+flight+".ER2"
	else
		if (strsearch(UpperStr(S_Instrument), "LACE", 0) >= 0)
			Open /C="R*ch"/P=ExchangeFilePath handle "GC20"+flight+".OMS"
		else
			abort "Could not find LACE or ACATS in the S_Instrument string."
		endif
	endif

	printf "Flight %s started.\r", flight
	
	fprintf handle, "%d 1001\r", 15 + NumCols + NumComLines
	fprintf handle, S_Participants + "\r"
	fprintf handle, "U.S. DEPT OF COMMERCE, NOAA / CMDL / HALOCARBONS AND OTHER ATMOSPHERIC TRACE SPECIES GROUP\r"
	fprintf handle, S_Instrument + "\r"
	fprintf handle, S_Mission + "\r"
	fprintf handle, "1 1\r"
	fprintf handle, "%10s   %10s\r", "20"+flight[0,1]+" "+flight[2,3]+" "+flight[4,5], ACATSdate2(date())
	fprintf handle, "0 \r"
	fprintf handle, "ELAPSED TIME IN SECONDS FROM 00:00:00  GMT ON SAMPLE DATE\r"
	fprintf handle,  num2str(NumCols) + "\r"

	// The scale factors and missing value lines
	inc = 0
	do 
		scale += "1.0 1.0 "
		missing += "9999 999 "
		inc += 1
	while (inc < NumMols)
	fprintf handle, scale + "\r"
	fprintf handle, missing + "\r"
	
	// Molecule and error list and prepare header
	inc = 0
	do
		mol = StringFromList(inc, molLst)
		header += mol + " " + mol + "e "
		fprintf handle, "%-18s %-13s (%s)\r", FullMolName(mol), "MIXING RATIO", ReturnConcType(mol)
		fprintf handle, "%-18s %-13s (%s)\r", FullMolName(mol), "ERROR 1-sd", ReturnConcType(mol)
		inc += 1
	while (inc < NumMols)
	
	// The comment lines
	fprintf handle, num2str(NumComLines) + "\r"
	inc = 0
	do
		fprintf handle, "%s\r", comments[inc]
		inc += 1
	while (inc < NumComLines)
		if(AddedFlightComment)
			comments[NumComLines-1]=""
		endif
	
	// The data header
	fprintf handle, num2str(1) + "\r"
	fprintf handle, header + "\r"	
	
	// Up to here PRsubmit and Write_SubmitFile are identical. From here they are different.
	
			inc=0
			Duplicate /o $"Tsecs_"+flight $"TimeTmp"
			wave tsecsWv=$"TimeTmp"
			make /o/d/n=(numpnts(tsecsWv)) $"FlagWv"
			wave /d FlagWv=$"FlagWv"
			FlagWv=0
			
			//	Create flag wave to remove completely blank rows; make duplicate Conc and Prec waves.
			inc=0
			variable pos=0
			//String FormatStr="\"%d"		// These commented out lines improve performance x5. However, missing values are submitted with decimal zeros.
			//String NumSigFigsList="$\""+nameofwave(tsecsWv)+"\""
			do
				mol = StringFromList(inc,molLst)
				attrib = ReturnAttrib(SubmitMethod[inc])
				duplicate /o $mol+"_"+attrib+"_conc_"+flight $"C"+num2str(inc)
				wave concWv = $"C"+num2str(inc)
//GSD				FlagWv=xBitSet64(FlagWv,5*(numType(concWv)==0))	// All normal number points will have bit 5 set.
				
					//	Also, convenient place to clean up Conc,Prec waves to create temporary submit waves which will be then filtered using FlagWv:
					duplicate /o $mol+"_"+attrib+"_prec_"+flight $"P"+num2str(inc)
					wave precWv = $"P"+num2str(inc)
					pos=0
						//do
							//if(numType(concWv[pos]))	// Replace Nans with Missing Values:
								//concWv[pos]=Mconc
								//precWv[pos]=Mprec
							//endif
							//pos+=1
						//while(pos<numpnts(concWv))
				//NVAR NumSigFigs = $mol+"_sigFigs"
				//FormatStr+=" %."+num2istr(NumSigFigs)+"f %."+num2istr(NumSigFigs)+"f"
				//NumSigFigsList+=",$\""+NameOfWave(concWv)+"\",$\""+NameOfWave(precWv)+"\""
				inc += 1
			while (inc < NumMols)
//GSD			FlagWv=xBitClr64(FlagWv,0) 		// If all points in all Mol_conc waves are Nan, corresponding FlagWv point will be zero.
			//FormatStr+="\\r\""
			
		// Wipe out blank rows in all temporary submit waves using flag wave
		inc=0
		do
			if(FlagWv[inc]==0)
				pos=0
				do
					wave precWv=$"P"+num2str(pos)
					wave concWv=$"C"+num2str(pos)
					deletePoints inc,1,precWv,concWv
					pos+=1
				while(pos<NumMols)
				deletePoints inc,1,FlagWv,tsecsWv
			else
				inc+=1
			endif
		while(inc<numpnts(FlagWv))
		
	inc=0
	make /o/n=(numpnts(tsecsWv))/t $"SubmitWave"=num2istr(tsecsWv)
	wave /t Sw=$"SubmitWave"
		do
			pos=0
			wave precWv=$"P"+num2str(inc)
			wave concWv=$"C"+num2str(inc)
			do
				if(numType(concWv[pos]))	
					Sw[pos]+=" "+num2str(Mconc)+" "+num2str(Mprec)
				else
					mol = StringFromList(inc, molLst)
					NVAR NumSigFigs = $mol+"_sigFigs"
					String Temp
						if(!numType(precWv[pos]))
							sprintf Temp," %.*f %.*f",NumSigFigs,concWv[pos],NumSigFigs,precWv[pos]
						else
							sprintf Temp," %.*f %d",NumSigFigs,concWv[pos],Mprec
						endif
					Sw[pos]+=Temp
				endif
				pos+=1
			while(pos<numpnts(tsecsWv))
			inc+=1
		while(inc<NumMols)

	// Write submit file:
		
		wfprintf handle, "", Sw
		//sprintf com,"wfprintf %d,%s %s",handle,FormatStr,NumSigFigsList
		//execute com

	close handle
		pos=0
		do
			wave precWv=$"P"+num2str(pos)
			wave concWv=$"C"+num2str(pos)
			killwaves /z precWv,concWv
			pos+=1
		while(pos<NumMols)
		killwaves /z tsecsWv,Sw,FlagWv
	printf "Flight %s done in %2.2f seconds.\r", flight,(Ticks-StartTime)/60.15
end

*****************************************************

//Just a small utility to print the bit mask of a double-precision number.

Proc printBitMask (m)
	variable /d m
	silent 1;pauseupdate
	iterate (64)
		printf "%1d", xBitTst64 (m,63-i)
		if (mod (i+1,8) == 0)
			printf " "
		endif
	loop
	printf "\r"
end

*****************************************************

function /s GetFlightComment(Date)
String Date
Variable inc=0, pos=0
String Result=""
		// Check EachFlightComments. This wave is updated automatically for time shift.
		if(exists("EachFlightComments")==1)
			Wave /t EachFlightComments=$"EachFlightComments"
			do
				if(cmpstr(EachFlightComments[inc][0],Date)==0)
					Result=EachFlightComments[inc][1]
				break
				endif
				inc+=1
			while(inc<numpnts(EachFlightComments))
		endif
		
		// Check the third column of the TSBF. This is for manually eantered individual flight comments.
		if(exists("TimeShiftByFlight")==1)
			Wave /t TSBF = $"TimeShiftByFlight"
			do
				if(cmpstr(TSBF[pos][0],Date)==0)
					Result += " " + TSBF[pos][2]
					break
				endif
				pos+=1
			while(pos<numpnts(TSBF))
		endif
		
	return Result
end

*****************************************************

function SetFlightComment(butNm):	buttonControl
String butNm
SVAR G_flightList=G_flightList
string temp
variable NumFlights=numElementsInList(G_flightList,";"),inc=0, pos=0
		if(exists("EachFlightComments")!=1)
			make /t/n=(NumFlights,2) $"EachFlightComments"
		endif
		Wave /t EachFlightComments=$"EachFlightComments"
		redimension /n=(NumFlights,2) EachFlightComments
		do
		EachFlightComments[inc][0]=StringFromList(inc, G_flightList)
			if (exists("TimeShiftByFlight")==1) 
			wave /t TSBF = $"TimeShiftByFlight"
				do
					temp = TSBF[pos][0]
					if(cmpstr(temp, EachFlightComments[inc][0])==0) 
						String Shift_s="GMTs were shifted by subtracting ("+TSBF[pos][1]+") s."
						break
					else
						Shift_s = "GMTs not shifted for this flight."
					endif
					pos+=1
				while(pos<numpnts(TSBF))
			else
				Shift_s = "GMTs not shifted for this flight."
			endif
		pos = 0
		EachFlightComments[inc][1]= Shift_s
		inc+=1
		while(inc<NumFlights)
		edit EachFlightComments
end

*****************************************************

function ShiftTsecs(Date)
String Date
Variable inc=0
String TsecsNm
if (exists("TimeShiftByFlight")==1)
	Wave /t TSBF=$"TimeShiftByFlight"
	do
		if (cmpstr(Date, TSBF[inc][0])==0)
		TsecsNm = TSBF[inc][0]
		// Check if Tsecs was backed up. If yes, do not shift to avoid double-shifting.
		if (exists("Tsecs_"+TsecsNm+"_org")!=1)
			Wave TsecsWv = $"Tsecs_"+TsecsNm
			duplicate TsecsWv $"Tsecs_"+TsecsNm+"_org"
			TsecsWv -= str2num(TSBF[inc][1])
		else
			print "For "+Date+" Tsecs are already shifted."
		endif
		break
		endif
		inc+=1
	while (inc<50)
else
	print "No TSBF wave. Sorry."
endif
end

*****************************************************

// The following is for plotting concetration plots for posting on the board after a flight.
// We could post pretty much anything (just making sure it is on time), but we decided to post
// more or less accurate information.
// Take care that the _conc_ waves for the molecules of choice are existing, otherwise a random
// wave will be generated and posted :-)

function Flight_Profile(Mol, Date, Overplot, Right, Hour_Scale_On_Top, All_Mols)
string Mol, Date, All_Mols // All_Mols is used for multi-mol layouts for setting axes and legends.
Variable Overplot, Right, Hour_Scale_On_Top
variable MinHrs, MaxHrs, MinSecs, MaxSecs, i=0
Wave Time_wave = $"Tsecs_"+Date

	Wavestats /q Time_wave
	MinSecs = V_min
	MaxSecs = V_max
	MinHrs = floor(MinSecs/3600)
	MaxHrs = ceil(MaxSecs / 3600)
	
	SVAR S_molLst=S_molLst // This is the list of molecules in current experiment.

	if (MaxHrs - MinHrs > 9)
		DoAlert 0, "Flight is longer than 9 hours from nearest whole hour before takeoff.\rWill not fit in standard graph. Will make chopped plot."
	endif

	MaxHrs = MinHrs + 9

	MinSecs = MinHrs * 3600
	MaxSecs = MaxHrs * 3600
	
//	MakeColorWave(NumElementsInList(S_molLst, ";"))
	wave ColorWv = $"ColorWv"

	wave Curr_concWv = $Mol+"_hght_conc_"+Date
	
	if (Hour_Scale_On_Top) 
		duplicate /o Time_Wave $"Temp"
		wave Time_Wave = $"Temp"
		Time_Wave /= 3600
	endif
	
	if (Overplot) 
		if (Right) 
			if (Hour_Scale_On_Top) 
				AppendToGraph /R/T Curr_concWv vs Time_Wave
			else
				AppendToGraph /R Curr_concWv vs Time_Wave
			endif
		else
			if (Hour_Scale_On_Top) 
				AppendToGraph /T Curr_concWv vs Time_Wave
			else
				AppendToGraph Curr_concWv vs Time_Wave
			endif
		endif
	else
			if (Hour_Scale_On_Top) 
				if (Right) 
					Display /R/T Curr_concWv vs Time_Wave
					ModifyGraph mirror(right)=1
				else
					Display /T Curr_concWv vs Time_Wave
					ModifyGraph mirror(left)=1
				endif
				setAxis top MinHrs, MaxHrs
				Label top "UTC (hours)"
				ModifyGraph manTick(top)={MinHrs,1,0,0}, manMinor(top)={1,0}, width={perUnit,72,top}, mirror(top)=1
			else
				if (Right) 
					Display /R Curr_concWv vs Time_Wave
					ModifyGraph mirror(right)=1
				else
					Display Curr_concWv vs Time_Wave
					ModifyGraph mirror(left)=1
				endif
				setAxis bottom MinSecs, MaxSecs
				Label bottom "UTC (sec)"
				ModifyGraph manTick(bottom)={MinSecs,3600,0,0}, manMinor(bottom)={0,50}, mirror(bottom)=1, width={perUnit,0.020016,bottom}
			endif
	endif
	
	variable Location = WhichListItem(Mol, S_molLst, ";") // In case the molecule was had 0 position in the list.
	
	//Determine the ticks for vertical axes.  We'll have 7 tick labels on the axis.
	wavestats /q Curr_concWv
	variable Top_limit = (V_max / 6 + 10 - mod(V_max / 6, 10))*6
	if (V_max < 20) 
		Top_limit = (V_max / 6 + 2 - mod(V_max / 6, 2))*6
	endif
	
	ModifyGraph mode($Mol+"_hght_conc_"+Date)=4, marker($Mol+"_hght_conc_"+Date)=Location+1, lstyle($Mol+"_hght_conc_"+Date)=0
	ModifyGraph msize($Mol+"_hght_conc_"+Date)=2, gaps=0, fSize=9
	ModifyGraph rgb($Mol+"_hght_conc_"+Date)=(ColorWv[Location][0],ColorWv[Location][1],ColorWv[Location][2])
	ModifyGraph tick=2, grid=2, margin(left)=45, margin(right)=45

	string Active_Axis = "left"
		if (Right) 
			Label right Mol+" (ppt/ppb)"
			ModifyGraph minor(right)=1, manTick(Right)={0, Top_limit/6, 0, 0}
			setAxis right 0, Top_limit
			Active_Axis = "right"
		else
			Label left Mol+" (ppt/ppb)"
			ModifyGraph manTick(left)={0, Top_limit/6, 0, 0}, minor(left)=1
			setAxis left 0, Top_limit
		endif
		
		doWindow /c $Mol
		if (cmpstr(all_mols, "")) 
			Label $Active_Axis All_Mols
		endif
End

*****************************************************
// The following is for creating a layout of panels for posting on the wall after flight processing is over.

function Flight_Profile_Layout(the_Date)
String the_Date

Flight_Profile("F113", the_Date, 0, 0, 1, "")
Flight_Profile("MC", the_Date, 1, 1, 1, "CH3CCl3 (ppt)")
ModifyGraph lblMargin(right)=7
Flight_Profile("CT", the_Date, 1, 0, 1, "CFC-113, CCl4 (ppt)")
Legend
DoWindow /K ConcLayout1
execute "Layout/C=1/P=Landscape as \"ACATS-IV SOLVE part 1\""
Textbox/N=text0/A=MT/X=0 /Y=1 "\\JC\\Z14ACATS Elkins/Hurst/Romashkin"
AppendText /N=text0 "\Z12ER-2  Flight Date: " + the_Date + ", Revision Date: " + Date() + ", GC20" + the_Date + ".ER2"
String com
sprintf com, "%s(26,100,764,325)/O=1/F=0", "CT"
execute "AppendToLayout " + com
DoWindow /C ConcLayout1

Flight_Profile("F11", the_Date, 0, 0, 0, "")
Flight_Profile("N2O", the_Date, 1, 0, 0, "CFC-11 (ppt), N2O (ppb)")
Flight_Profile("F12", the_Date, 1, 1, 0, "CFC-12 (ppt)")
ModifyGraph lblMargin(right)=7, tlOffset(right)=-5
Legend
sprintf com, "%s(26,323,764,548)/O=1/F=0", "CF"
execute "AppendToLayout " + com

Flight_Profile("H2", the_Date, 0, 1, 1, "H2 (ppb)")
SetAxis right 400,700
ModifyGraph manTick(right)={0,50,0,0},manMinor(right)={0,0}, lblMargin(right)=7
Flight_Profile("CH4", the_Date, 1, 0, 1, "CH4 (ppb)")
SetAxis left 600,1800
ModifyGraph manTick(left)={0,200,0,0},manMinor(left)={0,0}
Legend
DoWindow /K ConcLayout2
execute "Layout/C=1/P=Landscape as \"ACATS-IV SOLVE part 2\""
Textbox/N=text0/A=MT/X=0 /Y=1 "\\JC\\Z14ACATS Elkins/Hurst/Romashkin"
AppendText /N=text0 "\Z12ER-2  Flight Date: " + the_Date + ", Revision Date: " + Date() + ", GC20" + the_Date + ".ER2"
sprintf com, "%s(26,100,764,325)/O=1/F=0", "CH4"
execute "AppendToLayout " + com
DoWindow /C ConcLayout2

Flight_Profile("SF6", the_Date, 0, 1, 0, "SF6, H1211 (ppt)")
Flight_Profile("H1211", the_Date, 1, 1, 0, "")
SetAxis right 0,6
ModifyGraph manTick(right)={0,1,0,0},manMinor(right)={0,0}, lblMargin(right)=7
Flight_Profile("CF", the_Date, 1, 0, 0, "CHCl3 (ppt)")
Legend
sprintf com, "%s(26,323,764,548)/O=1/F=0", "F12"
execute "AppendToLayout " + com

end

*****************************************************
|The following Proc is for calling Flight_Profile_Layout from the menu only.

Proc FlightProfileLayout(flight)
string flight
prompt flight, "Flight to lay out:", popup, S_flightlst
Flight_Profile_Layout(flight)
end

*****************************************************
