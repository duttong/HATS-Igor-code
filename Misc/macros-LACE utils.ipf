function Insertvalue (compwv, inswv, compVal, insVal)
	wave compwv, inswv
	variable compVal, insVal
	
	variable nComp = numpnts (compwv), nIns = numpnts (inswv)
	
	if (nComp != nIns ) 
		printf  "Wave:  %s and Wave:  %s are not the same length. ", NameOfWave(compwv), NameOfWave(inswv)
		abort "The compare wave and the insert wave are not the same length"
	endif
	
	do
		nComp -= 1
		if ( compwv[nComp] == compVal )
			inswv[nComp] = insVal
		endif
	while (nComp != 0)

end

proc MakeWaveNoteWaves(detNum, strtChrm, endChrm)
	variable detNum, strtChrm=1, endChrm=G_rowRngMax
	prompt detNum, "Detector number", popup "1;2"
	prompt strtChrm, "Start Chromatogram"
	prompt endChrm, "Last Chromatogram"

	silent 1;pauseupdate

	variable chrNm = strtChrm
	string chr, pad, nt
	string press = ("det" + num2str(detNum) + "_injpress")
	string temp = ("det" + num2str(detNum) + "_injtemp")

	do	
		if (chrNm < 10)
			pad = "0000"
		endif
		if (chrNm > 9) * (chrNm < 100) 
		      pad = "000"
		endif
		if (chrNm > 99) * (chrNm < 1000) 
			pad = "00"
		endif

		chr = "chr" + num2str(detNum) + "_" + pad + num2str(chrNm)
		
		if (exists(chr) != 0) 
			nt = Note($chr)
			if (strlen(nt) > 0) 
				$press[chrNm] = str2num(GetStrFromList(nt,5,";"))
				$temp[chrNm] = str2num(GetStrFromList(nt,6,";"))
			endif
		else
		       print chr +" does not exist."
		endif
		
		chrNm += 1
		
	while (chrNm <= endChrm)
	
end

|Calculates for the AS the Response per mole of air = Peak area*injTemp/injPress  and writes it to the
|response DB column
Proc CalculateASResponse(attrib, useTemp, constTemp)
	string attrib="both"
	variable useTemp=2, constTemp=35
	prompt attrib, "Calc Resp with: ", popup "area;hght;both"
	prompt useTemp, "Use const temperature in resp?", popup "yes;no"
	prompt constTemp, "If yes, what temp in oC"
	
	silent 1; PauseUpdate
	
	if (cmpstr(attrib,"both") == 0)
		CalculateASResponseFUNCT("Area", useTemp, constTemp)
		G_noAlert=1
		cmvCopyAPcols("resp", "respArea")
		G_noAlert = 0
		CalculateASResponseFUNCT("Hght", useTemp, constTemp)
		G_noAlert=1
		cmvCopyAPcols("resp", "respHght")
		G_noAlert = 0
	else
		CalculateASResponseFUNCT(attrib, useTemp, constTemp)
	endif
end

Function CalculateASResponseFUNCT(attrib, useTemp, constTemp)
	string attrib
	variable useTemp, constTemp
	
	string chr, pkNm
	variable resp, area, temp, press
	
	NVAR ANYCHROMS = ANYCHROMS
	NVAR ERRVAL = ERRVAL
	NVAR G_activePkN = G_activePkn
	NVAR G_activeDetN = G_activeDetN
	NVAR G_activeRowN = G_activeRowN
	NVAR G_noAlert = G_noAlert
	
	resetNxtChromByActivePeak ()
	do
		chr = nxtChromByActivePeak (ANYCHROMS)			| Chromatogram does not need to be loaded.
		if (CmpStr (chr, "¯"))
	
			pkNm = saGet ("pkNmLst", G_activePkN)
			
			wave areaCol=$(pkNm + "_" + attrib)
			wave tempWv=$("det" + Num2Str(G_activeDetN) +"_injTemp")
			wave pressWv=$("det" + Num2Str(G_activeDetN) + "_injpress")
			
			area = dbRetChk(areaCol, G_activeRowN)
			temp = tempWv[G_activeRowN] 
			press = pressWv[G_activeRowN]
			
			if ((temp==ERRVAL)+(temp<=0)+(press==ERRVAL)+(press<=0)+(area==-1))
				resp = -1
			else
				if (useTemp == 1)
					resp = area*(constTemp + 273.15)/press
				else
					resp = area*(temp + 273.15)/press
				endif	
			endif
			
			dbIns($pkNm+"_resp", G_activeRowN, resp)
			
		endif
		
	while (CmpStr (chr, "¯"))

	chkProtWarn ()	
	
	G_noAlert=1
	cmvCopyAPcols("resp", "resp_org")		|"resp_org" is the true response, i.e. directly calculated from the areas
	G_noAlert=0
End

proc ShiftTheChrom (strtChrom, endChrom, appPoints, offset, det)
	variable strtChrom=1, endChrom=G_rowRngMax, appPoints=80, offset=8, det=2
	prompt strtChrom, "First Chromatogram"
	prompt endChrom, "Last Chromatogram"
	prompt appPoints, "Number of points to append from next chrom"
	prompt offset, "Number of points lost"
	prompt det, "Detector"

	silent 1; pauseupdate
	variable oldFitOpts
	
	if (exists("V_FitOptions") != 2)
		variable /g V_FitOptions=4
		oldFitOpts = 0
	else
		oldFitOpts = V_FitOptions
	endif
	V_FitOptions = 4
	
	ShiftTheChromFUNCT (strtChrom, endChrom, appPoints, offset, det)
	
	V_FitOptions = oldFitOpts
end

function ShiftTheChromFUNCT (strtChrom, endChrom, appPoints, offset, det)
	variable strtChrom, endChrom, appPoints, offset, det
	
	variable chrNm = strtChrom+1, numpnts1, numpnts2
	string chr1, chr2, detStr = num2str(det)
	
	wave W_coef = W_coef
	
	do
		chr1 = "chr" + detStr + "_" + NumPad(chrNm-1) + num2str(chrNm-1)
		chr2 = "chr" + detStr + "_" + NumPad(chrNm)  + num2str(chrNm)
		wave chrom1 = $chr1
		wave chrom2 = $chr2
		numpnts1 = numpnts(chrom1)
		InsertPoints numpnts1, appPoints+offset, chrom1
		chrom1[numpnts1,numpnts1+offset] = nan
		chrom1[numpnts1+offset,numpnts1+offset+appPoints] = chrom2[p-numpnts1-offset]
		CurveFit /q gauss chrom1(pnt2x(chrom1,numpnts1-offset*3),pnt2x(chrom1,numpnts1+offset*3))
		chrom1[numpnts1-offset/2,numpnts1+offset+offset/2] = W_coef[0]+W_coef[1]*exp(-((x-W_coef[2])/W_coef[3])^2)
		chrNm += 1
		DeletePoints 0, appPoints, chrom1
	while (chrNm <= endChrom)
end

function/s NumPad (chrNm)
	variable chrNm
	
	string pad
	
	if (chrNm < 10)
		pad = "0000"
	endif
	if (chrNm > 9) * (chrNm < 100) 
	      pad = "000"
	endif
	if (chrNm > 99) * (chrNm < 1000) 
		pad = "00"
	endif

	return pad
end	

proc BackupChroms (det)
	string det
	prompt det, "Channel", popup, ListNLong(G_nDets,";")+"all"
	
	silent 1; pauseUpdate
	variable DetInc = 1
	
	if (cmpstr(det,"all") == 0)
		do
			bat("duplicate @ B@","chr"+num2str(DetInc)+"_?????")
			DetInc += 1
		while (DetInc <= G_nDets)
	else
		bat("duplicate @ B@","chr"+det+"_?????")
	endif
end

proc RestoreChroms (det)
	string det
	prompt det, "Channel", popup, ListNLong(G_nDets,";")+"all"
	
	silent 1; pauseUpdate
	variable DetInc = 1

	// Do backups exist
	if (cmpstr(det,"all") == 0)
		if (exists("Bchr1_00002") != 1)
			abort "I don't think you backed up the chroms.  Run \"BackupChroms\""
		endif
	else
		if (exists("Bchr"+det+"_00002") != 1)
			abort "I don't think you backed up the chroms.  Run \"BackupChroms\""
		endif
	endif
	
	if (cmpstr(det,"all") == 0)
		do
			bat("duplicate /o B@ @","chr"+num2str(DetInc)+"_?????")
			DetInc += 1
		while(DetInc <= G_nDets)
	else
		bat("duplicate /o B@ @","chr"+det+"_?????")
	endif
end	
