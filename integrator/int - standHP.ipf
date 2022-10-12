#pragma rtGlobals=1		// Use modern global access method.

#include "macros-geoff"
#include <strings as lists>
#include <Remove Points>

// wrapper function for standards HP GC specific load.
function Loadchroms( fileNameStr, pathNameStr )
	string fileNameStr, pathNameStr

	LoadstandHP_GC( fileNameStr, pathNameStr )
	return 1
	
end

function LoadstandHP_GC( fileNameStr, pathNameStr )
	string fileNameStr, pathNameStr

	NVAR chromInc = root:V_chromInc

	wave /t config = config
	string newname, chrom
		
	SetDataFolder root:chroms
	
	LoadWave/T/Q/O/P=$pathNameStr fileNameStr
	
	// if first time executed.  Set a few global variables.
	if (exists("V_loaded") == 0)
		SetDataFolder root:
		config[1] = "stdHP"
		variable /G V_loaded = 1
		string /G V_instrument = config[1]
		execute "V_instrument := config[1]"		// set dependance
		SetDataFolder root:chroms
	endif
	
	
	// need to rename chroms from chan1 to chr1_00001
	// the chr1_##### file will be incremented from 1
	chrom = StringFromList(0, S_waveNames)
	newname = "chr1_" + PadStr(chromInc, 5, "0")
	duplicate /o $chrom, $newname
	killwaves /z $chrom
	
	chromInc += 1
		
	SetDataFolder root:

end


// LoaveWaveNotes is tailored for standards lab HP (n2o & sf6)
function LoadWaveNotes( )

	Variable n = CountObjects("root:chroms", 1), inc = 0
	Variable ch, inj, ResRow
	variable HH, MM, SS
	String chrom, theNote
//	wave injP = root:inj_p
//	wave injT = root:inj_t
	wave selpos = root:selpos
	wave tsecs = root:tsecs

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
		selpos[ResRow] = str2num(StringFromList(4, theNote, ";"))
		
		// handle tsecs wave
		HH =  str2num(StringFromList(0, StringFromList(2, theNote,";" ), ":"))
		MM = str2num(StringFromList(1, StringFromList(2, theNote,";" ), ":"))
		SS = str2num(StringFromList(2, StringFromList(2, theNote,";" ), ":"))
		tsecs[ResRow] = HH*60*60 + MM*60 + SS

		inc += 1
	while(1)
	
	SetDataFolder root:
	
end


