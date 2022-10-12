#pragma rtGlobals=1		// Use modern global access method.

// function will find a peak in chrom between xtart and xstop
// the baseline will first be subtracted
Function FindRetOnePeak(mol, chrnum)
	variable chrnum
	string mol
	
	NVAR IntButton = root:V_IntButton
		
	variable ch = returnChannel(mol)
	variable ResRow = ReturnResRowNumber(ch, chrnum)
	
	// non existant peak
	if ( ch < 1 )
		return nan
	endif
	
	wave DBexpStart = root:DB:DB_expStart
	wave DBexpStop = root:DB:DB_expStop
	wave DBedgePoints = root:DB:DB_edgePoints
	wave ret = $("root:" + mol + "_ret")
	wave molStart = $("root:" + mol + "_Start")
	wave molStop = $("root:" + mol + "_Stop")
	
	variable DBrow = returnMolDBrow(mol)
	variable edgeAvg = DBedgePoints[DBrow]
	
	variable BaseStart = molStart[ResRow]
	variable BaseStop = molStop[ResRow]
	variable PeakStart = ReturnPeakStartPt(mol, chrNum)
	variable PeakStop = ReturnPeakStopPt(mol, chrNum)
	variable DBpkStart = DBexpStart[DBrow]
	variable DBpkStop = DBexpStop[DBrow]
	variable avgStartY, avgStopY
	variable Signal2Noise = 0.1			// Peak needs to be 10% greater than measured noise.
	variable CloseEnough = 30			// resp (Hz)
	variable CloseEnoughT = 0.5			// seconds

	// use previous ret
	variable recRet = MostRecentRet(mol, chrNum)
	
	// missing peakstart or peakstop	
	if ((numtype(PeakStart) != 0) || (numtype(PeakStop) != 0))
		DBpkStart = DBexpStart[DBrow]
		DBpkStop = DBexpStop[DBrow]
		// no recent ret found
		if ( numtype(recRet) != 0 )
			recRet = MaxBetweenPtsOnChrom(mol, chrNum, DBpkStart, DBpkStop)
			ret[ReturnResRowNumber(ch, chrNum)] = recRet
		endif
		PeakStart = recRet - ( DBpkStop - DBpkStart )/2
		PeakStop = recRet + ( DBpkStop - DBpkStart )/2
	endif
	
	if ((numtype(BaseStart) != 0) || (numtype(BaseStop) != 0))
		BaseStart = PeakStart
		BaseStop = PeakStop
	endif


	String savedf = GetDataFolder(1)
	SetDataFolder root:chroms
	
	// make sure the chromatogram exists
	string chrom = ChromName(ch, chrNum)
	if (!exists(chrom))
		SetDataFolder savedf
		return NaN
	endif
	wave chromWv = $chrom

	duplicate /O/R=[x2pnt(chromWv,PeakStart)-edgeAvg/2, x2pnt(chromWv, PeakStop)+edgeAvg/2] chromWv, chromTmp
	
	// average the starting points		
	wavestats /Q/R=[0,edgeAvg-1] chromTmp
	avgStartY = V_avg
	wavestats /Q/R=[(numpnts(chromTmp)-1) - edgeAvg, (numpnts(chromTmp)-1)] chromTmp
	avgStopY = V_avg
	
	// subtract baseline
	variable m = (avgStopY - avgStartY) / (PeakStop - PeakStart)
	variable b = avgStartY - m*PeakStart
	chromTmp -= (b + m*x)

	wavestats /Q/R=(BaseStart,BaseStop) chromTmp
	Variable boxSize = V_npnts * 0.05							// used for smooth 
	Variable range = V_max - V_min
	Variable top = V_maxLoc
	Variable noise = V_sdev

	if (edgeAvg > 1)
		FindPeak/Q/B=(boxSize)/R=(BaseStart,BaseStop)/M=(range*Signal2Noise) chromTmp		// uses average measured from baseline
	else
		FindPeak/Q/B=(boxSize)/R=(BaseStart,BaseStop)/M=5 chromTmp
	endif

	SetDataFolder savedf

	if (V_Flag == 0)	// found peak with FindPeak algo
		
		// if top is on the edge of chromTmp return the found peak, V_PeakLoc
		if ( (abs(top-pnt2x(chromTmp,0)) <= CloseEnoughT) || (abs(top-pnt2x(chromTmp,numpnts(chromTmp)-1)) <= CloseEnoughT) )
			return V_PeakLoc
		endif

		if ( (chromTmp(V_PeakLoc)-chromTmp(top)) >=  CloseEnough ) // handle local max
			ret[ResRow] = V_PeakLoc
			return V_PeakLoc
		else
			ret[ResRow] = top
			return top
		endif
	else
		// check if top is larger than noise (V_sdev)
		if ( chromTmp[top] > noise*2 )
			return top
		else
			return NaN
		endif
	endif
	
end

// finds the max point between pt1 and pt2 and returns the x location.
// good for a quick guess a ret time
Function MaxBetweenPtsOnChrom(mol, chrnum, pt1, pt2)
	variable chrnum, pt1, pt2
	string mol
	
	wave DBexpStart = root:DB:DB_expStart
	wave DBexpStop = root:DB:DB_expStop
	wave DBedgePoints = root:DB:DB_edgePoints
	wave ret = $("root:" + mol + "_ret")
	
	variable DBrow = returnMolDBrow(mol)
	variable edgeAvg = DBedgePoints[DBrow]
	
	variable PeakStart = pt1
	variable PeakStop = pt2

	variable avgStartY, avgStopY
	variable ch = returnChannel(mol)
	String savedf = GetDataFolder(1)
	SetDataFolder root:chroms
	
	// make sure the chromatogram exists
	string chrom = ChromName(ch, chrNum)
	if (!exists(chrom))
		SetDataFolder savedf
		return NaN
	endif
	wave chromWv = $chrom

	duplicate /O/R=[x2pnt(chromWv,PeakStart)-edgeAvg/2, x2pnt(chromWv, PeakStop)+edgeAvg/2] chromWv, chromTmp

	// average the starting points		
	wavestats /Q/R=[0,edgeAvg-1] chromTmp
	avgStartY = V_avg
	wavestats /Q/R=[(numpnts(chromTmp)-1) - edgeAvg, (numpnts(chromTmp)-1)] chromTmp
	avgStopY = V_avg
	
	// subtract baseline
	variable m = (avgStopY - avgStartY) / (PeakStop - PeakStart)
	variable b = avgStartY - m*PeakStart
	chromTmp -= (b + m*x)

	// check and subtract baseline again
	wavestats /Q/R=[0, numpnts(chromTmp)/3] chromTmp
	variable minL = V_minLoc
	wavestats /Q/R=[numpnts(chromTmp)*2/3, numpnts(chromTmp)-1] chromTmp
	variable minR = V_minLoc
	m = (chromTmp(MinL) - chromTmp(MinR)) / (MinL - MinR)
	b = chromTmp(MinL) - m*MinL
	chromTmp -= (b + m*x)

	Wavestats /Q/R=(minL,minR) chromTmp

	return V_maxloc
end


// sets peak edges for a given molecule and chromatogram number to DB_expStart tna DB_expStop
// meth number 0
Function Edges_FixedWindow(mol, chrnum)
	variable chrnum
	string mol
	
	if (exists("root:V_tangentSkim") == 0 )
		variable /G 	root:V_tangentSkim = 0
	endif
	NVAR V_tangentSkim = root:V_tangentSkim

	wave methP1 = root:DB:DB_methParam1
	wave ret = $("root:" + mol + "_ret")
	
	variable ch = returnChannel(mol)
	variable ResRow = ReturnResRowNumber( ch, chrnum )
	variable DBrow = returnMolDBrow(mol)
	variable useRet = Max(methP1[DBrow], V_tangentSkim)

	wave pkStart = $("root:" + mol + "_Start")
	wave pkStop = $("root:" + mol + "_Stop")
	wave pkRet = $("root:" + mol + "_ret")
	wave flagMan = $("root:" + mol + "_flagMan")
	wave flagBad = $("root:" + mol + "_flagBad")
	
	wave DBexpStart = root:DB:DB_expStart
	wave DBexpStop = root:DB:DB_expStop

	if ( useRet )
		variable row, firstRet = 0, ASinc, leftofRet, rightOfRet, firstchrm
		wave AS = $("root:AS:CH" + num2str(ch) + "_AS")

		// find first defined retention time in AS
		firstchrm = RetFirstUnflaggedChrom( mol )
		firstRet = ret[ReturnResRowNumber( ch, firstchrm )]

		if ( firstRet > 0 )
			leftOfRet = firstRet - DBexpStart[DBrow]
			rightOfRet = DBexpStop[DBrow] - firstRet
		else 
			useRet = 0
		endif
		
	endif
	
	if ( useRet )
		pkStart[ResRow] = pkRet[ResRow] - leftOfRet
		pkStop[ResRow] = pkRet[ResRow] + rightOfRet
	else
		pkStart[ResRow] = DBexpStart[DBrow]
		pkStop[ResRow] = DBexpStop[DBrow]
	endif
	
end

// finds peak edges for a given molecule and chromatogram number
// meth number 1
Function Edges_FixedStart(mol, chrnum)
	variable chrnum
	string mol

	variable ch = returnChannel(mol)
	variable ResRow = ReturnResRowNumber( ch, chrnum )
	variable DBrow = returnMolDBrow(mol)
	
	wave pkStart = $("root:" + mol + "_Start")
	wave pkStop = $("root:" + mol + "_Stop")
	
	wave DBexpStart = root:DB:DB_expStart
	wave DBexpStop = root:DB:DB_expStop
	wave DBedgePoints = root:DB:DB_edgePoints

	variable edgeAvg = DBedgePoints[DBrow]
	variable half = ceil(edgeAvg/2)
	
	wave chrom = $(":chroms:chr" + num2str(ch) + "_" + PadStr(chrnum, 5, "0"))
	Differentiate chrom/D=:chroms:chromTmp
	wave diffchrom = :chroms:chromTmp
	Smooth /S=4 25, diffchrom
	
	variable startX = pkStart[ResRow]
	variable startPt = x2pnt(chrom, startX)
	
	if ( numtype(startX) != 0 )
		pkStop[ResRow] = NaN
		return 1
	endif
	
	wavestats /Q/R=[startPt - half, startPt + half] :chroms:chromTmp
	
	variable inc, pointInc, startslope = V_avg, stopslope, width, stopX, stopPt, maxStopX, maxStopPt, best, bestPt = nan, slope
	width = DBexpStop[DBrow] - startX
	stopX = DBexpStop[DBrow] - 0.3 * width
	maxStopX = DBexpStop[DBrow] + 0.2 * width
	maxStopPt = Min(x2pnt(:chroms:chromTmp, maxStopX),  numpnts(:chroms:chromTmp))
	stopPt = x2pnt(chrom, stopX)
	best = 100000
	pointInc = 1
	
	do
		wavestats /Q/R=[stopPt - half, stopPt + half] :chroms:chromTmp
		if ( abs(startSlope - V_avg) < best )
			best = abs(startSlope - V_avg)
			bestPt = stopPt
			stopX = pnt2x(chrom, stopPt)
//			slope = (chrom(startX) - chrom(stopX)) / (startX - stopX)
			if ( best < 2 ) // kicks out because 2 is a pretty good answer
				break
			endif
		endif

		// going the wrong way, consider done.
		if (( best < 100) && (abs(startSlope - V_avg) > 300))
			break
		endif

		stopPt += pointInc
//		inc += 1
	while ( stopPt < maxStopPt )
	
	if ( numtype(bestPt) == 0 )
		pkStart[ResRow] = pkStart[ResRow]
		pkStop[ResRow] = pnt2x(chrom, bestPt)
		return 1
	else
		pkStart[ResRow] = pkStart[ResRow]
		pkStop[ResRow] = DBexpStop[DBrow]
		return 0
	endif

end

// finds peak edges  for a given molecule and chromatogram number
// meth number 2
Function Edges_FixedStop(mol, chrnum)
	variable chrnum
	string mol

	variable ch = returnChannel(mol)
	variable ResRow = ReturnResRowNumber( ch, chrnum )
	variable DBrow = returnMolDBrow(mol)
	
	wave pkStart = $("root:" + mol + "_Start")
	wave pkStop = $("root:" + mol + "_Stop")
	
	wave DBexpStart = root:DB:DB_expStart
	wave DBexpStop = root:DB:DB_expStop
	wave DBedgePoints = root:DB:DB_edgePoints

	variable edgeAvg = DBedgePoints[DBrow]
	variable half = ceil(edgeAvg/2)
	
	wave chrom = $(":chroms:chr" + num2str(ch) + "_" + PadStr(chrnum, 5, "0"))
	Differentiate chrom/D=:chroms:chromTmp
	wave diffchrom = :chroms:chromTmp
	Smooth /S=4 25, diffchrom
	
	variable stopX = pkstop[ResRow]
	variable stopPt = x2pnt(chrom, stopX)
	
	if ( numtype(stopX) != 0 )
		pkStart[ResRow] = NaN
		return 1
	endif
	
	wavestats /Q/R=[stopPt - half, stopPt + half] diffchrom
	
	variable inc, pointInc, startslope = V_avg, stopslope, width, startX, startPt, minStartX, minStartPt, best, bestPt = nan, slope
	width = stopX - DBexpStart[DBrow]
	startX = DBexpStart[DBrow] + 0.3 * width
	minStartX = DBexpStart[DBrow] - 0.2 * width
	minStartPt = Max(x2pnt(:chroms:chromTmp, minStartX),  0)
	startPt = x2pnt(chrom, startX)
	best = 100000
	pointInc = 1

	do
		wavestats /Q/R=[startPt - half, startPt + half] :chroms:chromTmp
		if ( abs(startSlope - V_avg) < best )
			best = abs(startSlope - V_avg)
			bestPt = startPt
			startX = pnt2x(chrom, startPt)
			slope = (chrom(startX) - chrom(stopX)) / (startX - stopX)
			if ( best < 2 ) // kicks out because 2 is a pretty good answer
				break
			endif
		endif
		
		// going the wrong way, consider done.
		if (( best < 100) && (abs(startSlope - V_avg) > 300))
			break
		endif

		startPt -= pointInc
		inc += 1
	while ( startPt > minStartPt )

	if ( numtype(bestPt) == 0 )
		pkStart[ResRow] = pnt2x(chrom, bestPt)
		pkStop[ResRow] = pkStop[ResRow]
		return 1
	else
		pkStart[ResRow] = DBexpStart[DBrow]
		pkStop[ResRow] = pkStop[ResRow]
		return 0
	endif

end

Function Edges_TangentSkim(mol, chrnum)
	string mol
	variable chrnum
	
	if (exists("root:V_tangentSkim") == 0 )
		variable /G 	root:V_tangentSkim = 1
	endif
	NVAR V_tangentSkim = root:V_tangentSkim

	variable ch = returnChannel(mol)
	variable ResRow = ReturnResRowNumber( ch, chrnum )
	variable DBrow = returnMolDBrow(mol)
	
	wave pkStart = $("root:" + mol + "_Start")
	wave pkStop = $("root:" + mol + "_Stop")
	wave pkRet = $("root:" + mol + "_ret")
	wave flagMan = $("root:" + mol + "_flagMan")
	wave flagBad = $("root:" + mol + "_flagBad")
	
	wave DBexpStart = root:DB:DB_expStart
	wave DBexpStop = root:DB:DB_expStop
	wave DBedgePoints = root:DB:DB_edgePoints

	if ( (flagMan[ResRow]==1) || (flagBad[ResRow]==1))
		return 0
	endif

	wave chrom = $("root:chroms:" + ChromName(ch, chrNum))
	
	if ( numtype(pkRet[ResRow]) != 0 )
		pkStart[ResRow] = NaN
		pkStop[ResRow] = NaN
		return NaN
	endif
	
	// first set pkStart and pkStop with the fixed window
	V_tangentSkim = 1
	Edges_FixedWindow(mol, chrnum)
	V_tangentSkim = 0
	
	variable give = (DBexpStop[DBrow] - DBexpStart[DBrow])/8		// seconds
	variable boxSize, range
	
	// find minimum on left of peak
	Wavestats /Q/R=(pkStart[ResRow]-give, pkRet[ResRow])  chrom
	variable MinL = V_minloc
//	boxSize = V_npnts * 0.1
//	FindPeak/Q/N/B=(boxSize)/R=(MinL, pkRet[ResRow]) chrom
//	if ( V_flag == 0 )
//		MinL = V_PeakLoc
//	endif

	// find minimum to the right of the peak
	Wavestats /Q/R=(pkRet[ResRow], pkStop[ResRow]+give)  chrom
	variable MinR = V_minloc
//	boxSize = V_npnts * 0.1
//	FindPeak/Q/N/B=(boxSize)/R=(pkRet[ResRow], MinR) chrom
//	if ( V_flag == 0 )
//		MinR = V_PeakLoc
//	endif

	// subtract baseline
	variable m = (chrom(MinR) - chrom(MinL)) / (MinR - MinL)
	variable b = chrom(MinR) - m*MinR
	duplicate /o chrom, root:chroms:chromTmp
	wave chromTmp = root:chroms:chromTmp
	MinR += 1						// add 1 second to the right
	MinL -= 1						// subtract 1 s from the left
	deletepoints x2pnt(chrom, MinR), 1000000, chromTmp
	deletepoints 0, x2pnt(chrom, MinL), chromTmp
	SetScale/I x MinL,MinR,"", chromTmp
	chromTmp -= (m*x + b)

	if (numpnts(chromTmp) < 4 )
		pkStart[ResRow] = NaN
		pkStop[ResRow] = NaN
	else
		// refind minimum on left	
		Wavestats /Q/R=(MinL, pkRet[ResRow]) chromTmp
		MinL = V_minloc
	
		// refind minimum on right
		Wavestats /Q/R=(pkRet[ResRow], MinR)  chromTmp
		MinR = V_minloc
	
		pkStart[ResRow] = MinL
		pkStop[ResRow] = MinR
	endif

end

Function FindRetAS()
	
	wave DBactive = root:DB:DB_activePeak
	wave DBchan = root:DB:DB_chan
	
	NVAR numCh = root:V_chans
	
	variable molinc, ASinc, DBmolRow, ch, resRowNum
	string mol
	
	for (ch=1; ch <= numCh; ch+= 1)
		SVAR molLst = $("root:DB:S_molLst" + num2str(ch))
		molinc = 0
		do
			mol = StringFromList(molinc, molLst, ";")
			DBmolRow = returnMolDBrow(mol)

			// make mol results waves, if needed
			if ( ! WaveExists($("root:" + mol + "_ret")) )
				MakePeakResWaves( mol, 0 )
			endif
			
			wave ret = $("root:" + mol + "_ret")
			wave flagMan = $("root:" + mol + "_flagMan")
			wave flagBad = $("root:" + mol + "_flagBad")
			
			// is the peak active?
			if ( DBactive[DBmolRow] )
				
				// find retention time in active set only
				wave AS = $("root:AS:CH" + num2str(ch) + "_AS")
				ASinc = 0
				do
					if ( numpnts(AS) == 0 )
						break
					endif
					
					resRowNum = ReturnResRowNumber( ch, AS[ASinc] )

					// find edges if man or bad flags are not set
					if ( (! flagMan[resRowNum]) && (! flagBad[resRowNum]) ) 
						FindRetOnePeak(mol, AS[ASinc])
					endif
				
					ASinc += 1
				while (ASinc < numpnts(AS))
				
			endif
			
			molinc += 1
			
		while ( molinc < ItemsInList(molLst))
	endfor
	
	killwaves /z root:chroms:chromTmp
	
end

Function FindEdgesAS()

	wave DBactive = root:DB:DB_activePeak
	wave DBchan = root:DB:DB_chan
	wave DBmeth = root:DB:DB_meth
		
	NVAR numCh = root:V_chans
	NVAR /Z verbos = root:V_gaussVerbos
	
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

				// find edges in active set only
				wave AS = $("root:AS:CH" + num2str(ch) + "_AS")
				ASinc = 0
				do
					if ( numpnts(AS) == 0 )
						break
					endif

					ResRow = ReturnResRowNumber( ch, AS[ASinc] )
					
					if (( DBmeth[DBmolRow] == 4 ) && ( ! flagBad[ResRow] ))
						verbos = 0
						Edges_GaussFit(mol, AS[ASinc])
					elseif ( ( DBmeth[DBmolRow] != 4 ) && (! flagMan[ResRow]) && (! flagBad[ResRow]) ) 
			
						switch ( DBmeth[DBmolRow] )
							case 0:
								Edges_FixedWindow( mol, AS[ASinc] )
								break
							case 1:
								Edges_FixedStart( mol, AS[ASinc] )
								break
							case 2:
								Edges_FixedStop( mol, AS[ASinc] )
								break
							case 3:
								Edges_TangentSkim( mol, AS[ASinc] )
								break
						endswitch
						
						// refind ret with new edge points
						FindRetOnePeak(mol, AS[ASinc])
						
					endif
				
					ASinc += 1
				while (ASinc < numpnts(AS))
				
			endif
			
			molinc += 1
			
		while ( molinc < ItemsInList(molLst))
	endfor

	verbos = 1

end

Function GaussPeakFit(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = y0 + m*x + A0*exp(-((x-x0)/w0)^2) + A1*exp(-((x-x1)/w1)^pow)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 9
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = m
	//CurveFitDialog/ w[2] = A0
	//CurveFitDialog/ w[3] = x0
	//CurveFitDialog/ w[4] = w0
	//CurveFitDialog/ w[5] = A1
	//CurveFitDialog/ w[6] = x1
	//CurveFitDialog/ w[7] = w1
	//CurveFitDialog/ w[8] = pow
	
	return w[0] + w[1]*x + w[2]*exp(-((x-w[3])/w[4])^2) + w[5]*exp(-((x-w[6])/w[7])^w[8])
End

function MakeGaussFitWaves(mol)
	string mol
	
	variable ch = returnChannel(mol)
	variable NUMPARMS = 9			// number of fit parameters in GaussPeakFit

	// non existant peak
	if ( ch < 1 )
		return nan
	endif

	wave ASall = $"root:AS:CH" + num2str(ch) + "_All"

	// matrix to store fit results for all chroms
	string FitResultsStr = "root:" + mol + "_gaussRes"
	if (! WaveExists($FitResultsStr))
		make/n=(numpnts(ASall),NUMPARMS) $FitResultsStr = nan
	endif
	wave FitResults = $FitResultsStr 

	// make intial conditions waves
	string comment = "comment"
	string coef = "IntCoef_" + mol
	string hold = "Hold_" + mol 

	make /t/o/n=(NUMPARMS+2) $comment = {"offset (-1 = auto)", "slope", "peak amp (-1 = auto)", "peak loc (-1 = auto)", "peak wid (-1 = auto)", "baseline amp (-1 = auto)", "baseline loc (-1 = auto)", "baseline wid (-1 = auto)", "power (-1 = auto)", "window left of ret (s)", "window right of ret (s)" }
	if (! WaveExists($coef))
		make /D/n=(NUMPARMS+2) $coef = 0
	endif
	if (! WaveExists($hold))
		make /B/n=(NUMPARMS) $hold = 0
	endif
	
end

function GaussFit_InitGuess()

	NVAR chrnum = root:V_chromNum
	NVAR currCh = root:V_currCh
	SVAR currPeak = root:S_currPeak
	
	string info = TableInfo("GaussFitTable", 1)
	string mol = StringByKey("IntCoef", StringByKey("WAVE", info), "_", ":")
	if (strlen(mol) <= 0)
		abort "Can determine which molecule you are working on.  Function needs a \"Gauss Fit Params\" table."
	endif
	DoWindow /F GaussFitTable

	variable ch = returnChannel(mol)
	currCh = ch
	variable ResRow = ReturnResRowNumber(ch, chrnum)
	
	// makes sure the displayed peak is the same as from the Gauss Fit Table
	if ( cmpstr(currPeak, mol) != 0 )
		currPeak = mol
		MANpanel()
		DoWindow /F GaussFitTable
	endif

	wave coef = $("IntCoef_" + mol)
	wave hold = $("Hold_" + mol)

	wave ASall = $"root:AS:CH" + num2str(ch) + "_All"
	wave retwv = $("root:" + mol + "_ret")

	// Displayed chrom	
	string  chromStr = "root:chroms:" + ChromName(ch, chrNum)
	if (! WaveExists($chromStr))
		abort "Displayed chrom is not valid?"
	endif
	wave chrom = $chromStr
	
	variable PeakStart = ReturnPeakStartPt(mol, chrnum)
	variable PeakStop = ReturnPeakStopPt(mol, chrnum)
	variable ret = retwv[ResRow]

	wavestats /Q chrom

	coef[0] = (chrom(PeakStart) + chrom(PeakStop))/2					// offset
	coef[1] = 0																// slope
	coef[2] = chrom(ret) - Min(chrom(PeakStart), chrom(PeakStop))		// peak amplitude
	coef[3] = ret															// peak location
	coef[4] = (PeakStop-PeakStart)/2										// peak width
	coef[5] = (V_max - V_min) / 5											// baseline amplitude
	coef[6] = V_maxloc														// baseline location
	coef[7] = 20															// baseline width
	coef[8] = 2																// baseline exponent (1=exp, 2=gauss)
	
	if ( coef[9] <= 0 )
		coef[9] = (ret - PeakStart) * 2
	endif
	if ( coef[10] <= 0 )
		coef[10] = (PeakStop - ret) * 2
	endif
	
end

function Edges_GaussFit(mol, chrnum)
	string mol
	variable chrnum
	
	NVAR verbos = V_gaussVerbos
	
	variable NUMPARMS = 9
	Variable V_FitNumIters
	Variable V_FitMaxIters = 200
	Variable V_fitOptions = 4
	
	variable ch = returnChannel(mol)
	variable ResRow = ReturnResRowNumber(ch, chrnum)
	wave chrom = $("root:chroms:" + ChromName(ch, chrNum)	)
	wave retwv = $("root:" + mol + "_ret")
	wave Intcoef = $("IntCoef_" + mol)
	wave hold = $("Hold_" + mol)
	
	// matrix to store fit results for all chroms
	wave FitResults = $("root:" + mol + "_gaussRes") 
	
	Duplicate /o Intcoef, ResCoef
	Deletepoints NUMPARMS,2, ResCoef
	
	variable stepL = Intcoef[9]
	variable stepR = Intcoef[10]
	variable i
	variable ret = retwv[ResRow]
	variable ptL = Max(0, x2pnt(chrom, ret - stepL))
	variable ptR = Min(x2pnt(chrom, ret + stepR), numpnts(chrom))
	variable PeakStart = ReturnPeakStartPt(mol, chrnum)
	variable PeakStop = ReturnPeakStopPt(mol, chrnum)
	
	if (numtype(ret) != 0 )
		return 0
	endif
	
	// make hold string from hold wave
	string holdstr =""
	for (i=0; i<NUMPARMS; i+=1)
		sprintf holdstr, "%s%d", holdstr, hold[i]
	endfor

	// check for autoselection option in Coef Wave (any negative number execept for the slope)
	Wavestats /Q chrom
	if ( ResCoef[0] < 0 )
		ResCoef[0] = (chrom(PeakStart) + chrom(PeakStop))/2
	endif
	if ( ResCoef[1] < 0 )
		ResCoef[1] = ResCoef[1]
	endif
	if ( ResCoef[2] < 0 )
		ResCoef[2] = chrom(ret) - Min(chrom(PeakStart), chrom(PeakStop))	
	endif
	if ( ResCoef[3] < 0 )
		ResCoef[3] = ret
	endif
	if ( ResCoef[4] < 0 )
		ResCoef[4] = (PeakStop-PeakStart)/2
	endif
	if ( ResCoef[5] < 0 )
		ResCoef[5] = (V_max - V_min) / 5	
	endif
	if ( ResCoef[6] < 0 )
		ResCoef[6] = V_maxloc
	endif
	if ( ResCoef[7] < 0 )
		ResCoef[7] = 20
	endif
	if ( ResCoef[8] < 0 )
		ResCoef[8] = 2
	endif

	Duplicate /o ResCoef W_coef
	if ( verbos )
		FuncFit/N/Q/X=1/H=holdstr GaussPeakFit ResCoef  chrom[ptL,ptR]
		print "Found solution in", V_FitNumIters, "iterations"
	else
		FuncFit/Q/X=1/H=holdstr GaussPeakFit W_coef chrom[ptL,ptR]
		ResCoef = W_coef
	endif

	// save fit results.
	FitResults[ResRow][] = ResCoef[q]
end

Window GaussFitTable( mol ) : Table
	string mol
	PauseUpdate; Silent 1		// building window...
	
	if (exists("V_gaussVerbos") == 0)
		Variable /G V_gaussVerbos = 1
	endif
	
	MakeGaussFitWaves( mol )
	
	string coef = "IntCoef_" + mol
	string hold = "Hold_" + mol
	string Wcoef = "ResCoef"
	
	if (!WaveExists($Wcoef))
		Make /n=9 $Wcoef
	endif
	
	variable left = 556
	variable top = 51
	variable right = 1050
	variable bottom = 333
	
	DoWindow /K GaussFitTable
	Edit/K=1/W=(left, top, right, bottom) comment,$coef,$hold, $Wcoef as "Gauss Fit Params"
	ModifyTable font(comment)="Rockwell",size(comment)=12,style(comment)=1,width(comment)=155
	ModifyTable rgb($hold)=(65535,0,0)
	ModifyTable rgb($Wcoef)=(0,39321,0)
	
	DrawGaussPanel( left, top+308, right, bottom+110 )
	
	SetWindow GaussFitTable, hookevents=0, hook=GFITrefresh
	
EndMacro

function GFITrefresh( infoStr )
	String infoStr

	String event= StringByKey("EVENT",infoStr)
	String info, rangeStr
	Variable left, right, top, bottom
		
	if ((cmpstr(event, "moved") == 0) || (cmpstr(event, "activate") == 0))
		info = WinRecreation("GaussFitTable", 0)
		left = StrSearch(info, "/W=", 0)
		right = StrSearch(info,"comment",0)
		rangeStr = info[left+4,right-3]
		left = str2num(StringFromList(0,rangeStr,","))
		top = str2num(StringFromList(1,rangeStr,","))
		right = str2num(StringFromList(2,rangeStr,","))
		bottom = str2num(StringFromList(3,rangeStr,","))
		DrawGaussPanel(left, top+308, right, bottom+110 )
		DoWindow /F GaussFitTable
	elseif ( cmpstr(event, "kill") == 0)
		DoWindow /K GaussPanel
	endif
	
end

Function DrawGaussPanel(left, top, right, bottom ) 
	variable left, top, right, bottom 
	DoWindow /K GaussPanel
	NewPanel /K=1 /W=(left, top, right, bottom) as "Gauss Fit Panel"
	DoWindow /C GaussPanel
	ModifyPanel cbRGB=(65535,65534,49151), frameStyle=4
	SetDrawLayer UserBack
	SetDrawEnv arrow= 1
	DrawLine 103,28,125,28
	SetDrawEnv arrow= 1
	DrawLine 223,26,245,26
	SetDrawEnv arrow= 1
	DrawLine 343,27,365,27
	DrawLine 466,27,476,27
	DrawLine 476,27,476,66
	SetDrawEnv arrow= 1
	DrawLine 476,66,451,66
	Button FitOnePeak,pos={130,9},size={90,40},proc=GFIT_ButtonProc,title="Fit Displayed\rPeak"
	Button FitOnePeak,help={"Press button to use coefs displayed on current chromatogram."}
	Button FitOnePeak,fColor=(32769,65535,32768)
	Button FitAS,pos={250,9},size={90,40},proc=GFIT_ButtonProc,title="Fit All\rAS Peaks"
	Button FitAS,help={"Press button to use coefs displayed on all AS chromatograms."}
	Button FitAS,fColor=(16386,65535,16385)
	Button ApplyFitResults,pos={251,56},size={197,20},proc=GFIT_ButtonProc,title="Apply Fit Results to AS"
	Button ApplyFitResults,help={"Press button to apply fit results to the _height wave."}
	Button ApplyFitResults,fColor=(16385,49025,65535)
	Button InitialGuess,pos={11,9},size={90,40},proc=GFIT_ButtonProc,title="Initial\rGuess"
	Button InitialGuess,help={"Fills the IntCoef_ wave with an initial guess from the current chromatogram."}
	Button InitialGuess,fColor=(65535,60076,49151)
	Button resMatrix,pos={370,9},size={90,40},proc=GFIT_ButtonProc,title="View Results\rMatrix"
	Button resMatrix,help={"Opens a table with the _gaussRes matrix."}
	Button resMatrix,fColor=(16386,65535,16385)
EndMacro


Function GFIT_ButtonProc(ctrlName) : ButtonControl
	String ctrlName

	NVAR chrnum = root:V_chromNum
	NVAR currCh = root:V_currCh
	SVAR currPeak = root:S_currPeak
	
	strswitch ( ctrlName )
		case "FitOnePeak":
			Edges_GaussFit(currPeak, chrnum)
			DoWindow /F ChromPanel
			break
		
		case "FitAS":
			FindEdgesAS()
			break
		
		case "ApplyFitResults":
			ApplyFitResults()
			break

		case "InitialGuess":
			GaussFit_InitGuess()
			break
		
		case "resMatrix":
			GaussFitResultTable()
			break
		
	endswitch

End

Function ApplyFitResults()

	NVAR currCh = root:V_currCh
	SVAR currPeak = root:S_currPeak

	wave Res = $("root:" + currPeak + "_gaussRes")
	wave Hgt = $("root:" + currPeak + "_height")
	wave Are = $("root:" + currPeak + "_area")
	wave ret = $("root:" + currPeak + "_ret")
	wave ASall = $"root:AS:CH" + num2str(currCh) + "_All"
	variable i

	Make /o/d/n=9 coefAll, coefBase

	Hgt = Res[p][2]
	ret = Res[p][3]

	// calculate area
	for(i=0; i<numpnts(ASall); i+=1)
		string chromStr = "root:chroms:" + ChromName(currCh, i)
		if ( WaveExists($chromStr) )
			wave chrom = $chromStr
			if ( exists("full_fit") != 1)
				duplicate /o chrom, full_fit, base_fit
			endif
			coefAll = Res[i][p]
			coefBase = Res[i][p]
			coefBase[2] = 0
			full_fit = GaussPeakFit(coefAll, x)
			base_fit = GaussPeakFit(coefBase, x)
			full_fit -= base_fit
			full_fit = SelectNumber(numtype(full_fit)==0, 0, full_fit)
			are[i] = area(full_fit)
		endif
	endfor
	
	ResponseAS()
	
	Killwaves coefAll, coefBase, full_fit, base_fit

end

Function GaussFitResultTable() 
	PauseUpdate; Silent 1		// building window...

	NVAR currCh = root:V_currCh
	SVAR currPeak = root:S_currPeak
	
	string info = TableInfo("GaussFitTable", 1)
	string mol = StringByKey("IntCoef", StringByKey("WAVE", info), "_", ":")
	if (strlen(mol) <= 0)
		abort "Can determine which molecule you are working on.  Function needs a \"Gauss Fit Params\" table."
	endif
//	DoWindow /F GaussFitTable

	variable ch = returnChannel(mol)
	currCh = ch
	
	// makes sure the displayed peak is the same as from the Gauss Fit Table
	if ( cmpstr(currPeak, mol) != 0 )
		currPeak = mol
		MANpanel()
		DoWindow /F GaussFitTable
	endif
	
	String ASall = "root:AS:CH" + num2str(ch) + "_All"
	String Res = "root:" + mol + "_gaussRes"
	String Win = mol + "GaussFitResults"
	
	DoWindow /K $Win
	Edit/K=1/W=(12,51,939,499) $ASall,$Res as  mol + " Gauss Fit Results"
	ModifyTable style($ASall)=1,rgb($ASall)=(0,0,65535)
	DoWindow /C $Win

EndMacro

// wrapper procs for Macros menu
Proc FindRetOnePeak_Proc(mol, chrnum)
	string mol = S_currPeak 
	variable chrnum = V_chromNum
	prompt mol, "Molecule", popup, WaveToList("root:DB:DB_mols", ";")
	prompt chrnum, "Chrom number"
	
	print "Ret = ", FindRetOnePeak(mol, chrnum)
end

Proc Edges_TangentSkim_Proc(mol, chrnum)
	string mol = S_currPeak
	variable chrnum = V_chromNum
	prompt mol, "Molecule", popup, WaveToList("root:DB:DB_mols", ";")
	prompt chrnum, "Chrom number"

	silent 1
	
	variable ch = returnChannel(mol)
	variable ResRow = ReturnResRowNumber( ch, chrnum )
	
	string pkStart = ("root:" + mol + "_Start")
	string pkStop = ("root:" + mol + "_Stop")

	Edges_TangentSkim(mol, chrnum)
	print "Tangent Skim -- Start:", $pkStart[ResRow], "Stop:", $pkStop[ResRow]

end

Proc Edges_FixedStart_Proc(mol, chrnum)
	string mol = S_currPeak
	variable chrnum = V_chromNum
	prompt mol, "Molecule", popup, WaveToList("root:DB:DB_mols", ";")
	prompt chrnum, "Chrom number"

	silent 1
	
	variable ch = returnChannel(mol)
	variable ResRow = ReturnResRowNumber( ch, chrnum )
	
	string pkStart = ("root:" + mol + "_Start")
	string pkStop = ("root:" + mol + "_Stop")

	Edges_FixedStart(mol, chrnum)
	print "Tangent Skim Fixed Start -- Start:", $pkStart[ResRow], "Stop:", $pkStop[ResRow]

end

Proc Edges_FixedStop_Proc(mol, chrnum)
	string mol = S_currPeak
	variable chrnum = V_chromNum
	prompt mol, "Molecule", popup, WaveToList("root:DB:DB_mols", ";")
	prompt chrnum, "Chrom number"

	silent 1
	
	variable ch = returnChannel(mol)
	variable ResRow = ReturnResRowNumber( ch, chrnum )
	
	string pkStart = ("root:" + mol + "_Start")
	string pkStop = ("root:" + mol + "_Stop")

	Edges_FixedStop(mol, chrnum)
	print "Tangent Skim Fixed Stop -- Start:", $pkStart[ResRow], "Stop:", $pkStop[ResRow]

end

Proc Edges_FixedWindow_Proc(mol, chrnum)
	string mol = S_currPeak
	variable chrnum = V_chromNum
	prompt mol, "Molecule", popup, WaveToList("root:DB:DB_mols", ";")
	prompt chrnum, "Chrom number"

	silent 1
	
	variable ch = returnChannel(mol)
	variable ResRow = ReturnResRowNumber( ch, chrnum )
	
	string pkStart = ("root:" + mol + "_Start")
	string pkStop = ("root:" + mol + "_Stop")

	Edges_FixedWindow(mol, chrnum)
	print "Fixed Window -- Start:", $pkStart[ResRow], "Stop:", $pkStop[ResRow]

end

Function DisplayChromTmp()

	if (!WaveExists($"root:chroms:chromTmp"))
		abort
	endif
	DoWindow /K chromTmpPlot

	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:chroms:
	Display /K=1/W=(104,151,646,477) chromTmp as "chromTmp"
	SetDataFolder fldrSav0
	ModifyGraph gfSize=14,wbRGB=(56797,56797,56797)
	Label left "Response"
	Label bottom "Time"

	DoWindow /C chromTmpPlot

end