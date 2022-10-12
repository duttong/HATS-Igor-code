#pragma rtGlobals=1		// Use modern global access method.

proc SyncStations( mol, CATSonly )
	string mol = G_mol 
	variable CATSonly = 1
	prompt mol, "Molecule?", popup, G_molLst
	prompt CATSonly, "Which data set?", popup, "CATS only;CATS and RITS"

	SyncStationsFUNCT( mol, CATSonly )
end


function SyncStationsFUNCT( mol, CATSonly )
	string mol
	variable CATSonly
	
	string twavestr = mol + "_time_mo"
	string N = mol + "_N"
	string Ntemp = mol + "_Ntemp"
	string Nt = mol + "_Ntrop"	
	string St = mol + "_Strop"	
	string S = mol + "_S"
	string Nsd = mol + "_N_sd"
	string Ntempsd = mol + "_Ntemp_sd"
	string Ntsd = mol + "_Ntrop_sd"
	string Stsd = mol + "_Strop_sd"	
	string Ssd = mol + "_S_sd"
	string win = mol + "syncTable"
	variable inc
	
	if ( CATSonly == 1 )
		wave brw = $("brw_" + mol)
		wave nwr = $("nwr_" + mol)
		wave mlo = $("mlo_" + mol)
		wave smo = $("smo_" + mol)
		wave spo = $("spo_" + mol)
	else
		wave brw = $("insitu_brw_" + mol)
		wave nwr = $("insitu_nwr_" + mol)
		wave mlo = $("insitu_mlo_" + mol)
		wave smo = $("insitu_smo_" + mol)
		wave spo = $("insitu_spo_" + mol)
	endif
	
	DoWindow/K $win
	
	make/o/n=(19*12)/d $twavestr = nan
	SetScale d 0,0,"dat", $twavestr
	wave twave = $twavestr
	
	make /o/n=(19*12) $N=nan, $Nt=nan, $St=nan, $S=nan, $Nsd=nan, $Ntsd=nan, $Stsd=nan, $Ssd=nan, $Ntemp=nan, $Ntempsd=nan
	
	Filltimewave( mol )
	
	FillRegionWvs( mol, brw, $N )
	FillRegionWvs( mol, brw, $Ntemp )
	FillRegionWvs( mol, mlo, $Nt )
	FillRegionWvs( mol, smo, $St )
	FillRegionWvs( mol, spo, $S )

	wave waveN = $N		; wave waveNtemp = $Ntemp
	wave waveNsd = $Nsd	; wave waveNtempsd = $Ntempsd
	wave waveNt = $Nt
	wave waveNtsd = $Ntsd
	wave waveSt = $St
	wave waveStsd = $Stsd
	wave waveS = $S
	wave waveSsd = $Ssd
	
	waveN = (waveN * cos(71.3 * Pi / 180) + waveNtemp * cos(40.04 * Pi / 180)) / (cos(71.3 * Pi / 180) + cos(40.04 * Pi / 180))
	waveNsd = sqrt((waveNsd * cos(71.3 * Pi / 180))^2 + (waveNtempsd * cos(40.04 * Pi / 180))^2) / (cos(71.3 * Pi / 180) + cos(40.04 * Pi / 180))
	
	killwaves waveNtemp, waveNtempsd
	
	// Remove leading Nan's
	inc = 0
	do
		if ( ( numtype(waveN[inc]) == 2 ) * ( numtype(waveNt[inc]) == 2 ) * ( numtype(waveSt[inc]) == 2 ) * ( numtype(waveS[inc]) == 2 ) )
			inc += 1
		else
			break
		endif
	while (inc < numpnts(waveN))
	DeletePoints 0, inc, twave, waveN, waveNsd, waveNt, waveNtsd, waveSt, waveStsd, waveS, waveSsd

	string com
	sprintf com, "Edit/W=(5,44,883,801) %s,%s,%s,%s,%s,%s,%s,%s,%s", twavestr, N, Nsd, Nt, Ntsd, St, Stsd, S, Ssd
	execute com
	sprintf com, "ModifyTable format(%s)=6", twavestr
	execute com

	DoWindow/C $win
	
end

function FilltimeWave( mol ) 
	string mol

	wave twave = $mol + "_time_mo"
	
	variable inc, minc = 1, yinc = 1986, dinc = 15
	
	do
		twave[inc] = date2secs(yinc, minc, dinc)
		minc += 1
		if ( minc > 12 )
			minc = 1
			yinc += 1
		endif
		inc += 1
	while (( yinc < 2005))
	
end

function FillRegionWvs( mol, srcwv, destwv )
	string mol
	wave srcwv, destwv
	
	wave srcsd = $(NameofWave(srcwv) + "_sd")
	wave desttime = $(mol + "_time_mo")
	wave destsd = $(NameofWave(destwv) + "_sd")

	if ( exists(NameofWave(srcwv) + "_date") == 1 )
		wave srctime = $(NameofWave(srcwv) + "_date")
	else
		wave srctime = $(NameofWave(srcwv) + "_time")
	endif
	
	variable inc, pt
	do
		pt = BinarySearchInterp(desttime, srctime[inc])
		destwv[pt] = srcwv[inc]
		destsd[pt] = srcsd[inc]
		inc += 1
	while (inc < numpnts(srcwv))
	
end
