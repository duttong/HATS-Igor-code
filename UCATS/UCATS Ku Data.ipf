#pragma rtGlobals=1		// Use modern global access method.

Menu "Kuband"
	"Load Ku Data/1", /Q
	"-"
	"Load Data In Background/9"
	"Stop Loading Data"
	"-"
	"Plot 1 Trace"
	"Plot 2 Traces"
	"-"
	"Reload and Restart"
end


function LoadKuData()

	// global strings to keep track of files already loaded
	SVAR /Z engFilesLoaded = S_engFilesLoaded
	if (!SVAR_Exists(engFilesLoaded))
		String/G S_engFilesLoaded = ""
	endif
	SVAR /Z o3FilesLoaded = S_o3FilesLoaded
	if (!SVAR_Exists(o3FilesLoaded))
		String/G S_o3FilesLoaded = ""
	endif
	SVAR /Z o3xFilesLoaded = S_o3xFilesLoaded
	if (!SVAR_Exists(o3xFilesLoaded))
		String/G S_o3xFilesLoaded = ""
	endif

	PathInfo KU_PATH
	if (!V_flag)
		NewPath /M="Path to Ku data files." KU_PATH
		if (V_flag != 0)
			abort
		endif
	endif
	
	// get list of all .txt files
	String file, filelst = IndexedFile(KU_PATH, -1, ".txt"), englst = "", o3lst = "", o3xlst = ""
	variable i
	
	for(i=0;i<ItemsInList(filelst); i+=1)
		file = StringFromList(i, filelst)
		if (GrepString(file, "eng"))
			englst += file + ";"
		elseif (GrepString(file, "ozn"))
			o3lst += file + ";"
		elseif (GrepString(file, "ozx"))
			o3xlst += file + ";"
		endif
	endfor	
	
	LoadListofFiles(englst)
	LoadListofFiles(o3lst)
	LoadListofFiles(o3xlst)
	SetDataFolder root: 
	
end

function LoadListofFiles(filelst)
	string filelst

	SetDataFolder root:
	
	String file
	Variable i
	SVAR FilesLoaded = root:S_engFilesLoaded
	
	if (GrepString(filelst, "ozn"))
		SVAR FilesLoaded = root:S_o3FilesLoaded
	elseif (GrepString(filelst, "ozx"))
		SVAR FilesLoaded = root:S_o3xFilesLoaded
	endif

	// section loads each file once.
	for(i=0; i<=ItemsInList(filelst)-1; i+=1)
		file = StringFromList(i, filelst)
		if (!GrepString(FilesLoaded, file))
			if (i==0)
				LoadKuData_AppendAll(file)
			else
				LoadKuData_AppendPart(file)
			endif
		endif
	endfor
	FilesLoaded = filelst
	
	// now load the last file again.  The last file might still be growing.
	if (ItemsInList(filelst) == 1)
		LoadKuData_AppendAll(file)
	else
		LoadKuData_AppendPart(file)
	endif

	SetDataFolder root: 

end


function LoadKuData_BG(s)
	STRUCT WMBackgroundStruct &s

	// global strings to keep track of files already loaded
	SVAR engFilesLoaded = S_engFilesLoaded
	SVAR o3FilesLoaded = S_o3FilesLoaded
	SVAR o3xFilesLoaded = S_o3xFilesLoaded

	// get list of all .txt files
	String file, filelst = IndexedFile(KU_PATH, -1, ".txt"), englst = "", o3lst = "", o3xlst = ""
	variable i
	
	for(i=0;i<ItemsInList(filelst); i+=1)
		file = StringFromList(i, filelst)
		if (GrepString(file, "eng"))
			englst += file + ";"
		elseif (GrepString(file, "ozn"))
			o3lst += file + ";"
		elseif (GrepString(file, "ozx"))
			o3xlst += file + ";"
		endif
	endfor	
	
	LoadListofFiles(englst)
	LoadListofFiles(o3lst)
	LoadListofFiles(o3xlst)
	
	return 0
	
end


Function LoadDataInBackground()
	// start a background process
	Variable numTicks = 5 * 60		// Run every five seconds 
	CtrlNamedBackground MoreData, burst=1, period=numTicks, proc=LoadKuData_BG
	CtrlNamedBackground MoreData, start
End

Function StopLoadingData()
	CtrlNamedBackground MoreData, stop
End

function MaketimeWgc()
	Wave T = root:TimeW
	Wave D = root:DateW
	Make/o/d/n=(numpnts(T)) root:timeWgc = D+T
	SetScale d 0,0,"dat", root:timeWgc
	// make timeWh2o as well.  Normally this wave is created when h2o data is loaded
	Make/o/d/n=(numpnts(T)) root:timeWh2o = D+T
	SetScale d 0,0,"dat", root:timeWh2o
end

function MaketimeWO3()
	Wave T = root:TimeO3
	Wave D = root:DateO3
	Make/o/d/n=(numpnts(T)) root:TimeWO3 = D+T
	SetScale d 0,0,"dat", root:TimeWO3
end

function MaketimeWO3x()
	Wave T = root:TimeO3x
	Wave D = root:DateO3x
	Make/o/d/n=(numpnts(T)) root:TimeWO3x = D+T
	SetScale d 0,0,"dat", root:TimeWO3x
end


// loads a file and replaces data in root: folder
// this is used for the first file loaded
static function LoadKuData_AppendAll(file)
	string file
	
	LoadWave/O/Q/J/K=1/R={English,2,2,2,2,"Year/Month/DayOfMonth",40}/W/A/P=KU_PATH file

	// handle same wave names in ozone file
	if (GrepString(file, "ozn"))
		Duplicate /o TimeW, TimeO3
		Duplicate /o DateW, DateO3
		MaketimeWO3()
	elseif (GrepString(file, "ozx"))
		Duplicate /o TimeW, TimeO3x
		Duplicate /o DateW, DateO3x
		MaketimeWO3x()
	else
		MaketimeWgc()
	endif
	
	SetDataFolder root: 

end


// loads a file and replaces data
function LoadKuData_AppendPart(file)
	string file

	// test to see if file exists and has data in it
	Variable refnum
	Open/R/Z=1/P=KU_PATH refNum as file
	
	if (V_flag != 0)
		return V_flag
	endif
	FStatus refNum
	if (V_logEOF < 200)
		return 0
	endif	
	Close /A

	NewDataFolder /O/S Kuload

	LoadWave/O/D/Q/J/K=1/R={English,2,2,2,2,"Year/Month/DayOfMonth",40}/W/A/P=KU_PATH file
	// tring to ignore loadwave errors
	Variable err=GetRTError(1)
	if(err!=0)
		print "Error loading Kudata file"
		print err, GetErrMessage(err)
		return 0
	endif

	
	// handle same wave names in ozone file
	if (GrepString(file, "ozn"))
		Duplicate /O TimeW, TimeWO3
		Duplicate /O DateW, DateWO3
		Wave newTimeWv = TimeWO3
		Wave DD = DateWO3
		Wave TimeWv = root:TimeWO3
		//Wave DateWv = root:DateO3
	elseif (GrepString(file, "ozx"))
		Duplicate /O TimeW, TimeWO3x
		Duplicate /O DateW, DateWO3x
		Wave newTimeWv = TimeWO3x
		Wave DD = DateWO3x
		Wave TimeWv = root:TimeWO3x
		//Wave DateWv = root:DateO3x
	else
		Duplicate /O TimeW, TimeWgc
		Duplicate /O DateW, DateWgc
		Wave newTimeWv = TimeWgc
		Wave DD = DateWgc
		Wave TimeWv = root:TimeWgc
		//Wave DateWv = root:DateWgc
	endif
	newTimeWv += DD
	SetScale d 0,0,"dat", newTimeWv
	Killwaves /Z TimeW, DateW

	String name, wvlst = Wavelist("*", ";", "")
	Variable i
	
	Variable pt1 = BinarySearch(TimeWv, newTimeWv[0]), pt2, size
		
	if (pt1 == -2)
		// append data to the end of waves
		for (i=0; i<ItemsInList(wvlst); i+=1)
			name = StringFromList(i, wvlst)
			ConcatenateWaves("root:"+name, "root:Kuload:"+name)
		endfor
	else
		// sync data 
		pt2 = numpnts(TimeWv)-1
		pt1 = BinarySearch(newTimeWv, TimeWv[pt2])
		size = numpnts(newTimeWv)-pt1-1
		if ((size > 0) && (pt1 >= 0))
			for (i=0; i<ItemsInList(wvlst); i+=1)
				name = StringFromList(i, wvlst)
				wave /Z main = $"root:"+name
				if (Waveexists(main))
					wave wv = $name
					InsertPoints pt2, size, main
					main[pt2, ] = wv[pt1+p-pt2]
				endif
			endfor
		endif
	endif
	
	if (GrepString(file, "eng"))
		Duplicate /o TimeWv, root:TimeWh2o
	endif
	
	Killwaves /Z/A
	SetDataFolder root: 
	return 0

end


// Closes all tables and plots, kills all waves in root:, reloads data, and restarts LoadKuData_AppendPart in the background
Function ReloadandRestart()
	StopLoadingData()
	removeDisplayedObjects()
	SetDataFolder root:
	Killwaves /A
	String /G S_engFilesLoaded = ""
	String /G S_o3FilesLoaded = ""
	String /G S_o3xFilesLoaded = ""
	LoadKuData()
End


function Fig_one(wv, axislabel)
	wave wv
	string axislabel
	string win = NameOfWave(wv) + "_fig"
	SetDataFolder root:
	DoWindow /K $win
	Display /K=1/W=(35,44,618,351) wv vs root:timeWgc
	DoWindow /C $win
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left axislabel
	Label bottom "Date"
EndMacro

function Fig_two(wv1, wv2, axislabel)
	wave wv1, wv2
	string axislabel
	string win = NameOfWave(wv1) + "_and_" + NameOfWave(wv2) + "_fig"
	SetDataFolder root:
	DoWindow /K $win
	Display /K=1/W=(35,44,618,351) wv1 vs root:timeWgc
	AppendtoGraph /r wv2 vs root:timeWgc
	DoWindow /C $win
	ModifyGraph dateInfo(bottom)={0,0,0}, rgb[1]=(0,0,65535)
	Label left axislabel
	Label bottom "Date"
	Legend
EndMacro

function Channel1Flows()
	Fig_two(Flow_M1, Flow_BF1, "Flow rate (sccm)")
end

function Channel2Flows()
	Fig_two(Flow_M2, Flow_BF2, "Flow rate (sccm)")
end

function Plot1trace()

	string wvlst = WaveList("*", ";", ""), wv, axislbl
	Prompt wv, "Which parameter to plot?", popup, wvlst
	Prompt axislbl, "Enter a y-axis label"
	DoPrompt "Plot one trace", wv, axislbl
	
	if (V_flag == 1)
		return 0
	endif
	
	Fig_one($wv, axislbl)

end

function Plot2traces()

	string wvlst = WaveList("*", ";", ""), wv1, wv2, axislbl
	Prompt wv1, "Which parameter to plot?", popup, wvlst
	Prompt wv2, "Which parameter to plot?", popup, wvlst
	Prompt axislbl, "Enter a y-axis label"
	DoPrompt "Plot one trace", wv1, wv2, axislbl
	
	if (V_flag == 1)
		return 0
	endif
	
	Fig_two($wv1, $wv2, axislbl)

end


Window ECDaverages() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(45,104,836,476) ecdA_CH1 vs timeWgc
	AppendToGraph/R ecdA_CH2 vs timeWgc
	ModifyGraph rgb(ecdA_CH2)=(0,0,65535)
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left "Channel 1 Response (Hz)"
	Label bottom "Date"
	Label right "Channel 2 Response (Hz)"
	Legend/C/N=text0/J/X=82.58/Y=1.69 "\\s(ecdA_CH1) ecdA_CH1\r\\s(ecdA_CH2) ecdA_CH2"
EndMacro

Window Voltages() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(69,366,652,673)/K=1  volt_5 vs timeWgc
	AppendToGraph volt_15 vs timeWgc
	AppendToGraph volt_28 vs timeWgc
	ModifyGraph rgb(volt_5)=(3,52428,1),rgb(volt_28)=(0,0,0)
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left "Voltages (V)"
	Label bottom "Date"
	SetAxis/A/N=1 left
	Legend/C/N=text0/J/X=83.00/Y=17.62 "\\s(volt_5) volt_5\r\\s(volt_15) volt_15\r\\s(volt_28) volt_28"
EndMacro
