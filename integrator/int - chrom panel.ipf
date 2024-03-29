#pragma rtGlobals=1		// Use modern global access method.
#include <median>


Function MAN_CreateGlobalVars()

	wave CH1_All = root:AS:CH1_All
	wave /t DBmols = root:DB:DB_mols
	
	if (exists("root:V_autoscale") == 0 )
		variable /G root:V_autoscale = 0
	endif

	if (exists("root:V_chromNum") == 0 )
		Variable /g root:V_chromNum = CH1_All[0]
	endif
	
	if (exists("root:V_chromNumLast") == 0)
		variable /G root:V_chromNumLast = 0
	endif
	
	if (exists("S_currPeak") == 0 )
		String /G root:S_currPeak = DBmols[0]
	endif
	SVAR /Z currPeak = root:S_currPeak
	
	if (exists("V_currCh") == 0 )
		Variable /G root:V_currCh = ReturnChannel(DBmols[0])
	endif

	if (exists("V_ASselect") == 0 )
		Variable /G root:V_ASselect = 1
	endif
	
	if ( exists("root:" + currPeak + "_ret") != 1 )
		MakePeakResWaves( currPeak, 0 )
	endif
	
	UpdateASwaves(9)

end



Function MANpanel() : Graph

	DoWindow ChromPanel
	if (V_flag == 1)
		DoWindow /F ChromPanel
		abort
	endif		

	if ( numpnts(root:DB:DB_mols) == 0 )
		abort "Aborted.  You need to add a peak first."
	endif
	if ( exists("root:AS:CH1_All") == 0 )
		abort "Aborted.  You need to load some chromatograms and then run \"Prepare Chroms\""
	endif

	MAN_CreateGlobalVars()

	MakeAllPeakResWaves()
	
	NVAR currCh = root:V_currCh
	SVAR currPeak = root:S_currPeak
	SVAR molLst = $"root:DB:S_molLst" + num2str(currCh)
	string com
	
	Display /K=1/W=(34,86,815,562)
	DoWindow /C ChromPanel

	ModifyGraph margin(left)=108,gFont="Arial",gfSize=16,wbRGB=(65535,54607,32768),cbRGB=(65535,60076,49151)
	ModifyGraph frameStyle=2,frameInset=3
	ModifyGraph mirror=2

	ControlBar 110
	PopupMenu currDetNum,pos={9,6},size={108,20},proc=MANpopMenuProc,title="channel"
	PopupMenu currDetNum,help={"Choose channel number to view."},font="Arial"
	PopupMenu currDetNum,fSize=12
	PopupMenu currDetNum,mode=3,bodyWidth= 61,popvalue="3",value= #"listnlong(root:V_chans,\";\")"
	PopupMenu currPkNm,pos={7,30},size={110,20},proc=MANpopMenuProc,title="peak"
	PopupMenu currPkNm,help={"Choose peak to integrate."},font="Arial",fSize=12
	PopupMenu currPkNm,mode=1,bodyWidth= 80,popvalue="N2O",value= #"root:DB:S_molLst1"
	CheckBox autoScale,pos={132,79},size={75,14},proc=MANcheckProc,title="auto scale"
	CheckBox autoScale,help={"Autoscale the plot."},font="Arial",fSize=12
	CheckBox autoScale,variable= V_autoscale
	Button setExp,pos={128,57},size={80,18},proc=MANbuttonProc,title="set expect"
	Button setExp,help={"Use current cursor positions to set the \"expected\" peak start and stop positions."}
	Button setExp,font="Arial",fColor=(65535,65533,32768)
	Button prevBut,pos={17,73},size={44,16},proc=MANbuttonProc,title="prev"
	Button prevBut,help={"Previous chromatogram in active set."},font="Arial"
	Button prevBut,fColor=(65535,32768,32768)
	Button nextBut,pos={66,73},size={45,16},proc=MANbuttonProc,title="next"
	Button nextBut,help={"Next chromatogram in active set."},font="Arial"
	Button nextBut,fColor=(65535,32768,32768)
	SetVariable chromNum,pos={17,92},size={95,15},proc=MANsetVarProc,title="chrom #"
	SetVariable chromNum,help={"Current chromatogram in active set being displayed."}
	SetVariable chromNum,font="Arial",fSize=11,format="%d"
	SetVariable chromNum,limits={1,83,1},value= V_chromNum,live= 1
	Button toggCursors,pos={128,17},size={80,18},proc=MANbuttonProc,title="tog cursors"
	Button toggCursors,help={"Toggle cursors on or off."},font="Arial"
	Button toggCursors,fColor=(65535,65533,32768)
	Button expBut,pos={128,37},size={80,18},proc=MANbuttonProc,title="expect"
	Button expBut,help={"Place cursors at peak start and stop \"expected\" values."}
	Button expBut,font="Arial",fColor=(65535,65533,32768)
	Button integrateBut,pos={495,68},size={75,33},proc=MANbuttonProc,title="integrate"
	Button integrateBut,help={"Integrate peak with current cursor start and stop positions."}
	Button integrateBut,font="Arial",fColor=(32769,65535,32768)
	Button integrateBut2,pos={584,68},size={75,33},proc=MANbuttonProc,title="integrate\rand flag"
	Button integrateBut2,help={"Integrate peak with current cursor start and stop positions."}
	Button integrateBut2,font="Arial",fColor=(65535,16385,16385)
	CheckBox manFlag,pos={580,7},size={83,14},proc=MANcheckProc,title="manual flag"
	CheckBox manFlag,help={"When checked, the peak is flagged as to always manually integrate."}
	CheckBox manFlag,font="Arial",fSize=12,value= 0
	CheckBox badFlag,pos={580,23},size={92,14},proc=MANcheckProc,title="bad peak flag"
	CheckBox badFlag,help={"When checked, the peak is flagged as \"bad\" and will not be integrated."}
	CheckBox badFlag,font="Arial",fSize=12,value= 0
	Button viewAll,pos={679,5},size={90,18},proc=MANbuttonProc,title="AS all"
	Button viewAll,help={"Sets active chromatograms to \"all\"."},font="Arial"
	Button viewAll,fColor=(49151,65535,65535)
	Button viewManual,pos={679,25},size={90,18},proc=MANbuttonProc,title="AS manual"
	Button viewManual,help={"Set active chromatograms to \"manual\" flag."}
	Button viewManual,font="Arial",fColor=(49151,65535,65535)
	Button viewBad,pos={679,45},size={90,18},proc=MANbuttonProc,title="AS bad"
	Button viewBad,help={"Sets active chromatograms to \"bad\" flag."},font="Arial"
	Button viewBad,fColor=(49151,65535,65535)
	ValDisplay peakStart,pos={314,4},size={68,16},title="start"
	ValDisplay peakStart,help={"Peak start value for choosen peak."},font="Arial"
	ValDisplay peakStart,fSize=12,format="%3.1f",frame=2,fStyle=0
	ValDisplay peakStart,limits={0,0,0},barmisc={0,1000},bodyWidth= 40
//	ValDisplay peakStart,value= #"returnResult(\"start\")"
	ValDisplay peakRet,pos={324,23},size={58,16},title="ret"
	ValDisplay peakRet,help={"Peak retention value for choosen peak."},font="Arial"
	ValDisplay peakRet,fSize=12,format="%3.1f",frame=2
	ValDisplay peakRet,limits={0,0,0},barmisc={0,1000},bodyWidth= 40
//	ValDisplay peakRet,value= #"returnResult(\"ret\")"
	ValDisplay peakStop,pos={314,42},size={68,16},title="stop"
	ValDisplay peakStop,help={"Peak stop value for choosen peak."},font="Arial"
	ValDisplay peakStop,fSize=12,format="%3.1f",frame=2
	ValDisplay peakStop,limits={0,0,0},barmisc={0,1000},bodyWidth= 40
//	ValDisplay peakStop,value= #"returnResult(\"stop\")"
	ValDisplay peakArea,pos={395,5},size={89,16},title="area"
	ValDisplay peakArea,help={"Integrated area of peak."},font="Arial",fSize=12
	ValDisplay peakArea,format="%6.1f",frame=2,limits={0,0,0},barmisc={0,1000}
//	ValDisplay peakArea,value= #"returnResult(\"area\")"
	ValDisplay peakHght,pos={386,24},size={98,16},title="height"
	ValDisplay peakHght,help={"Integrated height of peak."},font="Arial",fSize=12
	ValDisplay peakHght,format="%6.1f",frame=2,limits={0,0,0},barmisc={0,1000}
//	ValDisplay peakHght,value= #"returnResult(\"height\")"
	Button flagAll,pos={582,45},size={80,18},proc=MANbuttonProc,title="flag all bad"
	Button flagAll,help={"Sets active chromatograms to \"all\"."},font="Arial"
	Button flagAll,fColor=(65535,49151,49151)
	Button viewAStable,pos={680,86},size={90,20},proc=MANbuttonProc,title="view AS table"
	Button viewAStable,help={"Set active chromatograms to \"manual\" flag."}
	Button viewAStable,font="Arial",fColor=(32768,54615,65535)
	Button firstBut,pos={17,55},size={44,16},proc=MANbuttonProc,title="first"
	Button firstBut,help={"Previous chromatogram in active set."},font="Arial"
	Button firstBut,fColor=(65535,49157,16385)
	Button lastBut,pos={66,55},size={44,16},proc=MANbuttonProc,title="last"
	Button lastBut,help={"Previous chromatogram in active set."},font="Arial"
	Button lastBut,fColor=(65535,49157,16385)
	Button aR1,pos={238,18},size={20,15},proc=MANcursorButtonProc,title="R1"
	Button aR1,help={"Move start cursor one point to the right."},font="Arial"
	Button aR1,fSize=10,fColor=(65535,65534,49151)
	Button aL1,pos={218,18},size={20,15},proc=MANcursorButtonProc,title="L1"
	Button aL1,help={"Move start cursor one point to the left."},font="Arial"
	Button aL1,fSize=10,fColor=(65535,65534,49151)
	Button aR2,pos={238,33},size={20,15},proc=MANcursorButtonProc,title="R2"
	Button aR2,help={"Move start cursor two points to the right."},font="Arial"
	Button aR2,fSize=10,fColor=(65535,65534,49151)
	Button aL2,pos={218,33},size={20,15},proc=MANcursorButtonProc,title="L2"
	Button aL2,help={"Move start cursor two points to the left"},font="Arial"
	Button aL2,fSize=10,fColor=(65535,65534,49151)
	Button aL4,pos={218,48},size={20,15},proc=MANcursorButtonProc,title="L4"
	Button aL4,help={"Move start cursor four points to the left."},font="Arial"
	Button aL4,fSize=10,fColor=(65535,65534,49151)
	Button aR4,pos={238,48},size={20,15},proc=MANcursorButtonProc,title="R4"
	Button aR4,help={"Move start cursor four points to the right."},font="Arial"
	Button aR4,fSize=10,fColor=(65535,65534,49151)
	Button aL8,pos={218,63},size={20,15},proc=MANcursorButtonProc,title="L8"
	Button aL8,help={"Move start cursor eight points to the left."},font="Arial"
	Button aL8,fSize=10,fColor=(65535,65534,49151)
	Button aR8,pos={238,63},size={20,15},proc=MANcursorButtonProc,title="R8"
	Button aR8,help={"Move start cursor eight points to the right."},font="Arial"
	Button aR8,fSize=10,fColor=(65535,65534,49151)
	Button aL16,pos={218,78},size={20,15},proc=MANcursorButtonProc,title="L16"
	Button aL16,help={"Move start cursor sixteen points to the left."},font="Arial"
	Button aL16,fSize=10,fColor=(65535,65534,49151)
	Button aR16,pos={238,78},size={20,15},proc=MANcursorButtonProc,title="R16"
	Button aR16,help={"Move start cursor sixteen points to the right."},font="Arial"
	Button aR16,fSize=10,fColor=(65535,65534,49151)
	Button bR1,pos={285,18},size={20,15},proc=MANcursorButtonProc,title="R1"
	Button bR1,help={"Move stop cursor one point to the right."},font="Arial"
	Button bR1,fSize=10,fColor=(65535,65534,49151)
	Button bL1,pos={265,18},size={20,15},proc=MANcursorButtonProc,title="L1"
	Button bL1,help={"Move stop cursor one point to the left."},font="Arial"
	Button bL1,fSize=10,fColor=(65535,65534,49151)
	Button bR2,pos={285,33},size={20,15},proc=MANcursorButtonProc,title="R2"
	Button bR2,help={"Move stop cursor two points to the right."},font="Arial"
	Button bR2,fSize=10,fColor=(65535,65534,49151)
	Button bL2,pos={265,33},size={20,15},proc=MANcursorButtonProc,title="L2"
	Button bL2,help={"Move stop cursor two points to the left"},font="Arial"
	Button bL2,fSize=10,fColor=(65535,65534,49151)
	Button bL4,pos={265,48},size={20,15},proc=MANcursorButtonProc,title="L4"
	Button bL4,help={"Move stop cursor four points to the left."},font="Arial"
	Button bL4,fSize=10,fColor=(65535,65534,49151)
	Button bR4,pos={285,48},size={20,15},proc=MANcursorButtonProc,title="R4"
	Button bR4,help={"Move stop cursor four points to the right."},font="Arial"
	Button bR4,fSize=10,fColor=(65535,65534,49151)
	Button bL8,pos={265,63},size={20,15},proc=MANcursorButtonProc,title="L8"
	Button bL8,help={"Move stop cursor eight points to the left."},font="Arial"
	Button bL8,fSize=10,fColor=(65535,65534,49151)
	Button bR8,pos={285,63},size={20,15},proc=MANcursorButtonProc,title="R8"
	Button bR8,help={"Move stop cursor eight points to the right."},font="Arial"
	Button bR8,fSize=10,fColor=(65535,65534,49151)
	Button bL16,pos={265,78},size={20,15},proc=MANcursorButtonProc,title="L16"
	Button bL16,help={"Move stop cursor sixteen points to the left."},font="Arial"
	Button bL16,fSize=10,fColor=(65535,65534,49151)
	Button bR16,pos={285,78},size={20,15},proc=MANcursorButtonProc,title="R16"
	Button bR16,help={"Move stop cursor sixteen points to the right."},font="Arial"
	Button bR16,fSize=10,fColor=(65535,65534,49151)
	ValDisplay peakSLtemp,pos={412,82},size={72,16},title="temp"
	ValDisplay peakSLtemp,help={"Sample loop temperature."},font="Arial",fSize=12
	ValDisplay peakSLtemp,format="%3.1f",frame=2
	ValDisplay peakSLtemp,limits={0,0,0},barmisc={0,1000},bodyWidth= 40
//	ValDisplay peakSLtemp,value= #"returnResult(\"temp\")"
	ValDisplay peakSLpress,pos={398,63},size={86,16},title="press"
	ValDisplay peakSLpress,help={"Sample loop pressure (mbar)."},font="Arial"
	ValDisplay peakSLpress,fSize=12,format="%3.1f",frame=2
	ValDisplay peakSLpress,limits={0,0,0},barmisc={0,1000},bodyWidth= 50
//	ValDisplay peakSLpress,value= #"returnResult(\"press\")"
	ValDisplay peakResp,pos={395,43},size={89,16},title="resp"
	ValDisplay peakResp,help={"Peak response (calculated from height or area and sample loop temp and press)."}
	ValDisplay peakResp,font="Arial",fSize=12,format="%6.1f",frame=2,fStyle=0
	ValDisplay peakResp,limits={0,0,0},barmisc={0,1000}
//	ValDisplay peakResp,value= #"returnResult(\"resp\")"
	ValDisplay selpos,pos={315,61},size={67,16},title=" ssv"
	ValDisplay selpos,help={"Peak stream select valve position (selpos wave)."}
	ValDisplay selpos,labelBack=(49151,53155,65535),font="Arial",fSize=12
	ValDisplay selpos,format="%3d",frame=2,fStyle=1
	ValDisplay selpos,limits={0,0,0},barmisc={0,1000},bodyWidth= 40
//	ValDisplay selpos,value= #"returnResult(\"selpos\")"
	Button viewDataTable,pos={495,5},size={75,34},proc=MANbuttonProc,title="ion60\rdata table"
	Button viewDataTable,help={"Set active chromatograms to \"manual\" flag."}
	Button viewDataTable,font="Arial",fColor=(49151,49152,65535)
	Button nullbutton,pos={321,81},size={69,21},proc=MANbuttonProc,title="NaN peak"
	Button nullbutton,help={"Set current peak result values to NaN"},font="Arial"
	Button nullbutton,fColor=(65535,49151,49151)
	Button viewDataPlolts,pos={495,43},size={75,20},proc=MANbuttonProc,title="result plots"
	Button viewDataPlolts,help={"Set active chromatograms to \"manual\" flag."}
	Button viewDataPlolts,font="Arial",fColor=(49151,49152,65535)
	Button viewSelpos,pos={679,65},size={90,18},proc=MANbuttonProc,title="AS by selpos"
	Button viewSelpos,help={"Sets active chromatograms to choosen selpos (ssv position)."}
	Button viewSelpos,font="Arial",fColor=(49151,65535,65535)
	
	PopupMenu currDetNum mode=currCh
	sprintf com, "PopupMenu currPkNm,mode=1,popvalue=\"%s\",value= #\"root:DB:S_molLst%d\"", currPeak, currCh
	execute com
	SVAR S_currMol = root:DB:S_currMol
	S_currMol = currPeak
		
	SetVariable chromNum,limits={returnMINchromNum(1),returnMAXchromNum(1),1},value=V_chromNum,noedit= 0
	SetWindow ChromPanel, hookevents=0, hook=MANrefresh
	
End


Function MANrefresh( infoStr )
	String infoStr

	String event= StringByKey("EVENT",infoStr)

	if ( cmpstr(event, "activate") == 0)
		DrawChrom( )
	endif
	
End

Function MANpopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	variable ch
	string molLst, com

	NVAR currCh = root:V_currCh
	NVAR chromNum = root:V_chromNum
	NVAR currMolRow = root:DB:V_currMolRow
	SVAR currPeak = root:S_currPeak
	
	string tablename = "ASview"
	
	strswitch(ctrlName)

		case "currDetNum":
			ch = popNum
			molLst = ReturnList("root:DB:S_molLst" + num2str(ch))
			if ( ch != currCh )
				currPeak = StringFromList(0,molLst,";")
				currCh = ch
			endif
			sprintf com, "PopupMenu currPkNm,mode=1,popvalue=\"%s\",value= #\"root:DB:S_molLst%d\"", currPeak, ch
			execute com

			SVAR S_currMol = root:DB:S_currMol
			S_currMol = currPeak
			SetDBvars(S_currMol)
		
			currMolRow = returnMolDBrow(currPeak)
			UpdateASwaves(9)
			chromNum = NextChromInAS(currCh, chromNum, 0 )
			DrawChrom()
			DoWindow $tablename
			if ( V_flag )
				ASviewTable()
			endif
			break
			
		case "currPkNm":
			currPeak = popStr
			currMolRow = returnMolDBrow(currPeak)
			SetDBvars(currPeak)
			UpdateASwaves(9)
			chromNum = NextChromInAS(currCh, chromNum, 0 )
			DrawChrom()
			break
		
	endswitch

End

Function MANsetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	setDataFolder root:
	
	strswitch(ctrlName)
		case "chromNum":
			DisplayNextChrom( varNum )
			break
	
	endswitch

End

// function called by the chrom # incrementor
Function DisplayNextChrom( chromNumber )
	variable chromNumber

	NVAR currCh = root:V_currCh
	NVAR chromNum = root:V_chromNum
	NVAR chromNumLast = root:V_chromNumLast
	
	variable next
		
	string chrom
	variable maxCh = returnMAXchromNum(currCh)
	variable minCh = returnMINchromNum(currCh)

	// handle the rails
	if ((chromNumber <= minCh) || (chromNumber >= maxCh))
		next = chromNumber
	else
		// step up or down
		if (chromNumLast >	 chromNumber)
			next = NextChromInAS(currCh, chromNum+1, -1 )
		else
			next = NextChromInAS(currCh, chromNum-1, 1 )
		endif
	endif

	chromNumLast = next
	chromNum = next

	DrawChrom()
	
end

// Remove all traces from graph and redraws the current chrom.
Function DrawChrom()

	NVAR autoscale = root:V_autoscale
	NVAR currCh = root:V_currCh
	NVAR currMolRow = root:DB:V_currMolRow
	NVAR chromNum = root:V_ChromNum
	NVAR ASsel = root:V_ASselect
	SVAR currPeak = root:S_currPeak
	
	SelectSelpos()
	
	wave selpos = root:selpos
	wave /t DBmols = root:DB:DB_mols
	wave DBexpStart = root:DB:DB_expStart
	wave DBexpStop = root:DB:DB_expStop
	wave AS = root:AS:CH1_AS
	
	if ( cmpstr(currPeak, "") == 0 )
		currPeak = DBmols[0]
		currCh = ReturnChannel(currPeak)
	endif
	
	wave manFlagWv = $("root:" + currPeak + "_flagMan")
	wave badFlagWv = $("root:" + currPeak + "_flagBad")
	wave PkstartWv = $("root:" + currPeak + "_Start")
	wave PkstopWv = $("root:" + currPeak + "_Stop")
	
	string com, title
	string path = "root:chroms:"
	string chrom = path + ChromName(currCh, chromNum)
	string chromShortName = ChromName(currCh, chromNum)
	variable ResRow = ReturnResRowNumber( currCh, chromNum )
	
	switch ( ASsel )
		case 1:
			title = chromShortName + "   AS: All"
			break
		case 2:
			title = chromShortName + "   AS: Manual"
			break
		case 3:
			title = chromShortName + "   AS: Bad"
			break
		case 4:
			title = chromShortName + "   AS: Selpos = " + num2str(selpos[ReturnResRowNumber( 1, AS[0] )])
			break
		case 5:
			title = chromShortName + "   AS: Multi-Selpos"
			break
	endswitch
	
	if ( chromNum == -1 )
		chrom = "blank"
	endif

	variable start, stop, cursorOn, DBrow
	variable axisLmin, axisLmax, axisBmin, axisBmax

	// are the cursors on?
	if (( strlen(CsrWave(A)) > 0 ) || ( strlen(CsrWave(B)) > 0 ))
		cursorOn = 1
	endif

	if ( ! autoscale)
		// save axis postion
		GetAxis /Q left
		axisLmin = V_min
		axisLmax = V_max
		GetAxis /Q bottom
		axisBmin = V_min
		axisBmax = V_max
	endif

	// Remove traces from chrom window
	// only removes waves named "bline", "rettick", or starts with "chr"
	string traceList = TraceNameList("", ";", 1), trace
	variable i
	for( i = 0; i<ItemsInList(traceList); i += 1)
		trace = StringFromList(i, traceList)
		if ((strsearch(trace, "bline", 0) != -1) || (strsearch(trace, "rettick", 0) != -1) || (cmpstr(trace[0,2], "chr") == 0) || (strsearch(trace, "vert", 0) != -1) )
			RemoveFromGraph/Z/W=ChromPanel $trace
		endif
	endfor
			
	if ( cmpstr(chrom, "blank") != 0)
		if ( exists(chrom) != 1)
			return 0
		endif
		AppendToGraph $chrom
		wave chrwv = $chrom

		DrawPeakBaselines( )

		if ( autoscale )
			start = ReturnPeakStartPtnoNAN(currPeak, chromNum, 1)
			stop = ReturnPeakStopPtnoNAN(currPeak, chromNum, 1)
			if (numtype(PkstartWv[ResRow]) == 0 )
				wavestats /Q/R=(PkstartWv[ResRow], PkstopWv[ResRow]) chrwv
			else
				wavestats /Q /R=(start, stop) $chrom
			endif
			axisLmin = V_min-(V_max-V_min)*0.4
			axisLmax = V_max+(V_max-V_min)*0.4
			axisBmin = Max(0,start-(stop-start)*0.8)
			axisBmax = Min(pnt2x(chrwv, numpnts(chrwv)-1), stop+(stop-start)*0.8)
		
			SetAxis left axisLmin, axisLmax
			SetAxis bottom axisBmin, axisBmax 
		else

			if (numtype(axisLmin) == 2 )
				SetAxis /A
			else
				SetAxis left axisLmin, axisLmax
				SetAxis bottom axisBmin, axisBmax
			endif
			
		endif

		DoWindow/T ChromPanel, title
		Label left "Response (Hz)"
		Label bottom "Time (s)"	
		ModifyGraph mirror=2
		ModifyGraph margin(left)=108

		DrawPeakRetTick( )
		
		if ( cursorOn )
			DBrow = returnMolDBrow(currPeak)
//			Cursor /a=0 A, $chromShortName, ReturnPeakStartPt(currPeak, chromNum)
//			Cursor /a=0 B, $chromShortName, ReturnPeakStopPt(currPeak, chromNum)
			Cursor /a=0 A, $chromShortName, PkstartWv[ResRow]
			Cursor /a=0 B, $chromShortName, PkstopWv[ResRow]
		endif
		
		// flag check boxes
		CheckBox manFlag,value=(manFlagWv[ResRow])
		CheckBox badFlag,value=(badFlagWv[ResRow])
		
		// result waves update
		ValDisplay peakStart,value= returnResult("start")
		ValDisplay peakStop,value= returnResult("stop")
		ValDisplay peakRet,value= returnResult("ret")
		ValDisplay peakArea,value= returnResult("area")
		ValDisplay peakHght,value= returnResult("height")
		ValDisplay peakResp,value= returnResult("resp")
		ValDisplay peakSLpress,value= returnResult("press")
		ValDisplay peakSLtemp,value= returnResult("temp")
		ValDisplay selpos,value= returnResult("selpos")

		PopupMenu currDetNum mode=currCh
		sprintf com, "PopupMenu currPkNm,mode=1,popvalue=\"%s\",value= #\"root:DB:S_molLst%d\"", currPeak, currCh
		execute com
		SVAR S_currMol = root:DB:S_currMol
		S_currMol = currPeak

		sprintf com, "Button viewDataTable,title=\"%s\\rdata table\"", currPeak
		execute com
	else
		DoWindow/T ScanChroms,"blank"
	endif
	
end


Function MANbuttonProc(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR chromNum = root:V_chromNum
	NVAR currCh = root:V_currCh
	NVAR currMolRow = root:DB:V_currMolRow
	NVAR ASselect = root:V_ASselect
	SVAR currMol = root:S_currPeak

	wave /t DBmols = root:DB:DB_mols
	wave DBexpStart = root:DB:DB_expStart
	wave DBexpStop = root:DB:DB_expStop
	wave pkStart = $"root:" + currMol + "_start"
	wave pkStop = $"root:" + currMol + "_stop"
	wave AS = $("root:AS:CH" + num2str(currCh) + "_AS")
	
	if (exists("V_IntButton") != 2 )
		variable /G root:V_IntButton = 0
	endif
	NVAR IntButton = root:V_IntButton
	
	string chrom =  ChromName(currCh, chromNum)	// chrom displayed
	variable next, resRowNum, inc, row
	
	strswitch ( ctrlName )
		case "FirstBut":
			chromNum = RetFirstUnflaggedChrom( currMol )
			if ( numtype(chromNum) != 0 )
				chromNum = -1
				beep
			endif
			DrawChrom()
			break
		
		case "LastBut":
			chromNum = RetLastUnflaggedChrom( currMol )
			if ( numtype(chromNum) != 0 )
				chromNum = -1
				beep
			endif
			DrawChrom()
			break
			
		case "prevBut":
			next = NextChromInAS(currCh, chromNum, -1 )
			if ( next == chromNum )
				beep
			else
				chromNum = next
				DrawChrom()
			endif
			break
			
		case "nextBut":
			next = NextChromInAS(currCh, chromNum, +1 )
			if ( next == chromNum )
				beep
			else
				chromNum = next
				DrawChrom()
			endif
			break
			
		case "toggCursors":
			if ( strlen(CsrWave(A)) > 0 )
				Cursor /K A
				Cursor /K B
			else
				resRowNum = ReturnResRowNumber( currCh, chromNum )
				if ( numtype(pkStart[resRowNum]) == 0 )
					Cursor /a=0 A, $chrom, pkStart[resRowNum]
				else					
					Cursor /a=0 A, $chrom, DBexpStart[currMolRow]
				endif
				if ( numtype(pkStop[resRowNum]) == 0 )
					Cursor /a=0 B, $chrom, pkStop[resRowNum] 
				else
					Cursor /a=0 B, $chrom, DBexpStop[currMolRow]
				endif
			endif
			break
	
		case "expBut":
			Cursor /a=0 A, $chrom, DBexpStart[currMolRow]
			Cursor /a=0 B, $chrom, DBexpStop[currMolRow]
			break
			
		case "setExp":
			wave ret = $("root:" + currMol + "_ret")
			if ( strlen(CsrWave(A)) > 0 )
				DBexpStart[currMolRow] = Min(Xcsr(A), Xcsr(B))
				DBexpStop[currMolRow] = Max(Xcsr(A), Xcsr(B))
			endif
			resRowNum = ReturnResRowNumber( currCh, chromNum )
			ret[resRowNum] = FindRetOnePeak(currMol, chromNum)
			DrawChrom()
			Cursor /a=0 A, $chrom, DBexpStart[currMolRow]
			Cursor /a=0 B, $chrom, DBexpStop[currMolRow]
			break
			
		case "viewAll":
			SetASchroms(1)
			DrawChrom()
			break
			
		case "viewManual":
			SetASchroms(2)
			DrawChrom()
			break
			
		case "viewBad":
			SetASchroms(3)
			DrawChrom()
			break
			
		case "viewSelpos":
			SetASusingSelpos()
			DrawChrom()
			break
		
		case "viewAStable":
			ASviewTable()
			break
			
		case "integrateBut":
			IntButton = 1
			wave ret = $("root:" + currMol + "_ret")
			wave pkStart = $("root:" + currMol + "_Start")
			wave pkStop = $("root:" + currMol + "_Stop")
			resRowNum = ReturnResRowNumber( currCh, chromNum )
			// Use cursors to define baseline
			if (( strlen(CsrWave(A)) > 0 ) && ( strlen(CsrWave(B)) > 0 ))
				pkStart[resRowNum] = Min(Xcsr(A), Xcsr(B))
				pkStop[resRowNum] = Max(Xcsr(A), Xcsr(B))
			endif
			FindRetOnePeak(currMol, chromNum)
			IntegrateOnePeak(currMol, chromNum)
			ResponseOnePeak(currMol, chromNum)
			DrawChrom()
			IntButton = 0
			break
		
		case "integrateBut2":
			IntButton = 1
			wave ret = $("root:" + currMol + "_ret")
			wave pkStart = $("root:" + currMol + "_Start")
			wave pkStop = $("root:" + currMol + "_Stop")
			wave man =$("root:" + currMol + "_flagMan")
			resRowNum = ReturnResRowNumber( currCh, chromNum )
			man[resRowNum] = 1
			UpdateASwaves(1)
			// Use cursors to define baseline
			if (( strlen(CsrWave(A)) > 0 ) && ( strlen(CsrWave(B)) > 0 ))
				pkStart[resRowNum] = Min(Xcsr(A), Xcsr(B))
				pkStop[resRowNum] = Max(Xcsr(A), Xcsr(B))
			endif
			FindRetOnePeak(currMol, chromNum)
			IntegrateOnePeak(currMol, chromNum)
			ResponseOnePeak(currMol, chromNum)
			DrawChrom()
			IntButton = 0
			break
			
		case "nullbutton":
			wave ret = $("root:" + currMol + "_ret")
			wave pkStart = $("root:" + currMol + "_Start")
			wave pkStop = $("root:" + currMol + "_Stop")
			wave are = $("root:" + currMol + "_area")
			wave hgt = $("root:" + currMol + "_height")
			wave resp = $("root:" + currMol + "_resp")
			resRowNum = ReturnResRowNumber( currCh, chromNum )
			ret[resRowNum] = NaN
			pkStart[resRowNum] = NaN
			pkStop[resRowNum] = NaN
			are[resRowNum] = NaN
			hgt[resRowNum] = NaN
			resp[resRowNum] = NaN
			DrawChrom()
			break
			
		case "flagAll":
			for(inc=0; inc<numpnts(DBmols); inc+=1)
				wave flag = $("root:" + DBmols[inc] + "_flagBad")
				row = ReturnResRowNumber( currCh, chromNum )
				flag[row] = 1
			endfor
			CheckBox badFlag,value= 1
			UpdateASwaves(2)

			break
			
		case "viewDataTable":
			RespTable( currMol )
			break

		case "viewDataPlolts":
			ResEdgePlot( currMol )
			ResRespPlot( currMol )
			break
			
	endswitch

End

Function MANcursorButtonProc(ctrlName) : ButtonControl
	String ctrlName

	NVAR chromNum = root:V_chromNum
	NVAR currCh = root:V_currCh
	NVAR currMolRow = root:DB:V_currMolRow
	SVAR mol = root:S_currPeak

	wave DBexpStart = root:DB:DB_expStart
	wave DBexpStop = root:DB:DB_expStop
	wave PKstart = $("root:" + mol + "_start")
	wave PKstop = $("root:" + mol + "_stop")

	variable ResRow = ReturnResRowNumber( currCh, chromNum )
	string path = "root:chroms:"
	string trace = ChromName(currCh, chromNum)
	string chrom = path + trace 	// chrom displayed

	variable csrApt, csrBpt
	variable left = 1, step
	
	if ( strlen(CsrWave(A)) > 0 )
		csrApt = x2pnt($chrom, Xcsr(A))
	else
		if ( numtype(PKstart[ResRow]) == 0 )
			csrApt = x2pnt($chrom, PKstart[ResRow])
		else		
			csrApt = x2pnt($chrom, DBexpStart[currMolRow])
		endif
	endif
	
	if ( strlen(CsrWave(B)) > 0 )
		csrBpt = x2pnt($chrom, Xcsr(B))
	else
		if ( numtype(PKstop[ResRow]) == 0 )
			csrBpt = x2pnt($chrom, PKstop[ResRow])
		else
			csrBpt = x2pnt($chrom, DBexpStop[currMolRow])
		endif
	endif
	string csr = ctrlName[0]
	if ( cmpstr(ctrlName[1], "L") == 0)
		left = -1
	endif
	step = str2num(ctrlName[2,3])

	if ( cmpstr(ctrlName[0], "a") == 0 )
		Cursor A, $trace, pnt2x($chrom, csrApt + step*left)
		Cursor B, $trace, pnt2x($chrom, csrBpt)
	else 
		Cursor A, $trace, pnt2x($chrom, csrApt)
		Cursor B, $trace, pnt2x($chrom, csrBpt + step*left)
	endif

End


// Draws a baseline between the expected start and stop values of
// the current selected peak.
Function DrawPeakBaselines( )

	NVAR chromNum = root:V_chromNum
	NVAR currCh = root:V_currCh
	NVAR currMolRow = root:DB:V_currMolRow
	SVAR currMol = root:S_currPeak
	SVAR molLst = $"root:DB:S_molLst" + num2str(currCh)

	wave DBmeth = root:DB:DB_meth
	wave DBedgePoints = root:DB:DB_edgePoints
	wave DBexpStart = root:DB:DB_expStart
	wave DBexpStop = root:DB:DB_expStop
	wave /t DBpeakStart = root:DB:DB_peakStart
	wave /t DBpeakStop = root:DB:DB_peakStop
	
	string bline, blineX, com, mol, vert, vertX
	string peakPt, peakPtMol, peakPtLoc
	variable inc, ch, start, stop, manFlag, badFlag, lpt, rpt
	variable avgStartX, medStartY, avgStopX, medStopY
	variable edgeAvg, ResRow, meth
	
	SetDataFolder root:chroms

	string dispchrom = ChromName(currCh, chromNum)
	wave chrom = $dispchrom

	do
		mol = StringFromList( inc, molLst, ";" )
		meth = DBmeth[returnMolDBrow(mol)]
		bline = "bline_" + mol
		blineX = "blineX_" + mol
		vert = "vert_" + mol
		vertX = "vertX_" + mol
		
		wave pkStart = $("root:" + mol + "_Start")
		wave pkStop = $("root:" + mol + "_Stop")
		start = ReturnPeakStartPt(mol, chromNum)
		stop = ReturnPeakStopPt(mol, chromNum)
		ch = ReturnChannel(mol)
		ResRow = ReturnResRowNumber( ch, chromNum )
		
		if ( ! WaveExists($("root:" + mol + "_ret")) )
			MakePeakResWaves( mol, 0 )
		endif
		
		wave manFlagWv = $("root:" + mol + "_flagMan")
		manFlag = manFlagWv[ResRow]
		wave badFlagWv = $("root:" + mol + "_flagBad")
		badFlag = badFlagWv[ResRow]
		
		if (( numtype(start) == 0 ) && ( numtype(stop) == 0 ))
				
			// median of the starting points
			edgeAvg = DBedgePoints[returnMolDBrow(mol)]
			edgeAvg = edgeAvg * 2 - 2
			lpt = x2pnt(chrom, start)-edgeAvg/2
			rpt = x2pnt(chrom, start)+edgeAvg/2
			medStartY = Median(chrom, pnt2x(chrom, lpt), pnt2x(chrom, rpt))

			lpt = x2pnt(chrom, stop)-edgeAvg/2
			rpt = x2pnt(chrom, stop)+edgeAvg/2
			medStopY = Median(chrom, pnt2x(chrom, lpt), pnt2x(chrom, rpt))
			
			avgStartX = (pnt2x(chrom, x2pnt(chrom, start)+edgeAvg/2) + pnt2x(chrom, x2pnt(chrom, start)-edgeAvg/2)) / 2 
			avgStopX = (pnt2x(chrom, x2pnt(chrom, Stop)+edgeAvg/2) + pnt2x(chrom, x2pnt(chrom, Stop)-edgeAvg/2)) / 2

			SetDataFolder root:temp

			// make baseline waves
			if (meth != 4)
				make /o/n=2 $bline = {medStartY, medStopY}, $blineX = {avgStartX, avgStopX}
			else		// gauss fit
				string Gbline = "gbline_" + mol
				wave GaussRes = $("root:" + mol + "_gaussRes")
				wave coef = $("root:IntCoef_" + mol)
				wave retwv = $("root:" + mol + "_ret")
				variable ret = retwv[ResRow]
				duplicate /o chrom, $bline, $Gbline
				wave blineW = $bline
				wave GblineW = $Gbline
				make /o/n=9 fitcoef = GaussRes[ResRow][p]
				GblineW = GaussPeakFit(fitcoef, x)
				fitcoef[2] = 0
				blineW = GaussPeakFit(fitcoef, x)
				GblineW = SelectNumber( (pnt2x(GblineW, p) < ret-coef[9]) || (pnt2x(GblineW, p) > ret+coef[10]), GblineW, NaN)
				blineW = SelectNumber( (pnt2x(blineW, p) < ret-coef[9]) || (pnt2x(blineW, p) > ret+coef[10]), blineW, NaN)
			endif

			// determine if vertical drop line is needed then make it
			variable m, b
			if (pkStart[ResRow] != start )
				m = (medStartY- medStopY) / (avgStartX - avgStopX)
				b = medStartY - m*avgStartX

				make /o/n=2 $vert = {chrom(pkStart[ResRow]), b + m*pkStart[ResRow]}, $vertX = {pkStart[ResRow],pkStart[ResRow]}
				AppendToGraph $vert vs $vertX
				if (cmpstr(mol, currMol) == 0 )
					sprintf com "ModifyGraph rgb(%s)=(0,0,65535)", vert
				else
					sprintf com "ModifyGraph rgb(%s)=(16386,65535,16385), lstyle(%s)=2", vert, vert
				endif
				execute com
			endif
			if (pkStop[ResRow] != stop )
				m = (medStartY- medStopY) / (avgStartX - avgStopX)
				b = medStartY - m*avgStartX

				make /o/n=2 $vert = {chrom(pkStop[ResRow]), b + m*pkStop[ResRow]}, $vertX = {pkStop[ResRow],pkStop[ResRow]}
				AppendToGraph $vert vs $vertX
				if (cmpstr(mol, currMol) == 0 )
					sprintf com "ModifyGraph rgb(%s)=(0,0,65535)", vert
				else
					sprintf com "ModifyGraph rgb(%s)=(16386,65535,16385), lstyle(%s)=2", vert, vert
				endif
				execute com
			endif
			
		
			if (strsearch(TraceNameList("", ";", 1), bline, 0) == -1)
				if ( meth != 4 )
					AppendToGraph $bline vs $blineX
				else
					AppendToGraph $bline, $Gbline
					sprintf com, "ModifyGraph rgb(%s) = (3,52428,1), lsize(%s) = 2", Gbline, Gbline
					execute com
				endif
				if (cmpstr(mol, currMol) == 0 )
					if ( badFlag )
						sprintf com "ModifyGraph lsize(%s)=2,lstyle(%s)=2,rgb(%s)=(59000,1,1)", bline, bline, bline
						execute com
					elseif ( manFlag )
						sprintf com "ModifyGraph lsize(%s)=1,lstyle(%s)=2,rgb(%s)=(0,0,65535)", bline, bline, bline
						execute com
					else
						sprintf com "ModifyGraph rgb(%s)=(0,0,65535)", bline
						execute com
					endif
				else
					sprintf com "ModifyGraph rgb(%s)=(16386,65535,16385), lstyle(%s)=2", bline, bline
					execute com
				endif
			endif
			SetDataFolder root:chroms
			
		endif
		inc += 1
	while ( inc < ItemsInList(molLst))
	
	SetDataFolder root:

end


// Draws a tick mark indicateing where the retention time is on displayed chrom.
Function DrawPeakRetTick(  )

	NVAR chromNum = root:V_chromNum
	NVAR currCh = root:V_currCh
	NVAR currMolRow = root:DB:V_currMolRow
	SVAR currMol = root:S_currPeak
	SVAR molLst = $"root:DB:S_molLst" + num2str(currCh)

	string rettick, rettickX, com, mol
	variable inc, retval, yscale

	GetAxis /Q left
	yscale = (V_Max - V_min) * 0.025
	
	SetDataFolder root:chroms

	string dispchrom =  ChromName(currCh, chromNum)
	wave chrom = $dispchrom

	do
		mol = StringFromList( inc, molLst, ";" )
		rettick = "rettick_" + mol
		rettickX = "rettickX_" + mol
		wave retwv = $("root:" + mol + "_ret")
		retval = retwv[ReturnResRowNumber(returnChannel(mol), chromNum)]
					
		SetDataFolder root:temp
		make /o/n=2 $rettick = {chrom(retval)-yscale, chrom(retval)+yscale}, $rettickX = {retval, retval}
	
		if (strsearch(TraceNameList("", ";", 1), rettick, 0) == -1)
			AppendToGraph $rettick vs $rettickX
			if (cmpstr(mol, currMol) == 0 )
				sprintf com "ModifyGraph rgb(%s)=(0,0,65535), lsize(%s)=2", rettick, rettick
				execute com
			else
				sprintf com "ModifyGraph rgb(%s)=(16386,65535,16385)", rettick
				execute com
			endif
		endif
		SetDataFolder root:chroms
		
		inc += 1
	while ( inc < ItemsInList(molLst))

	SetDataFolder root:	

end

// returns a chrom name
function/t ChromName(ch, chrNm)
	variable ch, chrNm
	
	return "chr" + num2str(ch) + "_" +PadStr(chrNm, 5, "0")
	
end

Function MANcheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR currCh = root:V_currCh
	NVAR chromNum = root:V_chromNum
	SVAR currPeak = root:S_currPeak
	String chrom
	
	variable row

	strswitch( ctrlName )
		case "autoScale":
			DrawChrom()
			break
			
		case "manFlag":
			wave flag = $("root:" + currPeak + "_flagMan")
			row = ReturnResRowNumber( currCh, chromNum )
			flag[row] = checked
			UpdateASwaves(1)
			break

		case "badFlag":
			wave flag = $("root:" + currPeak + "_flagBad")
			row = ReturnResRowNumber( currCh, chromNum )
			flag[row] = checked
			UpdateASwaves(2)
			break
			
	endswitch

End


// function returns a specific value from a "result" wave of S_currPeak and V_chromNum.  Used to update ScanChroms panel.
function ReturnResult(res)
	string res
	
	SVAR mol = root:S_currPeak
	NVAR chromNum = root:V_chromNum
	
	variable ch = returnChannel(mol)
	variable ResRow = ReturnResRowNumber(ch, chromNum)
	
	if (cmpstr(res,"temp") == 0)
		wave resWv = root:inj_t
		return resWv[ResRow][ch-1]
	elseif (cmpstr(res,"press") == 0)
		wave resWv = root:inj_p
		return resWv[ResRow][ch-1]
	elseif (cmpstr(res, "selpos") == 0 )
		wave resWv = root:selpos
		return resWv[ResRow]
	else
		string result = "root:" + mol + "_" + res
		if ( exists(result) == 1)
			wave resWv = $result
			return resWv[ResRow]
		else
			return NaN
		endif
	endif
	
end

function RespTable( mol )
	string mol
	
	variable ch = returnChannel(mol)
	string win = mol + "respTable"
	wave AS = $("root:AS:CH" + num2str(ch) + "_All")

	string ret = mol + "_ret"
	string start = mol + "_start"
	string stop = mol + "_stop"
	string height = mol + "_height"
	string are = mol + "_area"
	string resp = mol + "_resp"
	string man = mol + "_flagMan"
	string bad = mol + "_flagBad"
	string com
	
	DoWindow /k $win
	Edit/K=1/W=(5,44,910,378) 
	DoWindow /c $win
	
	if ( cmpstr(mol, "PAN") == 0 )
		AppendToTable AS, selposPAN
	else
		AppendToTable AS, selpos
	endif
	sprintf com, "AppendToTable %s,%s,%s,%s,%s,%s,%s,%s", start, ret, stop, are, height, resp, man, bad
	execute com
	sprintf com, "ModifyTable style(:AS:%s)=1,rgb(:AS:%s)=(0,0,65535)", NameOfWave(AS), NameOfWave(AS)
	execute com
	sprintf com, "ModifyTable rgb(%s)=(65535,0,0), rgb(%s)=(65535,0,0)", man, bad
	execute com
	
end

Function ASviewTable()
	NVAR ch = root:V_currCh
	SVAR mol = root:S_currPeak
	String com, title
	SetDataFolder root:AS:

	title = "ASview"
	DoWindow /k $title
	sprintf com, "Edit/K=1/W=(4,108,429,638) CH%d_AS,CH%d_All,CH%d_Manual,CH%d_Bad as \"Channel %d AS View\"", ch, ch, ch, ch, ch
	execute com
	sprintf com, "ModifyTable style(CH%d_AS)=1,rgb(CH%d_AS)=(0,0,65535)", ch, ch
	execute com
	DoWindow /c $title
	
	SetDataFolder root:
EndMacro

// Results edge plot
function ResEdgePlot( mol )
	string mol
	
	variable ch = returnChannel(mol)
	string win = mol + "edgePlot"
	string title = mol + " peak edge results"
	wave AS = $("root:AS:CH" + num2str(ch) + "_All")

	string ret = mol + "_ret"
	string start = mol + "_start"
	string stop = mol + "_stop"
	string height = mol + "_height"
	string are = mol + "_area"
	string resp = mol + "_resp"
	string man = mol + "_flagMan", tmpMan = "root:temp:" + man + "_tmp"
	string bad = mol + "_flagBad", tmpBad = "root:temp:" + bad + "_tmp"
	string com

	duplicate /o $bad, $tmpBad
	sprintf com, "%s := SelectNumber(root:%s[p], NaN, root:%s[p])", tmpBad, Bad, Bad
//	sprintf com, "%s := tmpFlagUpdate(root:%s)", tmpBad, bad
	execute com
	duplicate /o $man, $tmpMan
	sprintf com, "%s := SelectNumber(root:%s[p], NaN, root:%s[p])", tmpMan, Man, Man
//	sprintf com, "%s := tmpFlagUpdate(root:%s)", tmpMan, man
	execute com
	
	DoWindow /k $win
	Display /K=1/W=(12,370,553,716) $ret vs AS as title
	DoWindow /c $win

	AppendToGraph $ret vs AS
	AppendToGraph $start,$stop vs AS
	AppendToGraph $start,$stop vs AS
	AppendToGraph $start,$ret,$stop vs AS

	ModifyGraph gfSize=14,wbRGB=(49151,53155,65535)
	ModifyGraph mode=3
	
	sprintf com, "ModifyGraph marker(%s)=19,marker(%s#1)=16,marker(%s)=19,marker(%s)=19", ret, ret, start, stop
	execute com
	sprintf com, "ModifyGraph marker(%s#1)=16,marker(%s#1)=16,marker(%s#2)=19, marker(%s#2)=19", start, stop, start, stop
	execute com
	sprintf com, "ModifyGraph rgb(%s)=(0,0,0),rgb(%s#1)=(0,0,0),rgb(%s)=(0,0,0),rgb(%s)=(0,0,0)", ret, ret, start, stop
	execute com
	sprintf com, "ModifyGraph rgb(%s#1)=(0,0,0),rgb(%s#1)=(0,0,0), msize(%s#2)=2", start, stop, stop
	execute com
	sprintf com, "ModifyGraph msize(%s#1)=5,msize(%s#1)=5,msize(%s#2)=2,msize(%s#2)=3", start, stop, start, ret
	execute com
	sprintf com, "ModifyGraph mrkStrokeRGB(%s#1)=(52428,52428,52428)", start
	execute com
	sprintf com, "ModifyGraph zmrkSize(%s)={%s,0,1,0,4},zmrkSize(%s#1)={%s,0,1,0,4}", ret, tmpBad, ret, tmpMan
	execute com
	sprintf com, "ModifyGraph zmrkSize(%s)={%s,0,1,1,4},zmrkSize(%s)={%s,0,1,1,4}", start, tmpBad, stop, tmpBad
	execute com
	sprintf com, "ModifyGraph zmrkSize(%s#1)={%s,0,1,1,4},zmrkSize(%s#1)={%s,0,1,1,4}", start, tmpMan, stop, tmpMan
	execute com
	sprintf com, "ModifyGraph zColor(%s#2)={selpos,0,16,Rainbow},zColor(%s#2)={selpos,0,16,Rainbow}", start, ret
	execute com
	sprintf com, "ModifyGraph zColor(%s#2)={selpos,0,16,Rainbow}, textMarker(%s#2)={selpos,\"default\",0,0,5,0.00,0.00}", stop, ret
	execute com

	ModifyGraph grid=1
	ModifyGraph mirror=2
	Label left "Peak Start, Ret, and Stop Times"
	Label bottom "Chrom Number"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom

	sprintf com, "\\Z10\\s(%s) Bad flag\r\\s(%s#1) Manual flag ", ret, ret
	Legend/N=text0/J/B=1/X=-0.70/Y=88.43 com

End

// results response plot
function ResRespPlot( mol )
	string mol
	
	variable ch = returnChannel(mol)
	string win = mol + "responsePlot"
	string title = mol + " response results"
	wave AS = $("root:AS:CH" + num2str(ch) + "_All")

	string height = mol + "_height"
	string are = mol + "_area"
	string resp = mol + "_resp"
	string man = mol + "_flagMan", tmpMan = ":temp:" + man + "_tmp"
	string bad = mol + "_flagBad", tmpBad = ":temp:" + bad + "_tmp"
	string com, AorH, lftlabel

	wave DBrespMeth = root:DB:DB_respMeth
	variable DBrow = returnMolDBrow(mol)
	if ( DBrespMeth[DBrow] == 1 )
		AorH = are
		lftlabel = "Peak Area and Response"
	else
		AorH = height
		lftlabel ="Peak Height and Response"
	endif

	DoWindow /k $win
	Display /K=1/W=(556,370,1097,716) $AorH vs AS as title
	DoWindow /c $win

	AppendToGraph $resp vs AS
	AppendToGraph $AorH vs AS
	AppendToGraph $AorH vs AS
		
	ModifyGraph gfSize=14,wbRGB=(49151,53155,65535)
	ModifyGraph mode=3
	ModifyGraph marker[0]=19,marker[1]=19,marker[2]=42,marker[3]=12
	ModifyGraph rgb[1]=(0,0,65535),rgb[2]=(0,0,0),rgb[3]=(0,0,0)
	ModifyGraph zmrkSize[2]={$tmpBad,0,1,1,4},zmrkSize[3]={$tmpMan,0,1,1,4}
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph textMarker[1]={selpos,"default",1,0,5,0.00,0.00}
	Label bottom "Chrom Number"
	Label left lftlabel
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom

	sprintf com, "\\Z10\\s(%s#1) Bad flag\r\\s(%s#2) Manual flag ", AorH, AorH
	Legend/N=text0/J/B=1/X=-0.70/Y=88.43 com
	
	sprintf com, "\\Z10\\s(%s) %s\r\\s(%s) response", AorH, StringFromList(1, AorH, "_"), resp
	Legend/N=text1/J/X=-7.67/Y=-3.66 com

	
end

function tmpFlagUpdate(flagWv)
	wave flagWv

	wave tmpflag = $("root:temp:" + NameOfWave(flagWv) + "_tmp")
	
	tmpFlag = flagWv
	freplace(tmpFlag, 0, nan)
	
end


// makes a 2D matrix of all chroms in one channel
function ChromMatrix( )

	variable inc
	string chrom 
	
	setdatafolder root:chroms
	make /o/n=(numpnts(chr1_00085), 113) ch1 = 0
	
	for (inc=0; inc< 113; inc+=1)
		chrom = ChromName(2, inc+1)
		wave chr = $chrom
		ch1[][inc] = chr[p]
	endfor
	
	setdatafolder root:

end

