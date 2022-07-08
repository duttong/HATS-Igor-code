// Slimmed down verison made from "NASA Realtime ATOM Data.ipf"
// version 1.0		GSD 210608
// v 1.1 Added more columns to IWG1 parser.
// v 1.2 Added loader for UCATS engineering data load_realtime_GC_userpacket()
// v 1.3 Updated DisplayData
// v 1.4 Changed aircraft tail number from N809NA to N806NA
// v 1.5 bug. fixed removedata() to remove G_data string

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "macros-geoff"
#include "Trace to Graph"

constant VERBOS=0		//set to 1 to see loading URLs in history window
strconstant baseURL = "https://asp-interface.arc.nasa.gov/"
strconstant Aircraft = "N806NA"
strconstant packet_delim = "#UCATS_eng#"

Menu "Macros"
	"load all /1", /Q
	"load UCATS /2", load_UCATS();load_realtime_UCATS_userpacket()
	"load IWG (lat lon alt) /3", load_IWG1()
	"load ROZE (O3) /4", load_ROZE()
	"load HUPCRS (CH4, CO2, CO, H2O) /5", load_HUPCRS()
	"load HWV (Water vapor) /6", load_HWV()
	"-"
	"load all as background task every 30s", StartLoadTask()
	"stop background loading", StopLoadTask()
	"-"
	"Display Data"
	"-"
	"Lat vs Lon Figure", Lat_Lon()
	"Ozone Figure", Ozone_figure()
	"H2O Figure", H2O_figure()
	"-"
	"Prepare Stationery", Prepare_Stationery()
End

function loadall()
	load_UCATS()
	load_realtime_UCATS_userpacket()
	load_IWG1()
	load_ROZE()
	load_HUPCRS()
	load_HWV()
end

Function StartLoadTask()
	Variable numTicks = 30 * 60		// Run every 30 seconds
	CtrlNamedBackground loader, period=numTicks, proc=BkGload
	CtrlNamedBackground loader, start
End

Function StopLoadTask()
	CtrlNamedBackground loader, stop
End

Function BkGload(s)
	STRUCT WMBackgroundStruct &s
	
	//Printf "Task %s called, ticks=%d\r", s.name, s.curRunTicks
	loadall()
	return 0
end

function load_UCATS()

	string inst = "UCATS"
	string url = baseURL + "API/parameter_data/" + Aircraft + "/" + inst
	url = FetchURL_StartTime(url)

	if (VERBOS==1)
		print "Loading: " + url
	endif
	string data = FetchUrl(url)
	
	if (strlen(data) == 0)
		print "No " + inst + " data found."
		return -1
	endif
	
	variable multirows = StrSearch(data, inst, 0)
	multirows = StrSearch(data, inst, multirows+1)
	if (multirows == -1)
		// only one row of data, the last row.
		return 0
	endif
	
	// Cleanup the data before parsing
	data = ReplaceString(inst+",", data, "")
	data = ReplaceString("T", data, ",")
	
	PutScrapText data

	string datewvstr = inst + "_Date"
	string timewvstr = inst + "_Time"
	variable i

	string var, vars = "N2_highP;N2_lowP;T_amb;O3;N2O;SF6;CCl4;CFC12;H2O"
	String columnsFormat = ""
	columnsFormat += "C=1,F=6,N=dd;"
	columnsFormat += "C=1,F=7,N=tt;"
	columnsFormat += "C=1,N='_skip_';"  // skip the status column
	columnsFormat += "C=1,F=0,N=N2_highP;"
	columnsFormat += "C=1,F=0,N=N2_lowP;"
	columnsFormat += "C=1,F=0,N=T_amb;"
	columnsFormat += "C=1,F=0,N=O3;"
	columnsFormat += "C=1,F=0,N=N2O;"
	columnsFormat += "C=1,F=0,N=SF6;"
	columnsFormat += "C=1,F=0,N=CCl4;"
	columnsFormat += "C=1,F=0,N=CFC12;"
	columnsFormat += "C=1,F=0,N=H2O;"

	Loadwave /Q/J/O/A/R={English,2,2,2,1,"Year-Month-DayOfMonth",40}/B=columnsFormat "Clipboard"

	wave dd, tt, N2_highP, N2_lowP, T_amb, O3, N2O, SF6, CCl4, CFC12, H2O
	dd += tt
	
	wave /Z test = $datewvstr
	if (waveExists(test))
		DeletePoints 0,1, dd, tt, N2_highP, N2_lowP, T_amb, O3, N2O, SF6, CCl4, CFC12, H2O
		Concatenate {dd}, $datewvstr
		Concatenate {tt}, $timewvstr
		for(i=0; i<ItemsInList(vars); i+=1)
			var = StringFromList(i, vars)
			Concatenate {$var}, $(inst + "_" + var)
		endfor
	else
		Duplicate dd, $datewvstr
		Duplicate tt, $timewvstr
		for(i=0; i<ItemsInList(vars); i+=1)
			var = StringFromList(i, vars)
			Duplicate $var, $(inst + "_" + var)
		endfor
	endif

	SetScale/I x 0,819,"", $datewvstr
	
	Killwaves dd, tt, N2_highP, N2_lowP, T_amb, O3, N2O, SF6, CCl4, CFC12, H2O

end

function load_realtime_UCATS_userpacket()
	
	string url = baseURL + "API/binary_packet_data/" + Aircraft + "/UCATS_BIN"
	string vars, data
	SVAR /Z userpacket = G_userpacket

	// Get one second of data to parse out all of the variable names
	if (!SVAR_Exists(userpacket))
		data = FetchUrl(url)
		string /G G_userpacket = data
		
		if (strlen(data) == 0)
			print "No data found."
			return -1
		endif
	endif

	SVAR /Z userpacket = G_userpacket
	vars = userpacket_vars(userpacket)

	wave /Z mt = $"userpacket_matrix"
	
	if (WaveExists(mt))
		// update matrix
		Wave dd = $"Ueng_Date"
		Wave tt = $"Ueng_Time"
		string lasttime = ReturnDatetimeStr(dd[Inf], tt[Inf])
		url = url + "?Start=" + lasttime
		if (VERBOS==1)
			print "Loading: " + url
		endif
	else
		// make the matrix
		make /d/o/n=(1, ItemsInList(vars)) userpacket_matrix = Nan
	
		// all data
		url = baseURL + "API/binary_packet_data/" + Aircraft + "/UCATS_BIN?Start=0"
	endif

	data = FetchUrl(url)
	String /G G_data = data
		
	parse_userpacket()
	
	if (numpnts(userpacket_matrix) > 1)
		SplitWave /O/Name=vars userpacket_matrix
		Wave dd = $"Ueng_Date"
		SetScale d 0,0,"dat", dd
	endif
	
end

function /S ReturnDatetimeStr(dt, secs)
	variable dt, secs
	
	string str
	variable HH = floor(secs/3600)
	variable MM = floor((secs - HH*3600) / 60)
	variable SS = floor((secs - HH*3600 - MM*60))
	sprintf str, "%sT%02d:%02d:%02d", Secs2Date(dt,-2), HH, MM, SS
	return str
	
end

function parse_userpacket()

	SVAR data = G_data
	variable i = 0, pt0, pt1
	
	pt0 = StrSearch(data, packet_delim, 0)
	do
		pt1 = StrSearch(data, packet_delim, pt0+1)
		if (pt1 == -1)
			break
		endif

		userpacket_row(data[pt0, pt1])

		i += 1
		pt0 = pt1
	while(1)
	
end

// returns a list of all the variables in a UCATS user packet
function /S userpacket_vars(s)
	string s
	
	variable i = 0, pt
	string prefix = "Ueng_"
	string t, list = ReplaceString(packet_delim, s, "")
	list = ReplaceString(",", list, ";")
	
	string wvlist = ""
	for(i = 0; i<ItemsInList(list); i+=1)
		t = stringFromList(i, list)
		pt = strsearch(t, "=", 0)
		
		wvlist += prefix + t[0, pt-1] + ";"
	endfor
	
	return wvlist
	
end

// parses data from a one second user data packet (s)
function userpacket_row(s)
	string s
	
	wave mt = userpacket_matrix

	variable i = 0, pt, val
	string t, list = ReplaceString(packet_delim, s, "")
	list = ReplaceString(",", list, ";")
	
	Make /o/d/n=(ItemsInList(list))/FREE row = Nan
	
	for(i = 0; i<ItemsInList(list); i+=1)
		t = stringFromList(i, list)
		pt = strsearch(t, "=", 0)
		if (i == 0)
			// parse date
			variable YYYY = str2num(t[pt+1, pt+4])
			variable MM = str2num(t[pt+6, pt+7])
			variable DD = str2num(t[pt+9, pt+10])
			row[0] = date2secs(YYYY, MM, DD)		
		elseif (i == 1)
			// parse time
			variable HH = str2num(t[pt+1, pt+2])
			variable MN = str2num(t[pt+4, pt+5])
			variable SS = str2num(t[pt+7, pt+8])
			row[1] = HH * 3600 + MN * 60 + SS
			row[0] += row[1]	// add time to date column
		else
			row[i] = str2num(t[pt+1, Inf])
		endif

	endfor
	
	variable rownum = DimSize(mt, 0)
	InsertPoints/M=0 rownum,1, mt
	mt[rownum][] = row[q]
	
end


function /S FetchURL_StartTime(url)
	string url
	
	variable pt = strsearch(url, "/", Inf, 1)
	string inst = url[pt+1, strlen(url)]		// the instrument name is at the end of the url
	
	string datewvstr = inst + "_Date"
	string timewvstr = inst + "_Time"
	
	wave /Z dd = $datewvstr

	if (WaveExists(dd))
		// update data
		Wave dd = $datewvstr
		Wave tt = $timewvstr
		if (numpnts(dd) < 10)
			url = url + "?Start=0" // all data
		else
			string lasttime = ReturnDatetimeStr(dd[Inf], tt[Inf])
			url = url + "?Start=" + lasttime
		endif
	else
		url = url + "?Start=0" // all data
	endif
		
	return url
	
end

function load_IWG1()

	string inst = "IWG1"
	string url = baseURL + "API/parameter_data/" + Aircraft + "/" + inst
	url = FetchURL_StartTime(url)

	if (VERBOS==1)
		print "Loading: " + url
	endif
	string data = FetchUrl(url)
	
	if (strlen(data) == 0)
		Print "No " + inst + " data found."
		return -1
	endif
	
	variable multirows = StrSearch(data, inst, 0)
	multirows = StrSearch(data, inst, multirows+1)
	if (multirows == -1)
		// only one row of data, the last row.
		return 0
	endif
	
	// Cleanup the data before parsing
	data = ReplaceString(inst+",", data, "")
	data = ReplaceString("T", data, ",")
	
	PutScrapText data

	string datewvstr = inst + "_Date"
	string timewvstr = inst + "_Time"
	string var1str = inst + "_O3"
	variable i

	string var, vars = "lat;lon;gps_alt;airspeed;ambient_temp;cabin_press;wind_speed;wind_dir"
	String columnsFormat = ""
	columnsFormat += "C=1,F=6,N=dd;"
	columnsFormat += "C=1,F=7,N=tt;"
	columnsFormat += "C=1,F=0,N=lat;"
	columnsFormat += "C=1,F=0,N=lon;"
	columnsFormat += "C=1,F=0,N=gps_alt;"
	columnsFormat += "C=4,N='_skip_';"	// skip columns
	columnsFormat += "C=1,F=0,N=airspeed;"
	columnsFormat += "C=10,N='_skip_';"	// skip columns
	columnsFormat += "C=1,F=0,N=ambient_temp;"
	columnsFormat += "C=4,N='_skip_';"	// skip columns
	columnsFormat += "C=1,F=0,N=cabin_press;"
	columnsFormat += "C=1,F=0,N=wind_speed;"
	columnsFormat += "C=1,F=0,N=wind_dir;"
	columnsFormat += "C=100,N='_skip_';"	// skip columns

	Loadwave /Q/J/O/A/R={English,2,2,2,1,"Year-Month-DayOfMonth",40}/B=columnsFormat "Clipboard"

	wave dd, tt, lat, lon, gps_alt, airspeed, ambient_temp, cabin_press, wind_speed, wind_dir
	dd += tt
	
	wave /Z test = $datewvstr
	if (waveExists(test))
		DeletePoints 0,1, dd, tt, lat, lon, gps_alt, airspeed, ambient_temp, cabin_press, wind_speed, wind_dir	
		Concatenate {dd}, $datewvstr
		Concatenate {tt}, $timewvstr
		for(i=0; i<ItemsInList(vars); i+=1)
			var = StringFromList(i, vars)
			Concatenate {$var}, $(inst + "_" + var)
		endfor
	else
		Duplicate dd, $datewvstr
		Duplicate tt, $timewvstr
		for(i=0; i<ItemsInList(vars); i+=1)
			var = StringFromList(i, vars)
			Duplicate $var, $(inst + "_" + var)
		endfor
	endif

	SetScale/I x 0,819,"", $datewvstr
	
	Killwaves dd, tt, lat, lon, gps_alt, airspeed, ambient_temp, cabin_press, wind_speed, wind_dir	

end

function load_HUPCRS()

	string inst = "HUPCRS"
	string url = baseURL + "API/parameter_data/" + Aircraft + "/" + inst
	url = FetchURL_StartTime(url)

	if (VERBOS==1)
		print "Loading: " + url
	endif
	string data = FetchUrl(url)
	
	if (strlen(data) == 0)
		print "No " + inst + " data found."
		return -1
	endif
	
	variable multirows = StrSearch(data, inst, 0)
	multirows = StrSearch(data, inst, multirows+1)
	if (multirows == -1)
		// only one row of data, the last row.
		return 0
	endif
	
	// Cleanup the data before parsing
	data = ReplaceString(inst+",", data, "")
	data = ReplaceString("T", data, ",")
	
	PutScrapText data

	string datewvstr = inst + "_Date"
	string timewvstr = inst + "_Time"
	variable i

	string var, vars = "CH4;CO2;CO;H2O"
	String columnsFormat = ""
	columnsFormat += "C=1,F=6,N=dd;"
	columnsFormat += "C=1,F=7,N=tt;"
	columnsFormat += "C=7,N='_skip_';"
	columnsFormat += "C=1,F=0,N=CH4;"
	columnsFormat += "C=1,F=0,N=CO2;"
	columnsFormat += "C=1,F=0,N=CO;"
	columnsFormat += "C=1,F=0,N=H2O;"
	columnsFormat += "C=100,N='_skip_';"

	Loadwave /Q/J/O/A/R={English,2,2,2,1,"Year-Month-DayOfMonth",40}/B=columnsFormat "Clipboard"

	wave dd, tt, CH4, CO2, CO, H2O
	dd += tt
	
	wave /Z test = $datewvstr
	if (waveExists(test))
		DeletePoints 0,1, dd, tt, CH4, CO2, CO, H2O
		Concatenate {dd}, $datewvstr
		Concatenate {tt}, $timewvstr
		for(i=0; i<ItemsInList(vars); i+=1)
			var = StringFromList(i, vars)
			Concatenate {$var}, $(inst + "_" + var)
		endfor
	else
		Duplicate dd, $datewvstr
		Duplicate tt, $timewvstr
		for(i=0; i<ItemsInList(vars); i+=1)
			var = StringFromList(i, vars)
			Duplicate $var, $(inst + "_" + var)
		endfor
	endif

	SetScale/I x 0,819,"", $datewvstr
	
	Killwaves dd, tt, CH4, CO2, CO, H2O

end


// Ozone instrument
function load_ROZE()

	string inst = "ROZE"
	string url = baseURL + "API/parameter_data/" + Aircraft + "/" + inst
	url = FetchURL_StartTime(url)

	if (VERBOS==1)
		print "Loading: " + url
	endif
	string data = FetchUrl(url)
	
	if (strlen(data) == 0)
		print "No " + inst + " data found."
		return -1
	endif
	
	variable multirows = StrSearch(data, inst, 0)
	multirows = StrSearch(data, inst, multirows+1)
	if (multirows == -1)
		// only one row of data, the last row.
		return 0
	endif
	
	// Cleanup the data before parsing
	data = ReplaceString(inst+",", data, "")
	data = ReplaceString("T", data, ",")
	
	PutScrapText data

	string datewvstr = inst + "_Date"
	string timewvstr = inst + "_Time"
	string var1str = inst + "_O3"

	String columnsFormat = ""
	columnsFormat += "C=1,F=6,N=dd;"
	columnsFormat += "C=1,F=7,N=tt;"
	columnsFormat += "C=1,N='_skip_';"
	columnsFormat += "C=1,F=0,N=var1;"
	columnsFormat += "C=100,N='_skip_';"

	Loadwave /Q/J/O/A/R={English,2,2,2,1,"Year-Month-DayOfMonth",40}/B=columnsFormat "Clipboard"

	wave dd, tt, var1
	dd += tt
	
	wave /Z test = $datewvstr
	if (waveExists(test))
		DeletePoints 0,1, dd, tt, var1	
		Concatenate {dd}, $datewvstr
		Concatenate {tt}, $timewvstr
		Concatenate {var1}, $var1str
	else
		Duplicate dd, $datewvstr
		Duplicate tt, $timewvstr
		Duplicate var1, $var1str
	endif

	SetScale/I x 0,819,"", $datewvstr
	
	Killwaves dd, tt, var1
		
end


// Water vapor instrument
function load_HWV()

	string inst = "HWV"
	string url = baseURL + "API/parameter_data/" + Aircraft + "/" + inst
	url = FetchURL_StartTime(url)

	if (VERBOS==1)
		print "Loading: " + url
	endif
	string data = FetchUrl(url)
	
	if (strlen(data) == 0)
		print "No " + inst + " data found."
		return -1
	endif
	
	variable multirows = StrSearch(data, inst, 0)
	multirows = StrSearch(data, inst, multirows+1)
	if (multirows == -1)
		// only one row of data, the last row.
		return 0
	endif
	
	// Cleanup the data before parsing
	data = ReplaceString(inst+",", data, "")
	data = ReplaceString("T", data, ",")
	
	PutScrapText data

	string datewvstr = inst + "_Date"
	string timewvstr = inst + "_Time"
	string var1str = inst + "_H2O"

	String columnsFormat = ""
	columnsFormat += "C=1,F=6,N=dd;"
	columnsFormat += "C=1,F=7,N=tt;"
	columnsFormat += "C=1,N='_skip_';"
	columnsFormat += "C=1,F=0,N=var1;"
	columnsFormat += "C=100,N='_skip_';"

	Loadwave /Q/J/O/A/R={English,2,2,2,1,"Year-Month-DayOfMonth",40}/B=columnsFormat "Clipboard"

	wave dd, tt, var1
	dd += tt
	
	wave /Z test = $datewvstr
	if (waveExists(test))
		DeletePoints 0,1, dd, tt, var1	
		Concatenate {dd}, $datewvstr
		Concatenate {tt}, $timewvstr
		Concatenate {var1}, $var1str
	else
		Duplicate dd, $datewvstr
		Duplicate tt, $timewvstr
		Duplicate var1, $var1str
	endif

	SetScale/I x 0,819,"", $datewvstr
	
	Killwaves dd, tt, var1
		
end



Function DisplayData()
	string x, y
	Prompt y, "Y-axis", popup SortList(Wavelist("*_*", ";", ""))
	Prompt x, "x-axis", popup SortList(Wavelist("*_date", ";", ""))
	DoPrompt "Enter X and Y", x, y
	if (V_Flag)
		return -1								// User canceled
	endif

	string win = y+"_plt"
	DoWindow /K $win
	Display /K=1/W=(35,45,543,315) $y vs $x
	DoWindow /C $win
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left NameOfWave($y)
	Label bottom "Time"
	printf "Display %s vs %s", NameOfWave($y), NameOfWave($x)
EndMacro


Window Lat_Lon() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:USAStateBounds:
	Display /W=(325,53,835,410) W_Geometries[*][1] vs W_Geometries[*][0]
	AppendToGraph ::IWG1_lat vs ::IWG1_lon
	AppendToGraph ::WorldCoastline:W_Geometries[*][1] vs ::WorldCoastline:W_Geometries[*][0]
	SetDataFolder fldrSav0
	ModifyGraph margin(right)=144
	ModifyGraph lSize(IWG1_lat)=3
	ModifyGraph rgb(W_Geometries)=(43690,43690,43690),rgb(W_Geometries#1)=(13107,13107,13107)
	ModifyGraph zColor(IWG1_lat)={IWG1_date,*,*,BlueRedGreen}
	ModifyGraph mirror=2
	Label left "Latitude"
	Label bottom "Longitude"
	SetAxis left 33.8281423018388,45.8925212253822
	SetAxis/N=1 bottom -117.943744883658,-95.1453838122947
	ColorScale/C/N=Datetime/F=0/X=104.80/Y=15.02 trace=IWG1_lat, fsize=10
	ColorScale/C/N=Datetime lblMargin=40
	AppendText "Datetime"
EndMacro

Window H2O_figure() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(679,352,1054,577)/K=1  Ueng_tdl_best vs Ueng_Date
	AppendToGraph H2O_UCATS vs UCATS_date
	AppendToGraph HWV_H2O vs HWV_Date
	ModifyGraph rgb(Ueng_tdl_best)=(0,0,0),rgb(HWV_H2O)=(3,52428,1)
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left "H2O_UCATS"
	Label bottom "Time"
	Legend/C/N=text0/J/X=7.43/Y=2.15 "\\s(H2O_UCATS) H2O_UCATS\r\\s(Ueng_tdl_best) Ueng_tdl_best\r\\s(HWV_H2O) HWV_H2O"
EndMacro

Window Ozone_figure() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(704,371,1052,599)/K=1  UCATS_O3 vs UCATS_date
	AppendToGraph Ueng_o3xbest vs Ueng_Date
	AppendToGraph ROZE_O3 vs ROZE_date
	ModifyGraph rgb(Ueng_o3xbest)=(0,0,0),rgb(ROZE_O3)=(3,52428,1)
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left "O3_UCATS"
	Label bottom "Time"
	Legend/C/N=text0/J/X=71.43/Y=3.32 "\\s(UCATS_O3) UCATS_O3\r\\s(Ueng_o3xbest) Ueng_o3xbest\r\\s(ROZE_O3) ROZE_O3"
EndMacro




// used to reset experiment to make a stationery
function removedata()

	string wv, waves = wavelist("*", ";", "")
	variable i, pts
	for(i=0; i<ItemsInList(waves); i+=1)
		wv = stringfromList(i, waves)
		pts = numpnts($wv)
		DeletePoints 0,pts, $wv
	endfor
	
	killwaves /Z userpacket_matrix
	killstrings /Z G_userpacket, G_data
end


// Deletes Ueng_* waves that are of zero length. This occurs if the
// data is no longer transmitted through the "User packet" with that name.
function Cleanup()

	variable i
	string wv, wvs = WaveList("Ueng_*", ";", "")
	for(i=0; i<ItemsInList(wvs); i+=1)
		wv = StringFromList(i, wvs)
		if (numpnts($wv) == 0)
			Killwaves $wv
			print wv
		endif
	endfor
end

function Prepare_Stationery()

	removedata()
	abort "You may now save this experiment as a stationery"

end