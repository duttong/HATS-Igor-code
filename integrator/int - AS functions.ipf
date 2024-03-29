#pragma rtGlobals=1		// Use modern global access method.


// Returns 1 if the chromNum is in the Chromatogram active set.
Function IsChromInAS(ch, chromNum)
	variable ch, chromNum
	
	wave AS = $("root:AS:CH"+num2str(ch)+"_AS")

	variable loc = BinarySearch(AS, chromNum)

	if ( ( loc >= 0 ) && ( chromNum == AS[loc] ) )
		return 1
	else
		return 0
	endif
		
end

// runtuns the row number of the CH#_All wave for a given chromNumber
Function ReturnResRowNumber( ch, chromNum )
	variable ch, chromNum
	
	if (( ch < 0 ) || (numtype(ch) != 0))
		return NaN
	endif
	
	wave ASall = $("root:AS:CH" + num2str(ch) + "_All")
	
	variable loc = BinarySearch(ASall, chromNum)

	if ( ( loc >= 0 ) && ( chromNum == ASall[loc] ) )
		return loc
	else
		return NaN
	endif
	
end


// returns the largest chrom number in AS
Function returnMAXchromNum(ch)
	variable ch
	
	string CHallstr = "root:AS:CH" + num2str(ch) + "_AS"
	if (exists(CHallstr) != 1)
		return 0
	endif

	wave CHall = $CHallstr

	return CHall[numpnts(CHall)-1]

end

// returns the largest chrom number in AS
Function returnMINchromNum(ch)
	variable ch
	
	string CHallstr = "root:AS:CH" + num2str(ch) + "_AS"
	if (exists(CHallstr) != 1)
		return 0
	endif
	
	wave CHall = $CHallstr

	return CHall[0]

end

// function creates chromatogram "active sets" which is a list of chrom numbers for each channel
Function CreateChromAS()

	NVAR chans = root:V_chans
	variable inc, ch, num
	String objName, wstr, ASstr
	
	SetDataFolder root:AS
	
	for ( inc=1; inc<=chans; inc+=1 )
		wstr = "CH" + num2str(inc) + "_All"
		make /n=(MAXCHROMS)/o $wstr=NaN
		wstr = "CH" + num2str(inc) + "_Manual"
		make /n=0 /o $wstr
		wstr = "CH" + num2str(inc) + "_Bad"
		make /n=0 /o $wstr
	endfor

	inc = 0
	do
		objName = GetIndexedObjName("root:chroms", 1, inc)
		if (strlen(objName) == 0)
			break
		endif
		if (( cmpstr(objName[0,2], "chr" ) == 0 ) && ( cmpstr(objName, "chromTmp" ) != 0 ))
			ch = str2num(objName[3,4])
			num = str2num(objName[5,10])
			wave w = $("CH" + num2str(ch) + "_All")
			w[num] = num
		endif
		inc += 1
	while(1)

	for ( inc=1; inc<=chans; inc+=1 )
		wstr = "CH" + num2str(inc) + "_All"
		ASstr = "CH" + num2str(inc) + "_AS"
		RemoveNaNs($wstr)
		duplicate /o $wstr, $ASstr
	endfor
	
	SetDataFolder root:

end


// makes CH#_Manual or CH#_Bad waves from the _flagMan or _flagBad waves
Function UpdateASwaves(type)
	variable type
	
	NVAR ch = root:V_currCh
	SVAR mol = root:S_currPeak
	
	string path = "root:AS:", ASstr
	wave All = $(path + "CH" + num2str(ch) + "_All")
	variable i, num = numpnts(All)
	
	// CH1_Manual	
	if ( type == 1 )
		wave flag = $mol + "_flagMan"
		ASstr = path + "CH" + num2str(ch) + "_Manual"
		make /o/n=0 $ASstr
		wave AS = $ASstr

		for(i=0; i<num; i+=1)
			if ( flag[i] )
				insertpoints numpnts(AS), 1, AS
				AS[numpnts(AS)] = All[i]
			endif
		endfor
	
	// CH1_Bad	
	elseif ( type == 2 )
		wave flag = $mol + "_flagBad"
		ASstr = path + "CH" + num2str(ch) + "_Bad"
		make /o/n=0 $ASstr
		wave AS = $ASstr

		for(i=0; i<num; i+=1)
			if ( flag[i] )
				insertpoints numpnts(AS), 1, AS
				AS[numpnts(AS)] = All[i]
			endif
		endfor
		
	elseif ( type == 9 )		// make both
		
		UpdateASwaves(1)
		UpdateASwaves(2)
		
	else
		return 0
	endif
	
end

// sets the AS wave to 
function SetASchroms(ASselect)
	variable ASselect
	
	NVAR chans = root:V_chans
	NVAR chromNum = root:V_chromNum
	NVAR currCh = root:V_currCh
	NVAR ASsel = root:V_ASselect
	
	variable chinc
	string CHAS, CHASw, path = "root:AS:"
	
	switch ( ASselect )
		case 1:
			ASsel = 1
			for ( chinc = 1; chinc <= chans; chinc += 1 )		
				CHAS =  path + "CH" + num2str(chinc) + "_AS"
				CHASw = path + "CH" + num2str(chinc) + "_All"
				duplicate /o $CHASw, $CHAS
			endfor
			break

		case 2:
			ASsel = 2
			for ( chinc = 1; chinc <= chans; chinc += 1 )		
				CHAS =  path + "CH" + num2str(chinc) + "_AS"
				CHASw = path + "CH" + num2str(chinc) + "_Manual"
				duplicate /o $CHASw, $CHAS
			endfor
			break

		case 3:
			ASsel = 3
			for ( chinc = 1; chinc <= chans; chinc += 1 )		
				CHAS =  path + "CH" + num2str(chinc) + "_AS"
				CHASw = path + "CH" + num2str(chinc) + "_Bad"
				duplicate /o $CHASw, $CHAS
			endfor
			break
			
	endswitch
	
	chromNum = NextChromInAS( currCh, chromNum, 0 )
	
end

// sets the AS to a selected selpos number
function SetASusingSelpos()
	
	NVAR ASsel = root:V_ASselect
	NVAR chans = root:V_chans
	NVAR chromNum = root:V_chromNum
	NVAR currCh = root:V_currCh
	
	wave selpos = root:selpos
	
	variable chinc, selposInc, i, oneSSV
	string CHAS, CHASall, path = "root:AS:"
	string SSVselected

	Prompt SSVselected, "Set AS to which selpos?", popup, selPosLst( 1 )
	DoPrompt "Choose a selpos", SSVselected

	if ( V_flag == 1 )	// cancel was pressed
		abort
	endif
	
	SelposInc = ItemsInList(SSVselected, ",")
	
	for ( chinc = 1; chinc <= chans; chinc += 1 )		
		CHAS =  path + "CH" + num2str(chinc) + "_AS"
		CHASall = path + "CH" + num2str(chinc) + "_All"
		duplicate /o $CHASall, $CHAS
		wave AS = $CHAS
		wave all = $CHASall
		AS = NaN
		for ( i = 0; i < SelposInc; i+= 1 )
			oneSSV = str2num(StringFromList(i, SSVselected, ","))
			AS = SelectNumber(selpos == oneSSV, AS, all)
		endfor
		RemoveNaNs(AS)
	endfor
	
	if (SelposInc == 1)
		ASsel = 4
	else
		ASsel = 5
	endif

end

// ch == channel, oldchromNum, upOrDown is +1 or -1 to increment in the AS wave
Function NextChromInAS(ch, oldchromNum, upOrDown )
	variable ch, oldchromNum, upOrDown
	
	string path = "root:AS:"
	
	wave AS = $(path + "CH" + num2str(ch) + "_AS")
	variable len = numpnts(AS)
	
	variable loc = BinarySearch(AS, oldChromNum)

	if ( loc == -1 )
		beep
		return AS[0]
	elseif ( loc == -2 )
		beep
		return AS[len - 1]
	elseif ( loc == -3 )
		beep
		return -1
	else
		// added the check 130124 GSD.  The recursive calls below would fail if loc was outside of AS range
		if (((loc+upOrDown) >= len) || (loc+upOrDown) < 0)
			return AS[loc]
		endif
		if (upOrDown==0)
			return AS[loc]
		endif
		// check to see if the chrom exists
		if ( WaveExists($"root:chroms:"+ChromName(ch, AS[loc + upOrDown])) )
			return AS[loc + upOrDown]
		else
			return NextChromInAS(ch, AS[loc + upOrDown], upOrDown )
		endif
	endif
	
end


// returns MOL_Start for a given molecule.  If this value is NAN, DB_expStart is used.  This function also takes into account the start point
// assigned via DB_peakStart if useDBpoints is 1
function ReturnPeakStartPtnoNAN(mol, chromNum, useDBpoints)
	string mol
	variable chromNum, useDBpoints

	wave DBexpStart = root:DB:DB_expStart
	wave DBexpStop = root:DB:DB_expStop
	wave /t DBpeakStart = root:DB:DB_peakStart
	wave /t DBpeakStop = root:DB:DB_peakStop
	
	string peakPt, peakPtMol, peakPtLoc
	variable start, ResRow
	variable ch = ReturnChannel(mol)
	
	// get peak starting point defined in DB_peakStart
	peakPt = DBpeakStart[returnMolDBrow(mol)]			// ie  N2O_Start
	peakPtMol = StringFromList(0, peakPt, "_")			// ie  N2O
	peakPtLoc = StringFromList(1, peakPt, "_")			// ie  Start

	wave pkStart = $("root:" + peakPt)
	ResRow = ReturnResRowNumber( ch, chromNum )

	// if useDBpoints is false, then return the MOL_Start value, doesn't look at the DB_peakStart wave.
	if ( ! useDBpoints )
		if ( numtype(pkStart[ResRow]) == 0 )
			start = pkStart[ResRow]
		else
			start = DBexpStart[returnMolDBrow(mol)]
		endif
		return start
	endif

	if ( numtype(pkStart[ResRow]) == 0 )
		start = pkStart[ResRow]
	elseif ( cmpstr(peakPtLoc, "Start") == 0)
		start = DBexpStart[returnMolDBrow(peakPtMol)]
	else
		start = DBexpStop[returnMolDBrow(peakPtMol)]
	endif
	
	return start
	
end

// returns MOL_Start for a given molecule.   This function also takes into account the start point
// assigned via DB_peakStart
function ReturnPeakStartPt(mol, chromNum)
	string mol
	variable chromNum

	variable ch = ReturnChannel(mol)
	wave DBexpStart = root:DB:DB_expStart
	wave DBexpStop = root:DB:DB_expStop
	wave /t DBpeakStart = root:DB:DB_peakStart
	wave /t DBpeakStop = root:DB:DB_peakStop
	
	string peakPt, peakPtMol, peakPtLoc
	variable start, ResRow
	
	// get peak starting point defined in DB_peakStart
	peakPt = DBpeakStart[returnMolDBrow(mol)]			// ie  N2O_Start
	peakPtMol = StringFromList(0, peakPt, "_")			// ie  N2O
	peakPtLoc = StringFromList(1, peakPt, "_")			// ie  Start

	if (exists("root:" + peakPt) == 0)
		return NaN
	endif
	wave pkStart = $("root:" + peakPt)
	ResRow = ReturnResRowNumber( ch, chromNum )

	return pkStart[ResRow]
	
end


// returns MOL_Stop for a given molecule.  If this value is NAN, DB_expStop is used.  This function also takes into account the Stop point
// assigned via DB_peakStop
function ReturnPeakStopPtnoNAN(mol, chromNum, useDBpoints)
	string mol
	variable chromNum, useDBpoints

	wave DBexpStart = root:DB:DB_expStart
	wave DBexpStop = root:DB:DB_expStop
	wave /t DBpeakStop = root:DB:DB_peakStop
	wave /t DBpeakStart = root:DB:DB_peakStart
	
	string peakPt, peakPtMol, peakPtLoc
	variable Stop, ResRow
	variable ch = ReturnChannel(mol)
	

	// get peak Stoping point defined in DB_peakStop
	peakPt = DBpeakStop[returnMolDBrow(mol)]			// ie  N2O_Stop
	peakPtMol = StringFromList(0, peakPt, "_")			// ie  N2O
	peakPtLoc = StringFromList(1, peakPt, "_")			// ie  Stop
	
	wave pkStop = $("root:" + peakPt)
	ResRow = ReturnResRowNumber( ch, chromNum )

	// if useDBpoints is false, then return the MOL_Stop value, don't look at the DB_peakStop wave.
	if ( ! useDBpoints )
		if ( numtype(pkStop[ResRow]) == 0 )
			Stop = pkStop[ResRow]
		else
			Stop = DBexpStop[returnMolDBrow(mol)]
		endif
		return Stop
	endif
	
	if ( numtype(pkStop[ResRow]) == 0 )
		Stop = pkStop[ResRow]
	elseif ( cmpstr(peakPtLoc, "Start") == 0)
		Stop = DBexpStart[returnMolDBrow(peakPtMol)]
	else
		Stop = DBexpStop[returnMolDBrow(peakPtMol)]
	endif
	
	return Stop
	
end


// returns MOL_Stop for a given molecule.  This function also takes into account the Stop point
// assigned via DB_peakStop
function ReturnPeakStopPt(mol, chromNum)
	string mol
	variable chromNum

	variable ch = ReturnChannel(mol)
	wave DBexpStart = root:DB:DB_expStart
	wave DBexpStop = root:DB:DB_expStop
	wave /t DBpeakStop = root:DB:DB_peakStop
	wave /t DBpeakStart = root:DB:DB_peakStart
	
	string peakPt, peakPtMol, peakPtLoc
	variable Stop, ResRow
	
	// get peak Stoping point defined in DB_peakStop
	peakPt = DBpeakStop[returnMolDBrow(mol)]			// ie  N2O_Stop
	peakPtMol = StringFromList(0, peakPt, "_")			// ie  N2O
	peakPtLoc = StringFromList(1, peakPt, "_")			// ie  Stop
	
	if (exists("root:" + peakPt) == 0)
		return NaN
	endif
	wave pkStop = $("root:" + peakPt)
	ResRow = ReturnResRowNumber( ch, chromNum )

	return pkStop[ResRow]
	
end


// returns channel number for a choosen molcule
Function ReturnChannel(mol)
	string mol
	
	variable inc=0, loc = -1
	wave /t DBmols = root:DB:DB_mols
	wave DBchans = root:DB:DB_chan
	
	for( inc=0; inc < numpnts(DBmols); inc += 1)
		if (cmpstr(DBmols[inc], mol) == 0 )
			loc = inc
			break
		endif
	endfor
	
	if ( loc == -1 )
		return -9
	else
		return DBchans[loc]
	endif
	
end

// Returns the database row the molecule is listed in.
Function returnMolDBrow(mol)
	string mol
	
	variable inc=0, loc = -1
	wave /t DBmols = $"root:DB:DB_mols"
	
	do
		if (cmpstr(DBmols[inc], mol) == 0 )
			loc = inc
			break
		endif
		inc += 1
	while (inc < numpnts(DBmols))
	
	return loc

end

Function SetDBvars(mol)
	string mol
	
	NVAR all = root:DB:V_allpeaks
	NVAR currCh = root:DB:V_currCh
	NVAR currMolRow = root:DB:V_currMolRow
	SVAR currMol = root:DB:S_currMol
	SVAR currPeak = root:S_currPeak
	SVAR normPeak = root:norm:S_normPeak
	Wave active = root:DB:DB_activePeak
	
	currMol = mol
	currPeak = mol
	normPeak = mol
	currMolRow = returnMolDBrow(mol)
	currCh = ReturnChannel(mol)	

	all = 0
	active = 0
	active[currMolRow] = 1

end
// function switches between selposGC and selposPAN if these waves exist
function SelectSelpos()

	SVAR currPeak = root:S_currPeak
	NVAR currCh = root:V_currCh
	wave selpos = root:selpos

	currCh = ReturnChannel(currPeak)

	if (WaveExists($"root:selposPAN"))
		wave selposPAN = root:selposPAN
		wave selposGC = root:selposGC
		if (cmpstr(currPeak, "PAN") == 0 )
			selpos = selposPAN
		else
			selpos = selposGC
		endif
	endif

end

// function returns a list of selpos positions
// saves the list to S_selposLst for speed call function with remake == 0
function/t SelposLst( remake )
	variable remake

	if (exists("root:DB:V_shortLst") == 0)
		Variable /G root:DB:V_shortLst = 0
	endif

	SVAR inst = root:S_instrument
	NVAR shortlst = root:DB:V_shortLst
	SVAR/Z PANtype = root:S_PANTHERtype
	
	wave selpos = root:selpos
	string lst = "", lstL = "", lstH = "",  ssv
	variable inc

	if ((exists("root:S_selposLst") == 0) || ( remake ))
		String /G root:S_selposLst = ""
		remake = 1
	endif
	SVAR /Z ssvLst = root:S_selposLst

	if ( remake )
		for (inc=0; inc<numpnts(selpos); inc+= 1) 
			ssv = num2str(selpos[inc])
			if ( FindListItem(ssv, lst) == -1 )
				lst = AddListItem(ssv, lst)
			endif
		endfor
		ssvLst = SortList(lst, ";", 2)
	endif
	
	// make below and above 10 lists for PANTHER (used for two separate MSD traps)
	if (( cmpstr(inst, "PANTHER") == 0) && (shortLst == 0) && (cmpstr(PANtype,"MSD") == 0))
		return ssvLst + "1,3;1,11;3,13;11,13"
	else
		return ssvLst
	endif
end


// uses the current AS and returns chrom num
Function RetFirstUnflaggedChrom( mol )
	string mol
	
	variable ch = ReturnChannel( mol ), i, ResRow, found = 0
	
	wave AS = $("root:AS:CH" + num2str(ch) + "_AS")
	wave bad = $("root:" + mol + "_flagBad")
	wave man = $("root:" + mol + "_flagMan")
	
	for( i=0; i<= numpnts(AS); i+=1 )
		ResRow = ReturnResRowNumber(ch, AS[i])
		if ( bad[ResRow] != 1 && man[ResRow] != 1 )
			found  = 1
			break
		endif	
	endfor
	
	if ( found )
		return AS[i]
	else
		return NaN
	endif
end

// uses the current AS and returns chrom num
Function RetLastUnflaggedChrom( mol )
	string mol
	
	variable ch = ReturnChannel( mol ), i, ResRow, found = 0
	
	wave AS = $("root:AS:CH" + num2str(ch) + "_AS")
	wave bad = $("root:" + mol + "_flagBad")
	wave man = $("root:" + mol + "_flagMan")
	
	for( i=numpnts(AS)-1; i>=0; i-=1 )
		ResRow = ReturnResRowNumber(ch, AS[i])
		if ( bad[ResRow] != 1 && man[ResRow] != 1 )
			found  = 1
			break
		endif	
	endfor
	
	if ( found )
		return AS[i]
	else
		return NaN
	endif
end


// uses the current AS wave and selects the closets ret prior to chrmnm
// used to handle drifting peaks.
Function MostRecentRet(mol, chrNum)
	string mol
	variable chrNum
	
	variable ch = ReturnChannel( mol )
	
	wave AS = $("root:AS:CH" + num2str(ch) + "_AS")
	wave bad = $("root:" + mol + "_flagBad")
	wave man = $("root:" + mol + "_flagMan")			// currently not allowing the use of man
	wave ret = $("root:" + mol + "_ret")
	
	variable pt = BinarySearch(AS, chrNum), ResRow, i
	
	for( i=pt; i>0; i-=1 )
		ResRow = ReturnResRowNumber( ch, AS[i-1] )
		if ( (bad[ResRow] == 0)  && (numtype(ret[ResRow]) == 0) && (man[ResRow] == 0))
			return ret[ResRow]
		endif
	endfor

	return NaN
		
end