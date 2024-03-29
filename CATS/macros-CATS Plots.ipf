#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=1		// Use modern global access method.

Proc MoleResultPlot(mol, attrib, suffix)
	string mol = StrMakeOrDefault("root:G_mol", "")
	string attrib = StrMakeOrDefault("root:G_attribInt", "hght")
	string suffix = StrMakeOrDefault("root:G_suffixPt", "ALL")
	prompt mol, "Molecule", popup, G_loadMol
	prompt attrib, "Display concentration or response", popup, "hght;area;ret;injTemp;injPress"
	prompt suffix, "Plot with data?", popup, G_suffix +";ALL"

	silent 1; pauseupdate
	
	G_mol = mol
	G_attribInt = attrib
	G_suffixPt = suffix

	silent 1; pauseupdate
	string XX, YY, ZZ, title
	variable inc
	
	if (NumElementsInList(G_suffix, ";") == 1) 
		suffix = GetStrFromList(G_suffix, inc, ";")
	endif
	
	if (cmpstr(suffix, "ALL") == 0)
		suffix = GetStrFromList(G_suffix, inc, ";")
		XX = mol + "_" + suffix + "_date"
		YY = mol + "_" + suffix + "_" + attrib
		ZZ = mol + "_" + suffix + "_selpos"

		DoWindow /K $mol+"_"+attrib+"_ALL"
		title = mol + " " + attrib + " ALL"
		Display /W=(28,69,570,403) $YY vs $XX as title
		ModifyGraph textMarker($YY)={$ZZ,"default",0,0,5,0.00,0.00}
		DoWindow /C $mol+"_"+attrib+"_ALL"
	
		inc += 1
		do
			suffix = GetStrFromList(G_suffix, inc, ";")
			XX = mol + "_" + suffix + "_date"
			YY = mol + "_" + suffix + "_" + attrib
			ZZ = mol + "_" + suffix + "_selpos"
			print XX, YY, ZZ
			if ((exists(YY) == 1) * (exists(XX) == 1) * (exists(ZZ) == 1) )
				append $YY vs $XX
				ModifyGraph textMarker($YY)={$ZZ,"default",0,0,5,0.00,0.00}
			endif
			inc += 1
		while (inc < NumElementsInList(G_suffix, ";"))
		ModifyGraph gfSize=14, mode=3, marker=19, grid=1, mirror=1
		Label left mol + " " + attrib
		Label bottom "Day"
		ModifyGraph rgb=(0,0,65535)
		Legend/N=ssv/J/X=2.31/Y=3.49 "\\s("+YY+") SSV position "
	else
		XX = mol + "_" + suffix + "_date"
		YY = mol + "_" + suffix + "_" + attrib
		ZZ = mol + "_" + suffix + "_selpos"
		if ((exists(YY) == 1) * (exists(XX) == 1))
			DoWindow /K $mol+"_"+attrib
			title = mol + " " + attrib + " " + suffix
			Display /W=(28,69,570,403) $YY vs $XX as title
			DoWindow /C $mol+"_"+attrib
			ModifyGraph gfSize=14, mode=3, marker=19, grid=1, mirror=1
			Label left mol + " " + attrib
			Label bottom "Day"
			ModifyGraph textMarker($YY)={$ZZ,"default",0,0,5,0.00,0.00}
			ModifyGraph rgb=(0,0,65535)
			Legend/N=ssv/J/X=2.31/Y=3.49 "\\s("+YY+") SSV position "
		endif
	endif
	
	
end

Proc MoleConcPlot(mol, attrib, plotmeth, suffix)
	string mol = StrMakeOrDefault("root:G_mol", "")
	string attrib = StrMakeOrDefault("root:G_attrib", "conc")
	variable plotmeth = NumMakeOrDefault("root:G_plotmeth", 1)
	string suffix = StrMakeOrDefault("root:G_suffixPt", "ALL")
	prompt mol, "Molecule", popup, G_loadMol
	prompt attrib, "Display concentration or response", popup, "conc;resp"
	prompt plotmeth, "Plot method", popup, "All data;Daily Average;Weekly Average;Monthly Average;"
	prompt suffix, "Plot with data?", popup, G_suffix +";ALL"

	silent 1; pauseupdate
	
	G_mol = mol
	G_attrib = attrib
	G_suffixPt = suffix
	G_plotmeth = plotmeth
	
	if (plotmeth == 1)	
		AllDataPlot(mol, attrib, suffix)
	else	
	if (plotmeth == 2)	// Daily Avg.
		DailyAvgPlot(mol, attrib, suffix)
	else
	if (plotmeth == 3)	// Weekly Avg.
		WeeklyAvgPlot(mol, attrib, suffix)
	else
	if (plotmeth == 4)	// Monthly Avg.
	endif
	endif
	endif
	endif
		
EndMacro


function AllDataPlot(mol, attrib, suffix)
	string mol, attrib, suffix
	
	variable inc = 0
	string XX, YY, title
	SVAR G_suffix = G_suffix
		
	if (cmpstr(suffix, "ALL") == 0)
		DoWindow /K $mol+"_"+attrib+"_ALL"
		title = mol + " " + attrib + " ALL"
		Display /W=(5,42,610,332) as title
		DoWindow /C $mol+"_"+attrib+"_ALL"
		do
			suffix = GetStrFromList(G_suffix, inc, ";")
			XX = mol + "_" + suffix + "_conc_date"
			YY = mol + "_" + suffix + "_" + attrib
		
			if ((exists(YY) == 1) * (exists(XX) == 1))
				appendtograph $YY vs $XX
			endif
			inc += 1
		while (inc < NumElementsInList(G_suffix, ";"))
		ModifyGraph gfSize=14, mode=4, marker=19, grid=1, mirror=2
		Label left mol + " " + attrib
		Label bottom "Day"
		SetAxis/A/N=1 left
	else	
		XX = mol + "_" + suffix + "_conc_date"
		YY = mol + "_" + suffix + "_" + attrib
		
		if ((exists(YY) == 1) * (exists(XX) == 1))
			DoWindow /K $mol+"_conc"
			title = mol + " " + attrib + " " + suffix
			Display /W=(5,42,610,332) $YY vs $XX as title
			ModifyGraph gfSize=14, mode=4, marker=19, grid=1, mirror=2
			Label left mol + " " + attrib
			Label bottom "Day"
			SetAxis/A/N=1 left
			DoWindow /C $mol+"_conc"
		endif
	endif
	
end

function DailyAvgPlot(mol, attrib, suffix)
	string mol, attrib, suffix
	
	variable inc = 0, Dinc = 0, ptL, Xed = 0, all = 0
	string XX, YY, title
	SVAR G_suffix = G_suffix
	
	string DayX = mol + "_" + attrib + "_dailyX"
	string DayY = mol + "_" + attrib + "_dailyY"
	string DaySD = mol + "_" + attrib + "_dailySD"
	string DayNum = mol + "_" + attrib + "_dailyNum"
	make /o/n=500 $DayX=NaN, $DayY=NaN, $DaySD=NaN, $DayNum=NaN
	wave DayXwv = $DayX
	wave DayYwv = $DayY
	wave DaySDwv = $DaySD
	wave DayNumwv = $DayNum
	
	if (cmpstr(suffix, "ALL") == 0)
		all = 1
	endif
		
	if (all)
		DoWindow /K $("Daily_" +mol+"_"+attrib+"_ALL")
		title = "Daily Avg " + mol + " " + attrib + " ALL"
		Display /W=(5,42,610,332) as title
		DoWindow /C $("Daily_" +mol+"_"+attrib+"_ALL")
	else
		DoWindow /K $("Daily_" +mol+"_"+attrib)
		title = "Daily Avg " + mol + " " + attrib
		Display /W=(5,42,610,332) as title
		DoWindow /C $("Daily_" +mol+"_"+attrib)
	endif
	
	do
		if (all)
			suffix = GetStrFromList(G_suffix, inc, ";")
		endif
		XX = mol + "_" + suffix + "_conc_date"
		YY = mol + "_" + suffix + "_" + attrib
	
		if ( (exists(YY) == 1) * (exists(XX) == 1) )
			wave XXwv = $XX
			if (Xed == 0)	// Load up the Daily Average X wave
				DayXwv = floor(XXwv[0]) + x
				Xed = 1
			endif
			do
				findlevel /q XXwv, DayXwv[Dinc]-0.49
				if (V_Flag)
					ptL = pnt2x(XXwv, 0)
				else
					ptL = V_levelX
				endif
				findlevel /q XXwv, DayXwv[Dinc]+0.50
				if (V_Flag)
					V_levelX = pnt2x(XXwv, numpnts(XXwv) -1)
				endif
				WaveStats/Q/R=[ptL, V_levelX] $YY
				if (numtype(V_sdev) == 2)
					DaySDwv[Dinc] = NaN; DayYwv[Dinc] = NaN; DayNumwv[Dinc] = 0
				else
					DaySDwv[Dinc] = V_sdev; DayYwv[Dinc] = V_avg; DayNumwv[Dinc] = V_npnts
				endif
				Dinc += 1
			while (XXwv[numpnts(XXwv)-1] >= DayXwv[Dinc]+0.5)
		endif
		inc += 1
		
		if (all)
			if (inc >= NumElementsInList(G_suffix, ";"))
				break
			endif
		else
			break
		endif
		
	while (1)
	
	DeletePoints Dinc,500,DayYwv, DayXwv, DaySDwv, DayNumwv
	appendtograph DayYwv vs DayXwv
	ErrorBars $DayY Y,wave=(DaySDwv,DaySDwv)
	ModifyGraph gfSize=14, mode=4, marker=19, grid=1, mirror=2
	Label left mol + " " + attrib
	Label bottom "Day"
	SetAxis/A/N=1 left
	
end

function WeeklyAvgPlot(mol, attrib, suffix)
	string mol, attrib, suffix
	
	variable inc = 0, Dinc = 0, ptL, Xed = 0, all = 0
	string XX, YY, title
	SVAR G_suffix = G_suffix
	
	string WeekX = mol + "_" + attrib + "_weeklyX"
	string WeekY = mol + "_" + attrib + "_weeklyY"
	string WeekSD = mol + "_" + attrib + "_weeklySD"
	string WeekNum = mol + "_" + attrib + "_weeklyNum"
	string Stats = mol + "_" + attrib + "_stats"
	make /o/n=0 DayCatX, DayCatY
	make /o/n=500 $WeekX=NaN, $WeekY=NaN, $WeekSD=NaN, $WeekNum=NaN
	wave WeekXwv = $WeekX
	wave WeekYwv = $WeekY
	wave WeekSDwv = $WeekSD
	wave WeekNumwv = $WeekNum
	
	if (cmpstr(suffix, "ALL") == 0)
		all = 1
		make /o/n=6 $Stats
		wave StatsWv = $Stats
	endif

	// Concat all the data into a single wave
	do
		if (all)
			suffix = GetStrFromList(G_suffix, inc, ";")
		endif
		XX = mol + "_" + suffix + "_conc_date"
		YY = mol + "_" + suffix + "_" + attrib

		if ( (exists(YY) == 1) * (exists(XX) == 1) )
			concatdaWaves (DayCatX, $XX)
			concatdaWaves (DayCatY, $YY)
		endif

		if (all)
			if (inc >= NumElementsInList(G_suffix, ";"))
				break
			endif
		else
			break
		endif
		inc += 1
		
	while(1)
	
	if (all)
		// Do stats on ALL of the Data
		Wavestats /Q DayCatY
		StatsWv[0] = V_avg
		StatsWv[1] = V_sdev
		StatsWv[2] = V_rms
		StatsWv[3] = V_min
		StatsWv[4] = V_max
		StatsWv[5] = V_npnts
	endif
			
	WeekXwv = (floor(DayCatX[0]) - mod(floor(DayCatX[0]), 7)) + 7*x + 7/2

	do
		findlevel /q DayCatX, WeekXwv[Dinc]-7/2
		ptL = V_levelX
		if (V_Flag)
			ptL = pnt2x(DayCatX, 0)
			WeekXwv[Dinc] = DayCatX
		endif
		findlevel /q DayCatX, WeekXwv[Dinc]+7/2
		if (V_Flag)
			V_levelX = pnt2x(DayCatX, numpnts(DayCatX) -1)
		endif
		WaveStats/Q/R=[ptL, V_levelX] DayCatY
		if (numtype(V_sdev) == 2)
			WeekSDwv[Dinc] = NaN; WeekYwv[Dinc] = NaN; WeekNumwv[Dinc] = 0
		else
			WeekSDwv[Dinc] = V_sdev; WeekYwv[Dinc] = V_avg; WeekNumwv[Dinc] = V_npnts
		endif
		Dinc += 1
	while (DayCatX[numpnts(DayCatX)-1] >= WeekXwv[Dinc-1]+7/2)
		
	DeletePoints Dinc,500,WeekYwv, WeekXwv, WeekSDwv, WeekNumwv

	if (all)
		DoWindow /K $("Weekly_" +mol+"_"+attrib+"_ALL")
		title = "Daily Avg " + mol + " " + attrib + " ALL"
		Display /W=(5,42,610,332) as title
		DoWindow /C $("Weekly_" +mol+"_"+attrib+"_ALL")
	else
		DoWindow /K $("Weekly_" +mol+"_"+attrib)
		title = "Daily Avg " + mol + " " + attrib
		Display /W=(5,42,610,332) as title
		DoWindow /C $("Weekly_" +mol+"_"+attrib)
	endif
	
	AppendToGraph WeekYwv vs WeekXwv
	AppendToGraph WeekYwv vs WeekXwv
	ModifyGraph gfSize=14, mode($WeekY)=4, mode($WeekY#1)=3, marker=19
	ModifyGraph rgb($WeekY#1)=(0,0,0)
	ModifyGraph textMarker($WeekY#1)={WeekNumwv,"Helvetica",0,0,5,-10.00,10.00}
	ModifyGraph grid=1, mirror=2
	Label left mol + " " + attrib
	Label bottom "Day"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	ErrorBars $WeekY Y,wave=(WeekSDwv,WeekSDwv)
	
	killwaves DayCatX, DayCatY
	
end

Proc DataPlot(mol, attrib)
	string mol = StrMakeOrDefault("root:G_mol", "")
	string attrib = StrMakeOrDefault("root:G_attrib", "conc")
	prompt mol, "Molecule", popup, G_loadMol
	prompt attrib, "Display concentration or response", popup, "conc;resp"

	silent 1; PauseUpdate
	string WeekX = mol +"_" + attrib + "_weeklyX"
	string WeekY = mol +"_" + attrib + "_weeklyY"
	string WeekSD = mol +"_" + attrib + "_weeklySD"
	string stats = mol +"_" + attrib + "_Stats"
	string text
	
	MoleConcPlot(mol, attrib,1,"ALL")
	ModifyGraph mode=3,msize=2,rgb=(65535,32768,32768)
	MoleConcPlot(mol, attrib,3,"ALL")
	DoWindow /K $("Weekly_" +mol+"_"+attrib+"_All")
	
	AppendToGraph $WeekY vs $WeekX
	
	ModifyGraph mode($WeekY)=4,marker($WeekY)=16
	ModifyGraph msize($WeekY)=0,lsize($WeekY)=2
	ModifyGraph rgb($WeekY)=(0,0,0)
	ErrorBars $WeekY Y,wave=($WeekSD,$WeekSD)
	
	sprintf text, "\\Z14\\JC\\f01Stats on all of the data:\\f00\r\\Z12%3.3f ± %3.3f  (n = %d)", $stats[0], $stats[1], $stats[5]
	Textbox/N=stats/F=0/S=3/B=1/A=MC/X=-26.58/Y=35.51 text
	
end

Proc FilterData(mol, attrib, sd)
	string mol = StrMakeOrDefault("root:G_mol", "")
	variable sd = NumMakeOrDefault("root:G_sdFilt", 3)
	string attrib = StrMakeOrDefault("root:G_attrib", "conc")
	prompt mol, "Molecule", popup, G_loadMol
	prompt attrib, "Display concentration or response", popup, "conc;resp"
	prompt sd, "Standard Deviation Filter"
	
	silent 1;PauseUpdate
	
	G_mol = mol
	G_sdFilt = sd
	
	string suffix, YY
	variable inc, sdval, avgval
	
	make /o/n=0 filtX, filtY
	
	do	
		suffix = GetStrFromList(G_suffix, inc, ";")
		YY = mol + "_" + suffix + "_" + attrib

		if (exists(YY) == 1)
			concatdaWaves (filtY, $YY)
		endif
		inc += 1
	while (inc < NumElementsInList(G_suffix, ";") )
	
	print "•••• " + mol + " ••••"
	wavestats  filtY
	sdval = V_sdev
	avgval = V_avg
	
	inc = 0
	do
		suffix = GetStrFromList(G_suffix, inc, ";")
		YY = mol + "_" + suffix + "_" + attrib
		if (exists(YY) == 1)
			LowChop($YY, avgval-sd*sdval)
			HighChop($YY, avgval+sd*sdval)
		endif
		inc += 1
	while (inc < NumElementsInList(G_suffix, ";") )
	
end
