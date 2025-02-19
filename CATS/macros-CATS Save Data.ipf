#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=1		// Use modern global access method.
//#include <String Substitution>
#include "macros-CATS loading"


Proc SaveAllDataFromSite(site)
	string site=StrMakeOrDefault("root:G_site", "brw")
	prompt site, "Which site?", popup root:G_siteLst

	silent 1; pauseupdate
	G_site = site
	
	// First monthly means
	Load_Data(site=site, dur=4)
	SaveAllDataFromSiteType(site,4)
	
	// Daily means
	Load_Data(site=site, dur=2)
	SaveAllDataFromSiteType(site,2)
	
	// hourly data
	Load_Data(site=site, dur=1)
	SaveAllDataFromSiteType(site,1)

end

Proc SaveAllDataFromSiteType(site, type)
	string site=StrMakeOrDefault("root:G_site", "brw")
	variable type = NumMakeOrDefault("root:G_dur", 1)
	prompt site, "Which site?", popup, root:G_siteLst
	prompt type, "Duration of data", popup, "Every Point;Daily Median;Weekly Median;Monthly Median"
	
	silent 1
	root:G_site = site
	root:G_dur = type
	variable inc
	
	if (cmpstr(site,"brw")==0)
		SaveDataFile("brw","F11",type)
		SaveDataFile("brw","F12",type)
		SaveDataFile("brw","F113",type)
		SaveDataFile("brw","N2O",type)
		SaveDataFile("brw","MC",type)
		SaveDataFile("brw","CCl4",type)
		SaveDataFile("brw","SF6",type)
		SaveDataFile("brw","H1211",type)
		//SaveDataFile("brw","HCFC22",type)
		//SaveDataFile("brw","HCFC142b",type)
		//SaveDataFile("brw","OCS",type)
	endif

	if (cmpstr(site,"sum")==0)
		SaveDataFile("sum","F11",type)
		SaveDataFile("sum","F113",type)
		SaveDataFile("sum","F12",type)
		SaveDataFile("sum","N2O",type)
		SaveDataFile("sum","MC",type)
		SaveDataFile("sum","CCl4",type)
		SaveDataFile("sum","SF6",type)
		SaveDataFile("sum","H1211",type)
		SaveDataFile("sum","CO",type)
		SaveDataFile("sum","CH4",type)
	endif

	if (cmpstr(site,"nwr")==0)
		SaveDataFile("nwr","F11",type)
		SaveDataFile("nwr","F113",type)
		SaveDataFile("nwr","F12",type)
		SaveDataFile("nwr","N2O",type)
		SaveDataFile("nwr","MC",type)
		SaveDataFile("nwr","CCl4",type)
		SaveDataFile("nwr","SF6",type)
		SaveDataFile("nwr","H1211",type)
		//SaveDataFile("nwr","HCFC22",type)
		//SaveDataFile("nwr","HCFC142b",type)
		//SaveDataFile("nwr","OCS",type)
	endif
	
	if (cmpstr(site,"mlo")==0)
 		SaveDataFile("mlo","F11",type)
		SaveDataFile("mlo","F113",type)
		SaveDataFile("mlo","F12",type)
		SaveDataFile("mlo","N2O",type)
		SaveDataFile("mlo","MC",type)
		SaveDataFile("mlo","CCl4",type)
		SaveDataFile("mlo","SF6",type)
		SaveDataFile("mlo","H1211",type)
		//SaveDataFile("mlo","HCFC22",type)
		//SaveDataFile("mlo","HCFC142b",type)
		//SaveDataFile("mlo","OCS",type)
	endif
	
	if (cmpstr(site,"smo")==0)
		SaveDataFile("smo","F11",type)
		SaveDataFile("smo","F113",type)
		SaveDataFile("smo","F12",type)
		SaveDataFile("smo","N2O",type)
		SaveDataFile("smo","MC",type)
		SaveDataFile("smo","CCl4",type)
		SaveDataFile("smo","SF6",type)
		SaveDataFile("smo","H1211",type)
		//SaveDataFile("smo","HCFC22",type)
		//SaveDataFile("smo","HCFC142b",type)
		//SaveDataFile("smo","OCS",type)
	endif
	
	if (cmpstr(site,"spo")==0)
		SaveDataFile("spo","F11",type)
		SaveDataFile("spo","F12",type)
		SaveDataFile("spo","F113",type)
		SaveDataFile("spo","N2O",type)
		SaveDataFile("spo","MC",type)
		SaveDataFile("spo","CCl4",type)
		SaveDataFile("spo","SF6",type)
		SaveDataFile("spo","H1211",type)
		//SaveDataFile("spo","HCFC22",type)
		//SaveDataFile("spo","HCFC142b",type)
		//SaveDataFile("spo","OCS",type)
	endif
			
end

Proc SaveDataFile(site, mol, type)
	string site=StrMakeOrDefault("root:G_site4", "brw")
	string mol=StrMakeOrDefault("root:G_mol4", "N2O")
	variable type = NumMakeOrDefault("root:G_dur", 1)
	prompt site, "Which site?", popup, root:G_siteLst
	prompt mol, "Which molecule", popup, root:G_molLst 
	prompt type, "Duration of data", popup, "Every Point;Daily Median;Weekly Median;Monthly Median"
	
	silent 1

	SetDataFolder root:
	
	G_dur = type
	G_site4 = site
	G_mol4 = mol
	
	SaveDataFileFUNCT(site, mol, type)
	
end
	
function SaveDataFileFUNCT(site, mol, type)
	string site, mol
	variable type

	string DF = CATSdataFolder(1)
	SVAR Sdur = root:S_dur

	if (exists(site+"_"+mol) == 0 )
		return 0
	endif

	Print "Working on " + Sdur + " for " + site + " " + mol
	
	wave MR = $DF + site + "_" + mol
	wave day = $DF + site + "_time"
	wave dMR = $DF + site + "_" + mol + "_sd"
	wave /Z vMR = $DF + site + "_" + mol + "_var"
	wave /Z points = $DF + site + "_" + mol + "_num"
	wave /Z port = $DF + site + "_" + mol +"_port"
	variable YYY, MO, DD, HH, MN
	
	// Strings used for header info
	string submol = mol
	
	string longMolLst = "CCl4:Carbon tetrachloride;MC:Methyl chlorform;F11:Chlorofluorocarbon-11;F12:Chlorofluorocarbon-12;F113:Chlorofluorocarbon-113;"
	longMolLst += "H1211:Halon-1211;N2O:Nitrous Oxide;HCFC22:hydrochlorofluorocarbon-22;OCS:Carbonyl sulfide;SF6:Sulfur hexafluoride;"
	longMolLst += "HCFC142b:Hydrochloroflurocarbon-142b;"
	string longMol = StringByKey(submol, longMolLst)
		
	string units = "ppt"
	string unitsL = "trillion"
	if (cmpstr(submol,"N2O") == 0)
		units = "ppb"
		unitsL = "billion"
	endif

	variable inc = 0, handle
	string file, line, meth

	PathInfo/S SaveDataPath
	if (V_flag==0)
		NewPath /C/M="Where should I store the data?" SaveDataPath
	endif
	
	Close /a
	
	// _METH_ variable
	if (type == 4)
		file = site + "_" + submol + "_MM.dat"
		meth = "Monthly median"
	elseif (type == 3)
		file = site + "_" + submol + "_WM.dat"
		meth = "Weekly median"
	elseif (type == 2)
		file = site + "_" + submol + "_Day.dat"
		meth = "Daily median"
	elseif (type == 1)
		file = site + "_" + submol + "_All.dat"
		meth = "Hourly"
	else
		abort "Not coded yet!"
	endif
	
	// _CALSCALE_ etc, variables
	wave /t molwv = root:save:mol_wave
	wave /t scales = root:save:scales
	wave startyr = root:save:measure_start
	wave /t citewv = root:save:cite
	string calscale = "internal"
	string cite = "G.S. Dutton and B.D. Hall"
	string stryear = "1998"
	for( inc = 0; inc<numpnts(molwv); inc+=1 )
		if ( cmpstr(molwv[inc], mol) == 0) 
			calscale = scales[inc]
			break
		endif
	endfor
			
	// create header from head template
	concatheaders("CATS", site)
	wave /t header = $"root:save:head" + site
	duplicate /t/o/FREE header tmpheader
	for(inc=0; inc<numpnts(tmpheader); inc+=1)
		tmpheader[inc] = ReplaceString("_FILE_", tmpheader[inc], file)
		tmpheader[inc] = ReplaceString("_SHORTNM_", tmpheader[inc], submol)
		tmpheader[inc] = ReplaceString("_LONGNM_", tmpheader[inc], longMol)
		tmpheader[inc] = ReplaceString("_SHORTU_", tmpheader[inc], units)
		tmpheader[inc] = ReplaceString("_LONGU_", tmpheader[inc], unitsL)
		tmpheader[inc] = ReplaceString("_METH_", tmpheader[inc], meth)
		tmpheader[inc] = ReplaceString("_CITE_", tmpheader[inc], cite)
		tmpheader[inc] = ReplaceString("_CALSCALE_", tmpheader[inc], calscale)
		tmpheader[inc] = ReplaceString("_STARTYR_", tmpheader[inc], stryear)
		tmpheader[inc] = ReplaceString("_DATE_", tmpheader[inc], Secs2Date(DateTime,-2))
		tmpheader[inc] = ReplaceString("_YEAR_", tmpheader[inc], Secs2Date(DateTime,-2)[0,3])
		tmpheader[inc] = "#  " + tmpheader[inc]		// add comment delimeter 131024
	endfor
			
	if (type == 4)		// Monthly Means

		make /o/n=(numpnts(MR)) YYYY=NaN, MM=NaN
		YYYY = Str2Num(StringFromList(2, Secs2Date(day, 0), "/"))
		YYYY += YYYY >= 95 ? 1900 : 2000
		MM = Str2Num(StringFromList(0, Secs2Date(day, 0), "/"))

		Open /C="R*ch"/P=SaveDataPath handle file
	
		// write the header
		for ( inc=0; inc < numpnts(tmpheader); inc += 1 )
			fprintf handle, "%s\n", tmpheader[inc]
		endfor
		// Then write column info
		fprintf handle, "#  year, month, monthly median of %s in %s, uncertainty (unc), std. dev. (sd), number of samples\n#\n", submol, units
		fprintf handle, "%scats%syr %scats%smon %scats%sm %scats%sunc %scats%ssd %scats%sn\n", submol, upperstr(site), submol, upperstr(site), submol, upperstr(site), submol, upperstr(site), submol, upperstr(site), submol, upperstr(site)
		
		variable CurrentMonth =  str2num(StringFromList(1, Secs2date(DateTime,-1), "/")[0,3])
		for (inc = 0; inc < numpnts(MR); inc += 1 )
			// don't save MC data past 2013
			//if ((cmpstr(mol, "MC") == 0) && (YYYY[inc] >= 2014))
			//	break
			//endif
			if (( YYYY[inc] >= ReturnCurrentYear() ) && ( MM[inc] > CurrentMonth ))
				break
			endif
			if (numtype(MR[inc]) != 0)
				fprintf handle, "%4d %7d     nan        nan       nan       0\n", YYYY[inc], MM[inc]
			else
				if (cmpstr(mol, "SF6") == 0 )
					fprintf handle, "%4d %7d  %8.3f  %8.3f  %8.3f  %5d\n", YYYY[inc], MM[inc], MR[inc], dMR[inc], vMR[inc], points[inc]		/// added atmospheric veriablilty
				else
					fprintf handle, "%4d %7d  %8.2f  %8.2f  %8.2f  %5d\n", YYYY[inc], MM[inc], MR[inc], dMR[inc], vMR[inc], points[inc]
				endif
			endif
		endfor
			
		//killwaves YYYY, MM
		
	elseif (type == 3)		// Weekly Means
	
		make /o/n=(numpnts(MR)) YYYY=NaN, WW=NaN
		for (inc = 0; inc < numpnts(MR); inc += 1 )
			YYYY[inc] = Str2Num(StringFromList(2, Secs2Date(day[inc], 0), "/"))
			YYYY[inc] += YYYY[inc] >= 95 ? 1900 : 2000
			WW[inc] = floor(date2julian(YYYY[inc], Str2Num(StringFromList(0, Secs2Date(day[inc], 0), "/")),Str2Num(StringFromList(1, Secs2Date(day[inc], 0), "/"))) / 7.02404) + 1
		endfor

		Open /C="R*ch"/P=SaveDataPath handle file
		
		// write the header
		for ( inc=0; inc < numpnts(tmpheader); inc += 1 )
			fprintf handle, "%s\n", tmpheader[inc]
		endfor
		// Then write column info
		fprintf handle, "#  year, week, weekly mean of %s in %s, std. dev., number of samples\n#\n", submol, units
		fprintf handle, "%scats%syr %scats%sweek %scats%sm %scats%ssd %scats%sn\n", submol, upperstr(site), submol, upperstr(site), submol, upperstr(site), submol, upperstr(site), submol, upperstr(site)

		for (inc = 0; inc < numpnts(MR); inc += 1 )
			if (numtype(MR[inc]) != 0)
				fprintf handle, "%4d %7d     nan        nan       0\n", YYYY[inc], WW[inc]
			else
				if (cmpstr(mol, "SF6") == 0 )
					fprintf handle, "%4d %7d  %8.3f  %8.3f  %5d\n", YYYY[inc], MM[inc], MR[inc], dMR[inc], points[inc]
				else
					fprintf handle, "%4d %7d  %8.2f  %8.2f  %5d\n", YYYY[inc], MM[inc], MR[inc], dMR[inc], points[inc]
				endif
			endif
		endfor
			
		killwaves YYYY, WW

	elseif (type == 2)		// Daily Median
		Open /C="R*ch"/P=SaveDataPath handle file
		
		// write the header
		for ( inc=0; inc < numpnts(tmpheader); inc += 1 )
			fprintf handle, "%s\n", tmpheader[inc]
		endfor
		// Then write column info
		fprintf handle, "#  year, month, day, daily median %s in %s, std. dev.\n#\n", submol, units
		fprintf handle, "%scats%syr %scats%smon %scats%sday %scats%sm %scats%smsd %scats%sn\n", submol, upperstr(site), submol, upperstr(site), submol, upperstr(site), submol, upperstr(site), submol, upperstr(site), submol, upperstr(site)

		for (inc = 0; inc < numpnts(MR); inc += 1 )
			YYY = Str2Num(StringFromList(2, Secs2Date(day[inc], 0), "/"))
			YYY += YYY >= 95 ? 1900 : 2000
			MO = Str2Num(StringFromList(0, Secs2Date(day[inc], 0), "/"))
			DD = Str2Num(StringFromList(1, Secs2Date(day[inc], 0), "/"))

			// don't save MC data past 2013
			//if ((cmpstr(mol, "MC") == 0) && (YYY >= 2014))
			//	break
			//endif

			if (numtype(MR[inc]) == 0)
				if (cmpstr(mol, "SF6") == 0 )
					fprintf handle, "%4d %7d  %7d %8.3f %8.3f  %5d\n",YYY, MO, DD,  MR[inc], dMR[inc], points[inc]
				else
					fprintf handle, "%4d %7d  %7d %8.2f %8.2f  %5d\n",YYY, MO, DD,  MR[inc], dMR[inc], points[inc]
				endif
			else
				fprintf handle, "%4d %7d  %7d      nan      nan      0\n", YYY, MO, DD
			endif
		endfor
					
	elseif (type == 1)		// Every Point

		string datesecsSTR, timesecsSTR
		
		Open /C="R*ch"/P=SaveDataPath handle file
		
		// write the header
		for (inc=0; inc < numpnts(tmpheader); inc+= 1 )
			fprintf handle, "%s\n", tmpheader[inc]
		endfor
		// Then write column info
		fprintf handle, "#  year, month, day, hour, minute, %s in %s, std. dev.\n#\n", submol, units
		fprintf handle, "%scats%syr %scats%smon %scats%sday %scats%shour %scats%smin %scats%sm %scats%smsd\n", submol, upperstr(site), submol, upperstr(site), submol, upperstr(site), submol, upperstr(site), submol, upperstr(site), submol, upperstr(site), submol, upperstr(site)

		for (inc = 0; inc < numpnts(MR); inc += 1 )
			if ((port[inc] == 4) || (port[inc] == 8))
				datesecsSTR = Secs2Date(day[inc], 0)
				timesecsSTR = Secs2Time(day[inc], 2)
				YYY = Str2Num(StringFromList(2, datesecsSTR, "/"))
				YYY += YYY >= 95 ? 1900 : 2000
				MO = Str2Num(StringFromList(0, datesecsSTR, "/"))
				DD = Str2Num(StringFromList(1, datesecsSTR, "/"))
				HH = Str2Num(StringFromList(0, timesecsSTR, ":"))
				MN = Str2Num(StringFromList(1, timesecsSTR, ":"))

				// don't save MC data past 2013
				//if ((cmpstr(mol, "MC") == 0) && (YYY >= 2014))
				//	break
				//endif

				if (numtype(MR[inc]) != 0)
					fprintf handle, "%4d %7d  %7d %7d %7d     Nan       Nan\n", YYY, MO, DD, HH, MN
				else
					if (cmpstr(mol, "SF6") == 0 )
						fprintf handle, "%4d %7d  %7d %7d %7d %8.3f %8.3f\n", YYY, MO, DD, HH, MN, MR[inc], dMR[inc]
					else
						fprintf handle, "%4d %7d  %7d %7d %7d %8.3f %8.3f\n", YYY, MO, DD, HH, MN, MR[inc], dMR[inc]
					endif
				endif
				
			endif
		endfor
					
	endif

	Close handle	
	SetDataFolder root:

end

Function SaveAllGlobalData([insts, prefix])
	string insts, prefix
	
	SVAR GinstList = root:global:S_InstList
	SVAR Gpre = root:global:S_prefix
	insts = GinstList
	prefix = Gpre
	
	Prompt insts, "Which data set?", popup, AllInsts
	Prompt prefix, "Name waves with the following prefix:"
	
	if (  ParamIsDefault(insts) || ParamIsDefault(prefix))
		DoPrompt "Save all Global Mean Data:", insts, prefix
		if (V_flag)
			return -1
		endif
	endif
	
	GinstList = insts
	Gpre = prefix

	string mol, mollist = "N2O;SF6;F11;F12;F113;MC;CCl4;CHCl3;H1211;HCFC22;HCFC142b;CH3Cl;OCS;"
	variable inc = 0
	for(inc=0; inc< ItemsInList(mollist); inc+=1)
		mol = StringFromList(inc, mollist)
		SaveGlobalData(mol=mol, insts=insts, prefix="insitu", incsites=2)
	endfor

end

Function SaveAllCATSData()

	string mollist = "N2O;SF6;F11;F12;F113;MC;CCl4;CHCl3;H1211;" //HCFC22;HCFC142b;CH3Cl;" //OCS;"
	string mol
	variable inc

	for ( inc=0; inc < ItemsInList(mollist); inc+=1 )
		mol = StringFromList(inc, mollist)
		SaveDataFiles_mol(mol=mol)
	endfor

end	

// proceedure to save hourly, daily, monthly and global data files for a single molecule (CATS data only)
// mol is an optional parameter.  If mol is not defined the user will be prompted for mol.
function SaveDataFiles_mol([mol])
	string mol
	
	SetDataFolder root:
	
	SVAR G_molLst = G_molLst
	SVAR G_mol4 = G_mol4
	SVAR stationlst = root:G_siteLst
	NVAR type = root:G_dur
	variable inc = 0
	string station

	if (ParamIsDefault(mol))
		mol=StrMakeOrDefault("root:G_mol4", "N2O")
		prompt mol, "Which molecule", popup, G_molLst 
		Doprompt "SaveDataFiles Molecule", mol
		if (V_Flag)
			abort 		// User canceled
		endif
	endif
	G_mol4 = mol

	type = 1	// hourly
	for(inc=0; inc < ItemsInList(stationlst); inc += 1)
		station = StringFromList(inc, stationlst)
		SaveDataFileFUNCT(station, mol, type)
	endfor
	
	type = 2	// daily
	for(inc=0; inc < ItemsInList(stationlst); inc += 1)
		station = StringFromList(inc, stationlst)
		SaveDataFileFUNCT(station, mol, type)
	endfor

	type = 4	// monthly
	for(inc=0; inc < ItemsInList(stationlst); inc += 1)
		station = StringFromList(inc, stationlst)
		SaveDataFileFUNCT(station, mol, type)
	endfor
	
	// global data (CATS only)
	SaveGlobalData(mol=mol, insts="CATS", prefix="insitu", incsites=2)

end


Function EditHeaders()
	string head = "headGlobal"
	Prompt head, "Which header?", popup, "headGlobal;headGLOBALcomb;CATS_body;CATS_brw;CATS_sum;CATS_nwr;CATS_mlo;CATS_smo;CATS_spo;OldGC_body" 
	DoPrompt "Which header?", head
	if (V_flag)
		return -1
	endif

	SetDataFolder root:save:

	Edit/K=1/W=(30,47,773,800) $head
	ModifyTable alignment($head)=0,width($head)=658

	SetDataFolder root:

end

Function concatheaders(inst, site)
	string inst, site
	
	SetDataFolder root:save:
	String header = "head" + site
	wave /t HE = $inst + "_" + site
	wave /t BO = $inst + "_body"
	Duplicate /t/o HE, $header/Wave=head
	Redimension /n=(numpnts(HE) + numpnts(BO)) head
	head[numpnts(HE),numpnts(head)-1] = BO[p-numpnts(HE)]
	SetDataFolder root:
	
End

Proc EditHeaderMetadata() 
	PauseUpdate; Silent 1		// building window...
	SetDataFolder root:save:
	Edit/K=1/W=(67,94,1214,608) mol_wave,scales,measure_start,cite,doi as "Header Meta Data"
	ModifyTable format(Point)=1,style(mol_wave)=1,alignment(cite)=0,width(cite)=506
	ModifyTable alignment(doi)=0,width(doi)=220
	SetDataFolder root:
EndMacro

Function SaveGlobalData([insts, prefix, mol, incsites])
	String insts, prefix, mol
	Variable incsites

	SVAR mollst = root:G_molLst
	SVAR Gmol = root:G_mol
	SVAR GinstList = root:global:S_InstList
	SVAR Gpre = root:global:S_prefix

	Prompt insts, "Select a set of instruments", popup, AllInsts
	Prompt mol, "Which gas?", popup, mollst
	Prompt prefix, "Name waves with the following prefix:"
	Prompt incsites, "Include all stations in data file?", popup, "yes;no"
	if ( ParamIsDefault(mol) || ParamIsDefault(insts) || ParamIsDefault(prefix))
		prefix = Gpre
		mol = Gmol
		insts = GinstList
		incsites = 2
		DoPrompt "Save Global Mean data:", insts, mol, prefix, incsites
		if (V_flag)
			return -1
		endif
		Gmol = mol
		GinstList = insts
		Gpre = prefix
	endif
	
	string savefile = prefix + "_global_" + mol + ".txt"
	if ((cmpstr(prefix, "HATS") == 0) || (cmpstr(prefix, "GML") == 0))		// combined datasets
		//savefile = prefix + "_combined_" + mol + ".txt"
		savefile = prefix + "_global_" + mol + ".txt"
		Global_Mean(insts=insts, prefix=prefix, mol=mol, offsets=2)
	else
		Global_Mean(insts=insts, prefix=prefix, mol=mol, offsets=1)
	endif

	Close /a
	
	string DF = "root:global"
	string mixSTR = DF + ":" + prefix + "_global_" + mol
	wave mix = $mixSTR
	wave dec = $DF + ":" + prefix + "_" + mol + "_date"
	wave YYYY = $DF + ":" + prefix + "_" + mol + "_YYYY"
	wave MM = $DF + ":" + prefix + "_" + mol + "_MM"
	wave SD = $mixSTR + "_SD"
	string NHmixSTR = DF + ":" + prefix + "_NH_" + mol
	wave NHmix = $NHmixSTR
	wave NHSD = $NHmixSTR + "_SD"
	string SHmixSTR = DF + ":" + prefix + "_SH_" + mol
	wave SHmix = $SHmixSTR
	wave SHSD = $SHmixSTR + "_SD"
	Wave sites = $DF + ":" + prefix + "_Sites_" + mol
	Wave sitesSD = $DF + ":" + prefix + "_Sites_" + mol + "_SD"
	
	variable handle, inc, j, col
	string line, s, BKsites

	string longMolLst = "CCl4:Carbon tetrachloride;MC:Methyl chlorform;F11:Chloroflurocarbon-11;F12:Chloroflurocarbon-12;F113:Chloroflurocarbon-113;"
	longMolLst += "H1211:Halon-1211;N2O:Nitrous Oxide;HCFC22:Hydrochloroflurocarbon-22;OCS:Carbonyl sulfide;SF6:Sulfur hexaflouride;"
	longMolLst += "HCFC142b:Hydrochloroflurocarbon-142b;"
	string longMol = StringByKey(mol, longMolLst)
		
	string units = "ppt"
	string unitsL = "trillion"
	if (cmpstr(mol,"N2O") == 0)
		units = "ppb"
		unitsL = "billion"
	endif
	string meth
	
	PathInfo/S SaveDataPath
	if (V_flag==0)
		NewPath /C/M="Where should I store the data?" SaveDataPath
	endif

	// _CALSCALE_, _STARTYR_, _CITE_ variables
	wave /t molwv = root:save:mol_wave
	wave /t scales = root:save:scales
	wave startyr = root:save:measure_start
	wave /t citewv = root:save:cite
	wave /t doiwv = root:save:doi
	string calscale = "internal"
	string doi, cite = "G.S. Dutton and B.D. Hall"
	variable stryear = 1992
	for( inc = 0; inc<numpnts(molwv); inc+=1 )
		if ( cmpstr(molwv[inc], mol) == 0) 
			calscale = scales[inc]
			stryear = startyr[inc]
			cite = citewv[inc]
			doi = doiwv[inc]
			break
		endif
	endfor

	Open /P=SaveDataPath handle as savefile

	// create header from head template
	if (cmpstr(insts, "CATS") == 0 )
		cite = "G.S. Dutton and B.D. Hall"
		Wave /T header = root:save:headGlobal
	else
		Wave /T header = root:save:headGlobalComb
	endif
	
	duplicate /t/FREE header tmpheader
	for (inc=0; inc < numpnts(tmpheader); inc+= 1)
		tmpheader[inc] = ReplaceString("_FILE_", tmpheader[inc], savefile)
		tmpheader[inc] = ReplaceString("_SHORTNM_", tmpheader[inc], mol)
		tmpheader[inc] = ReplaceString("_LONGNM_", tmpheader[inc], longMol)
		tmpheader[inc] = ReplaceString("_SHORTU_", tmpheader[inc], units)
		tmpheader[inc] = ReplaceString("_LONGU_", tmpheader[inc], unitsL)
		tmpheader[inc] = ReplaceString("_CITE_", tmpheader[inc], cite)
		tmpheader[inc] = ReplaceString("_CALSCALE_", tmpheader[inc], calscale)
		if (strlen(doi) > 1)
			tmpheader[inc] = ReplaceString("_DOI_", tmpheader[inc], ",\n#     "+doi)
		else
			tmpheader[inc] = ReplaceString("_DOI_", tmpheader[inc], " ")
		endif
		tmpheader[inc] = ReplaceString("_STARTYR_", tmpheader[inc], num2str(stryear))
		tmpheader[inc] = ReplaceString("_DATE_", tmpheader[inc], Secs2Date(DateTime,-2))
		tmpheader[inc] = ReplaceString("_YEAR_", tmpheader[inc], Secs2Date(DateTime,-2)[0,3])
		tmpheader[inc] = "#  " + tmpheader[inc]				// add comment delimeter 131024
	endfor

	// write the header
	for ( inc=0; inc < numpnts(tmpheader); inc+=1 )
		fprintf handle, "%s\n", tmpheader[inc]
	endfor

	if ( incsites == 1 )
		BKsites = AllBKsitesOTTO	// constants defined in "global means.ipf"
		// wave name header
		fprintf handle, "%s %s %s %s %s %s %s %s ", Nameofwave(YYYY), Nameofwave(MM), NameofWave(NHmix), Nameofwave(NHSD), NameofWave(SHmix), Nameofwave(SHsd), NameofWave(mix), Nameofwave(sd)
		for (inc=0; inc<ItemsInList(BKsites); inc+=1)
			s = StringFromList(inc, BKsites)
			fprintf handle, "%s %s_sd ", prefix + "_" + s + "_" +mol, prefix + "_" + s + "_" + mol
		endfor
		fprintf handle, "%s_%s_Programs\n", prefix, mol
		
		//data
		for ( inc=0; inc < numpnts(YYYY); inc+=1 )
			if ( (numtype(NHmix[inc]) == 0 ) || (numtype(SHmix[inc]) == 0 ))		// exclude nan months
				fprintf handle, "%4d  %2d  %8.3f  %8.3f  %8.3f  %8.3f  %8.3f  %8.3f ", YYYY[inc], MM[inc], NHmix[inc], NHsd[inc], SHmix[inc], SHsd[inc], mix[inc], sd[inc]
				for (j=0; j<ItemsInList(BKsites); j+=1)
					s = StringFromList(j, BKsites)
					col = WhichListItem(s, Allsites)
					fprintf handle, "%8.3f %8.3f ", Sites[inc][col], SitesSD[inc][col]
				endfor
				fprintf handle, "    %s\n", ReturnProgramsString(prefix, mol, dec[inc])
			endif
		endfor
	else
		if (cmpstr(insts, "CATS") == 0 )
			fprintf handle, "%s %s %s %s %s %s %s %s\n", Nameofwave(YYYY), Nameofwave(MM), NameofWave(NHmix), Nameofwave(NHSD), NameofWave(SHmix), Nameofwave(SHsd), NameofWave(mix), Nameofwave(sd)
			for ( inc=0; inc < numpnts(YYYY); inc+=1 )
	
				// don't save MC data past 2013
				//if ((cmpstr(mol, "MC") == 0) && (YYYY[inc] >= 2014))
				//	break
				//endif

				fprintf handle, "%4d  %2d  %8.3f  %8.3f  %8.3f  %8.3f  %8.3f  %8.3f \n", YYYY[inc], MM[inc], NHmix[inc], NHsd[inc], SHmix[inc], SHsd[inc], mix[inc], sd[inc]
			endfor
		else
			fprintf handle, "%s %s %s %s %s %s %s %s %s_%s_Programs\n", Nameofwave(YYYY), Nameofwave(MM), NameofWave(NHmix), Nameofwave(NHSD), NameofWave(SHmix), Nameofwave(SHsd), NameofWave(mix), Nameofwave(sd), prefix, mol
			for ( inc=0; inc < numpnts(YYYY); inc+=1 )
				fprintf handle, "%4d  %2d  %8.3f  %8.3f  %8.3f  %8.3f  %8.3f  %8.3f     %s\n", YYYY[inc], MM[inc], NHmix[inc], NHsd[inc], SHmix[inc], SHsd[inc], mix[inc], sd[inc], ReturnProgramsString(prefix, mol, dec[inc])
			endfor
		endif
	endif
			
	close handle
			
end

Function Save_Combo_Data([mol])
	string mol

	SVAR Gmol = root:G_mol
	NVAR plt = root:global:G_plot
	plt = 2
	variable YES = 1
	
   if (ParamIsDefault(mol))
		Prompt mol, "Which gas?", popup, "N2O;SF6;F11;F12;F113;CCl4;MC"
		DoPrompt "Save Combined Data:", mol
		if (V_Flag)
			return -1 		// User canceled
		endif
	endif
	Gmol = mol

	if (cmpstr(mol, "F11") == 0)
		SaveGlobalData(insts="CATS+RITS+OTTO+OldGC+MSD", prefix="HATS", mol="F11", incsites=YES)
	elseif (cmpstr(mol, "F12") == 0)
		SaveGlobalData(insts="CATS+RITS+OTTO+OldGC+MSD", prefix="HATS", mol="F12", incsites=YES)
	elseif (cmpstr(mol, "F113") == 0)
		SaveGlobalData(insts="CATS+OTTO+MSD", prefix="HATS", mol="F113", incsites=YES)
	elseif (cmpstr(mol, "SF6") == 0)
		SaveGlobalData(insts="CATS+OTTO+CCGG", prefix="GML", mol="SF6", incsites=YES)
	elseif (cmpstr(mol, "N2O") == 0)
		SaveGlobalData(insts="CATS+RITS+OldGC+OTTO+CCGG", prefix="GML", mol="N2O", incsites=YES)
	elseif (cmpstr(mol, "CCl4") == 0)
		SaveGlobalData(insts="CATS+RITS+OTTO", prefix="HATS", mol="CCl4", incsites=YES)
	elseif (cmpstr(mol, "MC") == 0)
		SaveGlobalData(insts="RITS+MSD", prefix="HATS", mol="MC", incsites=YES)
	endif
end


Function SaveHATScombinedData([isites])
	variable isites
	
	if (ParamIsDefault(isites))
		isites = 1		// 1 to include site columns
	else
		isites = 2
	endif

	// AllInsts is a strconst in the "Global Means" proceedures.
	// added M3 data 180713
	SaveGlobalData(insts="CATS+RITS+OTTO+OldGC+MSD", prefix="HATS", mol="F11", incsites=isites)
	SaveGlobalData(insts="CATS+RITS+OTTO+OldGC+MSD", prefix="HATS", mol="F12", incsites=isites)
	SaveGlobalData(insts="CATS+OTTO+MSD", prefix="HATS", mol="F113", incsites=isites)

	// using CCGG data for SF6 and N2O, prefix="GMD"  190226
	// updated prefix to "GML" 210209
	SaveGlobalData(insts="CATS+OTTO+CCGG", prefix="GML", mol="SF6", incsites=isites)
	SaveGlobalData(insts="CATS+RITS+OldGC+OTTO+CCGG", prefix="GML", mol="N2O", incsites=isites)

	SaveGlobalData(insts="CATS+RITS+OTTO", prefix="HATS", mol="CCl4", incsites=isites)
	//SaveGlobalData(insts="CATS+RITS+OTTO+MSD", prefix="HATS", mol="MC", incsites=isites)
	SaveGlobalData(insts="RITS+MSD", prefix="HATS", mol="MC", incsites=isites)

end
// for halon1211
//Global_Mean(insts="MSD", prefix="HATS", mol="h1211", plot=2)
//SaveGlobalData(insts="MSD", prefix="HATS", mol="h1211", incsites=1)

Function SaveAll_HATS_data()

	saveHATScombinedData(isites=2)
	string non_combo_mols = "HCFC22;HCFC141b;HCFC142b;HFC134A;HFC152A;HFC227ea;HFC365mfc;COS;CH3CCl3;CH2Cl2;C2Cl4;h1211;h2402;CH3Br;CH3Cl;h1301;HFC125;HFC143a;HFC32;C2H6;C3H8;CF4;HFC236fa;NF3;PFC116;SO2F2"
	string mol
	variable i
	
	// MSD gases
	for(i=0; i<ItemsInList(non_combo_mols); i+=1)
		mol = StringFromList(i, non_combo_mols)
		SaveGlobalData(insts="MSD", prefix="HATS", mol=mol, incsites=2)
	endfor

end

function SaveOldGCdata(site, mol)
	string site, mol

	string DF = "root:oldgc:"
	SetDataFolder $DF

	if (exists(mol+site) == 0 )
		SetDataFolder root:
		return 0
	endif

	Print "Working on OldGC: " + site + " " + mol
	
	wave MR = $DF + mol+site
	wave day = $DF + mol+site + "_time"
	wave dMR = $DF + mol+site +"sd"
	wave /Z points = $DF + mol+site + "_n"
	variable YYY, MO, DD, HH, MN
	
	// Strings used for header info
	string submol = mol
	
	string longMolLst = "CCl4:Carbon tetrachloride;MC:Methyl chlorform;F11:Chloroflurocarbon-11;F12:Chloroflurocarbon-12;F113:Chloroflurocarbon-113;"
	longMolLst += "H1211:Halon-1211;N2O:Nitrous Oxide;HCFC22:Hydrochloroflurocarbon-22;OCS:Carbonyl sulfide;SF6:Sulfur hexaflouride;"
	longMolLst += "HCFC142b:Hydrochloroflurocarbon-142b;"
	string longMol = StringByKey(submol, longMolLst)
		
	string units = "ppt"
	string unitsL = "trillion"
	if (cmpstr(submol,"N2O") == 0)
		units = "ppb"
		unitsL = "billion"
	endif

	variable inc = 0, handle
	string file, line, meth

	PathInfo/S SaveDataPath
	if (V_flag==0)
		NewPath /C/M="Where should I store the data?" SaveDataPath
	endif
	
	Close /a
	
	file = site + "_" + submol + "_MM.dat"
	meth = "Monthly mean"
	
	// _CALSCALE_ variable
	wave /t molwv = root:save:mol_wave
	wave /t scales = root:save:scales
	string calscale
	for( inc = 0; inc<numpnts(molwv); inc+=1 )
		if ( cmpstr(molwv[inc], submol) == 0) 
			calscale = scales[inc]
			break
		endif
	endfor
			
	// create header from head template
	concatheaders("OldGC", site)
	wave /t header = $"root:save:head" + site
	duplicate /t/o header tmpheader
	for(inc=0; inc<numpnts(tmpheader); inc+=1)
		tmpheader[inc] = ReplaceString("_FILE_", tmpheader[inc], file)
		tmpheader[inc] = ReplaceString("_SHORTNM_", tmpheader[inc], submol)
		tmpheader[inc] = ReplaceString("_LONGNM_", tmpheader[inc], longMol)
		tmpheader[inc] = ReplaceString("_SHORTU_", tmpheader[inc], units)
		tmpheader[inc] = ReplaceString("_LONGU_", tmpheader[inc], unitsL)
		tmpheader[inc] = ReplaceString("_METH_", tmpheader[inc], meth)
		tmpheader[inc] = ReplaceString("_CALSCALE_", tmpheader[inc], calscale)
		tmpheader[inc] = ReplaceString("_DATE_", tmpheader[inc], Secs2Date(DateTime,-2))
		tmpheader[inc] = ReplaceString("_YEAR_", tmpheader[inc], Secs2Date(DateTime,-2)[0,3])
		tmpheader[inc] = "#  " + tmpheader[inc]		// add comment delimeter 170207
	endfor
			
	make /o/n=(numpnts(MR)) YYYY=NaN, MM=NaN
	YYYY = returnYear(day)
	MM = returnMonth(day)

	Open /C="R*ch"/P=SaveDataPath handle file

	// write the header
	for ( inc=0; inc < numpnts(tmpheader); inc += 1 )
		fprintf handle, "%s\n", tmpheader[inc]
	endfor
	// Then write column info
	//fprintf handle, "year, month, monthly mean of %s in %s, std. dev., number of samples\n|\n", submol, units
	fprintf handle, "%soldGC%syr %soldGC%smon %soldGC%sm %soldGC%ssd %soldGC%sn\n", submol, upperstr(site), submol, upperstr(site), submol, upperstr(site), submol, upperstr(site), submol, upperstr(site)
	
	variable CurrentMonth =  str2num(StringFromList(1, Secs2date(DateTime,-1), "/")[0,3])
	for (inc = 0; inc < numpnts(MR); inc += 1 )
		if (( YYYY[inc] >= ReturnCurrentYear() ) && ( MM[inc] > CurrentMonth ))
			break
		endif
		if (numtype(MR[inc]) != 0)
			fprintf handle, "%4d %7d       nan       nan    0\n", YYYY[inc], MM[inc]
		else
			if (cmpstr(mol, "SF6") == 0 )
				fprintf handle, "%4d %7d  %8.3f  %8.3f  %3d\n", YYYY[inc], MM[inc], MR[inc], dMR[inc], points[inc]
			else
				fprintf handle, "%4d %7d  %8.1f  %8.1f  %3d\n", YYYY[inc], MM[inc], MR[inc], dMR[inc], points[inc]
			endif
		endif
	endfor

	Close handle
	
	Killwaves /Z tmpheader
	SetDataFolder root:

end

function SaveOldGCdata_All(mol)
	string mol

	variable inc
	string s
	for (inc=0; inc<ItemsInList(AllSites); inc+=1)
		s = UpperStr(StringFromList(inc, AllSites))
		SaveOldGCdata(s, upperstr(mol))
	endfor 
	
end

function returnMonth( secs )
	variable /d secs
	
	string day = Secs2Date(secs,-2)
	return str2num(day[5,6])
end

function returnYear( secs )
	variable /d secs
	
	string day = Secs2Date(secs,-2)
	return str2num(day[0,3])
end

// Removes recent data
// used to remove CATS MC data after 2013
function NanRecentData(mol, posttime)
	string mol
	variable posttime
	
	string wvst, timest, slst = "brw;sum;nwr;mlo;smo;spo;"
	variable p

	// monthly data
	SetDataFolder root:month:
	NanRecentData_folder(mol, slst, posttime)
	
	// daily data
	SetDataFolder root:day:
	NanRecentData_folder(mol, slst, posttime)

	// hourly data
	SetDataFolder root:hour:
	NanRecentData_folder(mol, slst, posttime)

	// global data
	SetDataFolder root:global:
	timest = "insitu_MC_date"
	wvst = "insitu_NH_" + mol
	wave wv = $wvst
	p = BinarySearch($timest, posttime)
	wv[p,numpnts(wv)] = nan
	wvst = "insitu_SH_" + mol
	wave wv = $wvst
	p = BinarySearch($timest, posttime)
	wv[p,numpnts(wv)] = nan
	wvst = "insitu_Global_" + mol
	wave wv = $wvst
	p = BinarySearch($timest, posttime)
	wv[p,numpnts(wv)] = nan

	SetDataFolder root:
end

function NanRecentData_folder(mol, slst, posttime)
	string mol, slst
	variable posttime
	
	variable i, p
	string wvst, timest, s	

	for(i=0; i<ItemsInList(slst); i+=1)
		s = StringFromList(i, slst)
		wvst = s + "_" + mol
		wave wv = $wvst
		timest = s + "_time"
		p = BinarySearch($timest, posttime)
		wv[p,numpnts(wv)] = nan
	endfor

end

Function saveZonaldata(mol)
	string mol
	
	HATSglobalMeans(mol=mol)

	SetDataFolder root:global
	wave tt = $"HATS_"+mol+"_date"
	wave mr = $"HATS_LatBan_"+mol
	wave sd = $"HATS_LatBan_"+mol+"_sd"
	wave bins = latbin
	
	string file = "HATS_Zonal_"+mol+".txt"
	string txt, tmp
	
	variable i, j, handle, YYYY, MM
	variable pts = Dimsize(bins, 0)
	
	PathInfo/S SaveDataPath
	if (V_flag==0)
		NewPath /C/M="Where should I store the data?" SaveDataPath
	endif

	Close /a
	Open /C="R*ch"/P=SaveDataPath handle file
	
	variable z0 = 90, z1
	fprintf handle, "# NOAA Combined Data for %s\n", mol
	fprintf handle, "# Zonal means\n"
	fprintf handle, "# Columns from left to right\n"
	fprintf handle, "# Year, month\n"
	for(i=0;i<pts;i+=1)
		z1 = bins[i][0]
		fprintf handle, "# Mean mixing ratio zone %2d to %2d and uncertainty\n", z0, z1
		z0 = z1
	endfor
	
	for(i=0;i<numpnts(tt);i+=1)
		YYYY = str2num(StringFromList(2, Secs2Date(tt[i],-1), "/"))
		MM = str2num(StringFromList(1, Secs2Date(tt[i],-1), "/"))
		sprintf txt, "%4d, %2d", YYYY, MM
		for(j=0;j<pts;j+=1)
			sprintf tmp, ", %8.3f, %6.3f", mr[i][j], sd[i][j]
			txt += tmp
		endfor
		fprintf handle, txt+"\n"
	endfor	
	
	SetDataFolder root:
	
end

// run after loading MSD data
Function ZonalMeansMSD()

	string mol, mols = "h1211;HCFC22;HCFC141b;HCFC142b;HFC134a;HFC152a;CH3Br;CH3Cl;C2Cl4;C2H6;C3H8"
	variable i

	for(i=0; i<ItemsInList(mols); i+=1)
		mol = StringFromList(i, mols)
		Global_Mean(insts="MSD", prefix="HATS", mol=mol, plot=1, offsets=2)
		saveZonaldata(mol)
	endfor
	
end