#pragma rtGlobals=1		// Use modern global access method.

#include "macros-utilities"
#include "macros-strings and lists"

static constant TWO_INJS = 3600		// seconds 
static constant FOUR_INJS = 7200		// seconds 
static constant SIX_INJS = 10800
static constant EIGHT_INJS = 14400
static constant TWELVE_INJS = 21600


function loadStandardsFile()

	SetDataFolder root:
	SVAR site = G_site3
	
	SVAR ALM_list = ALM_list
	if (exists("ALM_list") != 2)
		string /g ALM_list = " "
	endif
	
	GetFileFolderInfo /Q/Z "Hats:gc:cats_results:stand"
	if (V_Flag == 0)
		// office computer
		NewPath /Q/O Standards, "Hats:gc:cats_results:stand"
	else
		GetFileFolderInfo /Q/Z "gdutton:stand:"
		if (V_Flag == 0)
			// home computer
			NewPath/O/Q Standards "gdutton:stand"
		else
			abort "Can't set Stasndards path"
		endif
	endif

	string file = "standards." + site
	LoadWave/Q/A/J/D/K=2/V={" "," $",0,1}/L={0,15,0,0,0}/P=Standards file
	
	duplicate /t/o wave0 ALMs
	Twave2Swave(wave1, "ALM_N2O")
	Twave2Swave(wave2, "ALM_SF6")
	Twave2Swave(wave4, "ALM_F12")
	Twave2Swave(wave5, "ALM_H1211")
	Twave2Swave(wave6, "ALM_F11")
	Twave2Swave(wave7, "ALM_F113")
	Twave2Swave(wave12, "ALM_CHCl3")
	Twave2Swave(wave13, "ALM_MC")
	Twave2Swave(wave14, "ALM_CCl4")
	Twave2Swave(wave15, "ALM_TCE")
	Twave2Swave(wave16, "ALM_H1301")
	Twave2Swave(wave17, "ALM_OCS")
	Twave2Swave(wave18, "ALM_HCFC22")
	Twave2Swave(wave19, "ALM_CH3Cl")
	Twave2Swave(wave21, "ALM_HCFC142b")
	Twave2Swave(wave22, "ALM_CH3Br")

	// For duplicate mols on other channels
	duplicate /t/o ALM_F11 ALM_F11a
	duplicate /t/o ALM_F113 ALM_F113a
	duplicate /t/o ALM_N2O ALM_N2Oa
	duplicate /t/o ALM_H1211 ALM_H1211a
	duplicate /t/o ALM_H1211 ALM_H1211cc
	duplicate /t/o ALM_F12 ALM_F12cc
	duplicate /t/o ALM_F12 ALM_F12f
	
	execute "bat(\"killwaves @\", \"wave*\")"
	
	FlattenRight(ALMs)
//	FlattenRight(ALM_site)
//	FlattenRight(ALM_HorL)
//	FlattenRight(ALM_start_date)
//	FlattenRight(ALM_end_date)
	
	ALM_list = WaveToList("ALMs", ";")
	
	// LoadDriftTables()
	
end

function loadStandardsFile_sum()

	SetDataFolder root:
	
	SVAR ALM_list = ALM_list
	if (exists("ALM_list") != 2)
		string /g ALM_list = " "
	endif
	
	NewPath/O/Q Standards "gdutton:stand:"
	string file = "standards.sum"
	LoadWave/Q/A/J/D/K=2/V={" "," $",0,1}/L={0,15,0,0,0}/P=Standards file

	duplicate /t/o wave0 ALMs
	Twave2Swave(wave1, "ALM_H2")
	Twave2Swave(wave2, "ALM_CH4")
	Twave2Swave(wave3, "ALM_CO")

	Twave2Swave(wave4, "ALM_N2O")
	Twave2Swave(wave17, "ALM_SF6")
	
	Twave2Swave(wave5, "ALM_F12")
	Twave2Swave(wave6, "ALM_H1211")
	Twave2Swave(wave7, "ALM_F11")
	Twave2Swave(wave8, "ALM_F113")
	Twave2Swave(wave13, "ALM_CHCl3")
	Twave2Swave(wave14, "ALM_MC")
	Twave2Swave(wave15, "ALM_CCl4")

	// For duplicate mols on other channels
	duplicate /t/o ALM_F11 ALM_F11a
	duplicate /t/o ALM_F113 ALM_F113a
	duplicate /t/o ALM_H1211 ALM_H1211a
	duplicate /t/o ALM_F12 ALM_F12f
	
	execute "bat(\"killwaves @\", \"wave*\")"
	
	FlattenRight(ALMs)
//	FlattenRight(ALM_site)
//	FlattenRight(ALM_HorL)
//	FlattenRight(ALM_start_date)
//	FlattenRight(ALM_end_date)
	
	ALM_list = WaveToList("ALMs", ";")
	
//	LoadDriftTables()
	
end

function loadTDF_StandardsFile()

	SVAR ALM_list = ALM_list
	if (exists("ALM_list") != 2)
		string /g ALM_list = " "
	endif
	
	LoadWave/Q/A/J/D/K=2/V={" "," $",0,1}/L={21,24,0,0,0} "Macintosh HD:data:CATS (STEALTH):Argentina:standards"
	
	duplicate /t/o wave0 ALMs
	Twave2Swave(wave1, "ALM_N2O")
	Twave2Swave(wave2, "ALM_SF6")
	Twave2Swave(wave3, "ALM_F12")
	Twave2Swave(wave4, "ALM_H1211")
	Twave2Swave(wave5, "ALM_F11")
	Twave2Swave(wave6, "ALM_F113")
	Twave2Swave(wave7, "ALM_CHCl3")
	Twave2Swave(wave8, "ALM_MC")
	Twave2Swave(wave9, "ALM_CCl4")

//	duplicate /t/o wave10 ALM_site
//	duplicate /t/o wave11 ALM_HorL
//	duplicate /t/o wave12 ALM_start_date
//	duplicate /t/o wave14 ALM_end_date
	
	execute "bat(\"killwaves @\", \"wave*\")"
	
	FlattenRight(ALMs)
//	FlattenRight(ALM_site)
//	FlattenRight(ALM_HorL)
//	FlattenRight(ALM_start_date)
//	FlattenRight(ALM_end_date)
	
	ALM_list = WaveToList("ALMs", ";")	
	
end


// Text wave to sigle precision wave
function Twave2Swave(inwv, outwv)
	wave /t inwv
	string outwv
	
	if (exists(outwv) == 1)
		killwaves /z $outwv
	endif
	make /o/n=(numpnts(inwv)) $outwv
	
	wave out = $outwv
	out = str2num(inwv)
	
	// replace -99 with NaN
	out = SelectNumber(out <= -99, out, NaN)
end

// Function loads data for cal tank drift corrections
function LoadDriftTables()

	NVAR G_remakeStdWVs =  G_remakeStdWVs 
	 G_remakeStdWVs = 1
	 
	LoadWave/Q/J/D/K=0/A=drift/V={","," $",0,0}/R={English,1,3,2,2,"DayOfMonth-Month-Year",40} "HOME:stand:drift.CH3Br"
	duplicate /t/o drift0 CH3Br_tank
	duplicate /o drift1 CH3Br_D1
	duplicate /o drift2 CH3Br_MR1
	duplicate /o drift3 CH3Br_D2
	duplicate /o drift4 CH3Br_MR2
	duplicate /o drift4 CH3Br_tankind
	gReplace(CH3Br_MR1, -99, nan)
	gReplace(CH3Br_MR2, -99, nan)
	CH3Br_tankind = p
	killwaves drift0, drift1, drift2, drift3, drift4
	CH3Br_tank = ReplaceString(" ", CH3Br_tank, "")

	LoadWave/Q/J/D/K=0/A=drift/V={","," $",0,0}/R={English,1,3,2,2,"DayOfMonth-Month-Year",40} "HOME:stand:drift.CH3Cl"
	duplicate /t/o drift0 CH3Cl_tank
	duplicate /o drift1 CH3Cl_D1
	duplicate /o drift2 CH3Cl_MR1
	duplicate /o drift3 CH3Cl_D2
	duplicate /o drift4 CH3Cl_MR2
	duplicate /o drift4 CH3Cl_tankind
	gReplace(CH3Cl_MR1, -99, nan)
	gReplace(CH3Cl_MR2, -99, nan)
	CH3Cl_tankind = p
	killwaves drift0, drift1, drift2, drift3, drift4
	CH3CL_tank = ReplaceString(" ", CH3CL_tank, "")

//	LoadWave/Q/J/D/K=0/A=drift/V={","," $",0,0}/R={English,1,3,2,2,"DayOfMonth-Month-Year",40} "Hats:gc:config:stealth:drift.CHCl3"
//	duplicate /t/o drift0 CHCl3_tank
//	duplicate /o drift1 CHCl3_D1
//	duplicate /o drift2 CHCl3_MR1
//	duplicate /o drift3 CHCl3_D2
//	duplicate /o drift4 CHCl3_MR2
//	duplicate /o drift4 CHCl3_tankind
//	gReplace(CHCl3_MR1, -99, nan)
//	gReplace(CHCl3_MR2, -99, nan)
//	CHCl3_tankind = p
//	killwaves drift0, drift1, drift2, drift3, drift4
//	CHCl3_tank = ReplaceString(" ", CHCl3_tank, "")

end

function /t index2tank(mol, index )
	string mol
	variable index

	if ( index < 0 )
		return "none"
	endif

	wave /t tank = $(mol + "_tank")
	wave ind = $(mol + "_tankind")
	variable loc = BinarySearch( ind, index )
	
	return tank[loc]

end

function tank2index (mol, tank )
	string mol, tank

	wave /t tanklst = $(mol + "_tank")
	wave  ind = $(mol + "_tankind")
	variable inc = 0
	
	do
		if (strsearch(tanklst[inc], tank, 0) != -1)
			return inc
		endif
		inc += 1
	while (inc < numpnts(ind))
	
//	print tank + " not found in tank list"
	return -1

end

	
// Removes all spaces to the right of the string 
function flattenRight(inwv)
	wave /t inwv
	
	string elem
	variable inc = 0, last
	
	duplicate /o/t inwv ttttwv
	
	do
		elem = inwv[inc]
		last = strsearch(elem, " ", 0)-1
		if (last > 0 )
			ttttwv[inc] = elem[0, last]
		endif
		inc += 1
	while (inc < numpnts(inwv))
	
	inwv = ttttwv
	
	killwaves ttttwv
	
end

proc MakeSiteTable(site, mol)
	string site=G_site3
	string mol=G_loadMol
	prompt mol, "Molecule", popup, G_loadMol

	silent 1
	
	loadStandardsFile(site)
	MakeSiteTableFUNCT(site, mol)
end

function MakeSiteTableFUNCT(site, mol)
	string site, mol
	
	SVAR G_loadMol
	string stdfile
	
	// work computer
	GetFileFolderInfo /Q/Z "Macintosh HD:Users:gdutton:Data:CATS:Data Processing:CATS Standards Tables.pxp"
	if (V_flag == 0)
		stdfile = "Macintosh HD:Users:gdutton:Data:CATS:Data Processing:CATS Standards Tables.pxp"
	else
		stdfile = "Macintosh HD:Users:geoff:CATS:Data Processing:CATS Standards Tables.pxp"
	endif
	
	string siteWv, currH= "", currL = "", val, val2
	string lstd = site + "_lstd"
	string hstd = site + "_hstd"
	string day = site + "_ALMdates"
	string SX = site + "_SX"
	string SXday = site + "_SXdates"
	string tbl = site + "_cal_calc_table"
	
	string mollst = ""
	variable inc=0
	do
		mol = StringFromList(inc, G_loadMol)
		if (stringmatch(mol, "*comb") != 1)
			mollst = AddListItem(mol, mollst)
		endif
		inc += 1
	while (inc < itemsinlist(G_loadMol))
	
	// change method cal12str to cal12 (130215) can remove this code after all experiments have been loaded.
	for(inc=0; inc<ItemsinList(G_loadMol); inc+=1)
		Wave/Z/T bestw = $(StringFromList(inc, G_loadMol) + "_best")
		if (WaveExists(bestw))
			bestw = SelectString(cmpstr(bestw, "cal12str")==0, bestw, "cal12")
		endif
	endfor	
	
	// Load stanard table waves.
	LoadData /q/o /j=day stdfile
	LoadData /q/o /j=lstd stdfile
	LoadData /q/o /j=hstd stdfile
	LoadData /q/o /j=SX stdfile
	LoadData /q/o /j=SXday stdfile

	wave /t lwv = $lstd
	wave /t hwv = $hstd
	wave /t dayWv = $day

	// Make table
	
	DoWindow /K $tbl
	Edit/K=1/W=(1515,52,2488,645) dayWv, lwv, hwv
	//Edit/K=1/W=(351,63,1324,656)  dayWv, lwv, hwv
	execute "lbat(\"appendtotable @_best\", \"" + mollst + "\")"
	execute "lbat(\"appendtotable @_offset\", \"" + mollst + "\")"
	execute "ModifyTable width(" + day + ")=115"
	MOdifyTable topLeftCell=(numpnts(dayWv),0)
	DoWindow /C $tbl
	
end


// Returns time in seconds from date string:  YYYYMMDD.HHMM
function/d date_return(day)
	string day
	
	if ( (cmpstr(day, "not") == 0) + (cmpstr(day, "yet") == 0) + (cmpstr(day, "offline") == 0) )
		return 0
	endif
	
	if ( (cmpstr(day, "current") == 0) )
		return 1
	endif
	
	variable /d secs
	
	if (strlen(day) == 8)
		// only date used no hhss
		secs = date2secs( str2num(day[0,3]),str2num(day[4,5]),str2num(day[6,7]))
	else
		secs = date2secs( str2num(day[0,3]),str2num(day[4,5]),str2num(day[6,7])) + str2num(day[9,10])*60*60 +  str2num(day[11,12])*60
	endif
	
	return secs
	
end

// opposite of date_return function
function/s dateS_return(secs)
	variable secs
	
	string YYYY = num2str(str2num(StringFromList(2, Secs2Date(secs, 2), ",")))
	string MM = (StringFromList(1, Secs2Date(secs, -1), "/"))
	string DD = (StringFromList(0, Secs2Date(secs, -1), "/"))
	string HH = (StringFromList(0, Secs2Time(secs, 2), ":"))
	string MN = (StringFromList(1, Secs2Time(secs, 2), ":"))
	
	return YYYY + MM + DD + "." + HH + MN
	
end

// Returns the mixing ratio assigned to a certain tank for a givin molecule.
function GetALMconc(mol, tank)
	string mol, tank

	SVAR ALM_list = root:ALM_list
	
	// combined data being used
	if (stringmatch(mol, "*comb") == 1)
		mol = mol[0, strlen(mol)-5]
	endif

	wave molWv = $("root:ALM_" + mol)

	if (cmpstr(tank, "") == 0)
		return NaN
	endif
	
	variable row = ReturnListPosition(ALM_list, tank, ";")
	
	if (row == -1)
		return NaN
	else
		return SelectNumber(molWv[row] < 0, molWv[row], NaN)
	endif
end

// function returns which hstd or lstd is on at time secs
// 070425
function/t ReturnTank(secs, HorL)
	variable /d secs
	variable HorL

	SVAR site = root:G_site3

	wave /t ALMdates = $"root:" + site + "_ALMdates"
	wave /t lstd = $"root:" + site + "_lstd"
	wave /t hstd = $"root:" + site + "_hstd"

	make /FREE/d/o/n=(numpnts(ALMdates)) ALMdatesSECS = date_return(ALMdates)
		
	if ( HorL == 1 )
		wave /t std = hstd
	else
		wave /t std = lstd
	endif

	variable pt = BinarySearch(ALMdatesSECS,  secs)
	string tank
	
	if ( pt == -1 ) 
		tank = "" 
	elseif ( pt == -2 )
		pt = numpnts(ALMdates)-1
		tank = std[pt]
	else
		tank = std[pt]
	endif

	return tank
	
end


// Generates a time depedent set of waves with the cal tank mixing ratios.
// replaced the findlevel function with BinarySearch (haven't tested a bunch 130312)
function MakeStandardWaves(mol, doremake)
	string mol
	variable doremake
	
	if ((exists("G_remakeStdWVs") == 0 ) || ( doremake == 1 ))
		variable /g G_remakeStdWVs = 1
	endif
	
	NVAR remake = G_remakeStdWVs
	SVAR site = G_site3
	
	wave day = $(mol + "_date")
	string lstdC = mol + "_lstd_conc"
	string hstdC = mol + "_hstd_conc"
	string workdate
	variable YYYY, MM, DD, HH, MN, levelX, oldLevelX, tankind
	variable /d level
	wave /t lstd = $(site + "_lstd")
	wave /t hstd = $(site + "_hstd")
	wave /t stddate = $(site + "_ALMdates")
	variable inc=0, drift = 0, val
	
	if ( numpnts($lstdC) == numpnts(day) )
		remake = 1
	endif

	if ( remake == 0 )
		return 0
	endif
	
	make /o/n=(numpnts(day)) $lstdC/Wave=lstdCwv=NaN, $hstdC/Wave=hstdCwv=NaN
		
	// Determine whether to drift correct the cal data
	if ((cmpstr(mol,"ch3br")==0) + (cmpstr(mol,"ch3cl")==0))
		drift = 1
	endif

	// No drift correction needed
	if  ( drift == 0 )
		oldLevelX = 0
		for(inc=0; inc<numpnts(stddate); inc+=1)
			level = date_return(stddate[inc])
			levelX = BinarySearch(day, level)
			
			if (inc > 0)
				val = SelectNumber(cmpstr(lstd[inc-1], "off")==0, GetALMconc(mol, lstd[inc-1]), GetALMconc(mol, lstd[inc-2]))
				lstdCWv[oldLevelX, levelX] = val

				val = SelectNumber(cmpstr(hstd[inc-1], "off")==0, GetALMconc(mol, hstd[inc-1]), GetALMconc(mol, hstd[inc-2]))
				hstdCWv[oldLevelX, levelX] = val
			endif
			oldLevelX = levelX
		endfor
			
		if (level < day[numpnts(day)])
			val = SelectNumber(cmpstr(lstd[inc-1], "off")==0, GetALMconc(mol, lstd[inc-1]), GetALMconc(mol, lstd[inc-2]))
			//print inc, val, levelX, GetALMconc(mol, lstd[inc-1]), mol, lstd[inc-1]
			lstdCWv[levelX,] = val
	
			val = SelectNumber(cmpstr(hstd[inc-1], "off")==0, GetALMconc(mol, hstd[inc-1]), GetALMconc(mol, hstd[inc-2]))
			hstdCWv[levelX,] = val
		endif
	
	// Drift correction used.	
	else
		
		make /FREE/o/n=(numpnts(day)) ttmpl, ttmph
	
		if ( cmpstr(mol,"ch3cl") == 0 ) 
			lstdCWv = ConstantMolarDrift(mol, day, 0)
			hstdCWv = ConstantMolarDrift(mol, day, 1)
		else
			oldLevelX = 0
			for(inc=0; inc<numpnts(stddate); inc+=1)
				level = date_return(stddate[inc])
				levelX = BinarySearch(day, level)
				
				if (inc > 0)
					if (cmpstr(lstd[inc-1], "off") == 0)
						val = GetALMconc(mol, lstd[inc-2])
						tankind = tank2index(mol, lstd[inc-2])
					else
						val = GetALMconc(mol, lstd[inc-1])
						tankind = tank2index(mol, lstd[inc-1])
					endif	
					lstdCWv[oldLevelX, levelX] = val
					ttmpl[oldLevelX, levelX] = tankind
					
					if (cmpstr(hstd[inc-1], "off") == 0)
						val = GetALMconc(mol, hstd[inc-2])
						tankind = tank2index(mol, hstd[inc-2])
					else
						val = GetALMconc(mol, hstd[inc-1])
						tankind = tank2index(mol, hstd[inc-1])
					endif
					hstdCWv[oldLevelX, levelX] = val
					ttmph[oldLevelX, levelX] = tankind
				endif
				oldLevelX = levelX
			endfor
			
			if (level <  day[numpnts(day)])
				if (cmpstr(lstd[inc-1], "off") == 0)
					val = GetALMconc(mol, lstd[inc-2])
					tankind = tank2index(mol, lstd[inc-2])
				else
					val = GetALMconc(mol, lstd[inc-1])
					tankind = tank2index(mol, lstd[inc-1])
				endif	
				lstdCWv[levelX,] = val
				ttmpl[levelX,] = tankind
		
				if (cmpstr(hstd[inc-1], "off") == 0)
					val = GetALMconc(mol, hstd[inc-2])
					tankind = tank2index(mol, hstd[inc-2])
				else
					val = GetALMconc(mol, hstd[inc-1])
					tankind = tank2index(mol, hstd[inc-1])
				endif
				hstdCWv[levelX,] = val
				ttmph[levelX,] = tankind
			endif
			
			print "Working on DRIFT low standards"
			make /FREE/o/n=(numpnts(lstdCwv)) MRwvtmp = nan
	
			EstimateCal(mol, ttmpl, day, 0)
			lstdCwv = MRwvtmp
	
			print "Working on DRIFT high standards"
			EstimateCal(mol, ttmph, day, 0)
			hstdCwv = MRwvtmp
			
		endif
			
	endif
	
	
	// if SPO and F11 shift low standard
	if (cmpstr(site, "spo") == 0)
		//if ((cmpstr(mol, "F11a") == 0) || (cmpstr(mol, "F11") == 0))
			lstdCwv[BinarySearchInterp(day, date2secs(2002,2,1)), BinarySearchInterp(day, date2secs(2006,1,1))] *= 0.98
		//endif
	endif
	
	remake = 0
		
end


// Same as above function but also applies an adjustment to the assigned mixing ratios.
// used in the genalgo section
//function MakeStandardWaves_addjust(mol)
	string mol
	
	SVAR site = G_site3
	
	wave day = $(mol + "_date")
	string lstdC = mol + "_lstd_conc"
	string hstdC = mol + "_hstd_conc"
	string workdate
	variable YYYY, MM, DD, HH, MN, levelX, oldLevelX
	variable /d level
	wave /t lstd = $(site + "_lstd")
	wave /t hstd = $(site + "_hstd")
	wave /t stddate = $(site + "_ALMdates")
	variable inc=0
	
	make /o/n=(numpnts(day)) $lstdC=NaN, $hstdC=NaN
	wave lstdCwv = $lstdC
	wave hstdCwv = $hstdC
	
	oldLevelX = 0
	do
		workdate = stddate[inc]
		YYYY = str2num(workdate[0,3])
		MM = str2num(workdate[4,5])
		DD = str2num(workdate[6,7])
		HH = str2num(workdate[9,10])
		MN = str2num(workdate[11,12])

		level = date2secs(YYYY, MM, DD) + HH*60*60 + MN*60
		if (level <= day[0])
			levelX = 0
		else
		if (level >= day[numpnts(day)])
			levelX = numpnts(day)
		else
			findlevel /Q day, level
			levelX = V_levelX
		endif
		endif
		
		variable/d val, del_val
		if (inc > 0)
			if (cmpstr(lstd[inc-1], "off") == 0)
				val = GetALMconc(mol, lstd[inc-2])
				del_val = return_adjust(mol, lstd[inc-2])
			else
				val = GetALMconc(mol, lstd[inc-1])
				del_val = return_adjust(mol, lstd[inc-1])
			endif	
			lstdCWv[oldLevelX, levelX] = val + del_val
			
			if (cmpstr(hstd[inc-1], "off") == 0)
				val = GetALMconc(mol, hstd[inc-2])
				del_val = return_adjust(mol, hstd[inc-2])
			else
				val = GetALMconc(mol, hstd[inc-1])
				del_val = return_adjust(mol, hstd[inc-1])
			endif
			hstdCWv[oldLevelX, levelX] = val + del_val
		endif
		oldLevelX = levelX
		
		inc += 1
	while (numpnts(stddate) != inc)

	if (level <  day[numpnts(day)])
		if (cmpstr(lstd[inc-1], "off") == 0)
			val = GetALMconc(mol, lstd[inc-2])
			del_val = return_adjust(mol, lstd[inc-2])
		else
			val = GetALMconc(mol, lstd[inc-1])
			del_val = return_adjust(mol, lstd[inc-1])
		endif	
		lstdCWv[levelX,] = val + del_val

		if (cmpstr(hstd[inc-1], "off") == 0)
			val = GetALMconc(mol, hstd[inc-2])
			del_val = return_adjust(mol, hstd[inc-2])
		else
			val = GetALMconc(mol, hstd[inc-1])
			del_val = return_adjust(mol, hstd[inc-1])
		endif
		hstdCWv[levelX,] = val + del_val
	endif
	
end

// Returns the adjustment value for a given tank.
function/d return_adjust(mol, tank)
	string mol, tank
	
	wave/t tankwv = $"tankwv"
	wave adj = $(mol + "_adjust")
	variable num = numpnts(adj), inc = 0
	variable /d adjust = 0
	
	do
		if (cmpstr(tank, tankwv[inc]) == 0)
			adjust = adj[inc]
			return adjust
		endif
		inc += 1
	while (inc < num)
	
	// if not found return 0
	return 0
	
end




// **************  Conc methods  **********************//

// creates c1r and c2r 
Function CreateCalRatios(mol, attrib)
	string mol, attrib

	variable tol = 8*1800			// 8 injections

	CreateIterpCals(mol, attrib)

	wave c1, c1x, c1i, c1xi
	wave c2, c2x, c2i, c2xi
	
	// create cal- ratios for uncertainty calc.
	duplicate /o c1, c1r
	//c1r = c1[p]/(c1[p-1] + c1[p+1]) * 2
	c1r = c1i[BinarySearchInterp(c1xi, c1x[p])] / ( c1i[BinarySearchInterp(c1xi, c1x[p-1])] + c1i[BinarySearchInterp(c1xi, c1x[p+1])] ) * 2
	c1r = SelectNumber(c1x[p+1]-c1x[p] > tol, c1r, nan)
	c1r = SelectNumber((numtype(c1[p]) !=0) && (numtype(c1[p+1]) != 0), c1r, nan)
	
	duplicate /o c2, c2r
	//c2r = c2[p]/(c2[p-1] + c2[p+1]) * 2
	c2r = c2i[BinarySearchInterp(c2xi, c2x[p])] / ( c2i[BinarySearchInterp(c2xi, c2x[p-1])] + c2i[BinarySearchInterp(c2xi, c2x[p+1])] ) * 2
	c2r = SelectNumber(c2x[p+1]-c2x[p] > tol, c2r, nan)
	c2r = SelectNumber((numtype(c2[p]) !=0) && (numtype(c2[p+1]) != 0), c2r, nan)

	duplicate /o c2, c12r
	c12r = c1i[BinarySearchInterp(c1xi, c1x[p])] / ( c2i[BinarySearchInterp(c2xi, c2x[p-1])] + c2i[BinarySearchInterp(c2xi, c2x[p+1])] ) * 2
	c12r = SelectNumber(c2x[p+1]-c2x[p] > tol, c12r, nan)
	c12r = SelectNumber((numtype(c2[p]) !=0) && (numtype(c2[p+1]) != 0), c12r, nan)
	NaNEveryNDays(c12r, c2x, 4, 10)

	NaNEveryNDays(c1r, c1x, 4, 10)
	NaNEveryNDays(c2r, c2x, 4, 10)
	
	// first and last points are sometimes bad
	c1r[FirstGoodPt(c1r)] = NaN
	c2r[FirstGoodPt(c2r)] = NaN
	c1r[LastGoodPt(c1r)] = NaN
	c2r[LastGoodPt(c2r)] = NaN

end

// interpolates and smooths c1 and c2 data
Function CreateIterpCals(mol, attrib)
	string mol, attrib
	
	variable SMOOTHFACT = ReturnSmoothFactor()
	
	wave ssv = $(mol + "_port")
	wave day = $(mol + "_date")
	wave resp = $(mol + "_" + attrib)
	wave flag = $(mol + "_flag")

	Killwaves /Z c1i, c2i, c1xi, c2xi

	Extract /o resp, c1, (ssv == 2) && (numtype(flag)==0)
	Extract /o resp, c2, (ssv == 6) && (numtype(flag)==0)
	Extract /o day, c1x, (ssv == 2) && (numtype(flag)==0)
	Extract /o day, c2x, (ssv == 6) && (numtype(flag)==0)
	
	Variable num1 = (c1x[inf]-c1x[0])/(60*60*24) * 50
	Variable num2 = (c2x[inf]-c2x[0])/(60*60*24) * 50

	Interpolate2/T=1/N=(num1) /J=2/Y=c1i/X=c1xi c1x, c1
	Interpolate2/T=1/N=(num2) /J=2/Y=c2i/X=c2xi c2x, c2

	SetScale d 0,0,"dat", c1x,c2x,c1xi,c2xi

	// smooth the response
	Smooth SMOOTHFACT, c1i, c2i
	
	RemoveLargeGaps(c1, c1x, c1i, c1xi)
	RemoveLargeGaps(c2, c2x, c2i, c2xi)
	
end


// removes large interpolated gaps
Function RemoveLargeGaps(cL, cLx, cLi, cLxi)
	Wave cL, cLx, cLi, cLxi
	
	variable i, j, d1, d2, pt1, pt2
	variable numInjs = 13
	
	// looking for gaps of NaNs in cL
	for (i=0; i<numpnts(cL); i+=1)
		d1 = 0
		d2 = 0
		// find first NaN
		if (numtype(cL[i]) == 2)
			d1 = i
			// find the last NaN
			for(j=i+1; j<numpnts(cL); j+=1)
				if (numtype(cL[j]) == 0)
					d2 = j
					// is the gap larger than 13 injections
					if ((cLx[d2]-cLx[d1])/1800 > numInjs)
						// now NaN the large gap in the interpolated wave
						pt1 = BinarySearchInterp(cLxi, cLx[d1-1])
						pt2 = BinarySearchInterp(cLxi, cLx[d2])
						if (numtype(pt1) == 0)
							cLi[pt1, pt2] = NaN
						endif
					endif
					break
				endif
			endfor
			i = j
		endif
	endfor
	
	// large time gaps
	for (i=0; i<numpnts(cL); i+=1)
		if ((cLx[i+1]-cLx[i])/1800 > numInjs)
			pt1 = BinarySearchInterp(cLxi, cLx[i])
			pt2 = BinarySearchInterp(cLxi, cLx[i+1])
			cLi[pt1+1, pt2-1] = SelectNumber(numtype(pt1)==0, cLi, NaN)
		endif
	endfor
	
end

// new version takes advantage of SelectNumber
function conc_cal1(mol, attrib)
	string mol, attrib
	
	string MRst = mol + "_cal1_conc"

	Wave c1, c1x, c1xi, c1i
	variable tol = 4*1800

	wave day = $(mol + "_date")
	wave std = $(mol + "_lstd_conc")
	wave resp = $(mol + "_" + attrib)
	wave ssv = $(mol + "_port")

	// calculates mixing ratio from interpolated cal 1
	Make/o/n=(numpnts(day))/FREE c1i_full = c1i[BinarySearchInterp(c1xi, day)]
	MatrixOp /O $MRst/WAVE=MR = std * resp / c1i_full

	MR = SelectNumber((ssv==4)||(ssv==8), nan, MR)
	
	// If the air data is not bracketed by cal 1 data within the tol, remove.
	MR = SelectNumber((abs(c1x[BinarySearch(c1x, day)]-day) <= tol) && (abs(c1x[BinarySearch(c1x, day)+1]-day) <= tol), nan, MR)

end

// new version takes advantage of SelectNumber
function conc_cal2(mol, attrib)
	string mol, attrib
	
	string MRst = mol + "_cal2_conc"
	variable tol = 4*1800

	Wave c2, c2x, c2xi, c2i

	wave day = $(mol + "_date")
	wave std = $(mol + "_hstd_conc")
	wave resp = $(mol + "_" + attrib)
	wave ssv = $(mol + "_port")

	// calculates mixing ratio from interpolated cal 2
	Make/o/n=(numpnts(day))/FREE c2i_full = c2i[BinarySearchInterp(c2xi, day)]
	MatrixOp /O $MRst/WAVE=MR = std * resp / c2i_full

	MR = SelectNumber((ssv==4)||(ssv==8), nan, MR)

	// If the air data is not bracketed by cal 2 data within the tol, remove.
	MR = SelectNumber((abs(c2x[BinarySearch(c2x, day)]-day) <= tol) && (abs(c2x[BinarySearch(c2x, day)+1]-day) <= tol), nan, MR)
	
end

// hardcoded for area
function conc_cal2_area(mol, attrib)
	string mol, attrib
	
	string MRst = mol + "_cal2_area_conc"
	variable tol = 4*1800

	Wave c2, c2x, c2xi, c2i

	wave day = $(mol + "_date")
	wave std = $(mol + "_hstd_conc")
	wave resp = $(mol + "_" + "a")
	wave ssv = $(mol + "_port")

	// calculates mixing ratio from interpolated cal 2
	Make/o/n=(numpnts(day))/FREE c2i_full = c2i[BinarySearchInterp(c2xi, day)]
	MatrixOp /O $MRst/WAVE=MR = std * resp / c2i_full

	MR = SelectNumber((ssv==4)||(ssv==8), nan, MR)

	// If the air data is not bracketed by cal 2 data within the tol, remove.
	MR = SelectNumber((abs(c2x[BinarySearch(c2x, day)]-day) <= tol) && (abs(c2x[BinarySearch(c2x, day)+1]-day) <= tol), nan, MR)
	
end


// new version takes advantage of SelectNumber and MatrixOp
function conc_cal12(mol, attrib)
	string mol, attrib
	
	string MRst = mol + "_cal12_conc"
	variable tol = FOUR_INJS

	Wave c1, c1x, c1xi, c1i
	Wave c2, c2x, c2xi, c2i

	wave day = $(mol + "_date")
	wave hstd = $(mol + "_hstd_conc")
	wave lstd = $(mol + "_lstd_conc")
	wave resp = $(mol + "_" + attrib)
	wave ssv = $(mol + "_port")

	Make/o/n=(numpnts(day))/FREE c1i_full = c1i[BinarySearchInterp(c1xi, day)]
	Make/o/n=(numpnts(day))/FREE c2i_full = c2i[BinarySearchInterp(c2xi, day)]
	MatrixOp /O $MRst/WAVE=MR = lstd + (hstd-lstd) * (resp - c1i_full)/(c2i_full - c1i_full)

	MR = SelectNumber((ssv==4)||(ssv==8), nan, MR)
	
	// If the air data is not bracketed by cal 1 data within the tol, remove.
	MR = SelectNumber((abs(c1x[BinarySearch(c1x, day)]-day) <= tol) && (abs(c1x[BinarySearch(c1x, day)+1]-day) <= tol), nan, MR)
	// If the air data is not bracketed by cal 2 data within the tol, remove.
	MR = SelectNumber((abs(c2x[BinarySearch(c2x, day)]-day) <= tol) && (abs(c2x[BinarySearch(c2x, day)+1]-day) <= tol), nan, MR)

end

// cal12 hard coded for area
function conc_cal12_area(mol, attrib)
	string mol, attrib
	
	string MRst = mol + "_cal12_area_conc"
	variable tol = FOUR_INJS

	Wave c1, c1x, c1xi, c1i
	Wave c2, c2x, c2xi, c2i

	wave day = $(mol + "_date")
	wave hstd = $(mol + "_hstd_conc")
	wave lstd = $(mol + "_lstd_conc")
	wave resp = $(mol + "_a")
	wave ssv = $(mol + "_port")

	Make/o/n=(numpnts(day))/FREE c1i_full = c1i[BinarySearchInterp(c1xi, day)]
	Make/o/n=(numpnts(day))/FREE c2i_full = c2i[BinarySearchInterp(c2xi, day)]
	MatrixOp /O $MRst/WAVE=MR = lstd + (hstd-lstd) * (resp - c1i_full)/(c2i_full - c1i_full)

	MR = SelectNumber((ssv==4)||(ssv==8), nan, MR)
	
	// If the air data is not bracketed by cal 1 data within the tol, remove.
	MR = SelectNumber((abs(c1x[BinarySearch(c1x, day)]-day) <= tol) && (abs(c1x[BinarySearch(c1x, day)+1]-day) <= tol), nan, MR)
	// If the air data is not bracketed by cal 2 data within the tol, remove.
	MR = SelectNumber((abs(c2x[BinarySearch(c2x, day)]-day) <= tol) && (abs(c2x[BinarySearch(c2x, day)+1]-day) <= tol), nan, MR)

end


function conc_cal12r(mol, attrib)
	string mol, attrib
	
	string MR = mol + "_cal12r_conc"
	
	MakeStandardWaves(mol, 0)
	
	wave day = $(mol + "_date")
	wave lstd = $(mol + "_lstd_conc")
	wave hstd = $(mol + "_hstd_conc")
	wave flag = $(mol + "_flag")
	wave ssv = $(mol + "_port")
	wave ftype = $mol + "_flagtype"
	wave flg = $(mol + "_best_conc_flg")
	wave resp = $(mol + "_" + attrib)

	CreateIterpCals(mol, attrib)
	
	Wave c1x, c1i, c1xi, c1delt
	Wave c2x, c2i, c2xi, c2delt
	
	make /d/o/n=(numpnts(day)) $MR=nan
	wave MRwv = $MR
	
	variable /d inc, cpt1, cpt2, closeC1pt, closeC2pt, closeC1pt_l, closeC1pt_r, closeC2pt_l, closeC2pt_r
	variable tol = EIGHT_INJS
	
	for(inc=0; inc< numpnts(day); inc+= 1)
	
		if ((ssv[inc] == 4) || (ssv[inc] == 8))
			closeC1pt = BinarySearch(c1x, day[inc])	// c1 that is closest to day[inc]
			closeC2pt = BinarySearch(c2x, day[inc])	// c2 that is closest to day[inc]
			// check to see if c1 and c2 are close enough to use the c1i and c2i values
			if ( (abs(c1x[closeC1pt] - day[inc]) <= tol) && (abs(c1x[closeC1pt+1] - day[inc]) <= tol) ) 
				if ( (abs(c2x[closeC2pt] - day[inc]) <= tol) && (abs(c2x[closeC2pt+1] - day[inc]) <= tol) )
					closeC1pt_l = BinarySearch(c1x, day[inc]-1)
					closeC1pt_r = BinarySearch(c1x, day[inc]+1)
					closeC2pt_l = BinarySearch(c2x, day[inc]-1)
					closeC2pt_r = BinarySearch(c2x, day[inc]+1)
					//if ( (c1delt[closeC1pt] < 3*MedianEO(c1delt, closeC1pt_l,closeC1pt_r) ) && (c2delt[closeC2pt] < 3*MedianEO(c2delt, closeC2pt_l, closeC2pt_r) ))
						cpt1 = BinarySearchInterp(c1xi, day[inc])
						cpt2 = BinarySearchInterp(c2xi, day[inc])
						MRwv[inc] = lstd[inc] + (hstd[inc] - lstd[inc]) * (resp[inc] - c1i[cpt1])/(c2i[cpt2] - c1i[cpt1])
					//endif
				endif
			endif
		endif

	endfor

end

function conc_brwcal2_drift(mol, attrib)
	string mol, attrib
	
	string MRst = mol + "_brwcal2_drift_conc"
	variable tol = FOUR_INJS

	Wave c1, c1x, c1xi, c1i
	Wave c2, c2x, c2xi, c2i

	wave day = $(mol + "_date")
	wave hstd = $(mol + "_hstd_conc")
	wave lstd = $(mol + "_lstd_conc")
	wave resp = $(mol + "_" + attrib)
	wave ssv = $(mol + "_port")

	Make/o/n=(numpnts(day))/FREE c1i_full = c1i[BinarySearchInterp(c1xi, day)]
	Make/o/n=(numpnts(day))/FREE c2i_full = c2i[BinarySearchInterp(c2xi, day)]

	// F11 M3 initial value and CATS estimate of final value
	variable m0, m1
	variable /D t0 = Date2secs(2019, 10, 17), t1 = date2secs(2021, 6, 20)
	if (cmpstr(mol, "F11") == 0)
		m0 = 227.222; m1 = 223.972
	elseif (cmpstr(mol, "F113") == 0)
		m0 = 68.54; m1 = 66.6
	endif	
	
	variable slope = (m0 - m1) / (t0 - t1)
	variable b = m0 - slope * t0
	
	Make/o/n=(numpnts(day))/FREE hstd_drift = slope * day + b
	
	MatrixOp /O $MRst/WAVE=MR = lstd + (hstd_drift-lstd) * (resp - c1i_full)/(c2i_full - c1i_full)

	MR = SelectNumber((ssv==4)||(ssv==8), nan, MR)
	
	// If the air data is not bracketed by cal 1 data within the tol, remove.
	MR = SelectNumber((abs(c1x[BinarySearch(c1x, day)]-day) <= tol) && (abs(c1x[BinarySearch(c1x, day)+1]-day) <= tol), nan, MR)
	// If the air data is not bracketed by cal 2 data within the tol, remove.
	MR = SelectNumber((abs(c2x[BinarySearch(c2x, day)]-day) <= tol) && (abs(c2x[BinarySearch(c2x, day)+1]-day) <= tol), nan, MR)
	
end

function conc_mlocal2_drift(mol, attrib)
	string mol, attrib
	
	string MRst = mol + "_mlocal2_drift_conc"
	variable tol = FOUR_INJS

	Wave c1, c1x, c1xi, c1i
	Wave c2, c2x, c2xi, c2i

	wave day = $(mol + "_date")
	wave hstd = $(mol + "_hstd_conc")
	wave lstd = $(mol + "_lstd_conc")
	wave resp = $(mol + "_" + attrib)
	wave ssv = $(mol + "_port")

	Make/o/n=(numpnts(day))/FREE c1i_full = c1i[BinarySearchInterp(c1xi, day)]
	Make/o/n=(numpnts(day))/FREE c2i_full = c2i[BinarySearchInterp(c2xi, day)]

	// F11 M3 initial value and CATS estimate of final value
	variable m0, m1
	variable /D t0 = Date2secs(2019, 05, 30), t1 = date2secs(2021, 8, 1)
	if (cmpstr(mol, "F113") == 0)
		m0 = 72.3; m1 = 71
	endif	
	
	variable slope = (m0 - m1) / (t0 - t1)
	variable b = m0 - slope * t0
	
	Make/o/n=(numpnts(day))/FREE hstd_drift = slope * day + b
	
	MatrixOp /O $MRst/WAVE=MR = lstd + (hstd_drift-lstd) * (resp - c1i_full)/(c2i_full - c1i_full)

	MR = SelectNumber((ssv==4)||(ssv==8), nan, MR)
	
	// If the air data is not bracketed by cal 1 data within the tol, remove.
	MR = SelectNumber((abs(c1x[BinarySearch(c1x, day)]-day) <= tol) && (abs(c1x[BinarySearch(c1x, day)+1]-day) <= tol), nan, MR)
	// If the air data is not bracketed by cal 2 data within the tol, remove.
	MR = SelectNumber((abs(c2x[BinarySearch(c2x, day)]-day) <= tol) && (abs(c2x[BinarySearch(c2x, day)+1]-day) <= tol), nan, MR)
	
end


// new version takes advantage of SelectNumber
function conc_curve1(mol, attrib)
	string mol, attrib
	
	string MRst = mol + "_curve1_conc"
	variable tol = 3*1800

	Wave c2, c2x, c2xi, c2i

	wave day = $(mol + "_date")
	wave std = $(mol + "_hstd_conc")
	wave resp = $(mol + "_" + attrib)
	wave ssv = $(mol + "_port")
	wave coef = W_coef_N2Opoly3
	variable a, b, c
	a = coef[2]
	b = coef[1]
	c = coef[0]
	
	// calculates mixing ratio using cal curve and normalized to c2
	Make/O/n=(numpnts(day))/FREE c2i_full = c2i[BinarySearchInterp(c2xi, day)]
	Make/O/n=(numpnts(day)) $MRst/WAVE=MR =  (-b + sqrt(b*b - 4*a*(c - resp/c2i_full))) / (2*a)

	MR = SelectNumber((ssv==4)||(ssv==8), nan, MR)

	// If the air data is not bracketed by cal 2 data within the tol, remove.
	MR = SelectNumber((abs(c2x[BinarySearch(c2x, day)]-day) <= tol) && (abs(c2x[BinarySearch(c2x, day)+1]-day) <= tol), nan, MR)
	
end

// adjusts the cal1 conc concentration to a diffrence between fits of cal1 and cal12.  This
// is usefully when the cal12 calculation is more accurate but much more noisy.
// developed: 180501 GSD
function conc_cal1_adj(mol, attrib)
	string mol, attrib

	variable inc
	string MRstr = mol + "_cal1_adj_conc"
	string MR12str = mol + "_cal12_conc"
	string MR1str = mol + "_cal1_conc"
	string DAYstr = mol + "_date"

	conc_cal1(mol, attrib)
	conc_cal12(mol, attrib)
	
	wave MR12 = $MR12str
	wave MR1 = $MR1str
	wave day = $DAYstr

	WaveStats/Q MR12
	lowchop(MR12, 0)
	highchop(MR12, v_avg*3)

	make /n=(numpnts(MR2)) /o $MRstr/Wave=MR=Nan
	make /n=(numpnts(MR2)) /o MR12fit, MR1fit
	
	fit_calrange(day, MR12, MR12fit, 0)
	fit_calrange(day, MR1, MR1fit, 0)
	
	MR = MR1 + MR12fit - MR1fit

end

// adjusts the cal2 conc concentration to a diffrence between fits of cal2 and cal12.  This
// is usefully when the cal12 calculation is more accurate but much more noisy.
// developed: 180501 GSD
function conc_cal2_adj(mol, attrib)
	string mol, attrib

	variable inc
	string MRstr = mol + "_cal2_adj_conc"
	string MR12str = mol + "_cal12_conc"
	string MR2str = mol + "_cal2_conc"
	string DAYstr = mol + "_date"
	string flagstr = mol + "_flag"

	conc_cal2(mol, attrib)
	conc_cal12(mol, attrib)
	
	wave MR12 = $MR12str
	wave MR2 = $MR2str
	wave day = $DAYstr
	wave flag = $flagstr
	
	// don't mess with the cal2_conc and cal12_conc waves
	duplicate /FREE MR12 MR12tmp
	duplicate /FREE MR2 MR2tmp
	
	MR2tmp = SelectNumber(numtype(flag)==0, NaN, MR2)
	MR12tmp = SelectNumber(numtype(flag)==0, NaN, MR12)

	make /n=(numpnts(day)) /o $MRstr/Wave=MR=Nan
	make /n=(numpnts(day)) /o MR12fit, MR2fit
	
	fit_calrange(day, MR12tmp, MR12fit, 1)
	fit_calrange(day, MR2tmp, MR2fit, 1)
	
	MR = MR2 + MR12fit - MR2fit

end

// function will step through cal table and fit a poly 3 line to each cal transition
// for wv_y vs wv_x
// stdtype = 0 for lstd, 1 for hstd
function fit_calrange(wv_x, wv_y, wv_dest, stdtype)
	wave wv_x, wv_y, wv_dest
	variable stdtype

	SVAR site = G_site3
	string savedDF= GetDataFolder(1)
	string mol = WaveName("",0,1)[0,strsearch(WaveName("",0,1), "_", 0)-1]
	wave /t days = $(savedDF + site + "_ALMdates")
	
	// choose which stand table to use for segements of the fit.
	if (stdtype == 0)
		wave /t std = $site + "_lstd"
	else
		wave /t std = $site + "_hstd"
	endif
	
	string tank0, tankon, tankoff
	variable i, p0, p1, inc
	for(i=0; i<numpnts(std); i+=1)
		tank0 = std[i]		
		if (cmpstr(tank0,"off")!=0)
			if ((cmpstr(tank0, std[i+1]) == 0) & (cmpstr(tank0,"off") !=0))
				inc=1
				// look ahead one more cell to compare.  This gets the three in a row cases
				if ((cmpstr(tank0, std[i+2]) == 0) & (cmpstr(tank0, std[i+3]) != 0))
					inc=2
				elseif ((cmpstr(tank0, std[i+2]) == 0) & (cmpstr(tank0,std[i+3]) == 0))
					inc=3
				endif
				tankon = days[i]
				tankoff = days[i+inc+1]
				i+=inc
			else
				tankon = days[i]
				tankoff = days[i+1]
			endif
			p0 = BinarySearchInterp(wv_x, date_return(tankon))
			if (numtype(p0)==2)  // first point
				p0=0
			endif
			p1 = BinarySearchInterp(wv_x, date_return(tankoff))
			if (i>=numpnts(std))	// last point
				p1 = numpnts(wv_x)
			endif
			// do the fit on cal segment
			if ((p1-p0) > 2000)
				wavestats /q/R=[p0,p1] wv_y
				//print p0,p1,V_npnts,V_numNans, V_npnts-V_numNaNs
				if ((V_npnts) > 100)
					CurveFit/Q poly 5, wv_y[p0,p1] /X=wv_x
					//CurveFit/Q line, wv_y[p0,p1] /X=wv_x
					wave coef = W_coef
					wv_dest[p0,p1] = SelectNumber(numtype(wv_y[p])==0, NaN, poly(coef, wv_x[p]))
				endif
			endif
			//print tank0, tankon, tankoff, p0, p1, p1-p0
		endif
	endfor
	
end

// Average of conc_cal1 and conc_cal2
function conc_cal12a(mol, attrib)
	string mol, attrib

	variable inc
	string MRstr = mol + "_cal12a_conc"
	string MR1str = mol + "_cal1_conc"
	string MR2str = mol + "_cal2_conc"
	
	conc_cal1(mol, attrib)
	conc_cal2(mol, attrib)
	
	wave MR1 = $MR1str
	wave MR2 = $MR2str
	
	make /n=(numpnts(MR1)) /o $MRstr = NaN
	wave MR = $MRstr
	
	MR = (MR1 + MR2) / 2
	do
		if (numtype(MR1[inc]) == 2) 
			MR[inc] = MR2[inc]
		elseif (numtype(MR2[inc]) == 2)
			MR[inc] = MR1[inc]
		endif
		inc += 1
	while (inc < numpnts(MR1))
	
end

// Average of conc_cal1 and conc_cal2, if one is missing use NAN
function conc_cal12ax(mol, attrib)
	string mol, attrib

	variable inc
	string MRstr = mol + "_cal12ax_conc"
	string MR1str = mol + "_cal1_conc"
	string MR2str = mol + "_cal2_conc"
	
	conc_cal1(mol, attrib)
	conc_cal2(mol, attrib)
	
	wave MR1 = $MR1str
	wave MR2 = $MR2str
	
	make /n=(numpnts(MR1)) /o $MRstr = NaN
	wave MR = $MRstr
	
	MR = (MR1 + MR2) / 2
	
end


Proc CalcConcDisp(mol, attrib, meth)
	string mol=StrMakeOrDefault("root:G_mol", "F11")
	string attrib=StrMakeOrDefault("root:G_attrib", "H")
	variable meth=NumMakeOrDefault("root:G_concmeth", 5)
	prompt mol, "Molecule", popup, G_loadMol
	prompt attrib, "Attribute", popup, "H;A"
	prompt meth, "Method", popup, "ratio to cal 1;ratio to cal 2;cal 1 & cal 2 ratio; cal1 & cal2 average;plot all four"
	
	silent 1; pauseupdate
	G_mol = mol
	G_attrib = attrib
	G_concmeth = meth
	
 	string day = mol + "_date"
 	string name = mol + "_concPlot"
 	string flag = mol + "_flag"

	DoWindow /K $name
	
	if (meth == 1)
		string conc = mol + "_cal1_conc"
		conc_cal1(mol, attrib)
		$conc *= $flag
		display /K=1/W=(32,70,844,517) $conc vs $day
	else
	if (meth == 2)
		string conc = mol + "_cal2_conc"
		conc_cal2(mol, attrib)
		$conc *= $flag
		display /K=1/W=(32,70,844,517) $conc vs $day
		execute "ModifyGraph rgb(" + conc + ")=(0,0,65535)"
	else
	if (meth == 3)
		string conc = mol + "_cal12_conc"
		conc_cal12(mol, attrib)
		$conc *= $flag
		display /K=1/W=(32,70,844,517) $conc vs $day
		execute "ModifyGraph rgb(" + conc + ")=(2,39321,1)"
	else
	if (meth == 4)
		string conc = mol + "_cal12a_conc"
		conc_cal12a(mol, attrib)
		$conc *= $flag
		display /K=1/W=(32,70,844,517) $conc vs $day
		execute "ModifyGraph rgb(" + conc + ")=(13107,13107,13107)"
	else	
	if (meth == 5)
		string cc1 = mol + "_cal1_conc"
		string cc2 = mol + "_cal2_conc"
		string c12 = mol + "_cal12_conc"
		//string c12a = mol + "_cal12a_conc"
		conc_cal1(mol, attrib)
		conc_cal2(mol, attrib)
		conc_cal12(mol, attrib)
		//conc_cal12a(mol, attrib)
		$cc1 *= $flag
		$cc2 *= $flag
		$c12 *= $flag
		//$c12a *= $flag
		display  /W=(32,70,844,517) $cc1 $cc2 $c12  vs $day
		execute "ModifyGraph rgb(" + cc2 + ")=(0,0,65535)"
		execute "ModifyGraph rgb(" + c12 + ")=(2,39321,1)"
		//execute "ModifyGraph rgb(" + c12a + ")=(13107,13107,13107)"
		legend
	endif
	endif
	endif
	endif
	endif

	DoWindow /C $name
	
	ModifyGraph mode=3,msize=2
	ModifyGraph grid=1,mirror=2
	SetAxis/A/N=1 left
	Label left mol + " Mixing Ratio (ppt)"
	Label bottom "Date"
	
	CalValueLinesToPlot()
	
	// set the scales to the save values as on the "best_conc" plot.
	string bestwin = "Weekly_" +  mol + "_ALL"
	GetAxis /W=$bestwin /Q left
	SetAxis /W=$name left V_min, V_max
	
end

function MeanCalRatioMatrix(mol, attrib)
	string mol, attrib
	
	SVAR site = G_site3
	
	string meanstr = mol + "_" + attrib + "_meanBins"
	wave day = $(mol + "_date")
	wave /t std = $(site + "_ALMdates")
	make /o/n=(numpnts(std), 3) $meanstr=nan
	wave meanWv = $meanstr
	variable YYYY, MM, DD, HH, MN, levelX, oldLevelX, inc
	variable /d level
	string workdate, choice, com
	NVAR V_ratioPlot = V_ratioPlot

	V_ratioPlot = 0
	sprintf com, "CalRatio(\"%s\",1,\"%s\",1)", mol, attrib
	execute com
	V_ratioPlot = 1

	wave ratio = $(mol + "_ratio_" + attrib +"_f")
	
	oldLevelX = 0
	do
		workdate = std[inc]
		YYYY = str2num(workdate[0,3])
		MM = str2num(workdate[4,5])
		DD = str2num(workdate[6,7])
		HH = str2num(workdate[9,10])
		MN = str2num(workdate[11,12])

		level = date2secs(YYYY, MM, DD) + HH*60*60 + MN*60
		if (level <= day[0])
			levelX = 0
		else
		if (level >= day[numpnts(day)])
			levelX = numpnts(day)
		else
			findlevel /q day, level
			levelX = V_levelX
		endif
		endif
		
		if (inc > 0)
			wavestats/q/r=(oldLevelX, levelX) ratio
			if (V_npnts > (levelX-oldLevelX)/10)
				meanWv[inc-1][0] = v_avg
			endif
			meanWv[inc-1][1] = oldLevelX
			meanWv[inc-1][2] = levelX
		endif
		oldLevelX = levelX
		
		inc += 1
		
	while (inc < numpnts(std))

	if (level < day[numpnts(day)])
		wavestats/q/r=(oldLevelX, numpnts(day)) ratio
		meanWv[inc-1][0] = v_avg
		meanWv[inc-1][1] = oldLevelX
		meanWv[inc-1][2] = numpnts(day)
	endif	
end
	

// function front end to BestConc
//081217
function BestConcCalc([mol])
	string mol
	
	NVAR G_recalcSD

	if ( ParamIsDefault(mol) )
		SVAR Gmol = root:G_mol
		mol = Gmol
	endif
	
	
	if ( strsearch(mol, "comb", 0) != -1 )
		CombineDataSetsFUNCT(mol[0,strsearch(mol,"comb",0)-1])
	else
	
		if (G_recalcSD==1)
			CalcDailyUncertainties()
		endif
	
		String attrib = ReturnIntAttrib(mol=mol)
		BestConcCalcFUNCT(mol, attrib, 1)
	endif	
	
	WeeklyAvg()
end


function BestConcCalcFUNCT(mol, attrib, flagR)
	string mol, attrib
	variable flagR
	
	SVAR site = G_site3
	
	string conc = mol + "_best_conc"
	string workdate, choice, com
	wave /t best = $mol + "_best"
	wave day = $mol + "_date"
	wave /t stddate = $(site + "_ALMdates")
	wave off = $mol + "_offset"
	wave flag = $mol +  "_flag"

	variable inc, ptR, ptL

	// these functions are called in CalcDailyUncertainties
	//MakeStandardWaves(mol, 0)
	//CreateIterpCals(mol, attrib)
	
	make /o/n=(numpnts(day)) $conc/WAVE=concWv=NaN
	
	// First update the conc_* waves
	string elem0, methlst = SortList(WaveToList(mol+"_best", ";"))
	methlst = UniqueList(methlst)
	
	// if area calculations are used
	if (strsearch(methlst, "_area", 0) > 0)
		CreateCalRatios(mol, "a")	// needed for hardcoded area routines
		inc = WhichListItem("cal2_area", methlst)
		if (inc != -1)
			conc_cal2_area(mol, "a")
			methlst = RemoveListItem(inc, methlst)
		endif
		inc = WhichListItem("cal12_area", methlst)
		if (inc != -1)
			conc_cal12_area(mol, "a")
			methlst = RemoveListItem(inc, methlst)
		endif
		CreateCalRatios(mol, attrib)		// set back
	endif

	for (inc = 0; inc< ItemsInList(methlst, ";"); inc+=1 )
		elem0 = StringFromList(inc, methlst, ";")
		if (cmpstr(elem0,"none") != 0)
			sprintf com, "conc_%s(\"%s\",\"%s\")", elem0, mol, attrib
			execute com
		endif
	endfor
	
	ptL = 0
	// build up "best_conc" wave
	for(inc=0; inc<=numpnts(stddate); inc+=1)
		workdate = stddate[inc]
		ptR = BinarySearchInterp(day, date_return(workdate))
		ptR = SelectNumber(numtype(ptR)==2, ptR, 0)
		ptR = SelectNumber(inc == numpnts(stddate), ptR, numpnts(concWv))
		
		if (cmpstr(best[inc-1], "none") == 0)
			concWv[ptL, ptR] = NaN
		else
			choice = mol + "_" + best[inc-1] + "_conc"
			wave choiceWv = $choice
			concWv[ptL, ptR] = choiceWv + off[inc-1]
		endif
		ptL = ptR
	endfor
	
	if (flagR == 1)
		duplicate /o flag $mol+"_flag_bak"
		FlagRediculous(concWv, mol, attrib)
	endif
	
	// save all data (flagged and unflagged)
	string all = conc + "_flg"
	duplicate /o concWv, $all/WAVE=flg
	
	flg = SelectNumber(numtype(flag)==0, concWv, NaN)

	ApplyShifts(mol, day, concWv)
		
end

// Apply other shifts in data using "_shift" wave
function ApplyShifts(mol, day, conc)
	string mol
	wave day, conc
	
	SVAR site = G_site3
	variable inc, ptL, ptR

	Wave /Z shift = $mol + "_shift"
	if (WaveExists(shift))
		Wave /T shiftT1 = $mol + "_shift_date_start"
		Wave /T shiftT2 = $mol + "_shift_date_stop"
		for (inc=0; inc<numpnts(shiftT1); inc+=1)
			ptL = BinarySearchInterp(day, date_return(shiftT1[inc]))
			ptR = BinarySearchInterp(day, date_return(shiftT2[inc]))
			ptR = SelectNumber(numtype(ptR) == 2, ptR, numpnts(day)-1)
			conc[ptL, ptR] += shift[inc]
		endfor
		
	endif
		
end

function/s shorttankname(tankstr)
	string tankstr
	
	variable i, len = strlen(tankstr)
	string chr
	
	for(i=0; i<len; i+=1)
		chr = tankstr[i]
		if (numtype(str2num(chr)) == 0)
			return tankstr[i,len]
		endif
	endfor

	return tankstr
end


// Function to append high/low cal tank change lines to a graph
function AppendCalLines()

	SVAR site = G_site3
	GetAxis /Q Left

	// if lines are present, remove them
	String traces = TraceNameList("", ";", 1)
	if ( strsearch( traces, "tnk", 0 ) > -1 )
		AppendCalLines_OFF()
		return 0
	endif

	string fol = WaveName("",0,1)  + "_CL"
	string savedDF= GetDataFolder(1)
	string strtank, shorttank, tagtxt
	wave /t lstd = $site + "_lstd"
	wave /t hstd = $site + "_hstd"
	wave /t days = $(savedDF + site + "_ALMdates")
	variable len = numpnts(lstd), inc
	
	if (DataFolderExists(fol) == 1)
		KillDataFolder /Z $fol
	endif
	NewDataFolder /O/S $fol
	
	// Append the low cal lines
	do
		if (cmpstr(lstd[inc],"off") != 0)
			strtank = "tnk" + shorttankname(lstd[inc]) + "on"
			shorttank = shorttankname(lstd[inc])
			if (exists(strtank) != 1)
				make /d/n=2 $strtank={V_min, V_max}
				SetScale/I x date_return(days[inc]), date_return(days[inc])+1, "", $strtank
				appendtograph $strtank
				sprintf tagtxt, "	Tag/N=%s/F=0/X=0.00/Y=5/L=0 %s, %d, \"\\K(39321,1,1)\\Z10\\f01%s\"", strtank, strtank, date_return(days[inc]), shorttank
				execute tagtxt
			endif
		endif
		inc += 1
	while (inc < len)

	// Append the high cal lines
	inc = 0
	do
		if (cmpstr(hstd[inc],"off") != 0)
			strtank = "tnk" + shorttankname(hstd[inc]) + "on"
			shorttank = shorttankname(hstd[inc])
			if (exists(strtank) != 1)
				make /d/n=2 $strtank={V_min, V_max}
				SetScale/I x date_return(days[inc]), date_return(days[inc])+1, "", $strtank
				appendtograph $strtank
				ModifyGraph rgb($strtank)=(3,52428,1)
				sprintf tagtxt, "	Tag/N=%s/F=0/X=0.00/Y=10/L=0 %s, %d, \"\\K(1,26214,0)\\Z10\\f01%s\"", strtank, strtank, date_return(days[inc]), shorttank
				execute tagtxt
			endif
		endif
		inc += 1
	while (inc < len)
	
	// Append Cal tank "offs"
	inc = 0
	do
		if (cmpstr(hstd[inc],"off") == 0)
			strtank = "tnk" + shorttankname(hstd[inc-1]) + "off"
			shorttank = shorttankname(hstd[inc-1])
			shorttank += "off"
			if (exists(strtank) != 1)
				make /d/n=2 $strtank={V_min, V_max}
				SetScale/I x date_return(days[inc]), date_return(days[inc])+1, "", $strtank
				appendtograph $strtank
				ModifyGraph rgb($strtank)=(1,26214,0)
				sprintf tagtxt, "	Tag/N=%s/F=0/X=0.00/Y=15/L=0 %s, %d, \"\\K(1,26214,0)\\Z10\\f01%s\"", strtank, strtank, date_return(days[inc]), shorttank
				execute tagtxt
			endif
		endif
		inc += 1
	while (inc < len)
	
	inc = 0
	do
		if (cmpstr(lstd[inc],"off") == 0)
			strtank = "tnk" + shorttankname(lstd[inc-1]) + "off"
			shorttank = shorttankname(lstd[inc-1])
			shorttank += "off"
			if (exists(strtank) != 1)
				make /d/n=2 $strtank={V_min, V_max}
				SetScale/I x date_return(days[inc]), date_return(days[inc])+1, "", $strtank
				appendtograph $strtank
				ModifyGraph rgb($strtank)=(39321,1,1)
				sprintf tagtxt, "	Tag/N=%s/F=0/X=0.00/Y=15/L=0 %s, %d, \"\\K(39321,1,1)\\Z10\\f01%s\"", strtank, strtank, date_return(days[inc]), shorttank
				execute tagtxt
			endif
		endif
		inc += 1
	while (inc < len)

	SetDataFolder savedDF

end

function AppendCalLines_OFF()

	String traces = TraceNameList("", ";", 1), t
	Variable i
	
	//print traces
	for(i=0; i<ItemsInList(traces); i+=1)
		t = StringFromList(i, traces)
		if (strsearch(t, "_", 0) == -1)
			RemoveFromGraph /z $t
		endif
	endfor
	
end

// Function to append concentration calculation methods
function AppendMethodLines()

	SVAR site = G_site3
	GetAxis /Q Left

	string fol = WaveName("",0,1)  + "_MT"
	string savedDF= GetDataFolder(1)
	string onemeth, tagtxt
	string mol = WaveName("",0,1)[0,strsearch(WaveName("",0,1), "_", 0)-1]
	wave /t meth = $(savedDF + mol + "_best")
	wave offset = $(savedDF + mol + "_offset")
	wave /t days = $(savedDF + site + "_ALMdates")
	variable len = numpnts(meth), inc
	
	if (DataFolderExists(fol) != 1)
		NewDataFolder /S $fol
	endif
	
	// Append the method lines
	do
		onemeth = meth[inc] + "on" + num2str(inc)
		make /o/d/n=2 $onemeth={V_min*1.01, V_max*0.99}
		SetScale/I x date_return(days[inc]), date_return(days[inc])+1, "", $onemeth
		appendtograph $onemeth
		if ( offset[inc] != 0 )
			sprintf tagtxt, "	Tag/A=LC/N=%s/F=0/X=1.00/Y=95/L=0 %s, %d, \"\\K(39321,1,1)\\Z10\\f01%s\\r\\K(0,40000,0)off: %2.2f\"", onemeth, onemeth, date_return(days[inc]), meth[inc], offset[inc]
		else
			sprintf tagtxt, "	Tag/A=LC/N=%s/F=0/X=1.00/Y=95/L=0 %s, %d, \"\\K(39321,1,1)\\Z10\\f01%s\"", onemeth, onemeth, date_return(days[inc]), meth[inc]
		endif
		execute tagtxt
		inc += 1
	while (inc < len)

	SetDataFolder savedDF

end

// Repeatedly calling this function will toggle the cal resp lines on and off
Function AppendCalResp()

	string traces = TraceNameList("", ";", 1)
	
	if ( strsearch(traces, "c1i", 0) != -1 )
		RemoveFromGraph c1, c2, c1i, c2i
		ModifyGraph mirror=2
		return 0
	endif

	AppendToGraph /r c1 vs c1x
	AppendToGraph /r c2 vs c2x
	AppendToGraph /r c1i vs c1xi
	AppendToGraph /r c2i vs c2xi
	
	ModifyGraph rgb(c1i)=(0,0,0),rgb(c1)=(0,0,0),rgb(c2)=(0,0,65535),rgb(c2i)=(0,0,65535)
	ModifyGraph mode(c1)=3,mode(c2)=3, msize(c1)=2, msize(c2)=2
	ModifyGraph marker(c1)=19,marker(c2)=19
	
	SetAxis/A=2 right
	DoUpdate
	GetAxis /Q right
	V_min *= 0.7
	V_max *= 1.3
	SetAxis right, V_min, V_max
	
end

// used from python program
Function ReloadAndCalcAll([mol])
	string mol
	
	if ( ParamIsDefault(mol) )
		Prompt mol, "Process which molecule", popup "N2O;F11;F12;F113;H1211;SF6;HCFC22;HCFC142b;OCS;MC;CCl4"
		DoPrompt "Reload and Calc All", mol
	endif

	
	if (cmpstr(mol, "N2O") == 0 )
		ReloadAndCalc(mol="N2O", ex=1)
		ReloadAndCalc(mol="N2Oa", ex=1)
		ReloadAndCalc(mol="N2Ocomb", ex=1)
	elseif (cmpstr(mol, "F11") == 0 )
		ReloadAndCalc(mol="F11", ex=1)
		ReloadAndCalc(mol="F11a", ex=1)
		ReloadAndCalc(mol="F11comb", ex=1)
	elseif (cmpstr(mol, "F113") == 0 )
		ReloadAndCalc(mol="F113", ex=1)
		ReloadAndCalc(mol="F113a", ex=1)
		ReloadAndCalc(mol="F113comb", ex=1)
	elseif (cmpstr(mol, "F12") == 0 )
		ReloadAndCalc(mol="F12", ex=1)
		ReloadAndCalc(mol="F12f", ex=1)
		ReloadAndCalc(mol="F12cc", ex=1)
		ReloadAndCalc(mol="F12comb", ex=1)
	elseif (cmpstr(mol, "H1211") == 0 )
		ReloadAndCalc(mol="H1211", ex=1)
		ReloadAndCalc(mol="H1211a", ex=1)
		ReloadAndCalc(mol="H1211cc", ex=1)
		ReloadAndCalc(mol="H1211comb", ex=1)
	else
		ReloadAndCalc(mol=mol, ex=1)
	endif
	
end

Function ReloadAndCalc([mol, ex])
	string mol
	variable ex

	SVAR loadMol = root:G_loadMol
	
	if ( ParamIsDefault(mol) )
		SVAR Gmol = root:G_mol
		mol = Gmol
	endif

	// make sure mol is loaded in this experiment
	if (strsearch(loadMol, mol, 0) == -1 )
		return -1
	endif

	if (strsearch(mol, "comb", 0) == -1 )
		LoadIntegrationResults(mol=mol)
	endif
	BestConcCalc(mol=mol)

	// export to web?	
	if ( ! ParamIsDefault(ex) )
		ExportForWebPagesFUNCT(mol)
	endif
end

Proc RecalcAllMols()

	string mol
	variable inc=0, stp = NumElementsInList(G_loadMol, ";")
	string attrib = "H"

	// First do regular molecules	
	do
		mol = GetStrFromList(G_loadMol, inc, ";")
		if (strsearch(mol, "comb", 0) == -1 )
			BestConcCalc(mol=mol, recalc=1)
		endif
		inc += 1
	while( inc < stp )

	// Next do combined data molecules
	inc = 0
	do
		mol = GetStrFromList(G_loadMol, inc, ";")
		if (strsearch(mol, "comb", 0) != -1 )
			mol = mol[0,strsearch(mol, "comb", 0)-1]
			CombineDataSets(mol,1)
		endif
		inc += 1
	while( inc < stp )

end



// Function to estimate a cal tank value givin cal tank drift. 
// Requires a drift table (loaded with loadStandardsFile() )
// estdate is in seconds -- use date2secs
// linear correciton
function EstimateCal(mol, tankwv, estdate, meth)
	string mol
	wave tankwv
	wave estdate
	variable meth
	
	// Average slope is used if no slope calculated 
	// this occures when the IN or OUT analysis is unavailable.
	variable AVG_CH3Cl_slope = 0.05  / (60*60*24)		// ppt/sec
	variable AVG_CH3Br_slope = 0 							// ppt/sec
	variable AVGslope = 0
	if ( cmpstr(mol, "ch3cl") == 0 )
		AVGslope = AVG_CH3Cl_slope
	endif
	
	SVAR site = G_SITE3
	
	wave /t ALM = $(mol + "_tank")
	wave D1 = $(mol + "_D1")
	wave D2 = $(mol + "_D2")
	wave MR1 = $(mol + "_MR1")
	wave MR2 = $(mol + "_MR2")
	
	make /o /n=(numpnts(tankwv)) MRwvtmp = nan
	
	variable /d slope, MR = -1
	variable inc, num = numpnts(ALM), row = -1
	variable n, tankind, tankindold = -1
	
	do 
		tankind = tankwv[n]
		// new tankind found
		if (tankind != tankindold)
		
			if (tankind != -1 )	
			
				// Find ALM row number in drift table
				for ( inc = 0; inc < num; inc += 1 )
					if (cmpstr(ALM[inc], index2tank(mol, tankind)) == 0)
						row = inc
						break
					endif
				endfor
	
				// If NaN return AVGslope
				slope = SelectNumber( ((numtype(MR1[row]) == 0) && (numtype(MR2[row]) == 0)),  AVGslope, (MR2[row] - MR1[row]) / (D2[row] - D1[row]))
				
			else
				slope = NaN
				row = -1
			endif
	
		endif
		tankindold = tankind
	
		// linear drift
		if ( meth == 0 )
			MRwvtmp[n] =  slope * (estdate[n] - D1[row]) + MR1[row]
		endif
		
		n += 1
	while ( n < numpnts(tankwv))
	
end

// t1 = tank online start
// t2 = tank offline
// t3 = final measurement
// p0 = initial tank pressure
// p1 = final tank pressure
// mr0 = initial concentration
// mr1 = final concentration 
function /d CH3Cldrift(t0, t1, t2, t3, p0, p1, mr0, mr1)
	variable /d t0, t1, t2, t3, p0, p1, mr0, mr1
	
	variable /d R = 0.082057		// gas constant ( L atm / ( K mol ) )
	variable V = 29.5				// ALM volumn ( L )
	variable T = 298				// temp ( K ) 
	p0 /=14.7
	p1 /= 14.7
	
	variable dP = (p0-p1)/(t2-t1)	// pressure loss ( atm / T )
	variable /d C = R * T / V 			// atm / mol
	variable /d S = (mr1 - mr0)/ (C * ((t1-t0)/p0 + (t3-t2)/p1 + 1/dP*ln(p0/p1)) )	// Rate ( conc/ T )
	
//	print dP, S * 60*60*24
		
	make /d/o/n=1000 MR, pr
	SetScale/I x t0, t3, "dat", MR
	
	variable /d i, tm, pt
	for(i=0; i<1000; i+=1)
		tm = pnt2x(MR, i)
		if ( tm <= t1 )
			pr[i] = p0 * 14.7
			MR[i] = mr0 + C/p0 * S * (tm - t0)
		elseif (( tm <= t2) && ( tm > t1))
			pt = p0 - (tm - t1) * dP
			pr[i] = pt * 14.7
			MR[i] = mr0 + C/p0 * S * (t1 - t0) + C * S * 1/dP*ln(p0/pt) 
		elseif ( tm > t2 )
			pr[i] = p1 * 14.7
			MR[i] = mr0 + C/p0 * S * (t1 - t0) + C * S * 1/dP*ln(p0/p1) + C/p1 * S * (tm - t2)
		endif
	endfor
	
end

// LorH == 1 for hstd, 0 for lstd
function ConstantMolarDrift(mol, secs, LorH)
	string mol
	variable /d secs, LorH
	
	SVAR site = G_site3
	
	if ( exists("root:G_CalcRow") == 0 )
		variable /G root:G_CalcRow = -1
	endif
	NVAR CalcRowOld = G_CalcRow
	if ( exists("root:G_t1") == 0 )
		variable /D/G root:G_t1 = -1
	endif
	NVAR t1old = G_t1
	if ( exists("root:G_t2") == 0 )
		variable /D/G root:G_t2 = -1
	endif
	NVAR t2old = G_t2
	
	// drift table waves
	wave /t ALM = $(mol + "_tank")
	wave D1 = $(mol + "_D1")
	wave D2 = $(mol + "_D2")
	wave MR1 = $(mol + "_MR1")
	wave MR2 = $(mol + "_MR2")
	
	// calc table waves
	wave /t ALMdates = $(site + "_ALMdates")
	wave /t meth = $(mol + "_best")
	string stdstr = SelectString(LorH, site+"_lstd", site+"_hstd")
	wave /t std = $stdstr
	
	// variables
	variable /d t0, t1, t2, t3, p0, p1, c0, c1
	variable CalcRow = CalcTableRow(secs)
	variable DriftRow = nan, i
	string tank = std[CalcRow]

	// save time by only extracting when the CalcRow changes
//	if ( CalcRowOld != CalcRow )
		// find tank in drift table
		Extract /indx/o ALM, tmpWv, cmpstr(ALM, tank) == 0
//	endif
	
	if (numtype(tmpWv[0]) == 0 )
		DriftRow = tmpWv[0]
	endif
	
	t0 = D1[DriftRow]
	t3 = D2[DriftRow]
	c0 = MR1[DriftRow]
	c1 = MR2[DriftRow]
	
	if ( t0 < date2secs(1997,1,1) )
		t0 = NaN
	endif
	if ( t3 < date2secs(1997,1,1) )
		t3 = NaN
	endif
	
	if ( CalcRowOld != CalcRow )
		// find when tank was put on
		for(i=0;i<numpnts(std); i+=1)
			if ( cmpstr(std[i], tank) == 0 )
				break
			endif	
		endfor
		t1 = date_return(ALMdates[i])
		t1old = t1
	
		// find when tank was taken off
		for(i=numpnts(std)-1;i>=0; i-=1)
			if ( cmpstr(std[i], tank) == 0 )
				break
			endif	
		endfor
		t2 = date_return(ALMdates[i+1])
		if ((i+1) == numpnts(std))			// tank is still online
			t2 = nan
		endif
		t2old = t2
	else 
		t1 = t1old
		t2 = t2old
	endif
	
//	if ( CalcRowOld != CalcRow )
//		print /d CalcRow, tank, t0, t1, t2, t3, 2000, 200, c0, c1
//	endif

	CalcRowOld = CalcRow

	return LinearDriftRate(t0, t1, t2, t3, 2000, 200, c0, c1, secs)
		
end

// t0 = original conc measurment date
// t1 = tank online start
// t2 = tank offline
// t3 = final measurement
// p0 = initial tank pressure
// p1 = final tank pressure
// mr0 = initial concentration
// mr1 = final concentration 
function /d LinearDriftRate(t0, t1, t2, t3, p0, p1, mr0, mr1, secs)
	variable /d t0, t1, t2, t3, p0, p1, mr0, mr1, secs
	
	variable /d R = 0.082057		// gas constant ( L atm / ( K mol ) )
	variable V = 29.5				// ALM volumn ( L )
	variable T = 298				// temp ( K ) 
	variable psi3stm = 1/14.7	
	
	p0 *= psi3stm
	p1 *= psi3stm
	
	variable dP = (p0-p1)/(t2-t1)	// pressure loss ( atm / T )
	variable avg_dP = 1e-06			// 
	if ( numtype(t2) == 2 )
		dP = avg_dP
	endif

	variable /d C = R * T / V 			// atm / mol
	variable /d S = (mr1 - mr0)/ (C * ((t1-t0)/p0 + (t3-t2)/p1 + 1/dP*ln(p0/p1)) )	// Rate ( conc/ T )
	variable /d avgS = 2.0 / (60*60*24)

	variable /d MR, pt

	if ((numtype(S) == 2 ) || (numtype(t2) == 2))
		S = avgS
		t2 = secs			// tank is still online
	endif
	
	if ( secs <= t1 )
		MR = mr0 + C/p0 * S * (secs - t0)
	elseif (( secs <= t2) && ( secs> t1))
		pt = p0 - (secs - t1) * dP
		MR = mr0 + C/p0 * S * (t1 - t0) + C * S * 1/dP*ln(p0/pt) 
	elseif ( secs > t2 )
		MR = mr0 + C/p0 * S * (t1 - t0) + C * S * 1/dP*ln(p0/p1) + C/p1 * S * (secs - t2)
	endif
	
	return MR
	
end



// 220427 GSD
// load CCGG .csv file made with Jupyter notebook on catsdata
// using a subset of sites
function LoadCCGGfile([mol])
	string mol
	
	if ( ParamIsDefault(mol) )
		Prompt mol, "Load which CCGG molecule", popup "N2O;SF6"
		DoPrompt "Molecule", mol
	endif

	string s, sMR, sSD, sDate
	string file = "Macintosh HD:Users:gdutton:Data:CATS:Data Processing:ccgg_" + lowerStr(mol) + ".csv"
	variable i
	
	NewDataFolder /o :CCGG
	
	String columnInfoStr = ""
	columnInfoStr += "C=1,F=-1,T=4,N=CCGG_" + mol + "_date;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_alt_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_alt_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_brw_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_brw_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_cgo_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_cgo_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_kum_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_kum_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_mhd_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_mhd_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_mlo_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_mlo_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_nwr_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_nwr_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_psa_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_psa_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_smo_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_smo_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_spo_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_spo_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_sum_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_sum_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_thd_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_thd_" + mol + "_sd;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_ush_" + mol + "_mn;"
	columnInfoStr += "C=1,F=-1,T=2,N=CCGG_ush_" + mol + "_sd;"
	
	LoadWave/O/A/Q/J/W/K=0/B=columnInfoStr/R={English,2,2,2,2,"Year-Month-DayOfMonth",40} file
	print "loaded from: " + file
	
	cd root:
	
end
