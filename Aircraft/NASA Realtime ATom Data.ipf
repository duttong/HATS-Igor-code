// updated for ATOM-4  180427 GSD

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "macros-geoff"
#include "Trace to Graph"

strconstant urlDC8 = "http://10.1.1.1/"
strconstant urlOther = "https://asp-interface.arc.nasa.gov/"

Menu "Macros"
	"Select platform URL", Select_platform()
	"-"
	"load all data from ChemWAD<B/1", load_ChemWAD()
	"-"
	"load PANTHER", load_realtime_GCdata(inst="PANTHER")
	"load UCATS", load_realtime_GCdata(inst="UCATS")
	"load PANTHER and UCATS/2", load_realtime_GCdata(inst="PANTHER"); load_realtime_GCdata(inst="UCATS")
	"load DLH", load_DLH()
	"load lat lon alt", load_IWG1()
	"-"
	"Display Data"
End


// Choose which URL the experiment gets data from
// DC-8: http://10.1.1.1
// Anywhere else: https://asp-interface.arc.nasa.gov
function Select_platform()

	variable platform
	Prompt platform, "Where are you running this experiment from?", popup "DC-8;Not DC-8"
	DoPrompt "", platform
	if (V_Flag)
		return -1
	endif
	
	if (platform == 1)
		string /G S_baseurl = urlDC8
	else
		string /G S_baseurl = urlOther
	endif
	
	print "Base URL: " + S_baseurl
	
	ChemWad_header()

end

// loads the ChemWad header from URL pointing to a csv file.
function ChemWad_header()

	SVAR baseURL = S_baseURL
	string url
	if (cmpstr(baseURL, urlDC8) == 0)
		url = baseURL + "usefulfiles/Chemwad-Header.csv"
	else
		//url = "https://asp-archive.arc.nasa.gov/ATOM-3/N817NA/Chemwad-Header.csv"
		url = "https://asp-archive.arc.nasa.gov/ATOM-4/N817NA/Chemwad-Header.csv"
	endif

	string data = FetchUrl(url)

	if (strlen(data) == 0)
		abort "Can't find ChemWad header file."
	endif

	data = ReplaceString(",", data, ";")		// make it an Igor list
	data = ReplaceString("\n", data, "")
	data = RemoveListItem(0, data)				// remove "ChemWad"
	data = RemoveListItem(0, data)				// remove "Timestamp"

	String /G S_ChemHeader = data
	
end

// use load_ChemWAD instead
function loadalldata()
	print "Loading PANTHER data"
	load_realtime_GCdata(inst="PANTHER")
	print "Loading UCATS data"
	load_realtime_GCdata(inst="UCATS")
	print "Loading lat, lon, and altitude from IWG1 stream"
	load_IWG1()
end

function load_realtime_GCdata([inst])
	string inst
	if (ParamIsDefault(inst))
		Prompt inst, "Select an instrment", popup "PANTHER;UCATS"
		DoPrompt "", inst
		if (V_Flag)
			return -1								// User canceled
		endif
	endif
	
	SVAR baseURL = S_baseURL
	string url = baseURL + "API/parameter_data/N817NA/" + inst + "?Start=0"
	print url
	
	string data = FetchUrl(url)
	
	if (strlen(data) == 0)
		abort "No data found.  Maybe instrument string is incorrect"
	endif
	
	// Cleanup the data before parsing
	data = REplaceString("PANTHER,", data, "")
	data = REplaceString("UCATS,", data, "")
	data = REplaceString("T", data, ",")
	
	String /g G_data = data
	String /g G_inst = inst

	PutScrapText data
	
	String columnsFormat = ""
	if (cmpstr(inst, "PANTHER") == 0)
		columnsFormat += "C=1,F=6,N=panther_date;"
		columnsFormat += "C=1,F=7,N=panther_time;"
		columnsFormat += "C=1,N='_skip_';"	// skip the status column
		columnsFormat += "C=1,F=0,N=panther_f11;"
		columnsFormat += "C=1,F=0,N=panther_n2o;"
		columnsFormat += "C=1,F=0,N=panther_sf6;"
		columnsFormat += "C=1,F=0,N=panther_ch4;"
	elseif (cmpstr(inst, "UCATS") == 0)
		columnsFormat += "C=1,F=6,N=ucats_date;"
		columnsFormat += "C=1,F=7,N=ucats_time;"
		columnsFormat += "C=1,N='_skip_';"  // skip the status column
		columnsFormat += "C=1,F=0,N=ucats_o3;"
		columnsFormat += "C=1,F=0,N=ucats_n2o;"
		columnsFormat += "C=1,F=0,N=ucats_ch4;"
		columnsFormat += "C=1,F=0,N=ucats_sf6;"
		columnsFormat += "C=1,F=0,N=ucats_h2o;"
	endif
	
	Loadwave /J/O/A/R={English,2,2,2,1,"Year-Month-DayOfMonth",40}/B=columnsFormat "Clipboard"

	Wave dd = $inst+"_date"	
	Wave dt = $inst+"_time"	
	dd += dt
	
	Killwaves dt
	
end

function load_IWG1()

	SVAR baseURL = S_baseURL
	string url = baseURL + "API/parameter_data/N817NA/IWG1?Start=0"
		
	string data = FetchUrl(url)
	
	if (strlen(data) == 0)
		abort "No data found.  Maybe instrument string is incorrect"
	endif
	
	// Cleanup the data before parsing
	data = REplaceString("IWG1,", data, "")
	data = REplaceString("T", data, ",")
	
	PutScrapText data
	
	String columnsFormat = ""
	columnsFormat += "C=1,F=6,N=iwg_date;"
	columnsFormat += "C=1,F=7,N=iwg_time;"
	columnsFormat += "C=1,F=0,N=lat;"
	columnsFormat += "C=1,F=0,N=lon;"
	columnsFormat += "C=1,F=0,N=gps_alt;"
	columnsFormat += "C=100,N='_skip_';"	// skip the status column
	
	Loadwave /J/O/A/R={English,2,2,2,1,"Year-Month-DayOfMonth",40}/B=columnsFormat "Clipboard"

	Wave dd = iwg_date
	Wave dt = iwg_time
	dd += dt
	
	Killwaves dt
	
end

function load_DLH()

	SVAR baseURL = S_baseURL
	string url = baseURL + "API/parameter_data/N817NA/DLH?Start=0"
	
	string data = FetchUrl(url)
	
	if (strlen(data) == 0)
		abort "No data found.  Maybe instrument string is incorrect"
	endif
	
	// Cleanup the data before parsing
	data = REplaceString("DLH,", data, "")
	data = REplaceString("T", data, ",")
	
	PutScrapText data
	
	String columnsFormat = ""
	columnsFormat += "C=1,F=6,N=dlh_date;"
	columnsFormat += "C=1,F=7,N=dlh_time;"
	columnsFormat += "C=1,F=0,N=dlh_h2o;"
	
	Loadwave /J/O/A/R={English,2,2,2,1,"Year-Month-DayOfMonth",40}/B=columnsFormat "Clipboard"

	Wave dd = dlh_date
	Wave dt = dlh_time
	dd += dt
	
	Killwaves dt
	
end

Function load_ChemWAD([start])
	variable start
	if (ParamIsDefault(start))
		Prompt start, "Start time of data", popup ("all data;starting today;starting yesterday")
		DoPrompt "When?", start
		if (V_Flag)
			return -1								// User canceled
		endif
	endif
	
	String startstr
	variable YYYY = str2num(StringFromList(2, Secs2date(DateTime,-1), "/")[0,3])
	variable MM = str2num(StringFromList(1, Secs2date(DateTime,-1), "/"))
	variable DD = str2num(StringFromList(0, Secs2date(DateTime,-1), "/"))

	variable /d tt
	switch(start)	// numeric switch
		case 1:
			startstr = "Start=0"
			break
		case 2:
			startstr = "Start="+num2istr(date2secs(YYYY, MM, DD)-date2secs(1970,1,1))
			break
		case 3:
			startstr = "Start="+num2istr(date2secs(YYYY, MM, DD-1)-date2secs(1970,1,1))
			break
	endswitch
	
	SVAR header = S_ChemHeader
	SVAR baseURL = S_baseURL
	string url = baseURL + "API/parameter_data/N817NA/ChemWAD?" + startstr
	print url
	
	string data = FetchUrl(url)
	
	if (strlen(data) == 0)
		abort "No data found.  URL is incorrect."
	endif
	
	// Cleanup the data before parsing
	data = REplaceString("ChemWAD,", data, "")
	data = REplaceString("T", data, ",")
	
	PutScrapText data
	
	Variable i
	String var, columnsFormat = ""
	columnsFormat += "C=1,F=6,N=DC8_date;"
	columnsFormat += "C=1,F=7,N=DC8_time;"
	for(i=0; i<ItemsInList(header); i+=1)
		var = StringFromList(i, header)
		columnsFormat += "C=1,F=0,N=DC8_"+var+";"
	endfor
	
	Loadwave /Q/J/O/A/R={English,2,2,2,1,"Year-Month-DayOfMonth",40}/B=columnsFormat "Clipboard"

	Wave dda = dc8_date
	Wave dt = dc8_time
	dda += dt
	
	Killwaves dt

end

Function DisplayData()
	string x, y
	Prompt y, "Y-axis", popup Wavelist("*_*", ";", "")
	Prompt x, "x-axis", popup Wavelist("*_date", ";", "")
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
EndMacro

// creates a ucats and panther _lat, _lon, and _alt waves.
// not needed.
//function sync_params()

	wave /Z lat, lon, gps_alt, iwg_date
	wave /Z panther_date, ucats_date
	
	if (WaveExists(panther_date))
		make /o/n=(numpnts(panther_date)) panther_lat, panther_lon, panther_alt
		panther_lat = lat[BinarySearchInterp(iwg_date, panther_date)]
		panther_lon = lon[BinarySearchInterp(iwg_date, panther_date)]
		panther_alt = gps_alt[BinarySearchInterp(iwg_date, panther_date)]
	endif
	
	if (WaveExists(ucats_date))
		make /o/n=(numpnts(ucats_date)) ucats_lat, ucats_lon, ucats_alt
		ucats_lat = lat[BinarySearchInterp(iwg_date, ucats_date)]
		ucats_lon = lon[BinarySearchInterp(iwg_date, ucats_date)]
		ucats_alt = gps_alt[BinarySearchInterp(iwg_date, ucats_date)]
	endif

end	