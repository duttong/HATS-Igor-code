#pragma rtGlobals=1		// Use modern global access method.

#include "macros-utilities"
#include "macros-geoff"


menu "macros"
	"Load Engineering Data /1"
	"MakePlots /2"
	"Save Plots /3"
	"Stat Page /4"
	"-"
	"Remove Displayed Graphs"
end
	

Proc LoadEngineeringData(YYYY, station)
	variable YYYY=NumMakeOrDefault("root:G_YYYY", str2num(GetStrFromList(date(), 2, ",")))
	string station=StrMakeOrDefault("root:G_site3", "brw")
	prompt YYYY, "The year the data was taken"
	prompt station, "Station", popup "brw;nwr;mlo;smo;spo"
	
	silent 1; pauseupdate
	
	
	Pathinfo engdatapath
	if (V_Flag == 0 )
		NewPath/M="Path to engineering data" engdatapath
	endif
	
	G_YYYY = YYYY
	G_site3 = station

	setStation( G_site3 )

	GenerateDayWv("Main1", "", YYYY)
	
	// Load data
	LoadAndRename("Main1")
	LoadAndRename("Main2")
	LoadAndRename("Main3")
	LoadAndRename("BF1")
	LoadAndRename("BF2")
	LoadAndRename("BF3")
	LoadAndRename("COL1")
	LoadAndRename("COL2")
	LoadAndRename("COL3")
	LoadAndRename("COL4")
	LoadAndRename("ECD1")
	LoadAndRename("ECD2")
	LoadAndRename("ECD3")
	LoadAndRename("ECD4")
	LoadAndRename("Trap")
	LoadAndRename("External")
	
	GenerateDayWv("Flow_a1", "_a1", YYYY)
	LoadAndRename("Flow_a1")
	GenerateDayWv("Flow_c1", "_c1", YYYY)
	LoadAndRename("Flow_c1")
	GenerateDayWv("Flow_a2", "_a2", YYYY)
	LoadAndRename("Flow_a2")
	GenerateDayWv("Flow_c2", "_c2", YYYY)
	LoadAndRename("Flow_c2")
	
	bat("killwaves @", "wave*")
	
end

function setStation( site )
	string site
	
	if (exists("G_station") != 2)
		string /g G_station
	endif
	
	if ( cmpstr(site,"brw") == 0 )
		G_station = "Barrow, Alaska"
	elseif ( cmpstr(site,"nwr") == 0 )
		G_station = "Niwot Ridge, Colorado"
	elseif ( cmpstr(site,"mlo") == 0 )
		G_station = "Mauna Loa, Hawaii"
	elseif ( cmpstr(site,"smo") == 0 )
		G_station = "American Samoa"
	elseif ( cmpstr(site,"spo") == 0 )
		G_station = "South Pole"
	endif
	
end

function GenerateDayWv(loadfile, extension, YYYY)
	string loadfile, extension
	variable YYYY
	
	string fileStr = "file" + extension
	string gmtStr = "gmt" + extension
	string dayStr = "day" + extension

	SVAR G_site3 = G_site3
	loadfile = G_site3+num2str(YYYY)+"_"+loadfile
	
	// Load file name and time used to calculate date.  This data is the same in each
	// engineering file.  Load only once.
	killwaves/Z wave0, wave1, wave2, wave3, $fileStr
	LoadWave/J/D/O/K=2/V={"\t, "," $",0,0}/L={0,0,0,0,1}/A /P=engdatapath loadfile
	duplicate/o wave0 $fileStr
	killwaves/Z wave0, wave1, wave2, wave3
	LoadWave/J/D/O/K=0/V={"\t, "," $",0,0}/L={0,0,0,1,1}/A /P=engdatapath loadfile
	duplicate/o wave0 $gmtStr
	killwaves/Z wave0, wave1, wave2, wave3
	duplicate/o $gmtStr $dayStr
	
	string filenmstr
	variable inc=0, day, hh
	wave dayWv = $dayStr
	wave /t fileWv = $fileStr
	wave gmtWv = $gmtStr
	do
		filenmstr = fileWv[inc]
		day = str2num(filenmstr[7,9])
		hh = str2num(filenmstr[10,11])
		if ( (hh <= 2) * (gmtWv[inc] > (22*60*60)) )
			dayWv[inc] = date2secs(YYYY,1,0)+(day - 1)*86400 + gmtWv[inc]
		else
			dayWv[inc] = date2secs(YYYY,1,0)+day*86400 + gmtWv[inc]
		endif
		inc += 1
	while (inc <= numpnts(fileWv))
	
end	

function LoadAndRename(type)
	string type

	NVAR YYYY=G_YYYY
	SVAR SITE=G_site3
	string file = SITE+num2str(YYYY)+"_"+type
	
	killwaves/Z wave0
	LoadWave/J/O/K=0/V={"\t, "," $",0,0}/L={0,0,0,2,1}/A /P=engdatapath file
	duplicate /o wave0 $type

	// Handles the 999.9 error.
	HighChop($type, 999)	

end	

Proc MakePlots()

	silent 1; pauseupdate
	
	wavestats /q ECD1
	MakePlot(day, ECD1, round(V_avg)-1, round(V_avg)+1, "Date", "ECD 1 (C)", "detector1")
	wavestats /q ECD2
	MakePlot(day, ECD2, round(V_avg)-1, round(V_avg)+1, "Date", "ECD 2 (C)", "detector2")
	wavestats /q ECD3
	MakePlot(day, ECD3, round(V_avg)-1, round(V_avg)+1, "Date", "ECD 3 (C)", "detector3")
	wavestats /q ECD4
	MakePlot(day, ECD4, round(V_avg)-1, round(V_avg)+1, "Date", "ECD 4 (C)", "detector4")

	wavestats /q COL1
	MakePlot(day, COL1, round(V_avg)-1, round(V_avg)+1, "Date", "Column 1 Temp (C)", "column1")
	wavestats /q COL2
	MakePlot(day, COL2, round(V_avg)-1, round(V_avg)+1, "Date", "Column 2 Temp (C)", "column2")
	wavestats /q COL3
	MakePlot(day, COL3, round(V_avg)-1, round(V_avg)+1, "Date", "Column 3 Temp (C)", "column3")
	wavestats /q COL4
	MakePlot(day, COL4, round(V_avg)-1, round(V_avg)+1, "Date", "Column 4 Temp (C)", "column4")
	
	MakePlot(day, Trap, -100, 0, "Date", "Minimum Trap Temp (C)", "trap_temp")
	MakePlot(day, External, 20, 35, "Date", "External to the GC temp (C)", "external_temp")

	Make2Plot(day, Main1, BF1, 20, 60, "Date", "Channel 1 Flows (sccm)", "flows1")
	Make2Plot(day, Main2, BF2, 20, 60, "Date", "Channel 2 Flows (sccm)", "flows2")
	Make2Plot(day, Main3, BF3, 20, 60, "Date", "Channel 3 Flows (sccm)", "flows3")
	
	MakeSampleFlowPlot("Date", "Sample Loop Flows (sccm)", "sample_flow")
	
end

function MakePlot(xwv, ywv, ymin, ymax, xlable, ylable, plotnm)
	wave xwv, ywv
	variable ymin, ymax
	string xlable, ylable, plotnm
	
	SVAR stationstr = G_station
	NVAR G_YYYY = G_YYYY
	
	// Make bold lables
	xlable = "\\f01" + xlable
	ylable = "\\f01" + ylable
	
	DoWindow/K $plotnm
	display ywv vs xwv
	DoWindow/C/T $plotnm, plotnm
	
	ModifyGraph gFont="Geneva",gfSize=14,width=600,height=400,wbRGB=(49151,60031,65535)
	ModifyGraph grid=1,mirror=2	
	ModifyGraph dateInfo(bottom)={0,0,0}
	SetAxis left ymin, ymax
	SetAxis bottom date2secs(G_yyyy,1,1),date2secs(G_yyyy+1,1,1) 
	Label left ylable
	Label bottom xlable
	Textbox/N=text0_1/F=0/A=MC/X=-38.50/Y=44.50 stationstr
	
end

function Make2Plot(xwv, y1wv, y2wv, ymin, ymax, xlable, ylable, plotnm)
	wave xwv, y1wv, y2wv
	variable ymin, ymax
	string xlable, ylable, plotnm
	
	SVAR stationstr = G_station
	NVAR G_YYYY = G_YYYY
	
	// Make bold lables
	xlable = "\\f01" + xlable
	ylable = "\\f01" + ylable
	
	string com

	DoWindow/K $plotnm
	display y1wv y2wv vs xwv
	DoWindow/C/T $plotnm, plotnm
	
	ModifyGraph gFont="Geneva",gfSize=14,width=600,height=400,wbRGB=(49151,60031,65535)
	ModifyGraph grid=1,mirror=2	
	ModifyGraph dateInfo(bottom)={0,0,0}
	sprintf com, "ModifyGraph rgb(%s)=(1,12815,52428)", nameofwave(y2wv)
	execute com
	SetAxis left ymin, ymax
	SetAxis bottom date2secs(G_yyyy,1,1),date2secs(G_yyyy+1,1,1) 
	Label left ylable
	Label bottom xlable
	Textbox/N=text0_1/F=0/A=MC/X=-38.50/Y=44.50 stationstr
	legend
	
end

function MakeSampleFlowPlot(xlable, ylable, plotnm)
	string xlable, ylable, plotnm
	
	SVAR stationstr = G_station
	NVAR G_YYYY = G_YYYY

	wave c1 = Flow_c1
	wave a1 = Flow_a1
	wave c2 = Flow_c2
	wave a2 = Flow_a2
	wave c1d = day_c1
	wave a1d = day_a1
	wave c2d = day_c2
	wave a2d = day_a2
	
	// Make bold lables
	xlable = "\\f01" + xlable
	ylable = "\\f01" + ylable
	
	string com

	DoWindow/K $plotnm
	
	display c1 vs c1d
	appendtograph a1 vs a1d
	appendtograph c2 vs c2d
	appendtograph a2 vs a2d
	
	DoWindow/C/T $plotnm, plotnm
	
	ModifyGraph gFont="Geneva",gfSize=14,width=600,height=400,wbRGB=(49151,60031,65535)
	ModifyGraph grid=1,mirror=2	
	ModifyGraph dateInfo(bottom)={0,0,0}
	SetAxis/A/N=1/E=1 left
	SetAxis bottom date2secs(G_yyyy,1,1),date2secs(G_yyyy+1,1,1) 
	ModifyGraph mode=3,msize=2,marker(Flow_c1)=8,rgb(Flow_c1)=(1,12815,52428);DelayUpdate
	ModifyGraph marker(Flow_c2)=5,rgb(Flow_c2)=(1,12815,52428),marker(Flow_a2)=1
	Label left ylable
	Label bottom xlable
	Textbox/N=text0_1/F=0/A=MC/X=-38.50/Y=44.50 stationstr
	legend
	
end


Proc SavePlots()

	silent 1; pauseupdate
	
	Pathinfo savepath
	if (V_flag == 0 )
		NewPath/O/M="Path to save plots." savepath
	endif
	
	string plots = "detector1;detector2;detector3;detector4;column1;column2;column3;column4;trap_temp;external_temp;flows1;flows2;flows3;sample_flow;"
	
	lbat("DoWindow /F @;SavePICT/O/P=savepath/E=-5/B=72 as \"@.png\"", plots)
	
end

Proc StatPage(startday, endday)
	string startday = StrMakeOrDefault("root:G_startday", "0101")
	string endday = StrMakeOrDefault("root:G_endday", "0201")
	prompt startday, "Starting day (MMDD)"
	prompt endday, "Ending day (MMDD)"
	
	silent 1
	G_startday = startday
	G_endday = endday
	variable MMs = str2num(startday[0,1])
	variable DDs = str2num(startday[2,3])
	variable MMe = str2num(endday[0,1])
	variable DDe = str2num(endday[2,3])
	
	StatPageFUNCT(date2secs(G_YYYY, MMs, DDs), date2secs(G_YYYY, MMe, DDe))
	
end

function StatPageFUNCT(strsec, endsec)
	variable  strsec, endsec

	wave day = $"day"
	variable startP = 0, endP = numpnts(day)-1
	string win = "MeanData"
	SVAR station = G_station

	if (exists("S_noteStr") != 2)
		string /g S_noteStr
	endif

	// Starting point for stats
	findlevel  /Q/P day, strsec
	if (V_flag == 0)
		startP = V_levelX
	endif
		
	// Ending point for stats
	findlevel /Q/P day, endsec
	if (V_flag == 0)
		endP = V_levelX
	endif

	DoWindow /K $win
	NewNotebook /f=0/N=$win
	Notebook $win, fsize = 10, fstyle = 0, text = station + " Engineering Mean Data\r"
	Notebook $win, text = "Period: " + Secs2Date(strsec, 0) + " to " + Secs2Date(endsec, 0) + "\r\r"
	
	StatsOnWave(ECD1, startP, endP)
	StatsOnWave(ECD2, startP, endP)
	StatsOnWave(ECD3, startP, endP)
	StatsOnWave(ECD4, startP, endP)
	StatsOnWave(COL1, startP, endP)
	StatsOnWave(COL2, startP, endP)
	StatsOnWave(COL3, startP, endP)
	StatsOnWave(COL4, startP, endP)
	StatsOnWave(Main1, startP, endP)
	StatsOnWave(Main2, startP, endP)
	StatsOnWave(Main3, startP, endP)
	StatsOnWave(BF1, startP, endP)
	StatsOnWave(BF2, startP, endP)
	StatsOnWave(BF3, startP, endP)
	StatsOnWave(External, startP, endP)
	StatsOnWave(Trap, startP, endP)
	
end

function  StatsOnWave(wv, p1, p2)
	wave wv
	variable p1, p2

	string win = "MeanData"
	SVAR S_noteStr = S_noteStr
	
	wavestats  /Q/R=[p1, p2] wv
	sprintf S_noteStr, "%10s average = %5.2f ± %4.2f\r", NameOfWave(wv), V_avg, V_sdev

	Notebook $win, text = S_noteStr
	
end