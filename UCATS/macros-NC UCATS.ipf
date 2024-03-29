#pragma rtGlobals=1		// Use modern global access method.

#include "macros-geoff"
#include <strings as lists>
#include <Remove Points>

Function BeforeFileOpenHook(refNum, fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr, fileKind)
	Variable refNum, fileKind
	String fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr
	
	variable len = strlen(fileNameStr)
	string com
	
	if ((cmpstr(fileNameStr[len-3,len], "itx")==0) * (fileKind == 5))

		if ( cmpstr(fileNameStr[0,1], "GC") == 0 )
			LoadUAV_GC(fileNameStr, pathNameStr)
		endif
	
		return 1
	endif
	
end


function LoadUAV_GC( fileNameStr, pathNameStr )
	string fileNameStr, pathNameStr
	
	variable injNumber
	
	// variable to know this is UAV data
	if (exists("G_UAV") == 0)
		variable /g G_UAV = 1
	endif

	LoadWave/T/Q/O/P=$pathNameStr fileNameStr

	string chstr
	variable inc = ItemsInList(S_waveNames, ";") 
	
	// remove bad data from ITX file
	do
		inc -= 1
		chstr = StringFromList( inc, S_waveNames, ";" )
		RemoveOutliers($chstr, 0, 199999)
	while ( inc > 0 )
	
	// Add to NoahChrom database
	injNumber = UAVautoAddChroms ( S_waveNames )

	// Strip out wave note
	inc = ItemsInList(S_waveNames, ";") 
	do
		inc -= 1
		chstr = StringFromList( inc, S_waveNames, ";" )
		UAV_GC_Notes( $chstr )
	while ( inc > 0 )

end

function UAV_GC_Notes( chrom )
	wave chrom

	NVAR G_injOffset = G_injOffset
	
	string chromStr = NameofWave(chrom)
	if (CmpStr (chromStr[0,1], "CH") == 0)						// ITX file (eg: chr1_12345)
		variable detN = str2num (chromStr [3,3])
		variable injN = str2num (chromStr [5, strlen(chromStr) - 1])			
	else
		print "Can't identify wave as a UAV chromatogram"
		abort
	endif
	
	String  theNote, selPosNm="selPos", dbRowLst
	String  injPressNm = "det" + num2str (detN) + "_injPress"
	String  injTempNm = "det"  + num2str (detN) + "_injTemp"
	variable HH, MM, SS, extSSV
	variable rowN
	
	theNote = Note(chrom)
	
	wave selPosWv = $selPosNm
	wave injPressWv = $injPressNm
	wave injTempWv = $injTempNm
	wave tsecs = $"tsecs"

	rowN = injN + G_injOffset
	
	// ssv
	selPosWv[rowN] = str2num(StringFromList(4, theNote, ";"))
	if ( selPosWv[rowN] == 1 )
		extSSV = str2num(StringFromList(5, theNote, ";"))
		selPosWv[rowN] = extSSV
	endif		
	
	// injection pressure and temperature	
	injPressWv[rowN] = str2num(StringFromList(6, theNote, ";" ))
	if ( detN == 1 ) 
		injTempWv[rowN] = str2num(StringFromList(7, theNote, ";" ))
	elseif ( detN == 2 ) 
		injTempWv[rowN] = str2num(StringFromList(8, theNote,";" ))
	endif
	
	// handle tsecs wave
	HH =  str2num(StringFromList(0, StringFromList(2, theNote,";" ), ":"))
	MM = str2num(StringFromList(1, StringFromList(2, theNote,";" ), ":"))
	SS = str2num(StringFromList(2, StringFromList(2, theNote,";" ), ":"))
	tsecs[rowN] = HH*60*60 + MM*60 + SS
	
end

function UAVautoAddChroms ( chromlst )
	string chromlst
	
	variable n, detN, injN, chrN, nChrs, rowN
	string chrom, prfx, dbRowLst
	
	NVAR G_injOffset = G_injOffset
	NVAR G_nDets = G_nDets
	NVAR G_dbLen = G_dbLen
	wave inj = $"inj"
	wave AS1 = $"AS1"

	n = 0
	nChrs = ItemsInList(chromlst, ";")

	do
		chrom = StringFromList(n, chromlst, ";")
		prfx = chrom[0,1]
	
		if (CmpStr (prfx, "CH") == 0)						// ITX file (eg: chr1_12345)
			detN = str2num (chrom [3,3])
			injN = str2num (chrom [5, strlen(chrom) - 1])	
		endif
			
		rowN = injN + G_injOffset
	
		if ((detN <= G_nDets) * (rowN < G_dbLen))
			dbRowLst = saGet ("dbRowLstLst", detN-1)		// Which db row list to use for this detector
	
			saPut (dbRowLst, rowN, chrom)
			//chromNote2DBcolumns (detN, chrom, rowN)
			// chrom notes are added in the UAV_GC_Notes function
			inj[rowN] = injN
						
			AS1[n] = injN
		else
			print "Injection # and/or Detector # too high:  ", chrom
		endif	
		
		n += 1
		
	while( n < nChrs )
	
	return injN
	
end	

// function sets the DB flags which are used for the normalization functions
// also makes  AS_Cal, AS_Air, AS_CalAir Waves
function UAV_setDBflags()

	wave selpos = $"selpos"
	variable row = 1, inc
	string com
	SVAR flaglist = G_flagNmLst 
	
	make/o/n=0 AS_Cal, AS_Air, AS_CalAir

	// clear all DB flags
	do
		sprintf com, "ASclrFlag(\"%s\")", StringFromList(inc, flaglist)
		execute com
		inc += 1
	while (inc < ItemsInList(flaglist))
	
	
	dbSetFlagFunc(0,"Bad Chromatogram",1)
	do 

		if (selpos[row] == 0)
			dbSetFlagFunc(row,"Air",1)
			InsertPoints 0, 1, AS_Air
			AS_Air[0] = row
		elseif (selpos[row]==1)
			dbSetFlagFunc(row,"Cal",1)
			InsertPoints 0, 1, AS_Cal
			AS_Cal[0] = row
		else
			dbSetFlagFunc(row,"Bad Chromatogram",1)
		endif
		row += 1
	while (row < numpnts(selpos))
	
	duplicate /o AS_Cal, AS_CalAir
	concatdaWaves (AS_CalAir,AS_Air)
	sort AS_Cal, AS_Cal
	sort AS_Air, AS_Air
	sort AS_CalAir, AS_CalAir

end

Proc PrepData()

	string YY 
	sprintf YY, "%02s", Num2Str(ReturnCurrentYear()-2000)
	string MM = StringFromList(1, Secs2date(DateTime,-1), "/")
	string DD = StringFromList(0, Secs2date(DateTime,-1), "/")
	G_theDate = YY+MM+DD
	
	DateJimsSister()
	
	wavestats /q inj
	deleteDBrows (V_maxloc+1,V_endRow)
	variable strtChrom=G_rowRngMin,endChrom=G_rowRngMax
	
	FixupTsecs()
	// make tsecs_1904
	make /d/o/n=(numpnts($"tsecs")) tsecs_1904 = NaN
	freplace(tsecs, -1, NaN)
	tsecs_1904 = date2secs(2000 + str2num(G_thedate[0,1]),  str2num(G_thedate[2,3]),  str2num(G_thedate[4,5])) + tsecs
	SetScale d 0,0,"dat", tsecs_1904
	print "**** tsecs_1904 wave created. **** "
	
	
	UAV_setDBflags()

	ShifttheChroms(strtChrom,endChrom,1,330,1,1)
	SmoothChroms("all",4,15)

end


