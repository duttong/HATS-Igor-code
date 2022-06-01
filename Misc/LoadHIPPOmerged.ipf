#pragma rtGlobals=1		// Use modern global access method.
#include <remove points>


Menu "HIPPO"
	"Load HIPPO Merged data", Load_HIPPO_merged()
	"Split By Flight"
	"-"
	"Tracer Tracer Plot"
end

Function Load_HIPPO_merged()

	Variable refNum
	Open/R/F="Merge Files:.tbl" refNum as ""		// Display dialog
	if (refNum == 0)
		return -1									// User canceled
	endif

	NewDataFolder /S/O root:All

	variable numLinesLoaded = 0, j
	Variable numPoints = 10000, pointIncrement = 5000
	string buffer, wvstr
	string header = ReadHeaderLine(refNum)
		
	String /G root:S_Params = header
	
	MakeWaves(header, numPoints)
	
	FReadLine refNum, buffer		// first line is header
	do
		FReadLine refNum, buffer
		if (strlen(buffer) == 0)
			break							// End of file
		endif

		buffer = ReplaceString("NA", buffer, "NaN")			// fix nans
		buffer = ReplaceString(" ", buffer, ";")					// turn string into list
		
		// insert into waves
		for(j=0; j<ItemsInList(buffer); j+=1)
			wvstr = StringFromList(j, header)
			wave wv = $wvstr
			wv[numLinesLoaded] = str2num(StringFromList(j, buffer))
		endfor

		numLinesLoaded +=1
		
		// Check if we need to increase the size of the waves.
		if (numLinesLoaded >= numPoints)
			numPoints += pointIncrement
			for(j=0; j<ItemsInList(buffer); j+=1)
				wvstr = StringFromList(j, header)
				wave wv = $wvstr
				Redimension/N=(numPoints) wv
			endfor
			print "Increased wave sizes: ", numPoints
		endif

	while(1)
	
	// shorten
	for(j=0; j<ItemsInList(header); j+=1)
		wvstr = StringFromList(j, header)
		wave wv = $wvstr
		Redimension/N=(numLinesLoaded) wv
	endfor
	Print "Loaded ", numLinesLoaded, " points"

	close refNum
	
	SetDataFolder root:
end


// header line is the first line
// looks and fixes duplicate variable names
Function /S ReadHeaderLine(refNum)
	Variable refNum

	Variable i, loc
	String buffer, headlst, itm
	FReadLine refNum, buffer
	
	buffer = ReplaceString(".", buffer, "_")
	headlst = ReplaceString(" ", buffer, ";")
	headlst = ReplaceString("\r", headlst, "")
	
	for(i=0;  i<ItemsInList(headlst)-1; i+=1)
		itm = StringFromList(i, headlst)
		loc = WhichListItem(itm, headlst, ";", i+1)
		if (loc != -1)		// found duplicate wave name
			headlst = RemoveListItem(loc, headlst)
			headlst = AddListItem(itm+"dup", headlst, ";", loc)
		endif
	endfor
	
	return headlst
end


// function makes waves that are in the header line
function MakeWaves(header, size)
	string header
	variable size
	
	String itm
	Variable i
	for(i=0; i<ItemsInList(header); i+=1)
		itm = StringFromList(i, header)
		Make /o/n=(size) $itm=NaN
	endfor
	
end

// chop up the data by flight
Function SplitByFlight()

	SetDataFolder root:all

	string wvlst = WaveList("*", ";", ""), DF, wvnm, newnm
	Wave flt = root:all:flt
	string fltlst = UniquePoints(flt)

	wvlst = RemoveFromList("flt", wvlst)
	
	String /G root:S_DFlst = ""
	SVAR DFlst = root:S_DFlst
	
	variable flinc = 0, flightnum, i
	for(flinc=0; flinc<ItemsInList(fltlst); flinc+=1)
		flightnum = str2num(StringFromList(flinc, fltlst))
		
		sprintf DF, "Flight%02d", flightnum
		if (flightnum <= 0)
			sprintf DF, "Test%d", abs(flightnum)
		endif
		Print "Creating " + DF
		DFlst += DF + ";"
		
		DF = "root:"+DF
		NewDataFolder /O $DF
		
		// extract data
		for(i=0; i<ItemsInList(wvlst); i+=1)
			wvnm = StringFromList(i, wvlst)
			if (flightnum <=0)
				sprintf newnm, "%s_T%d", wvnm, abs(flightnum)
			else
				sprintf newnm, "%s_F%02d", wvnm, flightnum
			endif
			Extract /O $wvnm, $DF+":"+newnm, flt==flightnum
		endfor
		
	endfor

	SetDataFolder root:
	
end

// ruturns a list of unique points in a wv
Function /S UniquePoints(wv)
	wave wv
	
	duplicate /FREE wv, wtmp
	
	variable pt, cnt
	string uniqlst = ""
	
	RemoveNaNs(wtmp)
	do
		pt = wtmp[0]
		uniqlst += num2str(pt) + ";"
		wtmp = SelectNumber(wtmp==pt, wtmp, NaN)
		RemoveNaNs(wtmp)
	while (numpnts(wtmp)>0)
	
	return uniqlst
	
end

Function TracerTracerPlot()

	SVAR params = root:S_Params
	SVAR DFlst = root:S_DFlst
	
	String s1, s2
	Prompt s1, "Y axis", popup, SortList(params)
	Prompt s2, "X axis", popup, SortList(params)
	DoPrompt "Tracer Tracer Plot", s1, s2
	If (V_flag)
		return 0
	endif
	
	Variable i
	String DF, sub, win = s1+"vs"+s2
	
	DoWindow /K $win
	Display /W=(35,44,766,499)/K=1
	DoWindow /C $win
	
	if (exists("color_table") == 0 )
		Make /n=(12,3) color_table
		color_table[0][0]= {65535,0,0,65535,16385,32764,65535,16385,49157,49157,0,0}
		color_table[0][1]= {0,65535,0,32764,65535,16385,49157,65535,16385,0,49157,0}
		color_table[0][2]= {0,0,65535,16385,32764,65535,16385,49157,65535,0,0,49157}
	endif
	variable clen = DimSize(color_table, 0)
	
	For(i=0; i<ItemsInList(DFlst); i+=1)
		DF = "root:" + StringFromList(i, DFlst)
		if (strsearch(DF, "Flight",0) != -1)
			sub = "_F" + ReplaceString("root:Flight", DF, "")
		else
			sub = "_T" + ReplaceString("root:Test", DF, "")
		endif
		wave wv1 = $DF+":"+s1+sub
		wave wv2 = $DF+":"+s2+sub
		AppendToGraph wv1 vs wv2
		ModifyGraph rgb($s1+sub) = (color_table[mod(i,clen)][0], color_table[mod(i,clen)][1], color_table[mod(i,clen)][2])
		ModifyGraph marker($s1+sub) = floor(i/5)
		
	endfor
	
	Label left s1
	Label bottom s2
	ModifyGraph mode=3
	legend

	
end


Window CO_QCLSvsCH4_QCLS() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Test1:
	Display /W=(35,44,766,499)/K=1  CO_QCLS_T1 vs CH4_QCLS_T1
	AppendToGraph ::Test0:CO_QCLS_T0 vs ::Test0:CH4_QCLS_T0
	AppendToGraph ::Flight01:CO_QCLS_F01 vs ::Flight01:CH4_QCLS_F01
	AppendToGraph ::Flight02:CO_QCLS_F02 vs ::Flight02:CH4_QCLS_F02
	AppendToGraph ::Flight03:CO_QCLS_F03 vs ::Flight03:CH4_QCLS_F03
	AppendToGraph ::Flight04:CO_QCLS_F04 vs ::Flight04:CH4_QCLS_F04
	AppendToGraph ::Flight05:CO_QCLS_F05 vs ::Flight05:CH4_QCLS_F05
	AppendToGraph ::Flight06:CO_QCLS_F06 vs ::Flight06:CH4_QCLS_F06
	AppendToGraph ::Flight07:CO_QCLS_F07 vs ::Flight07:CH4_QCLS_F07
	AppendToGraph ::Flight08:CO_QCLS_F08 vs ::Flight08:CH4_QCLS_F08
	AppendToGraph ::Flight09:CO_QCLS_F09 vs ::Flight09:CH4_QCLS_F09
	AppendToGraph ::Flight10:CO_QCLS_F10 vs ::Flight10:CH4_QCLS_F10
	AppendToGraph ::Flight11:CO_QCLS_F11 vs ::Flight11:CH4_QCLS_F11
	AppendToGraph ::Flight12:CO_QCLS_F12 vs ::Flight12:CH4_QCLS_F12
	SetDataFolder fldrSav0
	ModifyGraph mode=3
	ModifyGraph marker(CO_QCLS_F04)=1,marker(CO_QCLS_F05)=1,marker(CO_QCLS_F06)=1,marker(CO_QCLS_F07)=1
	ModifyGraph marker(CO_QCLS_F08)=1,marker(CO_QCLS_F09)=2,marker(CO_QCLS_F10)=2,marker(CO_QCLS_F11)=2
	ModifyGraph marker(CO_QCLS_F12)=2
	ModifyGraph rgb(CO_QCLS_T0)=(0,65535,0),rgb(CO_QCLS_F01)=(0,0,65535),rgb(CO_QCLS_F02)=(65535,32764,16385)
	ModifyGraph rgb(CO_QCLS_F03)=(16385,65535,32764),rgb(CO_QCLS_F04)=(32764,16385,65535)
	ModifyGraph rgb(CO_QCLS_F05)=(65535,49157,16385),rgb(CO_QCLS_F06)=(16385,65535,49157)
	ModifyGraph rgb(CO_QCLS_F07)=(49157,16385,65535),rgb(CO_QCLS_F08)=(49157,0,0),rgb(CO_QCLS_F09)=(0,49157,0)
	ModifyGraph rgb(CO_QCLS_F10)=(0,0,49157),rgb(CO_QCLS_F12)=(0,65535,0)
	Label left "CO_QCLS"
	Label bottom "CH4_QCLS"
	Legend/C/N=text0/J/X=80.85/Y=2.55 "\\s(CO_QCLS_T1) CO_QCLS_T1\r\\s(CO_QCLS_T0) CO_QCLS_T0\r\\s(CO_QCLS_F01) CO_QCLS_F01\r\\s(CO_QCLS_F02) CO_QCLS_F02"
	AppendText "\\s(CO_QCLS_F03) CO_QCLS_F03\r\\s(CO_QCLS_F04) CO_QCLS_F04\r\\s(CO_QCLS_F05) CO_QCLS_F05\r\\s(CO_QCLS_F06) CO_QCLS_F06\r\\s(CO_QCLS_F07) CO_QCLS_F07"
	AppendText "\\s(CO_QCLS_F08) CO_QCLS_F08\r\\s(CO_QCLS_F09) CO_QCLS_F09\r\\s(CO_QCLS_F10) CO_QCLS_F10\r\\s(CO_QCLS_F11) CO_QCLS_F11\r\\s(CO_QCLS_F12) CO_QCLS_F12"
EndMacro
