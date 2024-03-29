#pragma rtGlobals=1		// Use modern global access method.

#include "macros-geoff"
#include <strings as lists>
#include <Remove Points>

// wrapper function for UCATS specific load.
function Loadchroms( fileNameStr, pathNameStr )
	string fileNameStr, pathNameStr

	LoadSC_GC( fileNameStr, pathNameStr )
	return 1
	
end

function LoadSC_GC( fileNameStr, pathNameStr )
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
		config[1] = "bld1"
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


// LoaveWaveNotes is tailored for Stratcore
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
		//Changed by Eric 9/23/2014 to fix selpos in cal experiments, with or without a tank in the "cal" position
		//Cal tanks are run with the SSV plumbed downstream of the Tavco in the air "selpos 0" position
		//Except for sometimes one tank in the cal "selpos 1" position
		selpos[ResRow] = str2num(StringFromList(4, theNote, ";"))
		extSSV = str2num(StringFromList(5, theNote, ";"))
//		if (( selpos[ResRow] == 1 ) && (extSSV > 0 ))
//			selpos[ResRow] = extSSV
//		Set selpos to 20 for cal position, just like in cal.tma.  Do this first.
		if (( selpos[ResRow] == 1 ) && (extSSV > 0 ))
			selpos[ResRow] = 20
		endif		
		if (( selpos[ResRow] == 0 ) && (extSSV > 0 ))
			selpos[ResRow] = extSSV
		endif		
		
		// injection pressure and temperature	
		if ( ch == 1 ) 
			injP[ResRow][0] = str2num(StringFromList(6, theNote, ";" ))
			injT[ResRow][0] = str2num(StringFromList(7, theNote, ";" ))
		elseif ( ch == 2 ) 
			injP[ResRow][1] = str2num(StringFromList(6, theNote, ";" ))
			injT[ResRow][1] = str2num(StringFromList(8, theNote,";" ))
		elseif ( ch == 3 ) 
			injP[ResRow][2] = str2num(StringFromList(6, theNote, ";" ))
			injT[ResRow][2] = str2num(StringFromList(9, theNote,";" ))
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



// The default smoothing is Savitzsky-Golay with 75 smoothing factor.
// The smoothing factor must be an odd number
// To call the function without a smoothing factor (uses the default) like this:
//    Smooth_InjT()
// To run the function with a different smoothing factor:
//    Smooth_InjT(smoothfact=45)
//
// The original inj_t matrix is backed up as int_T_org.
// To restore the data to the original and call the function again.
//   1) Close any graphs with inj_T or inj_T_org
//   2) Duplicate /O inj_T_org inj_T
//   3) Killwaves inj_T_org
//   4) Now run Smooth_InjT again
function Smooth_InjT([smoothfact])			// GSD 131203  //EH 220201 for 3-channel UCATS
	variable smoothfact

	if (ParamIsDefault(smoothfact))
		smoothfact = 75
	endif
	
	wave injT = inj_t
	wave TT = tsecs_1904
	
	// Backup the original data
	if (WaveExists(inj_t_org))
		abort("inj_T is already backed up as inj_T_org.  inj_T has probably been smoothed already?")
	endif
	Duplicate injT inj_T_org
	Wave org = inj_T_org

	// Smooth each sample loop (hard coded to 2) - change to 3 for DCOTSS
	Variable i
	for(i=0; i<3; i+=1)	
		MatrixOp /FREE t1 = col(injT,i)
		// Savitzsky-Golay smoothing 
		Smooth/S=2 smoothfact, t1
		injT[][i] = t1[p]
	endfor
	
	// make a figure
	Display /K=1 org[][0], org[][1], org[][2] vs TT
	AppendtoGraph injT[][0], injT[][1], injT[][2] vs TT
	ModifyGraph lsize(inj_T)=2,rgb(inj_T)=(0,0,0),lsize(inj_T#1)=2
	ModifyGraph rgb(inj_T#1)=(0,65535,0),lsize(inj_T#2)=2,rgb(inj_T#2)=(0,0,65535)

end