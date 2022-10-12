#pragma rtGlobals=1		// Use modern global access method.

#include "macros-geoff"
#include <strings as lists>

Function BeforeFileOpenHook(refNum, fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr, fileKind)
	Variable refNum, fileKind
	String fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr
	
	variable len = strlen(fileNameStr)
	string com
	
	if ((cmpstr(fileNameStr[len-3,len], "itx")==0) * (fileKind == 5))
		if ( cmpstr(fileNameStr[0,2], "MSD") == 0 )
			LoadPANTHER_MSD(fileNameStr, pathNameStr)
		endif
		if ( cmpstr(fileNameStr[0,1], "GC") == 0 )
			LoadPANTHER_GC(fileNameStr, pathNameStr)
		endif
		
		return 1
	endif
	
end

function LoadPANTHER_MSD( fileNameStr, pathNameStr )
	string fileNameStr, pathNameStr
	
	variable T0offset = 37			// solvent delay time (s)
	variable SmoothSD = 3			// smooth standard deviation 
	variable SmoothFact = .2		// smoothing factor  -- see info in Interpolate help
	variable chromPTs = 2000	

	LoadWave/T/O/Q/P=$pathNameStr fileNameStr
	
	string msdT = GetStrFromList( S_waveNames, 0, ";" )
	string msdR = GetStrFromList( S_waveNames, 1, ";" )
	string chromNum = msdT[strlen(msdT)-5, strlen(msdT)] 
	string chNum = num2str(str2num(msdT[4,4]) + 1)
	string newChrom = "chr"+chNum+"_"+chromNum
	
	string com
	variable Ltm, Rtm
	
	sprintf com, "Interpolate/T=3/N=%d/F=%f/S=%d/Y=SSmsd %s /X=%s", chromPTs, SmoothFact, SmoothSD, msdR, msdT
	execute com
	
	// shift the chrom to account for the solvent delay and convert from milliseconds to seconds
	Ltm = pnt2x(SSmsd, 0)/1000 + T0offset
	Rtm = pnt2x(SSmsd, numpnts(SSmsd)-1)/1000 + T0offset 
	SetScale/I x Ltm, Rtm,"", SSmsd
	
	duplicate /o SSmsd $newChrom
			
	Note $newChrom, Note($msdR)

	// variable to know this is PANTHER data
	if (exists("G_PANTHER") == 0)
		variable /g G_PANTHER = 1
	endif
	
	PANTHERautoAddChroms( newChrom )
	PANTHER_MSD_Notes( $newChrom )

	killwaves SSmsd, $msdT, $msdR	

end

function LoadPANTHER_GC( fileNameStr, pathNameStr )
	string fileNameStr, pathNameStr
	
	silent 1
	// variable to know this is PANTHER data
	if (exists("G_PANTHER") == 0)
		variable /g G_PANTHER = 1
	endif

	LoadWave/T/Q/O/P=$pathNameStr fileNameStr
	
	string chstr
	variable inc = NumElementsInList(S_waveNames, ";") 
	do
		inc -= 1
		chstr = GetStrFromList( S_waveNames, inc, ";" )
		RemoveBadGCdata( $chstr )
	while ( inc > 0 )
	
	PANTHERautoAddChroms ( S_waveNames )

	inc = NumElementsInList(S_waveNames, ";") 
	do
		inc -= 1
		chstr = GetStrFromList( S_waveNames, inc, ";" )
		PANTHER_GC_Notes( $chstr )
	while ( inc > 0 )

end

// Sometimes there are -999 in one column of gc data (one chrom) and
// not the others.  The -999 is placed there by the data collection
// program as a place holder.  This routine removes these data.
function RemoveBadGCdata( chrom )
	wave chrom
	
	variable inc
	do
		if (chrom[inc] == -999)
			DeletePoints inc,1, chrom
			inc -= 1
		endif
		inc += 1 
	while (inc < numpnts(chrom))

end

function PANTHER_GC_Notes( chrom )
	wave chrom

	NVAR G_injOffset = G_injOffset
	
	string chromStr = NameofWave(chrom)
	if (CmpStr (chromStr[0,1], "CH") == 0)						// ITX file (eg: chr1_12345)
		variable detN = str2num (chromStr [3,3])
		variable injN = str2num (chromStr [5, strlen(chromStr) - 1])			
	else
		print "Can't identify wave as a PANTHER chromatogram"
		abort
	endif
	
	String  theNote, selPosNm="selPos", dbRowLst
	String  injPressNm = "det" + num2str (detN) + "_injPress"
	String  injTempNm = "det"  + num2str (detN) + "_injTemp"
	variable rowN
	
	theNote = Note(chrom)
	
	wave selPosWv = $selPosNm
	wave injPressWv = $injPressNm
	wave injTempWv = $injTempNm

	rowN = injN + G_injOffset
	
	selPosWv[rowN] = str2num(GetStrFromList(theNote, 4, ";"))
	injPressWv[rowN] = str2num(GetStrFromList(theNote, 6, ";" ))
	if ( detN == 1 ) // SF6 temp
		injTempWv[rowN] = str2num(GetStrFromList(theNote, 7, ";" ))
	else
	if ( detN == 2 ) // F11 temp
		injTempWv[rowN] = str2num(GetStrFromList(theNote, 8, ";" ))
	else
	if ( detN == 3 ) // CO temp
		injTempWv[rowN] = str2num(GetStrFromList(theNote, 9, ";" ))
	else
		injTempWv[rowN] = str2num(GetStrFromList(theNote, 9, ";" ))
	endif
	endif
	endif	
	
end

function PANTHER_MSD_Notes( chrom )
	wave chrom

	NVAR G_injOffset = G_injOffset
	NVAR G_yr = G_yr
	NVAR G_mo = G_mo
	NVAR G_day = G_day
	NVAR G_sec = G_sec
	
	string chromStr = NameofWave(chrom)
	
	if (CmpStr (chromStr[0,1], "CH") == 0)						
		variable detN = str2num (chromStr [3,3]) 
		variable injN = str2num (chromStr [6, strlen(chromStr) - 1])			
	else
		print "Can't identify wave as a PANTHER MSD chromatogram."
		abort
	endif
	
	String  theNote, selPosNm="selPos", dbRowLst
	String  injPressNm = "det" + num2str (detN) + "_injPress"
	String  injTempNm = "det"  + num2str (detN) + "_injTemp"
	variable rowN
	
	theNote = Note(chrom)
	
	wave selPosWv = $selPosNm
	wave injPressWv = $injPressNm
	wave injTempWv = $injTempNm
	wave tsecsWv = $"tsecs"
	wave doyWv = $"doy"
	wave yrWv = $"yr"

	rowN = injN + G_injOffset
	
	QBdate2ParsedDate(GetStrFromList(theNote, 3, ";"), GetStrFromList(theNote, 2, ";"))
	yrWv[rowN] = G_yr
	doyWv[rowN] = date2julian (G_yr, G_mo, G_day)
	tSecsWv[rowN] = G_sec

	selPosWv[rowN] = str2num(GetStrFromList(theNote, 4, ";"))
	injPressWv[rowN] = str2num(GetStrFromList(theNote, 9, ";" ))
	injTempWv[rowN] = str2num(GetStrFromList(theNote, 14, ";" ))
	
	//print rowN, detN, selPosWv[rowN], injPressWv[rowN], injTempWv[rowN], nameofwave(injPressWv)
	
end