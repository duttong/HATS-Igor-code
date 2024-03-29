#pragma rtGlobals=1		// Use modern global access method.

#include "macros-geoff"
#include <strings as lists>
#include <Remove Points>

// wrapper function for UCATS specific load.
function Loadchroms( fileNameStr, pathNameStr )
	string fileNameStr, pathNameStr
	
	// sets a variable to keep track of whether the experiment is for GC or MSD data.
	// only one type of data can be loaded.
	if (exists("S_PANTHERtype") == 0 )
		String /G S_PANTHERtype
		if ( cmpstr(fileNameStr[0,1], "GC") == 0 )
			S_PANTHERtype = "GC"
		elseif ( cmpstr(fileNameStr[0,2], "MSD") == 0 )
			S_PANTHERtype = "MSD"
		else
			S_PANTHERtype = "???"
		endif
	endif
	SVAR S_PANTHERtype = S_PANTHERtype

	if ( cmpstr(fileNameStr[0,1], "GC") == 0 )
		if ( cmpstr(S_PANTHERtype, "GC") == 0 )
			LoadPANTHER_GC( fileNameStr, pathNameStr )
			return 1
		endif
	elseif ( cmpstr(fileNameStr[0,2], "MSD") == 0 )
		if ( cmpstr(S_PANTHERtype, "MSD") == 0 )
			LoadPANTHER_MSD( fileNameStr, pathNameStr )
			return 1
		endif
	endif
	
	return 0
	
end

function LoadPANTHER_GC( fileNameStr, pathNameStr )
	string fileNameStr, pathNameStr
	
	variable injNumber, inc
	wave /t config = config
	string chstr
		
	SetDataFolder root:chroms
	
	LoadWave/T/Q/O/P=$pathNameStr fileNameStr
	
	inc = ItemsInList(S_waveNames, ";") 
	
	// if first time executed.  Set a few global variables.
	if (exists("V_loaded") == 0)
		SetDataFolder root:
		config[1] = "PANTHER"
		variable /g V_loaded = 1
		string /G V_instrument = config[1]
		execute "V_instrument := config[1]"		// set dependance
		String /G S_PANTHERtype = "GC"		// GC or MSD used for loading wave notes 
		SetDataFolder root:chroms
	endif

	// remove bad data from ITX file
	do
		inc -= 1
		chstr = StringFromList( inc, S_waveNames, ";" )
		RemoveOutliers($chstr, 0, 199999)				// filters bad points such as -999
	while ( inc > 0 )
	
	SetDataFolder root:

end

function LoadPANTHER_MSD( fileNameStr, pathNameStr )
	string fileNameStr, pathNameStr

	variable T0offset = 60            // solvent delay time (s)
	variable SmoothSD = 2            // smooth standard deviation
	variable SmoothFact = .01    // smoothing factor  -- see info in Interpolate help
	variable chromPTs = 800
	wave /t config = config

	// check if  name is correct
	if ( strlen(fileNameStr) != 27 )
		return 0
	endif

	SetDataFolder root:chroms
	
	LoadWave/T/O/Q/P=$pathNameStr fileNameStr

	// if first time executed.  Set a few global variables.
	if (exists("V_loaded") == 0)
		SetDataFolder root:
		config[1] = "PANTHER"
		variable /g V_loaded = 1
		string /G V_instrument = config[1]
		execute "V_instrument := config[1]"		// set dependance
		String /G S_PANTHERtype = "MSD"		// GC or MSD used for loading wave notes 
		SetDataFolder root:chroms
	endif

	string msdT = GetStrFromList( S_waveNames, 0, ";" )
	string msdR = GetStrFromList( S_waveNames, 1, ";" )
	string chromNum = msdT[strlen(msdT)-5, strlen(msdT)]
	string chNum = num2str(str2num(msdT[4,4]) + 1)
	string newChrom = "chr"+chNum+"_"+chromNum

	wave msdTwv = $msdT
	wave msdRwv = $msdR
	string com
	variable Ltm, Rtm

//	Interpolate2 does not give the same results as Interpolate???????
//	Interpolate2/T=3/N=(chromPTs)/F=(SmoothFact)/S=(SmoothSD)/Y=SSmsd  $msdR

//	sprintf com, "Interpolate/T=3/N=%d/F=%f/S=%d/Y=SSmsd %s /X=%s", chromPTs, SmoothFact, SmoothSD, msdR, msdT
//	execute com

	// shift the chrom to account for the solvent delay and convert from milliseconds to seconds
	Ltm = msdTwv[0]/1000 + T0offset
	Rtm = msdTwv[numpnts(msdTwv)-1]/1000 + T0offset
	SetScale/I x Ltm, Rtm,"", msdRwv

	duplicate /o msdRwv $newChrom

	Note $newChrom, Note(msdRwv)

	// variable to know this is PANTHER data
	if (exists("G_PANTHER") == 0)
 		variable /g G_PANTHER = 1
 	endif

	killwaves /Z msdTwv, msdRwv

	SetDataFolder root:

end

// LoaveWaveNotes is tailored for PANTHER
function LoadWaveNotes( )

	SetDataFolder root:
	
	SVAR type = root:S_PANTHERtype

	strswitch( type )
	
		case "GC":
			PANTHER_ECD_Notes()
			break
		
		case "MSD":
			PANTHER_MSD_Notes()
			break
			
	endswitch
	
end

function PANTHER_ECD_Notes( )

	Variable ch, inj, ResRow, inc
	variable HH, MM, SS
	String chrom, theNote
	wave injP = root:inj_p
	wave injT = root:inj_t
	wave selpos = root:selpos
	wave tsecs = root:tsecs
	
	variable psi2mbar = 68.9475729
	
	// make selposPAN 
	duplicate /o selpos root:selposPAN
	wave selposPAN = root:selposPAN
	
	SetDataFolder root:chroms
	
	if (WaveExists($"chromTmp"))
		Killwaves /Z chromTmp
	endif
	if (WaveExists($"chromTmp"))
		abort "Close the graph with chromTmp and then rerun."
	endif
	
	do
		chrom = GetIndexedObjName(":", 1, inc)
	
		if (strlen(chrom) == 0)
			break
		endif
	
		if (CmpStr (chrom[0,1], "CH") == 0)					// ITX file (eg: chr1_12345)
			ch = str2num(chrom[3,3]) 						// channel number
			inj = str2num (chrom [5, strlen(chrom) - 1])		// injection number	
			theNote = Note($chrom)							// wave note
		endif
		
		ResRow = ReturnResRowNumber( ch, inj )
		
		// ssv
		selpos[ResRow] = str2num(StringFromList(4, theNote, ";"))
		if ( str2num(StringFromList(6, theNote, ";")) == 1 )
			selposPAN[ResRow] = 2
		else
			selposPAN[ResRow] = 1
		endif			
		
		// determine the number of items in wavenote
		// PresBP_PAN was added on 060118
		variable extra = 0
		if ( numtype(str2num(StringFromList(12, theNote, ";"))) == 0 )
			extra += 1
		endif
		
		// injection pressure same for channels 0-2, PAN (ch 3) is different
		injP[ResRow][] = str2num(StringFromList(7, theNote, ";" ))
		injP[ResRow][3] = str2num(StringFromList(7+extra, theNote, ";" ))
		if ( injP[ResRow][3] < 30 )
			injP[ResRow][3] *= psi2mbar
		endif
		
		// injection temperature	
		if ( ch == 1 ) 
			injT[ResRow][0] = str2num(StringFromList(8+extra, theNote, ";" ))
		elseif ( ch == 2 ) 
			injT[ResRow][1] = str2num(StringFromList(9+extra, theNote,";" ))
		elseif ( ch == 3 ) 
			injT[ResRow][2] = str2num(StringFromList(10+extra, theNote,";" ))
		elseif ( ch == 4 ) 
			injT[ResRow][3] = str2num(StringFromList(11+extra, theNote,";" ))
		endif
		
		// handle tsecs wave
		HH =  str2num(StringFromList(0, StringFromList(2, theNote,";" ), ":"))
		MM = str2num(StringFromList(1, StringFromList(2, theNote,";" ), ":"))
		SS = str2num(StringFromList(2, StringFromList(2, theNote,";" ), ":"))
		tsecs[ResRow] = HH*60*60 + MM*60 + SS

		inc += 1
	while(1)
	
	SetDataFolder root:

end



function PANTHER_MSD_Notes( )

	Variable ch, inj, ResRow, inc
	variable HH, MM, SS
	String chrom, theNote
	wave injP = root:inj_p
	wave injT = root:inj_t
	wave selpos = root:selpos
	wave tsecs = root:tsecs
	
	SetDataFolder root:chroms

	if (WaveExists($"chromTmp"))
		Killwaves /Z chromTmp
	endif
	
	do
		chrom = GetIndexedObjName(":", 1, inc)
	
		if (strlen(chrom) == 0)
			break
		endif
	
		if (CmpStr (chrom[0,1], "CH") == 0)					// ITX file (eg: chr1_12345)
			ch = str2num(chrom[3,3]) 						// channel number
			inj = str2num (chrom [5, strlen(chrom) - 1])		// injection number	
			theNote = Note($chrom)							// wave note
		endif

		ResRow = ReturnResRowNumber( ch, inj )

		if (numtype(ResRow) == 2)
			break
		endif
		
		// ssv
		selpos[ResRow] = str2num(StringFromList(4, theNote, ";")) + 10*str2num(StringFromList(5, theNote, ";"))
		
		
		// injection pressure same for all channels
		injP[ResRow][] = str2num(StringFromList(9, theNote, ";" ))
		
		// injection temperature for all channels
		injT[ResRow][] = str2num(StringFromList(14, theNote,";" ))
		
		// handle tsecs wave
		HH =  str2num(StringFromList(0, StringFromList(2, theNote,";" ), ":"))
		MM = str2num(StringFromList(1, StringFromList(2, theNote,";" ), ":"))
		SS = str2num(StringFromList(2, StringFromList(2, theNote,";" ), ":"))
		tsecs[ResRow] = HH*60*60 + MM*60 + SS

		inc += 1
	while(1)
	
	SetDataFolder root:

end

