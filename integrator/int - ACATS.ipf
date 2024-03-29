#pragma rtGlobals=1		// Use modern global access method.

#include "macros-geoff"
#include <strings as lists>
#include <Remove Points>

// wrapper function for UCATS specific load.
function Loadchroms( fileNameStr, pathNameStr )
	string fileNameStr, pathNameStr

	LoadACATS_GC( fileNameStr, pathNameStr )
	return 1
	
end

function LoadACATS_GC( fileNameStr, pathNameStr )
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
		config[1] = "ACATS"
		variable /g V_loaded = 1
//		variable /g V_chans = inc
		string /g S_instrument = config[1]
		execute "S_instrument := config[1]"		// set dependance
		SetDataFolder root:chroms
	endif

	SetDataFolder root:

end


// LoaveWaveNotes is tailored for ACAS
function LoadWaveNotes( )

	Variable n = CountObjects("root:chroms", 1), inc = 0
	Variable ch, inj, ResRow
	variable HH, MM, SS
	String chrom, theNote
	wave injP = root:inj_p
	wave injT = root:inj_t
	wave selpos = root:selpos
	wave tsecs = root:tsecs

	killwaves /z root:chroms:chromTmp
	SetDataFolder root:chroms

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
		if ( ch == 1 )
			selpos[ResRow] = str2num(StringFromList(4, theNote, ";"))
		endif
		
		// injection pressure and temperature	
		if (( ch == 1 ) || ( ch == 2 ))
			injT[ResRow][ch-1] = str2num(StringFromList(5, theNote, ";" ))
			injP[ResRow][ch-1] = str2num(StringFromList(7, theNote, ";" ))
		else
			injT[ResRow][ch-1] = str2num(StringFromList(6, theNote, ";" ))
			injP[ResRow][ch-1] = str2num(StringFromList(7, theNote,";" ))
		endif
		
		// handle tsecs wave
		if (ch == 1)
			HH =  str2num(StringFromList(0, StringFromList(2, theNote,";" ), ":"))
			MM = str2num(StringFromList(1, StringFromList(2, theNote,";" ), ":"))
			SS = str2num(StringFromList(2, StringFromList(2, theNote,";" ), ":"))
			tsecs[ResRow] = HH*60*60 + MM*60 + SS
		endif
		
		inc += 1
	while(1)
	
	SetDataFolder root:
	
end


