#pragma rtGlobals=1		// Use modern global access method.


menu  "Macros"

	"Add New Mol /1"
	"-"
	"Quick Fit"
	"Cursors 2 DB"
	"-"
	"Load Chroms and Go /2"
	"Intgrate Current"
	"-"
	"Data Table"
	"Data Plot /3"
	"-"
	"Void Data"

end

Function BeforeFileOpenHook(refNum, fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr, fileKind)
	Variable refNum, fileKind
	String fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr
	
	SVAR G_molList = G_molList
	SVAR G_chromNote = G_chromNote
	NVAR G_JulianDec = G_JulianDec
	string chromLst
	
	string mol, JulianDate
	variable len = strlen(fileNameStr), inc = 0, numMols = NumElementsInList(G_molList, ";")
	
	if ((cmpstr(fileNameStr[len-3,len], "itx")==0) * (fileKind == 5))
		LoadWave/Q/T/O/P=$pathNameStr fileNameStr
		Killwaves /Z chrom1, chrom2, chrom3, chrom4
		JulianDate = fileNameStr[0,3] + fileNameStr[7,9] + "." + fileNameStr[10,13]
		G_JulianDec = JulianDate2Dec(JulianDate)
		chromLst = wavelist("chr*_0000*", ";", "")
		rename $GetStrFromList(chromLst, 0, ";") chrom1
		rename $GetStrFromList(chromLst, 1, ";") chrom2
		rename $GetStrFromList(chromLst, 2, ";") chrom3
		rename $GetStrFromList(chromLst, 3, ";") chrom4
		G_chromNote = Note(chrom1)
		print "Integrating: " + fileNameStr
		Do
			mol = GetStrFromList(G_molList, inc, ";")
			Intg(mol, fileNameStr, 1)
			inc += 1
		while (inc < numMols)
			
		return 1
	endif
				
end

Function /d Gauss_Fit_line(w, x)
	wave /d w
	variable /d x

	return w[0] + w[1]*exp(-((x - w[2])/w[3])^2) + w[4]*x
end

Function /d Gauss_Fit_poly (w, x)
	wave /d w
	variable /d x

	return w[0] + w[1]*exp(-((x - w[2])/w[3])^2) + w[4]*x + w[5]*x^2
end

Function /d Gauss_Fit_poly3 (w, x)
	wave /d w
	variable /d x
	
	return w[0] + w[1]*exp(-((x - w[2])/w[3])^2) + w[4]*x + w[5]*x^2 + w[6]*x^3
end


Proc LoadChromsandGo(snum, startinc)
	string snum = StrMakeOrDefault("G_loadNum", "All")
	variable startinc = 0 
	prompt snum, "Number of chroms to load", popup, "1;10;100;500;1000;All"
	prompt startinc, "Start on file number"
	
	silent 1;
	G_loadNum = snum
	variable /d num, inc = startinc
	variable molinc, numMols = NumElementsInList(G_molList, ";")
	if (cmpstr(snum, "All")==0)
		num = 1000000
	else
		num = str2num(snum) + startinc
	endif
	
	Pathinfo chroms
	if (V_flag == 0)
		NewPath /M="Point me to the folder with chroms." chroms
	endif
	
	string fileNameStr, JulianDate, chromLst, mol
	do
		fileNameStr = IndexedFile(chroms, inc, ".itx")
		if (cmpstr(fileNameStr,"") == 0)
			print "Last file!  Done!!!"
			break
		endif
		LoadWave/Q/T/O/P=chroms fileNameStr
		Killwaves /Z chrom1, chrom2, chrom3, chrom4
		JulianDate = fileNameStr[0,3] + fileNameStr[7,9] + "." + fileNameStr[10,13]
		G_JulianDec = JulianDate2Dec(JulianDate)
		chromLst = wavelist("chr*_0000*", ";", "")
		rename $GetStrFromList(chromLst, 0, ";") chrom1
		rename $GetStrFromList(chromLst, 1, ";") chrom2
		rename $GetStrFromList(chromLst, 2, ";") chrom3
		rename $GetStrFromList(chromLst, 3, ";") chrom4
		G_chromNote = Note(chrom1)
		print "inc = " + num2str(inc) + "   Integrating: " + fileNameStr
		molinc = 0
		Do
			mol = GetStrFromList(G_molList, molinc, ";")
			Intg(mol, fileNameStr,1)
			molinc += 1
		while (molinc < numMols)
		inc += 1		
	while (inc < num)
	
end

Proc QuickFit(chrom)
	string chrom = StrMakeOrDefault("G_chrom", "chrom1")
	prompt chrom, "Chromatogram", popup, "chrom1;chrom2;chrom3;chrom4;"
	silent 1
	
	G_chrom = chrom 
	
	QuickFitFUNCT($chrom, 1)
end
	 

function QuickFitFUNCT(wv, disp)
	wave wv
	variable disp

	wave fit = $"fit"
	variable lft, rtg

	if (xcsr(A) > xcsr(B))
		lft = xcsr(B); rtg = xcsr(A)
		if (disp)
			make /o/n=(pcsr(A)-pcsr(B)) fit = NaN
			SetScale/I x xcsr(B),xcsr(A),"", fit
		endif
	else
		lft = xcsr(A); rtg = xcsr(B)
		if (disp)
			make /o/n=(pcsr(B)-pcsr(A)) fit = NaN
			SetScale/I x xcsr(A),xcsr(B),"", fit
		endif
	endif
	
	CurveFit /Q gauss wv(lft,rtg)
	
	duplicate /o W_coef coefs
	InsertPoints 4,3, coefs
	coefs[4] = 0
	coefs[5] = 0
	coefs[6] = 0		
	
	FuncFit/Q/H="0010000" Gauss_Fit_poly3 coefs wv(lft,rtg)

	if (disp)
		fit = Gauss_Fit_poly3(coefs,x)
		CheckDisplayed fit
		if (V_flag == 0)	
			appendtograph fit
			ModifyGraph rgb(fit)=(1,4,52428)
		endif
	endif
	
end

Proc IntgrateCurrent(mol, disp)
	string mol = StrMakeOrDefault("G_mol", "")
	variable disp = NumMakeOrDefault("G_disp",0)
	prompt mol, "Integrate which molecule", popup G_molList
	prompt disp, "Display the intgration", popup, "No;Yes"
	
	silent 1
	G_mol = mol
	G_disp = disp
	
	if (disp)
		string DBdate = mol + "_DBdate"
		string chan = mol + "_chan"
		string x1 = mol + "_x1"
		string x2 = mol + "_x2" 
		variable index = IntParamsIndex($DBdate)
		string chrom = "chrom" + num2str($chan[index])
		string win = "Chromatogram_" + num2str($chan[index])

		if (disp)
			make /o/n=(x2pnt($chrom,$x2[index])-x2pnt($chrom,$x1[index])) fit = NaN
			SetScale/I x $x1[index],$x2[index],"", fit
		endif

		DoWindow /K $win
		Display $chrom
		DoWindow /C $win
	endif		
	
	Intg(mol, "", 0)
	
	if (disp)
		fit = Gauss_Fit_poly3(coefs,x)
		CheckDisplayed fit
		if (V_flag == 0)	
			appendtograph fit
			ModifyGraph rgb(fit)=(1,4,52428)
		endif
	endif

	
end

Function Intg (mol, chromfile, toDB)
	string mol, chromfile
	variable toDB

	NVAR V_FitError = V_FitError
	NVAR G_JulianDec = G_JulianDec
	SVAR G_chromNote = G_chromNote
	
	// Result waves
	wave /D day = $(mol + "_date")
	wave hght = $(mol + "_hght")
	wave wdth = $(mol + "_wdth")
	wave ret = $(mol + "_ret")
	wave selpos = $(mol + "_selpos")
	wave press = $(mol + "_InjPress")
	wave temp = $(mol + "_InjTemp")
	
	// DB waves
	wave DBdate = $(mol + "_DBdate")
	wave chan = $(mol + "_chan")
	wave x1 = $(mol + "_x1") 
	wave x2 = $(mol + "_x2") 
	
	variable index = IntParamsIndex(DBdate)
	if (index == -1)
		print "ERROR:  Can't find IntparamsIndex for " + mol
	endif
		
	variable DataLen = numpnts(day)
	wave chrom = $("chrom" + num2str(chan[index]))
		
	CurveFit /Q gauss chrom(x1[index],x2[index])
	
	duplicate /o W_coef coefs
	InsertPoints 4,3, coefs
	coefs[4] = 0
	coefs[5] = 0
	coefs[6] = 0
	
	V_FitError = 0
	FuncFit /Q/H="0010000" Gauss_Fit_poly3 coefs chrom(x1,x2)
	
	if (V_FitError != 0)
		print "Integration ERROR:  Could not fit " + mol + " on chrom: " + chromfile
	else
		if (toDB)
			insertpoints DataLen, 1, day, hght, ret, wdth, selpos, press, temp
			day[DataLen] = G_JulianDec
			hght[DataLen] = coefs[1]
			ret[DataLen] = coefs[2]
			wdth[DataLen] = coefs[3]
			selpos[DataLen] = str2num(GetStrFromList(G_chromNote, 4, ";"))
			press[DataLen] = str2num(GetStrFromList(G_chromNote, 6, ";"))
			temp[DataLen] = str2num(GetStrFromList(G_chromNote, 5, ";"))
		endif
	endif
	
end
	
function/d JulianDate2Dec(JulianDateStr)
	string JulianDateStr
	
	variable YYYY = str2num(JulianDateStr[0,3])
	variable JJJ = str2num(JulianDateStr[4,6])
	variable MM, DD, DDD = 0, DDDold
	variable HH = str2num(JulianDateStr[8,9])
	variable MN = str2num(JulianDateStr[10,11])
	variable days = 365, inc = 1
	string months = "1;31;59;90;120;151;181;212;243;274;304;335;365"
	
	if (mod(YYYY,4) == 0)
		days += 1
		months = "1;31;60;91;121;152;182;213;244;275;305;336;366"
	endif
	
	do
		DDDold = DDD
		DDD = str2num(GetStrFromList(months, inc, ";"))
		if (DDD == JJJ)
			MM = inc + 1
			DD = 1
			break
		endif
		if (DDD > JJJ)
			MM = inc
			DD = JJJ - DDDold
			break
		endif
		inc += 1
	while (inc <= 13)
	
//	print YYYY, MM, DD, HH, MN, DDD, JJJ, DDDold, inc
	return date2secs(YYYY, MM, DD) + HH*60*60 + MN*60
	
end

function/d Date2Dec(DateStr)
	string DateStr
	
	variable YYYY = str2num(DateStr[0,3])
	variable MM = str2num(DateStr[4,5])
	variable DD = str2num(DateStr[6,7])
	variable HH = str2num(DateStr[9,10])
	variable MN = str2num(DateStr[11,12])
	variable days = 365
	
	if (mod(YYYY,4) == 0)
		days += 1
	endif
	
//	print YYYY, MM, DD, HH, MN
//	return YYYY + ((date2secs(YYYY, MM, DD) + HH*60*60 + MN*60) - date2secs(YYYY, 1, 1)) / (days*24*60*60)
	return date2secs(YYYY, MM, DD) + HH*60*60 + MN*60
	
end

function IntParamsIndex(DBdate)
	wave /t DBdate

	NVAR JulianDec = G_JulianDec
	variable num = numpnts(DBdate)
	if (num == 1)
		return num-1
	endif

	variable inc = 0
	variable /d dateDecOld, dateDec = 0

	do
		dateDecOld = dateDec
		dateDec = Date2Dec(DBdate[inc])
		if ((dateDecOld) >= JulianDec) * (dateDec < JulianDec))
			return inc
		endif
		inc += 1
	while (inc < num)
	
	return -1

end

Proc AddNewMol(mol, chan)
	string mol
	variable chan = 1
	Prompt mol, "New molecule"
	Prompt chan, "Channel the molecule is on", popup, "1;2;3;4"
	
	silent 1
	G_mol = mol
	
	string day = mol + "_DBdate"
	string chn = mol + "_chan"
	string x1 = mol + "_x1"
	string x2 = mol + "_x2"
	
	string day2 = mol + "_date"
	string hght = mol + "_hght"
	string wdth = mol + "_wdth"
	string ret = mol + "_ret"
	string selpos = mol + "_selpos"
	string press = mol + "_InjPress"
	string temp = mol + "_InjTemp"
	
	string win = mol + "_Int_Params"
	
	if (exists(day) == 1)
		Edit/W=(5,42,493,335) $day,$x1,$x2, $chn
		ModifyTable width($day)=122
		DoWindow /C $win
		abort "Molecule is already in data base"
	endif
	
	StrMakeOrDefault("G_molList", "")
	G_molList = AddElementToList(mol, G_molList, ";")
	G_molList = SortList(G_molList, 0, 0, ";")
	
	make /n=1 $chn = chan, $x1 = 100, $x2 = 200
	make /n=1 /t $day = "19990101.0000"
	make /n=0 $hght, $wdth, $ret, $selpos, $press, $temp
	make /n=0/d $day2
	SetScale d 0,0,"dat", $day2

	Edit/W=(5,42,493,335) $day,$x1,$x2, $chn
	ModifyTable width($day)=122
	DoWindow /C $win

end	
	
Proc VoidData(mol)
	string mol = G_mol
	Prompt mol, "DELETE Integration results for which molecule", popup, G_molList + "All Mols"
	
	silent 1; PauseUpdate
	
	if (cmpstr(mol, "All Mols") == 0)
		variable num = NumElementsInList(G_molList, ";"), inc
		do
			mol = GetStrFromList(G_molList, inc, ";")
			VoidData(mol)
			inc += 1
		while (inc < num)
	endif	
	
	G_mol = mol
	
	string day = mol + "_date"
	string hght = mol + "_hght"
	string wdth = mol + "_wdth"
	string ret = mol + "_ret"
	string selpos = mol + "_selpos"
	string press = mol + "_InjPress"
	string temp = mol + "_InjTemp"

	make /o/n=0 $hght, $wdth, $ret, $selpos, $press, $temp
	make /o/n=0/d $day
	SetScale d 0,0,"dat", $day
	
end

	
Proc Cursors2DB(mol)
	string mol = StrMakeOrDefault("G_mol", "")
	prompt mol, "Update which molecule database", popup G_molList

	silent 1
	G_mol = mol
	
	string x1 = mol + "_x1"
	string x2 = mol + "_x2"
	variable len = numpnts($x1)-1
	
	if (xcsr(A) > xcsr(B))
		$x1[len] = xcsr(B); $x2[len] = xcsr(A)
	else
		$x1[len] = xcsr(A); $x2[len] = xcsr(B)
	endif
	
end

Proc DataTable(mol)
	string mol = StrMakeOrDefault("G_mol", "")
	prompt mol, "Table of results for which molecule?", popup G_molList

	PauseUpdate; Silent 1		// building window...
	G_mol = mol
	
	string day = mol + "_date"
	string hght = mol + "_hght"
	string wdth = mol + "_wdth"
	string ret = mol + "_ret"
	string selpos = mol + "_selpos"
	string press = mol + "_InjPress"
	string temp = mol + "_InjTemp"
	
	string win = mol + "_Int_Results"
	
	DoWindow /K $win
	Edit/W=(242,73,958,686) $day,$hght,$wdth,$ret,$selpos,$press,$temp
	ModifyTable sigDigits($day)=12,width($day)=148,width($selpos)=60
	DoWindow /C $win
EndMacro

Proc DataPlot(mol, attrib) 
	string mol = StrMakeOrDefault("G_mol", "")
	string attrib = StrMakeOrDefault("G_attrib", "hght")
	prompt mol, "Plot which molecule?", popup G_molList
	prompt attrib, "Attribute", popup, "hght;wdth;selpos;ret;injPress;injTemp"

	PauseUpdate; Silent 1		// building window...
	G_mol = mol
	G_attrib = attrib
	
	string yyy = mol + "_" + attrib
	string day = mol + "_date"
	string selpos = mol + "_selpos"
	string win = mol + "_dataPlot"
	
	DoWindow /K $win
	Display /W=(32,69,1008,361) $yyy vs $day
	DoWindow /C $win
	ModifyGraph mode=3
	ModifyGraph rgb=(0,0,0)
	ModifyGraph msize=4
	ModifyGraph zColor($yyy)={$selpos,*,*,BlueRedGreen}
	ModifyGraph textMarker($yyy)={$selpos,"default",0,0,5,0.00,0.00}
	ModifyGraph dateInfo(bottom)={0,0,0}
	
	Label left "\\Z14" +mol + " " + attrib
	Label bottom "\\Z14Date"
	ModifyGraph grid=1,mirror=2
	
EndMacro
