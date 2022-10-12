#pragma rtGlobals=1		// Use modern global access method.
#include <median>

Function IntegrateOnePeak(mol, chrnum)
	variable chrnum
	string mol
	
	variable ch = returnChannel(mol)
	variable ResRow = ReturnResRowNumber(ch, chrnum)
	
	// non existant peak
	if ( ch < 1 )
		return NaN
	endif
	
	wave pkStart = $("root:" + mol + "_Start")
	wave pkStop = $("root:" + mol + "_Stop")
	wave retwv = $("root:" + mol + "_ret")
	wave are = $("root:" + mol + "_area")
	wave hgt = $("root:" + mol + "_height")

	wave DBedgePoints = root:DB:DB_edgePoints

	variable edgeAvg = DBedgePoints[returnMolDBrow(mol)]
	edgeAvg = edgeAvg * 2 - 2

	variable ret = retwv[ResRow]
	variable startX = pkStart[ResRow], medStartY
	variable stopX = pkStop[ResRow], medStopY
	variable Defstart = ReturnPeakStartPt(mol, chrnum)		// uses defined peak start point. (ie N2O_start)
	variable Defstop = ReturnPeakStopPt(mol, chrnum)
	

	String savedf = GetDataFolder(1)
	SetDataFolder root:chroms
	
	// make sure the chromatogram exists
	string chrom = "chr" + num2str(ch) + "_" + PadStr(chrnum, 5, "0")
	if (! exists(chrom))
		SetDataFolder savedf
		return NaN
	endif
	wave chromWv = $chrom
	
	// bad start or stop
	if ( (numtype(startX) != 0) && (numtype(stopX) != 0 ))
		are[ResRow] = Nan
		hgt[ResRow] = NaN
		SetDataFolder savedf
		return NaN
	endif
	
	// re-find retention time (in case peak start and/or stop changed).
	retwv[ResRow] = FindRetOnePeak(mol, chrnum)
	
	duplicate /O/R=[x2pnt(chromWv,DefStart)-edgeAvg/2, x2pnt(chromWv, DefStop)+edgeAvg/2] chromWv, chromTmp
	
	// median of the start and stop points
	medStartY = Median(chromTmp, pnt2x(chromTmp, 0), pnt2x(chromTmp, edgeAvg-1))
	medStopY = Median(chromTmp, pnt2x(chromTmp, (numpnts(chromTmp)-1) - edgeAvg), pnt2x(chromTmp, numpnts(chromTmp)-1))
	
	// subtract baseline
	variable m = (medStopY - medStartY) / (DefStop - DefStart)
	variable b = medStartY - m*startX
	chromTmp -= (b + m*x)
	
	// area
	are[ResRow] = Area(chromTmp, startX, stopX)
	
	// height
	ret = retwv[ResRow]
	if (numtype(ret) == 0)
//		wavestats /Q/R=[x2pnt(chromTmp, ret)-edgeAvg/2, x2pnt(chromTmp, ret)+edgeAvg/2] chromTmp
//		hgt[ResRow] = V_avg
		hgt[ResRow] = chromTmp(ret)
	else
		hgt[ResRow] = Nan
	endif
	
	SetDataFolder savedf

	return 1

end

Function IntegrateAS()

	wave DBactive = root:DB:DB_activePeak
		
	NVAR numCh = root:V_chans
	
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

				// integrate in active set only
				wave AS = $("root:AS:CH" + num2str(ch) + "_AS")
				ASinc = 0
				do
					if ( numpnts(AS) == 0 )
						break
					endif

					ResRow = ReturnResRowNumber( ch, AS[ASinc] )
					
					// integrate bad flags are not set
					// removed the logic that included  the manual flag (gsd 061101)
					if (! flagBad[ResRow]) 
						IntegrateOnePeak( mol, AS[ASinc] )
					endif
				
					ASinc += 1
				while (ASinc < numpnts(AS))
				
			endif
			molinc += 1
		while ( molinc < ItemsInList(molLst))
	endfor

end
