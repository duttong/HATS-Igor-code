#pragma rtGlobals=1		// Use modern global access method.
#include <concatenate waves>

Constant MAXCHROMS = 5000		// maximum number of chromatograms (of a single channel) loaded.


Function BeforeFileOpenHook(refNum, fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr, fileKind)
	Variable refNum, fileKind
	String fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr
	
	variable len = strlen(fileNameStr)
	string com
	wave /t config = config

	if ((cmpstr(fileNameStr[len-3,len], "itx")==0) * (fileKind == 5))

		if (( cmpstr(fileNameStr[0,1], "GC") == 0 ) || ( cmpstr(fileNameStr[0,2], "MSD") == 0 ))
			LoadChroms(fileNameStr, pathNameStr)
		endif
	
		return 1
	endif
	
end


// use this function to load all chroms (.itx) files from a path (folder).
Function ChromLoader()

	InstrumentSpecficCalls()
	
	PathInfo ChromFiles
	if ( V_flag == 0 )
		NewPath /Q/M="Path to the chromatograms (.itx files) to load." ChromFiles
		PathInfo ChromFiles
	endif
	if ( V_flag == 0 )
		abort
	endif
	
	string chrom
	variable count, inc
	
	do
		chrom = IndexedFile(ChromFiles, inc, ".itx")
		if ( strlen(chrom) == 0 )
			break
		endif
		inc += 1
		count += LoadChroms(chrom, "ChromFiles")
	while (1)
	
	Print count, "chromatogram files loaded."
	
	KillPath ChromFiles
	
end

// Use this proceedure to customize chromatogram maniuplation
// such as smoothing or shifting.
function PrepareChroms()

	SetDataFolder root:
	
	NVAR chans = root:V_chans
	if (exists("prepConfig") != 1)
		abort "You need to set up chromatogram preperation parameters with \"Prepare Chroms Configuration\" macro prior to running this procedure."
	endif
	
	wave /t prep = prepConfig
	wave /t smo = smoothConf
	variable concat, shift, ch, iter, algo

	CreateDBwaves()			// also calls CreateChromAS()
	
	print "Loading Wave Notes"
	LoadWaveNotes()
	
	print "Trimming DB waves"
	TrimDBwaves()
	
	DetermineFlightDate()		// sets S_date
	
	print "Fixing Tsecs"
	FixupTsecs()
	MakeTsecs1904()
	
	print "Chrom Manipulation"
	// chrom manipulation such as concatenating and shifting
	for(ch=1; ch<=chans; ch+= 1)
		concat = str2num(StringFromList(0,prep[ch-1],"/"))
		shift =  str2num(StringFromList(1,prep[ch-1],"/"))
		if ( shift > 0 )
			print "ShiftTheChromsFUNCT (", returnMINchromNum(ch), ",", returnMAXchromNum(ch), ",", shift, ",", 1, ",", ch,  ")"
			ShiftTheChromsFUNCT (returnMINchromNum(ch), returnMAXchromNum(ch), shift, 1, ch)
		endif
		if ( concat == 2 )
			print "ConcatChromsFUNCT(", returnMINchromNum(ch), ",", ch, ")"
			ConcatChromsFUNCT(returnMINchromNum(ch), ch)
		elseif ( concat < 1 )
			// print "SplitChromsFUNCT(", returnMINchromNum(ch), ",", ch, ")"
			// SplitChromsFUNCT(returnMINchromNum(ch), ch)
		endif
	endfor
	
	
	// smooth chroms in each channel
	for(ch=1; ch<=chans; ch+= 1)
		algo = str2num(StringFromList(0, smo[ch-1], "/"))
		iter = str2num(StringFromList(1,smo[ch-1],"/"))
		if ( iter > 0 )
			Switch (algo)
				case 1:	// binomial (gausian)  -- iter (1-1000)
					printf "SMOOTH ch=%d with Binomial Smooth Iter=%d\r", ch, iter
					SmoothChromsFUNCT(ch, algo, iter)
					break;
				case 2:	// box (odd iter 1-1000)
					if ((iter < 1) || (iter > 1001) || (Mod (iter, 2)==0))
						iter = 15
						print "Bad iter for box smooth!!!  Setting to 15"
					endif
					printf "SMOOTH ch=%d with Box Smooth Iter=%d\r", ch, iter
					SmoothChromsFUNCT(ch, algo, iter)
					break;
				case 3:	// 2nd Order Savitzky-Golay
					if ((iter < 5) || (iter > 25) || (Mod (iter, 2)==0))
						iter = 15
						print "Bad iter for 2nd Order Savitzky-Golay smooth!!!  Setting to 15"
					endif
					printf "SMOOTH ch=%d with 2nd Order Savitzky-Golay Smooth Iter=%d\r", ch, iter
					SmoothChromsFUNCT(ch, algo, iter)
					break;
				case 4:	// 2nd Order Savitzky-Golay
					if ((iter < 7) || (iter > 25) || (Mod (iter, 2)==0))
						iter = 25
						print "Bad iter for 4th Order Savitzky-Golay smooth!!!  Setting to 25"
					endif
					printf "SMOOTH ch=%d with 4th Order Savitzky-Golay Smooth Iter=%d\r", ch, iter
					SmoothChromsFUNCT(ch, algo, iter)
					break;
			endswitch
		endif
	endfor
	
end


// creates database waves
function CreateDBwaves()

	SetDataFolder root:
	
	NVAR chans = root:V_chans

	killvariables /Z V_loaded					// not needed
	
	// make database waves
	make /o/n=(MAXCHROMS) selpos = nan				// ssv position
	make /o/d/n=(MAXCHROMS) tsecs = nan			// injection time
	make /o/n=(MAXCHROMS,chans) inj_p = nan		// injection pressure
	make /o/n=(MAXCHROMS,chans) inj_t = nan		// injection temperature
	
	CreateChromAS()									// creates chromatogram list waves (active sets)

end

// Trims database waves to the number or loaded chromatograms
function TrimDBwaves()

	SetDataFolder root:

	wave selpos = selpos
	wave tsecs = tsecs
	wave injP = inj_p
	wave injT = inj_t
	wave AS = root:AS:CH1_All
		
	deletepoints numpnts(AS),MAXCHROMS, selpos, tsecs, injP, injT
	
	// looks for special PAN selpos wave
	if ( WaveExists($"selposPAN") )
		wave selposPAN = selposPAN
		deletepoints numpnts(AS),MAXCHROMS, selposPAN
		duplicate /o selpos, selposGC
	endif

end


 Function FixupTsecs()
	variable baseday = -1, index, lastline
	
	wave Tsecs = Tsecs
	
	index = 0
	lastline = numpnts(Tsecs)

	if (baseday < 0)
		index = 0
		baseday = -1
		
		do
			if (Tsecs[index] > baseday)
				baseday = Tsecs[index]
			else
				if (baseday > 0)
					if (Tsecs[index] > 0)
						Tsecs[index] += 24 * 3600
						baseday = Tsecs[index]
					endif
				endif
			endif
			index += 1
		while (index < lastline)
	endif
	
End 

// makes a tsecs wave using the native Mac time formate, seconds elapsed since 1904
Function MakeTsecs1904()

	SVAR S_date = root:S_date
	wave tsecs = root:tsecs
		
	// make tsecs_1904
	make /d/o/n=(numpnts(tsecs)) tsecs_1904 = NaN
	tsecs_1904 = date2secs(str2num(S_date[0,3]),  str2num(S_date[4,5]),  str2num(S_date[6,7])) + tsecs
	SetScale d 0,0,"dat", tsecs_1904
	print "**** tsecs_1904 wave created. **** "
end

// function looks up the flight date in the chrom note of the first itx file in the "chroms" folder.
// sets global variable S_date to YYYYMMDD
Function DetermineFlightDate()

	SetDataFolder root:chroms
	// updated to use wavelist instead of GetIndexedObjName (210807 GSD)
	string chroms = SortList(WaveList("chr1_*", ";", ""))
	string chrom = StringFromList(0, chroms)
	string theNote = Note($chrom)
	wave /t config = root:config
	SVAR S_date = root:S_date
	
	variable DD =  str2num(StringFromList(1, StringFromList(3, theNote,";" ), "-"))
	variable MM =  str2num(StringFromList(0, StringFromList(3, theNote,";" ), "-"))
	variable YYYY =  str2num(StringFromList(2, StringFromList(3, theNote,";" ), "-"))

	SetDataFolder root:
	
	string /g S_date = "000000"
	sprintf S_date, "%d%02d%02d", YYYY, MM, DD
	config[4] = S_date
	execute "S_date := config[4]"		// set dependance
	Print "Flight date: ", S_date

end


proc SmoothChroms(det, type, iter)
	variable det = V_chans+1, iter=15, type=4
	prompt det, "Channel:", popup, ListNLong(V_chans,";")+"all"
	prompt type, "Smoothing", popup, "Binomial;Box;2nd Order Savitzky-Golay;4th Order Savitzky-Golay"
	prompt iter, "Iterations.  (There are some limitations depending on smoothing type)"
	
	silent 1
	
	SmoothChromsFUNCT(det, type, iter)

end
		
function SmoothChromsFUNCT(det, type, iter)
	variable det, iter, type
	
	string chrom, stype, com, comment
	variable inc, smoothinc, ch

	NVAR V_chans = V_chans
				
	// Check smoothing types
	if (type == 1)  // Binomial Smooth
		stype = " "
		comment = "Binomial"
		if ((iter < 1) || (iter > 1001))
			abort "The iteration field needs to be between 1 and 1001 for binomial smoothing."
		endif
	elseif (type == 2) // Box Smooth
		stype = "/B"
		comment = "Box"
		if ((iter < 1) || (iter > 1001) || (Mod (iter, 2)==0))
			abort "The iteration field needs to be an odd between 1 and 1001 for binomial smoothing."
		endif		
	elseif (type == 3) // 2nd Order Savitzky-Golay
		stype = "/S=2"
		comment = "2nd Order Savitzky-Golay"
		if ((iter < 5) || (iter > 25) || (Mod (iter, 2)==0))
			abort "The iteration field needs to be an odd number between 5 and 25 for 2nd order Savitzky-Golay."
		endif
	elseif (type == 4) //4th Order Savitzky-Golay
		stype = "/S=4"
		comment = "4th Order Savitzky-Golay"
		if ((iter < 7) || (iter > 25) || (Mod (iter, 2)==0))
			abort "The iteration field needs to be an odd number between 7 and 25 for 4th order Savitzky-Golay."
		endif
	endif
	
	SetDataFolder root:chroms
	string TT = time()
	string DD = date()
	
	do
		chrom = GetIndexedObjName(":", 1, inc)
		if (strlen(chrom) == 0)
			break
		endif

		if ((CmpStr(chrom[0,1], "CH") == 0) && (numpnts($chrom) > iter))
			if (( str2num(chrom[3,3]) == det ) || ( det == V_chans+1))
				sprintf com, "Smooth %s %d, %s", stype, iter, chrom
				execute com
				sprintf com, "Smoothed (%s, %d) %s, %s", comment, iter, TT, DD
				Note $chrom, com
				smoothinc += 1
			endif
		endif
		
		inc += 1

	while (1)
	
	print smoothinc, " chromatograms smoothed."
	
	SetDataFolder root:
	
end

proc ShiftTheChroms (strtChrom, endChrom, appPoints, offset, det)
	variable strtChrom=returnMINchromNum(1), endChrom=returnMAXchromNum(1), appPoints=0, offset=8, det=V_currCh
	prompt strtChrom, "First Chromatogram"
	prompt endChrom, "Last Chromatogram"
	prompt appPoints, "Number of points to append from next chrom"
	prompt offset, "Number of points lost"
	prompt det, "Detector", popup, ListNLong(V_chans,";")

	silent 1; pauseupdate
	
	// Don't bother if appPoints is <= 0
	if (appPoints <= 0) 
		return
	endif
	
	variable oldFitOpts
	
	if (exists("V_FitOptions") != 2)
		variable /g V_FitOptions=4
		oldFitOpts = 0
	else
		oldFitOpts = V_FitOptions
	endif
	V_FitOptions = 4
	
	ShiftTheChromsFUNCT (strtChrom, endChrom, appPoints, offset, det)
	
	V_FitOptions = oldFitOpts
end

function ShiftTheChromsFUNCT (strtChrom, endChrom, appPoints, offset, det)
	variable strtChrom, endChrom, appPoints, offset, det
	
	variable stepSize = 1
	variable chrNm = strtChrom+stepSize, numpnts1, numpnts2, inc
	string com, chrom1Nm, chrom2Nm
	
	SetDataFolder root:chroms:

//	wave /Z W_coef = W_coef
	make /n=2/o W_coef

	string TT = time()
	string DD = date()

	do
		chrom1Nm = ChromName(det, chrNm-stepSize)
		chrom2Nm = ChromName(det, chrNm)
		if ( (exists(chrom1Nm) == 1) * (exists(chrom2Nm) == 1) )
			wave chrom1 = $chrom1Nm
			wave chrom2 = $chrom2Nm
			numpnts1 = numpnts(chrom1)
			InsertPoints numpnts1, appPoints+offset, chrom1
			chrom1[numpnts1,numpnts1+offset] = nan
			chrom1[numpnts1+offset,numpnts1+offset+appPoints] = chrom2[p-numpnts1-offset]

//			originally had gauss fit.  But occiationally bombs (singular matrix).
			CurveFit /Q line chrom1(pnt2x(chrom1,numpnts1-offset*3),pnt2x(chrom1,numpnts1+offset*3))
			chrom1[numpnts1-offset/2,numpnts1+offset+offset/2] = W_coef[0]+W_coef[1]*x
//			CurveFit /q gauss chrom1(pnt2x(chrom1,numpnts1-offset*3),pnt2x(chrom1,numpnts1+offset*3))
//			chrom1[numpnts1-offset/2,numpnts1+offset+offset/2] = W_coef[0]+W_coef[1]*exp(-((x-W_coef[2])/W_coef[3])^2)

			DeletePoints 0, appPoints, chrom1
			sprintf com, "Chromatogram shifted by %d points:  %s, %s", appPoints, TT, DD
			Note chrom1, com
		endif
		chrNm += stepSize
	while (chrNm <= endChrom)
	
	SetDataFolder root:
	
end

//Pastes chroms together
Proc ConcatChroms (firstChrom, ch)
	variable firstChrom=returnMINchromNum(1), ch=V_currCh
	prompt firstChrom, "Chrom num in FIRST pair?"
	prompt ch, "Detector Number of chroms to concatenate?",  popup, ListNLong(V_chans,";")
	
	silent 1; pauseUpdate
	
	if  (firstChrom>=0)
		ConcatChromsFUNCT (firstChrom, ch)
	endif
	
end

// changed function to use AS_All (061101 gsd)
function ConcatChromsFUNCT (firstChrom, ch)
	variable firstChrom, ch
	
	DoWindow /K ChromPanel

	wave AS = $("root:AS:CH" + num2str(ch) + "_All")
	SVAR mollst = $("root:DB:S_molLst" + num2str(ch))
	string ch1, ch2, mol
	variable last = returnMAXchromNum(ch), chrominc = firstChrom, i, ResRow
	
	SetDataFolder root:chroms:

	do
		ch1 = ChromName(ch, chrominc)
		chrominc = NextChromInAS(ch, chrominc, 1 )
		ch2 = ChromName(ch, chrominc)
		ConcatenateWaves(ch1, ch2)
		killwaves $ch2
		for(i=0; i<ItemsInList(mollst); i+=1)
			mol = StringFromList(i, mollst)
			if ( exists("root:" + mol + "_ret") != 1 )
				MakePeakResWaves( mol, 0 )
			endif
			wave flag = $("root:" + mol + "_flagBad")
			ResRow = ReturnResRowNumber( ch, chrominc )
			flag[ResRow] = 1
		endfor
		chrominc = NextChromInAS(ch, chrominc, 1 )
	while(chrominc <= last-1 )
	
	SetDataFolder root:	

//	CreateChromAS()
end

// Cut a chrom in half and makes two chroms.
// NOTE::::: Splitchroms does not lengthen tsecs, selpos, inj_p or inj_t
Proc SplitChroms (firstChrom, ch)
	variable firstChrom=returnMINchromNum(1), ch=V_currCh
	prompt firstChrom, "Chrom num in FIRST pair?"
	prompt ch, "Detector Number of chroms to split in half?",  popup, ListNLong(V_chans,";")
	
	silent 1; pauseUpdate
		
	if  (firstChrom>=0)
		SplitChromsFUNCT (firstChrom, ch)
	endif
	
end

function SplitChromsFUNCT (firstChrom, ch)
	variable firstChrom, ch

	DoWindow /K ChromPanel

	wave AS = $("root:AS:CH" + num2str(ch) + "_All")
	string fullchrom, front, tail, chrom, chromNew
	variable last = returnMAXchromNum(ch), inc = firstChrom
	variable ASinc = ReturnResRowNumber( ch, firstChrom ), num, scale

	SetDataFolder root:chroms:
	
	// cut each chrom in half and store these new chroms in the temp data folder, delete the original
	do
		fullchrom = ChromName(ch, AS[ASinc])
		front = "root:temp:" + ChromName(ch, inc)
		tail = "root:temp:" + ChromName(ch, inc + 1)
		num = numpnts($fullchrom)
		scale = pnt2x($fullchrom, numpnts($fullchrom))/numpnts($fullchrom)
		duplicate /o/R=[0,(num-1)/2] $fullchrom, $front
		duplicate /o /R=[(num-1)/2+1, num] $fullchrom, $tail
		SetScale/P x 0,scale,"", $tail
		killwaves $fullchrom
		inc += 2
		ASinc += 1
	while(ASinc < numpnts(AS) )

	// move the new chroms from the temp data folder	
	SetDataFolder root:temp:
	inc = 0
	do
		chrom = GetIndexedObjName(":", 1, inc)
		chromNew = "root:chroms:" + chrom
		if (strlen(chrom) == 0)
			break
		endif
		if (strsearch(chrom, "chr", 0) != -1)
			duplicate /o $chrom, $chromNew
			killwaves $chrom
			inc -= 1 
		endif
		inc += 1
	while (1)
	
	SetDataFolder root:	

	CreateChromAS()

end

// determins if experiment is a PANTHER experiment and if so, which type of itx file to load
function InstrumentSpecficCalls()

	SVAR inst = root:S_instrument
	
	// handle two type of PANTHER itx files.
	if ( cmpstr(inst, "PANTHER") == 0)
		string datatype
		string helptext = "PANTHER integrator experiments can only process one data set type at a time.  Choose either ECD or MSD data sets."
		Prompt datatype, "Load which type of PANTHER data?", popup, "ECD;MSD"
		DoPrompt /HELP=helptext "Load which type of PANTHER data?", datatype

		if ( V_flag == 1 )	// cancel was pressed
			abort
		endif

		if (cmpstr(datatype, "ECD") == 0)
			String /G S_PANTHERtype = "GC"
		else
			String /G S_PANTHERtype = "MSD"
		endif
		
	elseif ( cmpstr(inst, "stdHP") == 0 )			// handles varialbe for incrementing chrom name
		if (exists("root:V_chromInc") == 0 )
			variable /G root:V_chromInc = 1
		endif
		NVAR chromInc = root:V_chromInc
		chromInc = 1
	endif
	

end