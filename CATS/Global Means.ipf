#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=8.0
#pragma version=2.2

constant RAD = 0.0174533			// Pi/180  to covert degrees to radians
// tdf was renamed ush  151015
strconstant AllSites = "alt;sum;brw;mhd;thd;nwr;lef;kum;mlo;smo;cgo;psa;spo;ush;hfm;" 	// added ush and htm for MSD ,  added lef,    added gmi, mid, asc, eic (CCGG sites)
strconstant AllBKsitesMSD = "alt;sum;brw;mhd;thd;nwr;kum;mlo;smo;cgo;psa;spo;"
//strconstant AllBKsitesMSD = "alt;brw;mhd;nwr;kum;mlo;smo;cgo;psa;spo;"  // 10 site subset
//strconstant AllBKsitesOTTO = "alt;sum;brw;mhd;thd;nwr;kum;mlo;smo;cgo;ush;psa;spo;"		// same as MSD + ush
strconstant AllBKsitesOTTO = "alt;sum;brw;mhd;thd;nwr;kum;mlo;smo;cgo;psa;spo;"		// same as MSD, removed ush 210510 GSD
strconstant AllBKsitesCCGG = "alt;sum;brw;mhd;thd;nwr;kum;mlo;smo;cgo;ush;psa;spo;"
strconstant AllInsts = "CATS;RITS;OTTO;OldGC;MSD;CATS+RITS;CATS+RITS+OTTO;CATS+RITS+OTTO+MSD;CATS+OTTO;CATS+RITS+OldGC;CATS+RITS+OTTO+OldGC;CATS+RITS+OTTO+OldGC+MSD;CATS+RITS+OTTO+OldGC+CCGG"
strconstant AllPrograms = "oldGC;RITSnew;otto;CATS;CCGG;MSD"
strconstant latKey = "brw:71.3;sum:72.5;nwr:40.04;mlo:19.5;smo:-14.3;spo:-66;alt:82.45;cgo:-40.68;kum:19.52;mhd:53.33;psa:-64.92;thd:40.10;lef:45.95;ush:-54.87;hfm:42.54;gmi:13.386;mid:28.210;asc:-7.967;eic:-27.160;"
latKey += "smox;-14.3"

Structure GlobalMean_Struct
	Variable FirstYear, LastYear
	String mol
	String prefix
	String site
	
	Wave NHinc, SHinc
	Wave NHnorm, SHnorm
	Wave Programs
	
	Wave NH, GG, SH
	Wave NHsd, GGsd, SHsd
	Wave NHnum, GGnum, SHnum
	Wave gdate
	Variable /D first_date
	
	// matrix of all stations and latitude bands
	Wave Stations, StationsSD
	Wave LatBans, LatBansSD, LatNorm
EndStructure

Structure SiteData_Struct
	String site
	String prog
	Wave MR, MRsd, MRnum, MRt		// data
	Wave MRI, MRIsd, MRInum, MRIt	// interpolated
EndStructure

Structure WeightedAvg_Struct
	Wave x1, y1, y1sd
	Wave x2, y2, y2sd
	Wave outx, outy, outysd
endStructure

// handles oldGC, otto predecessor, file names and path
function prog_OldGC(s)
	STRUCT SiteData_Struct &s
	
	SVAR mol = root:Global:S_mol
	String site = s.site
	s.prog = "oldGC"
	
	String P = "root:oldGC:"
	
	if (exists(P+mol+site) == 0 )
		return -1
	endif
	
	Wave s.MR = $P +mol + site
	Wave s.MRsd = $P + mol + site + "sd"

	// single flask measurements do not have a sd
	Wavestats/M=1 /Q s.MRsd
	greplace(s.MRsd, 0, V_avg)		// avg sd
	greplace(s.MR, -99, NaN)
	
	// add 3 ppt to sd error due to non-linearity in F12 correction
	if ((cmpstr(mol, "F12") == 0 ) && ( V_min < 3 ))
		s.MRsd += 3
	endif
	
	// make time 
	SetDataFolder $P
	
	String Ts = mol+site+"_time"
	//Wave Yr = $mol+"yr"
	//Wave Mo = $mol+"mon"
	Make /o/d/n=(numpnts(s.MR)) $Ts
	Wave s.MRt = $P + Ts
	s.MRt = date2secs(returnYear(s.MRt), returnMonth(s.MRt), 15)
	SetScale d 0,0,"dat", s.MRt

	SetDataFolder root:
	
	return 1
end

// handles CCGG file names and path
function prog_CCGG(s)
	STRUCT SiteData_Struct &s
	
	SVAR mol = root:Global:S_mol
	String site = s.site
	s.prog = "CCGG"
	
	String P = "root:CCGG:"
	
	if (exists(P + "CCGG_" + site+"_"+mol+"_mn") == 0)
		return -1
	endif

	Wave s.MR = $P + "CCGG_" + site + "_" + mol + "_mn"
	
	// make _sd waves
	String sd = P + "CCGG_" + site + "_" + mol + "_sd"
	if (! WaveExists($sd))
		Make /n=(numpnts(s.MR)) $sd=0.4
	endif	
	
	Wave s.MRsd = $P + "CCGG_" + site + "_" + mol + "_sd"
	Wave s.MRt = $P + "CCGG_" + mol + "_date"
	
	return 1
end

// handles otto file names and path
function prog_OTTO(s)
	STRUCT SiteData_Struct &s
	
	SVAR mol = root:Global:S_mol
	String site = s.site
	s.prog = "otto"
	
	String P = "root:otto:"
	
	if (exists(P+"otto_"+site+"_"+mol) == 0 )
		return -1
	endif
	
	Wave s.MR = $P + "otto_" + site + "_" + mol 
	Wave s.MRsd = $P + "otto_" + site + "_" + mol + "_sd"
	Wave s.MRt = $P + "otto_" + site +"_" + mol + "_date"
	
	return 1
end

// handles CATS file names and path
function prog_CATS(s)
	STRUCT SiteData_Struct &s
	
	SVAR mol = root:Global:S_mol
	String site = s.site
	s.prog = "CATS"
	
	String P = "root:month:"
	
	if (exists(P+site+"_"+mol) == 0 )
		return -1
	endif
	
	Wave s.MR = $P + site + "_" + mol
//	Wave s.MRsd = $P + site + "_" + mol + "_sd"
	Wave /Z s.MRsd = $P + site + "_" + mol + "_Var"		// switched to atmospheric variance
	if (WaveExists(s.MRsd) == 0)
		Wave s.MRsd = $P + site + "_" + mol + "_sd"
	endif
//	Wave s.MRnum = $P + site + "_" + mol + "_num"
	Wave s.MRt = $P + site + "_time"
	
	return 1
end

// handles RITS file names and path
function prog_RITS(s)
	STRUCT SiteData_Struct &s
	
	SVAR mol = root:Global:S_mol
	String site = s.site
	s.prog = "RITS"
	
	String P = "root:RITS:"
	
	if (exists(P+"RITS_"+site+"_"+mol) == 0 )
		return -1
	endif
	
	Wave s.MR = $P + "RITS_" + site + "_" + mol 
	Wave s.MRsd = $P + "RITS_" + site + "_" + mol + "_sd"
//	Wave s.MRnum = $P + "RITS_" + site + "_" + mol + "_num"
	Wave s.MRt = $P + "RITS_" + site + "_" + mol + "_date"
	
	return 1
end

// handles RITS file names and path
function prog_RITSNEW(s)
	STRUCT SiteData_Struct &s
	
	SVAR mol = root:Global:S_mol
	String site = s.site
	s.prog = "RITS"
	
	String P = "root:RITS:"
	
	if (exists(P+"RITS_"+site+"_"+mol + "_new") == 0 )
		return -1
	endif
	
	Wave s.MR = $P + "RITS_" + site + "_" + mol + "_new"
	Wave s.MRsd = $P + "RITS_" + site + "_" + mol + "_new_sd"
//	Wave s.MRnum = $P + "RITS_" + site + "_" + mol + "_num"
	Wave s.MRt = $P + "RITS_" + site + "_" + mol + "_new_date"
	
	return 1
end

// handles MSD flask file names and path
function prog_MSD(s)
	STRUCT SiteData_Struct &s
	
	SVAR mol = root:Global:S_mol
	String site = s.site
	s.prog = "MSD"
	
	// takes sites like smox and returns wave references to smo waves
	if (strlen(site) == 4)
		site = site[0,2]
	endif
	
	String P = "root:MSD:"
	
	if (exists(P+"MSD_"+site+"_"+mol) == 0 )
		return -1
	endif
	
	Wave s.MR = $P + "MSD_" + site + "_" + mol 
	Wave s.MRsd = $P + "MSD_" + site + "_" + mol + "_sd"
	Wave s.MRt = $P + "MSD_" + site + "_" + mol + "_date"
	
	return 1
end

// handles Perseus flask file names and path
function prog_PR1(s)
	STRUCT SiteData_Struct &s
	
	SVAR mol = root:Global:S_mol
	String site = s.site
	s.prog = "PR1"
	
	// takes sites like smox and returns wave references to smo waves
	if (strlen(site) == 4)
		site = site[0,2]
	endif
	
	String P = "root:PR1:"
	
	if (exists(P+"PR1_"+site+"_"+mol) == 0 )
		return -1
	endif
	
	Wave s.MR = $P + "PR1_" + site + "_" + mol 
	Wave s.MRsd = $P + "PR1_" + site + "_" + mol + "_sd"
	Wave s.MRt = $P + "PR1_" + site + "_" + mol + "_date"
	
	return 1
end


Function Global_Mean([insts, prefix, mol, plot, offsets])
	string insts, prefix, mol
	variable plot, offsets

	SVAR mollst = root:G_molLst
	SVAR Gmol = root:G_mol
	SVAR GinstList = root:global:S_InstList
	SVAR Gpre = root:global:S_prefix
	NVAR Gplot = root:global:G_plot
	NVAR Goff = root:global:G_offsets
	NVAR MCsim = root:simulation:G_MC
	SVAR sitesused = root:S_sitesused

	if ( ParamIsDefault(mol) )
		mol = Gmol
	endif
	if ( ParamIsDefault(insts) )
		insts = GinstList
	endif
	if ( ParamIsDefault(prefix) )
		prefix = Gpre
	endif
	if ( ParamIsDefault(plot) )
		plot = Gplot
	endif
	if ( ParamIsDefault(offsets) )
		offsets = Goff
	endif
	if ( ParamIsDefault(mol) || ParamIsDefault(insts) || ParamIsDefault(prefix))
		Prompt insts, "Select a set of instruments", popup, AllInsts
		Prompt mol, "Which gas?", popup, mollst+kMSDmols
		Prompt prefix, "Name waves with the following prefix:"
		Prompt plot, "Make Plot?", popup, "Yes;No"
		Prompt offsets, "Apply Offset variables?", popup, "No;Yes"
		DoPrompt "Global Mean:", insts, mol, prefix, plot, offsets
		if (V_flag)
			return -1
		endif
		Print "Global_Mean(insts=\"" + insts + "\", prefix=\"" + prefix + "\", mol=\"" + mol + "\", plot=" + num2str(plot) + ", offsets=" + num2str(offsets) + ")"
	endif
	
	insts = ReplaceString("+", insts, ";")			// turn inst into a ; list
	insts = ReplaceString("RITS", insts, "RITSnew")	// assume we want rits new
	insts = ReplaceString("RITSnewnew", insts, "RITSnew")	// assume we want rits new
	
	Gmol = mol
	GinstList = insts
	Gpre = prefix
	Gplot = plot
	Goff = offsets
	
	if ((Goff == 2) && (MCsim ==0))
		Printf "*** Applying offsets to some data: prefix=%s, mol=%s ***\r", prefix, mol 
	endif
	
	STRUCT GlobalMean_struct glb
	String list = "", inst
	Variable i

	// full set of sities
	String CATS = ReturnSiteDataList("brw;sum;nwr;mlo;smo;spo;", "CATS")
	String RITS =  ReturnSiteDataList("brw;nwr;mlo;smo;spo;", "RITS")
	String RITSNEW =  ReturnSiteDataList("brw;nwr;mlo;smo;spo;", "RITSNEW")
	String oldGC = ReturnSiteDataList("alt;brw;nwr;mlo;smo;cgo;spo;", "oldGC")
	String OTTO = ReturnSiteDataList(AllBKsitesOTTO, "otto")
	String CCGG = ReturnSiteDataList(AllBKsitesCCGG, "CCGG")
	String MSD = ReturnSiteDataList(AllBKsitesMSD, "MSD")
	String PR1 = ReturnSiteDataList(AllBKsitesMSD, "PR1")

	glb.prefix = prefix
	glb.FirstYear = 1998
	glb.LastYear = 1999
	for(i=0; i<ItemsInList(insts); i+=1)
		inst = StringFromList(i, insts)
		strswitch(UpperStr(inst))
			case "CATS":
				glb.FirstYear = min(glb.FirstYear, 1998)
				glb.LastYear = max(glb.LastYear, ReturnCurrentYear() + 1)
				if (cmpstr(mol, "MC")==0)	// don't use CATS MC data past 2013
					glb.LastYear = 2013
				endif
				list = DataSetKeyAdd(list, CATS)
				break
			case "RITS":
				glb.FirstYear = min(glb.FirstYear, 1987)
				glb.LastYear = max(glb.LastYear, 2002)
				list = DataSetKeyAdd(list, RITS)
				break
			case "RITSNEW":
				glb.FirstYear = min(glb.FirstYear, 1987)
				glb.LastYear = max(glb.LastYear, 2002)
				list = DataSetKeyAdd(list, RITSNEW)
				break
			case "OTTO":
				glb.FirstYear = min(glb.FirstYear, 1994)
				glb.LastYear = max(glb.LastYear, ReturnCurrentYear() + 1)
				list = DataSetKeyAdd(list, OTTO)
				break
			case "OLDGC":
				glb.FirstYear = min(glb.FirstYear, 1977)
				glb.LastYear = max(glb.LastYear, 1995)
				list = DataSetKeyAdd(list, oldGC)
				break
			case "CCGG":
				glb.FirstYear = min(glb.FirstYear, 2001)
				glb.LastYear = max(glb.LastYear, ReturnCurrentYear() + 1)
				list = DataSetKeyAdd(list, CCGG)
				break
			case "MSD":
				glb.FirstYear = min(glb.FirstYear, 1992)
				glb.LastYear = max(glb.LastYear, ReturnCurrentYear() + 1)
				glb.first_date = date2secs(glb.FirstYear, 1, 1)
				list = DataSetKeyAdd(list, MSD)
				break
			case "PR1":
				glb.FirstYear = min(glb.FirstYear, 2014)
				glb.LastYear = max(glb.LastYear, ReturnCurrentYear() + 1)
				glb.first_date = date2secs(glb.FirstYear, 1, 1)
				list = DataSetKeyAdd(list, PR1)
				break
		endswitch
	endfor
	
	// commented out GSD 200813
	//glb.FirstYear = 1977
	//glb.LastYear = ReturnCurrentYear() + 1
	
	GlobalMeanFunction(glb, mol, list)
	
	// can't interpolate BRW for CH3Cl, remove interpolated section  from 6/02 to 12/02 
	if (( cmpstr(mol, "CH3Cl") == 0 ) && (cmpstr(prefix, "insitu")==0))
		K0 = BinarySearch(glb.gdate, date2secs(2002, 6, 15))
		K1 = BinarySearch(glb.gdate, date2secs(2002, 12, 16))
		glb.GG[K0, K1] = NaN
		glb.NH[K0, K1] = NaN
		glb.NHsd[K0, K1] = NaN
	endif
	
	NVAR MCsim = root:simulation:G_MC
	// shorten waves if all NaNs
	if (MCsim == 0)
		ShortenGlbWaves(glb)
	endif
	
	if (plot==1)
		GlobalMeanPlot(insts=GinstList, prefix=Gpre, mol=Gmol)
	endif
	
end

// creates a list key
Function/S ReturnSiteDataList(sites, inst)
	string sites, inst
	
	Variable i
	String lst = ""
	
	for(i=0; i<ItemsInList(sites); i+=1)
		lst += StringFromList(i, sites) + ":" + inst + ";"
	endfor
	
	return lst
	
end

// Adds site lists strings together
// there is no error checking to make sure there are duplicate sites with the same name
function/S DataSetKeyAdd(org, add)
	string org, add
	
	String loc, site, insts_add, insts_org
	Variable i
	
	for(i=0; i<ItemsInList(add); i+=1)
		loc = StringFromList(i, add)				// site and instruments
		site = StringFromList(0, loc, ":")			// station code
		insts_add = StringByKey(site, loc)			// instruments (ie CATS,RITS)
		insts_org = StringByKey(site, org)
		if ( strlen(insts_org) > 0 )
			insts_org += "," + insts_add
		else
			insts_org += insts_add
		endif
		org = ReplaceStringByKey(site, org, insts_org)
	endfor

	return org
	
end

// Makes standard error wave
function MakeSTDERR(inst, sd, suf)
	string inst, suf
	wave sd
	
	string stdes = "stde" + suf
	SVAR mol = root:global:S_mol
	
	Duplicate /O sd, $stdes/Wave=stde
	
	if (cmpstr(inst, "CATS") == 0)
		stde  /= sqrt(14)
	elseif (cmpstr(inst, "RITS") == 0)
		stde /= sqrt(2)
	elseif (cmpstr(inst, "RITSNEW") == 0)
		stde /= sqrt(2)
	elseif (cmpstr(inst, "OTTO") == 0)
		// otto monthly files are already sqrt(N)
		// average 
		if (cmpstr(mol, "N2O") == 0 )
			stde = SelectNumber(sd < 0.7, sd, 0.7)
		else
			//stde /= sqrt(3)
		endif
	elseif (cmpstr(inst, "MSD") == 0)
		stde /= sqrt(4)
	elseif (cmpstr(inst, "oldGC") == 0)
		//stde /= sqrt(2)
	elseif (cmpstr(inst, "CCGG") == 0)
		stde /= sqrt(2)
	endif
	
end

// Creates temporary waves and calls the station acumulator function
function GlobalMeanFunction(glb, mol, datasets)
	STRUCT GlobalMean_struct &glb
	String mol, datasets
	
	Variable j, i, pt, numinsts, colS
	String loc, site, instruments, instrument
	SetDataFolder root:global:

	SVAR sitesused = root:S_sitesused
	String /G S_mol = mol
	String /G S_site = ""
	SVAR Gsite = S_site
	glb.mol = mol
	MakeGlobalMeanWaves(glb)

	Wave latbin = root:global:latbin
	
	// used in weighting calculation for Add_station_LatBands or Station_LatBands
	latbin_count_reset()
	for(j=0; j<ItemsInList(datasets); j+=1 )
		loc = StringFromList(j, datasets)			// site and instruments
		site = StringFromList(0, loc, ":")			// station code
		if (findlistitem(site, sitesused) >= 0)
			latbin_count(site)
		endif
	endfor

	// step through each site
	for(j=0; j<ItemsInList(datasets); j+=1 )
		STRUCT SiteData_Struct s
		loc = StringFromList(j, datasets)			// site and instruments
		site = StringFromList(0, loc, ":")			// station code
		instruments = StringByKey(site, loc)		// instruments (ie CATS,RITS)
		s.site = site

		if (findlistitem(site, sitesused) >= 0)
			// add up instruments at a given site, glb.site
			WeightedMean_ofasite(site, instruments, glb)
			
			// loop through each instrument program at each site
			for(i=0; i<ItemsInList(instruments, ","); i+=1)
				instrument = StringFromList(i, instruments, ",")
				ReturnStationStruct(s, instrument)
				string extra = "_"
				if (cmpstr(s.prog, "CATS") == 0)
					extra = "_Ca_"
				endif
				cd root:interp
				string MRIstr = glb.prefix + extra + Nameofwave(s.MR) + "_I"
				Wave /Z s.MRI = $MRIstr
				cd root:
				if (WaveExists(s.MRt))
					UpDateProgramsMatrix(instrument, s, glb)
				endif
			endfor
		endif
			
	endfor
	
	if ((cmpstr(mol, "F113") == 0) & (cmpstr(glb.prefix, "HATS") == 0))
		Filter_ifCATSonlyProgram("F113")
	endif
	if ((cmpstr(mol, "F11") == 0) & (cmpstr(glb.prefix, "HATS") == 0))
		Filter_ifCATSonlyProgram("F11")
	endif
	if ((cmpstr(mol, "F12") == 0) & (cmpstr(glb.prefix, "HATS") == 0))
		Filter_ifCATSonlyProgram("F12")
	endif
	
	// sum up latitudes
	Station_LatBands(glb)
		
	// normalize with cosine wighting	
	glb.NH  /= glb.NHnorm	
	glb.NHsd = sqrt(glb.NHsd/glb.NHnorm)
	glb.SH /= glb.SHnorm
	glb.SHsd = sqrt(glb.SHsd/glb.SHnorm)
	
	// if less than 2 sites set to NaN
	glb.NH = SelectNumber(glb.NHinc>1, NaN, glb.NH)
	glb.NHsd = SelectNumber(glb.NHinc>1, NaN, glb.NHsd)
	glb.SH = SelectNumber(glb.SHinc>1, NaN, glb.SH)
	glb.SHsd = SelectNumber(glb.SHinc>1, NaN, glb.SHsd)
	
	// global means
	glb.GG = (glb.NH + glb.SH) / 2
	glb.GGsd = sqrt(glb.NHsd^2 + glb.SHsd^2)
	
	// lat bands
	glb.LatBans /= glb.LatNorm
	glb.LatBansSD /= sqrt(glb.LatBansSD/glb.LatNorm)
	//DeletePoints/M=1 0,1, glb.LatBans, glb.LatBansSD
	
	// delete temporary waves _norm and _inc
	Wave NH = glb.NHnorm, NHi = glb.NHinc
	Wave SH = glb.SHnorm, SHi = glb.SHinc
	Wave latN = glb.LatNorm
	Wave SitesLat = $"root:global:" + glb.prefix + "_Sites_" + glb.mol + "_lat"	// added 200506
	Killwaves /Z  NH, SH, NHi, SHi, latN, SitesLat

	Killwaves /Z stde1, mmFill_L, mmTfill_L, mmNUMfill		// from Iterp_InstStation function
	
	SetDataFolder root:
end


// finds the first row in the "sites" wave that has data, removes all rows above
// same with the last rows
Function ShortenGlbWaves(glb)
	STRUCT GlobalMean_struct &glb
	
	variable i, pt, pt2
	
	pt = FirstGoodDataMatrix(glb.Stations)
	wave dd = glb.gdate
	
	String DF = "root:global:"
	Wave YYYY = $(DF + glb.prefix + "_" + glb.mol + "_YYYY")
	Wave MM = $(DF+ glb.prefix + "_" + glb.mol + "_MM")
	
	DeletePoints 0, pt, glb.NH, glb.GG, glb.SH, glb.NHsd, glb.GGsd, glb.SHsd, glb.gdate, glb.Stations, glb.StationsSD, glb.LatBans, glb.LatBansSD, YYYY, MM
	DeletePoints 0, pt, glb.Programs
	
end

// Returns row number of first row with real data (not all NaNs)
//   brute force, row by row, must be a better way?
function FirstGoodDataMatrixOld(mt)
	wave mt
	
	variable i
	for(i=0; i<Dimsize(mt, 0); i+=1)
		MatrixOp /FREE row = row(mt, i)
		Wavestats /Q/M=1 row
		if (numtype(v_avg) == 0)
			break
		endif
	endfor
	
	return i
end

//faster than function above
// There was a bug in this routine. GSD 20210616
// crit = greater(productRows(replaceNaNs(mt,1)), 1) would fail for mixing ratios less than 1 (ie HFC365mfc).
function FirstGoodDataMatrix(mt)
	wave mt
	
	variable i
	MatrixOp /FREE crit = equal(productRows(replaceNaNs(mt,1)), 1)
	for(i=0; i<Dimsize(mt, 0); i+=1)
		if (crit[i] != 1)
			return i
		endif
	endfor
	
	return -1
end


// Plots hemispheric and global means
Function GlobalMeanPlot([insts, prefix, mol, offsets])
	string insts, prefix, mol
	variable offsets

	SVAR mollst = root:G_molLst
	SVAR Gmol = root:G_mol
	SVAR GinstList = root:global:S_InstList
	SVAR Gpre = root:global:S_prefix
	NVAR Goff = root:global:G_offsets

	if ( ParamIsDefault(mol) )
		mol = Gmol
	endif
	if ( ParamIsDefault(insts) )
		insts = GinstList
	endif
	if ( ParamIsDefault(prefix) )
		prefix = Gpre
	endif
	if ( ParamIsDefault(offsets) )
		offsets = Goff
	endif
	if ( ParamIsDefault(mol) || ParamIsDefault(insts) || ParamIsDefault(prefix))
		Prompt insts, "Select a set of instruments", popup, AllInsts
		Prompt mol, "Which gas?", popup, mollst
		Prompt prefix, "Name waves with the following prefix:"
		Prompt offsets, "Apply Offset variables?", popup, "No;Yes"
		DoPrompt "Global Mean:", insts, mol, prefix
		if (V_flag)
			return -1
		endif
	endif

	//Global_Mean(prefix=prefix, insts=insts, mol=mol, offsets=Goff)

	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:global:
	
	string com
	string GG = prefix + "_global_" + mol
	string NH = prefix + "_NH_" + mol
	string SH = prefix + "_SH_" + mol
	string TTT = prefix + "_" + mol + "_date"
	String Win = prefix + "_Global_Mean_Figure_" + mol

	DoWindow /K $win
	Display /K=1/W=(572,196,1405,704)/K=1  $GG vs $TTT
	DoWindow /C $win
	
	AppendToGraph $NH vs $TTT
	AppendToGraph $SH vs $TTT
	SetDataFolder fldrSav0
	
	ModifyGraph margin(bottom)=90,gFont="Georgia",gfSize=18,gmSize=2
	ModifyGraph lSize=3
	ModifyGraph rgb($GG)=(0,0,0),rgb($NH)=(0,0,65535),rgb($SH)=(52428,1,1)
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,1,1,2,"Year",-1}
	ModifyGraph manTick(bottom)={2082844800,5,0,0,yr},manMinor(bottom)={0,50}
	
	Label left "\\f01" + FullMolName(mol)
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	
	Sprintf win, "\\s(%s) Global\r\\s(%s) Northern\r\\s(%s) Southern", GG, NH, SH
	Legend/C/N=legend/J/S=3/X=42.55/Y=79.60 win
	AppendNOAALogo("NOAA/GML halocarbons group", txt2=date())
End

// Accumulates stations into global mean bins
Function ReturnStationStruct(s, instrument)
	STRUCT SiteData_Struct &s
	String  instrument

	strswitch( instrument )
		case "CATS":
			return prog_CATS(s)
			break
		case "RITS":
			return prog_RITS(s)
			break
		case "RITSNEW":
			return prog_RITSNEW(s)
			break
		case "otto":
			return prog_OTTO(s)
			break
		case "oldGC":
			return prog_OldGC(s)
			break
		case "CCGG":
			return prog_CCGG(s)
			break
		case "MSD":
			return prog_MSD(s)
			break
		case "PR1":
			return prog_PR1(s)
			break
		default:
			abort "Unknown program: " + instrument
	endswitch
	
	return -1
	
end

// zonal means calculated
Function Station_LatBands(glb)
	STRUCT GlobalMean_struct &glb

	Variable lat, i, j, colL
	String site
	NVAR MCsim = root:simulation:G_MC
	Wave latbin = root:global:latbin
	Variable latcount, coslat

	//Wave SitesLat = $"root:global:" + glb.prefix + "_Sites_" + glb.mol + "_lat"
	
	MatrixOP /FREE sta = Replace(glb.stations, NaN, 0)
	MatrixOP /FREE staSD = Replace(glb.stationsSD, NaN, 0)
		
	for(i=0; i<ItemsInList(AllSites); i+=1)
		site = StringFromList(i, AllSites)
		lat = NumberByKey(site, latKey)
		//SitesLat[i] = lat
		
		// tweak lat if G_MC == 4
		if (MCsim == 4)
			lat += enoise(10)	// tweak lat +/- 10 deg
		endif
		lat *= RAD

		MatrixOp /FREE sta_tmp = col(sta, i)
		
		if (mean(sta_tmp) > 0)
			latcount = latbin_returncount(site)
			//latcount = 1
			coslat = cos(lat)/latcount
	
			if ( lat > 0 )
				glb.NH += SelectNumber(sta[p][i] > 0, 0, sta[p][i] * coslat)
				glb.NHsd += SelectNumber(sta[p][i] > 0, 0, (staSD[p][i]^2 * coslat))
				glb.NHnorm += SelectNumber(sta[p][i] > 0, 0, coslat)
				glb.NHinc += SelectNumber(sta[p][i] > 0, 0, 1)
			else
				glb.SH += SelectNumber(sta[p][i] > 0, 0, sta[p][i] * coslat)
				glb.SHsd += SelectNumber(sta[p][i] > 0, 0, (staSD[p][i]^2 * coslat))
				glb.SHnorm += SelectNumber(sta[p][i] > 0, 0, coslat)
				glb.SHinc += SelectNumber(sta[p][i] > 0, 0, 1)
			endif
			
	
			// lat specific
			colL = latbin_returnlat(lat/RAD)
			glb.LatBans[][colL] += SelectNumber(sta[p][i] > 0, 0, sta[p][i] * coslat)
			glb.LatBansSD[][colL] += SelectNumber(sta[p][i] > 0, 0, (staSD[p][i]^2 * coslat))
			glb.LatNorm[][colL] += SelectNumber(sta[p][i] > 0, 0, coslat)
			
		endif
	endfor

	//edit glb.NH, glb.NHnorm, glb.NHinc

end

	

// latbin functions are used to bin up stations in latitudinal bands
function latbin_edit()
	if (exists("root:global:latbin") == 0)
		make /n=8/o root:global:latbin
	endif
	Wave latbin = root:global:latbin
	latbin[][1] = 0
	edit root:global:latbin
end

// adds one for bin that the site lands in
function latbin_count(site)
	string site
	
	Variable lat = NumberByKey(site, latKey)
	Variable i
	Wave latbin = root:global:latbin
	
	for (i=0;i<Dimsize(latbin,0); i+=1)
		if (lat >= latbin[i][0])
			latbin[i][1] += 1
			break
		endif
	endfor
end

// sets counter column back to 0
function latbin_count_reset()
//	if (exists("root:global:latbin") == 0)
//		make /n=8/o root:global:latbin
//	endif
	Wave latbin = root:global:latbin
	latbin[][1] = 0
end

// returns the number of stations or sites in latbin based off of a site's location.
function latbin_returncount(site)
	string site
	
	Wave latbin = root:global:latbin
	Variable lat = NumberByKey(site, latKey)
	Variable i
	for (i=0;i<DimSize(latbin,0);i+=1)
		if (lat >= latbin[i][0])
			return latbin[i][1]
		endif
	endfor
	
	return -1 // error	
end

// returns the lat bin nearest lat
function latbin_returnlat(lat)
	variable lat

	Wave latbin = root:global:latbin
	Variable i
	for (i=0; i<DimSize(latbin,0); i+=1)
		if (lat >= latbin[i][0])
			return i
		endif
	endfor
	
	return -1 // error	
end

// Each column in the program matrix is for a different measurement program.
function UpDateProgramsMatrix(inst, s, glb)
	String inst
	//Wave MRt
	STRUCT SiteData_struct &s
	STRUCT GlobalMean_struct &glb
	
	SetDataFolder root:interp
	
	string extra = "_"
	if (cmpstr(s.prog, "CATS") == 0)
		extra = "_Ca_"
	endif
	string intTTstr = glb.prefix + extra + Nameofwave(s.MRt) + "_I"
	Wave s.MRIt = $intTTstr
	
	Variable i, pt
	// col number in Program matrix
	Variable col = WhichListItem(inst, AllPrograms,";", 0, 0)
	
	// program
	// found a bug where I was using s.MRt instead of s.MRIt  20200422
	for (i=0; i<numpnts(s.MRIt); i+=1)
		pt = round(BinarySearchInterp(glb.gdate, s.MRIt[i] + 60*60*24))
		if (numtype(pt) != 0)
			pt = numpnts(s.MRIt)
		endif
		// if any MRI is not NaN use glb.Programs (this maybe set from other stations, can't use a 0)
		glb.Programs[pt][col] = SelectNumber(numtype(s.MRI[i])==0, glb.Programs, 1)
	endfor	
	SetDataFolder root:
end


// function returns a binary string representing which programs were used
// in calculating the global mean
Function/S ReturnProgramsString(prefix, mol, TT)
	String prefix, mol
	Variable /D TT
	
	string  GL = "root:global:"
	Wave/Z D = $GL + prefix + "_" + mol + "_date"
	Wave/Z Pr = $GL + prefix + "_Programs_" + mol
	
	if (!WaveExists(D) || !WaveExists(Pr))
		return "-1"
	endif
	
	Variable row = round(BinarySearchInterp(D, TT))
	Variable n = ItemsInList(AllPrograms), col
	String bin = ""
	
	If ( row < 0 )
		return "-1"
	endif
		
	For(col=0; col<n; col+=1)
		bin += num2str(Pr[row][col])
	Endfor

	return bin
end

// removes Site data if only CATS is used
Function Filter_ifCATSonlyProgram(mol)
	String mol
	
	Wave prjs = $"root:global:" + "HATS_Programs_" + mol
	Wave sites = $"root:global:" + "HATS_Sites_" + mol
	Wave sitesSD = $"root:global:" + "HATS_Sites_" + mol + "_sd"
	Wave DD = $"root:global:" + "HATS_" + mol + "_date"
	variable i, j, pt, pt_msd, col
	variable /D month
	string station
	string cats_sites = "brw;nwr;mlo;smo;spo"
	
	MatrixOP /FREE binarysum = sumRows(powR(2, indexCols(prjs)) * prjs)
	Extract /FREE/INDX binarysum, match_idxs, (binarysum == 8) | (binarysum == 40)		// 8 is only CATS data, 40 CATS and MSD
	
	for(i=0; i<numpnts(match_idxs); i+=1)
		pt = match_idxs[i]
		for(j=0; j<ItemsInList(cats_sites); j+=1)
			station = StringFromList(j, cats_sites)
			col = WhichListItem(station, AllSites)
			month = DD[pt]
			wave msd = $"root:MSD:MSD_" + station + "_" + mol
			wave msd_date = $"root:MSD:MSD_" + station + "_" + mol + "_date"
			pt_msd = BinarySearchInterp(msd_date, month)
			if (numtype(pt_msd) == 2)
				sites[pt][col] = nan
				sitesSD[pt][col] = nan
				//print pt, secs2date(month, -2), pt_msd, station, msd[pt_msd]
			endif
		endfor
	endfor

end

// interpolates a particular site's data for a given program
// creates waves with original MR name and a _I suffix
// structure s has the interpolated wave references
function Interp_InstStation(glb, s)
	STRUCT GlobalMean_struct &glb
	STRUCT SiteData_Struct &s

	String CDF = GetDataFolder(1)
	NVAR Goff = root:global:G_offsets
	variable offset = 0
	
	if ( ! WaveExists(s.MR) )
		return 0
	endif

	variable i, pt
	
	string extra = "_"
	if (cmpstr(s.prog, "CATS") == 0)
		extra = "_Ca_"
	endif
	string intMDstr = glb.prefix + extra + Nameofwave(s.MR) + "_I"
	string intSDstr = glb.prefix + extra + Nameofwave(s.MRsd) + "_I"
	string intTTstr = glb.prefix + extra + Nameofwave(s.MRt) + "_I"
	string notestr

	NewDataFolder /O/S root:interp

	// apply offset?
	if (Goff == 2)  // 2 == yes
		offset = ReturnOffset(s.prog, glb.mol)
		Duplicate /FREE s.MR, MRback
		s.MR *= (100 + offset)/100
	endif
	
	if (!WaveExists(s.MR))
		SetDataFolder root:
		return -1
	endif
	if (numpnts(s.MR) < 2)
		SetDataFolder root:
		return -1
	endif

	// Check if the data wave is all NaNs
	Wavestats /M=1/Q s.MR
	if (V_npnts < 2)
		SetDataFolder root:
		return -1
	endif

	// use standard error instead of sd
	MakeSTDERR(s.prog, s.MRsd, "1")
	Wave stde1 = stde1
	
	// double the error for smo
	if (cmpstr(s.site, "smo") == 0)
		stde1 *= 2
	endif
	
	Make /o/n=(DimSize(glb.gdate,0)) $intMDstr/Wave=intMD = NaN
	Make /o/n=(DimSize(glb.gdate,0)) $intSDstr/Wave=intSD = NaN
	Duplicate /o glb.gdate, $intTTstr/Wave=intTT						/// could remove intTT and stick with glb.gdate but would need to reprogram a bit.
	
	// Map MR to glb.gdate
	for(i=0;i<numpnts(s.MRt); i+=1)
		pt = BinarySearchInterp(glb.gdate, s.MRt[i])
		if (numtype(pt) == 0)
			intMD[pt] = s.MR[i]
//			intSD[pt] = s.MRsd[i]
			intSD[pt] = stde1[i]
		elseif (numtype(pt) == 2)		// handles if NaN
			intMD[0] = s.MR[0]
//			intSD[0] = s.MRsd[0]
			intSD[0] = stde1[0]
		endif
	endfor


	// monte carlo fit
	variable num = (glb.LastYear-glb.FirstYear)*12 
	variable monteiters = 50	// set to 100 for more robust fit
	Wave /Z MCmed = $"root:simulation:fx_" + intMDstr + "_av"
	//Killwaves /Z MCmed			// force to recalc MonteCarlo_Fit
	if (!WaveExists(MCmed))
		MonteCarlo_Fit(intTT, intMD, intSD, iters=monteiters, plt=0)
	elseif (num != numpnts(MCmed))
		MonteCarlo_Fit(intTT, intMD, intSD, iters=monteiters, plt=0)
	endif
	
	Wave /Z MCmed = $"root:simulation:fx_" + intMDstr + "_av"
	Wave /Z MCsd = $"root:simulation:fx_" + intMDstr + "_sd"

	// Use monte carlo results
	intSD = SelectNumber(numtype(intMD)==2, intSD, MCsd)
	intMD = SelectNumber(numtype(intMD)==2, intMD, MCmed)
	
	// ************* Special Case code below *************
	Variable p1, p2, p3
	
	if (cmpstr(s.prog, "MSD") == 0)
		// remove large gap interpolation -- this only effects h-2402 and HCFC141b (MHD)
		NANgaps(s.MR, s.MRt, 12 * 30*24*60*60)		//12 month gaps
		wave gapIDX
		if (numpnts(gapIDX) > 0)
			for(i=0; i<numpnts(gapIDX); i+=2)
				p1 = BinarySearchInterp(intTT, s.MRt[gapIDX[i]])
				p2 = BinarySearchInterp(intTT, s.MRt[gapIDX[i+1]])
				intMD[p1+3, p2-3] = NaN
				intSD[p1+3, p2-3] = NaN
			endfor
		endif
	endif
	
	// smooth the old flask gc data except for the short cgo record
	if ((cmpstr(s.prog, "oldGC") == 0))
		p1 = FirstGoodPt(intMD)
		p2 = LastGoodPt(intMD)
		if ( (cmpstr(s.site, "cgo") == 0) || (cmpstr(s.site, "alt") == 0))
			Loess/E=1/Z=1/SMTH=0.2  factors={intTT}, srcWave= intMD
		else
			Loess/E=1/SMTH=0.05 factors={intTT}, srcWave= intMD
		endif
		intMD[0,p1-1] = nan
		intMD[p2+1, numpnts(intMD)] = nan
		
		// don't use interpolated data from 11/1/91 to 11/1/94
		//     I commented this out, F11 seems okay.  Maybe should exclude these dates for N2O?  GSD 150128
		//p1 = BinarySearchInterp(intTT, date2secs(1991,11,1))
		//p2 = BinarySearchInterp(intTT, date2secs(1994,11,1))
		//intMD[p1,p2] = NaN
	endif
	
	// extends the otto data with a linear fit to last 3 years of data
	if ((cmpstr(s.prog, "OTTO") == 0))
		variable months = 6
		//if (cmpstr(glb.mol, "F11") == 0)
		//	months = 6		// less since linear fit is not a good representation
		//endif
		p2 = LastGoodPt(intMD)
		p1 = p2-36
		CurveFit/Q/X=1 line intMD[p1,p2]  /W=intSD /I=1
		Wave coef = W_coef
		variable yyyy = ReturnCurrentYear()
		variable MM = str2num(StringFromList(1, Secs2date(DateTime,-1), "/"))
		p3 = BinarySearchInterp(intTT, date2secs(yyyy, MM, 1))
		// extend only 12 months a most
		p3 = min(p2+months, p3)
		intMD[p2, p3] = coef[0] + x*coef[1]
		WaveStats/Q/R=[p1,p2] intSD
		intSD[p2, p3] = V_avg + V_avg * (p-p2)/12		// scale the avg error the further the forecast
	endif
	
	// set site structure up
	Wave s.MRI = intMD
	Wave s.MRIsd = intSD
	Wave s.MRIt = intTT
//	Wave s.MRInum = mmNUMfill

	if (Goff == 2)
		s.MR = MRback
	endif
	
	SetDataFolder CDF
	
end



// return offset value stored in offset datafolder for a given program and molecule
Function ReturnOffset(prog, mol)
	string prog, mol

	wave /t molwv = root:save:mol_wave
	wave offsets = $"root:offsets:" + prog
	variable offset = 0, inc
	
	for(inc = 0; inc<numpnts(molwv); inc+=1 )
		if ( cmpstr(molwv[inc], mol) == 0) 
			offset = offsets[inc]
			break
		endif
	endfor
	return offset
end


/// Find large NaN gaps in wv the gap point indexes are returned via gapIDX wave
function NANgaps(wv, wvx, duration)
	wave wv, wvx
	variable duration
	
	variable i, p1 = -1, p2 = -1
	Make /O/n=(numpnts(wv)) gapIDX=NaN
	
	for(i=0;i<numpnts(wv);i+=1)
		if ((numtype(wv[i]) == 2) && (p1 == -1))		// start of gap
			p1 = i
		elseif ((numtype(wv[i]) == 2) && (p1 != -1))	// still a gap
			p2 = i
		elseif (numtype(wv[i]) == 0)						// end found or good value
			if ((p2 != -1) && ((wvx[p2] - wvx[p1]) > duration))
				gapIDX[p1] = p1
				gapIDX[p2] = p2
				//print p1, p2, (wvx[p2] - wvx[p1])
			endif
			p1 = -1
			p2 = -1
		endif
	endfor
	
	RemoveNaNs(gapIDX)
	
end


function RetrunInterpRefs(s, prefix)
	STRUCT SiteData_Struct &s
	string prefix

	if ( ! WaveExists(s.MR) )
		return 0
	endif
	
	String CDF = GetDataFolder(1)
	
	SetDataFolder root:interp
	
	string extra = "_"
	if (cmpstr(s.prog, "CATS") == 0)
		extra = "_Ca_"
	endif

	string mmFillstr = prefix + extra + Nameofwave(s.MR) + "_I"
	string mmSDfillstr = prefix + extra + Nameofwave(s.MRsd) + "_I"
	string mmTfillstr = prefix + extra + Nameofwave(s.MRt) + "_I"
	
	// set site structure up
	Wave /Z s.MRI = $mmFillstr
	Wave /Z s.MRIsd = $mmSDfillstr
	Wave /Z s.MRIt = $mmTfillstr
//	Wave s.MRInum = mmNUMfill

	SetDataFolder CDF

end

// Smooths the glb.station matrix column (site) by column
Function Station_smooth(site, glb)
	String site
	STRUCT GlobalMean_struct &glb

	NVAR /Z MCsim = root:simulation:G_MC
	
	Variable pt1, pt2
	Variable colS = WhichListItem(site, AllSites)

	// don't smooth for MC simulation
	If (MCsim)
		return 0
	endif

	MatrixOp /FREE sta = col(glb.stations, colS)
	Wavestats/M=1/Q sta

	if (V_npnts > 2)
		MatrixOp /FREE staSD = col(glb.stationsSD, colS)
		Duplicate /FREE sta, sta_org
		
		// Don't smooth gases with large seasonal cycles
		//if (cmpstr(glb.mol, "OCS") != 0)
			//Smooth/E=3 2, sta
			Smooth/E=3 /S=4 7, sta		// minimal Savitzky-Golay smoothing.  Other smoothing methods reduce seasonal cycles.
		//endif

		// insert first data points
		pt1 = FirstGoodPt(sta)
		pt2 = FirstGoodPt(sta_org)
		sta[pt2,pt1] = sta_org

		// insert last data point because it was removed after the smooth
		pt1 = lastGoodPt(sta)
		pt2 = lastGoodPt(sta_org)
		sta[pt1,pt2] = sta_org
		
		// insert average sd for missing months
		Wavestats /M=1/Q staSD
		staSD = SelectNumber(numtype(staSD)==2, staSD, V_avg)
		
		glb.stations[][colS] = sta[p]
		glb.stationsSD[][colS] = staSD[p]
	endif

end


// creates the hemispheric and global mean waves
function MakeGlobalMeanWaves(glb)
	STRUCT GlobalMean_struct &glb

	String CDF = GetDataFolder(1)
	SetDataFolder root:global:

	Variable Fy = glb.FirstYear
	Variable Ly = glb.LastYear
	Wave latbin = root:global:latbin
	
	// means
	String NHstr = glb.prefix + "_NH_" + glb.mol
	String SHstr = glb.prefix + "_SH_" + glb.mol
	String GGstr = glb.prefix + "_Global_" + glb.mol
	Make /O/N=((Ly-Fy)*12) $NHstr = 0, $GGstr = 0, $SHstr = 0
	Wave glb.NH = $NHstr
	Wave glb.GG = $GGstr
	Wave glb.SH = $SHstr 

	// sd
	NHstr = glb.prefix + "_NH_" + glb.mol + "_sd"
	SHstr = glb.prefix + "_SH_" + glb.mol + "_sd"
	GGstr = glb.prefix + "_Global_" + glb.mol + "_sd"
	Make /O/N=((Ly-Fy)*12) $NHstr = 0, $GGstr = 0, $SHstr = 0
	Wave glb.NHsd = $NHstr
	Wave glb.GGsd = $GGstr
	Wave glb.SHsd = $SHstr 

	// num
//	NHstr = glb.prefix + "_NH_" + glb.mol + "_num"
//	SHstr = glb.prefix + "_SH_" + glb.mol + "_num"
//	GGstr = glb.prefix + "_Global_" + glb.mol + "_num"
//	Make /O/N=((Ly-Fy)*12) $NHstr = 0, $GGstr = 0, $SHstr = 0
//	Wave glb.NHnum = $NHstr
//	Wave glb.GGnum = $GGstr
//	Wave glb.SHnum = $SHstr  

	// num sites with a measurement
	NHstr = glb.prefix + "_NH_" + glb.mol + "_inc"
	SHstr = glb.prefix + "_SH_" + glb.mol + "_inc"
	Make /O/N=((Ly-Fy)*12) $NHstr = 0, $SHstr = 0
	Wave glb.NHinc = $NHstr
	Wave glb.SHinc = $SHstr 

	// cos weighted normalizing waves
	NHstr = glb.prefix + "_NH_" + glb.mol + "_norm"
	SHstr = glb.prefix + "_SH_" + glb.mol + "_norm"
	Make /O/N=((Ly-Fy)*12) $NHstr = 0, $SHstr = 0
	Wave glb.NHnorm = $NHstr
	Wave glb.SHnorm = $SHstr 

	// sites matrix	
	String Sites = glb.prefix + "_Sites_" + glb.mol
	String SitesSD = Sites + "_sd"
	String SitesLat = Sites + "_lat"
	Make /O/N=((Ly-Fy)*12, ItemsInList(AllSites)) $Sites = NaN
	Make /O/N=((Ly-Fy)*12, ItemsInList(AllSites)) $SitesSD = NaN
	Make /O/N=(ItemsInList(AllSites)) $SitesLat = NaN
	Wave glb.Stations = $Sites
	Wave glb.StationsSD = $SitesSD
	
	// lat bin matrix
	String lats = glb.prefix + "_LatBan_" + glb.mol
	String latsSD = lats + "_sd"
	String latNorm = glb.prefix + "_LatNorm_" + glb.mol
	Make /O/N=((Ly-Fy)*12, DimSize(latbin,0)) $lats = 0
	Make /O/N=((Ly-Fy)*12, DimSize(latbin,0)) $latsSD = 0
	Make /O/N=((Ly-Fy)*12, DimSize(latbin,0)) $latNorm = 0
	Wave glb.LatBans = $lats
	Wave glb.LatBansSD = $latsSD
	Wave glb.LatNorm = $latNorm
	
	// Programs Matrix
	String Prog = glb.prefix + "_Programs_" + glb.mol
	Make /O/N=((Ly-Fy)*12, ItemsInList(AllPrograms)) $Prog = 0
	Wave glb.Programs = $Prog
	
	// date
	MakeGlobalDateWave(glb)
	
	SetDataFolder CDF

end

// creates date wave for hemisphere and global means
Function MakeGlobalDateWave(glb)
	STRUCT GlobalMean_struct &glb
	
	variable inc, minc, yinc, day, hour, num = (glb.LastYear-glb.FirstYear)*12

	// date
	String TTstr = glb.prefix + "_" + glb.mol + "_date"
	String YYYYstr = glb.prefix + "_" + glb.mol + "_YYYY"
	String MMstr = glb.prefix + "_" + glb.mol + "_MM"
	Make /D/O/N=(num) $TTstr/Wave=TT, $YYYYstr/Wave=YYYY, $MMstr/Wave=MM
	Wave glb.gdate = TT
	SetScale d 0,0,"dat", glb.gdate
	
	// Create exact time template wave
	for(inc=0; inc<num; inc += 1)
		minc += 1
		if (minc == 13)
			minc = 1
			yinc += 1
		endif
		day = ReturnMidDayOfMonth(glb.FirstYear + yinc, minc)
		if (mod(day, 1) != 0)
			hour = 12
			day -= 0.5
		else
			hour = 0
		endif			
		glb.gdate[inc] = date2secs(glb.FirstYear + yinc, minc, day) + 60*60*hour
		YYYY[inc] = glb.FirstYear + yinc
		MM[inc] = minc
	endfor
	
end

// new method can handle any number of instruments, not just two.
Function WeightedMean_ofasite(site, insts, glb)
	string site, insts	
	STRUCT GlobalMean_struct &glb
	
	Variable i, j, pt, Inv
	String instrument
	STRUCT SiteData_Struct s
	
	Make /FREE/n=(numpnts(glb.gdate)) WMm, WMsd, Weight
	
	for(i=0; i<ItemsInList(insts, ","); i+=1)
		instrument = StringFromList(i, insts, ",")
		s.site = site
		ReturnStationStruct(s, instrument)

		// make interpolated waves
		Interp_InstStation(glb, s)

		// no need to loop through all points if only one instrument (this is faster)
		if ((ItemsInList(insts, ",") == 1) & (WaveExists(s.MRI)))
			WMm = s.MRI/s.MRIsd
			WMsd = 1
			Weight = 1/s.MRIsd
		else
			// more than one instrument
			for(j=0; j<numpnts(s.MRI); j+=1)	// step through each month
				if (numtype(s.MRI[j]) == 0)
					Inv = 1/s.MRIsd[j]
					WMm[j] += Inv * s.MRI[j]
					WMsd[j] += 1					// same as  Inv * s.MRIsd[j]
					Weight[j] += Inv
				endif
			endfor
		endif

	endfor
	
	if (strlen(site) == 4)
		site = site[0,2]
	endif
	
	Variable colS = WhichListItem(site, AllSites)
	glb.Stations[][colS] = WMm[p]/Weight[p]
	glb.StationsSD[][colS] = WMsd[p]/Weight[p]
	
	// apply smoothing
	Station_smooth(site, glb)

	MatrixOp /FREE WMm = col(glb.Stations, colS)
	MatrixOp /FREE WMsd = col(glb.StationsSD, colS)
	
	// Add miss-match errors
	if (ItemsInList(insts, ",") >= 1)
		for(i=0; i<ItemsInList(insts, ","); i+=1)
			instrument = StringFromList(i, insts, ",")
			s.site = site
			ReturnStationStruct(s, instrument)
			RetrunInterpRefs(s, glb.prefix)
			
			if (WaveExists(s.MRI))
				WMsd += SelectNumber(abs(WMm-s.MRI) > (WMsd + s.MRIsd), 0, abs(WMm-s.MRI) - (WMsd + s.MRIsd))
			endif
		endfor
	endif

	// if data is nan then sd should be nan
	WMsd = SelectNumber(numtype(WMm)==0, Nan, WMsd)

	glb.StationsSD[][colS] = WMsd[p]
	
end

Function AppendRITStoGraph(mol)
	string mol
	
	SetDataFolder root:interp:
	
	String wvs = WaveList("RITS_*_"+mol+"_I", ";", "")
	String wvsD = WaveList("RITS_*_"+mol+"_date_I", ";", "")
	Variable i
	String xx, yy

	for(i=0; i<ItemsInList(wvs); i+=1)
		xx = StringFromList(i, wvsD)
		yy = StringFromList(i, wvs)
		AppendToGraph $yy vs $xx
	endfor
	
	SetDataFolder root:
end

Function AppendRITSNEWtoGraph(mol)
	string mol
	
	SetDataFolder root:interp:
	
	String wvs = WaveList("RITS_*_"+mol+"_new_I", ";", "")
	String wvsD = WaveList("RITS_*_"+mol+"_new_date_I", ";", "")
	Variable i
	String xx, yy

	for(i=0; i<ItemsInList(wvs); i+=1)
		xx = StringFromList(i, wvsD)
		yy = StringFromList(i, wvs)
		AppendToGraph $yy vs $xx
	endfor
	
	SetDataFolder root:
end

Function AppendOldGCtoGraph(mol)
	string mol
	
	SetDataFolder root:interp:
	
	String sites = "alt;brw;nwr;mlo;smo;cgo;spo;"
	Variable i
	String xx, yy

	for(i=0; i<ItemsInList(sites); i+=1)
		xx = mol + StringFromList(i, sites) + "_time_I"
		yy = mol + StringFromList(i, sites) + "_I"
		AppendToGraph $yy vs $xx
	endfor
	
	SetDataFolder root:
end

Function AppendOttotoGraph(mol)
	string mol
	
	SetDataFolder root:interp:
	
	String wvs = WaveList("otto_*_"+mol+"_I", ";", "")
	String wvsD = WaveList("otto_*_"+mol+"_date_I", ";", "")
	Variable i
	String xx, yy

	for(i=0; i<ItemsInList(wvs); i+=1)
		xx = StringFromList(i, wvsD)
		yy = StringFromList(i, wvs)
		AppendToGraph $yy vs $xx
	endfor
	
	SetDataFolder root:
end


Function QuickInstPlot(inst, mol)
	string inst, mol

	String xx, yy, wvs, wvsD
	Variable i
		
	//Display /K=1
	StrSwitch(inst)
		case "oldGC":
			SetDataFolder root:oldgc:
			String sites = "alt;brw;nwr;mlo;smo;cgo;spo;"
			for(i=0; i<ItemsInList(sites); i+=1)
				xx = mol + StringFromList(i, sites) + "_time"
				yy = mol + StringFromList(i, sites)
				AppendToGraph $yy vs $xx
			endfor
			break
		case "otto":
			SetDataFolder root:otto:
			wvs = WaveList("otto_*_"+mol, ";", "")
			wvsD = WaveList("otto_*_"+mol+"_date", ";", "")
			for(i=0; i<ItemsInList(wvs); i+=1)
				xx = StringFromList(i, wvsD)
				yy = StringFromList(i, wvs)
				AppendToGraph $yy vs $xx
			endfor
			break
		case "ritsnew":
			SetDataFolder root:rits:
			wvs = WaveList("rits_*_"+mol+"_new", ";", "")
			wvsD = WaveList("rits_*_"+mol+"_new_date", ";", "")
			for(i=0; i<ItemsInList(wvs); i+=1)
				xx = StringFromList(i, wvsD)
				yy = StringFromList(i, wvs)
				AppendToGraph $yy vs $xx
			endfor
			break
		case "cats":
			SetDataFolder root:month:
			sites = "brw;sum;nwr;mlo;smo;spo;"
			for(i=0; i<ItemsInList(sites); i+=1)
				xx =  StringFromList(i, sites) + "_time"
				yy = StringFromList(i, sites) + "_" + mol
				AppendToGraph $yy vs $xx
			endfor
			break
		case "MSD":
			SetDataFolder root:MSD:
			sites = Allsites
			for(i=0; i<ItemsInList(sites); i+=1)
				xx =  "MSD_" + StringFromList(i, sites) + "_" + mol + "_date"
				yy = "MSD_" + StringFromList(i, sites) + "_" + mol
				if (WaveExists($yy))
					AppendToGraph $yy vs $xx
				endif
			endfor
			break
		
	EndSwitch
	
	ModifyGraph mode=4,marker=19,msize=2
	//SetAxis left 200,550;DelayUpdate
	SetAxis bottom 2.3037696e+09,3.3451488e+09
	ModifyGraph msize=1

	SetDataFolder root:
end

Function StationView([site, mol])
	string site, mol
	
	SVAR mlist = root:G_molLst
	SVAR Gmol = root:G_mol
	SVAR Gsite = root:G_site
	Prompt site, "Site", popup, AllSites
	Prompt mol, "Molecule", popup, mlist + kMSDmols
	
	if ( ParamIsDefault(mol) || ParamIsDefault(site))
		mol = Gmol
		site = Gsite
		DoPrompt "Station View", site, mol
		if (V_flag)
			return -1
		endif
	endif
	
	Gsite = site
	Gmol = mol
	
	String fldrSav0= GetDataFolder(1)
	
	String intP = "root:interp:"
	String glbP = "root:global:"
	String Pre = "HATS_"
	String sta = Pre + "Sites_" + mol, staSD = sta + "_sd", staT = "HATS_" + mol + "_date"
	Variable col = WhichListItem(site, AllSites)
	Variable offset

	String oldP = "root:oldGC:"
	String old = mol + site, oldI = Pre + old + "_I", oldT = old + "_time", oldTI = Pre + mol + site + "_time_I", oldSD = old + "sd"
	String ottoP = "root:otto:"
	String otto = "otto_" + site + "_" + mol, ottoI = Pre + otto + "_I", ottoT = otto + "_date", ottoTI = Pre + ottoT + "_I", ottoSD = otto + "_sd"
	String ritsP = "root:RITS:"
	String rits = "RITS_" + site + "_" + mol + "_new", ritsI = Pre + rits + "_I", ritsT = rits + "_date", ritsTI = Pre + ritsT + "_I", ritsSD = rits + "_sd"
	String catsP = "root:month:"
	String cats = site + "_" + mol, catsI = "HATS_ca_" + site +"_" + mol + "_I", catsT = site + "_time", catsTI = "HATS_ca_" +site + "_time_I", catsSD = cats + "_sd"
	String ccggP = "root:CCGG:"
	String ccgg = "CCGG_" + site + "_" + mol + "_mn", ccggI = Pre + ccgg + "_I", ccggT = "CCGG_" + site + "_" + mol + "_date", ccggTI = Pre + ccggT + "_I", ccggSD = "CCGG_" + site + "_" + mol + "_sd"
	String msdP = "root:MSD:"
	String msd = "msd_" + site + "_" + mol , msdI = Pre + msd + "_I", msdT = msd + "_date", msdTI = Pre + msdT + "_I", msdSD = msd + "_sd"
	String pr1P = "root:PR1:"
	String pr1 = "PR1_" + site + "_" + mol , pr1I = Pre + pr1 + "_I", pr1T = pr1 + "_date", pr1TI = Pre + pr1T + "_I", pr1SD = pr1 + "_sd"
		
	String win = "Comb_Site_Figure_" + site + "_" + mol
	String leg 	
	Sprintf leg, "\\s(%s) Combined %s", sta, site
	
	DoWindow /K $win
	Display /K=1/W=(87,141,882,656) 
	DoWindow /C $win

	SetDataFolder $intP
	if (WaveExists($oldI))
		AppendToGraph $oldI vs $oldTI
		SetDataFolder $oldP
		AppendToGraph $old vs $oldT
		ModifyGraph mode($old)=3, marker($old)=19, msize($old)=4, rgb($old)=(0,0,0), rgb($oldI)=(0,0,0), msize($oldI)=1, hideTrace($oldI)=1
		ErrorBars $old Y,wave=($oldP+oldSD,$oldP+oldSD)
		leg += "\r\\s("+old+") old GC\r\\s("+oldI+") "
		offset = (100 + ReturnOffset("OldGC", mol))/100
		if (offset != 1)
			ModifyGraph muloffset($old)={0, offset}
			leg = ReplaceString(") old GC", leg, ") old GC offset:"+num2str(offset))
		endif
	endif
	SetDataFolder $intP
	if (WaveExists($ottoI))
		AppendToGraph $ottoI vs $ottoTI
		SetDataFolder $ottoP
		AppendToGraph $otto vs $ottoT
		ModifyGraph mode($otto)=3, marker($otto)=19, msize($otto)=4, rgb($otto)=(65535,0,0),  rgb($ottoI)=(65535,0,0), msize($ottoI)=1, hideTrace($ottoI)=1
		ErrorBars $otto Y,wave=($ottoP+ottoSD,$ottoP+ottoSD)
		leg += "\r\\s("+otto+") OTTO\r\\s("+ottoI+") "
		offset = (100 + ReturnOffset("otto", mol))/100
		if (offset != 1)
			ModifyGraph muloffset($otto)={0, offset}
			leg = ReplaceString(") OTTO", leg, ") OTTO offset:"+num2str(offset))
		endif
	endif
	SetDataFolder $intP
	if (WaveExists($ritsI))
		AppendToGraph $ritsI vs $ritsTI
		SetDataFolder $ritsP
		AppendToGraph $rits vs $ritsT
		ModifyGraph mode($rits)=3, marker($rits)=61, msize($rits)=4, rgb($rits)=(1,12815,52428), rgb($ritsI)=(1,12815,52428), msize($ritsI)=1, hideTrace($ritsI)=1
		ErrorBars $rits Y,wave=($ritsP+ritsSD,$ritsP+ritsSD)
		leg += "\r\\s("+rits+") RITS\r\\s("+ritsI+") "
		offset = (100 + ReturnOffset("RITS", mol))/100
		if (offset != 1)
			ModifyGraph muloffset($rits)={0, offset}
			leg = ReplaceString(") RITS", leg, ") RITS offset:"+num2str(offset))
		endif
	endif
	SetDataFolder $intP
	if (WaveExists($catsI))
		AppendToGraph $catsI vs $catsTI
		SetDataFolder $catsP
		AppendToGraph $cats vs $catsT
		ModifyGraph mode($cats)=3, marker($cats)=18, msize($cats)=4, rgb($cats)=(21845,21845,21845), rgb($catsI)=(21845,21845,21845), msize($catsI)=1, hideTrace($catsI)=1
		ErrorBars $cats Y,wave=($catsP+catsSD,$catsP+catsSD)
		leg += "\r\\s("+cats+") CATS\r\\s("+catsI+") "
		offset = (100 + ReturnOffset("CATS", mol))/100
		if (offset != 1)
			ModifyGraph muloffset($cats)={0, offset}
			leg = ReplaceString(") CATS", leg, ") CATS offset:"+num2str(offset))
		endif
	endif
	SetDataFolder $intP
	if (WaveExists($ccggI))
		AppendToGraph $ccggI vs $ccggTI
		SetDataFolder $ccggP
		AppendToGraph $ccgg vs $ccggT
		ModifyGraph mode($ccgg)=3, marker($ccgg)=17, msize($ccgg)=4, rgb($ccgg)=(36873,14755,58982), rgb($ccggI)=(36873,14755,58982), msize($ccggI)=1, hideTrace($ccggI)=1
		ErrorBars $ccgg Y,wave=($ccggP+ccggSD,$ccggP+ccggSD)
		leg += "\r\\s("+ccgg+") CCGG\r\\s("+ccggI+") "
		offset = (100 + ReturnOffset("CCGG", mol))/100
		if (offset != 1)
			ModifyGraph muloffset($ccgg)={0, offset}
			leg = ReplaceString(") CCGG", leg, ") CCGG offset:"+num2str(offset))
		endif
	endif
	SetDataFolder $intP
	if (WaveExists($msdI))
		AppendToGraph $msdI vs $msdTI
		SetDataFolder $msdP
		AppendToGraph $msd vs $msdT
		ModifyGraph mode($msd)=3, marker($msd)=2, msize($msd)=4, rgb($msd)=(52428,1,41942), rgb($msdI)=(52428,1,41942), msize($msdI)=1, hideTrace($msdI)=1
		ErrorBars $msd Y,wave=($msdP+msdSD,$msdP+msdSD)
		leg += "\r\\s("+msd+") M3\r\\s("+msdI+") "
		offset = (100 + ReturnOffset("msd", mol))/100
		if (offset != 1)
			ModifyGraph muloffset($msd)={0, offset}
			leg = ReplaceString(") msd", leg, ") msd offset:"+num2str(offset))
		endif
	endif
	SetDataFolder $intP
	if (WaveExists($pr1I))
		AppendToGraph $pr1I vs $pr1TI
		SetDataFolder $pr1P
		AppendToGraph $pr1 vs $pr1T
		ModifyGraph mode($pr1)=3, marker($pr1)=52, msize($pr1)=4, rgb($pr1)=(0,0,65535), rgb($pr1I)=(0,0,65535), msize($pr1I)=1, hideTrace($pr1I)=1
		ErrorBars $pr1 Y,wave=($pr1P+pr1SD,$pr1P+pr1SD)
		leg += "\r\\s("+pr1+") PR1\r\\s("+pr1I+") "
		offset = (100 + ReturnOffset("pr1", mol))/100
		if (offset != 1)
			ModifyGraph muloffset($pr1)={0, offset}
			leg = ReplaceString(") PR1", leg, ") PR1 offset:"+num2str(offset))
		endif
	endif
	
	
	SetDataFolder $glbP
	AppendToGraph $sta[][col] vs $staT
	ErrorBars $sta Y,wave=($glbP+staSD[*][col],$glbP+staSD[*][col])

	SetDataFolder fldrSav0
	
	ModifyGraph gFont="Rockwell",gfSize=18
	ModifyGraph lSize($sta)=3, rgb($sta)=(3,52428,1)
	ModifyGraph mirror=2
//	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,1,1,2,"Year",-1}

	Label left "\\f01" + site + " " + FullMolName(mol)
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	Legend/C/N=text0/J/A=LB/X=0.61/Y=1.17 leg
End

// calculate monthly meansFunction MonthlyMeans(ywv, xwv, suf)
	wave ywv, xwv
	string suf
	
	Variable yyyy = 1998, mm = 1, i, yinc, ptL, ptR
	String MMys = Nameofwave(ywv) + suf
	String MMysds = Nameofwave(ywv) + "_sd" + suf
	String MMxs = Nameofwave(xwv) + suf
	
	Make /d/o/n=((ReturnCurrentYear()-yyyy+1)*12) $MMxs/Wave=MMx, $MMys/Wave=MMy=NaN, $MMysds/Wave=MMysd=NaN
	SetScale d 0,0,"dat", MMx
	
	ptL = BinarySearchInterp(xwv, Date2Secs(yyyy, mm, 1))
	if ( numtype(ptL) == 2 )
		ptL = 0
	endif
	
	for(i=0;i<((ReturnCurrentYear()+1)-yyyy)*12;i+=1)
		MMx[i] = Date2Secs(yyyy+yinc, mm, 15)
		mm +=1 
		if ( mm == 13 )
			yinc += 1
			mm = 1
		endif
		ptR = BinarySearchInterp(xwv, Date2Secs(yyyy + yinc, mm, 1))
		if ( numtype(ptR) == 2 )
			ptR = ptL
		endif

		WaveStats/Q/R=[ptL, ptR] ywv
		if (( ptL != ptR ) && ( V_npnts > 10 )) 
			MMy[i] = V_avg
			MMysd[i] = V_sdev
		endif
		ptL = ptR
	endfor
	
end

// calculates monthly medians
Function MonthlyMedians(ywv, xwv, suf)
	wave ywv, xwv
	string suf
	
	Variable yyyy = 1998, mm = 1, i, yinc, ptL, ptR
	String MMys = Nameofwave(ywv) + suf
	String MMysds = Nameofwave(ywv) + "_sd" + suf
	String MMxs = Nameofwave(xwv) + suf
	
	Make /d/o/n=((ReturnCurrentYear()-yyyy+1)*12) $MMxs/Wave=MMx, $MMys/Wave=MMy=NaN, $MMysds/Wave=MMysd=NaN
	SetScale d 0,0,"dat", MMx
	
	ptL = BinarySearchInterp(xwv, Date2Secs(yyyy, mm, 1))
	if ( numtype(ptL) == 2 )
		ptL = 0
	endif
	
	for(i=0;i<((ReturnCurrentYear()+1)-yyyy)*12;i+=1)
		MMx[i] = Date2Secs(yyyy+yinc, mm, 15)
		mm +=1 
		if ( mm == 13 )
			yinc += 1
			mm = 1
		endif
		ptR = BinarySearchInterp(xwv, Date2Secs(yyyy + yinc, mm, 1))
		if ( numtype(ptR) == 2 )
			ptR = ptL
		endif

		WaveStats/Q/R=[ptL, ptR] ywv
		if (( ptL != ptR ) && ( V_npnts > 10 )) 
			MMy[i] = MedianEO(ywv, pnt2x(xwv, ptL), pnt2x(xwv, ptR))
			MMysd[i] = V_sdev
		endif
		ptL = ptR
	endfor
	
end


// makes contour plot from latbin matrix
Function ContourLatbin(prefix, mol)
	string prefix, mol
	
	String p = "root:global:"
	SetDataFolder $p

	String Ystr = prefix + "_LatBan_" + mol + "_lat"
	Wave mtx = $prefix + "_LatBan_" + mol
	Wave XX = $prefix + "_" + mol + "_date"
	Wave latbin
	Variable i, j
	String win = prefix + "_" + mol + "_contour"
	
	Make /o/n=(DimSize(mtx, 1)) $Ystr/WAVE=YY
	YY = latbin[p][0]

	// interp missing data in bins
	for (i=1; i<DimSize(mtx,1)-1; i+=1)	
		for (j=1; j<DimSize(mtx,0); j+=1)
			if (numtype(mtx[j][i]) == 2)
				mtx[j][i] = (mtx[j][i-1] +  mtx[j][i+1]) /2
			endif
		endfor
	endfor
	
	// find where data starts and ends
	i = 0
	do
		MatrixOp /o row = row(mtx, i)
		Wavestats /Q/M=1 row
		if (V_npnts > 5)
			K10 = i
			break
		endif
		i += 1
	while (i < DimSize(mtx,0))

	i = DimSize(mtx,0)-1
	do
		MatrixOp /o row = row(mtx, i)
		Wavestats /Q/M=1 row
		if (V_npnts > 5)
			K11 = i
			break
		endif
		i -= 1
	while (i > 0)
	
	// select resonable number of bins
	WaveStats /Q mtx
	Variable bins = (ceil(V_max) - floor(V_min))
	if (bins > 50)
		do
			bins/=2
		while(bins > 50)
	elseif (bins < 10)
		bins *= 3
	endif

	YY[0] = 90
	Dowindow /K $win
	Display /W=(408,64,1052,483)/K=1 
	AppendMatrixContour mtx vs {xx,yy}
	DoWindow /C $win
	ModifyGraph manTick(left)={-90,30,0,0},manMinor(left)={0,50}
	Label left "\\Z16\\f01Latitude"
	Label bottom "\\Z16\\f01Time"
	SetAxis left -90,90
	SetAxis bottom XX[K10],XX[K11]
	ModifyGraph margin(top)=30
	ModifyGraph width=600,height=300
	TextBox/C/N=text0/F=0/B=1/X=-0.54/Y=-8.95 "\\Z16"+ FullMolName(mol, units=0) +" global history " + ReturnMolUnits(mol)
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,1,1,2,"Year",-1}
	
	ModifyContour $(prefix + "_LatBan_" + mol) autoLevels={*,*,bins}
	
	if (cmpstr(mol, "F12") == 0)
		ModifyContour HATS_LatBan_F12 moreLevels=0,moreLevels={535,545}
	endif
	
	WMAppendFillBetweenContours_NP()
	string img = prefix + "_LatBan_" + mol + "Img"
	
	if (cmpstr(mol,"F11",0)==0)
		ModifyImage $img ctab= {*,270,Terrain256,0}
	else
		ModifyImage $img ctab= {*,*,Terrain256,0}
	endif
	ModifyContour $(prefix + "_LatBan_" + mol) rgbLines=(30583,30583,30583),labelBkg=1
	
	ModifyGraph manTick(bottom)={2871763200,5,0,0,yr},manMinor(bottom)={4,50}
	ModifyGraph margin(bottom)=65
	TextBox/C/N=NOAA/F=0/A=LB/X=-0.83/Y=-19.67 "\\F'Geneva'\\Z10NOAA/GML halocarbons program\r\\Z09" + date()[5,50]
	SetDrawLayer UserFront
	DrawPICT -0.0885603471626703,1.05884582970776,0.4,0.4,noaa_logo_png
	
	SetDataFolder root:
	
end


function ZonalMeanFigure([mol]) 
	string mol
	
	SVAR mlist = root:G_molLst

	if (ParamIsDefault(mol))
		Prompt mol, "Molecule", popup, mlist
		DoPrompt "Zonal Mean Figure", mol
		if (V_flag ==1)
			abort
		endif
	endif

	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:global:
	String txt, LatBanS = "HATS_LatBAN_" + mol
	Wave LatBan = $latbans
	Wave DD = $"HATS_" + mol + "_date"
	String win = "HATS_ZonalMeanFigure_" + mol
	DoWindow /K $win
	Display /K=1/W=(49,113,962,570) LatBan[*][0] vs DD
	Dowindow /C $win
	AppendToGraph LatBan[*][1] vs DD
	AppendToGraph LatBan[*][2] vs DD
	AppendToGraph LatBan[*][3] vs DD
	AppendToGraph LatBan[*][4] vs DD
	AppendToGraph LatBan[*][5] vs DD
	AppendToGraph LatBan[*][6] vs DD
	SetDataFolder fldrSav0
	ModifyGraph lSize=2
	
	ModifyGraph lStyle($LatBanS#4)=2,lStyle($LatBanS#5)=2,lStyle($LatBanS#6)=2
	ModifyGraph rgb($LatBanS#1)=(24576,24576,65535),rgb($LatBanS#2)=(3,52428,1)
	ModifyGraph rgb($LatBanS#3)=(4369,4369,4369),rgb($LatBanS#4)=(3,52428,1)
	ModifyGraph rgb($LatBanS#5)=(0,0,65535),rgb($LatBanS#6)=(52428,1,1)
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left mol
	Label bottom "Date"
	
	Sprintf txt, "\\s(%s)60-90 N \r\\s(%s#1)45-60 N\r\\s(%s#2)20-45 N\r\\s(%s#3) 0-20 N", LatBanS, LatBanS, LatBanS, LatBanS
	Legend/C/N=legd/J txt
	Sprintf txt, "\\s(%s#4) 0-20 S\r\\s(%s#5)20-60 S\r\\s(%s#6)60-90 S", LatBanS, LatBanS, LatBanS
	AppendText/N=legd txt

end

Window OffsetsTable() : Table
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:offsets:
	Edit/K=1/W=(5,44,717,450) ::save:mol_wave,oldGC,otto,CATS,RITS,CCGG,MSD as "Combine Data Offests"
	ModifyTable format(Point)=1,style(::save:mol_wave)=1
	SetDataFolder fldrSav0
EndMacro


// looks at the combined waves and makes num points waves that go into the locations.
function MakeNumMeasureWaves(progs, mol)
	string progs, mol

	string prog, site, sitenumST
	variable i, j, k, nope
	
	SetDataFolder "root:global:"
	
	wave MR = $"HATS_Sites_" + mol
	wave DD = $"HATS_" + mol + "_date"
	SetScale d 0,0, "dat", DD
	
	//edit DD
	for (i=0; i<ItemsInList(progs); i+=1)
		prog = StringFromList(i, progs)
		for(j=0; j<ItemsInList(AllSites); j+=1)
			site = StringFromList(j, AllSites)
			nope = 0
	
			// Create the correct wave reference for a giving measurement program
			if (cmpstr(prog, "oldGC") == 0)
				if (!WaveExists($"root:oldGC:" + mol + site + "_time") )
					nope = 1
				else
					wave d = $"root:oldGC:" + mol + site + "_time"
					wave n = $"root:oldGC:" + mol + site + "_n"
				endif
			elseif (strsearch(prog, "RITS", 0) > -1)
				if (!WaveExists($"root:RITS:RITS_" + site + "_" + mol + "_new_date"))
					nope = 1
				else
					wave d = $"root:RITS:RITS_" + site + "_" + mol + "_new_date"
					wave n = $"root:RITS:RITS_" + site + "_" + mol + "_new_num"
				endif
			elseif (cmpstr(prog, "otto") == 0)
				if (!WaveExists($"root:otto:otto_" + site + "_" + mol + "_date"))
					nope = 1
				else
					wave d = $"root:otto:otto_" + site + "_" + mol + "_date"
					wave n = $"root:otto:otto_" + site + "_" + mol + "_num"
				endif
			elseif (cmpstr(prog, "CATS") == 0)
				if (!WaveExists($"root:month:" + site + "_time"))
					nope = 1
				else
					wave d = $"root:month:" + site + "_time"
					wave n = $"root:month:" + site + "_" + mol + "_num"
				endif
			elseif (cmpstr(prog, "CCGG") == 0)
				if (!WaveExists($"root:CCGG:CCGG_" + site + "_" + mol +"_date"))
					nope = 1
				else
					wave d = $"root:CCGG:CCGG_" + site + "_" + mol +"_date"
					wave n = $"root:CCGG:CCGG_" + site + "_" + mol +"_num"
				endif
			endif

			// create site num wave
			sitenumST = "HATS_" + site + "_" + mol + "_num"
			if (WaveExists($sitenumST) == 0)
				make /n=(numpnts(DD)) $sitenumST=0
			elseif (numpnts($sitenumST) != numpnts(DD))
				make /n=(numpnts(DD)) $sitenumST=0
			endif
			Wave sitenum = $sitenumST
			if (i==0)
				sitenum = 0
				//appendtoTable $sitenumST
			endif

			if (!nope)
				// Fill in site num wave
				for (k=0; k<numpnts(d); k+=1)
					FindLevel /Q/P DD, d[k]
					if ((V_flag == 0) && (numtype(n[k]) == 0))
						sitenum[V_LevelX] += n[k]
					endif
				endfor
			endif

		endfor		
	endfor
	
	SetDataFolder root:
	
end

// function works on top graph
function ColorWavesBasedonLat()

	string site
	string trace, traces = TraceNameList("",";",1)
	Variable i, j, lat, idx
	
//	ColorTab2Wave RainBow
//	ColorTab2Wave Spectrum
	ColorTab2Wave EOSSpectral11
	wave colors = M_colors
	variable N = DimSize(colors, 0)
	
	for(i=0; i<ItemsInList(traces); i+=1)
		trace = StringFromList(i, traces)
		for(j=0; j<ItemsInList(AllSites); j+=1)
			site = StringFromList(j, AllSites)
			if (strsearch(trace, site, 0, 2) > -1)
				lat  = NumberByKey(site, latKey)
				idx = (90-lat) * N/180
				ModifyGraph rgb($trace) = (colors[idx][0], colors[idx][1], colors[idx][2])
			endif
		endfor
	
	endfor
End

// updates all MSD global means except the combo molecules.
Function MSDglobalMeans([saveit, plt])
	variable saveit, plt
	if (ParamIsDefault(saveit))
		saveit=1
	endif
	if (ParamIsDefault(plt))
		plt=1
	endif

	string mol, mols = kMSDmols + ";" + kPERSEUSmols
	mols = RemoveFromList("F11", mols)
	mols = RemoveFromList("F113", mols)
	mols = RemoveFromList("F12", mols)
	mols = RemoveFromList("CCl4", mols)
	mols = RemoveFromList("MC", mols)
	mols = RemoveFromList("CH3CCl3", mols)

	variable i
	for(i=0; i<ItemsInList(mols); i+=1)
		mol = StringFromList(i, mols)
		print "MSD global means: ", mol
		Global_Mean(insts="MSD", prefix="HATS", mol=mol, plot=plt, offsets=1)

		if (saveit == 1)
			SaveGlobalData(mol=mol, insts="MSD", prefix="HATS", incsites=2)
		endif
	endfor
	
end

Function CalcAll_HATSglobalMeans([plt])
	variable plt
	if (ParamIsDefault(plt))
		plt=1
	endif
	
	HATSglobalMeans(mol="N2O",plt=plt)
	HATSglobalMeans(mol="SF6",plt=plt)
	HATSglobalMeans(mol="F11",plt=plt)
	HATSglobalMeans(mol="F12",plt=plt)
	HATSglobalMeans(mol="F113",plt=plt)
	HATSglobalMeans(mol="CCl4",plt=plt)
	HATSglobalMeans(mol="MC",plt=plt)
end

Function HATSglobalMeans([mol,plt])
	string mol
	variable plt
	
	if (ParamIsDefault(plt))
		plt=1
	endif
	
	if (ParamIsDefault(mol))
		Prompt mol, "Which gas?", popup, "N2O;SF6;F11;F12;F113;MC;CCl4"
		DoPrompt "Global Mean", mol
		if (V_flag)
			return -1
		endif
	endif
	calcHATScombinedDATA(mol=mol,plt=plt)
end

Function calcHATScombinedData([mol,plt])
	string mol
	variable plt
	
	if (ParamIsDefault(plt))
		plt=1
	endif
	
	if (ParamIsDefault(mol))
		Global_Mean(insts="CATS+RITS+OTTO+OldGC+MSD", prefix="HATS", mol="F11", plot=plt)
		Global_Mean(insts="CATS+RITS+OTTO+OldGC+MSD", prefix="HATS", mol="F12", plot=plt)
		Global_Mean(insts="CATS+OTTO+MSD", prefix="HATS", mol="F113", plot=plt, offsets=2)
	
		Global_Mean(insts="CATS+OTTO+CCGG", prefix="HATS", mol="SF6", plot=plt)
		//Global_Mean(insts="CATS+OTTO", prefix="HATS", mol="SF6", plot=plt)
		Global_Mean(insts="CATS+RITS+OldGC+OTTO+CCGG", prefix="HATS", mol="N2O", plot=plt)
		//Global_Mean(insts="CATS+RITS+OldGC+OTTO", prefix="HATS", mol="N2O", plot=plt)
	
		Global_Mean(insts="CATS+RITS+OTTO", prefix="HATS", mol="CCl4", plot=plt)
		Global_Mean(insts="RITS+MSD", prefix="HATS", mol="MC", plot=plt)
		Global_Mean(insts="MSD", prefix="HATS", mol="H1211", plot=plt)
	else
		strswitch(mol)
			case "F11":
				Global_Mean(insts="CATS+RITS+OTTO+OldGC+MSD", prefix="HATS", mol="F11", plot=plt)
				break
			case "F12":
				Global_Mean(insts="CATS+RITS+OTTO+OldGC+MSD", prefix="HATS", mol="F12", plot=plt)
				break
			case "F113":
				Global_Mean(insts="CATS+OTTO+MSD", prefix="HATS", mol="F113", plot=plt, offsets=2)
				break
			case "SF6":
				//Global_Mean(insts="CATS+OTTO", prefix="HATS", mol="SF6", plot=plt)
				Global_Mean(insts="CATS+OTTO+CCGG", prefix="HATS", mol="SF6", plot=plt)
				break
			case "N2O":
				Global_Mean(insts="CATS+RITS+OldGC+OTTO+CCGG", prefix="HATS", mol="N2O", plot=plt)
				break
			case "CCl4":
				Global_Mean(insts="CATS+RITS+OTTO", prefix="HATS", mol="CCl4", plot=plt)
				break
			case "MC":
				Global_Mean(insts="RITS+MSD", prefix="HATS", mol="MC", plot=plt)
				break
			case "H1211":
				Global_Mean(insts="MSD", prefix="HATS", mol="H1211", plot=plt)
				break
			default:
				Print "Combined dataset is not defined for " + mol
		endswitch
	endif

end
