// Added detection of a quick restart of UCATS. This can occur if starting rungc and should have started labdoit
// Added o3x gap detection  (171220)

// Changed Dataroutines_H2O to handle quirks with new TDL instrument. Faster data rate,
//   a few missing values or zero values.
// Cleaned up H2Oplots and plotting pull down menu  (180604) GSD
// Updated for new 3-channel GC and DCOTSS (201230) EJH
// Also updated for only O3x
// Found a couple bugs in FixTimeWave (GSD 220603)

#pragma rtGlobals=1		// Use modern global access method.

#include "macros-utilities"
#include "macros-geoff"
#include <strings as lists>
#include <Concatenate Waves>
#include <Remove Points>
#include "macros-ICARTT"

// the ( character is used to turn off menu items
menu "UCATS_Macros"
	"Plot GC Everything<B"
	"-"
	Submenu "CHANNEL 1<B"
		"Plot All CHAN1<B", CH1plots()
		" Flows", EngPlot2(Flow_M1, Flow_BF1, "Flow (cc/min)",0)
		" Flows - setpoints", EngPlot2(Flow_M1_sp, Flow_BF1_sp, "Flow (cc/min)",0)
		" Back flush pressures", EngPlot2(pres_BP1, pres_BP1_sp, "Pressure (psi)",0)
		" Pressure ECDs", EngPlot1(pres_ECD1, "Pressure (mbar)",0)
		" Temp ECD", EngPlot1(CH1_ECD, "Temp (C)",0)
		" Temp Columns", EngPlot1(CH1_Col, "Temp (C)",0)
		" ECD Response", EngPlot1(ecdA_CH1, "Response (Hz)",0)
	end
	Submenu "CHANNEL 2<B"
		"Plot All CHAN2<B", CH2plots()
		" Flows", EngPlot2(Flow_M2, Flow_BF2, "Flow (cc/min)",0)
		" Flows - setpoints", EngPlot2(Flow_M2_sp, Flow_BF2_sp, "Flow (cc/min)",0)
		" Back flush pressures", EngPlot2(pres_BP2, pres_BP2_sp, "Pressure (psi)",0)
		" Pressure ECDs", EngPlot1(pres_ECD2, "Pressure (mbar)",0)
		" Temp ECD", EngPlot1(CH2_ECD, "Temp (C)",0)
		" Temp Columns", EngPlot1(CH2_Col, "Temp (C)",0)
		" ECD Response", EngPlot1(ecdA_CH2, "Response (Hz)",0)
	end
	Submenu "CHANNEL 3<B"
		"Plot All CHAN3<B", CH3plots()
		" Flows", EngPlot2(Flow_M3, Flow_BF3, "Flow (cc/min)",0)
		" Flows - setpoints", EngPlot2(Flow_M3_sp, Flow_BF3_sp, "Flow (cc/min)",0)
		" Back flush pressures", EngPlot1(pres_BP3, "Pressure (psi)",0)
		" Pressure ECDs", EngPlot1(pres_ECD3, "Pressure (mbar)",0)
		" Temp ECD", EngPlot1(CH3_ECD, "Temp (C)",0)
		" Temp Columns", EngPlot2(CH3_Col, CH3_Post, "Temp (C)",0)
		" ECD Response", EngPlot1(ecdA_CH3, "Response (Hz)",0)
	end
	Submenu "Ozone<B"
		"Plot All Ozone parameters<B", OzonePlots()
		" Ozone concentration", O3xPlot1(o3xbest, "Ozone (ppm)")
		" cell temp", O3xPlot1(o3xtemp, "Ozone Cell Temp (C)")
		" cell press", O3xPlot1(o3xpres, "Ozone Cell Pressure (C)")
		//"O3 correlation", O3vsO3x()
	end
	Submenu "Water<B"
		"Plot All Water parameters<B", H2OPlots()
		"TDL Water concentrations", H2OPlot2(tdl_longH2O, tdl_shortH2O,"Water (ppm)")
		//"Vaisala  Temp and RH ", H2OPlot2rt(vaiT, vaiRH)
		"TDL Temp Pressure", H2OPlot2rt(tdl_T, tdl_P)
		//"Vaisala RH and TDL Water- short", H2OPlot2rt(vaiRH, tdlsh2o) 
		"TDL Laser Power", H2OPlot2rt(tdl_pow, tdl_amp)
		"TDL Line Position", H2OPlot2(tdl_pos, tdl_posB, "Line Position")
		"TDL Zero", H2OPlot1(tdl_zer, "zero")
	end
	"-"
		"Make P-ext Synched to OZ<B", TimeMatchData(timewo3x,timewgc,pres_extern,o3_pres_extern, 5)
		"Make P-ext Synched to GC<B", TimeMatchData(tsecs_1904,timewgc,pres_extern,gc_pres_extern, 5)
		"Make O3 Synched to GC<B", TimeMatchData(tsecs_1904,timewo3x,o3x,o3x_gc, 20)
	"-"
		Submenu "Sampling"
		"Plot All Sampling<B", SampPlots()
		Submenu " Plots at Injection Time"
			" Sample loop temps ", SampleTempsInj()
			" Sample loop pressure ", SamplePressInj()
			" Sample loop flow ", SampleFlowInj()
		end
		Submenu " Plot all data"
			" Sample loop temps", EngPlot2(temp_SL1, temp_SL2, "Temp (C)",0)
			" Sample loop pressure", EngPlot1( pres_SL, "Press (mbar)",0)
			" Sample loop flow", EngPlot1( flow_SL, "Flow (cc/min)",0)
		end
	end
	Submenu "Cylinders"
		"Plot All Cylinder Pressures<B", CylinderPlots()
		" N2 - low", EngPlot1(presL_N2, "Pressure (psi)",0)
		" Cal - low", EngPlot1(presL_cal, "Pressure (psi)",0)
		" CO2 - low", EngPlot1(presL_dope, "Pressure (psi)",-5)
		//"N2O - low", EngPlot1(pres_bp1, "N2O Pressure (psi)",0)
		" Selected high pressure", EngPlot1(presH_123, "Pressure (psi)",0)
	end
	Submenu "Power"
		"Plot All Power<B", PowerPlots()
		" +28 or +24",  EngPlot1(volt_28, "+28 or +24 (Volts)",0)
		" +15 or -15",  EngPlot1(volt_15, "+15 or -15 (Volts)",-20)
		" +5 or +12", EngPlot1(volt_5, "+5 or +12 (Volts)",0)
	end
	Submenu "Thermistors"
		"Plot All Thermistors<B", ThermPlots()
		" Sample loops", EngPlot2(temp_SL1, temp_SL2, temp_SL3, "Sample Loops (C)",0)
		" Pump" , EngPlot1(temp_pump, "Pump temp (C)",-40)
		" Ambient", EngPlot1(temp_amb, "Internal temp (C)",-40)
		" Gas Bottles", EngPlot2(temp_gasB_N, temp_gasB_C, "External gas bottles (C)",-20)
	end
	"External Pressure", EngPlot1( pres_extern, "External Pressure (mbar)",0)
	"Pump Pressure", EngPlot1( pres_PUMP, "Pump Pressure (mbar)",0)
	"-"
	"Create Inj Waves"
	"-"
	"Close All Graphs<B", removeDisplayedGraphs()
end



Function BeforeFileOpenHook(refNum, fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr, fileKind)
	Variable refNum, fileKind
	String fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr
	

	variable len = strlen(fileNameStr)
	string com 
	
	// .dat files are eng files.
	if (cmpstr(fileNameStr[len-3,len], "dat")==0)

		if (cmpstr(fileNameStr[0,2], "eng") == 0)		// GC eng file found
			Load_Eng( pathNameStr, fileNameStr )
			return 1
		elseif (cmpstr(fileNameStr[0,2], "o3x") == 0)	// ozone X data file found
			Load_OzoneX( pathNameStr, fileNameStr )
			return 1
		elseif (cmpstr(fileNameStr[0,2], "h2o") == 0)	// h2o data file found
			Load_Water( pathNameStr, fileNameStr )
			return 1
		endif		
		return 1
	elseif (cmpstr(fileNameStr[len-3,len], "itx")==0)
		return 0
	else
		print "ERROR:  Can't load " + fileNameStr + " in this experiment."
		return 1		// returning a 1 will ignore other file types
	endif
	
end


// When loading both eng files

function Load_Eng( pathNameStr, fileNameStr )
	string pathNameStr, fileNameStr

	variable yyyy, mm, dd, st, Need2Cat = 0
	
	// determine which file is being loaded
	variable fileNum = str2num(fileNameStr[3,3])
	string /G englist1 = StrMakeOrDefault("root:englist1","")
	string /G englist2 = StrMakeOrDefault("root:englist2","")
	
	if (fileNum == 1 )
		SVAR englist = englist1
	else
		SVAR englist = englist2
	endif

	if (strlen(englist) > 0)
		Need2Cat = 1
		CatData_Prep(englist)
	endif
	
	print "Loading... " + fileNameSTR
	
	LoadWave/A/J/W/O/Q/K=0/P=$pathNameStr/V={" "," $",0,0}/L={1,3,0,0,0} fileNameStr
	if (fileNum == 1)
		duplicate /o TimeW TimeWgc
		Wave TT = TimeWgc
	else
		Wave TT = TimeW
	endif

	// add date to time wave (the date is from filename)
	st = strsearch(fileNameStr, "_", 0) + 1
	yyyy = str2num(fileNameStr[st,st+1]) + 2000
	mm = str2num(fileNameStr[st+2,st+3])
	dd = str2num(fileNameStr[st+4, st+5])
	FixTimeWave(TT, yyyy, mm, dd)

	// make englist string used in PrepForMoreDate and CatEngData 
	if ( fileNum == 1 )
		englist1 = "TimeWgc;" + RemoveFromList("TimeW", S_waveNames) 
	else
		englist2 = RemoveFromList("TimeW", S_waveNames)
	endif 
	
	if ( Need2Cat == 1 )
		print "****  Treating data as ADDITIONAL engineering data.  Concatenating new data to old data."
		CatData(englist)
	endif

	CleanUpBadValues( fileNum )
	//killwaves $"TimeW"
	
	// crude check to see if both eng files are loaded.  If so, create injection waves.
	if ( (exists("GCstate") ==  1) * (exists("pres_SL") == 1))
		CreateInjWaves()
	endif

end

function Load_Ozone( pathNameStr, fileNameStr )
	string pathNameStr, fileNameStr

	variable yyyy, mm, dd, st, Need2Cat = 0
	SVAR /Z wvlst = S_OzoneWaves
	if (!SVAR_exists(wvlst))
		String /G S_OzoneWaves = ""
		SVAR /Z wvlst = S_OzoneWaves			// make sure you delete the string if loading new data
	endif
	
	print "Loading... " + fileNameSTR

	if (strlen(wvlst) > 0)
		Need2Cat = 1
		CatData_Prep(wvlst)
	endif

	LoadWave/A/J/W/O/Q/K=0/P=$pathNameStr/V={" "," $",0,0}/L={1,3,0,0,0} fileNameStr
	duplicate /o TimeW TimeWo3
	Wave TT = TimeWo3
	wvlst = S_waveNames
	wvlst = ReplaceString("TimeW", wvlst, NameOfWave(TT))

	// add date to time wave (the date is from filename)
	st = strsearch(fileNameStr, "_", 0) + 1
	yyyy = str2num(fileNameStr[st,st+1]) + 2000
	mm = str2num(fileNameStr[st+2,st+3])
	dd = str2num(fileNameStr[st+4, st+5])
	FixTimeWave(TT, yyyy, mm, dd)	
	
	DataRoutines_Ozone()

	if ( Need2Cat == 1 )
		print "****  Treating data as ADDITIONAL ozone data.  Concatenating new data to old data."
		CatData(wvlst)
	endif

	SortData(TimeWo3, wvlst)
	
end

function Load_OzoneX(pathNameStr, fileNameStr)
	string pathNameStr, fileNameStr

	variable yyyy, mm, dd, st, Need2Cat = 0
	SVAR /Z wvlst = S_OzoneXwaves
	if (!SVAR_exists(wvlst))
		String /G S_OzoneXwaves = ""
		SVAR /Z wvlst = S_OzoneXwaves			// make sure you delete the string if loading new data
	endif
	
	print "Loading... " + fileNameSTR

	if (strlen(wvlst) > 0)
		Need2Cat = 1
		CatData_Prep(wvlst)
	endif

	LoadWave/A/J/W/O/Q/K=0/P=$pathNameStr/V={" "," $",0,0}/L={1,3,0,0,0} fileNameStr
	duplicate /o TimeW TimeWo3x
	Wave TT = TimeWo3x
	wvlst = S_waveNames
	wvlst = ReplaceString("TimeW", wvlst, NameOfWave(TT))
	
	// add date to time wave (the date is from filename)
	st = strsearch(fileNameStr, "_", 0) + 1
	yyyy = str2num(fileNameStr[st,st+1]) + 2000
	mm = str2num(fileNameStr[st+2,st+3])
	dd = str2num(fileNameStr[st+4, st+5])
	FixTimeWave(TT, yyyy, mm, dd)
	
	// update ICARTT flight data variable
	if (DataFolderExists("root:ICARTT:"))
		SVAR /Z flt = root:ICARTT:UCATS_O3:G_flightdate
		sprintf flt, "%4d%02d%02d", yyyy, mm, dd
		DataDate_today()
		ICARTT_Refresh()
	endif
	
	DataRoutines_OzoneX()

	if ( Need2Cat == 1 )
		print "****  Treating data as ADDITIONAL ozoneX data.  Concatenating new data to old data."
		CatData(wvlst)
		SortData(TimeWo3x, wvlst)
	endif

end


function Load_Water( pathNameStr, fileNameStr )
	string pathNameStr, fileNameStr

	variable yyyy, mm, dd, st, Need2Cat = 0
	SVAR /Z wvlst = S_WaterWaves
	if (!SVAR_exists(wvlst))
		String /G S_WaterWaves = ""
		SVAR /Z wvlst = S_WaterWaves			// make sure you delete the string if loading new data
	endif
	
	print "Loading... " + fileNameSTR

	if (strlen(wvlst) > 0)
		Need2Cat = 1
		CatData_Prep(wvlst)
	endif

	LoadWave/A/J/W/O/Q/K=0/P=$pathNameStr/V={" "," $",0,0}/L={1,3,0,0,0} fileNameStr
	duplicate /o TimeW TimeWh2o
	Wave TT = TimeWh2o
	wvlst = S_waveNames
	wvlst = ReplaceString("TimeW", wvlst, NameOfWave(TT))

	// add date to time wave (the date is from filename)
	st = strsearch(fileNameStr, "_", 0) + 1
	yyyy = str2num(fileNameStr[st,st+1]) + 2000
	mm = str2num(fileNameStr[st+2,st+3])
	dd = str2num(fileNameStr[st+4, st+5])
	FixTimeWave(TT, yyyy, mm, dd)
	
	// update ICARTT flight data variable
	if (DataFolderExists("root:ICARTT:"))
		SVAR /Z flt = root:ICARTT:UCATS_H2O:G_flightdate
		sprintf flt, "%4d%02d%02d", yyyy, mm, dd
		DataDate_today()
		ICARTT_Refresh()
	endif	
	
	/// This needs to run before concatenation
	DataRoutines_H2O()

	if ( Need2Cat == 1 )
		print "****  Treating data as ADDITIONAL H2O data.  Concatenating new data to old data."
		CatData(wvlst)
	endif
	
	SortData(TimeWh2o, wvlst)

end

// handles cross over to new day (updated 210807)
// bug fix (220525)
function FixTimeWave(timeW, yyyy, mm, dd)
	wave timeW
	variable yyyy, mm, dd
	
	// If transition is set, the QNX extraction was run a day after
	// the flight started. Need to remove 24 hours from the time wave
	variable day_inc = 0
	
	Differentiate/Meth=1 TimeW/D=TimeW_DIF
	FindLevel/Q timeW_DIF, -100   // a transition at 60*60*24 seconds
	If (V_flag == 0)
		timeW[V_levelX+2, Inf] += 60*60*24
		day_inc = 1
	endif
	Killwaves TimeW_DIF
	
	timeW += date2secs(yyyy,mm,dd)
	if (day_inc == 1)
		timeW -= 60*60*24
	endif
end


function CatData_Prep(wvlst)
	string wvlst

	string wvstr, nwvstr
	variable inc

	for(inc=0; inc<ItemsInList(wvlst); inc+=1)
		wvstr = StringFromList(inc, wvlst)
		nwvstr = wvstr + "_N"
		if (WaveExists($wvstr))
			rename $wvstr, $nwvstr
		endif
	endfor
		
end

// Concatenates a list of waves
function CatData(wvlst)
	string wvlst
	
	string wvstr, nwvstr, com
	variable inc

	for(inc=0; inc<ItemsInList(wvlst); inc+=1)
		wvstr = StringFromList(inc, wvlst)
		nwvstr = wvstr + "_N"
		Wave /Z wv = $wvstr
		if (WaveExists(wv))
			//print nwvstr, numpnts($nwvstr), wvstr, numpnts($wvstr)
			ConcatenateWaves(nwvstr, wvstr)
			killwaves wv
			rename $nwvstr, $wvstr
		endif
	endfor	
	
end

// sorts all data for all of the waves listed in wvlst.  The sortkey is usually the time wave.
Function SortData(sortkey, wvlst)
	wave sortkey
	string wvlst

	String com, wvs
	wvs = ReplaceString(";", wvlst, ",")
	if (WhichListItem(NameOfWave(sortkey), wvlst) == -1)
		wvs += NameOfWave(sortkey)
	endif
	sprintf com, "Sort %s %s", NameOfWave(sortkey), wvs
	execute com
end


// Replace bad engineering data with NaNs
function  CleanUpBadValues( engfilenum )
	variable engfilenum
	
	string Omegas = "CH3_ECD;CH3_Col;CH3_Post;CH2_ECD;CH2_Col;CH1_ECD;CH1_Col"
	variable inc, BAD1 = -99.9, BAD2 = -999
	
	if ( engfilenum == 1 )
	elseif ( engfilenum == 2)
		do
			wave Omega = $StringFromList(inc, Omegas)
			Omega[0] = NaN
			freplace(Omega, BAD1, NaN)
			freplace(Omega, BAD2, NaN)
			inc += 1
		while ( ItemsInList( Omegas ) > inc )
	endif
end

Function DataRoutines_Ozone()

	SVAR wvlst = S_OzoneWaves
	variable i, j, pt
		
	// Remove null data points.  These occur when UCATS is on and OzoneX is off
	Wave YY = O3yy
	Wave HH = O3hh
	Wave MN = O3min
	Wave SS = O3ss
	Wave TT = TimeWO3
	
	FindLevel/Q YY, 10
	pt = ceil(V_LevelX)
	for(i=0; i<ItemsInList(wvlst); i+=1)
		DeletePoints 0, pt, $StringFromList(i, wvlst)
	endfor

	// Remove duplicate records
	for(i=Numpnts(YY)-1; i>0; i-=1)
		if ((SS[i]==SS[i-1]) && (MN[i]==MN[i-1]) && (HH[i]==HH[i-1]))
			for(j=0; j<ItemsInList(wvlst); j+=1)
				DeletePoints i, 1, $StringFromList(j, wvlst)
			endfor
		endif
	endfor
	
	// Save pseudo original time wave
	// doesn't work with concatenation
	Duplicate /o TT, TimeWo3_org
		
	// Create a 10 second time wave
	TT = TT[0] + p*10
	
end


Function DataRoutines_OzoneX()

	SVAR wvlst = S_OzoneXwaves
	variable i, j, pt
		
	// Remove null data points.  These occur when UCATS is on and OzoneX is off
	Wave YY = O3xyy
	Wave HH = O3xhh
	Wave MN = O3xmin
	Wave SS = O3xss
	Wave TT = TimeWO3X
	String cmd = ""
	
	// Remove bad rows at the beginning of the file
	// Level changed from 2000 to 10 for Model 211 ozone (year is 16, 17, etc)
	FindLevel /Q YY, 10
	if (V_flag==0)
		pt = ceil(V_LevelX)
		// FindLevel twice, the 2nd if the program was restarted in the beginning of the flight
		FindLevel/Q/R=[pt+1,pt+50] YY, 10
		if (V_flag==0)
			pt = ceil(V_LevelX)+3
		endif
		sprintf cmd, "DeletePoints 0, %d, %s", pt, ReplaceString(";", wvlst, ",")
		print cmd
		execute cmd
	endif

	// Remove duplicate records (faster method)
	Make /o/n=(numpnts(YY)) index = 0
	for(i=Numpnts(YY)-1; i>0; i-=1)
		if ((SS[i]==SS[i-1]) && (MN[i]==MN[i-1]) && (HH[i]==HH[i-1]))
			index[i] = 1
		endif
	endfor
	SortData(index, wvlst)
	j = BinarySearch(index, 0)		// point of transition between 0 and 1
	sprintf cmd, "DeletePoints %d, %d, %s", j+1, numpnts(TT), ReplaceString(";", wvlst, ",")
	execute cmd
	SortData(TT, wvlst)
	Killwaves index
	DoUpdate

	// Forces time wave to have constant time step (170922)
	variable duration = round((TT[Inf]-TT[0])/numpnts(TT))		// should be 2 seconds
	TT = TT[0] + duration*p
	
	fixO3x_gaps()
		
end

// looks for missing O3x record (a 4 second gap in time), inserts a nan where record should be.
function fixO3x_gaps()

	wave gcT = timewo3x
	wave o3x
	wave yy = o3xyy
	wave mm = o3xmm
	wave dd = o3xdd
	wave hh = o3xhh
	wave mn = o3xmin
	wave ss = o3xss
	wave gcT = timewo3x
	SVAR loadedwvs = root:S_OzoneXwaves
	variable n, wn
	string wv

	make /o/d/n=(numpnts(o3x)) o3xT
	o3xT = date2secs(2000+yy, mm, dd) + hh*60*60 + mn*60 + ss
	variable del = (gcT[0] - o3xT[0])		// difference between QNX time and O3x time
	o3xT += del
	SetScale d 0,0,"dat",o3xT

	// for diagnostics 
	// make /o/n=(numpnts(gcT)) diff = o3xT - gcT

	// look for missing point in o3x data.  This is a 4 second gap.
	for(n=0;n<numpnts(gcT);n+=1)
		if ((o3xT[n] - o3xT[n-1]) == 4)	// 4 seconds
			InsertPoints numpnts(gcT), 1, gcT, o3xT
			gcT[Inf] = gcT[numpnts(gcT)-2]+2
			for(wn=0;wn<ItemsInList(loadedwvs);wn+=1)
				wv = StringFromList(wn, loadedwvs)
				if (cmpstr(wv, "TimeWo3x") != 0)
					InsertPoints numpnts($wv), 1, $wv
					shiftwave($wv, n, 1)
				endif
			endfor
			shiftwave(o3xT, n, 1)
			o3xT[n] = o3xT[n-1]+2			// 2 seconds
			// make /o/n=(numpnts(gcT)) diff = o3xT - gcT
		endif
	endfor
end

// function inserts a nan at pt and shifts the data down
function shiftwave(wv, pt, step)
	wave wv
	variable pt, step
	
	duplicate /O/FREE wv, tempwv
	wv[pt,Inf] = tempwv[p-step]
	wv[pt] = nan
end

Function DataRoutines_H2O()

	SVAR tdls = root:S_WaterWaves
	Variable i, j, rec
	String wvs, com
	Wave tdlrec

	wvs = ReplaceString(";", tdls, ",")

	// Remove all tdlrec <= 0 lines from h2o data
	Extract/FREE/INDX tdlrec, tdlrec0, tdlrec <= 0
	sprintf com, "Deletepoints 0, %d, %s", numpnts(tdlrec0)-1, wvs
	execute com
	
	// Delete extra records
	Extract/FREE/INDX tdlrec, tdlrecDup, tdlrec[p]==tdlrec[p+1]
	for(i=numpnts(tdlrecDup); i>=0; i-=1)
		sprintf com, "Deletepoints %d, 1, %s", tdlrecDup[i]+1, wvs
		execute com
	endfor
	
	// Insert missing records
	for(i=0; i<numpnts(tdlrec)-1; i+=1)
		rec = tdlrec[i]
		if (tdlrec[i+1] != rec+1)
			printf "Inserting H2O record at %d.\r", rec+1
			for(j=0; j<ItemsInList(tdls); j+=1)
				wvs = StringFromList(j, tdls)
				wave wv = $wvs
				InsertPoints i+1, 1, wv
				if (cmpstr(wvs, "TimeWH2O") == 0)
					wv[i+1] = (wv[i] + wv[i+2])/2
				elseif(cmpstr(wvs, "tdlrec") == 0)
					wv[i+1] = rec + 1
				else
					wv[i+1] = nan
				endif
			endfor
		endif
	endfor
	
	// remove 0 and nan records (added this routine 180604 GSD)
//	wvs = ReplaceString(";", tdls, ",")
//	wave pos = root:tdl_pos
//	Extract /INDX/FREE pos, badpoints, (pos==0) || (numtype(pos)==2)
//	for(i=numpnts(badpoints)-1; i>=0; i-=1)
//		sprintf com, "Deletepoints %d, 1, %s", badpoints[i], wvs
//		execute com
//	endfor

// replace 0s with NaNs (added 180607)
wave pos = root:tdl_pos
Extract /INDX/FREE pos, badpoints, pos==0
for(i=0; i<numpnts(badpoints); i+=1)
	for(j=0; j<ItemsInList(tdls); j+=1)
		wvs = StringFromList(j, tdls)
		wave wv = $wvs
		if (cmpstr(wvs, "tdl_best")==0)
			wv[badpoints[i]] = NaN
		else
			wv[badpoints[i]] = SelectNumber(wv[badpoints[i]], NaN, wv[badpoints[i]])
		endif
	endfor	
endfor
	
	Wave TT = root:TimeWH2O
	// Save pseudo original time wave
	// doesn't work with concatenation
	Duplicate /o TT, TimeWh2o_org
	
//	// Respace time wave (removed 180606)
//	Variable delta = (TT[INF]-TT[0])/numpnts(TT)
//	Printf, "Respacing H2O Time wave.  Delta %2.4f\r", delta
//	TT = TT[0] + delta*p

End

// injection bit waves and pres, temp, and flow injection waves
function CreateInjWaves( )
	
	wave GCstate = $"GCstate"
	
	print "Creating injection waves..."
	
	duplicate/o GCstate injBit, injBitm10
	
	injBit = SelectNumber(((GCstate[p]==1)+(GCstate[p]==3)),NaN,1)
	injBitm10 = SelectNumber(((GCstate[p+10]==1)+(GCstate[p+10]==3)),NaN,1)
	
	wave timeW = $"timeWgc"
	wave pres = $"pres_SL"
	wave temp1 = $"temp_SL1"
	wave temp2 = $"temp_SL2"
	wave temp3 = $"temp_SL3"
	wave flow = $"flow_SL"
	wave ssv = $"ssv"
	wave calssv = $"valv_cal"
		
	string timeWinjStr = NameOfWave(timeW) + "_inj"
	string timeWinjm10Str = NameOfWave(timeW) + "_injm10"
	string presInjStr = NameOfWave(pres) + "_inj"
	string temp1InjStr = NameOfWave(temp1) + "_inj"
	string temp2InjStr = NameOfWave(temp2) + "_inj"
	string temp3InjStr = NameOfWave(temp3) + "_inj"
	string flowInjStr = NameOfWave(flow) + "_inj"
	string flowInj10Str = NameOfWave(flow) + "_injm10"
	string ssvInjStr = NameOfWave(ssv) + "_inj"
	string calInjStr = NameOfWave(calssv) + "_inj"
	
	duplicate /o timeW, $timeWinjStr, $timeWinjm10str
	wave timeWinj = $timeWinjStr
	wave timeWinjm10 = $timeWinjm10Str
	
	duplicate /o pres, $presInjStr
	wave presInj = $presInjStr

	duplicate /o temp1, $temp1InjStr
	wave temp1inj = $temp1InjStr
	duplicate /o temp2, $temp2InjStr
	wave temp2inj = $temp2InjStr
	duplicate /o temp3, $temp3InjStr
	wave temp3inj = $temp3InjStr
	
	duplicate /o flow, $flowInjStr, $flowInj10Str
	wave flowInj = $flowInjStr
	wave flow10Inj = $flowInj10Str
	
	duplicate /o ssv, $ssvInjStr
	wave ssvInj = $ssvInjStr
	
	duplicate /o calssv, $calInjStr
	wave calInj = $calInjStr

	timeWinj 	*= injBit			; RemoveNaNs(timeWinj)
	presInj 	*= injBit			; RemoveNaNs(presInj)
	temp1Inj 	*= injBit			; RemoveNaNs(temp1Inj)
	temp2Inj 	*= injBit			; RemoveNaNs(temp2Inj)
	temp3Inj 	*= injBit			; RemoveNaNs(temp3Inj)
	flowInj 	*= injBit			; RemoveNaNs(flowInj)
	ssvInj		*= injBit			; RemoveNaNs(ssvInj)
	calInj		*= injBit			; RemoveNaNs(calInj)
	
	timeWinjm10 	*= injBitm10	; RemoveNaNs(timeWinjm10)
	flow10Inj 		*= injBitm10	; RemoveNaNs(flow10Inj)

end

function EngPlot1(Ywv, ylabel,chop)
	wave Ywv
	string ylabel
	variable chop
	
	if(numtype(chop)!=2)
		lowchop(Ywv,chop)
	endif
	wave timeW = $"timeWgc"
	string win = NameOfWave(Ywv) + "win"
	
	DoWindow/K $win
	Display /K=1/W=(88,108,811,464) Ywv vs timeW as NameOfWave(Ywv)
	DoWindow/C $win
	SetAxis/A/N=1 left
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label bottom "Time (gmt)"
	Label left ylabel
	
EndMacro

function EngPlot2(Ywv1, Ywv2, ylabel,chop)
	wave Ywv1, Ywv2
	string ylabel
	variable chop
	if(numtype(chop)!=2)
		lowchop(Ywv1,chop)
		lowchop(Ywv2,chop)		
	endif
	
	wave timeW = $"timeWgc"
	string win = NameOfWave(Ywv1) + "_and_" + NameOfWave(Ywv2)
	string winT = NameOfWave(Ywv1) + " & " + NameOfWave(Ywv2)
	string com
	
	DoWindow/K $win
	Display /K=1/W=(88,108,811,464) Ywv1 vs timeW as NameOfWave(Ywv1)
	AppendToGraph Ywv2 vs timeW
	DoWindow/C $win
	DoWindow/T $win, winT
	
	SetAxis/A/N=1 left
	sprintf com, "ModifyGraph rgb(%s)=(0,0,65535)", NameOfWave(Ywv2)
	execute com
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left ylabel
	Label bottom "Time (gmt)"
	
	sprintf com, "Legend/N=text0/J \"\\\s(%s) %s\\r\\\s(%s) %s\"", NameOfWave(Ywv1), NameOfWave(Ywv1), NameOfWave(Ywv2), NameOfWave(Ywv2)
	execute com

EndMacro

function EngPlot3(Ywv1, Ywv2, Ywv3, ylabel,chop)
	wave Ywv1, Ywv2, Ywv3
	string ylabel
	variable chop
	if(numtype(chop)!=2)
		lowchop(Ywv1,chop)
		lowchop(Ywv2,chop)		
		lowchop(Ywv3,chop)		
	endif
	
	wave timeW = $"timeWgc"
	string win = NameOfWave(Ywv1) + NameOfWave(Ywv2) + "_and_" + NameOfWave(Ywv3)
	string winT = NameOfWave(Ywv1) + ", " + NameOfWave(Ywv2) + " & " + NameOfWave(Ywv3)
	string com
	
	DoWindow/K $win
	Display /K=1/W=(88,108,811,464) Ywv1 vs timeW as NameOfWave(Ywv1)
	AppendToGraph Ywv2 vs timeW
	AppendToGraph Ywv3 vs timeW
	DoWindow/C $win
	DoWindow/T $win, winT
	
	SetAxis/A/N=1 left
	sprintf com, "ModifyGraph rgb(%s)=(0,0,65535)", NameOfWave(Ywv2)
	execute com
	sprintf com, "ModifyGraph rgb(%s)=(0,0,0)", NameOfWave(Ywv3)
	execute com
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left ylabel
	Label bottom "Time (gmt)"
	
	sprintf com, "Legend/N=text0/J \"\\\s(%s) %s\\r\\\s(%s) %s\\r\\\s(%s) %s\"", NameOfWave(Ywv1), NameOfWave(Ywv1), NameOfWave(Ywv2), NameOfWave(Ywv2), NameOfWave(Ywv3), NameOfWave(Ywv3)
	execute com

EndMacro

function EngPlot2rt(Ywv1, Ywv2,chop1,chop2)
	wave Ywv1, Ywv2
	variable chop1
	variable chop2
	
	if(numtype(chop1)!=2)
		lowchop(Ywv1,chop1)
	endif	
	
	if(numtype(chop2)!=2)
		lowchop(Ywv2,chop2)		
	endif	
	
	wave timeW = $"timeWgc"
	string win = NameOfWave(Ywv1) + "win"
	string com
	
	DoWindow/K $win
	Display /K=1/W=(88,108,811,464) Ywv1 vs timeW as NameOfWave(Ywv1)
	AppendToGraph /r Ywv2 vs timeW
	DoWindow/C $win

	sprintf com, "ModifyGraph rgb(%s)=(0,0,65535)", NameOfWave(Ywv2)
	execute com
	ModifyGraph grid(bottom)=1
	ModifyGraph mirror(bottom)=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left NameOfWave(Ywv1) 
	Label right NameOfWave(Ywv2)
	Label bottom "Time (gmt)"
	
	sprintf com, "Legend/N=text0/J \"\\\s(%s) %s\\r\\\s(%s) %s\"", NameOfWave(Ywv1), NameOfWave(Ywv1), NameOfWave(Ywv2), NameOfWave(Ywv2)
	execute com

EndMacro

function O3Plot1(Ywv, ylabel)
	wave Ywv
	string ylabel

	wave timeW = $"timeWo3"
	string win = NameOfWave(Ywv) + "win"
	
	DoWindow/K $win
	Display /K=1/W=(88,108,811,464) Ywv vs timeW as NameOfWave(Ywv)
	DoWindow/C $win
	SetAxis/A/N=1 left
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	ModifyGraph rgb=(3,52428,1)
	Label bottom "Time (gmt)"
	Label left ylabel
	
EndMacro

function O3xPlot1(Ywv, ylabel)
	wave Ywv
	string ylabel

	wave timeW = $"timeWo3x"
	string win = NameOfWave(Ywv) + "win"
	
	DoWindow/K $win
	Display /K=1/W=(88,108,811,464) Ywv vs timeW as NameOfWave(Ywv)
	DoWindow/C $win
	SetAxis/A/N=1 left
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	//ModifyGraph rgb=(3,52428,1)
	Label bottom "Time (gmt)"
	Label left ylabel
	
EndMacro

function H2OPlot1(Ywv, ylabel)
	wave Ywv
	string ylabel

	wave timeW = $"timeWh2o"
	string win = NameOfWave(Ywv) + "win"
	
	DoWindow/K $win
	Display /K=1/W=(88,108,811,464) Ywv vs timeW as NameOfWave(Ywv)
	DoWindow/C $win
	SetAxis/A/N=1 left
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	ModifyGraph rgb=(3,52428,1)
	Label bottom "Time (gmt)"
	Label left ylabel
	
EndMacro

function H2OPlot2(Ywv1, Ywv2, ylabel)
	wave Ywv1, Ywv2
	string ylabel

	wave timeW = $"timeWh2o"
	string win = NameOfWave(Ywv1) + "_and_" + NameOfWave(Ywv2)
	string winT = NameOfWave(Ywv1) + " & " + NameOfWave(Ywv2)
	string com

	DoWindow/K $win
	Display /K=1/W=(88,108,811,464) Ywv1 vs timeW as NameOfWave(Ywv1)
	AppendToGraph Ywv2 vs timeW

	DoWindow/C $win
	DoWindow/T $win, winT
	
	SetAxis/A/N=1 left
	sprintf com, "ModifyGraph rgb(%s)=(0,0,65535)", NameOfWave(Ywv2)
	execute com
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left ylabel
	Label bottom "Time (gmt)"
	
	sprintf com, "Legend/N=text0/J \"\\\s(%s) %s\\r\\\s(%s) %s\"", NameOfWave(Ywv1), NameOfWave(Ywv1), NameOfWave(Ywv2), NameOfWave(Ywv2)
	execute com

EndMacro

function H2OPlot2rt(Ywv1, Ywv2)
	wave Ywv1, Ywv2
	
	wave timeW = $"timeWH2O"
	string win = NameOfWave(Ywv1) + "win"
	string com
	
	DoWindow/K $win
	Display /K=1/W=(88,108,811,464) Ywv1 vs timeW as NameOfWave(Ywv1)
	AppendToGraph /r Ywv2 vs timeW
	DoWindow/C $win

	sprintf com, "ModifyGraph rgb(%s)=(0,0,65535)", NameOfWave(Ywv2)
	execute com
	ModifyGraph grid(bottom)=1
	ModifyGraph mirror(bottom)=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left NameOfWave(Ywv1) 
	Label right NameOfWave(Ywv2)
	Label bottom "Time (gmt)"
	
	sprintf com, "Legend/N=text0/J \"\\\s(%s) %s\\r\\\s(%s) %s\"", NameOfWave(Ywv1), NameOfWave(Ywv1), NameOfWave(Ywv2), NameOfWave(Ywv2)
	execute com

EndMacro

function SampleTempsInj() 
	if (!WaveExists(timeWgc_inj))
		return 0
	endif
	string win = "SampleTemps"
	DoWindow /k $win
	Display /W=(14,45,737,401) temp_SL1_inj,temp_SL2_inj,temp_SL3_inj vs timeWgc_inj
	DoWindow /C $win
	ModifyGraph rgb(temp_SL2_inj)=(0,0,65535)
	ModifyGraph rgb(temp_SL3_inj)=(0,0,0)
	ModifyGraph grid(bottom)=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left "Sample Temp at Injection (C)"
	Label bottom "Time (gmt)"
	SetAxis/A/N=1 left
	Legend/N=text0/J/X=6.55/Y=2.56 "\\s(temp_SL1_inj) temp_SL1_inj\r\\s(temp_SL2_inj) temp_SL2_inj\r\\s(temp_SL3_inj) temp_SL3_inj"
End

function SamplePressInj() 
	if (!WaveExists(timeWgc_inj))
		return 0
	endif
	string win = "SamplePress"
	DoWindow /k $win
	Display /W=(37,76,760,432) pres_SL_inj vs timeWgc_inj
	DoWindow /c $win
	ModifyGraph mode=3
	ModifyGraph marker=19
	ModifyGraph msize=2
	ModifyGraph grid(bottom)=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left "Sample Press at Injection (mbar)"
	Label bottom "Time (gmt)"
	SetAxis/A/N=1 left
EndMacro

function SampleFlowInj() 
	if (!WaveExists(timeWgc_injm10))
		return 0
	endif
	string win = "SampleFlows"
	DoWindow /k $win
	Display /W=(63,110,786,466) flow_SL_injm10 vs timeWgc_injm10
	DoWindow /C $win
	AppendToGraph flow_SL_inj vs timeWgc_inj
	ModifyGraph mode=3
	ModifyGraph marker(flow_SL_injm10)=19,marker(flow_SL_inj)=8
	ModifyGraph rgb(flow_SL_injm10)=(0,0,65535)
	ModifyGraph msize=2
	ModifyGraph grid(bottom)=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	ModifyGraph zColor(flow_SL_injm10)={ssv_inj,0,1,Rainbow}
	Label left "Sample Flow (cc/min)"
	Label bottom "Time (gmt)"
	SetAxis/A/N=1/E=1 left
	Legend/N=text0/J/X=5.83/Y=3.42 "\\s(flow_SL_inj) Flow at injection\r\\s(flow_SL_injm10) Flow 10s prior to injection "
EndMacro



function PlotGCEverything()

	CH3plots()
	CH2plots()
	CH1plots()
	SampPlots()
	CylinderPlots()
	PowerPlots()
	ThermPlots()
	EngPlot1( pres_extern, "External Pressure (mbar)",0)
	EngPlot1( pres_PUMP, "Pump Pressure (mbar)",0)
	
	execute "TileWindows/O=1/C/P"
	
end


function OzonePlots()

	//  Modified November 2016 for Model 211 Ozone
	O3xPlot1(o3xflowa, "Cell flows (cc/min)")
	ModifyGraph rgb=(0,0,65535)
	appendtograph o3xflowb vs timewo3x
	legend
	
	//O3Plot1(o3lmpv, "Ozone Lamp Voltages (V)")
	//appendtograph o3lmpsd vs timewo3
	//  	AppendToGraph/R o3xdet1,o3xdet2 vs TimeWo3x
	//  	ModifyGraph rgb(o3xdet1)=(0,0,65535),rgb(o3xdet2)=(0,0,0)
	//  	Label right "OzoneX Lamp Voltages (V)"
	//legend

	O3xPlot1(o3xbest, "Ozone (ppb)")
	//appendtograph o3xbest vs timewo3x
	//legend
	
	O3xPlot1(o3xtemp, "Ozone Cell Temp (C)")
	//appendtograph o3xtemp vs timewo3x
	//legend
	
	O3xPlot1(o3xpres, "Ozone Cell Pressure (mbar)")
	//appendtograph o3xpres vs timewo3x
	//legend
	
	execute "TileWindows/O=1/C/P"

end

function H2OPlots()

//	if (WaveExists(H2O_Pelt_Sp))
//		H2OPlot2(H2O_Pelt, H2O_Pelt_Sp,"Peltier T and Setpoint (deg. C)")
//	endif

	H2OPlot1(tdl_zer, "zero")
	H2OPlot2(tdl_pos, tdl_posB, "Line Position")
	H2OPlot2rt(tdl_pow, tdl_amp)
	H2OPlot2rt(tdl_T, tdl_P)
	appendtograph tdl_elecT vs timeWh2o
	ModifyGraph rgb(tdl_elecT)=(0,65535,0)

	H2OPlot2(tdl_H2OCD, tdl_best, "Water (ppm)")
	SetAxis left 0,400
		
	H2OPlot2(tdl_shortH2O, tdl_longH2O,"Water (ppm)")
	appendtograph tdl_H2OB vs timeWh2o
	appendtograph tdl_best vs timeWh2o
	ModifyGraph rgb(tdl_best)=(0,65535,0)
	ModifyGraph rgb(tdl_H2OB)=(0,0,0)

	execute "TileWindows/O=1/C/P"
	
end

function CH3plots()

	EngPlot2(Flow_M3, Flow_BF3, "Flow (cc/min)",0)
	EngPlot2(Flow_M3_sp, Flow_BF3_sp, "Flow (cc/min)",0)
	EngPlot1(pres_BP3, "Pressure (psi)",0)
	EngPlot1(pres_ECD3, "Pressure (mbar)",0)
	EngPlot1(CH3_ECD, "Temp (C)",0)
	EngPlot2(CH3_Col, CH3_Post, "Temp (C)",0)
	EngPlot1(ecdA_CH3, "Response (Hz)",0)

	execute "TileWindows/O=1/C/P"

end

function CH2plots()

	EngPlot2(Flow_M2, Flow_BF2, "Flow (cc/min)",0)
	EngPlot2(Flow_M2_sp, Flow_BF2_sp, "Flow (cc/min)",0)
	EngPlot2(pres_BP2, pres_BP2_sp, "Pressure (psi)",0)
	EngPlot1(pres_ECD2, "Pressure (mbar)",0)
	EngPlot1(CH2_ECD, "Temp (C)",0)
	EngPlot1(CH2_Col, "Temp (C)",0)
	EngPlot1(ecdA_CH2, "Response (Hz)",0)

	execute "TileWindows/O=1/C/P"

end

function CH1plots()

	EngPlot2(Flow_M1, Flow_BF1, "Flow (cc/min)",0)
	EngPlot2(Flow_M1_sp, Flow_BF1_sp, "Flow (cc/min)",0)
	EngPlot2(pres_BP1, pres_BP1_sp, "Pressure (psi)",0)
	EngPlot1(pres_ECD1, "Pressure (mbar)",0)
	EngPlot1(CH1_ECD, "Temp (C)",0)
	EngPlot1(CH1_Col, "Temp (C)",0)
	EngPlot1(ecdA_CH1, "Response (Hz)",0)

	execute "TileWindows/O=1/C/P"

end

function SampPlots()
	
	SampleTempsInj()
	SamplePressInj()
	SampleFlowInj()	
//	EngPlot2(temp_SL1, temp_SL2, "Samp Loop Temps (C)")
//	EngPlot1( pres_SL, "Sample Loop Press (mbar)")
//	EngPlot1( flow_SL, "Sample Loop Flow (cc/min)")
		
end

function CylinderPlots()
	
	EngPlot1(presL_N2, "Pressure (psi)",0)
	EngPlot1(presL_cal, "Pressure (psi)",0)
	EngPlot1(presL_dope, "CO2 Pressure (psi)",-5)
	EngPlot1(presH_123, "Pressure (psi)",0)
//	EngPlot1(pres_bp1, "N2O Pressure (psi)",0)

end

function PowerPlots()
	
	EngPlot1(volt_28, "+28 or +24 (Volts)",0)
	EngPlot1(volt_15, "+15 or -15 (Volts)",-20)
	EngPlot1(volt_5, "+5 or +12 (Volts)",0)
	
end

function ThermPlots()

	EngPlot3(temp_SL1, temp_SL2, temp_SL3, "Sample Loops (C)",0)
	EngPlot1(temp_pump, "Pump temp (C)", -40)
	EngPlot1(temp_amb, "Internal temp (C)",-40)
	EngPlot2(temp_gasB_N, temp_gasB_C, "External gas bottles (C)", -40)

end

function RH2ppm(wv,wv1,wv2,wv3)
wave wv	// T (K)
wave wv1	// P (mbar or hPa)
wave wv2	//  RH (in %)
wave wv3	// OUTPUT:  H2Oppmv

variable c0=   0.4931358
variable c1= -0.46094296e-2
variable c2=   0.13746454e-4
variable c3= -0.12743214e-7

duplicate /o wv theta

theta -= c0
theta -= c1*wv
theta -= c2*(wv^2)
theta -= c3*(wv^3)

variable bi= -0.58002206e4
variable b0=  0.13914993e1
variable b1= -0.48640239e-1
variable b2=   0.41764768e-4
variable b3= -0.14452093e-7
variable b4=   6.5459673

duplicate /o theta satpv

satpv = ln(satpv) * b4
satpv += bi/theta
satpv += b0
satpv += b1*theta
satpv += b2*(theta^2)
satpv += b3*(theta^3)

satpv = exp(satpv)/100

duplicate /o wv2  wv3
wv3=nan

wv3 = ((10^4)*wv2*satpv)/(wv1-(wv2*satpv/100))

end

