#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=1		// Use modern global access method.

#include "macros-geoff"

// Procedure to load GMD met data
Proc LoadMetData( site )
	string site = StrMakeOrDefault("root:G_site", "brw")
	prompt site, "Which site", popup, "brw;mlo;smo;spo"

	silent 1; PauseUpdate
	G_site = site
	
	LoadMetDataFUNCT( site )

end

function LoadMetDataFUNCT( site ) 
	string site
	
	if ( ! DataFolderExists("root:hour:") )
		abort "There are no CATS hourly data.  Load CATS data first."
	endif
	
	NewDataFolder /O/S met
	
	string file = "met_" + site + ".txt"
	string pf = "met_" + site + "_"		// prefix

	PathInfo METdata
	if (V_flag == 0)
		NewPath /M="Path to Met data" METdata
	endif

	LoadWave/G/O/A/P=METdata file

//	duplicate /o wave0 $pf+"ID"
	duplicate /o wave1 $pf+"YYYY"
	duplicate /o wave2 $pf+"MM"
	duplicate /o wave3 $pf+"DD"
	duplicate /o wave4 $pf+"HH"
	duplicate /o wave5 $pf+"winddir"
	duplicate /o wave6 $pf+"windspeed"
//	duplicate /o wave7 $pf+"windsted"
	duplicate /o wave8 $pf+"press"
	duplicate /o wave9 $pf+"temp"
//	duplicate /o wave10 $pf+"dewpoint"
	duplicate /o wave11 $pf+"precip"

	make /o/d/n=(numpnts(wave1)) $(pf+"date") = 0
	wave D = $pf+"date"
	wave YYYY = $pf+"YYYY"
	wave DD = $pf+"DD"
	wave MM = $pf+"MM"
	wave HH = $pf+"HH"
	
	D = date2secs(YYYY, MM, DD) + HH * 60*60

	// a little processing
	SetScale d 0,0,"dat", D
	
	SyncMetData( site )

	// delete unneed waves
	killwaves YYYY, MM, DD, HH, D
	bat("killwaves @", "wave*")

	SetDataFolder root:	

end

Function SyncMetData(site)
	string site
	
	string METDF = "root:met:"
	string CATSDF = "root:hour:"
	
	if ( ! DataFolderExists(CATSDF) )
		abort "There are no CATS hourly data.  Load CATS data first."
	endif

	SetDataFolder $METDF
	
	Wave T = $CATSDF + site + "_time"
	Wave MetT = $"met_" + site + "_date"
	Wave METprecip = $"met_" + site + "_precip"
	Wave METpress = $"met_" + site + "_press"
	Wave METtemp = $"met_" + site + "_temp"
	Wave METwinddir = $"met_" + site + "_winddir"
	Wave METwindspeed = $"met_" + site + "_windspeed"
	Variable /D i, pt
	
	Make /o/n=(numpnts(T)) precip = NaN, press = NaN, temp = NaN, winddir = NaN, windspeed = NaN
	
	for ( i=0; i<numpnts(T); i+=1 )
		pt = BinarySearchInterp(MetT, T[i])
		if ( numtype(pt) == 0 )
			precip[i] = METprecip[pt]
			press[i] = METpress[pt]
			temp[i] = METtemp[pt]
			winddir[i] = METwinddir[pt]
			windspeed[i] = METwindspeed[pt]
		endif
	endfor

	highchop(windspeed, 99)
	highchop(winddir, 361)
	highchop(press, 2000)
	highchop(precip, 900)
	highchop(temp,40)
	
	Duplicate /O precip, METprecip
	Duplicate /O press, METpress
	Duplicate /O temp, METtemp
	Duplicate /O winddir, METwinddir
	Duplicate /O windspeed, METwindspeed
	
	killwaves precip, press, temp, winddir, windspeed
	
end



Macro WindBins( mol, suffix, detrend, monthlst ) 
	string mol = G_mol
	variable detrend = NumMakeOrDefault("root:G_detrend", 1 )
	string monthlst = StrMakeOrDefault("root:G_monthlst", "1;2;3;4;5")
	string suffix = G_suffix
	prompt mol, "Which molecule?", popup, G_loadmol
	prompt suffix, "Wind Data Suffix"
	prompt detrend, "Detrend the data?", popup, "yes;no"
	prompt monthlst, "List of months to use"
	
	silent 1
	G_mol = mol
	G_suffix = suffix
	G_detrend = detrend
	G_monthlst = monthlst

	variable bindeg = 15

	string wind = "met_" + G_site + "_winddir" + suffix
	print wind
	string day = mol + "_date"

	if ( detrend == 1)
		string data = mol+"_detrend"
		if (exists(data) != 1)
			DetrendCATSdata( mol )
		endif
		if (numpnts($data) != numpnts($day))
			DetrendCATSdata( mol )
		endif
	else
		string data = mol+"_best_conc_hourlyY"
	endif
	
	WindBinsFUNCT( bindeg, $day, $data, $wind, monthlst )

	DoWindow /K $"bintable"
	DoWindow /K $"binGraph"
	Edit/W=(979,47,1375,483) bin_deg,bin_data,bin_num
	DoWindow /C $"bintable"
	Display /W=(981,513,1376,721) bin_data vs bin_deg
	ModifyGraph mode=5
	SetAxis/A/N=1/E=0 left
	DoWindow /C $"binGraph"
	
end

//function WindBinsFUNCT( bindeg, day, data, wind, monthlst )
	variable bindeg
	wave day, data, wind
	string monthlst
	
	variable inc=0, binpnt, month, inlst
	make /d/o/n=((360/bindeg)) bin_deg = nan, bin_num = 0, bin_data = 0
	
	if ( numpnts(day) != numpnts(wind) )
		abort "date and wind waves are not the same length"
	endif
	
	variable bininc = 0
	do
		bin_deg[inc] = bininc
		inc += 1
		bininc += bindeg
	while (bininc < 360 )

	inc = 0	
	for( inc = 0; inc < numpnts(day); inc += 1 )
		if ( numtype(wind[inc]) == 0 )
			binpnt = BinarySearch(bin_deg, wind[inc])
			if ( binpnt == -2 )
				binpnt = numpnts(bin_deg)-1
			endif
			if (numtype(data[inc]) == 0)
				month = returnMonth( day[inc] )
				inlst =  FindListItem(num2str(month), monthlst, ";", 0)
				if (inlst >= 0)
					bin_data[binpnt] += data[inc]
					bin_num[binpnt] += 1
				endif
			endif
		endif
	endfor
		
	for ( inc = 0; inc < numpnts(bin_data); inc += 1 )
		bin_data[inc] /= bin_num[inc]
	endfor
	
end


