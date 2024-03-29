#pragma rtGlobals=2		// Use modern global access method.


#include "macros-utilities"
#include "macros-geoff"
#include "macros-strings and lists"
#include <strings as lists>
#include "macros-CATS Data Panel"
#include "macros-CATS conc"
#include "macros-CATS combine mols"
#include "macros-CATS flagging"
#include "macros-CATS Cal3"
#include "macros-CATS detrend"
#include <median>
#include <Remove Points>
#include "HATS FTP Data"

// use SaveGraphCopy
//#include "SaveGraph"

menu "Macros"
	"CATS Panel /F4", /Q
	"Add_Molecule"
	"-"
	"Load Integration Results/1"
	"Cal Flagging/2"
	"-"
	"Load CCGG file"
	//"Load Cal3 Results"
	//"Compare Cals"
	"Flag Cal Data in marquee", flagcaldata()
	"-"
	"Set Man Flag To Perm Flag"
	"Flag Inside Box FAST/F2", /Q
	"Un Flag Inside Box/F3", /Q
	"-"
	"Calc Daily Uncertainties"
	"Display Data Table", DataTable()
	"-"
	"Calc Conc Disp /5"	
	"Best Conc Calc /6"
	"Recalc All Mols"
	"Re Load And Calc", ReloadAndCalcAll()
	"-"
	"Edit Comb Table"
	"Combine Data Sets"
	"-"
	"Daily Means Plot"
	"Month Means Plot /7"
	"-"
	"Make Site Table"
	"load Standards File"
	"Load Drift Tables"
	"Append Method Lines"
	"Append Cal Resp Lines", AppendCalResp()
	"Append Flagged Data  /F9", /Q
	"-"
	"Export For Web Pages"
	"-"
	"Nuke Extra Data"
	"remove Displayed Objects"
	"remove Displayed Graphs"

end

//SetIgorHook IgorBeforeNewHook=CATSpanelhook
//Function CATSpanelhook( igorApplicationNameStr )
//	string igorApplicationNameStr
//	
//	CATSpanel()
//end


Function AfterFileOpenHook(refNum,file,pathName,type,creator,kind)
	Variable refNum,kind
	String file,pathName,type,creator
	
	CATSpanel()
	
	return 0							// don't prevent MIME-TSV from displaying
End


Macro LoadEngFile(suffix)
	string suffix=""
	prompt suffix, "Suffix to append to loaded waves (or leave blank)."
	
	silent 1; pauseupdate
	
	if (cmpstr(suffix,"") != 0)
		string allwvlst = WaveList("*",";","")
	endif
	
	LoadWave/J/W/A/O/K=1/V={" "," $", 3, 0}/L={1, 3, 0, 0, 0 }
	
	// Rename the wave if needed.
	if (cmpstr(suffix,"") != 0)
		string Newallwvlst = WaveList("*",";","")
		string wvLstDiff = ReturnListDiff(allwvlst, Newallwvlst, ";")
		string com
		sprintf com, "lbat(\"duplicate /o @ @_%s\", \"%s\")", suffix, wvLstDiff
		execute com
		sprintf com, "lbat(\"killwaves /z @\", \"%s\")", wvLstDiff
		execute com
	endif

end

Macro AutoLoadEngFile(fileNm, suffix)
	string fileNm,suffix=""
	prompt fileNm, "Engineering file name"
	prompt suffix, "Suffix to append to loaded waves (or leave blank)."
	
	silent 1; pauseupdate

	variable yy = str2num(fileNm[0,3])
	variable jDay = str2num(fileNm[7,9]), inc, lastPt
	
	if (cmpstr(suffix,"") != 0)
		string allwvlst = WaveList("*",";","")
	endif
	
	PathInfo EngPath
	if (V_Flag == 0)
		NewPath/O/Q/Z/M="Path to engineering files" EngPath
		PathInfo EngPath
	endif
	
	s/J/W/A/O/K=1/P=EngPath/V={" "," $", 1, 0}/L={1, 3, 0, 0, 0 } fileNm
	SetScale d 0,0,"", TimeW
	TimeW = jDay + TimeW/86400
	lastPt = numpnts(TimeW)-1
	if (TimeW[0] > TimeW[lastPt])
		do
			TimeW[inc] -= 1
			inc += 1
		while ((TimeW[inc] > TimeW[lastPt]) || (inc >= numpnts(TimeW)))
	endif
	
	// Rename the wave if needed.
	if (cmpstr(suffix,"") != 0)
		//string Newallwvlst = WaveList("*",";","")
		//string wvLstDiff = ReturnListDiff(allwvlst, Newallwvlst, ";")
		string wvLstDiff = S_wavenames
		string com
		sprintf com, "lbat(\"duplicate /o @ @_%s\", \"%s\")", suffix, wvLstDiff
		execute com
		sprintf com, "lbat(\"killwaves /z @\", \"%s\")", wvLstDiff
		execute com
		print "Waves renamed with suffix \"" + suffix + "\""
	endif

end


// use this proceedure to add a molecule to the experiment
proc Add_Molecule(mol)
	string mol = StrMakeOrDefault("root:G_mol", "N2O")
	prompt mol, "Name of molecule"

	silent 1
	
	G_mol = mol
		
	if (exists("G_loadMol") != 2)
		string /g G_loadMol = mol + ";"
	else
		G_loadMol = AddListItem(mol, G_loadMol)
	endif
	
	make /o/t/n=1 $(mol + "_best")="cal12"
	make /o/n=1 $(mol + "_offset")=0
	
end

function  LoadIntegrationResults([mol])
	string mol
	
	SVAR G_loadMol, G_mol, G_site3
	Variable /G root:G_recalcSD = 1
	NVAR recalc = root:G_recalcSD

	// added this variable 20200730
	NVAR /Z G_load2yrs
	if (!NVAR_Exists(G_load2yrs))
		variable /G root:G_load2yrs = 1
	endif
	
	if (ParamIsDefault(mol))
		Prompt mol, "Which molecule", popup, G_loadMol
		DoPrompt "Loading CATS integration results", mol
		if (v_flag==1)
			abort
		endif
		G_mol = mol
	endif

	//MoveWindow /C 10, 1100, 1300, 1300

	// don't load the comb date	
	if (stringmatch(mol, "*comb") != 1)
		if (G_load2yrs == 1)
			LoadGCwerksResults_2yrs(mol)
		else
			//LoadGCwerksResults_txt(mol)
			LoadGCwerksResults(mol)
		endif
		if ((cmpstr(mol, "F11") == 0) && (cmpstr(G_site3, "mlo") == 0))
			LoadGCwerksResults_mloF11()
		endif
		postloadfunctions(mol)
	endif

	MakeStandardWaves(mol, 1)
end

// new slimed down load proceedure (130208)
// this version loads the .txt file
function LoadGCwerksResults_txt(mol)
	string mol

	SVAR G_site3, G_mol, G_loadMol
	string filename = G_site3 + "_" + mol + ".txt"
	G_mol = mol

	SetStationVariables(G_site3)

	NVAR V_ratioPlot = V_ratioPlot
	
	//NewPath /O ConcPath,  "Hats:gc:cats_results:"
	NewPath/O/Q ConcPath "catsdata:cats_results:"
	
	String Custom 
	Sprintf Custom, "C=1,F=6,N=%s_date;C=1,F=0,N=timewv;C=1,F=0,T=8,N=%s_port;C=1,F=0,T=2,N=%s_rt;C=1,F=0,T=2,N=%s_H;C=1,F=0,T=2,N=%s_A;", mol, mol, mol, mol, mol
	LoadWave/O/A/J/V={"\t, "," $",0,0}/R={English,1,2,2,1,"YearMonthDayOfMonth",40}/B=Custom /P=ConcPath filename
	
	Wave DD = $mol + "_date"
	Wave TT = timewv
	DD += floor(TT/100)*60*60 + mod(TT,100)*60		// add in the hours and mins
	SetScale d 0,0,"dat", DD
	Killwaves TT
		
end

// newer .csv file (additional sig fig) 20200730
function LoadGCwerksResults(mol)
	string mol

	SVAR G_site3, G_mol
	G_mol = mol
	SetStationVariables(G_site3)

	GetFileFolderInfo /Q/Z "Hats:gc:cats_results:"
	if (V_Flag == 0)
		// office computer
		NewPath /O ConcPath,  "Hats:gc:cats_results:"
	else
		GetFileFolderInfo /Q/Z "catsdata:cats_results:"
		if (V_Flag == 0)
			// home computer
			NewPath/O/Q ConcPath "catsdata:cats_results:"
		else
			abort "Can't set ConcPath"
		endif
	endif
	
	String Custom , filename = G_site3 + "_" + mol + ".csv"
	Sprintf Custom, "C=1,F=8,N=%s_date;C=1,F=0,T=8,N=%s_port;C=1,F=0,T=2,N=%s_rt;C=1,F=0,T=2,N=%s_H;C=1,F=0,T=2,N=%s_A;", mol, mol, mol, mol, mol
	LoadWave/O/A/J/V={","," $",0,0}/L={0,1,0,0,0}/R={English,2,2,2,2,"Year-Month-DayOfMonth",40}/B=Custom /P=ConcPath filename
	
	Wave DD = $mol + "_date"
	SetScale d 0,0,"dat", DD
			
end

// cleanup bad values, create flag waves, load standards file
function postloadfunctions(mol)
	string mol
	
	SVAR G_site3
	Wave DD = $mol + "_date"
	Wave ht = $mol+"_H"
	Wave ar = $mol+"_A"
	//Wave rt = $mol+"_rt"
	Wave port = $mol+"_port"
	ht = SelectNumber(ht<=0, ht, NaN)
	ar = SelectNumber(ar<=0, ar, NaN)
	//rt = SelectNumber(rt<=0, rt, NaN)
	
	KillNan4(DD, ht, ar, port)

	Make /o/n=(numpnts(DD)) $mol+"_flag"/WAVE=flag=1
	Duplicate /o flag, $mol+"_manflag"/WAVE=manflag
	// make flag type wave
	make /o/n=(numpnts(flag)) $mol+"_flagtype"/WAVE=ftype = NO_FLAG
	print numpnts(DD)
		
	// regular flagging on all data
	//FlaggingNew(mol)

	// use permanent flags
	if (exists(mol+"_permflag") == 1)
		PreserveFlags(mol)
	else
		make /d/n=(0)/o $mol+"_permflag"
		SetScale d 0,0,"dat", $mol+"_permflag"
	endif
	
	if (cmpstr(G_site3,"tdf") == 0)
		loadTDF_StandardsFile()	
	elseif ( cmpstr(G_site3, "sum") == 0 )
		loadStandardsFile_sum()
	else
		loadStandardsFile()
	endif

	MakeSiteTableFUNCT(G_site3, mol)
	
	CalFlagging(mol=mol, attrib=ReturnIntAttrib(), meth="c1")

End

function killNaN5(w1, w2, w3, w4, w5)
	wave w1, w2, w3, w4, w5

	Variable p, numPoints, numNaNs
	Variable w1v, w2v, w3v, w4v, w5v
	
	numNaNs = 0
	p = 0											// the loop index
	numPoints = numpnts(w1)			// number of times to loop

	do
		w1v = w1[p]
		w2v = w2[p]
		w3v = w3[p]
		w4v = w4[p]
		w5v = w5[p]
		if ((numtype(w1v)==2) %| (numtype(w2v)==2) %| (numtype(w3v)==2) %| (numtype(w4v)==2) %| (numtype(w5v)==2))		// either is NaN?
			numNaNs += 1
		else										// if not an outlier
			w1[p - numNaNs] = w1v		// copy to input wave
			w2[p - numNaNs] = w2v		// copy to input wave
			w3[p - numNaNs] = w3v		// copy to input wave
			w4[p - numNaNs] = w4v		// copy to input wave
			w5[p - numNaNs] = w5v		// copy to input wave
		endif
		p += 1
	while (p < numPoints)
	
	// Truncate the wave
	DeletePoints numPoints-numNaNs, numNaNs, w1, w2, w3, w4, w5
	
	return numpnts(w1)
	
end


function LoadGCwerksResults_2yrs(mol)
	string mol

	SVAR G_site3, G_mol
	G_mol = mol

	GetFileFolderInfo /Q/Z "Hats:gc:cats_results:"
	if (V_Flag == 0)
		// office computer
		NewPath /O ConcPath,  "Hats:gc:cats_results:"
	else
		GetFileFolderInfo /Q/Z "catsdata:cats_results:"
		if (V_Flag == 0)
			// home computer
			NewPath/O/Q ConcPath "catsdata:cats_results:"
		else
			abort "Can't set ConcPath"
		endif
	endif
	
	String Custom, filename = G_site3 + "_" + mol + "_2yr.csv"
	Sprintf Custom, "C=1,F=8,N=%s_date_2yr;C=1,F=0,T=8,N=%s_port_2yr;C=1,F=0,T=2,N=%s_rt_2yr;C=1,F=0,T=2,N=%s_H_2yr;C=1,F=0,T=2,N=%s_A_2yr;", mol, mol, mol, mol, mol
	LoadWave/O/A/J/V={","," $",0,0}/L={0,1,0,0,0}/R={English,2,2,2,2,"Year-Month-DayOfMonth",40}/B=Custom /P=ConcPath filename

	Wave DD = $mol+"_date"
	Wave DD2yr = $mol+"_date_2yr"
	Wave port = $mol+"_port"
	Wave port2yr = $mol+"_port_2yr"
	Wave ht = $mol+"_H"
	Wave ht2yr = $mol+"_H_2yr"
	Wave ar = $mol+"_A"
	Wave ar2yr = $mol+"_A_2yr"
	// not saving _rt waves
	//Wave rt = $mol+"_rt"
	//Wave rt2yr = $mol+"_rt_2yr"
	
	variable pt = BinarySearch(DD, DD2yr[0])
	if (pt < 0)
		abort "Problem append 2yr data to original data"
	endif

	splice(DD, DD2yr, pt)
	splice(port, port2yr, pt)
	splice(ht, ht2yr, pt)
	splice(ar, ar2yr, pt)
	//splice(rt, rt2yr, pt)		// not saving _rt waves

	SetScale d 0,0,"dat", DD
	
end

// function to load results from Gaussian fits
function LoadGCwerksResults_mloF11()

	string mol = "F11"

	SVAR G_site3, G_mol
	G_mol = mol

	
	String Custom, filename = "F11_gauss_fits.csv"
	Sprintf Custom, "C=1,F=8,N=%s_date_g;C=1,F=0,T=8,N=%s_port_g;C=1,F=0,T=2,N=%s_rt_g;C=1,F=0,T=2,N=%s_H_g;C=1,F=0,T=2,N=%s_A_g;", mol, mol, mol, mol, mol
	LoadWave/O/A/J/V={","," $",0,0}/L={0,1,0,0,0}/R={English,2,2,2,2,"Year-Month-DayOfMonth",40}/B=Custom /P=home filename

	Wave DD = $mol+"_date"
	Wave DDg = $mol+"_date_g"
	Wave port = $mol+"_port"
	Wave portg = $mol+"_port_g"
	Wave ht = $mol+"_H"
	Wave htg = $mol+"_H_g"
	Wave ar = $mol+"_A"
	Wave arg = $mol+"_A_g"
	// not saving _rt waves
	//Wave rt = $mol+"_rt"
	//Wave rtg = $mol+"_rt_g"
	
	variable pt0 = BinarySearch(DD, DDg[0])
	variable pt1 = BinarySearch(DD, DDg[Inf])

	insert(DD, DDg, pt0, pt1)
	insert(port, portg, pt0, pt1)
	insert(ht, htg, pt0, pt1)
	insert(ar, arg, pt0, pt1)
	//splice(rt, rtg, pt0, pt1)		// not saving _rt waves

	SetScale d 0,0,"dat", DD
	
end


function splice(wv0, wv1, pt)
	wave wv0, wv1
	variable pt
	
	Duplicate /FREE/R=[0,pt-1] wv0, wv_head
	Concatenate /o {wv_head, wv1}, $NameOfWave(wv0)

end

function insert(wv0, wv1, pt0, pt1)
	wave wv0, wv1
	variable pt0, pt1
	
	Duplicate /FREE/R=[0,pt0-1] wv0, wv_head
	Duplicate /FREE/R=[pt1,Inf] wv0, wv_tail
	Concatenate /o {wv_head, wv1, wv_tail}, $NameOfWave(wv0)

end

function SetStationVariables(st)
	string st
	
	SVAR G_station, G_site3

	if (cmpstr(st,"mlo") == 0)
		G_station = "Mauna Loa, Hawaii"
		G_site3 = "mlo"
	elseif (cmpstr(st,"brw") == 0)
		G_station = "Barrow, Alaska"
		G_site3 = "brw"
	elseif (cmpstr(st,"nwr") == 0)
		G_station = "Niwot Ridge, Colo."
		G_site3 = "nwr"
	elseif (cmpstr(st,"smo") == 0)
		G_station = "American Samoa"
		G_site3 = "smo"
	elseif (cmpstr(st,"spo") == 0)
		G_station = "South Pole"
		G_site3 = "spo"
	elseif (cmpstr(st,"sum") == 0)
		G_station = "Summit, Greenland"
		G_site3 = "sum"
	elseif (cmpstr(st,"tdf") == 0)
		G_station = "Tierra del Fuego"
		G_site3 = "tdf"
	endif

end


function NukeExtraData()
	
	SVAR mollst= G_loadMol
	
	bat("killwaves /z @", "*_rt")
	bat("killwaves /z @", "*_rt_*")
	bat("killwaves /z @", "*_w")
	bat("killwaves /z @", "*_w_*")
//	bat("killwaves /z @", "*_a")
//	bat("killwaves /z @", "*_a_*")
	bat("killwaves /z @", "*_concA")
	bat("killwaves /z @", "*_concA_*")
	bat("killwaves /z @", "*_concH")
	bat("killwaves /z @", "*_concH_*")
	bat("killwaves /z @", "*_2i")
	bat("killwaves /z @", "*_4i")
	bat("killwaves /z @", "*_6i")
	bat("killwaves /z @", "*_8i")
	bat("killwaves /z @", "*_2f")
	bat("killwaves /z @", "*_6f")
	
	// ratio waves from IDL
	bat("killwaves /Z @", "*_C1a")
	bat("killwaves /Z @", "*_C1h")
	bat("killwaves /Z @", "*_C2a")
	bat("killwaves /Z @", "*_C2h")
	bat("killwaves /Z @", "*_C12a")
	bat("killwaves /Z @", "*_C12h")
	
	bat("killwaves /z @", "*_IDLflag")
	killwaves /z tmpIDL
	
	killwaves /z ALMsecWave
	
	// obsolete waves
	lbat("killwaves @", WaveList("*best_conc_Monthly_YYYY", ";", ""))
	lbat("killwaves @", WaveList("*best_conc_Monthly_MM", ";", ""))
	lbat("killwaves @", WaveList("*best_conc_MonthlyL", ";", ""))
	lbat("killwaves @", WaveList("*best_conc_MonthlyR", ";", ""))
	lbat("killwaves @", WaveList("*best_conc_Daily_YYYY", ";", ""))
	lbat("killwaves @", WaveList("*best_conc_Daily_MM", ";", ""))
	lbat("killwaves @", WaveList("*best_conc_DailyL", ";", ""))
	lbat("killwaves @", WaveList("*best_conc_DailyR", ";", ""))
	lbat("killwaves @", WaveList("*_2", ";", ""))
	lbat("killwaves @", WaveList("*_4", ";", ""))
	lbat("killwaves @", WaveList("*_6", ";", ""))
	lbat("killwaves @", WaveList("*_8", ";", ""))
	lbat("killwaves @", WaveList("*_code", ";", ""))
	lbat("killwaves @", WaveList("*_portnm", ";", ""))
	lbat("Killwaves @", WaveList("*_best_conc_stats", ";", ""))
	lbat("Killwaves @", WaveList("ALM*on", ";",""))
	lbat("Killwaves @", WaveList("ALM*off", ";",""))
	lbat("Killwaves @", WaveList("ALM*date", ";",""))

	// obsolete waves added 130214
//	lbat("Killwaves @", WaveList("*_YYYY", ";",""))
//	lbat("Killwaves @", WaveList("*_DD", ";",""))
//	lbat("Killwaves @", WaveList("*_HH", ";",""))
//	lbat("Killwaves @", WaveList("*_MN", ";",""))
//	lbat("Killwaves @", WaveList("*_MM", ";",""))
//	lbat("@ = nan", WaveList("*_ratio_*", ";", ""))
//	lbat("Killwaves @", WaveList("*_ratio_*", ";", ""))
//	lbat("Killwaves @", WaveList("*_seasonal*", ";", ""))
//	lbat("Killwaves @", WaveList("*_sampflow", ";", ""))
//	lbat("Killwaves @", WaveList("*_Hist", ";", ""))
//	lbat("Killwaves @", WaveList("*_detrend", ";", ""))
//	lbat("Killwaves @", WaveList("*delt", ";", ""))
//	lbat("Killwaves @", WaveList("*_hcalval", ";", ""))
//	lbat("Killwaves @", WaveList("*_lcalval", ";", ""))
	
	// delete old _conc wave
	variable i, cinc, pnts
	string mol, concLst, concWv
	do
		mol = StringFromList(i, mollst)
		pnts = numpnts($(mol+"_best_conc"))
		concLst = WaveList(mol+"_*_conc", ";", "")
		cinc = 0
		do
			concWv = StringFromList(cinc, concLst)
			if (numpnts($concWv) < pnts)
				Killwaves /Z $concWv
				print "Deleted: ", concWv
			endif
			cinc += 1
		while (cinc < ItemsInList(concLst))
		i += 1
	while (i < ItemsInList(mollst))
	
	// Delete temporary data folders
	string fold
	i = 0
	do
		fold = GetIndexedObjName("root:", 4, i)
		if (strlen(fold) == 0)
			break
		endif
		if ((strsearch(fold, "_calLines", 0) > 0 ) || (strsearch(fold, "_CL", 0) > 0 ) || (strsearch(fold, "_MT", 0) > 0 ) || (strsearch(fold, "Algo", 0) > 0 ))
			KillDataFolder /Z $fold
			if ( V_flag == 0 )
				print "Deleted DataFolder: ", fold
				i -= 1
			endif
		endif
		i += 1
 	while (1)
	
end


function CalFlagging([mol, meth, attrib])
	string mol, meth, attrib
	
	SVAR /Z G_calmeth
	if (!SVAR_Exists(G_calmeth))
		String /G G_calmeth = "c1"
	endif
	
	SVAR G_mol, G_attrib, G_loadMol, G_site3
	Prompt mol, "Molecule", popup, G_loadMol
	Prompt meth, "Method", popup, "c1;c2;c1/c2"
	Prompt attrib, "Type of response", popup, "H;A"
	if (ParamIsDefault(mol) || ParamIsDefault(meth) || ParamIsDefault(attrib))
		mol = G_mol
		meth = G_calmeth
		attrib = G_attrib
		DoPrompt "Cal flagging figures", mol, meth, attrib
		if (V_flag)
			abort	// cancled
		endif
	endif
	G_mol = mol
	G_calmeth = meth
	G_attrib = attrib
	
	CreateCalRatios(mol, attrib)
	
	String win = "cal_flagging_fig"
	
	DoWindow /K $win
	Display /K=1/W=(768,44,1644,625)
	DoWindow /C $win
	
	if (cmpstr(meth, "c1") == 0)
		AppendToGraph c1 vs c1x
		AppendToGraph/R c1r vs c1x
		ModifyGraph marker(c1)=8
		ModifyGraph rgb(c1r)=(24576,24576,65535)
	elseif (cmpstr(meth, "c2") == 0)
		AppendToGraph c2 vs c2x
		AppendToGraph/R c2r vs c2x
		ModifyGraph marker(c2)=8
		ModifyGraph rgb(c2r)=(24576,24576,65535)
	else
		Duplicate /o c2, c12r
		Duplicate /o c2x, c12rx
		wave c1, c2, c1x,  c2x
		c12r = c1[BinarysearchInterp(c1x, c2x[p])]/c2
		AppendToGraph c12r vs c12rx
		ModifyGraph marker(c12r)=8
	endif
	
	ModifyGraph mode=3
	ModifyGraph msize=2
	ModifyGraph grid(left)=1,grid(right)=1
	ModifyGraph axisEnab(left)={0.42,1}
	ModifyGraph axisEnab(right)={0,0.4}
	ModifyGraph dateInfo(bottom)={0,0,0}
	ModifyGraph mirror(bottom)=2
	Label left meth + "  " + attrib
	Label bottom "Date"
	Label right meth + " ratio"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 right
	
	TextBox/C/N=info/A=LT/X=1.78/Y=1.38 G_site3 + " " + mol + "  " + meth
	
	Button cal1,pos={823,11},size={46,39},proc=CATS_ButtonProc,title="Cal1"
	Button cal1,fColor=(65535,60076,49151)
	Button cal2,pos={823,56},size={46,39},proc=CATS_ButtonProc,title="Cal2"
	Button cal2,fColor=(65535,60076,49151)
	Button lastyear,pos={823,258},size={46,39},proc=CATS_ButtonProc,title="Last\r3 mon"
	Button lastyear,fColor=(55535,50076,49151)
	Button appendinterp,pos={824,100},size={46,39},proc=CATS_ButtonProc,title="Interp"
	Button appendinterp,fColor=(65535,60076,49151)
	
	appendInterp()
	
	// look at last year as default
	Wave day = $mol + "_date"
	variable pt = numpnts(day)-1
	SetAxis bottom day[pt]-60*60*24*365, day[pt]
	SetAxis/A=2 left
	SetAxis/A=2 right

end


// Returns the likely molecule plotted on a graph.
// also sets G_mol
Function/S MolFromGraph()

	SVAR Gmol = root:G_mol
	String mol, traces
	// First look for a _date wave
	traces = WaveList("*_date", ";","WIN:")
	
	if ( strlen(traces) > 0 )
		mol = traces[0, strsearch(traces, "_", 0)-1]
		Gmol = mol
		return mol
	else
		return Gmol
	endif

End

// repeatedly calling this function will toggle the cal values lines
Function CalValueLinesToPlot()

	String mol =  MolFromGraph()
	String traces = TraceNameList("", ";", 1)

	String hi = mol + "_hstd_conc"
	String lo = mol + "_lstd_conc"
	String xx = mol + "_date"

	if ( strsearch(traces, hi, 0) != -1 )
		RemoveFromGraph $hi, $lo
		Return 0
	else
		AppendToGraph $hi $lo vs $xx
		ModifyGraph lsize($hi)=2,rgb($hi)=(32769,65535,32768)
		ModifyGraph lsize($lo)=2,rgb($lo)=(65535,16385,16385)
	endif		
		
end

function AirSampColor() 

	string mol =  MolFromGraph()
	string conc = mol + "_best_conc_hourlyY"
	string port = mol + "_port"

	string traces = TraceNameList("", ";", 1)
	if ( strsearch(traces, conc, 0) == -1 )
		return 0
	endif
	
	// check to see if trace is already colored
	if ( strsearch(TraceInfo("", conc, 0), "BlueHot", 0) == -1 )
		ModifyGraph zColor($conc)={$port,1,8,BlueHot}
	else
		ModifyGraph zColor($conc)=0
	endif

end

Function WeeklyAvg([mol,attrib])
	string mol, attrib

	if ( ParamIsDefault(mol) )
		SVAR Gmol = root:G_mol
		mol = Gmol
	endif
	if ( ParamIsDefault(attrib) )
		attrib = ReturnIntAttrib()
	endif

	Variable i, ptL, ptR
	Variable secsperweek = 7*24*60*60
	Variable NumPointsRequired = 20
	String com, best = "best_conc"
	
	string WeekXst = mol + "_" + best + "_weeklyX"
	string WeekYst = mol + "_" + best + "_weeklyY"
	string WeekSDst = mol + "_" + best + "_weeklySD"
	//string WeekMin = mol + "_" + best + "_weeklyMin"
	
	Wave bestconc = $mol + "_" + best
	Wave air = $mol + "_"+ best + "_hourlyY"
	Wave airX = $mol + "_date"
	Wave airSD = $mol + "_" + attrib + "_sd"
	Wave flag = $mol + "_flag"
	
	// update the hourlyY wave
	Duplicate /o bestconc, air
	air *= flag

	Make /o/d/n=((ReturnCurrentYear()-1998+1)*52) $WeekXst/WAVE=wX=NaN, $WeekYst/WAVE=wY=NaN, $WeekSDst/WAVE=wSD=NaN
	
	wX = date2secs(1998,1,4) + secsperweek*p			// Jan 4th is the first Sunday of 1998

	ptR = BinarySearchInterp(airX, wx[0] - secsperweek/2)
	for(i=1; i<numpnts(wX); i+=1)
		ptL = ptR
		ptR = BinarySearchInterp(airX, wx[i] + secsperweek/2)
		if ((ptR-ptL) >= NumPointsRequired)
			WaveStats/Q /M=1/R=[ptL, ptR] air
			wY[i] = V_avg
			WaveStats/Q /M=1/R=[ptL, ptR] airSD
			wSD[i] = V_avg
		endif
	endfor
	
	// Trim leading and trailing NaNs
	Deletepoints 0, FirstGoodPt(wY), wY, wX, wSD
	Deletepoints LastGoodPt(wY)+1, Inf, wY, wX, wSD
	
	WeeklyAvgPlot()
	
end

//Function WeeklyAvg([mol,attrib])
	string mol, attrib

	if ( ParamIsDefault(mol) )
		SVAR Gmol = root:G_mol
		mol = Gmol
	endif
	if ( ParamIsDefault(attrib) )
		attrib = ReturnIntAttrib()
	endif
	
	Variable inc = 0, Dinc = 0, ptL, ptR
	Variable secsperweek = 604800
	Variable NumPointsRequired = 20
	String com, best = "best_conc"
	
	string WeekX = mol + "_" + best + "_weeklyX"
	string WeekY = mol + "_" + best + "_weeklyY"
	string WeekSD = mol + "_" + best + "_weeklySD"
	string WeekMin = mol + "_" + best + "_weeklyMin"
	string DayCatY = mol + "_"+ best + "_hourlyY"
	string DayCatX = mol + "_date"
	string flag = mol + "_flag"

	Make /o/d/n=1000 $WeekX=NaN, $WeekY=NaN, $WeekSD=NaN, $WeekMin=NaN
	wave WeekXwv = $WeekX
	wave WeekYwv = $WeekY
	wave WeekSDwv = $WeekSD
	wave WeekMinwv = $WeekMin

	String dailySDstr = mol + "_" + attrib + "_sd"
	Wave dailySD = $dailySDstr
		
	if (exists(mol+ "_" + best) == 1)
		duplicate /o $mol+ "_" + best, $DayCatY
	endif
	Wave DayCatYwv = $DayCatY
	Wave DayCatXwv = $DayCatX
	
	if (exists(flag) == 1)
		wave flagwv = $flag
		DayCatYwv *= flagwv
		sprintf com, "%s := %s * %s", nameofwave(DayCatYwv), nameofwave(DayCatYwv), nameofwave(flagwv)
		execute com
	endif

	WeekXwv = date2secs(1998,1,4) + secsperweek*x			// Jan 4th is the first Sunday of 1998

	do
		ptL = BinarySearchInterp(DayCatXwv, WeekXwv[Dinc]-secsperweek/2)
		ptL = SelectNumber( numtype(ptL), ptL, 0 )
		ptR = BinarySearchInterp(DayCatXwv, WeekXwv[Dinc]+secsperweek/2)
		ptR = SelectNumber( numtype(ptR), ptR, numpnts(DayCatXwv)-1 )
		
		if ( DayCatXwv < WeekXwv[Dinc] + secsperweek/2 )
			WaveStats/Q/R=[ptL, ptR] dailySD
			if (numtype(V_sdev) == 2)
				WeekSDwv[Dinc] = NaN
				WeekYwv[Dinc] = NaN
			elseif (V_npnts >= NumPointsRequired)
				WeekSDwv[Dinc] = V_avg
				WaveStats/Q/R=[ptL, ptR] DayCatYwv
				WeekYwv[Dinc] = V_avg
				WeekMinwv[Dinc] = V_min
			endif
		endif
		
		Dinc += 1
	while (DayCatXwv[numpnts(DayCatXwv)-1] >= WeekXwv[Dinc-1]+secsperweek/2)
	
	DeletePoints Dinc,5000,WeekYwv, WeekXwv, WeekSDwv, WeekMinwv

	// delete all leading NaNs
	variable i
	for (i = 0; i<=numpnts(WeekXwv); i+=1)
		if ( numtype(WeekYwv[i]) == 0 )
			DeletePoints 0,i-1,WeekYwv, WeekXwv, WeekSDwv, WeekMinwv
			break
		endif
	endfor
	
	WeeklyAvgPlot()
	
end

Function WeeklyAvgPlot( )

	SVAR mol = root:G_mol
	string attrib = ReturnIntAttrib()

	string best = "best_conc"
	string WeekX = mol + "_" + best + "_weeklyX"
	string WeekY = mol + "_" + best + "_weeklyY"
	string WeekSD = mol + "_" + best + "_weeklySD"
	string WeekMin = mol + "_" + best + "_weeklyMin"
	string DayCatY = mol + "_"+ best + "_hourlyY"
	string DayCatX = mol + "_date"
	string flag = mol + "_flag"
	variable al1 = -999, al2, ab1, ab2

	string win = "Weekly_" +mol+"_ALL"
	String title = "Daily Avg " + mol + " " + " ALL"
	DoWindow /F $win

	// save plot scaling
//	if ( strlen(winlist(win, ";", "")) > 0 )
//		GetAxis /Q left
//		al1 = v_min
//		al2 = v_max
//		GetAxis /Q bottom
//		ab1 = v_min
//		ab2 = v_max
//	endif

	// only draw if win is missing
	if ( strlen(winlist(win, ";", "")) == 0 )
		DoWindow /K $win
		Display/K=1 /W=(28,44,761,448) as title
		DoWindow /C $win
		
		AppendToGraph $DayCatY vs $DayCatX
		AppendToGraph $WeekY vs $WeekX
		ModifyGraph margin(top)=54,gfSize=14,wbRGB=(49151,65535,57456)
		ModifyGraph gfSize=14, mode($WeekY)=4, marker=19
		ModifyGraph mode($DayCatY)=3,marker($DayCatY)=0
		ModifyGraph msize=2,rgb($DayCatY)=(0,43690,65535)
		ModifyGraph rgb($WeekY)=(0,0,0)
		ModifyGraph grid=1, mirror=2
		Label left mol + " Mixing Ratio (attrib=" + attrib + ")"
		Label bottom "Date"
		if ( al1 == -999 )
			SetAxis/A/N=1 left
			SetAxis/A/N=1 bottom
		else
			SetAxis/N=1 left, al1, al2
			SetAxis/N=1 bottom, ab1, ab2
		endif
		ErrorBars $WeekY Y,wave=($WeekSD,$WeekSD)
	
		Button refresh_graph,pos={627,16},size={70,20},proc=CATS_ButtonProc,title="Refresh"
		Button refresh_graph,fColor=(65535,60076,49151)
		Button recalc_graph,pos={539,16},size={80,20},proc=CATS_ButtonProc,title="Recalculate"
		Button recalc_graph,fColor=(65535,65534,49151)
		Button togglecallines_graph,pos={75,4},size={100,20},proc=CATS_ButtonProc,title="Cal Tank Changes"
		Button togglecallines_graph,fSize=10,fColor=(65535,65535,65535)
		Button toggleairports_graph,pos={180,4},size={100,20},proc=CATS_ButtonProc,title="Color Air Ports"
		Button toggleairports_graph,fSize=10,fColor=(65535,65535,65535)
		Button togglecalresp_graph,pos={180,26},size={100,20},proc=CATS_ButtonProc,title="Cal Responses"
		Button togglecalresp_graph,fSize=10,fColor=(65535,65535,65535)
		Button togglecals_graph,pos={75,26},size={100,20},proc=CATS_ButtonProc,title="Cal Values"
		Button togglecals_graph,fSize=10,fColor=(65535,65535,65535)
		Button datatable_graph,pos={296,16},size={100,20},proc=CATS_ButtonProc,title="Data Table"
		Button datatable_graph,fSize=10,fColor=(60535,60535,60535)
		Button export_graph,pos={8,5},size={54,37},proc=CATS_ButtonProc,title="Export"
		Button export_graph,fSize=10,fColor=(65535,54611,49151)
		CheckBox timezone,pos={6,383},size={81,15},proc=CATS_CheckProc,title="Local Time"
		CheckBox timezone,help={"Toggle for local time."},font="Lucida Grande",fSize=12
		CheckBox timezone,value= 0
		CheckBox errorbars,pos={412,18},size={76,15},proc=CATS_CheckProc,title="Error bars"
		CheckBox errorbars,help={"Toggle for local time."},font="Lucida Grande",fSize=12
		CheckBox errorbars,value= 0
	endif

End

Function MonthMeansPlot([mol,attrib])
	string mol, attrib
	
	SVAR G_loadMol, G_mol, G_attrib
	NVAR G_plot, G_med, G_recalcSD
	
	mol=StrMakeOrDefault("root:G_mol", "F11")
	attrib=ReturnIntAttrib(mol=mol)
	variable med=NumMakeOrDefault("root:G_med", 1)
	variable plot=NumMakeOrDefault("root:G_plot", 1)
	variable comp=2
	prompt mol, "Which molecule", popup, G_loadMol
	prompt attrib, "Attribute", popup, "H;A"
	prompt med, "Which method", popup, "Means;Medians"
	prompt plot, "Make a plot?", popup, "no;yes"
	prompt comp, "Compare old monthly data to new monthly data (yes will create plot)", popup, "no;yes"
	DoPrompt "Monthly mean/median figure", mol, attrib, med, plot, comp
	if (V_flag==1)
		abort
	endif
	
	G_mol = mol
	G_plot = plot
	G_med = med
	G_attrib = attrib
	
	if (stringmatch(mol, "*comb") != 1)
		if (G_recalcSD == 1)
			CalcDailyUncertainties()
		endif
		SetManFlagToPermFlag(mol=mol)
	endif
	PrepForComparison(mol)	

	variable timerREF = StartMSTimer
	MonthlyMeansCalc(mol, attrib, med, plot, comp)
	variable microSeconds = StopMSTimer(timerREF)
	//print "MonthlyMeansCalc took ", microSeconds/1e6, " seconds"
	
end

function MonthlyMeansCalc(mol, attrib, med, plot, comp)
	string mol, attrib
	variable med, plot, comp
	
	wave best = $mol + "_best_conc_hourlyY"
	wave dateWv = $mol + "_date"
	
	SVAR G_station = G_station
	variable YYYY = 1998, MM = 1
	variable stp = (ReturnCurrentYear() - 1998) +1
	
	wave dailySD = $(mol + "_" + attrib + "_sd")
	string bestMXstr = mol + "_best_conc_MonthlyX"
	string bestMYstr = mol + "_best_conc_MonthlyY"			// Monthly means
	string bestMSDstr = mol + "_best_conc_MonthlySD"			// standard deviation (instrument precision)
	string bestMVRstr = mol + "_best_conc_MonthlyVar"		// atmospheric variance (added 180921)
	string bestMMedstr = mol + "_best_conc_MonthlyMed"		// Monthly medians
	string bestMNumstr = mol + "_best_conc_MonthlyNum"
	string plt = mol + "_month_means"
	string com

	make /n=(stp*12) /o $bestMYstr/WAVE=bestMY=NaN, $bestMSDstr/WAVE=bestSD=nan, $bestMMedstr/WAVE=bestMed=nan, $bestMNumstr/WAVE=bestNum=nan
	make /n=(stp*12) /o/d $bestMXstr/WAVE=bestMX=NaN, $bestMVRstr/WAVE=bestVR=nan
	SetScale d 0,0,"dat", bestMX
	
	variable /d inc, lpt, rpt, num
	do
		lpt = BinarySearch(dateWv, date2secs(YYYY, MM, 1)) + 1
		rpt = BinarySearch(dateWv, date2secs(YYYY, MM+1, 1))
		if (rpt == -2 )
			rpt = numpnts(dateWv)-1
		endif
		num = rpt-lpt

		if ( num > 30 )		
			Wavestats /Q/R=[lpt, rpt] best
			
			if (V_npnts > 20 )
				bestMX[inc] = date2secs(YYYY, MM, 15)
				bestMY[inc] = V_avg
				bestMed[inc] = Median(best, lpt, rpt)
				bestVR[inc] = V_sdev
				bestNum[inc] = V_npnts
				Wavestats /Q/M=1/R=[lpt, rpt] dailySD
				bestSD[inc] = V_avg
			else
				bestMX[inc] = date2secs(YYYY, MM, 15)
				bestMY[inc] = NaN
				bestMed[inc] = NaN
				bestVR[inc] = NaN
				bestNum[inc] = V_npnts
				bestSD[inc] = NaN
			endif

		else
			bestMX[inc] = date2secs(YYYY, MM, 15)
			bestMY[inc] = NaN
			bestMed[inc] = NaN
			bestVR[inc] = NaN
			bestSD[inc] = NaN
			bestNum[inc] = 0
		endif

		MM += 1
		if ( MM > 12 )
			MM = 1
			YYYY += 1
		endif

		inc += 1

	while (rpt < numpnts(dateWv)-2)
	
	// Remove the NaNs
	deletepoints inc, Inf, bestMX,bestMY,bestSD,bestVR,bestMed,bestNum 
	
	// delete NaNs at top and bottom
	inc = FirstGoodPt(bestMy)
	deletepoints 0, inc, bestMX,bestMY,bestSD,bestVR,bestMed,bestNum 
	
	inc = LastGoodPt(bestMy)
	deletepoints inc+1, Inf, bestMX,bestMY,bestSD,bestVR,bestMed,bestNum 	
	
	// Overwrite median on mean wave
	if (med == 2)
		FastOp bestMY = bestMed
	endif

	// Calculate difference between old and new
	if ( comp == 2)
		string DF = "root:" + mol + "_MonthlyBackup"
		variable i, pt
		SetDataFolder $DF
		wave oldY = $mol + "_best_conc_MonthlyY"
		wave oldX = $mol + "_best_conc_MonthlyX"
		duplicate /o bestMY diff
		duplicate /o bestMX diffX
		diff = nan
		for(i=0; i<numpnts(diffX); i+=1)
			pt = BinarySearch(oldX, bestMX[i])
			if ( pt >= 0 )
				diff[i] = bestMY[i] - oldY[pt]
			else
				diff[i] = nan
			endif
		endfor
		diff = diff/bestMY * 100
		SetDataFolder root:
	endif
	
	if ((plot == 2) || (comp == 2))
		MeansPlot( mol )
	endif

end

Function MeansPlot( mol ) 
	string mol
	
	SVAR Station = root:G_station
	
	SetDataFolder  root:
	string NewY = mol + "_best_conc_MonthlyY"
	string NewX = mol + "_best_conc_MonthlyX"
	string NewSD = mol + "_best_conc_MonthlySD"
	string com
	
	String win = mol + "_month_means"
	String DF = "root:" + mol + "_MonthlyBackup:"
	
	DoWindow /K $win
	
	SetDataFolder $DF
	String OldY = mol + "_best_conc_MonthlyY"
	String OldX = mol + "_best_conc_MonthlyX"
	String OldSD = DF + mol + "_best_conc_MonthlySD"
	String diff = DF + "diff"
	String diffX = DF + "diffX"
	
	WaveStats /Q $diff
	
	Display /W=(37,275,956,763)/K=1  $"root:"+NewY vs $"root:"+NewX
	AppendToGraph $OldY vs $OldX
	AppendToGraph/R $diff vs $diffX
	DoWindow /C $win
	DoUpdate
	SetDataFolder root:
	
	ModifyGraph gfSize=14
	ModifyGraph mode=3
	ModifyGraph marker($NewY)=19
	ModifyGraph marker($NewY#1)=5
	ModifyGraph marker(diff)=17
	ModifyGraph rgb($NewY#1)=(0,0,65535),rgb(diff)=(3,52428,1)
	ModifyGraph gaps(diff)=0
	ModifyGraph grid(left)=1,grid(bottom)=1
	ModifyGraph zero(right)=1
	ModifyGraph mirror(bottom)=2
	ModifyGraph lblMargin(right)=6
	ModifyGraph lblLatPos(right)=-2
	ModifyGraph axisEnab(left)={0,0.75}
	ModifyGraph axisEnab(right)={0.75,1}
	ModifyGraph dateInfo(bottom)={0,0,0}
	ModifyGraph lowTrip(right)=0.01
	Label left mol + " Monthly Means (ppt)"
	Label bottom "Date"
	Label right "New - Old (%)"
	SetAxis/A/N=1 left
	SetAxis/A/N=1/E=2 right
	ErrorBars $NewY Y,wave=($NewSD,$NewSD)
	ErrorBars $NewY#1 Y,wave=($OldSD,$OldSD)
	TextBox/C/N=text0/F=0/A=MC/X=-51.85/Y=-60.87 Station
	sprintf com, "\\s(%s) New Monthly Means\r\\s(%s#1) Old Monthly Means\r\\s(diff) diff", NewY, NewY
	Legend/C/N=text1/J/S=3/X=75/Y=83 com

	SetDataFolder root:
	
EndMacro


// Function duplicates monthly mean data to a data folder for later camparison of newly calculated monthly means
function PrepForComparison(mol)
	string mol

	string bestMXstr = mol + "_best_conc_MonthlyX"
	string bestMYstr = mol + "_best_conc_MonthlyY"
	string bestMSDstr = mol + "_best_conc_MonthlySD"
	string bestMNumstr = mol + "_best_conc_MonthlyNum"
	
	string foldNM =  mol+"_MonthlyBackup"
	string fold = ":" + foldNM + ":"
	

	// If the datafolder MonthlyBackup exists DO NOT overwrite it
	if (DataFolderExists(foldNM) != 1)
		NewDataFolder $foldNM
		duplicate $bestMXstr, $(fold+bestMXstr)
		duplicate $bestMYstr, $(fold+bestMYstr)
		duplicate $bestMSDstr, $(fold+bestMSDstr)
		duplicate $bestMNumstr, $(fold+bestMNumstr)
	endif

end

function KillMonthlyMeanBackup(mol)
	string mol
	
	string fold = "root:" + mol + "_MonthlyBackup"
	if (DataFolderExists(fold))
		KillDataFolder $fold
	endif
end


Proc DailyMeansPlot(mol, attrib, med, plot, comp)
	string mol=StrMakeOrDefault("root:G_mol", "F11")
	string attrib=StrMakeOrDefault("root:G_attrib", "H")
	variable med=NumMakeOrDefault("root:G_med", 1)
	variable plot=NumMakeOrDefault("root:G_plot", 1)
	variable comp=2
	prompt mol, "Which molecule", popup, G_loadMol
	prompt attrib, "Attribute", popup, "H;A"
	prompt med, "Which method", popup, "Means;Medians"
	prompt plot, "Make a plot?", popup, "no;yes"
	prompt comp, "Compare old Daily data to new Daily data (yes will create plot)", popup, "no;yes"
	
	silent 1; pauseupdate
	
	G_plot = plot
	G_med = med
	G_attrib = attrib
	
	
	PrepForDailyComparison(mol)	

	variable timerREF = StartMSTimer
	DailyMeansPlotFUNCT(mol, attrib, med, plot, comp)
	variable microSeconds = StopMSTimer(timerREF)
//	print "DailyMeansPlotFUNCT took ", microSeconds/1e6, " seconds"
	
end

function DailyMeansPlotFUNCT(mol, attrib, med, plot, comp)
	string mol, attrib
	variable med, plot, comp
	
	wave best = $mol + "_best_conc_hourlyY"
	wave dateWv = $mol + "_date"
	
	//print "Calculating daily means: " + mol
	
	SVAR G_station = G_station
	variable stp = ReturnCurrentYear() - 1998 + 1
	
	variable YYYY = 1998, MM = 1, DD = 1

	wave dailySD = $(mol + "_" + attrib + "_sd")
	string bestDXstr = mol + "_best_conc_DailyX"
	string bestDYstr = mol + "_best_conc_DailyY"			// Daily means
	string bestDSDstr = mol + "_best_conc_DailySD"		// standard deviation
	string bestDMedstr = mol + "_best_conc_DailyMed"		// Daily medians
	string bestDNumstr = mol + "_best_conc_DailyNum"
	string plt = mol + "_Day_means"
	string com

	make /n=(stp*366) /o $bestDYstr/WAVE=bestDY=NaN, $bestDSDstr/WAVE=bestSD=nan, $bestDMedstr/WAVE=bestDmed=nan, $bestDNumstr/WAVE=bestNum=nan
	make /n=(stp*366) /o /d $bestDXstr/WAVE=bestDX=NaN
	SetScale d 0,0,"dat", bestDX

	variable inc, lpt, rpt, num, medin, day
	rpt = -1
	do
		day = date2secs(YYYY, MM, DD)
		lpt =  rpt + 1
		rpt = BinarySearchInterp( dateWv, day + 60*60*24 )
		num = rpt-lpt

		if ( num > 5 )		
			medin = Median(best, lpt, rpt)
			wavestats /M=1/Q/R=[lpt, rpt] best
			
			bestDX[inc] = day + 60*60*12
			if ( V_npnts > 4 )
				bestDY[inc] = V_avg
				bestDmed[inc] = medin
				bestNum[inc] = V_npnts
				Wavestats /Q/M=1/R=[lpt, rpt] dailySD
				bestSD[inc] = V_avg
			else
				bestDY[inc] = nan
				bestDmed[inc] = nan
				bestNum[inc] = 0
				bestSD[inc] = NaN
			endif
	
		else
			bestDX[inc] = day + 60*60*12
			bestDY[inc] = NaN
			bestDmed[inc] = NaN
			bestSD[inc] = NaN
			bestNum[inc] = 0
		endif
		
		DD += 1
		if ( DD > NumDaysInMonth(YYYY, MM) )
			DD = 1
			MM += 1
		endif
		if ( MM > 12 )
			YYYY += 1
			MM = 1
		endif
		
		inc += 1
		
	while (YYYY < ReturnCurrentYear() + 1)

	// delete NaNs at top and bottom
	inc = FirstGoodPt(bestDY)
	deletepoints 0, inc, bestDX,bestDY,bestSD,bestDMed,bestNum 
	
	inc = LastGoodPt(bestDY)
	deletepoints inc+1, Inf, bestDX,bestDY,bestSD,bestDMed,bestNum 
	
	// Overwrite median on mean wave
	if (med == 2)
		FastOp bestDY = bestDmed
	endif
	
	if ((plot == 2) || (comp == 2))
		DoWindow /K $plt
		Display /K=1/W=(134,193,1039,534) bestDY vs bestDX
		ModifyGraph gfSize=14
		ModifyGraph mode=4
		ModifyGraph marker=19
		ModifyGraph grid=1
		ModifyGraph mirror=2
		ModifyGraph dateInfo(bottom)={0,0,0}
		Label left mol + " Daily Means (ppt)"
		Label bottom "Date"
		SetAxis/A/N=1 left
		sprintf com, "ErrorBars %s Y,wave=(%s,%s)", bestDYstr, bestDSDstr,bestDSDstr
		execute com
		Textbox/N=text0/F=0/A=MC/X=-40.44/Y=44.95 G_station
		DoWindow /C $plt
		
		if (comp == 2)
			string fold = "root:" + mol + "_DailyBackup:"
			wave oldY = $(fold+bestDYstr)
			wave oldX = $(fold+bestDXstr)
			wave oldSD = $(fold+bestDSDstr)
			appendtograph oldY vs oldX
			sprintf com, "ModifyGraph marker(%s#1)=16", bestDYstr ; 			execute com
			sprintf com, "ModifyGraph rgb(%s#1)=(0,0,65535)", bestDYstr ; 	execute com
			ModifyGraph gfSize=14
			ModifyGraph mode=4
			sprintf com, "ErrorBars %s#1 Y,wave=(%s%s,%s%s)", bestDYstr, fold, bestDSDstr, fold, bestDSDstr
			execute com
			sprintf com, "\\s(%s) New Daily Means\r\\s(%s#1) Old Daily Means", bestDYstr, bestDYstr
			Legend/N=text1/J/S=3/X=1.75/Y=3.36  com
		endif

	endif	
	
end

function NumDaysInMonth(y, m)
	variable y, m
	
	variable ly = 0
	
	if ((m == 1) || (m == 3) || (m == 5) || (m == 7) || (m == 8) || (m == 10) || (m == 12))
		return 31
	elseif ((m == 4) || (m == 6) || (m == 9) || (m == 11))
		return 30
	elseif (m == 2)
		if ( (mod(y, 4) == 0) && (y != 2000))
			ly = 1
		endif
		return 28 + ly
	else
		return 0
	endif
	
end

// Function duplicates Daily mean data to a data folder for later camparison of newly calculated Daily means
function PrepForDailyComparison(mol)
	string mol

	string bestDXstr = mol + "_best_conc_DailyX"
	string bestDYstr = mol + "_best_conc_DailyY"
	string bestDSDstr = mol + "_best_conc_DailySD"
	string bestDNumstr = mol + "_best_conc_DailyNum"
	string bestDMstr = mol + "_best_conc_Daily_MM"
	string bestYYYYstr = mol + "_best_conc_Daily_YYYY"
	
	string foldNM =  mol+"_DailyBackup"
	string fold = ":" + foldNM + ":"
	

	// If the datafolder DailyBackup exists DO NOT overwrite it
	if (DataFolderExists(foldNM) != 1)
		NewDataFolder $foldNM
		duplicate $bestDXstr, $(fold+bestDXstr)
		duplicate $bestDYstr, $(fold+bestDYstr)
		duplicate $bestDSDstr, $(fold+bestDSDstr)
		duplicate $bestDNumstr, $(fold+bestDNumstr)
	endif

end

function KillDailyMeanBackup(mol)
	string mol
	
	string fold = "root:" + mol + "_DailyBackup"
	if (DataFolderExists(fold))
		KillDataFolder $fold
	endif
end

Proc  Point2Date(mol, pnt)
	string mol
	variable pnt
	prompt mol, "Which molecule", popup, G_loadMol
	prompt pnt, "Point number to retrieve data from"
	
	Point2DateFUNCT(mol,pnt)
end

function Point2DateFUNCT(mol, pnt)
	string mol
	variable pnt
	
	wave YYYY = $mol + "_YYYY"
	wave MM = $mol + "_MM"
	wave DD = $mol + "_DD"
	wave HH = $mol + "_HH"
	wave MN = $mol + "_MN"
	
	printf "Point %d is %4d%2d%2d.%2d%2d\r", pnt, YYYY[pnt], MM[pnt], DD[pnt], HH[pnt], MN[pnt]

end

// attrib H is HARDWIRED!!!!! --- FIXED 081219
proc ExportForWebPages( mol )
	string mol = "_All_"
	prompt mol, "Which molecule", popup, G_loadMol + "_ALL_"
	
	//MoveWindow /C 10, 800, 1000, 950
	
	ExportForWebPagesFUNCT(mol)
	SyncFigures()
	
end

function ExportForWebPagesFUNCT(mol)
	string mol

	SVAR site = G_site3
	SVAR G_molLst = G_loadMol
	
	variable i

	// handle recursive call
	if (cmpstr(mol,"_ALL_") == 0) 
		for(i=0; i<ItemsInList(G_molLst); i+=1)
			mol = StringFromList(i, G_molLst)
			ExportForWebPagesFUNCT(mol)
		endfor
		return 1
	endif
	
	// work computer	
	NewPath /C/O/Q SavePath, "Macintosh HD:Users:gdutton:Data:CATS:web-GML:webdata:insitu:cats:conc:"

	NukeExtraData()
	
	// remove monthly means window if it is open.
	string win = mol + "_month_means"
	Dowindow /K $win
	DoWindow /K cal_flagging_fig
	
	//Kill the montly mean backup folder (when running Export, this assumes the current data is good).
	KillMonthlyMeanBackup(mol)
	KillDailyMeanBackup(mol)

	SetManFlagToPermFlag(mol=mol)

	//print "Exporting " + mol
	String plt = "Weekly_" + mol + "_ALL"
	DoWindow /F $plt

	if (V_flag == 1)
		
		// Save the Monthly and Daily medians
		string attrib = ReturnIntAttrib(mol=mol)
		MonthlyMeansCalc(mol, attrib, 2, 1, 1)		
		DailyMeansPlotFUNCT(mol, attrib, 2, 1, 1)

		string savelist = UpperStr("n2o sf6 f12 f11 f113 h1211 mc ccl4 hcfc22 hcfc142b ch3cl")
		if ( GrepString(mol, "comb") )
			WebPlot(mol)
		elseif ( GrepString(savelist, UpperStr(mol) ) )
			if ( !GrepString(G_molLst, mol+"comb" ))
				WebPlot(mol)
			endif
		endif		
	endif
		
end

Function WebPlot( mol )
	string mol

	SVAR station = G_station
	SVAR site = G_site3
	string hX = mol + "_date"
	string hY = mol + "_best_conc_hourlyY"
	string newX = mol + "_date_new"
	string newY = mol + "_best_conc_new"
	string mX = mol + "_best_conc_monthlyX"
	string mY = mol + "_best_conc_monthlyY"
	string mSD = mol + "_best_conc_monthlySD"
	wave/t ALMs = $site + "_ALMdates"
	string win = mol + "_webPlot"
	string leftlabel = FullMolName(mol)
	string com	
	
	// date data was last submitted.
	variable num = numpnts(ALMs)
	variable subdate = date_return(ALMs[num-3])
	
	wave hourX = $hX
	Extract /o $hX, $newX, hourX > subdate
	Extract /o $hY, $newY, hourX > subdate
	
	// Summit data is now finallized.  180323
	if (cmpstr(site, "SUM")==0)
		wave new_y = $newY
		new_y = Nan
	endif
	
	if (exists(hX) == 0 )
		abort
	endif

	DoWindow /k $win
	Display /W=(915,442,1578,829)/K=1  $hY vs $hX
	AppendToGraph $newY vs $newX
	AppendToGraph $mY vs $mX
	DoWindow /C $win
	
	ModifyGraph margin(bottom)=70,margin(right)=20,margin(left)=75, Font="Geneva",gfSize=14,width=550,height=300
	ModifyGraph mode($hY)=3,mode($mY)=4, mode($newY)=3
	ModifyGraph marker($mY)=19
	ModifyGraph rgb($hY)=(0,43690,65535),rgb($mY)=(8738,8738,8738), rgb($newY)=(65535,32764,16385)
	ModifyGraph msize=2, grid=1, mirror=2, axThick=2
	ModifyGraph lblPos(left)=78, lblMargin(bottom)=10
	ModifyGraph margin(top)=30
	ModifyGraph manTick(bottom)={2966457600,2,0,0,yr},manMinor(bottom)={1,50}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left "\\f01" + leftlabel
	Label bottom "\\f01Date"
	SetAxis/A/N=1 left
	SetAxis/N=1 bottom 2966457600,date2secs(ReturnCurrentYear()+1, 1, 1)
	ErrorBars $mY Y,wave=($mSD,$mSD)
	TextBox/C/N=StationID/F=0/A=LC/X=-0.91/Y=56.33 "\\F'Georgia'\\f01" + station
	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-36.73/Y=-68.67 "\\Z10NOAA/ESRL insitu halocarbons program\r\\Z09" + date()
	Legend/C/N=text0/J/F=0/A=RC/X=-1.27/Y=56.00
	sprintf com, "\\F'Georgia'\\Z13\\s(%s)Hourly samples\\s(%s)Preliminary data  \\s(%s) Monthly median", hY, newY, mY
	AppendText com
	SetDrawLayer UserFront
	SetDrawEnv linefgc= (65535,65535,65535)
	DrawPICT -0.126853146853147,1.07705340699816,0.4,0.4,NOAAlogo

	sprintf com, "SavePICT/O/P=SavePath/E=-5/B=72 as \"%s_%s_all.png\"", site, LowerStr(ReplaceString("comb", mol, ""))
	execute com	
	
	SyncFigures()
	
End

// runs upload.sh script which syncs figures to the website
// same function in main CATS Data experiment (macros-CATS)
function SyncFigures()

	string igorCmd, unixCmd
	
	unixCmd = "\\\"/Users/gdutton/data/CATS/web-GML/upload.sh\\\""
	
	sprintf igorCmd, "do shell script \"%s\"", unixCmd
	ExecuteScriptText igorCmd
	
	Print S_value
end

Function/S FullMolName(mol)
	string mol

	if (GrepString(mol, "N2O|n2o"))
		return "N2O (ppb)"
	elseif (GrepString(mol, "SF6|sf6"))
		return "SF6 (ppt)"
	elseif (GrepString(mol, "F113|f113"))
		return "CFC-113 (ppt)"
	elseif (GrepString(mol, "F11|f11"))
		return "CFC-11 (ppt)"
	elseif (GrepString(mol, "F12|f12"))
		return "CFC-12 (ppt)"
	elseif (GrepString(mol, "HCFC22|hcfc22"))
		return "HCFC-22 (ppt)"
	elseif (GrepString(mol, "142b"))
		return "HCFC-142b (ppt)"
	elseif (GrepString(mol, "MC|mc"))
		return "CH3CCl3 (ppt)"
	elseif (GrepString(mol, "CCl4|ccl4"))
		return "CCl4 (ppt)"
	elseif (GrepString(mol, "CHCl3|chcl3"))
		return "CHCl3 (ppt)"
	elseif (GrepString(mol, "CCl4|ccl4"))
		return "CCl4 (ppt)"
	elseif (GrepString(mol, "CH3Cl|ch3cl"))
		return "CH3Cl (ppt)"
	elseif (GrepString(mol, "CH3Br|ch3br"))
		return "CH3Br (ppt)"
	elseif (GrepString(mol, "1211"))
		return "halon-1211 (ppt)"
	elseif (GrepString(mol, "COS|cos|OCS|ocs"))
		return "COS (ppt)"
	elseif (GrepString(mol, "CO|co"))
		return "CO (ppb)"
	elseif (GrepString(mol, "H2|h2"))
		return "H2 (ppb)"
	elseif (GrepString(mol, "CH4|ch4"))
		return "CH4 (ppb)"
	else
		return ""
	endif	

end

// function to return calc table row number for a given date (secs)
function CalcTableRow(sec)
	variable /d sec
	
	SVAR site = root:G_site3

	// calc table waves
	wave /t ALMdates = $("root:" + site + "_ALMdates")
	
	// make some temp waves
	if (( exists("root:ALMsecWave") == 0 ) || ( numpnts(ALMsecWave) != numpnts(ALMdates)) )
		make /d/o/n=(numpnts(ALMdates)) ALMsecWave = date_return(ALMdates)
	endif
	
	variable row = BinarySearch( ALMsecWave, sec )
	
	// secs is more recent than last tanks change date
	if ( row == -2 ) 
		row = numpnts(ALMdates)-1
	endif
	
//	killwaves ALMsecWave
	
	return row
	
end

// this function will return the concentration calculation method for a given time and molecule
function/s LookUpCalMethod(secs, mol)
	variable /d secs
	string mol
	
	wave /t best = $"root:" + mol + "_best"
	variable row = CalcTableRow(secs)
	return best[row]
	
end


//function CalcDailyUncertainties()

	SVAR mol = G_mol
	SVAR site = G_site3
	NVAR recalc = G_recalcSD
	string attrib = ReturnIntAttrib()

	wave day = $(mol + "_date")
	wave port = $(mol + "_port")
	variable SDonNumDays =  5

	String statwvstr = mol + "_" + attrib + "_sd"
	make /O/n=(numpnts(day)) $statwvstr/WAVE=statwv = nan

	wave /t stddate = $(site + "_ALMdates")
	wave /t best = $mol+"_best"
	
	MakeStandardWaves(mol, 1)		// not using the adjust version
	CreateCalRatios(mol, attrib)

	Wave c1r, c1x, c2r, c2x

	StatsOnNDays(c1r, c1x, statwv, day, 1, SDonNumDays)	
	duplicate /FREE statwv tmpstatwv1

	StatsOnNDays(c2r, c2x, statwv, day, 2, SDonNumDays)	
	Duplicate /FREE statwv tmpstatwv2

	Variable i, lp, rp
	// step through the ALMdates table for cal method
	for(i=0; i<numpnts(stddate); i+=1)
		lp = BinarySearch(day, date_return(stddate[i]))
		rp = BinarySearch(day, date_return(stddate[i+1]))

		lp = SelectNumber(lp==-1, lp, 0)
		rp = SelectNumber(rp==lp, rp, numpnts(day)-1)
		
		if ((cmpstr(best[i], "cal12") == 0) || (cmpstr(best[i], "curve1") == 0) || (cmpstr(best[i], "cal12_area") == 0))
			statwv[lp, rp] = sqrt(tmpstatwv1[p]^2 + tmpstatwv2[p]^2)
		elseif (cmpstr(best[i], "cal12a") == 0)
			statwv[lp, rp] = sqrt(tmpstatwv1[p]^2 + tmpstatwv2[p]^2)
		elseif ((cmpstr(best[i], "cal1") == 0) || (cmpstr(best[i], "cal1_adj") == 0))
			statwv[lp, rp] = tmpstatwv1[p]
		elseif ((cmpstr(best[i], "cal2") == 0) || (cmpstr(best[i], "cal2_adj") == 0) || (cmpstr(best[i], "cal2_area") == 0))
			statwv[lp, rp] = tmpstatwv2[p]
		elseif (cmpstr(best[i], "none") == 0)
			statwv[lp, rp] = NaN
		else
			abort "Undefined uncertainty method. Error in CalcDailyUncertainties"
		endif
	endfor
	
	recalc = 2
	
end

// added area methods
function CalcDailyUncertainties()

	SVAR mol = G_mol
	SVAR site = G_site3
	NVAR recalc = G_recalcSD
	string attrib = ReturnIntAttrib()

	wave day = $(mol + "_date")
	wave port = $(mol + "_port")
	variable SDonNumDays =  5

	String statwvstr = mol + "_" + attrib + "_sd"
	make /O/n=(numpnts(day)) $statwvstr/WAVE=statwv = nan

	wave /t stddate = $(site + "_ALMdates")
	wave /t best = $mol+"_best"
	
	MakeStandardWaves(mol, 1)		// not using the adjust version

	// check to see if an area method is used in calculating mixing ratios
	String list
	wfprintf list, "%s;", best
	if (strsearch(list, "_area", 0) > 0)
		CreateCalRatios(mol, "a")
		Wave c1r, c1x, c2r, c2x
	
		StatsOnNDays(c1r, c1x, statwv, day, 1, SDonNumDays)	
		duplicate /FREE statwv tmpstatwv1_area
		StatsOnNDays(c2r, c2x, statwv, day, 2, SDonNumDays)	
		Duplicate /FREE statwv tmpstatwv2_area
	endif

	CreateCalRatios(mol, attrib)

	Wave c1r, c1x, c2r, c2x

	StatsOnNDays(c1r, c1x, statwv, day, 1, SDonNumDays)	
	duplicate /FREE statwv tmpstatwv1
	StatsOnNDays(c2r, c2x, statwv, day, 2, SDonNumDays)	
	Duplicate /FREE statwv tmpstatwv2
	
	Variable i, lp, rp
	// step through the ALMdates table for cal method
	for(i=0; i<numpnts(stddate); i+=1)
		lp = BinarySearch(day, date_return(stddate[i]))
		rp = BinarySearch(day, date_return(stddate[i+1]))

		lp = SelectNumber(lp==-1, lp, 0)
		rp = SelectNumber(rp==lp, rp, numpnts(day)-1)
		
		// area methods
		if (cmpstr(best[i], "cal12_area") == 0)
			statwv[lp, rp] = sqrt(tmpstatwv1_area[p]^2 + tmpstatwv2_area[p]^2)
		elseif (cmpstr(best[i], "cal2_area") == 0)
			statwv[lp, rp] = tmpstatwv2_area[p]
		
		elseif ((cmpstr(best[i], "cal12") == 0) || (cmpstr(best[i], "curve1") == 0) || (cmpstr(best[i], "brwcal2_drift") == 0) || (cmpstr(best[i], "mlocal2_drift") == 0))
			statwv[lp, rp] = sqrt(tmpstatwv1[p]^2 + tmpstatwv2[p]^2)
		elseif (cmpstr(best[i], "cal12a") == 0)
			statwv[lp, rp] = sqrt(tmpstatwv1[p]^2 + tmpstatwv2[p]^2)
		elseif ((cmpstr(best[i], "cal1") == 0) || (cmpstr(best[i], "cal1_adj") == 0))
			statwv[lp, rp] = tmpstatwv1[p]
		elseif ((cmpstr(best[i], "cal2") == 0) || (cmpstr(best[i], "cal2_adj") == 0))
			statwv[lp, rp] = tmpstatwv2[p]
		elseif (cmpstr(best[i], "none") == 0)
			statwv[lp, rp] = NaN
		else
			abort "Undefined uncertainty method. Error in CalcDailyUncertainties"
		endif
	endfor
	
	recalc = 2
	
end


// wvY and wvX are the data waves
// statwvY and statwvX are the results waves, they can be different lengths than wvY and wvX
// whichstand:  1 = cal1, 2 = cal2
function StatsOnNDays(wvY, wvX, statwvY, statwvX, whichstand, dayBox)
	wave wvY, wvX, statwvY, statwvX
	variable whichstand, dayBox
	
	SVAR mol = G_mol

	variable daySecs = dayBox * 60 * 60 * 24
	variable /d lp, rp, i, pt
	variable missingDATA = 5		// if less then missingDATA points use NAN as uncertainty
	
	wave port = $(mol + "_port")
	if ( whichstand == 1 )
		wave std = $(mol + "_lstd_conc")
	else
		wave std = $(mol + "_hstd_conc")
	endif
	
	Extract /FREE/INDX statwvX, airinjs, (port==4)||(port==8)
		
	for (i=0; i< numpnts(airinjs); i+=1)
		pt = airinjs[i]
		lp = BinarySearch(wvX, statwvX[pt] - daySecs/2)
		rp = BinarySearch(wvX, statwvX[pt] + daySecs/2)

		lp = SelectNumber(lp==-1, lp, 0)
		rp = SelectNumber(rp==-2, rp, numpnts(wvX)-1)
	
		if (rp-lp > missingDATA)
			Wavestats /Q/R=[lp, rp] wvY

			if (V_npnts >= missingDATA)
				statwvY[pt] = SelectNumber(whichstand==1, V_sdev * std[pt], V_sdev * std[pt] *1.1111)
			else
				statwvY[pt] = NaN
			endif
		endif
	endfor
	
end


// appends NOAA logo to plot
function NOAAlogo()

	PathInfo logoPATH
	if ( V_flag == 0 )
		NewPath /O/C logoPATH "Macintosh HD:data:CATS:"
	endif
	
	if (strlen(PICTInfo("NOAAlogo")) == 0 )
		LoadPICT /O/P=logoPATH "noaa_logo.png", NOAAlogo
	endif
	
	// bottom left corner
	DrawPICT 0.007,0.87,0.4,0.4,NOAAlogo

end

function DataTable()
	string mol = MolFromGraph()

	string d = mol + "_date"
	string h = mol + "_" + ReturnIntAttrib()
	string c = mol + "_best_conc_hourlyY"
	string port = mol + "_port"
	string flg = mol + "_flag"
	string typ = mol + "_flagtype"
	string win = mol + "_DATAtable"
	
	DoWindow /K $win
	Edit/K=1/W=(765,46,1401,748) $d,$h,$c,$port, $flg,$typ
	ModifyTable format(Point)=1,format($d)=8,width($d)=116
	DoWindow /C $win
	
	// set top left cell to first point displayed in graph
	GetAxis /Q bottom
	variable pt = BinarySearch($d, V_min)
	ModifyTable topLeftCell=(pt , 0)
	
End