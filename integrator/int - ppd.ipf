#pragma rtGlobals=1		// Use modern global access method.

#include "macros-geoff"
#include <strings as lists>
#include <Remove Points>

// wrapper function for PPD specific load.
function Loadchroms( fileNameStr, pathNameStr )
	string fileNameStr, pathNameStr

	LoadPPD_GC( fileNameStr, pathNameStr )
	return 1
	
end

function LoadPPD_GC( fileNameStr, pathNameStr )
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
		config[1] = "PPD"
		variable /g V_loaded = 1
//		variable /g V_chans = inc
		string /g V_instrument = config[1]
		execute "V_instrument := config[1]"		// set dependance
		SetDataFolder root:chroms
	endif

	// remove bad data from ITX file
//	do
//		inc -= 1
//		chstr = StringFromList( inc, S_waveNames, ";" )
//		RemoveOutliers($chstr, 0, 199999)				// filters bad points such as -999
//	while ( inc > 0 )
	
	SetDataFolder root:

end


// LoaveWaveNotes is tailored for PPD
function LoadWaveNotes( )

	Variable n = CountObjects("root:chroms", 1), inc = 0
	Variable ch, inj, ResRow
	variable HH, MM, SS, extSSV
	String chrom, theNote
	wave injP = root:inj_p
	wave injT = root:inj_t
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
		//selpos[ResRow] = str2num(StringFromList(4, theNote, ";"))
		selpos[ResRow] = 1;
		
		inc += 1
	while(1)
	
	SetDataFolder root:
	
end




