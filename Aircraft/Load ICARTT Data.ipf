#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version=1.0

#include "macros-utilities"
#include "macros-Geoff"
#include "macros-Strings and Lists"

menu "Macros"
	"Load ICARTT files"
	"Time Series Plot"
	"-"
	"Close all graphs", removeDisplayedGraphs()
end

// load all ICARTT data files in the DataPath
Function LoadICARTTfiles()
		
	PathInfo DataPath
	if (V_flag == 0)
		NewPath/M="Select folder with ICARTT data files." DataPath
	endif
	
	// list of ICARTT data files
	String file, files = IndexedFile(DataPath, -1, ".ict")
	
	Variable i, headerlines
	for(i=0; i<ItemsInList(files); i+=1)
		file = StringFromList(i, files)
		LoadICARTTfile(file)
	endfor
	
	DateList()
	InstList()
end

Function LoadICARTTfilesDate(fltdate)
	string fltdate
	
	String /G S_InstList = ""
	
	PathInfo DataPath
	if (V_flag == 0)
		NewPath/M="Select folder with ICARTT data files." DataPath
	endif
	
	// list of ICARTT data files
	String file, files = IndexedFile(DataPath, -1, ".ict")

	Variable i, headerlines
	for(i=0; i<ItemsInList(files); i+=1)
		file = StringFromList(i, files)
		if (strsearch(file, fltdate, 0) > 0)
			LoadICARTTfile(file)
		endif
	endfor
	
	DateList()	
	InstList()
End


Function LoadICARTTfile(file)
	string file

	Variable headerlines = numheaderlines(file)
	String Inst = ICARTTfilenameField(file, 0)
	String fltdate = ICARTTfilenameField(file, 2)
	
	SVAR /Z InstLst = root:S_InstList
	if (!SVAR_exists(InstLst))
		String /G root:S_InstList = ""
	endif
	SVAR InstLst = root:S_InstList
	if (WhichListItem(Inst, InstLst) < 0)
		InstLst = AddListItem(Inst, InstLst)
	endif
	
	SVAR /Z Plst = root:S_ParamLst
	if (!SVAR_exists(Plst))
		String /G root:S_ParamLst = ""
	endif
	SVAR Plst = root:S_ParamLst
	
	NewDataFolder/O/S $fltdate
	LoadWave/Q/O/A/G/D/W/P=DataPath/L={headerlines-1,headerlines,0,0,0} file
	
	// handle the time waves
	if (WaveExists($"Time_Start") && WaveExists($"Time_Stop"))
		// average of start and stop 
		wave t0 = Time_Start
		wave t1 = Time_Stop
		MatrixOp /O $"Time_"+Inst = (t0+t1)/2
		Killwaves t0, t1
		// remove t0 and t1 from S_waveNames list
		S_waveNames = RemoveListItem(0, S_waveNames)
		S_waveNames = RemoveListItem(0, S_waveNames)
	else
		// use first column as time
		wave wv0 = $StringFromList(0, S_waveNames)
		Duplicate /O wv0, $"Time_"+Inst
		Killwaves wv0
		S_waveNames = RemoveListItem(0, S_waveNames)
	endif

	Wave TT = $"Time_"+Inst
	TT += date2secs(str2num(fltdate[0,3]), str2num(fltdate[4,5]), str2num(fltdate[6,7]))
	SetScale d 0,0,"dat", TT
	
	// replace bad data values with NaN
	variable i, p, BAD = -999
	for(i=0; i<ItemsInList(S_waveNames); i+=1)
		Wave wv = $StringFromList(i, S_waveNames)
		wv = SelectNumber(wv <= BAD, wv, NaN)
	endfor
	
	// add to parameter list
	string parm
	for(i=0; i<ItemsInList(S_waveNames); i+=1)
		parm = StringFromList(i, S_waveNames)
		p = strsearch(parm, "_", 0)
		if (p > 0)
			parm = parm[0,p-1]
		endif
		// don't add the error waves to the parameter list for UCATS and PANTHER
		if ((strsearch(parm, "UCATS", 0) > 0) || (strsearch(parm, "GCECD", 0) > 0))
			if (cmpstr(parm[strlen(parm)-1], "e") != 0)
				Plst = AddListItem(parm, Plst)
			endif
		else
			Plst = AddListItem(parm, Plst)
		endif
	endfor

	Plst = RemoveFromList("N2Oe", Plst)	
	Plst = RemoveFromList("SF6e", Plst)	
	Plst = RemoveFromList("F11e", Plst)	
	Plst = RemoveFromList("F113e", Plst)	
	Plst = RemoveFromList("CH4e", Plst)	
	Plst = RemoveFromList("COe", Plst)	
	Plst = RemoveFromList("H2e", Plst)	
	Plst = UniqueList(Plst)
	Plst = SortList(Plst)
	
	cd root:
End

// Returns the number of header lines in an ICARTT 1001 file
Function numheaderlines(file)
	String file
	
	Variable refnum
	String buffer, headerlines="", expr
	
	// read the first line of the file
	Open/P=DataPath/R refnum as file
	FReadLine refnum, buffer
	Close refnum
	
	buffer = ReplaceString(" ", buffer, "")
	
	if (strsearch(buffer, "1001", 0) > 0)
		expr = "([[:digit:]]+),([[:digit:]]+)"
		SplitString/E=(expr) buffer, headerlines
	endif
		
	return str2num(headerlines)
End

// Returns a parameter (string) from an ICARTT file name.
// fieldnum variable
//   0      instrument
//   1      plateform
//   2      flight date
//   3      revision number
Function/S ICARTTfilenameField(file, fieldnum)
	string file
	variable fieldnum
	
	String expr = ReplaceString("_", file, ";")
	expr = ReplaceString(".ict", expr, "")
	return StringFromList(fieldnum, expr)
End

// Creates a flight date list (S_fltdates) with all of the data folders
// starting with a "2"
Function DateList()

	Variable i
	String df
	String /G root:S_fltdates = ""
	SVAR dd = root:S_fltdates
	
	do
		df = GetIndexedObjName(":", 4, i)
		if (cmpstr(df[0], "2") == 0)
			dd += df+";"
		elseif (strlen(df) == 0)
			break
		endif
		i += 1
	while(1)
	dd = SortList(dd, ";", 1)
End

// Create a list of instruments load
//  Steps through all flight date directories finding Time_* waves 
//  associated with an instrument.
Function InstList()

	Variable i
	String df
	String /G root:S_InstList = ""
	SVAR ilst = root:S_InstList
	SVAR /Z flts = root:S_fltdates
	if (!SVAR_exists(flts))
		DateList()
	endif
	
	// step in each date data folder to find instrument time waves.
	for(i=0; i<ItemsInList(flts); i+=1)
		String day = StringFromList(i, flts)
		SetDataFolder day
		String timewvs = Wavelist("Time_*", ";","")
		timewvs = ReplaceString("Time_", timewvs, "")
		ilst += timewvs
		cd root:
	endfor
	
	ilst = UniqueList(ilst)
	ilst = SortList(ilst)
End

Function TimeSeriesPlot([flt, param])
	string flt, param

	SVAR flts = root:S_fltdates
	SVAR params = root:S_ParamLst
	cd root:
	
	if (ParamIsDefault(flt))
		Prompt flt, "Flight Date to Plot", popup, flts+"All Flights"
		DoPrompt "Time Series Figure Flight Date", flt
		if (V_Flag)
			return -1								// User canceled
		endif
	endif
	if (ParamIsDefault(param))
		Prompt param, "Parameter to Plot", popup, params
		DoPrompt "Time Series Figure Parameter", param
		if (V_Flag)
			return -1								// User canceled
		endif
	endif
	
	// get lists of potential waves to plot
	string timewvs, ywvs, xwv, ywv, day
	variable i, j, pts
	if (cmpstr(flt, "All Flights") != 0)
		SetDataFolder $flt
		timewvs = Wavelist("Time_*", ";", "")
		ywvs = Wavelist(param+"_*", ";", "")
		if (WaveExists($param))
			ywvs += param
		endif
	else
		for(i=0; i<ItemsInList(flts); i+=1)
			day=StringFromList(i, flts)
			if (cmpstr(day, "All Flights") != 0)
				TimeSeriesPlot(flt=day, param=param)
			endif
		endfor
		return -1
	endif
	
	string cmd="", win = param + "_" + flt + "_fig"
	DoWindow /K $win
	Display /W=(35,45,544,338)/K=1
	DoWindow /C $win
	
	for(i=0; i<ItemsInList(ywvs); i+=1)
		ywv = StringFromList(i, ywvs)
		pts = numpnts($ywv)
		for(j=0; j<ItemsInList(timewvs); j+=1)
			xwv = StringFromList(j, timewvs)
			if (numpnts($xwv) == pts)
				break
			endif
		endfor
		AppendToGraph $ywv vs $xwv
		// make pfps be markers instead of lines
		if (strsearch(ywv, "PFP", 0) > 0)
			ModifyGraph mode($ywv)=3
			sprintf cmd, "ModifyGraph marker(%s)=%d", ywv, Inst_marker(ywv); execute cmd
		endif
		sprintf cmd, "ModifyGraph rgb(%s)=%s", ywv, Inst_color(ywv); execute cmd
		Label left param
		Label bottom "Flight Time"
	endfor
	legend
	cd root:
end

Function/S Inst_Color(Inst)
	string Inst
	
	if (strsearch(Inst, "UCATS", 0) > 0)
		return "(0,0,65535)"	// blue
	elseif (strsearch(Inst, "PFP", 0) > 0)
		return "(0,0,0)"		// black
	else
		return "(65535,0,0)"	// red
	endif
end

Function Inst_Marker(Inst)
	string Inst
	
	if (strsearch(Inst, "CCGG", 0) > 0)
		return 8
	elseif (strsearch(Inst, "HATS", 0) > 0)
		return 16
	else
		return 0
	endif
end