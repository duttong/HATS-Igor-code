#pragma rtGlobals=1		// Use modern global access method.

Proc LoadCal3results(mol)
	string mol = G_mol
	prompt mol, "Which molecule", popup, G_loadMol

	Silent 1; PauseUpdate
	SetDataFolder root:
	
	MakeCal3strucs(mol)
	LoadCal3results_func(mol)
	ProcessLoadResults(mol)
	FlagFirst3injs(mol)
	Cal3plot(mol)
	
	SetDataFolder root:
	
end

function MakeCal3strucs(mol)
	string mol

	NewPath /O/Q cal3 "gc:cats_results:cal3:"
	
	string DF = "root:cal3_" + mol
	NewDataFolder /O/S $DF
	
	// check for flag wave
	if (exists("flagged") != 1 )
		make /n=0/d flagged
	endif

end

function LoadCal3results_func(mol)
	string mol

	SVAR site = root:G_site3
	string file = "a_" + lowerStr(site) + mol
	string DF = "root:cal3_" + mol

	// load SX data from Standards Tables experiment
	SetDataFolder root:
	loadStandardsFile()
	string stdfile = "Macintosh HD:user:geoff:data:CATS:CATS Standards Tables.pxp"
	string SX = site + "_SX"
	string SXday = site + "_SXdates"
	LoadData /q/o /j=SX stdfile
	LoadData /q/o /j=SXday stdfile
	
	string colinfo = ""
	colinfo += "C=1,F=-2,N=datestr;"
	colinfo += "C=1,F=-2,N=hourstr;"
	colinfo += "C=1,F=0,T=2,N=ssv;"
	colinfo += "C=1,F=0,T=2,N=ret;"
	colinfo += "C=1,F=0,T=2,N=wid;"
	colinfo += "C=1,F=0,T=2,N=hgt;"
	colinfo += "C=1,F=0,T=2,N=are;"
	
	SetDataFolder $DF
	LoadWave/B=colinfo /A/O/J/D/Q/P=cal3/K=0 file
		
end

function ProcessLoadResults(mol)
	string mol
	
	wave /t datestr
	wave /t hourstr
	wave ssv, hgt
	string tstr = "cal3_date"

	make /o/n=(numpnts(datestr)) YYYY, MM, DD, HH, MN
	make /o/d/n=(numpnts(datestr)) $tstr
	wave T = $tstr
	SetScale d 0,0,"dat", T
	
	YYYY = str2num((datestr)[0,3])	
	MM = str2num((datestr)[4,5])
	DD = str2num((datestr)[6,7])
	HH = str2num((hourstr)[0,2])
	MN = str2num((hourstr)[3,4])
	T = date2secs(YYYY, MM, DD) + HH*60*60 + MN*60
	
	Killwaves /Z YYYY, MM, DD, HH, MN, datestr, hourstr
	
	// split ports for Hight only!!!
	make /o/n=(numpnts(T)) cal1, cal2, cal3
	cal1 = selectnumber(ssv==2, NaN, hgt)
	cal2 = selectnumber(ssv==6, NaN, hgt)
	cal3 = selectnumber(ssv==0, NaN, hgt)
	
	FlagCal3Data(mol)
	
end

// uses the stored flag data from "flagged" wave to flag recently loaded data
function FlagCal3Data(mol)
	string mol

	string DF = "root:cal3_" + mol
	SetDataFolder $DF

	wave cal1, cal2, cal3, flagged
	wave /d cal3_date
	variable i, loc

	make/o/n=(numpnts(cal3)) flag = 1
	
	for (i=0;i<numpnts(flagged);i+=1)
		loc = BinarySearch(cal3_date, flagged[i])
		if ( loc >= 0 )
			flag[loc] = NaN
		endif
	endfor
		
	cal1*= flag
	cal2 *= flag
	cal3 *= flag
	
	SetDataFolder "root:"
	
end

proc FlagCalData () : GraphMarquee

	string mol

	GetMarquee left, bottom
	
	// checks if cal3 data is on the graph
	if ( StringMatch(S_marqueeWin, "*_cal3*") )
		mol = S_marqueeWin[0,strsearch(S_marqueeWin,"_",0)-1]
		G_mol = mol
		FlagInsideCalBox_func (mol)
	endif
	
end

function FlagInsideCalBox_func(mol)
	string mol

	string DF = "root:cal3_" + mol
	SetDataFolder $DF

	wave flag, flagged
	wave cal1, cal2, cal3
	variable i

	GetMarquee  left, bottom	
	
	if ( WaveExists(XWaveRefFromTrace("", "cal1")) )
		wave wvX = XWaveRefFromTrace("", "cal1")
		Extract /INDX/O cal1, JunkY, ( (wvX > V_left) && (wvX < V_right) && (cal1 < V_top) && (cal1 > V_bottom) )
	endif
	for(i = 0; i<numpnts(JunkY); i+=1)
		InsertPoints numpnts(flagged), 1, flagged
		flagged[numpnts(flagged)-1] = wvX[JunkY[i]]
		flag[JunkY[i]] = NaN
	endfor
	
	if ( WaveExists(XWaveRefFromTrace("", "cal2")) )
		wave wvX = XWaveRefFromTrace("", "cal2")
		Extract /INDX/O cal2, JunkY, ( (wvX > V_left) && (wvX < V_right) && (cal2 < V_top) && (cal2 > V_bottom) )
	endif
	for(i = 0; i<numpnts(JunkY); i+=1)
		InsertPoints numpnts(flagged), 1, flagged
		flagged[numpnts(flagged)-1] = wvX[JunkY[i]]
		flag[JunkY[i]] = NaN
	endfor

	if ( WaveExists(XWaveRefFromTrace("", "cal3")) )
		wave wvX = XWaveRefFromTrace("", "cal3")
		Extract /INDX/O cal3, JunkY, ( (wvX > V_left) && (wvX < V_right) && (cal3 < V_top) && (cal3 > V_bottom) )
	endif
	for(i = 0; i<numpnts(JunkY); i+=1)
		InsertPoints numpnts(flagged), 1, flagged
		flagged[numpnts(flagged)-1] = wvX[JunkY[i]]
		flag[JunkY[i]] = NaN
	endfor
	
	cal1 *= flag
	cal2 *= flag
	cal3 *= flag
	
	Killwaves JunkY
	
	SetDataFolder "root:"
	
end

function FlagFirst3injs(mol)
	string mol
	
	SVAR site = root:G_site3
	
	String DF = "root:cal3_" + mol
	SetDataFolder $DF
	
	wave cal1, cal2, cal3
	wave flag, flagged
	wave /d cal3_date
	variable p1, p2, days = 60*60*24*2
	
	p1 = 0
	do
		p2 = BinarySearch(cal3_date, cal3_date[p1] + days)
		if (p2 == -2 )
			p2 = numpnts(cal3_date)-1
		endif
		flag[p1] = NaN
		flag[p1+1] = NaN
		flag[p1+2] = NaN
		p1 = p2 + 1
	while(p2 < numpnts(cal3_date)-1) 
	
	cal1 *= flag
	cal2 *= flag
	cal3 *= flag
	
	SetDataFolder root:

end



Proc Cal3plot(mol): Graph
	string mol=StrMakeOrDefault("root:G_mol", "F11")
	prompt mol, "Molecule", popup, root:G_loadMol
	
	root:G_mol = mol
	
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	String DF = "root:cal3_" + mol
	String win = mol + "_cal3height"
	
	SetDataFolder $DF
	DoWindow/K $win
	Display /W=(18,56,1046,315) cal3,cal2,cal1 vs cal3_date
	DoWindow/C $win
	SetDataFolder fldrSav0
	ModifyGraph mode=3
	ModifyGraph marker(cal3)=8,marker(cal2)=19,marker(cal1)=19
	ModifyGraph rgb(cal3)=(0,0,0),rgb(cal2)=(3,52428,1)
	ModifyGraph msize=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	Legend/N=text0/J/X=91.55/Y=7.77 "\\s(cal1) cal1\r\\s(cal2) cal2\r\\s(cal3) cal3"
	Label left "Response"
	Label bottom "Date"
EndMacro

Proc CompareCals(mol)
	string mol = G_mol
	prompt mol, "Which molecule", popup, G_loadMol

	Silent 1; PauseUpdate
	SetDataFolder root:

	CompareCals_func(mol)
	Plot_Cal3Est(mol)
	Plot_Cal3diff(mol)

	SetDataFolder root:
end

function CompareCals_func(mol)
	string mol
	
	SVAR site = root:G_site3
	
	String DF = "root:cal3_" + mol
	SetDataFolder $DF
	
	wave hgt, cal1, cal2, cal3
	wave /d cal3_date
	variable i, p1, p2, days = 60*60*24*2
	variable MR1, MR2, MR3, lb, hb, inc
	
	make /o/n=(numpnts(cal1)/10) Cal1Est=nan,  Cal1Est_sd=nan, Cal2Est=nan, Cal2Est_sd=nan, CalEst_date=nan
	make /o/n=(numpnts(cal1)/10) Cal3Est=nan,  Cal3Est_sd=nan
	make /o/n=(numpnts(cal1)/10) Cal1diff=nan, Cal2diff=nan, Cal3diff=nan
	SetScale d 0,0,"dat", CalEst_date

	p1 = 0
	i = 0
	do
		p2 = BinarySearch(cal3_date, cal3_date[p1] + days)
		if (p2 == -2 )
			p2 = numpnts(cal3_date)-1
		endif
		make /d/o/n=(p2-p1+1) cal1work, cal2work, cal3work, cal3date
		make /d/o/n=(p2-p1+1) cal1estWcal3, cal2estWcal3, cal3estW 
		cal1work = cal1[p1+p]
		cal2work = cal2[p1+p]
		cal3work = cal3[p1+p]
		cal3date = cal3_date[p1+p]
		
		// assigned mixing ratios to each cal tank
		MR1 = GetALMconc(mol, ReturnTank(cal3date[0], 0))
		MR2 = GetALMconc(mol, ReturnTank(cal3date[0], 1))
		MR3 = GetALMconc(mol, ReturnSXTank(cal3date[0]))
		
		// calc mixing ratio of cal1 and cal3 using cal3
		cal1estWcal3 = MR3 * 2 * cal1work[p] / (cal3work[p-2]+cal3work[p+1])
		cal2estWcal3 = MR3 * 2 * cal2work[p] / (cal3work[p-1]+cal3work[p+2])

		// estimate cal3 using cal1 and/or cal2
		string meth = LookUpCalMethod(cal3date[0], mol)
		strswitch ( meth ) 
			case "cal1":
				cal3estW = MR1 * 2 * cal3work[p] / (cal1work[p+2] + cal1work[p-1])
				break
			case "cal2":
				cal3estW = MR2 * 2 * cal3work[p] / (cal2work[p+1] + cal2work[p-2])
				break
			case "cal12str":
			case "cal12":
				for(inc=0; inc<numpnts(cal3work); inc+=1)
					if (numtype(cal3work[inc]) == 2)
						cal3estW[inc] = NaN
					else
						lb = (cal1work[inc-1] + cal1work[inc+2]) / 2
						hb = (cal2work[inc-2] + cal2work[inc+1]) / 2
						cal3estW[inc] = (MR1-MR2)/(lb-hb) * cal3work[inc] + (MR2*lb - MR1*hb)/(lb-hb)
					endif
				endfor
				break
			default:
				cal3estW = nan
				break
		endswitch

		// do some averaging
		Wavestats /Q cal3date
		CalEst_date[i] = V_avg
		
		Wavestats /Q cal1estWcal3
		Cal1Est[i] = V_avg
		Cal1Est_sd[i] = V_sdev
		Cal1Diff[i] = V_avg - MR1
		
		Wavestats /Q cal2estWcal3
		Cal2Est[i] = V_avg
		Cal2Est_sd[i] = V_sdev
		Cal2Diff[i] = V_avg - MR2
		
		Wavestats /Q cal3estW
		Cal3Est[i] = V_avg
		Cal3Est_sd[i] = V_sdev
		Cal3Diff[i] = V_avg - MR3
				
		p1 = p2 + 1
		i += 1
	while(p2 < numpnts(cal3_date)-1) 
	
	// cleanup
	DeletePoints i, 1000, Cal1Est, Cal1Est_sd, Cal2Est, Cal2Est_sd,  Cal3Est, Cal3Est_sd, CalEst_date, Cal1diff, Cal2diff, Cal3diff
	killwaves cal1work, cal2work, cal3work, cal3date, cal1estWcal3, cal2estWcal3, cal3estW
//	edit cal1work, cal2work, cal3work, cal3date, cal1estWcal3, cal2estWcal3, cal3estW

	// make cal3 value line
	make /o/n=(numpnts(CalEst_date)) cal3vals = GetALMconc(mol, ReturnSXTank(CalEst_date))
	
	Cal3Diff = Cal3Diff/cal3vals * 100
	
	SetDataFolder root:

end


// function returns SX tank number at a certain time
function/t ReturnSXTank(secs)
	variable /d secs

	SVAR site = root:G_site3

	wave /t ALMdates = $"root:" + site + "_SXdates"
	wave /t std = $"root:" + site + "_SX"

	make /d/o/n=(numpnts(ALMdates)) ALMdatesSECS = date_return(ALMdates)
		
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

	Killwaves ALMdatesSECS
	
	return tank
	
end

Proc Plot_Cal3Est(mol) : Graph
	string mol=StrMakeOrDefault("root:G_mol", "F11")
	prompt mol, "Molecule", popup, root:G_loadMol

	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	String DF = ":cal3_" + mol
	String win = mol + "_calest"
	string hstd = mol + "_hstd_conc"
	string lstd = mol + "_lstd_conc"
	string day = mol + "_date"
		
	SetDataFolder $DF
	DoWindow/K $win	
	Display /W=(18,339,1048,583) Cal1Est,Cal2Est vs CalEst_date
	DoWindow/C $win	
	AppendToGraph $"root:"+hstd, $"root:"+lstd vs $"root:"+day
	SetDataFolder fldrSav0
	ModifyGraph mode(Cal2Est)=3,mode(Cal1Est)=3
	ModifyGraph marker(Cal2Est)=19,marker(Cal1Est)=19
	ModifyGraph lSize($hstd)=2,lSize($lstd)=2
	ModifyGraph rgb(Cal2Est)=(2,39321,1),rgb(Cal1Est)=(52428,1,1),rgb($hstd)=(32769,65535,32768)
	ModifyGraph rgb($lstd)=(65535,16385,16385)
	ModifyGraph msize(Cal2Est)=1,msize(Cal1Est)=1
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left "Mixing Ratio"
	Label bottom "Date"
	SetAxis/A/N=1 left

	SetDataFolder $DF
	
	AppendToGraph cal3vals vs CalEst_date
	ModifyGraph mode(cal3vals)=6
	ModifyGraph lstyle(cal3vals)=1,rgb(cal3vals)=(0,0,65535)
	
	SetAxis bottom CalEst_date[0],CalEst_date[numpnts(CalEst_date)-1]

	ErrorBars Cal2Est Y,wave=(Cal2Est_sd,Cal2Est_sd)
	ErrorBars Cal1Est Y,wave=(Cal1Est_sd,Cal1Est_sd)
	Legend
//	Legend/N=text0/J "\\s(Cal1Est) Cal1Est\r\\s(Cal2Est) Cal2Est\r\\s(MC_lstd_conc) MC_lstd_conc\r\\s(MC_hstd_conc) MC_hstd_conc"
	SetDataFolder root:
EndMacro

Proc Plot_Cal3diff(mol) : Graph
	string mol=StrMakeOrDefault("root:G_mol", "F11")
	prompt mol, "Molecule", popup, root:G_loadMol

	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	String DF = ":cal3_" + mol
	String win = mol + "_cal3est"

	SetDataFolder $DF
	DoWindow /k $win
	Display /W=(19,606,1049,850) cal3vals vs CalEst_date
	DoWindow /C $win
	
	AppendToGraph Cal3Est vs CalEst_date
	AppendToGraph/L=diffs Cal3diff vs CalEst_date
	SetDataFolder fldrSav0
	ModifyGraph mode(Cal3Est)=3,mode(Cal3diff)=3
	ModifyGraph marker(Cal3Est)=19,marker(Cal3diff)=19
	ModifyGraph mode(cal3vals)=6
	ModifyGraph lSize(cal3vals)=2
	ModifyGraph lStyle(cal3vals)=1
	ModifyGraph rgb(cal3vals)=(0,0,65535),rgb(Cal3Est)=(0,0,65535)
	ModifyGraph msize(Cal3Est)=1,msize(Cal3diff)=2
	ModifyGraph grid(diffs)=2
	ModifyGraph lblPos(left)=56,lblPos(diffs)=51
	ModifyGraph lblLatPos(diffs)=-3
	ModifyGraph freePos(diffs)=0
	ModifyGraph axisEnab(left)={0,0.48}
	ModifyGraph axisEnab(diffs)={0.53,1}
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left "Mixing Ratio"
	Label bottom "Date"
	Label diffs "% Diff"
	SetAxis/A/N=1 left
	
	SetDataFolder $DF
	SetAxis bottom CalEst_date[0],CalEst_date[numpnts(CalEst_date)-1]
	SetAxis/A/E=2 diffs
	ErrorBars Cal3Est Y,wave=(Cal3Est_sd,Cal3Est_sd)
	Legend/N=text0/J/X=1.06/Y=-5.24 "\\s(cal3vals) cal3vals\r\\s(Cal3Est) Cal3Est\r\\s(Cal3diff) Cal3diff"
	
	SetDataFolder root:
	
EndMacro

Window Layout_Cal3( mol ) : Layout
	string mol=StrMakeOrDefault("root:G_mol", "F11")
	prompt mol, "Molecule", popup, root:G_loadMol

	PauseUpdate; Silent 1		// building window...
	
	String win1 = mol + "_cal3height"
	String win2 = mol + "_calest"
	String win3 = mol + "_cal3est"
	String Com

	NewLayout/P=Landscape
	AppendLayoutObject /R=(19,21,751,211) graph $win1
	AppendLayoutObject /R=(19,211,751,389) graph $win2
	AppendLayoutObject /R=(19,389,751,594) graph $win3

EndMacro
