#pragma rtGlobals=1		// Use modern global access method.

Proc SetMissingRets(mol, val, useAS)
	string mol = S_currPeak
	variable val
	variable useAS = 1
	prompt mol, "Peak", popup, WaveToList(":DB:DB_mols", ";")
	prompt val, "Retention Time"
	prompt useAS, "Use AS?", popup, "Use Current AS;Whole ret wave"
	
	Silent 1

	variable ch = ReturnChannel(mol)
	variable i, ResRow
	string AS = ("root:AS:CH" + num2str(ch) + "_AS")

	string ret = ("root:" +mol + "_ret")


	if ( useAS == 1)
		i = 0
		do
			ResRow = ReturnResRowNumber( ch, $AS[i] )
			if ( numtype($ret[ResRow]) == 2)
				$ret[ResRow] = val
			endif
			i += 1
		while ( i < numpnts($AS))
	else
		$ret = SelectNumber(numtype($ret) == 2), $ret, val)
	endif
	
end

Function ResponseOnePeak(mol, chrnum)
	variable chrnum
	string mol

	variable ch = returnChannel(mol)
	variable DBrow = returnMolDBrow(mol)
	variable ResRow = ReturnResRowNumber(ch, chrnum)
	variable normP, normT
	variable CtoK = 273.15		// conversion of C to K
	variable standP = 1013.25	// mbar
	variable standT = 25 + CtoK	// use 25 C as standard temp
	
	// non existant peak
	if ( ch < 1 )
		return nan
	endif
	
	// resp method defined in DB
	wave respMeth = root:DB:DB_respMeth
	wave Pmeth = root:DB:DB_respPmeth
	wave Tmeth = root:DB:DB_respTmeth
	wave Pconst = root:DB:DB_respPconst
	wave Tconst = root:DB:DB_respTconst	
	
	wave resp = $("root:" + mol + "_resp")
	wave hgt = $("root:" + mol + "_height")
	wave are = $("root:" + mol + "_area")
	wave injP = root:inj_p
	wave injT = root:inj_t
	
	// normalized pressure
	if ( Pmeth[DBrow] == 0 )
		normP = injP[ResRow][ch-1] / standP 		// use sample loop measurement
	else
		normP = Pconst[DBrow] / standP			// use constant value
	endif

	// normalized temperature
	if ( Tmeth[DBrow] == 0 )
		normT = (injT[ResRow][ch-1] + CtoK) / standT		// use sample loop measurement
	else
		normT = (Tconst[DBrow] + CtoK) / standT			// use constant value
	endif
		
	if ( respMeth[DBrow] == 0 )
		resp[ResRow] = hgt[ResRow] / normP * normT		// use height
	else	
		resp[ResRow] = are[ResRow] / normP * normT		// use area
	endif

//	print resrow, normP, injP[ResRow][ch-1], normT, injT[ResRow][ch-1], hgt[ResRow], resp[ResRow]
	
	return resp[ResRow]

end


Function ResponseAS()

	wave DBactive = root:DB:DB_activePeak

	NVAR numCh = root:V_chans
	
	variable molinc, ASinc, DBmolRow, ch, ResRow
	string mol
	
	for (ch=1; ch <= numCh; ch+= 1)
		SVAR molLst = $("root:DB:S_molLst" + num2str(ch))
		molinc = 0
		do
			mol = StringFromList(molinc, molLst, ";")
			DBmolRow = returnMolDBrow(mol)
			
			// is the peak active?
			if ( DBactive[DBmolRow] )

				wave flagMan = $("root:" + mol + "_flagMan")
				wave flagBad = $("root:" + mol + "_flagBad")

				// response in active set only
				wave AS = $("root:AS:CH" + num2str(ch) + "_AS")
				
				for (ASinc=0; ASinc < numpnts(AS); ASinc += 1)
					if ( numpnts(AS) == 0 )
						break
					endif
					
					ResRow = ReturnResRowNumber( ch, AS[ASinc] )

					// response if bad flag is not set
					// man flag is not used to insure that response for manual integrated peaks is calculated
					if ( ! flagBad[ResRow] ) 
						ResponseOnePeak( mol, AS[ASinc] )
					endif
				endfor
				
			endif
			molinc += 1
		while ( molinc < ItemsInList(molLst))
	endfor

end


// function creates the result waves for a molecule.
function MakePeakResWaves( mol, saveflags )
	string mol
	variable saveflags
	
	variable ch = returnChannel(mol)
	string AS = "root:AS:CH" + num2str(ch) + "_All"
	variable num = numpnts($AS)		// number of chroms
	String savedf = GetDataFolder(1)
	
	SetDataFolder root:
	
	string ret = mol + "_ret"
	string start = mol + "_start"
	string stop = mol + "_stop"
	string height = mol + "_height"
	string are = mol + "_area"
	string resp = mol + "_resp"
	string man = mol + "_flagMan"
	string bad = mol + "_flagBad"
	
	if ( saveflags )
		make /o/n=(num) $ret = nan, $start = nan, $stop = nan, $height = nan, $are = nan, $resp = nan
		if (exists(man) == 0)
			make /o/n=(num) $man = 0, $bad = 0
		endif
	else
		make /o/n=(num) $ret = nan, $start = nan, $stop = nan, $height = nan, $are = nan, $resp = nan, $man = 0, $bad = 0
	endif
	
	SetDataFolder savedf
	
end

// makes result waves if they do not exist
function MakeAllPeakResWaves()

	wave /t DBmols = root:DB:DB_mols
	variable inc
	string mol, ret
	
	do
		mol = DBmols[inc]
		ret = "root:" + mol + "_ret"
		if ( exists(ret) != 1 )
			MakePeakResWaves( mol, 0 )
		endif
		inc += 1
	while (inc < numpnts(DBmols))
end


Proc ResetResultWaves(mol, saveflags, useAS)
	string mol = S_currPeak
	variable saveflags = 1
	variable useAS = 1
	prompt mol, "Peak", popup, WaveToList(":DB:DB_mols", ";")
	prompt saveflags, "Preserve the flag waves?", popup, "Yes;No"
	prompt useAS, "Use AS or reset the whole wave?", popup, "Use Current AS;Reset Whole Result DB"

	if (useAS == 2)
		MakePeakResWaves( mol, (saveflags==1) )
	else
		ResetResWavesUsingAS( mol, (saveflags==1) )
	endif
		
end

// resets all result waves to NaN using the AS
function ResetResWavesUsingAS( mol, saveflags )
	string mol
	variable saveflags
	
	variable ch = ReturnChannel(mol)
	variable i, ResRow
	wave AS = $("root:AS:CH" + num2str(ch) + "_AS")

	wave ret = $(mol + "_ret")
	wave start = $(mol + "_start")
	wave stop = $(mol + "_stop")
	wave height = $(mol + "_height")
	wave are = $(mol + "_area")
	wave resp = $(mol + "_resp")
	wave man = $(mol + "_flagMan")
	wave bad = $(mol + "_flagBad")
	
	for (i=0; i<numpnts(AS); i+= 1)
		ResRow = ReturnResRowNumber( ch, AS[i] )
		ret[ResRow] = NaN
		start[ResRow] = NaN
		stop[ResRow] = NaN
		height[ResRow] = NaN
		are[ResRow] = NaN
		resp[ResRow] = NaN
		if (! saveflags )
			man[ResRow] = 0
			bad[ResRow] = 0
		endif
	endfor
	
end


// Function to set a single result wave to NaN useing the AS
Proc ResetOneResWaves( mol, res, useAS )
	string mol = S_currPeak
	string res
	variable useAS = 1
	prompt mol, "Peak", popup, WaveToList(":DB:DB_mols", ";")
	prompt res, "Which result wave?", popup, "ret;start;stop;height;area;resp;flagMan;flagBad"
	prompt useAS, "Use AS or reset the whole wave?", popup, "Use current AS;Reset whole result wave"

	ResetOneResWavesUsingAS( mol, res, useAS )
	
end

function ResetOneResWavesUsingAS( mol, res, useAS )
	string mol, res
	variable useAS
	
	variable ch = ReturnChannel(mol)
	variable i, ResRow
	wave AS = $("root:AS:CH" + num2str(ch) + "_AS")
	
	wave resWv = $("root:" + mol + "_" + res )
	
	if (useAS == 1)
		do
			ResRow = ReturnResRowNumber( ch, AS[i] )
			resWv[ResRow] = NaN
			i += 1
		while( i < numpnts(AS) )
	else
		resWv = NaN
	endif
	
end

function DeletePeakResWaves( mol )
	string mol
	
	String savedf = GetDataFolder(1)
	
	SetDataFolder root:
	
	string ret = mol + "_ret"
	string start = mol + "_start"
	string stop = mol + "_stop"
	string height = mol + "_height"
	string are = mol + "_area"
	string resp = mol + "_resp"
	string man = mol + "_flagMan"
	string bad = mol + "_flagBad"

	killwaves /Z $ret, $start, $stop, $height, $are, $resp, $man, $bad
	
	SetDataFolder savedf
	
end
