#pragma rtGlobals=1		// Use modern global access method.

#include "macros-utilities"
#include "macros-geoff"
#include "macros-Strings and Lists"
#include <strings as lists>
#include <Concatenate Waves>

menu "PANTHER"
	"First Make Inj Waves", MakeInjWvs(gcstate,ssv1,timew,1)
	Submenu "SF6"
		"Plot All SF6<B /F1", SF6plots(); sprintf com, "TileWindows/O=1/C"; execute com
		" Flows", EngPlot2(FlowM_SF6, FlowB_SF6)
		" Flows - lock loops", EngPlot2(voltM_SF6, voltB_SF6)
		" Pressure BF", EngPlot1(PresBP_SF6)
		" Pressure BF - lock loops", EngPlot1(voltBP_SF6)
		" Pressure ECD", EngPlot1(PresE_SF6)
		" Pressure ECD - lock loops", EngPlot1(voltE_SF6)
		" Temp ECD", EngPlot1(SF6_ECD); lowchop(SF6_ECD, -1)
		" Temp Columns", EngPlot2(SF6_Col, SF6_Post); lowchop(SF6_Col, -1); lowchop(SF6_Post, -1)
		" ECD Response", EngPlot1(ecdA_SF6); lowchop(ecdA_SF6, 0)
	end
	Submenu "F11"
		"Plot All F11<B /F2", F11plots();string com; sprintf com, "TileWindows/O=1/C"; execute com
		" Flows", EngPlot2(FlowM_F11, FlowB_F11)
		" Flows - lock loops", EngPlot2(voltM_F11, voltB_F11)
		" Pressure BF", EngPlot1(PresBP_F11)
		" Pressure BF - lock loops", EngPlot1(voltBP_F11)
		" Pressure ECD", EngPlot1(PresE_5)
		" Pressure ECD - lock loops", EngPlot1(voltE_F11)
		" Temp ECD", EngPlot1(F11_ECD); lowchop(F11_ECD, -1)
		" Temp Column", EngPlot1(F11_Col); lowchop(F11_Col, -1)
		" ECD Response", EngPlot1(ecdA_F11); lowchop(ecdA_F11, 0)
	end
	Submenu "CO"
		"Plot All CO<B /F3", COplots()
		" Flows", EngPlot2(FlowM_CO, FlowB_CO);string com; sprintf com, "TileWindows/O=1/C"; execute com
		" Flows - lock loops", EngPlot2(voltM_CO, voltB_CO)
		" Pressure BF", EngPlot1(PresBP_CO)
		" Pressure BF - lock loops", EngPlot1(voltBP_CO)
		" Pressure ECD", EngPlot1(PresE_F11)
		" Pressure ECD - lock loops", EngPlot1(voltE_CO)
		" Temp ECD", EngPlot1(CO_ECD); lowchop(CO_ECD, -1)
		" Temp Column", EngPlot1(CO_Col); lowchop(CO_Col, -1)
		" ECD Response", EngPlot1(ecdA_CO); lowchop(ecdA_CO, 0)
	end
	Submenu "PAN"
		"Plot All PAN<B /F4", PANplots();string com; sprintf com, "TileWindows/O=1/C"; execute com
		" Column Temp", EngPlot1(ColT_PAN)
		" Pressures", EngPlot2(Pres1_PAN, Pres2_PAN)
		" Press - lock loops", EngPlot2(voltM_PAN, voltB_PAN)
		" Pressure ECD", EngPlot1(PresE_PAN)
		" Pressure ECD - lock loops", EngPlot1(voltE_PAN)
		" Temp ECD", EngPlot1(PAN_ECD); lowchop(PAN_ECD, -1)
		" ECD Response", EngPlot1(ecdA_PAN); lowchop(ecdA_PAN, 0)
	end
	Submenu "Mass Spec"
		"Plot All Mass Spec.<B /F5", MSplots();string com; sprintf com, "TileWindows/O=1/C"; execute com
		" Cold Block Temps", EngPlot2(Trap2_CB, Trap1_CB)
		" Column Temps", EngPlot2(ColT_MS1, ColT_MS2)
		" ColdBlock & Column 1 temps", EngPlot2rt(Trap1_CB, ColT_MS1); lowchop(ColT_MS1, -99.8); lowchop(Trap1_CB, -99.8)
		" ColdBlock & Column 2 temps", EngPlot2rt(ColT_MS2, Trap2_CB); lowchop(ColT_MS2, -99.8); lowchop(Trap2_CB, -99.8)
		" Column 1 Pressures", EngPlot2rt(PresMS1, VoltMS1)
		" Column 2 Pressures", EngPlot2rt(PresMS2, VoltMS2)
		" Avg. Response Chan 0", EngPlot1(msdA_0); lowchop(msdA_0, -1)
		" Avg. Response Chan 1", EngPlot1(msdA_1); lowchop(msdA_1, -1)
		" Avg. Response Chan 2", EngPlot1(msdA_2); lowchop(msdA_2, -1)
		" Avg. Response Chan 3", EngPlot1(msdA_3); lowchop(msdA_3, -1)
	end
	"-"
	Submenu "Sampling"
		"Plot All Sampling <B /F6", SampPlots();string com; sprintf com, "TileWindows/O=1/C"; execute com
		" GC sample loop pressure", EngPlot3(Pres_sl,Pres_SL_injcal,Pres_SL_injair); ModifyGraph mode=3,marker=19,msize=3,mode(Pres_sl)=0,rgb(Pres_sl)=(0,0,0)
		" PAN sample loop pressure", EngPlot3(Presbp_pan,Pres_panSL_injcal,Pres_panSL_injair); ModifyGraph mode=3,marker=19,msize=3,mode(Presbp_pan)=0,rgb(Presbp_pan)=(0,0,0)
		" GC sample loop flow", EngPlot4(flow_packsl,flow_packsl_injcal,flow_packsl_injair,flow_packsl_15cal,flow_packsl_15air);ModifyGraph mode=3,msize=3,marker(flow_packsl_15cal)=19,marker(flow_packsl_15air)=19,marker(flow_packsl_injcal)=17,marker(flow_packsl_injair)=17,mode(Flow_Packsl)=0,rgb(Flow_Packsl)=(0,0,0)
		" PAN sample loop flow", EngPlot4(flow_pansl,flow_pansl_injcal,flow_pansl_injair,flow_pansl_15cal,flow_pansl_15air);ModifyGraph mode=3,msize=3,marker(flow_pansl_15cal)=19,marker(flow_pansl_15air)=19,marker(flow_pansl_injcal)=17,marker(flow_pansl_injair)=17,mode(Flow_Pansl)=0,rgb(Flow_Pansl)=(0,0,0)
		" (NOT MS sample loop pressure", EngPlot2rt(PresE_5, VoltE_5)
		" MS sample loop flow", EngPlot1(Flow_MSsl)
		" Ext. inlet pressure (Un-Cal)", EngPlot1(Pres_Inlet)
		" SF6 samp temps", EngPlot1(Temp_SF6sl)
		" F11 samp temps", EngPlot1(Temp_F11sl)
		" CO samp temps", EngPlot1(Temp_COsl)
		" PAN samp temps", EngPlot1(Temp_PANsl)
		" PAN Source pressure and Flow", EngPlot2rt(PresSrc_PAN, FlowSrc_PAN)
	end
	Submenu "Cylinders"
		"Plot All Cylinder Pressures<B /F7", CylinderPlots();string com; sprintf com, "TileWindows/O=1/C"; execute com
		" N2", EngPlot2rt(PresH_N2, PresL_N2)
		" He", EngPlot2rt(PresH_He, PresL_He)
		" Cal1", EngPlot2rt(PresH_Cal1, PresL_Cal1)
		" Cal2", EngPlot2rt(PresH_Cal2, PresL_Cal2)
		" CO2", EngPlot2rt(PresH_CO2, PresL_CO2)
		" N2O", EngPlot2rt(PresH_N2O, PresL_N2O)
		" Zero Air", EngPlot2rt(PresH_ZA, PresL_ZA)
		" PAN Source", EngPlot2rt(PresH_PAN, PresL_PAN)
	end
	Submenu "Power"
		"Plot All Power<B", PowerPlots();string com; sprintf com, "TileWindows/O=1/C"; execute com
		" +28",  EngPlot2(Pow_p28pri, Pow_p28sec)
		" +24", EngPlot2(Pow_p24gsv, Pow_p24ms)
		" +15 pelts",  EngPlot2(Pow_p15pel1, Pow_p15pel2)
		" +15 and +12", EngPlot2(Pow_p15, Pow_p12)
		" +5", EngPlot1(Pow_p5)
		" -15", EngPlot1(Pow_m15)
	end
	Submenu "Temperatures"
		"Plot All Temps<B", TempPlots();string com; sprintf com, "TileWindows/O=1/C"; execute com
		" GSV board and electrometers", EngPlot2(Temp_GSVbo, Temp_elect)
		" SF6 samp temps", EngPlot2(Temp_SF6sl,Temp_PANsl)
		" F11 samp temps", EngPlot2(Temp_F11sl,Temp_COsl)		
		" SF6 Cols", EngPlot2(SF6_Col, SF6_Post); lowchop(SF6_Col, -1); lowchop(SF6_Post, -1)
		" F11 Column", EngPlot1(F11_Col); lowchop(F11_Col, -1)
		" CO Column", EngPlot1(CO_Col); lowchop(CO_Col, -1)		
		" PAN Column", EngPlot1(ColT_PAN)
		" SF6 ECD", EngPlot1(SF6_ECD); lowchop(SF6_ECD, -1)
		" F11 ECD", EngPlot1(F11_ECD); lowchop(F11_ECD, -1)
		" CO ECD", EngPlot1(CO_ECD); lowchop(CO_ECD, -1)
		" PAN ECD", EngPlot1(PAN_ECD); lowchop(PAN_ECD, -1)

	end
	"-"
	"Close All Graphs<B /1", removeDisplayedGraphs()
end



Function BeforeFileOpenHook(refNum, fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr, fileKind)
	Variable refNum, fileKind
	String fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr
	
		
	variable len = strlen(fileNameStr)
	string com
	
	if ((cmpstr(fileNameStr[len-3,len], "itx")==0) * (fileKind == 5))
		//LoadSTEALTHchrom(fileNameStr, fileNameStr[len-14, len-8])
		return 1
	endif
	
	if (cmpstr(fileNameStr[len-3,len], "txt")==0)
		if ( exists( "TimeW" ) != 1 )
			make /d/n=0 TimeW
		endif
		if ( cmpstr(fileNameStr[0,2], "eng") == 0 )
			loadPANTHEReng( pathNameStr, fileNameStr )
		endif
		if ( cmpstr(fileNameStr[0,2], "dig") == 0 )
			loadPANTHERdig( pathNameStr, fileNameStr )
		endif
		return 1
	endif	
	

end


function loadPANTHEReng( pathNameStr, fileNameStr )
	string pathNameStr, fileNameStr

	variable yyyy, mm, dd, Need2Cat = 0

// If need to concatinate, the detection code below is too simple.  Needs improvement. 	
//	if ( exists( "FlowM_CO" ) == 1 )
//		Need2Cat = 1
//		PrepForMoreData()
//	endif

	yyyy = str2num(fileNameStr[3,4]) + 2000
	mm = str2num(fileNameStr[5,6])
	dd = str2num(fileNameStr[7,8])
	LoadWave/A/J/W/O/Q/K=0/P=$pathNameStr/V={" "," $",0,0}/L={1,3,0,0,0} fileNameStr

	wave timewv = $"TimeW"
	timewv += date2secs(yyyy,mm,dd)
	FixTimeWave( timewv )
	
//	if ( Need2Cat == 1 )
//		CatEngData()
//	endif

end

function loadPANTHERdig( pathNameStr, fileNameStr )
	string pathNameStr, fileNameStr

	variable yyyy, mm, dd, Need2Cat = 0
	
//	if ( exists( "ssv1" ) == 1 )
//		Need2Cat = 1
//		PrepForMoreData()  // need to make one for the dig data
//	endif

	yyyy = str2num(fileNameStr[3,4]) + 2000
	mm = str2num(fileNameStr[5,6])
	dd = str2num(fileNameStr[7,8])
	LoadWave/A/J/W/O/Q/K=0/P=$pathNameStr/V={" "," $",0,0}/L={1,3,0,0,0} fileNameStr

	wave timewv = $"TimeW"
	timewv += date2secs(yyyy,mm,dd)
	FixTimeWave( timewv )

//	if ( Need2Cat == 1 )
//		CatEngData()
//	endif

end

function FixTimeWave(timewv)
	wave timewv
	
	variable inc = numpnts(timewv)
	variable /d t1, t0
	
	do
		t1 = timewv[inc]
		t0 = timewv[inc-1]
		if ( t0 > t1 )
			timewv[0,inc-1] -= 60*60*24
		endif
		inc -= 1
	while (inc > 1)
	
end

function PrepForMoreData()

	string wvstr, nwvstr, com
	variable inc
	wave /t englist

	do
		wvstr = englist[inc]
		nwvstr = wvstr + "_N"
		wave wv = $wvstr
		sprintf com, "rename %s, %s", wvstr, nwvstr
		execute com
		inc+= 1
	while ( inc < numpnts(englist) )
	
end

function CatEngData()

	string wvstr, nwvstr, com
	variable inc
	wave /t englist

	do
		wvstr = englist[inc]
		nwvstr = wvstr + "_N"
		wave wv = $wvstr
		ConcatenateWaves(nwvstr, wvstr)
		killwaves wv
		sprintf com, "rename %s, %s", nwvstr, wvstr
		execute com
		inc+= 1
	while ( inc < numpnts(englist) )
	
end

function EngPlot1(Ywv)
	wave Ywv

	wave TimeWv = $"TimeW"
	string win = NameOfWave(Ywv) + "win"
	
	DoWindow/K $win
	Display /K=1 /W=(88,108,811,464) Ywv vs TimeW as NameOfWave(Ywv)
	DoWindow/C $win
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left NameOfWave(Ywv)
	Label bottom "Time (gmt)"
EndMacro

function EngPlot2(Ywv1, Ywv2)
	wave Ywv1, Ywv2

	wave TimeWv = $"TimeW"
	string win = NameOfWave(Ywv1) + "win"
	string com
	
	DoWindow/K $win
	Display /K=1 /W=(88,108,811,464) Ywv1 vs TimeW as NameOfWave(Ywv1)
	AppendToGraph Ywv2 vs TimeW
	DoWindow/C $win

	sprintf com, "ModifyGraph rgb(%s)=(0,0,65535)", NameOfWave(Ywv2)
	execute com
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left NameOfWave(Ywv1) + " & " + NameOfWave(Ywv2)
	Label bottom "Time (gmt)"
	
	sprintf com, "Legend/N=text0/J \"\\\s(%s) %s\\r\\\s(%s) %s\"", NameOfWave(Ywv1), NameOfWave(Ywv1), NameOfWave(Ywv2), NameOfWave(Ywv2)
	execute com

EndMacro

function EngPlot3(Ywv0, Ywv1, Ywv2)
	wave Ywv0, Ywv1, Ywv2
	variable inc
	
	wave TimeWv = $"TimeW"
	string win = NameOfWave(Ywv1) + "win"
	string com
	
	DoWindow/K $win
	Display /K=1 /W=(88,108,811,464) Ywv0 vs TimeW as NameOfWave(Ywv1)
	AppendToGraph Ywv1 Ywv2 vs TimeW
	DoWindow/C $win

	sprintf com, "ModifyGraph rgb(%s)=(0,0,65535)", NameOfWave(Ywv2)
	execute com
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left NameOfWave(Ywv1) + " & " + NameOfWave(Ywv2)
	Label bottom "Time (gmt)"
	
	sprintf com, "Legend/N=text0/J \"\\\s(%s) %s\\r\\\s(%s) %s\"", NameOfWave(Ywv1), "Cal @ INJ-15", NameOfWave(Ywv2), "Air @ INJ-15"
	execute com
	
	wavestats /q TimeW; inc=(V_max-V_min)/10
	SetAxis bottom V_min+4*inc,V_min+5*inc
	
	

EndMacro

function EngPlot4(Ywv0,Ywv1, Ywv2,Ywv3,Ywv4)
	wave Ywv0, Ywv1, Ywv2, Ywv3, Ywv4
	variable inc
	
	wave TimeWv = $"TimeW"
	string win = NameOfWave(Ywv1) + "win"
	string com
	
	DoWindow/K $win
	Display /K=1 /W=(88,108,811,464) Ywv0 vs TimeW as NameOfWave(Ywv0)
	AppendToGraph Ywv1 Ywv2 Ywv3 Ywv4 vs TimeW
	DoWindow/C $win

	sprintf com, "ModifyGraph rgb(%s)=(0,0,65535)", NameOfWave(Ywv2) 
	execute com
	sprintf com, "ModifyGraph rgb(%s)=(0,0,65535)", NameOfWave(Ywv4) 
	execute com
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left NameOfWave(Ywv1) + " & " + NameOfWave(Ywv2)
	Label bottom "Time (gmt)"
	
	sprintf com, "Legend/N=text0/J \"\\\s(%s) %s\\r\\\s(%s) %s\\r\\\s(%s) %s\\r\\\s(%s) %s\"", NameOfWave(Ywv1), "Cal @ INJ", NameOfWave(Ywv2), "Air @ INJ", NameOfWave(Ywv3), "Cal @ INJ-15", NameOfWave(Ywv4), "Air @ INJ-15"
	execute com

	wavestats /q TimeW; inc=(V_max-V_min)/10
	SetAxis bottom V_min+4*inc,V_min+5*inc

EndMacro
function EngPlot2rt(Ywv1, Ywv2)
	wave Ywv1, Ywv2

	wave TimeWv = $"TimeW"
	string win = NameOfWave(Ywv1) + "win"
	string com
	
	DoWindow/K $win
	Display /K=1 /W=(88,108,811,464) Ywv1 vs TimeW as NameOfWave(Ywv1)
	AppendToGraph /r Ywv2 vs TimeW
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

function MakeInjWvs(wv,wv0,wv1,inc)
wave wv	// gcstate
wave wv0	// ssv1
wave wv1	// eng data timestamps (timew)
variable inc	  //  fudge factor for 2s diff between GCstate injection flags and ITX wavenote injection times (Currently set at 1 second to split the diff)

if((exists("gcstate")!=1)||(exists("ssv1"))!=1)
	print "You must first load the waves: gcstate and ssv1 from the digYYMMDD.txt file"
else

	duplicate /o pansol1 selpos_pan
	selpos_pan += 1					//  Change pan "selpos" values from 0 & 1 (Air & Cal) to 1 & 2
	
	duplicate /o wv1 time_inj
	time_inj=selectnumber(wv[p-inc]==1,nan,time_inj)		// Injection times for packed columns (every 70s)
	
	duplicate /o wv1 time_inj_15
	time_inj_15=selectnumber(wv[p+15-inc]==1,nan,time_inj_15)		// 15 s before Injection times for packed columns (every 70s)
	
	duplicate /o wv1 time_pan_inj
	time_pan_inj=selectnumber(wv[p-2-inc]==1,nan,time_pan_inj)
	duplicate /o time_pan_inj temp
	killnan(temp,temp)
	temp[1, ;2]=nan
	killnan(temp,temp)
	time_pan_inj = temp[binarysearch(temp,wv1)]
	time_pan_inj=selectnumber(time_pan_inj==wv1,nan,time_pan_inj)	// Injection times for PAN  (every 140s)
	
	duplicate /o wv1 time_pan_inj_15
	time_pan_inj_15=selectnumber(wv[p+13-inc]==1,nan,time_pan_inj_15)
	duplicate /o time_pan_inj_15 temp
	killnan(temp,temp)
	temp[1, ;2]=nan
	killnan(temp,temp)
	time_pan_inj_15 = temp[binarysearch(temp,wv1)]
	time_pan_inj_15=selectnumber(time_pan_inj_15==wv1,nan,time_pan_inj_15)	// 15s before  Injection times for PAN (every 140s)
	
	// AIR INJS
	duplicate /o pres_sl pres_sl_injair
	duplicate /o flow_packsl flow_packsl_injair
	duplicate /o flow_packsl flow_packsl_15air
	duplicate /o presbp_pan pres_pansl_injair
	duplicate /o flow_pansl flow_pansl_injair
	duplicate /o flow_pansl flow_pansl_15air
	
	pres_sl_injair = selectnumber((time_inj>0)&&(wv0==1),nan,pres_sl_injair)		// PACKED  Pres @ INJ
	flow_packsl_injair = selectnumber((time_inj>0)&&(wv0==1),nan,flow_packsl_injair)	// PACKED Flow @ INJ
	flow_packsl_15air = selectnumber((time_inj_15>0)&&(wv0==1),nan,flow_packsl_15air)	// PACKED Flow @ INJ-15
	pres_pansl_injair = selectnumber((time_pan_inj>0)&&(selpos_pan==1),nan,pres_pansl_injair)		// PAN  Pres @ INJ
	flow_pansl_injair = selectnumber((time_pan_inj>0)&&(selpos_pan==1),nan,flow_pansl_injair)	// PAN Flow @ INJ
	flow_pansl_15air = selectnumber((time_pan_inj_15>0)&&(selpos_pan==1),nan,flow_pansl_15air)	// PAN Flow @ INJ-15
	
	// CAL INJS
	duplicate /o pres_sl pres_sl_injcal
	duplicate /o flow_packsl flow_packsl_injcal
	duplicate /o flow_packsl flow_packsl_15cal
	duplicate /o presbp_pan pres_pansl_injcal
	duplicate /o flow_pansl flow_pansl_injcal
	duplicate /o flow_pansl flow_pansl_15cal
	
	pres_sl_injcal = selectnumber((time_inj>0)&&(wv0==2),nan,pres_sl_injcal)		// PACKED  Pres @ INJ
	flow_packsl_injcal = selectnumber((time_inj>0)&&(wv0==2),nan,flow_packsl_injcal)	// PACKED Flow @ INJ
	flow_packsl_15cal = selectnumber((time_inj_15>0)&&(wv0==2),nan,flow_packsl_15cal)	// PACKED Flow @ INJ-15
	pres_pansl_injcal = selectnumber((time_pan_inj>0)&&(selpos_pan==2),nan,pres_pansl_injcal)		// PAN  Pres @ INJ
	flow_pansl_injcal = selectnumber((time_pan_inj>0)&&(selpos_pan==2),nan,flow_pansl_injcal)	// PAN Flow @ INJ
	flow_pansl_15cal = selectnumber((time_pan_inj_15>0)&&(selpos_pan==2),nan,flow_pansl_15cal)	// PAN Flow @ INJ-15

endif
end


function SF6plots()

	EngPlot2(FlowM_SF6, FlowB_SF6)
	EngPlot2(voltM_SF6, voltB_SF6)
	EngPlot1(PresBP_SF6)
	EngPlot1(voltBP_SF6)
	EngPlot1(PresE_SF6)
	EngPlot1(voltE_SF6)
	EngPlot1(SF6_ECD); lowchop(SF6_ECD, -1)
	EngPlot2(SF6_Col, SF6_Post); lowchop(SF6_Col, -1); lowchop(SF6_Post, -1)
	EngPlot1(ecdA_SF6); lowchop(ecdA_SF6, 0)

end

function COplots()

	EngPlot2(FlowM_CO, FlowB_CO)
	EngPlot2(voltM_CO, voltB_CO)
	EngPlot1(PresBP_CO)
	EngPlot1(voltBP_CO)
	EngPlot1(PresE_F11)
	EngPlot1(voltE_CO)
	EngPlot1(CO_ECD); lowchop(CO_ECD, -1)
	EngPlot1(CO_Col); lowchop(CO_Col, -1)
	EngPlot1(ecdA_CO); lowchop(ecdA_CO, 0)

end

function F11plots()

	EngPlot2(FlowM_F11, FlowB_F11)
	EngPlot2(voltM_F11, voltB_F11)
	EngPlot1(PresBP_F11)
	EngPlot1(voltBP_F11)
	EngPlot1(PresE_5)
	EngPlot1(voltE_F11)
	EngPlot1(F11_ECD); lowchop(F11_ECD, -1)
	EngPlot1(F11_Col); lowchop(F11_Col, -1)
	EngPlot1(ecdA_F11); lowchop(ecdA_F11, 0)

end

function PANplots()

	EngPlot1(ColT_PAN)
	EngPlot2(Pres1_PAN, Pres2_PAN)
	EngPlot2(voltM_PAN, voltB_PAN)
	EngPlot1(PresE_PAN)
	EngPlot1(voltE_PAN)
	EngPlot1(PAN_ECD); lowchop(PAN_ECD, -1)
	EngPlot1(ecdA_PAN); lowchop(ecdA_PAN, 0)

end

function MSplots()
	EngPlot2(Trap2_CB, Trap1_CB)
	EngPlot2(ColT_MS1, ColT_MS2)
	EngPlot2rt(Trap1_CB, ColT_MS1); lowchop(ColT_MS1, -99.8); lowchop(Trap1_CB, -99.8)
	EngPlot2rt(ColT_MS2, Trap2_CB); lowchop(ColT_MS2, -99.8); lowchop(Trap2_CB, -99.8)
	EngPlot2rt(PresMS1, VoltMS1)
	EngPlot2rt(PresMS2, VoltMS2)
	EngPlot1(msdA_0); lowchop(msdA_0, -1)
	EngPlot1(msdA_1); lowchop(msdA_1, -1)
	EngPlot1(msdA_2); lowchop(msdA_2, -1)
	EngPlot1(msdA_3); lowchop(msdA_3, -1)
end

function SampPlots()

	EngPlot3(Pres_sl,Pres_SL_injcal,Pres_SL_injair); ModifyGraph mode=3,marker=19,msize=3,mode(Pres_sl)=0,rgb(Pres_sl)=(0,0,0)
	EngPlot3(Presbp_pan,Pres_panSL_injcal,Pres_panSL_injair); ModifyGraph mode=3,marker=19,msize=3,mode(Presbp_pan)=0,rgb(Presbp_pan)=(0,0,0)
	EngPlot4(flow_packsl,flow_packsl_injcal,flow_packsl_injair,flow_packsl_15cal,flow_packsl_15air);ModifyGraph mode=3,msize=3,marker(flow_packsl_15cal)=19,marker(flow_packsl_15air)=19,marker(flow_packsl_injcal)=17,marker(flow_packsl_injair)=17,mode(Flow_Packsl)=0,rgb(Flow_Packsl)=(0,0,0)
	EngPlot4(flow_pansl,flow_pansl_injcal,flow_pansl_injair,flow_pansl_15cal,flow_pansl_15air);ModifyGraph mode=3,msize=3,marker(flow_pansl_15cal)=19,marker(flow_pansl_15air)=19,marker(flow_pansl_injcal)=17,marker(flow_pansl_injair)=17,mode(Flow_Pansl)=0,rgb(Flow_Pansl)=(0,0,0)
	EngPlot1(Flow_MSsl)
	EngPlot1(Pres_Inlet)
	EngPlot1(Temp_SF6sl)
	EngPlot1(Temp_F11sl)
	EngPlot1(Temp_COsl)
	EngPlot1(Temp_PANsl)
	EngPlot2rt(PresSrc_PAN, FlowSrc_PAN)

end

function CylinderPlots()
	
	EngPlot2rt(PresH_N2, PresL_N2)
	EngPlot2rt(PresH_He, PresL_He)
	EngPlot2rt(PresH_Cal1, PresL_Cal1)
	EngPlot2rt(PresH_Cal2, PresL_Cal2)
	EngPlot2rt(PresH_CO2, PresL_CO2)
	EngPlot2rt(PresH_N2O, PresL_N2O)
	EngPlot2rt(PresH_ZA, PresL_ZA)

end

function PowerPlots()
	
	EngPlot2(Pow_p28pri, Pow_p28sec)
	EngPlot2(Pow_p24gsv, Pow_p24ms)
	EngPlot2(Pow_p15pel1, Pow_p15pel2)
	EngPlot2(Pow_p15, Pow_p12)
	EngPlot1(Pow_p5)
	EngPlot1(Pow_m15)
	
end

function TempPlots()

	EngPlot2(Temp_GSVbo, Temp_elect)
	EngPlot2(Temp_SF6sl,Temp_PANsl)
	EngPlot2(Temp_F11sl,Temp_COsl)		
	EngPlot2(SF6_Col, SF6_Post); lowchop(SF6_Col, -1); lowchop(SF6_Post, -1)
	EngPlot1(F11_Col); lowchop(F11_Col, -1)
	EngPlot1(CO_Col); lowchop(CO_Col, -1)		
	EngPlot1(ColT_PAN)
	EngPlot1(SF6_ECD); lowchop(SF6_ECD, -1)
	EngPlot1(F11_ECD); lowchop(F11_ECD, -1)
	EngPlot1(CO_ECD); lowchop(CO_ECD, -1)
	EngPlot1(PAN_ECD); lowchop(PAN_ECD, -1)
		
end