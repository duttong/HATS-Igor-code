#pragma rtGlobals= 1
#include "macros-strings and lists"

|Modified for POLARIS.   Changed some wave names and variable names to remove the "MKS" name.
|
|Modified for STRAT mission.  To change the mission name
|edit the variable G_mission in the init() macro.
|
|GSD Oct 95
|GSD updated July 96.  Remove all string arrays.  This allows the expriment to be save as "packed"
|
menu "macros"
	"Read GC Data"
	"-"
	"Make ACATS Graphs"
	"Make ACATS Layouts"
	"-"
	"Statistics Pages"
	"-"
	"Remove All Graphs"
	"Remove All Graphs and Layouts"
end

proc init ()
	variable /G  G_r, G_g, G_b, G_colorPieAngle, G_colorPiePeriod
	variable /G G_ymin, G_ymax
	string /G G_mission="POLARIS", G_fltDate
	make /n=2 merit
end

proc ReadGCData()
	xreadgcdata
end

proc RemoveAllGraphs()
	removeDisplayedGraphs()
end

proc RemoveAllGraphsandLayouts()
	removeDisplayedObjects()
end

macro makeACATSgraphs (fltDate, mission)
	string fltDate, mission=G_mission
	prompt fltDate, "Enter date of this flight:"
	prompt mission, "Enter mission string:"
	
	string /G G_fltDate=fltDate
	string /G G_mission=mission
	
	makeACATSgraphsFUNCT (fltDate)
end

function makeACATSgraphsFUNCT (fltDate)
	string fltDate
	
	SVAR mission = G_mission
	
	string botLbl = mission + ":  " + fltDate
	variable doTags=1,doLegend=0
	
	string flowA = "AF_CAR1_FLOW;AF_CAR2_FLOW;AF_BACK1_FLOW;AF_BACK2_FLOW"
	string flowB = "BF_CAR3_FLOW;BF_CAR4_FLOW;BF_BACK3_FLOW;BF_BACK4_FLOW"
	string presA = "AP_ECD1_PRES;AP_ECD2_PRES"
	string presB = "BP_ECD3_PRES;BP_ECD4_PRES"
	string drvA = "AD_ECD1_DRIVE;AD_ECD2_DRIVE"
	string drvB = "BD_ECD3_DRIVE;BD_ECD4_DRIVE"
	string temp1A = "AT_MFM_TEMP;AT_PrsCont_TEMP;AT_ECD1_CAN_TEMP;AT_ECD2_CAN_TEMP;AT_SHELF_TEMP"
	string temp1B = "BT_MFM_TEMP;BT_PrsCont_TEMP;BT_ECD3_CAN_TEMP;BT_ECD4_CAN_TEMP;BT_SHELF_TEMP"
	string temp2A = "AT_GSV_TEMP;AT_TYLAN_TEMP"
	string temp2B = "BT_GSV_TEMP;BT_TYLAN_TEMP"	
	string tempCols = "AT_COL1_CAN_TEMP;AT_COL2_CAN_TEMP;BT_COL3_CAN_TEMP;BT_COL4_CAN_TEMP;tempCOL1;tempCOL2;tempCOL3;tempCOL4"
	string tempECDs = "tempECD1;tempECD2;tempECD3;tempECD4"
	string temp1X = "XT_COMP_TEMP;XT_N2_SOL_TEMP;XT_MFM_TEMP;XT_INLET_TEMP;BT_EXHAUST_TEMP"
	string temp2X = "XT_CRIMP_TEMP;XT_SSV_TEMP;XT_N2O_REG_TEMP"
	string spansHI = "XP_CAL_REG_HI;XP_P5_REG_HI;XP_N2_REG_HI"
	string spansLO = "XP_CAL_REG_LO;XP_P5_REG_LO;XP_N2_REG_LO;XP_N2O_PRES;XP_PUMP_PRES"
	string pres1X = "XP_SAMP_PRES"
	string drvX = "XD_SAMP_DRIVE"
	string pres2X = "XP_EXT_PRES;XP_QBAY_PRES"
	string flowX = "XF_SAMP_FLOW"
	string OverFlowX = "XF_PUMP_OVERFLOW"
	string baseDC = "XV_PLUS_28;XV_MINUS_15;XV_PLUS_5;XV_PLUS_15;XV_PLUS_24"
	string Detector1Avg = "det1avg"
	string Detector2Avg = "det2avg"
	string Detector3Avg = "det3avg"
	string Detector4Avg = "det4avg"
	string CompMerit ="Merit"
	
	multiTraceGraph ("Plot_pres2X", pres2X,"External Pressures [mbar]", botLbl,1)
	multiTraceGraph ("Plot_flowX", flowX,"Sample Flow [sccm]", botLbl,1)
	multiTraceGraph ("Plot_OverFlowX",OverFlowX,"Pump Overflow [slm]", botLbl,1)
	multiTraceGraph ("Plot_pres1X", pres1X,"Sample Pressure [mbar]", botLbl,1)
	multiTraceGraph ("Plot_drvX", drvX,"Sample Press Drive", botLbl,1)
	multiTraceGraph ("Plot_spansHI", spansHI,"High Pressure Spans [psia]", botLbl,1)
	multiTraceGraph ("Plot_spansLO", spansLO,"Low Pressure Spans [psia]", botLbl,1)
	multiTraceGraph ("Plot_tempECDs", tempECDs,"ECD Temps", botLbl,1)
	multiTraceGraph ("Plot_temp1X", temp1X,"Base Temps", botLbl,1)
	multiTraceGraph ("Plot_temp2X", temp2X,"Base Temps (controlled)", botLbl,1)
	multiTraceGraph ("Plot_tempCols", tempCols,"Column Temps", botLbl,0)
	multiTraceGraph ("Plot_temp2B", temp2B,"Module B Temps (controlled)", botLbl,1)
	multiTraceGraph ("Plot_temp2A", temp2A,"Module A Temps (controlled)", botLbl,1)
	multiTraceGraph ("Plot_temp1B", temp1B,"Module B Temps", botLbl,1)
	multiTraceGraph ("Plot_temp1A", temp1A,"Module A Temps", botLbl,1)
	multiTraceGraph ("Plot_presB", presB,"Module B pressures", botLbl,1)
	multiTraceGraph ("Plot_presA", presA,"Module A pressures", botLbl,1)
	multiTraceGraph ("Plot_drvB", drvB,"Module B press drives", botLbl,1)
	multiTraceGraph ("Plot_drvA", drvA,"Module A press drives", botLbl,1)
	multiTraceGraph ("Plot_flowB", flowB,"Module B flows", botLbl,1)
	multiTraceGraph ("Plot_flowA", flowA,"Module A flows", botLbl,1)
	multiTraceGraph ("Plot_baseDC",baseDC,"Baseplate DC Out", botLbl, 1)
	multiTraceGraph ("Plot_Detector1Avg",Detector1Avg,"Detector 1 10s Averages", botLbl, 1)
	multiTraceGraph ("Plot_Detector2Avg",Detector2Avg,"Detector 2 10s Averages", botLbl, 1)
	multiTraceGraph ("Plot_Detector3Avg",Detector3Avg,"Detector 3 10s Averages", botLbl, 1)
	multiTraceGraph ("Plot_Detector4Avg",Detector4Avg,"Detector 4 10s Averages", botLbl, 1)
	multiTraceGraph ("Plot_CompMerit", CompMerit,"Merit (fraction of second)", botLbl, 1) 
	
	doAlert 0,"Adjust the engineering graphs manually (if you want).  Then run \"Make ACATS Layouts.\""
	
end

proc TestOrientation()
	silent 1
	string com="\Z24DO THE FOLLOWING NOW:\r"
	Layout /W=(80,40,460,490)  as "Test Orientation"
	DoAlert 1,"Is the page in this layout vertical? If not, click on the NO button."
	if (V_flag != 1) then
		com += "\Z18	1) click on \"File:Page setup for this layout\"\r"
		com += "\Z18	2) reset the page orientation to vertical \r"
		com += "\Z18	3) Click on OK.\r"
		com += "\Z18	4) Kill this layout window and do not save it.\r"
		com += "\Z18	5) Re-run \"Print ACATS Layouts.\"\r"
	      TextBox  /N=TextBox_0/A=LT/X=1.27273/Y=3.70879  com
		Modify width(TextBox_0)=538,height(TextBox_0)=300
		abort
	endif  
	DoWindow /k $(WinName (0,4)) 
end


macro makeACATSlayouts (doPrint)
	variable doPrint=2
	prompt doPrint, "Do you wanna print the blighters as well?", popup "Yeah Okay;Nope"
	doPrint = (doPrint == 1)
	
	silent 1
	
	variable page=1
	
 	TestOrientation()
	
	page = StatsLayout (page, doPrint)
		
	Layout2Plot ("flowsAB", "Plot_flowA", "Plot_flowB", doPrint, page); 						page += 1
	Layout2Plot ("PIDA", "Plot_presA", "Plot_drvA", doPrint, page); 							page += 1
	Layout2Plot ("PIDB", "Plot_presB", "Plot_drvB", doPrint, page); 							page += 1
	Layout2Plot ("tempA", "Plot_temp1A", "Plot_temp2A", doPrint, page); 						page += 1
	Layout2Plot ("tempB", "Plot_temp1B", "Plot_temp2B", doPrint, page); 						page += 1
	Layout2Plot ("tempCanCol", "Plot_tempECDs", "Plot_tempCols", doPrint, page); 			page += 1
	Layout2Plot ("BaseTemps", "Plot_temp1X", "Plot_temp2X", doPrint, page); 				page += 1
	Layout3Plot ("presX", "Plot_pres2X", "Plot_spansHI", "Plot_spansLO", doPrint, page); 	page += 1
	Layout2Plot ("SampleFlow", "Plot_pres1X", "Plot_drvX", doPrint, page); 					page += 1
	Layout2Plot ("SamplePress", "Plot_flowX", "Plot_OverFlowX", doPrint, page); 				page += 1
	Layout2Plot ("ModAdetavg", "Plot_Detector1Avg", "Plot_Detector2Avg", doPrint, page); 	page += 1
	Layout2Plot ("ModBdetavg", "Plot_Detector3Avg", "Plot_Detector4Avg", doPrint, page);	page += 1
	
	doWindow /F ACATSstats2
	doWindow /F ACATSstats1

end	

function Layout1Plot (layoutNm, grp1, doPrint, page)
	string grp1, layoutNm
	variable doPrint, page
	
	string com

	variable numPlots = 2

	if (StrSearch(WinList ("*", ";", ""), grp1, 0) > -1)
		sprintf com, "Layout /T/C=1/A=(%d,1)/W=(80,40,460,490) %s", numPlots, grp1
		execute com
		doWindow /K $layoutNm
		doWindow /C $layoutNm
		Textbox/N=PageNum/F=0/A=LB/X=95.09/Y=1.10 "\\Z16\\f01\\F'Times'"+num2str(page)
		if (doPrint)
			execute "printLayout " + layoutNm
			doWindow /K $layoutNm
		endif
	else
		beep;printf "Couldn't make layout.  The graph %s does not exist.\r", grp1
	endif
end

function Layout2Plot (layoutNm, grp1, grp2, doPrint, page)
	string grp1, grp2, layoutNm
	variable doPrint, page
	
	string pltlst=WinList ("*", ";", ""), com
	variable numPlots = 2

	if ((StrSearch(pltlst, grp1, 0) > -1) * (StrSearch(pltlst, grp2, 0) > -1))
		sprintf com, "Layout /T/C=1/A=(%d,1)/W=(80,40,460,490) %s, %s", numPlots, grp1, grp2
		execute com
		doWindow /K $layoutNm
		doWindow /C $layoutNm
		Textbox/N=PageNum/F=0/A=LB/X=95.09/Y=1.10 "\\Z16\\f01\\F'Times'"+num2str(page)
		if (doPrint)
			execute "printLayout " + layoutNm
			doWindow /K $layoutNm
		endif
	else
		beep;printf "Couldn't make layout.  One or more of the following graphs not found: %s or %s\r", grp1, grp2
	endif
end

function Layout3Plot (layoutNm, grp1, grp2, grp3, doPrint, page)
	string grp1, grp2, grp3, layoutNm
	variable doPrint, page
	
	string pltlst = WinList ("*", ";", ""), com
	variable numPlots = 3

	if ((StrSearch(pltlst, grp1, 0) > -1) * (StrSearch(pltlst, grp2, 0) > -1) * (StrSearch(pltlst, grp3, 0) > -1))
		sprintf com, "Layout /T/C=1/A=(%d,1)/W=(80,40,460,490) %s, %s, %s", numPlots, grp1, grp2, grp3
		execute com
		doWindow /K $layoutNm
		doWindow /C $layoutNm
		Textbox/N=PageNum/F=0/A=LB/X=95.09/Y=1.10 "\\Z16\\f01\\F'Times'"+num2str(page)
		if (doPrint)
			execute "printLayout " + layoutNm
			doWindow /K $layoutNm
		endif
	else
		beep;printf "Couldn't make layout.  One or more of the following graphs not found: %s, %s or %s\r", grp1, grp2, grp3
	endif
end


Function advanceColor ()
	NVAR red = G_r, green = G_g, blue = G_b, angle = G_colorPieAngle, period = G_colorPiePeriod
	
	red=65535*((sin (angle)+1)/2)
	green=65535*((sin (angle+2*Pi/3)+1)/2)
	blue=65535*((sin (angle+2*2*Pi/3)+1)/2)
	angle += (2*Pi/period)
end

Function multiTraceGraph (winNm,wvLst,leftLbl,botLbL,doTags)
	string winNm,wvLst,leftLbl,botLbL
	variable doTags
	
	variable/g G_r,G_g,G_b,G_colorPieAngle,G_colorPiePeriod
	variable index, wvCnt
	string wvNm, axisCom, colorpluswvNm
	
	index = 0
	wvCnt = 0
	axisCom = "autoSetHorizAxis (\"left\""
	variable numWvs= NumElementsInList(wvLst, ";")
	variable xInc = (pnt2x(merit, numpnts (merit) - 1) - pnt2x(merit, 0)) / (numWvs+1)
	variable xTagLoc = pnt2x(merit, 0) + xInc
	
	if (index < numWvs) 
		doWindow /K $winNm
		Display 
		doWindow /C $winNm
		G_colorPiePeriod=numWvs
		G_colorPieAngle = 0
		
		do
			wvNm = GetStrFromList(wvLst, index, ";")
			if (exists (wvNm) == 1)
				wvCnt+=1
				appendToGraph $wvNm
				advanceColor ()
				colorpluswvNm = "\\K("+num2str(G_r)+","+num2str(G_g)+","+num2str(G_b)+")" + wvNm
				if (doTags == 1)
					tag /F=0/X=10/Y=7 $wvNm, xTagLoc, colorpluswvNm
					xTagLoc = pnt2x(merit, 0) + xInc*(wvCnt+1)
					endif
				modifyGraph  rgb ($wvNm) = (G_r,G_g,G_b)
				
				axisCom += ",\"" + wvNm + "\""
			else
				beep;print "Wave: "+wvNm+" not found in experiment..."
			endif
		
			index +=1
		while (index < numWvs) 
		
		if (wvCnt > 0)
			if (wvCnt < 8)
				do 
					axisCom += ",\"\""
					wvCnt += 1
				while (wvCnt < 8)
			endif
			
			axisCom += ")"
			print axisCom
			execute axisCom				
			
			if (doTags == 0)
				legend
			endif
			
			label left leftLbl
			label bottom botLbL
			modifyGraph grid=1, mirror=1,minor=1
		else
			doWindow /K $winNm
			print "Could not make graph: ", winNm, " because none of it's waves are loaded..."
		endif	
	else
		doAlert 0, "No waves in list... Can't give you a plot..."
	endif
	
end

function getAscentTime(press)
	wave press
	
	variable n=numpnts(press), inc=0, asc=0
	wave der=$(Nameofwave(press)+"_der")
	variable lowpress=300, lowder=-0.05, highder=-lowder, latesttime=1800
	
	duplicate /o press der
	Differentiate der
	Smooth/S=2 15, der
	
	do
		if ((press[inc] < lowpress) * (der[inc] <= highder) * (der[inc] >= lowder))
			return pnt2x(press, inc)
		endif
		if ((asc == 0) * (inc == latesttime))
			printf "No obvious level flight after ascent.\r"
			return pnt2x(press, 0)
		endif
		inc += 1
	while (inc < latesttime)
	
	killwaves der
	
end

function getDescentTime(press)
	wave press
	
	variable n=numpnts(press), inc=n, dsc=0
	wave der=$(Nameofwave(press)+"_der")
	variable lowpress=150, lowder=-0.15, highder=-lowder
	
	duplicate /o press der
	Differentiate der
	Smooth/S=2 15, der
	
	do
		if ((press[inc] < lowpress) * (der[inc] <= highder) * (der[inc] >= lowder))
			return pnt2x(press, inc)
		endif
		if ((dsc == 0) * (inc == n/2))
			printf "No obvious level flight near the descent.\r"
			return pnt2x(press, n-1)
		endif
		inc -= 1
	while (inc > n/2)
	
	killwaves der
	
end

Macro StatisticsPages(doPrint)
	variable doPrint=2
	prompt doPrint, "Do you wanna print the stats pages?", popup "Yeah Okay;Nope"
	
	silent 1
	doPrint = (doPrint == 1)

	TestOrientation()
	
	StatsLayout(1, doPrint)
end

#pragma rtGlobals= 0
function StatsLayout(page, doPrint)
	variable page, doPrint
	
	string txt1, txt2, lbl
	string title, flttxt, cyltxt1, cyltxt2, cyltxt3, pumptxt, comptxt, powertxt1, powertxt2
	string tmptxt1, tmptxt2, tmptxt3, tmptxt4, tmptxt5, tmptxt6, tmptxt7
	string ch1txt1, ch1txt2, ch1txt3
	string ch2txt1, ch2txt2, ch2txt3
	string ch3txt1, ch3txt2, ch3txt3
	string ch4txt1, ch4txt2, ch4txt3
	wave arbit = merit										|arbitrary wave 
	variable starttime = pnt2x(arbit, 0)
	variable endtime = pnt2x(arbit, numpnts (arbit) - 1)
	variable durSec = endtime-starttime
	variable asc = getAscentTime(XP_EXT_PRES)
	variable dsc = getDescentTime(XP_EXT_PRES)
	variable first = starttime+30, last = endtime - 1		|in seconds
	SVAR mission = G_mission, fltDate = G_fltDate
	
	lbl = mission + ":  " + fltDate
	sprintf title, "\\F'Times'\\Z18\\f01%s \rACATS Engineering Statistics\\f00\r\r", lbl
	
	flttxt = "\t\\Z14\\f01Flight Statistics\t\tWhole Flight\t\t\t\tStats. at altitude\\f00\\Z12\r"
	sprintf flttxt, "%s\tFlight Duration (seconds):\t%d\t(%0.2f hours)\r", flttxt, durSec, durSec/3600
	wavestats/Q/R=(first, last) XP_EXT_PRES
	sprintf flttxt, "%s\tExternal Pressure (mbar):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", flttxt, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) XP_EXT_PRES
	sprintf flttxt, "%s\t\t(%0.1f � %0.1f)\r", flttxt, V_avg, V_sdev
	wavestats/Q/R=(first, last) XP_QBAY_PRES
	sprintf flttxt, "%s\tQ-Bay Pressure (mbar):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", flttxt, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) XP_QBAY_PRES
	sprintf flttxt, "%s\t\t\t(%0.1f � %0.1f)\r", flttxt, V_avg, V_sdev
	
	cyltxt1 = "\r\t\\Z14\\f01Cylinder Pressures\\f00\\Z12\r"
	wavestats/Q/R=(first, last) XP_N2_REG_LO
	sprintf cyltxt1, "%s\tN2 Low Pressure (psia):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", cyltxt1, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) XP_N2_REG_LO
	sprintf cyltxt1, "%s\t\t\t(%0.1f � %0.1f)\r", cyltxt1, V_avg, V_sdev
	wavestats/Q/R=(first, last) XP_P5_REG_LO
	sprintf cyltxt1, "%s\tP5 Low Pressure (psia):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", cyltxt1, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) XP_P5_REG_LO
	sprintf cyltxt1, "%s\t\t\t(%0.1f � %0.1f)\r", cyltxt1, V_avg, V_sdev
	cyltxt2=""
	wavestats/Q/R=(first, last) XP_CAL_REG_LO
	sprintf cyltxt2, "%s\tCal Low Pressure (psia):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", cyltxt2, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) XP_CAL_REG_LO
	sprintf cyltxt2, "%s\t\t\t(%0.1f � %0.1f)\r", cyltxt2, V_avg, V_sdev
	wavestats/Q/R=(first, last) XP_N2O_PRES
	sprintf cyltxt2, "%s\tN2O  Pressure (psia):\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", cyltxt2, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) XP_N2O_PRES
	sprintf cyltxt2, "%s\t\t\t(%0.1f � %0.1f)\r", cyltxt2, V_avg, V_sdev
	cyltxt3=""
	wavestats/Q/R=(first, last) XP_N2_REG_HI
	if (V_avg < 1000)
		sprintf cyltxt3, "%s\tN2 High Pressure (psia):\t%d,  (%d � %d),  %d", cyltxt3, V_min, V_avg, V_sdev, V_max
		sprintf cyltxt3, "%s\t\t\tConsumption: %0.1f psi/h\r", cyltxt3, (XP_N2_REG_HI(asc)-XP_N2_REG_HI(dsc))/(dsc-asc)*3600
	else
		sprintf cyltxt3, "%s\tN2 High Pressure (psia):\t%d,  (%d � %d),  %d", cyltxt3, V_min, V_avg, V_sdev, V_max
		sprintf cyltxt3, "%s\t\t\tConsumption: %0.1f psi/h\r", cyltxt3, (XP_N2_REG_HI(asc)-XP_N2_REG_HI(dsc))/(dsc-asc)*3600
	endif
	wavestats/Q/R=(first, last) XP_P5_REG_HI
	if (V_avg < 1000)
		sprintf cyltxt3, "%s\tP5 High Pressure (psia):\t%d,  (%d � %d),  %d", cyltxt3, V_min, V_avg, V_sdev, V_max
		sprintf cyltxt3, "%s\t\t\tConsumption: %0.1f psi/h\r", cyltxt3, (XP_P5_REG_HI(asc)-XP_P5_REG_HI(dsc))/(dsc-asc)*3600
	else
		sprintf cyltxt3, "%s\tP5 High Pressure (psia):\t%d,  (%d � %d),  %d", cyltxt3, V_min, V_avg, V_sdev, V_max
		sprintf cyltxt3, "%s\t\t\tConsumption: %0.1f psi/h\r", cyltxt3, (XP_P5_REG_HI(asc)-XP_P5_REG_HI(dsc))/(dsc-asc)*3600
	endif

	wavestats/Q/R=(first, last) XP_CAL_REG_HI
	if (V_avg < 1000)
		sprintf cyltxt3, "%s\tCal High Pressure (psia):\t%d,  (%d � %d),  %d", cyltxt3, V_min, V_avg, V_sdev, V_max
		sprintf cyltxt3, "%s\t\t\tConsumption: %0.1f psi/h\r", cyltxt3, (XP_CAL_REG_HI(asc)-XP_CAL_REG_HI(dsc))/(dsc-asc)*3600
	else
		sprintf cyltxt3, "%s\tCal High Pressure (psia):\t%d,  (%d � %d),  %d", cyltxt3, V_min, V_avg, V_sdev, V_max
		sprintf cyltxt3, "%s\t\t\tConsumption: %0.1f psi/h\r", cyltxt3, (XP_CAL_REG_HI(asc)-XP_CAL_REG_HI(dsc))/(dsc-asc)*3600
	endif
			
	pumptxt = "\r\t\\Z14\\f01Pump Diagnostics\\f00\\Z12\r"
	wavestats/Q/R=(first, last) XP_PUMP_PRES
	sprintf pumptxt, "%s\tPump  Pressure (psia):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", pumptxt, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) XP_PUMP_PRES
	sprintf pumptxt, "%s\t\t\t(%0.1f � %0.1f)\r", pumptxt, V_avg, V_sdev
	wavestats/Q/R=(first, last) XF_SAMP_FLOW
	sprintf pumptxt, "%s\tSample Flow(sccm):\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", pumptxt, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) XF_SAMP_FLOW
	sprintf pumptxt, "%s\t\t\t(%0.1f � %0.1f)\r", pumptxt, V_avg, V_sdev
	wavestats/Q/R=(first, last) XF_PUMP_OVERFLOW
	sprintf pumptxt, "%s\tPump Overflow (slm):\t\t%0.2f,  (%0.2f � %0.2f),  %0.2f", pumptxt, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) XF_PUMP_OVERFLOW
	sprintf pumptxt, "%s\t\t\t(%0.1f � %0.1f)\r", pumptxt, V_avg, V_sdev
	
	comptxt = "\r\t\\Z14\\f01Computer Diagnostics\\f00\\Z12\r"
	wavestats/Q/R=(first, last) XT_COMP_TEMP
	sprintf comptxt, "%s\tComputer  Temp (oC):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", comptxt, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) XT_COMP_TEMP
	sprintf comptxt, "%s\t\t\t(%0.1f � %0.1f)\r", comptxt, V_avg, V_sdev
	wavestats/Q/R=(first, last) merit
	sprintf comptxt, "%s\tMerit:\t\t\t\t%d,  (%0.1f � %0.1f),  %d\r", comptxt, V_min, V_avg, V_sdev, V_max
	
	powertxt1 = "\r\t\\Z14\\f01Power Diagnostics\\f00\\Z12\r"
	wavestats/Q/R=(first, last) XV_PLUS_28
	sprintf powertxt1, "%s\tPlus 28 Vdc:\t\t\t%0.1f,  (%0.2f � %0.2f),  %0.1f\r", powertxt1, V_min, V_avg, V_sdev, V_max
	wavestats/Q/R=(first, last) XV_PLUS_24
	sprintf powertxt1, "%s\tPlus 24 Vdc:\t\t\t%0.1f,  (%0.2f � %0.2f),  %0.1f\r", powertxt1, V_min, V_avg, V_sdev, V_max
	powertxt2 = ""
	wavestats/Q/R=(first, last) XV_PLUS_15
	sprintf powertxt2, "%s\tPlus 15 Vdc:\t\t\t%0.1f,  (%0.2f � %0.2f),  %0.1f\r", powertxt2, V_min, V_avg, V_sdev, V_max
	wavestats/Q/R=(first, last) XV_PLUS_5
	sprintf powertxt2, "%s\tPlus 5 Vdc:\t\t\t%0.1f,  (%0.2f � %0.2f),  %0.1f\r", powertxt2, V_min, V_avg, V_sdev, V_max
	wavestats/Q/R=(first, last) XV_MINUS_15
	sprintf powertxt2, "%s\tMinus 15 Vdc:\t\t%0.1f,  (%0.2f � %0.2f),  %0.1f\r", powertxt2, V_min, V_avg, V_sdev, V_max
	
	tmptxt1 = "\r\t\\Z14\\f01Various Temperatures (\\So\\M\\Z14C)\\f00\\Z12\r"
	wavestats/Q/R=(first, last) XT_N2_SOL_TEMP
	sprintf tmptxt1, "%s\tN2 Solenoid:\t\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", tmptxt1, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) XT_N2_SOL_TEMP
	sprintf tmptxt1, "%s\t\t\t(%0.1f � %0.1f)\r", tmptxt1, V_avg, V_sdev
	wavestats/Q/R=(first, last) XT_MFM_TEMP
	sprintf tmptxt1, "%s\tSample loop MFM:\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", tmptxt1, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) XT_MFM_TEMP
	sprintf tmptxt1, "%s\t\t\t(%0.1f � %0.1f)\r", tmptxt1, V_avg, V_sdev
	tmptxt2=""
	wavestats/Q/R=(first, last) XT_INLET_TEMP
	sprintf tmptxt2, "%s\tInlet:\t\t\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", tmptxt2, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) XT_INLET_TEMP
	sprintf tmptxt2, "%s\t\t\t(%0.1f � %0.1f)\r", tmptxt2, V_avg, V_sdev
	wavestats/Q/R=(first, last) BT_EXHAUST_TEMP
	sprintf tmptxt2, "%s\tExhaust:\t\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", tmptxt2, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) BT_EXHAUST_TEMP
	sprintf tmptxt2, "%s\t\t\t(%0.1f � %0.1f)\r", tmptxt2, V_avg, V_sdev
	tmptxt3=""
	wavestats/Q/R=(first, last) XT_N2O_REG_TEMP
	sprintf tmptxt3, "%s\tN2O regulator:\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", tmptxt3, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) XT_N2O_REG_TEMP
	sprintf tmptxt3, "%s\t\t\t(%0.1f � %0.1f)\r", tmptxt3, V_avg, V_sdev
	wavestats/Q/R=(first, last) XT_SSV_TEMP
	sprintf tmptxt3, "%s\tSSV:\t\t\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", tmptxt3, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) XT_SSV_TEMP
	sprintf tmptxt3, "%s\t\t\t(%0.1f � %0.1f)\r", tmptxt3, V_avg, V_sdev
	tmptxt4=""
//	wavestats/Q/R=(first, last) XT_CRIMP_TEMP
//	sprintf tmptxt4, "%s\tCrimp Oven:\t\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", tmptxt4, V_min, V_avg, V_sdev, V_max
//	wavestats /Q/R=(asc, dsc) XT_CRIMP_TEMP
//	sprintf tmptxt4, "%s\t\t\t(%0.1f � %0.1f)\r", tmptxt4, V_avg, V_sdev
	wavestats/Q/R=(first, last) AT_SHELF_TEMP
	sprintf tmptxt4, "%s\tModual A shelf:\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", tmptxt4, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) AT_SHELF_TEMP
	sprintf tmptxt4, "%s\t\t\t(%0.1f � %0.1f)\r", tmptxt4, V_avg, V_sdev
	tmptxt5=""
	wavestats/Q/R=(first, last) BT_SHELF_TEMP
	sprintf tmptxt5, "%s\tModual B shelf:\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", tmptxt5, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) BT_SHELF_TEMP
	sprintf tmptxt5, "%s\t\t\t(%0.1f � %0.1f)\r", tmptxt5, V_avg, V_sdev
	wavestats/Q/R=(first, last) AT_GSV_TEMP
	sprintf tmptxt5, "%s\tModual A GSV:\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", tmptxt5, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) AT_GSV_TEMP
	sprintf tmptxt5, "%s\t\t\t(%0.1f � %0.1f)\r", tmptxt5, V_avg, V_sdev
	tmptxt6=""
	wavestats/Q/R=(first, last) BT_GSV_TEMP
	sprintf tmptxt6, "%s\tModual B GSV:\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", tmptxt6, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) BT_GSV_TEMP
	sprintf tmptxt6, "%s\t\t\t(%0.1f � %0.1f)\r", tmptxt6, V_avg, V_sdev
	wavestats/Q/R=(first, last) AT_TYLAN_TEMP
	sprintf tmptxt6, "%s\tModual A tylan:\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", tmptxt6, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) AT_TYLAN_TEMP
	sprintf tmptxt6, "%s\t\t\t(%0.1f � %0.1f)\r", tmptxt6, V_avg, V_sdev
	tmptxt7=""
	wavestats/Q/R=(first, last) BT_TYLAN_TEMP
	sprintf tmptxt6, "%s\tModual B tylan:\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", tmptxt6, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) BT_TYLAN_TEMP
	sprintf tmptxt6, "%s\t\t\t(%0.1f � %0.1f)\r", tmptxt6, V_avg, V_sdev
	
	ch1txt1 = "\r\t\\Z14\\f01Channel 1\\f00\\Z12\r"
	wavestats/Q/R=(first, last) tempECD1
	sprintf ch1txt1, "%s\tECD Temperature (oC):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch1txt1, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) tempECD1
	sprintf ch1txt1, "%s\t\t\t(%0.1f � %0.1f)\r", ch1txt1, V_avg, V_sdev
	wavestats/Q/R=(first, last) tempCOL1
	sprintf ch1txt1, "%s\tColumn Temperature (oC):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch1txt1, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) tempCOL1
	sprintf ch1txt1, "%s\t\t\t(%0.1f � %0.1f)\r", ch1txt1, V_avg, V_sdev
	ch1txt2=""
	wavestats/Q/R=(first, last) AP_ECD1_PRES
	sprintf ch1txt2, "%s\tECD Pressure (mbar):\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch1txt2, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) AP_ECD1_PRES
	sprintf ch1txt2, "%s\t\t\t(%0.1f � %0.1f)\r", ch1txt2, V_avg, V_sdev
	wavestats/Q/R=(first, last) AD_ECD1_DRIVE
	sprintf ch1txt2, "%s\tECD Drive:\t\t\t%0.2f,  (%0.2f � %0.2f),  %0.2f", ch1txt2, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) AD_ECD1_DRIVE
	sprintf ch1txt2, "%s\t\t\t(%0.2f � %0.2f)\r", ch1txt2, V_avg, V_sdev
	ch1txt3=""
	wavestats/Q/R=(first, last) AF_CAR1_FLOW
	sprintf ch1txt3, "%s\tMain Flow (sccm):\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch1txt3, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) AF_CAR1_FLOW
	sprintf ch1txt3, "%s\t\t\t(%0.1f � %0.1f)\r", ch1txt3, V_avg, V_sdev
	wavestats/Q/R=(first, last) AF_BACK1_FLOW
	sprintf ch1txt3, "%s\tBackflush Flow (sccm):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch1txt3, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) AF_BACK1_FLOW
	sprintf ch1txt3, "%s\t\t\t(%0.1f � %0.1f)\r", ch1txt3, V_avg, V_sdev
	
	ch2txt1 = "\r\t\\Z14\\f01Channel 2\\f00\\Z12\r"
	wavestats/Q/R=(first, last) tempECD2
	sprintf ch2txt1, "%s\tECD Temperature (oC):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch2txt1, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) tempECD2
	sprintf ch2txt1, "%s\t\t\t(%0.1f � %0.1f)\r", ch2txt1, V_avg, V_sdev
	wavestats/Q/R=(first, last) tempCOL2
	sprintf ch2txt1, "%s\tColumn Temperature (oC):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch2txt1, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) tempCOL2
	sprintf ch2txt1, "%s\t\t\t(%0.1f � %0.1f)\r", ch2txt1, V_avg, V_sdev
	ch2txt2=""
	wavestats/Q/R=(first, last) AP_ECD2_PRES
	sprintf ch2txt2, "%s\tECD Pressure (mbar):\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch2txt2, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) AP_ECD2_PRES
	sprintf ch2txt2, "%s\t\t\t(%0.1f � %0.1f)\r", ch2txt2, V_avg, V_sdev
	wavestats/Q/R=(first, last) AD_ECD2_DRIVE
	sprintf ch2txt2, "%s\tECD Drive:\t\t\t%0.2f,  (%0.2f � %0.2f),  %0.2f", ch2txt2, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) AD_ECD2_DRIVE
	sprintf ch2txt2, "%s\t\t\t(%0.2f � %0.2f)\r", ch2txt2, V_avg, V_sdev
	ch2txt3=""
	wavestats/Q/R=(first, last) AF_CAR2_FLOW
	sprintf ch2txt3, "%s\tMain Flow (sccm):\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch2txt3, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) AF_CAR2_FLOW
	sprintf ch2txt3, "%s\t\t\t(%0.1f � %0.1f)\r", ch2txt3, V_avg, V_sdev
	wavestats/Q/R=(first, last) AF_BACK2_FLOW
	sprintf ch2txt3, "%s\tBackflush Flow (sccm):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch2txt3, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) AF_BACK2_FLOW
	sprintf ch2txt3, "%s\t\t\t(%0.1f � %0.1f)\r", ch2txt3, V_avg, V_sdev
	
	ch3txt1 = "\r\t\\Z14\\f01Channel 3\\f00\\Z12\r"
	wavestats/Q/R=(first, last) tempECD3
	sprintf ch3txt1, "%s\tECD Temperature (oC):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch3txt1, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) tempECD3
	sprintf ch3txt1, "%s\t\t\t(%0.1f � %0.1f)\r", ch3txt1, V_avg, V_sdev
	wavestats/Q/R=(first, last) tempCOL3
	sprintf ch3txt1, "%s\tColumn Temperature (oC):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch3txt1, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) tempCOL3
	sprintf ch3txt1, "%s\t\t\t(%0.1f � %0.1f)\r", ch3txt1, V_avg, V_sdev
	ch3txt2=""
	wavestats/Q/R=(first, last) BP_ECD3_PRES
	sprintf ch3txt2, "%s\tECD Pressure (mbar):\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch3txt2, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) BP_ECD3_PRES
	sprintf ch3txt2, "%s\t\t\t(%0.1f � %0.1f)\r", ch3txt2, V_avg, V_sdev
	wavestats/Q/R=(first, last) BD_ECD3_DRIVE
	sprintf ch3txt2, "%s\tECD Drive:\t\t\t%0.2f,  (%0.2f � %0.2f),  %0.2f", ch3txt2, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) BD_ECD3_DRIVE
	sprintf ch3txt2, "%s\t\t\t(%0.2f � %0.2f)\r", ch3txt2, V_avg, V_sdev
	ch3txt3=""
	wavestats/Q/R=(first, last) BF_CAR3_FLOW
	sprintf ch3txt3, "%s\tMain Flow (sccm):\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch3txt3, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) BF_CAR3_FLOW
	sprintf ch3txt3, "%s\t\t\t(%0.1f � %0.1f)\r", ch3txt3, V_avg, V_sdev
	wavestats/Q/R=(first, last) BF_BACK3_FLOW
	sprintf ch3txt3, "%s\tBackflush Flow (sccm):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch3txt3, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) BF_BACK3_FLOW
	sprintf ch3txt3, "%s\t\t\t(%0.1f � %0.1f)\r", ch3txt3, V_avg, V_sdev
	
	ch4txt1 = "\r\t\\Z14\\f01Channel 4\\f00\\Z12\r"
	wavestats/Q/R=(first, last) tempECD4
	sprintf ch4txt1, "%s\tECD Temperature (oC):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch4txt1, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) tempECD4
	sprintf ch4txt1, "%s\t\t\t(%0.1f � %0.1f)\r", ch4txt1, V_avg, V_sdev
	wavestats/Q/R=(first, last) tempCOL4
	sprintf ch4txt1, "%s\tColumn Temperature (oC):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch4txt1, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) tempCOL4
	sprintf ch4txt1, "%s\t\t\t(%0.1f � %0.1f)\r", ch4txt1, V_avg, V_sdev
	ch4txt2=""
	wavestats/Q/R=(first, last) BP_ECD4_PRES
	sprintf ch4txt2, "%s\tECD Pressure (mbar):\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch4txt2, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) BP_ECD4_PRES
	sprintf ch4txt2, "%s\t\t\t(%0.1f � %0.1f)\r", ch4txt2, V_avg, V_sdev
	wavestats/Q/R=(first, last) BD_ECD4_DRIVE
	sprintf ch4txt2, "%s\tECD Drive:\t\t\t%0.2f,  (%0.2f � %0.2f),  %0.2f", ch4txt2, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) BD_ECD4_DRIVE
	sprintf ch4txt2, "%s\t\t\t(%0.2f � %0.2f)\r", ch4txt2, V_avg, V_sdev
	ch4txt3=""
	wavestats/Q/R=(first, last) BF_CAR4_FLOW
	sprintf ch4txt3, "%s\tMain Flow (sccm):\t\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch4txt3, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) BF_CAR4_FLOW
	sprintf ch4txt3, "%s\t\t\t(%0.1f � %0.1f)\r", ch4txt3, V_avg, V_sdev
	wavestats/Q/R=(first, last) BF_BACK4_FLOW
	sprintf ch4txt3, "%s\tBackflush Flow (sccm):\t%0.1f,  (%0.1f � %0.1f),  %0.1f", ch4txt3, V_min, V_avg, V_sdev, V_max
	wavestats /Q/R=(asc, dsc) BF_BACK4_FLOW
	sprintf ch4txt3, "%s\t\t\t(%0.1f � %0.1f)\r", ch4txt3, V_avg, V_sdev
	
	LevelFlightPlot(asc, dsc, XP_EXT_PRES)
	
	doWindow /K ACATSstats1
	execute "layout /T/C=1/A=(1,1)/W=(80,40,460,490)"
	doWindow /C ACATSstats1
	txt1    = title+flttxt+cyltxt1+cyltxt2+cyltxt3+pumptxt+comptxt+powertxt1+powertxt2
	txt1 += tmptxt1+tmptxt2+tmptxt3+tmptxt4+tmptxt5+tmptxt6+tmptxt7
	Textbox/N=Stats/F=0/A=MC/X=-0.36/Y=5.37 txt1
	Textbox/N=PageNum/F=0/A=LB/X=95.09/Y=1.10 "\\Z16\\f01\\F'Times'"+num2str(page)

	doWindow /K ACATSstats2
	execute "layout /T/C=1/A=(1,1)/W=(80,40,460,490)"
	doWindow /C ACATSstats2
	txt2  = title
	txt2 += ch1txt1+ch1txt2+ch1txt3
	txt2 += ch2txt1+ch2txt2+ch2txt3
	txt2 += ch3txt1+ch3txt2+ch3txt3
	txt2 += ch4txt1+ch4txt2+ch4txt3
	Textbox/N=Stats/F=0/A=MC/X=-2.73/Y=12.26 txt2		
	Textbox/N=PageNum/F=0/A=LB/X=95.09/Y=1.10 "\\Z16\\f01\\F'Times'"+num2str(page+1)
	execute "AppendToLayout Press_levelFlight(74,556,559,736)/O=1/F=0"

	if (doPrint)
		execute "printLayout ACATSstats1"
		execute "printLayout ACATSstats2"
	endif

	return page+2

end

#pragma rtGlobals= 1
function LevelFlightPlot(asc, dsc, press)
	variable asc, dsc
	wave press
	
	variable ticWidth=100
	
	make /o/n=2 pres_tic_ascX, pres_tic_ascY, pres_tic_dscX, pres_tic_dscY
	pres_tic_ascX=asc
	pres_tic_dscX=dsc
	pres_tic_ascY[0]=press(asc)+ticWidth; pres_tic_ascY[1]=press(asc)-ticWidth
	pres_tic_dscY[0]=press(dsc)+ticWidth; pres_tic_dscY[1]=press(dsc)-ticWidth

	Display /W=(6,291,425,424) XP_EXT_PRES
	AppendtoGraph pres_tic_ascY vs pres_tic_ascX
	AppendtoGraph pres_tic_dscY vs pres_tic_dscX
	ModifyGraph gFont="Times"
	ModifyGraph marker=19
	ModifyGraph lSize(pres_tic_ascY)=2,lSize(pres_tic_dscY)=2
	ModifyGraph rgb(pres_tic_ascY)=(3,52428,1),rgb(pres_tic_dscY)=(3,52428,1)
	ModifyGraph msize=2
	ModifyGraph grid=2
	ModifyGraph mirror=2
	ModifyGraph axOffset(left)=1.2,axOffset(bottom)=1
	Label left "\\Z14External Pressure (mbar)"
	Label bottom "\\Z14Time (kGMT)"
	Tag/N=asc/F=0/S=3/X=5.57/Y=36.71 pres_tic_ascY, 0, "\\JC\\Z12End of\rascent"
	Tag/N=dsc/F=0/S=3/X=-6.55/Y=40.51 pres_tic_dscY, 0, "\\Z12\\JCBeginning\rof descent"
	
	DoWindow/K Press_levelFlight
	DoWindow/C Press_levelFlight

end

function computeRangeHeight (wvlst,rngXmin,rngXmax)
	String wvlst
	Variable rngXmin,rngXmax
	|
	String next,com,list=wvlst
	Variable ch2,rngHght
	NVAR rng = G_rangeHeight
	print "All chromatograms to be plotted with same y-axis height.  Calculating that height now."

	rng = -1e+10
	do
		ch2 =  StrSearch (list, ";", 0)-1
		next = list[0,ch2]
		list=list[ch2+2,strlen(list)]
		if (strlen(next) < 1)
			break
		endif
		|
		rngHght = getRngHghtOneWave ($next,rngXmin,rngXmax)
		if (rngHght > rng)
			rng = rngHght
		endif				
	while (1)
	print "Y-axis height = ", rng
end

| computes G_ymax and G_ymin in interval between xmin to xmax, returns ymax-ymin. 
function getRngHghtOneWave (wv,xmin,xmax)
	Wave wv
	Variable xmin,xmax
	|
	Variable p1,p2,tmp
	NVAR ymin=G_ymin, ymax=G_ymax
	|
	p1= x2pnt (wv,xmin)
	p2= x2pnt (wv,xmax)
	if (p1 > p2)
		tmp=p1
		p1=p2
		p2=tmp
	endif
	if (p1 == p2)
		ymin=wv[p1]
		ymax=wv[p1]
		return 0
	endif
	|
	if (p1 < 0)
		p1 = 0
	endif
	if (p2>=numpnts(wv))
		p2=numpnts(wv) - 1
	endif
	|		
	ymin=999999999
	ymax=-999999999
	do
		if (wv[p1]>ymax)
			ymax=wv[p1]
		endif
		if (wv[p1]<ymin)
			ymin=wv[p1]
		endif
		p1+=1
	while (p1 <= p2)
	return (ymax-ymin)
end
	
| This function plays with lots of global variables.  G_rangeHeight==max hght in autorange interval over all
| plots. G_ymin and G_ymax are both set by getRngHghtONeWave, and re-set by this proc.
function autoGetYrange (wv,rngXmin,rngXmax)
	String	wv
	Variable rngXmin,rngXmax
	NVAR rng = G_rangeHeight, ymin = G_ymin, ymax = G_ymax
	|
	Variable margin = rng * 8/100, tmp
	|
	tmp = getRngHghtOneWave ($wv,rngXmin,rngXmax)	
	ymax=ymin+rng+margin
	ymin=ymin-margin
end

function autoSetHorizAxis (which,wv1,wv2,wv3,wv4,wv5,wv6,wv7,wv8)
	String which,wv1,wv2,wv3,wv4,wv5,wv6,wv7,wv8
	|
	Variable	min_=99999999, max_=-999999999,hght,border=15
	if (StrLen (wv1) > 0)
		WaveStats /Q/R=[10,numpnts($wv1)-11] $wv1;min_=min(V_min,min_);max_=max(V_max,max_)
	endif
	if (StrLen (wv2) > 0)
		WaveStats /Q/R=[10,numpnts($wv2)-11] $wv2;min_=min(V_min,min_);max_=max(V_max,max_)
	endif
	if (StrLen (wv3) > 0)
		WaveStats /Q/R=[10,numpnts($wv3)-11] $wv3;min_=min(V_min,min_);max_=max(V_max,max_)
	endif
	if (StrLen (wv4) > 0)
		WaveStats /Q/R=[10,numpnts($wv4)-11] $wv4;min_=min(V_min,min_);max_=max(V_max,max_)
	endif
	if (StrLen (wv5) > 0)
		WaveStats /Q/R=[10,numpnts($wv5)-11] $wv5;min_=min(V_min,min_);max_=max(V_max,max_)
	endif
	if (StrLen (wv6) > 0)
		WaveStats /Q/R=[10,numpnts($wv6)-11] $wv6;min_=min(V_min,min_);max_=max(V_max,max_)
	endif
	if (StrLen (wv7) > 0)
		WaveStats /Q/R=[10,numpnts($wv7)-11] $wv7;min_=min(V_min,min_);max_=max(V_max,max_)
	endif
	if (StrLen (wv8) > 0)
		WaveStats /Q/R=[10,numpnts($wv8)-11] $wv8;min_=min(V_min,min_);max_=max(V_max,max_)
	endif
	|
	hght=max_ - min_
	if (CmpStr (which, "right")==0)
		SetAxis right min_-hght*border/100, max_+hght*border/100
	else
		SetAxis left min_-hght*border/100, max_+hght*border/100
	endif		
end

function AveMinOfBins (wv, nBins)
	wave wv
	variable nBins
	|
	Variable binMin,pnt=0,tot=0,cnt=0,binWidth=numpnts(wv)/nBins,binEnd=binWidth
	do
		binMin=99999999
		do
			binMin=min(binMin,wv[pnt])
			pnt+=1
		while (pnt <= binEnd)
		tot+=binMin
		cnt+=1
		binEnd=min(binEnd+binWidth,numpnts(wv)-1)
	while (cnt<nBins)
	return tot/cnt
end			
	


| Plots some or all of the loaded chromatograms.  User can only select a subset, however, based on 
|  a prefix to the wave names. Plots four per page.
Macro FourPlotWaves (prefix,layouttitle,plotTime,autoscale,xmin,xmax,subXmin,subXmax,pntsPerSec)
       String	prefix = G_prefix
	Variable pntsPerSec=G_pntsPerSec
	String layouttitle = G_layouttitle
	String plotTime = G_plotTime
	Variable autoscale=G_autoscale,xmin=G_xmin,xmax=G_xmax,subXmin=G_subXmin,subXmax=G_subXmax
	|
	Prompt prefix, "Prefix of the waves to plot"
	Prompt pntsPerSec,"No. points per sec these chromatograms"
	Prompt plotTime, "Approx time to allow per plot ?",popup "00:00:01;00:00:10;00:00:20;00:00:30;00:00:45;00:01:00;00:02:00"
	Prompt layouttitle, "Page Title"
	Prompt autoscale, "Autoscaling--Each Entire Plot?", popup "ON--All data points for each chrom. will be included;"
	"OFF--Define x-min | max, Auto y-rng in interval"
	Prompt xmin, "X-axis plot min (When autoscaling off)"
	Prompt xmax, "X-axis plot max (When autoscaling off)"
	Prompt subXmin, "Left X for auto Y-ranging"
	Prompt subXmax, "Right X for auto Y-ranging"
	PauseUpdate; Silent 1
	|
	G_prefix=prefix;G_layouttitle=layouttitle;G_plotTime=plotTime;G_autoscale=autoscale
	G_subXmin=subXmin;G_subXmax=subXmax;G_xmin=xmin;G_xmax=xmax
	G_pntsPerSec=pntsPerSec
	|
	autoscale=(autoscale==1)
	|
	Layout /W=(101,50,574,426)  as "Test Orientation"
	DoAlert 1,"Is the page in this layout horizontal? If not, you MUST click on the NO button."
	if (V_flag != 1) then
	       TextBox  /N=TextBox_0/A=LT/X=1.27273/Y=3.70879  "\Z24DO THE FOLLOWING NOW:\r"
		AppendText "\Z18	1) click on FILE/PAGE SETUP"
		AppendText "\Z18	2) reset the page orientation to horizontal "
		AppendText "\Z18		(the torso in the picture is sideways)"
		AppendText "\Z18	3) Click on OK to save horizontal layout."
		AppendText "\Z18	4) Kill this layout window and do not save it."
		AppendText "\Z18	5) Re-run FourPlotWaves from the start."
		Modify width(TextBox_0)=538,height(TextBox_0)=300
		beep; abort
	endif  
	DoWindow /k $(WinName (0,4)) 
	|
	String w1,w2,w3,w4,g1,g2,g3,g4,laywin, wvname, wvlst=WaveList (prefix+"*", ";", "")
	if (strlen (wvlst) == 0) then
		DoAlert 0, "No waves loaded with prefix "+prefix+".  You may want to run LoadBWaves"
		return
	endif
	|
	computeRangeHeight (wvlst,subXmin,subXmax)
	|
	Variable ch1 = 0, ch2,ngraph
	Make /o/n=128 b1,b2,b3,b4
	|
 	display b1
	Modify grid=1,mirror=2			|	, manTick(left)={0,20000,0,0}
	Label left, "Response (hz)"; Label bottom, "Retention Time (secs)"
	w1 = WinName (0,1)
	|
 	display b2
	Modify grid=1,mirror=2
	Label left, "Response (hz)"; Label bottom, "Retention Time (secs)"
	w2 = WinName (0,1)
	|
 	display b3
	Modify grid=1,mirror=2
	Label left, "Response (hz)"; Label bottom, "Retention Time (secs)"
	w3 = WinName (0,1)
	|
 	display b4
	Modify grid=1,mirror=2
	Label left, "Response (hz)"; Label bottom, "Retention Time (secs)"
	w4 = WinName (0,1)
	|
	TileWindows /C $w1,$w2,$w3,$w4
	|
	do
		ngraph=1
		do
			PauseUpdate
			ch2 = StrSearch (wvlst, ";", ch1) - 1
			wvname = wvlst[ch1, ch2]
|			SetScale /P x,0,(1/PntsPerSec),"",$wvname
			|
			if (ngraph == 1) then
				duplicate /o $wvname,b1
				DoWindow /F $w1
				if (! autoscale) then 
					autoGetYrange ("b1",subXmin,subXmax)
					SetAxis left,G_ymin,G_ymax; SetAxis bottom,xmin,xmax
				endif
				Textbox /C/N=plotleg/A=LC/X=3/Y=50  wvname
			endif
			if (ngraph == 2) then
				duplicate /o $wvname,b2
				DoWindow /F $w2
				if (! autoscale) then 
					autoGetYrange ("b2",subXmin,subXmax)
					SetAxis left,G_ymin,G_ymax; SetAxis bottom,xmin,xmax
				endif
				Textbox /C/N=plotleg/A=LC/X=3/Y=50  wvname
			endif
			if (ngraph == 3) then
				duplicate /o $wvname,b3
				DoWindow /F $w3
				if (! autoscale) then 
					autoGetYrange ("b3",subXmin,subXmax)
					SetAxis left,G_ymin,G_ymax; SetAxis bottom,xmin,xmax
				endif
				Textbox /C/N=plotleg/A=LC/X=3/Y=50  wvname
			endif
			if (ngraph == 4) then
				duplicate /o $wvname,b4
				DoWindow /F $w4
				if (! autoscale) then 
					autoGetYrange ("b4",subXmin,subXmax)
					SetAxis left,G_ymin,G_ymax; SetAxis bottom,xmin,xmax
				endif
				Textbox /C/N=plotleg/A=LC/X=3/Y=50  wvname
			endif
			ResumeUpdate
			ch1 = ch2+2
			ngraph+=1
		while ((ch1 < strlen (wvlst))*(ngraph <= 4))	
		|
		g1=w1+"(33,80,393,320)/O=1/F=0"
		g2=w2+"(400,80,760,320)/O=1/F=0"
		g3=w3+"(33,330,393,570)/O=1/F=0"
		g4=w4+"(400,330,760,570)/O=1/F=0"	
		|
		Layout /W=(101,50,574,426)  $g1,$g2,$g3,$g4  as "plotlayout"
		Textbox /N=TextBox_0/F=0/A=MC/X=0/Y=43.2727
		AppendText "\Z16"+layouttitle
		laywin = WinName (0,4)
 		PrintLayout $laywin
		Sleep /Q $plotTime
		DoWindow /k $laywin
		|
		b1=0;DoWindow /F $w1;Textbox /C/N=plotleg "                                       "
		b2=0;DoWindow /F $w2;Textbox /C/N=plotleg "                                       "
		b3=0;DoWindow /F $w3;Textbox /C/N=plotleg "                                       "		
		b4=0;DoWindow /F $w4;Textbox /C/N=plotleg "                                       "
	while (ch1 < strlen (wvlst))
	|
	DoWindow /k $w1;DoWindow /k $w2;DoWindow /k $w3;DoWindow /k $w4
End

