#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1
#pragma versoin=1.3

// version 1.1: Added support for PANTHER_GC and PANTHER_MSD  160726
// version 1.2: Added G_suffix to variable names.  160907
// version 1.3: Addded Mission suffix (G_missionsuffix). Allow rev numbers to be letters now. RA, RB, etc. 20210628


// Datasets coded below to work with ICARTT file format
strconstant kDsets="UCATS_H2O;UCATS_O3;UCATS_GC;PANTHER_GC;PANTHER_MSD"
static strconstant kmissingvalue= "-99999"

Menu "Macros"
	"-"
	"ICARTT Panel", ICARTT_Data_panel()
	"-"
End

function ICARTT_Init()

	SetDataFolder root:
	
	Variable i
	
	// data folders for ICARTT projects.
	For(i=0; i<ItemsInList(kDsets); i+=1)
		ICARTT_init_one(StringFromList(i, kDsets))
	endfor

end

function ICARTT_init_one(df)
	string df
	
	SetDataFolder root:
	NewDataFolder /O/S ICARTT
	
	// Global variable to keep track of ICARTT datafolder for selected dataset.
	if (exists("root:ICARTT:G_ICARTTdf") != 2)
		String /G G_ICARTTdf = "root:ICARTT:UCATS_H2O"
	endif

	If (exists("root:ICARTT:G_datasetloc") != 2)	
		Variable /G root:ICARTT:G_datasetloc = 1
	endif
	
	if (exists("root:ICARTT:G_usefltlst") != 2)
		Variable /G root:ICARTT:G_usefltlst = 0
	endif

	NewDataFolder /O/S $df
	
	// Added G_suffix string  160907 GSD
	if (exists("G_suffix") == 0 )
		String /G G_Suffix = ""
	endif
	
	// DCOTSS update 210628 GSD
	if (exists("G_missionsuffix") == 0)
		String /G G_missionsuffix = "2021"
		String /G G_rev = "R0"
		Killvariables /Z G_revNum
	endif	
	
	If (exists("G_mission") != 2)
		String /G G_mission = "DCOTSS"
		String /G G_platform = "ER2"
		String /G G_flightdate = "20130101"
		String /G G_datadate = "20130101"
		if (cmpstr(df, "UCATS_H2O") == 0)
			String /G G_inst = "UCATS"
			String /G G_varlist = "Time_Stop;H2O;H2Oe"
			String /G G_suffix = "_UCATS"
			String /G G_filename = G_mission + "-" + G_inst + "-H2O_" + G_platform + "_" + G_flightdate + "_" + G_rev + ".ict"
		elseif (cmpstr(df, "UCATS_O3") == 0)
			String /G G_inst = "UCATS"
			String /G G_varlist = "Time_Stop;O3;O3e"
			String /G G_suffix = "_UCATS"
			String /G G_filename = G_mission + "-" + G_inst + "-O3_" + G_platform + "_" + G_flightdate + "_" + G_rev + ".ict"
		elseif (cmpstr(df, "UCATS_GC") == 0)
			String /G G_inst = "UCATS"
			String /G G_varlist = "var1;var1_sd;var2;var2_sd;var3;var3_sd;var4;var4_sd"
			String /G G_suffix = "_UCATS"
			String /G G_filename = G_mission + "-" + G_inst + "-GC_" + G_platform + "_" + G_flightdate + "_" + G_rev + ".ict"
		elseif (cmpstr(df, "PANTHER_GC") == 0)
			String /G G_inst = "PANTHER"
			String /G G_varlist = "var1;var1_sd;var2;var2_sd;var3;var3_sd;var4;var4_sd"
			String /G G_suffix = "_PE"
			String /G G_filename = G_inst + "-GC_" + G_platform + "_" + G_flightdate + "_" + G_rev + ".ict"
		elseif (cmpstr(df, "PANTHER_MSD") == 0)
			String /G G_inst = "PANTHER"
			String /G G_varlist = "var1;var1_sd;var2;var2_sd;var3;var3_sd;var4;var4_sd"
			String /G G_suffix = "_PM"
			String /G G_filename = G_inst + "-MSD_" + G_platform + "_" + G_flightdate + "_" + G_rev + ".ict"
		else
			String /G G_varlist = "var1;var1_sd;var2;var2_sd;var3;var3_sd;var4;var4_sd"
			String /G G_suffix = ""
		endif
		
		Make /T/n=1 rev_comments
		Make /T/n=2 personnel, comments, meta
		personnel[0] = "MOORE, FRED; HINTSA, ERIC; NANCE, DAVID; DUTTON, GEOFF; HALL, BRAD; ELKINS, JAMES"
		personnel[1] = "CIRES, University of Colorado and NOAA/ESRL/GMD"

	endif
	
	SetDataFolder root:
end


Proc ICARTT_Data_panel()

	if (strsearch(WinList("*",";","WIN:64"), "ICARTT_Panel", 0) != -1)
		DoWindow /K ICARTT_Panel
	endif

	ICARTT_init()
	
	DoWindow /K ICARTT_Panel
	ICARTT_panel_create()
	DoWindow /C ICARTT_Panel
	ICARTT_Refresh()
	
end

Window ICARTT_Panel_create() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(488,48,851,485) as "ICARTT"
	ModifyPanel cbRGB=(49151,60031,65535), frameStyle=4, frameInset=2
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (49151,65535,57456)
	DrawRect 37,183,327,244
	SetDrawEnv fillfgc= (49151,65535,57456)
	DrawRect 36,249,327,334
	SetDrawEnv fillfgc= (49151,65535,57456)
	DrawRect 37,89,328,178
	PopupMenu dataset,pos={12.00,14.00},size={147.00,23.00},proc=ICARTT_PopMenuProc,title="Dataset: "
	PopupMenu dataset,help={"Select a data set to create an ICARTT file."},fSize=12
	PopupMenu dataset,mode=2,popvalue="UCATS_O3",value= #"kDsets"
	Button button_edit1,pos={44.00,257.00},size={115.00,20.00},proc=ICARTT_ButtonProc,title="Edit Personnel"
	Button button_edit2,pos={44.00,282.00},size={115.00,20.00},proc=ICARTT_ButtonProc,title="Edit Comments"
	Button button_edit3,pos={44.00,306.00},size={115.00,20.00},proc=ICARTT_ButtonProc,title="Edit Meta Data"
	SetVariable mission,pos={214.00,11.00},size={122.00,18.00},bodyWidth=75,proc=ICARTT_SetVarProc,title="Mission"
	SetVariable mission,help={"Name of science mission."},fSize=12
	SetVariable mission,value= root:ICARTT:UCATS_O3:G_mission
	SetVariable flightdate,pos={102.00,190.00},size={141.00,18.00},bodyWidth=75,proc=ICARTT_SetVarProc,title="Flight Date"
	SetVariable flightdate,fSize=12,value= root:ICARTT:UCATS_O3:G_flightdate
	SetVariable flightdate1,pos={68.00,217.00},size={174.00,18.00},bodyWidth=75,proc=ICARTT_SetVarProc,title="Submission Date"
	SetVariable flightdate1,fSize=12,value= root:ICARTT:UCATS_O3:G_datadate
	Button today,pos={251.00,217.00},size={40.00,20.00},proc=ICARTT_ButtonProc,title="today"
	Button today,help={"Click to set submission date to today's date."},fSize=10
	PopupMenu RevNum,pos={182.00,268.00},size={123.00,23.00},proc=ICARTT_PopMenuProc,title="Revision Number"
	PopupMenu RevNum,mode=12,popvalue="RA",value= #"\"R0;R1;R2;R3;R4;R5;R6;R7;R8;R9;RA;RB;RC;RD;RE;RF\""
	Button button_edit4,pos={170.00,293.00},size={150.00,20.00},proc=ICARTT_ButtonProc,title="Edit Rev Comments"
	SetVariable varlist,pos={42.00,99.00},size={280.00,18.00},bodyWidth=220,proc=ICARTT_SetVarProc,title="Variables:"
	SetVariable varlist,fSize=12,value= root:ICARTT:UCATS_O3:G_varlist
	SetVariable Suffix,pos={61.00,123.00},size={140.00,18.00},bodyWidth=100,proc=ICARTT_SetVarProc,title="Suffix:"
	SetVariable Suffix,fSize=12,value= root:ICARTT:UCATS_O3:G_Suffix
	Button writefile,pos={39.00,398.00},size={100.00,20.00},proc=ICARTT_ButtonProc,title="Write File"
	Button writefile,help={"Push this button to create an ICARTT data file with the selected revision number."}
	Button writefile,fColor=(3,52428,1)
	SetVariable platform,pos={209.00,61.00},size={127.00,18.00},bodyWidth=75,proc=ICARTT_SetVarProc,title="Platform"
	SetVariable platform,help={"The platform the instrument acquired data on.  This is used in the ICARTT file name."}
	SetVariable platform,fSize=12,value= root:ICARTT:UCATS_O3:G_platform
	SetVariable filename,pos={38.00,374.00},size={293.00,16.00},disable=2,title="Filename:"
	SetVariable filename,help={"Name of the ICARTT file to be created when \"write file\" button is pushed."}
	SetVariable filename,fSize=10,value= root:ICARTT:UCATS_O3:G_filename
	Button button_edit5,pos={91.00,151.00},size={180.00,20.00},proc=ICARTT_ButtonProc,title="Edit Variable Comments"
	Button prepare,pos={39.00,349.00},size={100.00,20.00},proc=ICARTT_ButtonProc,title="Prepare Data"
	Button prepare,help={"Push this button to run preparation function for dataset."}
	Button prepare,fColor=(65535,65534,49151)
	CheckBox use_fltlst,pos={247.00,400.00},size={80.00,16.00},title="Use flight list?"
	CheckBox use_fltlst,help={"When toggled the flights defined in the Post Processing Panel are used."}
	CheckBox use_fltlst,variable= root:ICARTT:G_usefltlst,side= 1
	SetVariable mission_suffix,pos={178.00,36.00},size={158.00,18.00},bodyWidth=75,proc=ICARTT_SetVarProc,title="Mission Suffix"
	SetVariable mission_suffix,help={"Name of science mission."},fSize=12
	SetVariable mission_suffix,value= root:ICARTT:UCATS_O3:G_mission
EndMacro

Function ICARTT_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	SVAR df = root:ICARTT:G_ICARTTdf
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			if (cmpstr(ba.ctrlName, "today")==0)
				DataDate_today()
			elseif (cmpstr(ba.ctrlName, "button_edit1")==0)
				EditPersonnel()
			elseif (cmpstr(ba.ctrlName, "button_edit2")==0)
				EditComments()
			elseif (cmpstr(ba.ctrlName, "button_edit3")==0)
				EditMeta()
			elseif (cmpstr(ba.ctrlName, "button_edit4")==0)
				EditRevComments()
			elseif (cmpstr(ba.ctrlName, "button_edit5")==0)
				EditVarComments()
			elseif (cmpstr(ba.ctrlName, "prepare")==0)
				if (strsearch(df, "UCATS_O3", 0) !=-1 )
					PrepareUCATSozone()
				elseif (strsearch(df, "UCATS_H2O", 0) !=-1 )
					PrepareUCATSh2o()
				endif
			elseif (cmpstr(ba.ctrlName, "writefile")==0)
				if (strsearch(df, "_GC", 0) !=-1 )
#if Exists("ReturnSelectedFlights")
					NVAR /Z usefltlst = root:ICARTT:G_usefltlst
					SVAR flt = $df+":G_flightdate"
					if (usefltlst)
						String flights = ReturnSelectedFlights()
						Variable i
						for(i=0;i<ItemsInList(flights);i+=1)
							flt = StringFromList(i, flights)
							WriteICARTTfile()
						endfor
					else
						WriteICARTTfile()
					endif
#else
					WriteICARTTfile()
#endif
				else
					WriteICARTTfile()
				endif
			else
				print "Strange button pressed?"
			endif
			break
			
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function DataDate_today()
	SVAR df = root:ICARTT:G_ICARTTdf
	string tmp = Secs2Date(DateTime,-2,"/")
	tmp = ReplaceString("/", tmp, "")
	SVAR dd = $df + ":G_datadate"
	dd = tmp
end

Function ICARTT_PopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	
	SVAR df = root:ICARTT:G_ICARTTdf
	string basedf = "root:ICARTT:"
	NVAR loc = $basedf+"G_datasetloc"

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr

			if (cmpstr(popStr, "UCATS_H2O") == 0)
				df = basedf + "UCATS_H2O"
				loc = 1
			elseif (cmpstr(popStr, "UCATS_O3") == 0)
				df = basedf + "UCATS_O3"
				loc = 2
			elseif (cmpstr(popStr, "UCATS_GC") == 0)
				df = basedf + "UCATS_GC"
				loc = 3
			elseif (cmpstr(popStr, "PANTHER_GC") == 0)
				df = basedf + "PANTHER_GC"
				loc = 4
			elseif (cmpstr(popStr, "PANTHER_MSD") == 0)
				df = basedf + "PANTHER_MSD"
				loc = 5
			elseif(cmpstr(pa.ctrlName, "RevNum") == 0)
				SVAR rev = $df+":G_rev"
				rev = pa.popStr
			else
				Print "Unknow popup: " + popStr
			endif
			break
			
		case -1: // control being killed
			break
	endswitch

	ICARTT_Refresh()

	return 0
End

Function ICARTT_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			break
		case -1: // control being killed
			break
	endswitch
	
	ICARTT_Refresh()

	return 0
End

// used to refresh the values in the ICARTT panel
Function ICARTT_Refresh()

	SVAR df = root:ICARTT:G_ICARTTdf
	NVAR loc = root:ICARTT:G_datasetloc
	
	// Only run refresh if the ICARTT panel is open
	if (strsearch(WinList("*",";","WIN:64"), "ICARTT_Panel", 0) == -1)
		return 0
	endif
	DoWindow /F ICARTT_Panel
	DoUpdate
	
	SetDataFolder $df
	//SVAR rev = G_rev
	
	SetVariable mission,value=G_mission
	SetVariable mission_suffix,value=G_missionsuffix
	SetVariable flightdate,value=G_flightdate
	SetVariable flightdate1,value=G_datadate
	SetVariable varlist,value=G_varlist
	SetVariable platform,value=G_platform
	SetVariable suffix,value=G_Suffix
	PopupMenu dataset,mode=loc
	//PopupMenu RevNum,mode=G_rev
	SetVariable filename,value= G_filename
	
	if ((strsearch(df, "_GC", 0) != -1) || (strsearch(df, "_MSD", 0) != -1))
		CheckBox use_fltlst disable=0
		Button prepare disable=1
	else 
		CheckBox use_fltlst disable=1
		Button prepare disable=0
	endif
	
	UpdateFilename()
	
	SetDatafolder root:
	
end

// updates the ICARTT filename for a particular dataset (loc)
Function UpdateFilename()

	SVAR df = root:ICARTT:G_ICARTTdf
	NVAR loc = root:ICARTT:G_datasetloc

	SetDataFolder $df
	SVAR file = G_filename
	SVAR mission = G_mission
	SVAR inst = G_inst
	SVAR plat = G_platform
	SVAR fltd = G_flightdate
	SVAR /Z rev = G_rev
	if (!SVAR_exists(rev))
		file = "refresh-panel"
		return -1
	endif

	switch(loc)
		case 1:
			file = mission + "-" + inst + "-H2O_" + plat + "_" + fltd + "_" + rev + ".ict"
			break
		case 2:
			file = mission + "-" + inst + "-O3_" + plat + "_" + fltd + "_" + rev + ".ict"
			break
		case 3:
			file = mission + "-" + inst + "-GC_" + plat + "_" + fltd + "_" + rev + ".ict"
			break
		case 4:
			file = "GCECD_" + plat + "_" + fltd + "_" + rev + ".ict"
			break
		case 5:
			file = "GCMSD_" + plat + "_" + fltd + "_" + rev + ".ict"
			break
	endswitch
	
	SetDataFolder root:

end

Function EditPersonnel()

	SVAR df = root:ICARTT:G_ICARTTdf
	String sub = df[strsearch(df, ":", Inf,1)+1,Inf]
	String win = sub + "_Personnel"
	
	SetDataFolder $df
	DoWindow /K $win
	Edit/k=1/W=(5,44,710,200) personnel as sub + " Personnel"
	DoWindow /C $win
	ModifyTable format(Point)=1,alignment(personnel)=0,width(personnel)=600
	SetDataFolder root:
	
End

Function EditComments()

	SVAR df = root:ICARTT:G_ICARTTdf
	String sub = df[strsearch(df, ":", Inf,1)+1,Inf]
	String win = sub + "_Comments"
	
	SetDataFolder $df
	DoWindow /K $win
	Edit/k=1/W=(5,44,710,400) comments as sub + " Comments"
	DoWindow /C $win
	ModifyTable format(Point)=1,alignment(comments)=0,width(comments)=600
	SetDataFolder root:
	
End

Function EditMeta()

	SVAR df = root:ICARTT:G_ICARTTdf
	String sub = df[strsearch(df, ":", Inf,1)+1,Inf]
	String win = sub + "_Meta"
	
	SetDataFolder $df
	DoWindow /K $win
	Edit/k=1/W=(5,44,810,400) meta as sub + " Meta"
	DoWindow /C $win
	ModifyTable format(Point)=1,alignment(meta)=0,width(meta)=700
	SetDataFolder root:
	
End

Function EditRevComments()

	SVAR df = root:ICARTT:G_ICARTTdf
	String sub = df[strsearch(df, ":", Inf,1)+1,Inf]
	String win = sub + "_RevCom"
	
	SetDataFolder $df
	DoWindow /K $win
	Edit/k=1/W=(5,44,710,200) rev_comments as sub + " Rev Comments"
	DoWindow /C $win
	ModifyTable format(Point)=1,alignment(rev_comments)=0,width(rev_comments)=600
	SetDataFolder root:
	
End

Function EditVarComments()

	SVAR df = root:ICARTT:G_ICARTTdf
	String sub = df[strsearch(df, ":", Inf,1)+1,Inf]
	String win = sub + "_VarCom"
	Variable i

	SetDataFolder $df
	SVAR varlist = G_varlist
	
	if (!Waveexists(VarComments))
		Make /T/N=(ItemsInList(varlist)) VarComments
	endif
	Make /O/T/N=(ItemsInList(varlist)) Vars
	for(i=0; i<ItemsInList(varlist); i+=1)
		Vars[i] = StringFromList(i, varlist)
	endfor

	DoWindow /K $win
	Edit/k=1/W=(5,44,808,302) Vars,VarComments as sub + " Var Comments"
	DoWindow /C $win
	ModifyTable format(Point)=1,alignment(VarComments)=0,width(VarComments)=600
	ModifyTable style(Vars)=1, rgb(Vars)=(2,39321,1)
	SetDataFolder root:

End

Function WriteICARTTfile()

	PathInfo ICARTTsave
	If (!V_flag)
		NewPath /M="Where shall we save the ICARTT file?" ICARTTsave
	endif

	SVAR df = root:ICARTT:G_ICARTTdf
	Variable refnum, i, j
	
	if (strsearch(df, "_GC", 0) != -1)
		PrepareGCdata()
	elseif (strsearch(df, "_MSD", 0) != -1)
		PrepareMSDdata()
	endif	
	
	SetDatafolder $df
	SVAR file = G_filename
	SVAR rev = G_rev
	SVAR mission = G_mission
	SVAR missionsuffix = G_missionsuffix
	SVAR inst = G_inst
	SVAR fltd = G_flightdate
	SVAR datd = G_datadate
	SVAR varlst = G_varlist
	SVAR suff = G_suffix
	Wave /T meta, comments, personnel, rev_comments, VarComments, Vars
		
	//These waves are required
	if (!WaveExists(Time_Start) || !WaveExists(Time_Stop))
		abort "Need Time_Start and Time_Stop waves."
	endif
	Wave StartT = Time_Start
	Wave StopT = Time_Stop
	
	// variables concerning comment and header length
	Variable Ncom = numpnts(comments), Nmeta, Nvars = ItemsInList(varlst), Ntot
	Nmeta = numpnts(meta) + numpnts(rev_comments) + 2
	Ntot = 9 + Nvars + 3 + Ncom +1 + Nmeta + 1  
	
	String tm1, tm2, var
	Open /P=ICARTTsave refnum as file
	
	// file header
	fprintf refnum, "%d, 1001\r\n", Ntot
	for(i=0; i<numpnts(personnel); i+=1)
		fprintf refnum, "%s\r\n", personnel[i]
	endfor
	fprintf refnum, "%s %s\r\n1, 1\r\n", mission, missionsuffix
	fprintf refnum, "%s, %s, %s,      %s, %s, %s\r\n", fltd[0,3], fltd[4,5], fltd[6,7], datd[0,3], datd[4,5], datd[6,7]
	fprintf refnum, "0\r\nTime_Start, seconds, ELAPSED TIME IN SECONDS FROM 00:00:00 GMT ON FLIGHT DATE TO START OF SAMPLING\r\n"
	fprintf refnum, "%d\r\n", Nvars
	
	// scale factor and missing number
	tm1 = ""; tm2 = ""
	for (i=0; i<Nvars-1; i+=1)
		tm1 += "1.0, "
		tm2 +=  kmissingvalue + ", "
	endfor
	tm1 += "1.0"
	tm2 += kmissingvalue
	fprintf refnum, "%s\r\n%s\r\n", tm1, tm2
	
	// variables and descriptions
	for (i=0; i<Nvars; i+=1)
		tm1 = ""
		for(j=0; j<20-strlen(Vars[i]); j+=1)
			tm1 += " "
		endfor
		if (cmpstr("Time_Stop", Vars[i]) == 0)
			fprintf refnum, "%s,%s%s%s\r\n", Vars[i], ReturnSpaces(strlen(suff)), tm1, VarComments[i]		// don't add suffix to Stop_UTC
		else
			fprintf refnum, "%s%s,%s%s\r\n", Vars[i], suff, tm1, VarComments[i]  // added Suffix to variable 160907
		endif
	endfor
	
	// comment field
	fprintf refnum, "%d\r\n", Ncom
	for (i=0; i<Ncom; i+=1)
		fprintf refnum, "%s\r\n", comments[i]
	endfor
	
	// Meta data
	fprintf refnum, "%d\r\n", Nmeta
	for (i=0; i<numpnts(meta) ; i+=1)			// bug fix GSD 140909
		fprintf refnum, "%s\r\n", meta[i]
	endfor
	
	// rev number and comments
	fprintf refnum, "REVISION: %s\r\n", rev
	for (i=0; i<numpnts(rev_comments); i+=1)
		fprintf refnum, "%s\r\n", rev_comments[i]
	endfor
	
	// variables followed by data
	tm1 = "Time_Start, "
	for (i=0; i<numpnts(Vars)-1; i+=1)
		if (cmpstr("Time_Stop", Vars[i]) == 0)
			tm1 += Vars[i] + ", "				// don't add suffix to Time_Stop
		else
			tm1 += Vars[i] + suff + ", "				// added Suffix to variable 160907
		endif
	endfor
	tm1 += Vars[i+1] + suff
	fprintf refnum, "%s\r\n", tm1
	
	// data
	for (i=0; i<numpnts(StartT); i+=1)
		sprintf tm1, "%6.1f, %6.1f", StartT[i], StopT[i]
		for (j=1; j<numpnts(Vars); j+=1)
			var = Vars[j]
			Wave vwv = $var
			if (!WaveExists(vwv))
				abort("Missing wave: "+var)
				close refnum
			endif
			// handle nan in data
			if (numtype(vwv[i]) != 0)
				sprintf tm1, "%s,%7d, ", tm1, str2num(kmissingvalue)
			else
				if ((strsearch(var, "SF6", 0) != -1) || (strsearch(var, "H1211", 0) != -1))
					sprintf tm1, "%s,%7.2f, ", tm1, vwv[i]
				else
					sprintf tm1, "%s,%7.1f, ", tm1, vwv[i]
				endif
			endif
			tm1 = tm1[0,strlen(tm1)-3]		// remove the last comma and space
		endfor
		fprintf refnum, "%s\r\n", tm1
	endfor
	
	Printf "File: %s written to %s\r", file, S_Path
	
	Close refnum
	SetDatafolder root:

End

// Returns a string of spaces of length num 
Function /S ReturnSpaces(num)
	variable num
	
	variable i
	string sp = ""
	for(i=0; i<num; i+=1)
		sp += " "
	endfor
	return sp
	
end

// Converts the flight date string into
Function YYYYMMDD2secs(str)
	string str

	return date2secs(str2num(str[0,3]), str2num(str[4,5]), str2num(str[6,7]))

End

// Function to prepare the o3x data for the ICARTT data file save funcitons.
Function PrepareUCATSozone()

	// data to be submitted should be in the ICARTT data folder
	DFREF df = root:ICARTT:UCATS_O3
	
	Variable create = 1
	if (WaveExists(df:O3_UO3))
		String ans = "Yes (overwrite);No (quit)"
		Prompt create, "Create O3_UO3, O3e_UO3, Time_Start and Time_Stop", popup ans
		DoPrompt "One or more of the Ozone waves exists.  Recreate?", create
		if (V_Flag)
			return -1								// User canceled
		endif
	endif
	
	// make or recreate submission waves
	if (create==1)
		SetDatafolder df
		//Duplicate /O root:O3xbest, O3_UO3, O3e_UO3
		//Duplicate /O root:TimeWO3x, Start_UTC, Stop_UTC

		// merged data used?
		// Updated for DCOTSS by EJH 2021 06 25 - change time from Start_UTC to Time_Start, and also Stop_UTC to Time_Stop
		Duplicate /O root:O3_merg, O3, O3e
		// Duplicate /O root:TimeWO3_merg, Start_UTC, Stop_UTC
		Duplicate /O root:TimeWO3_merg, Time_Start, Time_Stop
		
		// These are best guesses to get the waves setup.  You should manually edit/process the ozone waves before
		// submitting the data vi ICARTT panel.
		
		// make sure you edit the comment field (in meta section) to reflect uncertainties
		O3e = abs(O3) * 0.02 + 2

		//  Remove flight date seconds from time waves stored in Igor native seconds formate	
		SVAR flt = G_flightdate
		Time_Start -= YYYYMMDD2secs(flt)
		Time_Stop -= YYYYMMDD2secs(flt)

		// two second ozone
		//Start_UTC -= 1
		//Stop_UTC += 1
		
		variable delta = (Time_Start[1] - Time_Start[0])/2
		Time_Start -= delta
		Time_Stop += delta
		
		String win = "O3xsubmit"
		Dowindow /K $win
		edit /K=1 Time_Start, Time_Stop, O3, O3e
		DoWindow /C $win
		
	endif
	
	TrimBlankData("O3;O3e")
	
	Setdatafolder root:
	
	Print "Ozone X is prepared for submission."
	
end

// Function to prepare the UCATS tdl h2o data for the ICARTT data file save funcitons.
Function PrepareUCATSh2o()

	// data to be submitted should be in the ICARTT data folder
	DFREF df = root:ICARTT:UCATS_H2O

	Variable create = 1
	if (WaveExists(df:H2O_UWV))
		String ans = "Yes (overwrite);No (quit)"
		Prompt create, "Create H2O_UWV, H2Oe_UWV, Start_UTC and Stop_UTC", popup ans
		DoPrompt "One or more of the H2O waves exists.  Recreate?", create
		if (V_Flag)
			return -1								// User canceled
		endif
	endif
	
	// make or recreate submission waves
	// edited by EJH 20180606
	if (create==1)
		SetDatafolder df
		Duplicate /O root:tdl_best, H2O, H2Oe
		Duplicate /O root:TimeWh2o, Time_Start, Time_Stop
		
		// These are best guesses to get the waves setup.  You should manually edit/process the ozone waves before
		// submitting the data vi ICARTT panel.
		
		// make sure you edit the comment field (in meta section) to reflect uncertainties
		H2Oe = abs(H2O) * 0.05 + 1

		//  Remove flight date seconds from time waves stored in Igor native seconds formate		
		SVAR flt = G_flightdate
		Time_Start -= YYYYMMDD2secs(flt)
		Time_Stop -= YYYYMMDD2secs(flt)

		// one second h2o (more or less)
		Time_Start -= .5
		Time_Stop += .5
		
		String win = "H2Osubmit"
		Dowindow /K $win
		edit /K=1 Time_Start, Time_Stop, H2O, H2Oe
		DoWindow /C $win

		
	endif
	
	TrimBlankData("H2O;H2Oe")
	
	SetDataFolder root:
	
	Print "UCATS H2O is prepared for submission."

End


// Copies UCATS or PANTHER GC ECD data to the ICARTT data folder in preperation
// for writting ICARTT file.  The Start and Stop waves are created here.
Function PrepareGCdata([fltstr])
	string fltstr

	SVAR df = root:ICARTT:G_ICARTTdf
	SetDatafolder df
	
	SVAR flt = G_flightdate
	SVAR inst = G_inst
	SVAR vars = G_varlist
	
	// if fltstr is not defined use flt
	if (ParamIsDefault(fltstr) == 1)
		fltstr = flt
	endif
	if (strlen(fltstr) == 6)
		fltstr = "20" + fltstr
	endif
	flt = fltstr
	UpdateFilename()
	SetDatafolder df			// UpdateFilename sets df to root
	
	Variable i
	String var, wvstr

	// shtflt is 6 dig date used for waves names
	String shtflt = fltstr
	if (strlen(fltstr) == 8)
		shtflt = fltstr[2,Inf]
	endif

	// Check to see if data is loaded for flightdate
	Sprintf wvstr, "root:tsecs_%s", shtflt
	If (!WaveExists($wvstr))
		abort "Missing data for flight: " + flt
	endif
	
	// Copy waves from root: to df and make UTC waves
	for (i=1; i<ItemsInList(vars); i+=1)		// i=1 to skip the Stop_UTC var (handle later)
		var = StringFromList(i, vars)
		// error or _prec waves (keys off the 'e', hopefully no molecules have an 'e' at their end)
		if (cmpstr(var[strlen(var)-1,Inf], "e") == 0)
			Sprintf wvstr, "root:%s_hght_prec_%s", var[0, strlen(var)-2], shtflt
		else
			Sprintf wvstr, "root:%s_hght_conc_%s", var, shtflt
		endif
		Wave /Z wv = $wvstr
		If (WaveExists(wv))
			Duplicate /o wv, $var
		endif
	endfor
	
	// handle Start and Stop times
	Sprintf wvstr, "root:tsecs_%s", shtflt
	Wave /Z wv = $wvstr
	Duplicate /o wv, Time_Stop, Time_Start

	// based on uav.sol file when the sample loop closes
	// can use inst variable to have different times for both UCATS and PANTHER
	if (cmpstr(inst, "UCATS") == 0)
		Time_Start -= 9
		Time_Stop -= 6
	elseif (cmpstr(inst, "PANTHER") == 0)
		Time_Start -= 9
		Time_Stop -= 6
	else
		abort "Unrecognized instrument: " + inst
	endif

	string noUTC = RemoveFromList("Time_Stop", vars)
	TrimBlankData(noUTC)
	SetDataFolder root:

end

// very similar to PrepareGCdata but only used for PANTHER MSD Data
Function PrepareMSDdata([fltstr])
	string fltstr

	SVAR df = root:ICARTT:G_ICARTTdf
	SetDatafolder df
	
	SVAR flt = G_flightdate
	SVAR inst = G_inst
	SVAR vars = G_varlist
	
	// if fltstr is not defined use flt
	if (ParamIsDefault(fltstr) == 1)
		fltstr = flt
	endif
	if (strlen(fltstr) == 6)
		fltstr = "20" + fltstr
	endif
	flt = fltstr
	UpdateFilename()
	SetDatafolder df			// UpdateFilename sets df to root
	
	Variable i
	String var, wvstr

	// shtflt is 6 dig date used for waves names
	String shtflt = fltstr
	if (strlen(fltstr) == 8)
		shtflt = fltstr[2,Inf]
	endif

	// Check to see if data is loaded for flightdate
	Sprintf wvstr, "root:tsecs_%s", shtflt
	If (!WaveExists($wvstr))
		abort "Missing data for flight: " + flt
	endif
	
	// Copy waves from root: to df and make UTC waves
	for (i=1; i<ItemsInList(vars); i+=1)		// i=1 to skip the Stop_UTC var (handle later)
		var = StringFromList(i, vars)
		// error or _prec waves (keys off the 'e', hopefully no molecules have an 'e' at their end)
		if (cmpstr(var[strlen(var)-1,Inf], "e") == 0)
			Sprintf wvstr, "root:%s_hght_prec_%s", var[0, strlen(var)-2], shtflt
		else
			Sprintf wvstr, "root:%s_hght_conc_%s", var, shtflt
		endif
		Wave /Z wv = $wvstr
		If (WaveExists(wv))
			Duplicate /o wv, $var
		endif
	endfor
	
	// handle Start and Stop times
	Sprintf wvstr, "root:tsecs_%s", shtflt
	Wave /Z wv = $wvstr
	Duplicate /o wv, Stop_UTC, Start_UTC

	// based on msd.sol file when the sample loop closes
	Start_UTC -= 9
	Stop_UTC -= 6

	string noUTC = RemoveFromList("Stop_UTC", vars)
	TrimBlankData(noUTC)
	SetDataFolder root:

end


// Trim blank data from the beginning and end of data waves
// function works for current datafolder
Function TrimBlankData(wvlst)
	string wvlst

	variable i, j, del
	
	Wave wv0 = $StringFromList(0, wvlst)

	// Delete points from top
	for (j=0; j<numpnts(wv0); j+=1)
		del = 1
		for (i=0; i<ItemsInList(wvlst); i+=1)
			wave wv = $StringFromList(i, wvlst)
			if (numtype(wv[j]) == 0)
				del = 0
				break
			endif
		endfor
		if (del)
			for (i=0; i<ItemsInList(wvlst); i+=1)
				wave wv = $StringFromList(i, wvlst)
				DeletePoints j, 1, wv
			endfor
			DeletePoints j, 1, Time_Start, Time_Stop
			j -= 1
		endif
	endfor

End