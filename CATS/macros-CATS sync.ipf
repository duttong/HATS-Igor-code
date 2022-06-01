#pragma rtGlobals=1		// Use modern global access method.

// function uses the G_dur variable (set in load_DataFUNCT) to determine
// which data folder should be selected.
function/S CATSdataFolder( set )
	variable set

	SetDataFolder root:
	
	NVAR dur = G_dur
	string DF
	
	String /G root:S_dur = "monthly"
	SVAR Sdur = root:S_dur

	if (dur==1)
		DF = "root:hour"
		Sdur = "hourly"
	elseif (dur==2)
		DF = "root:day"
		Sdur = "daily"
	elseif (dur==3)
		DF = "root:week"
		Sdur = "weekly"
	elseif (dur==4)
		DF = "root:month"
		Sdur = "monthly"
	else
		abort "Bad duration: " + num2str(dur)
	endif

	if ( !DataFolderExists(DF))
		NewDataFolder $DF
	endif
	
	if ( set )
		SetDataFolder DF
	endif
	
	return DF + ":"

end

function UnifiedTimeBase(site)
	string site
	
	NVAR dur = root:G_dur
	CATSdataFolder( 1 )
	
	// mols to pull time waves from
	string mols = "N2O;F11;SF6;HCFC22;H1211a;H1211;F12"
	string moltime, wvlist = "", cmd
	variable i, j
	
	string timeUN = site + "_time"
	
	if ( dur != 4 )
		
		for(i=0; i<ItemsInList(mols, ";"); i+=1)
			moltime = site + "_" + StringFromList(i, mols) + "_time"
			if (exists(moltime) == 1)
				wvlist += moltime + ","
			endif
		endfor
		wvlist = wvlist[0, strlen(wvlist)-2]
		
		cmd = "Concatenate /O { " + wvlist + " }, tttemp"
		Execute cmd
		Wave tttemp
		Sort tttemp, tttemp
		//FindDuplicates/RN=$timeUN tttemp  // FindDuplicates is really slow Extract is faster
		
		// save last point to include after the extract statement
		variable lastpt = tttemp[numpnts(tttemp)-1]
		
		Extract /o tttemp, $timeUN, tttemp[p] != tttemp[p+1]
		wave UNtime = $timeUN
		InsertPoints numpnts(UNtime),1, UNtime
		UNtime[numpnts(UNtime)-1] = lastpt
		SetScale d 0,0,"dat", UNtime
		killwaves tttemp
		
	else		/// monthly means
		variable y = 1998
		make /d/o/n=((ReturnCurrentYear()-y+1)*12) $timeUN = Nan
		wave timeUNwv = $timeUN
		SetScale d 0,0,"dat", timeUNwv

		j = 1
		for (i=0; i<numpnts(timeUNwv); i+=1)
			timeUNwv[i] = date2secs(y, j, 15)
			j += 1
			if ( j > 12)
				j = 1
				y += 1
			endif
		endfor
	
	endif

	SetDataFolder root:
	
end

function mol2UnifiedTime(site, mol)
	string site, mol
	
	CATSdataFolder( 1 )
	
	if (! WaveExists($site + "_time") )
		SetDataFolder root:
		return 0
	endif

	if (! WaveExists($site + "_" + mol) )
		SetDataFolder root:
		return 0
	endif
	
	wave t = $site + "_time"			// unified time
	string mStr = site + "_" + mol
	wave m = $mStr
	string mTstr = site + "_" + mol + "_time"
	wave mT = $mTstr
	string sdStr = site + "_" + mol + "_sd"
	wave sd = $sdStr
	string varStr = site + "_" + mol + "_Var"
	wave /Z var = $varStr
	String numStr = site + "_" + mol + "_num"
	wave /Z num = $numStr
	string portStr = site + "_" + mol + "_port"
	wave /Z port = $portStr
	
	Make /FREE/n=(numpnts(t)) out = NaN, out_sd = NaN, out_num = NaN, out_port = NaN, out_var = NaN
	
	variable i, pt
	
	// much faster to remove the WaveExists check from inside the for loop	
	if ((WaveExists(num)) && (WaveExists(port)))	// hourly data
		for (i=0; i<numpnts(mT); i+=1)
			pt = BinarySearch(t, mT[i])
			out[pt] = m[i]
			out_sd[pt] = sd[i]
			out_num[pt] = num[i]
			out_port[pt] = port[i]
		endfor
	elseif ((WaveExists(num)) && (!WaveExists(port)))	
		for (i=0; i<numpnts(mT); i+=1)
			pt = BinarySearch(t, mT[i])
			out[pt] = m[i]
			out_sd[pt] = sd[i]
			out_num[pt] = num[i]
			if (WaveExists(var) == 0)  // this code is temporary (180924).  Needed until all _var wave are created
				out_var[pt] = Nan
			else
				out_var[pt] = var[i]
			endif
		endfor
	elseif ((!WaveExists(num)) && (WaveExists(port)))
		for (i=0; i<numpnts(mT); i+=1)
			pt = BinarySearch(t, mT[i])
			out[pt] = m[i]
			out_sd[pt] = sd[i]
			out_port[pt] = port[i]
		endfor
	else
		for (i=0; i<numpnts(mT); i+=1)
			pt = BinarySearch(t, mT[i])
			out[pt] = m[i]
			out_sd[pt] = sd[i]
		endfor
	endif
	
	// overwrites old
	duplicate /o out, $mStr
	duplicate /o out_sd, $sdStr
	if (exists(varstr) == 1)
		duplicate /o out_var, $varStr
	endif
	if (exists(numstr) == 1)
		duplicate /o out_num, $numStr
	endif
	if (exists(portstr) == 1)
		duplicate /o out_port, port
	endif
	
	// kill the un-unified time wave
	Killwaves /Z mT
	
	SetDataFolder root:
	return 1
	
end

// function syncs a site to use a single time wave.
function TimeSyncCATSdata(site)
	string site
	
	string DF = CATSdataFolder( 1 )
	
	SVAR mols = root:G_molLst
	
	variable i
	string mol
	
	UnifiedTimeBase(site)

	wave t = $DF + site + "_time"

	Print "Syncing " + site + " data"
	for (i=0; i<ItemsInList(mols); i+=1)
		mol = StringFromList(i, mols)
		mol2UnifiedTime(site, mol)
	endfor
	
	SetDataFolder root:
	
end