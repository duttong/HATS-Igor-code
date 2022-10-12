#pragma rtGlobals=2		// Use modern global access method.
#include <Strings as Lists>
#include <remove points>
#include <concatenate waves> 

////////////////////////////////////

menu "macros"
	"RemoveMSColumnFLM"
	"SetToValue"
	"SetToPoly"
	"ReplaceCurrentValue"
	"Replace A with B conditonal C"
	 "Replace A with B condition NAN C"
	"RuberbandToOffset_Win"
	"RuberbandTo_Value"
	"Imbed Prim To Secod Sink Time"
end
///////////////////////////////////////////////////////////////////
function ImbedPrimToSecodSinkTime(wwaveP,wwaveS,wwaveTP,wwaveTS)
	string wwaveP, wwaveS,  wwaveTP, wwaveTS
	variable nP, nS, nPstop, nSstop
	wave waveP = $wWaveP
	wave waveS = $wWaveS
	wave waveTP = $wWaveTP
	wave waveTS = $wWaveTS
	nPstop = numpnts(waveTP)
	nSstop = numpnts(waveTS)
	silent 1
	nP =0
	nS=0
	do
		do  
			nS +=1 
			if (nS == nSstop)
				break
			endif	
		while (waveTS[nS] <= waveTP[nP]) 
		
		waveS[nS] = waveP[nP]
		do 
			nP +=1
			if (nP == nPstop)
				break
			endif
		while  (waveTP[nP] <= waveTS[nS] )
				
	while (nP< nPstop)
	killwaves waveP				
end
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
//proc ImbedPrimToSecodSinkTime(waveP,waveS,waveTP,waveTS)
//	string waveP, waveS,  waveTP, waveTS,
//	variable nP, nS, nPstop
//	nPstop = numpnts($waveTP)
//	silent 1
//	nP =1
//	nS=1
//	do
//		do  
//			nS +=1
		while ($waveTS[nS] <= $waveTP[nP])	
		$waveS[nS] = $waveP[nP]
		nP +=1
	while (nP< nPstop)
	killwaves $waveP				
end
///////////////////////////////////////////////////////////////

function RemoveSpikInMarque() : GraphMarquee
	string ywvlst, xwvlst, fitType="poly 3"
//	prompt ywvlst, "Y-axis wave", popup, TraceNameList("", ";", 1)
//	prompt xwvlst, "X-axis wave", popup "_none_;"+TraceNameList("", ";", 0)
//	prompt fitType,"Fit type:", popup,"gauss;lor;exp;dblexp;sin;line;poly 3;poly 4;poly 5;poly 6;poly 7;poly 8;poly 9"
//	DoPrompt "Fit Points In Marquee", ywvlst, fitType
	
	ywvlst = StringFromList(0,TraceNameList("", ";", 1))
	 print ywvlst
	wave wvY = TraceNameToWaveRef("", ywvlst)
	duplicate/o wvY wvYRisid
	string com
	variable nnow=1, PRstart = 1,PRstop = 1
	
	GetMarquee left, bottom
	
	// check for XY pairing
	if ( WaveExists(XWaveRefFromTrace("", ywvlst)) )
		wave wvX = XWaveRefFromTrace("", ywvlst)
		Extract /O wvY, JunkY, ( (wvX > V_left) && (wvX < V_right) && (wvY < V_top) && (wvY > V_bottom) )
		Extract /O wvX, JunkX, ( (wvX > V_left) && (wvX < V_right) )
		variable first = JunkX[0]
		JunkX -= first
		sprintf com, "CurveFit /Q  %s,  JunkY /X=JunkX /D", fitType
		execute com
		SetScale/I x first,first+pnt2x(fit_JunkY, numpnts(fit_JunkY)), "", fit_JunkY
		Duplicate /o fit_JunkY, $"fit_" + ywvlst
		//AppendToGraph $"fit_" + ywvlst
	else
		Make /O/n=(numpnts(wvY)) JunkXorg = pnt2x(wvY, p)
		Extract /O wvY, JunkY, ( (pnt2x(wvY, p) > V_left) && (pnt2x(wvY,p) < V_right) && (wvY < V_top) && (wvY > V_bottom) )
		Extract /O JunkXorg, JunkX, ( (JunkXorg > V_left) && (JunkXorg < V_right)  && (wvY < V_top) && (wvY > V_bottom) )
		sprintf com, "CurveFit /Q %s, JunkY  /X=JunkX /D", fitType
		execute com
		Duplicate /o fit_JunkY, $"fit_" + ywvlst
		//AppendToGraph $"fit_" + ywvlst
	endif
	
	wvYRisid = wvY - poly(w_coef, pnt2X(wvY,P))
															// check for XY pairing  on residual wave
	if ( WaveExists(XWaveRefFromTrace("", ywvlst)) )
		wave wvX = XWaveRefFromTrace("", ywvlst)
		Extract /O wvYRisid, JunkY, ( (wvX > V_left) && (wvX < V_right) && (wvY < V_top) && (wvY > V_bottom) )
		Extract /O wvX, JunkX, ( (wvX > V_left) && (wvX < V_right) )
		 first = JunkX[0]
		JunkX -= first
	else
		Make /O/n=(numpnts(wvY)) JunkXorg = pnt2x(wvY, p)
		Extract /O wvYRisid, JunkY, ( (pnt2x(wvY, p) > V_left) && (pnt2x(wvY,p) < V_right) && (wvY < V_top) && (wvY > V_bottom) )
		Extract /O JunkXorg, JunkX, ( (JunkXorg > V_left) && (JunkXorg < V_right)  && (wvY < V_top) && (wvY > V_bottom) )	
	endif
	
	WaveStats /Q /z JunkY   								// wave stasts on risidual wave to get V_sdev
	
	PRstart = 3+x2pnt(wvY, V_left)
	PRstop = x2pnt(wvY, V_right) -3
	nnow = PRstart
	
	do  													// replace points 2 Sdev away
		if  (abs(wvYRisid[nnow]) > (2* V_sdev))
		wvY[nnow] = poly(w_coef, pnt2X(wvY,nnow))
		endif
		nnow += 1							
	while (nnow <= PRstop)
	Killwaves /Z fit_JunkY, JunkXorg,  JunkY, JunkX
end

proc RemoveMSColumnFLM(ColumnNum,LastRow, FirstRow)
	string ColumnNum
	variable  ClmNum, LastRow = 200, FirstRow= 0 
	prompt ColumnNum, "Deleat Which Column (2 for above 9)", popup "0;1;2"
	prompt FirstRow, "FirstRow"
	prompt LastRow, "LastRow"
	ClmNum = str2num(ColumnNum)
	silent 1;pauseupdate
	RRemoveColumnNFLM(ClmNum,LastRow, FirstRow)
end 

//proc RemoveFlagedNegSelPosFromDB(ColumnNum,LastRow, FirstRow)
	string ColumnNum
	variable  ClmNum, LastRow = 200, FirstRow= 0 
	prompt ColumnNum, "Deleat flagged NEG selpos rows", popup "-1"
	prompt FirstRow, "FirstRow"
	prompt LastRow, "LastRow"
	ClmNum = str2num(ColumnNum)
	silent 1;pauseupdate
	RRemoveColumnNFLM(ClmNum,LastRow, FirstRow)
end 

//Function RRemoveColumnNFLM(ColumnNum, LastRow, FirstRow)
	variable  ColumnNum, LastRow, FirstRow
	variable Row
	wave selpos
	Row = LastRow
	
	do
		if (ColumnNum == 2)
			if (Selpos(Row) > 9 )
			 FdeleteDBrowsFUNCT(Row, Row)	
			endif
			
		elseif (ColumnNum == 1)	
			if  (Selpos(Row) > 0 )
				if (Selpos(Row) < 9 )
				 FdeleteDBrowsFUNCT(Row, Row)	
				endif
			endif
			
		elseif(ColumnNum == 0)
			if  (Selpos(Row) < 1 )
			 FdeleteDBrowsFUNCT(Row, Row)	
			 endif
		elseif(ColumnNum == -1)
			if  (Selpos(Row) < 0 )
			 FdeleteDBrowsFUNCT(Row, Row)	
			 endif
		else
		endif
		Row-=1
	while (Row >= FirstRow)						
end
	
// converted to function.  GSD 951008
// changed name added NVAR statments and comented out doAlert for YES RESPONCE.
//function FdeleteDBrowsFUNCT(strtRow, endRow)
	variable strtRow, endRow
	Variable dbLength, dbFinalLength,nCols, toRow, fromRow, inc=0
	string colNm, com, dbrowlst
	
	NVAR G_dbLen = G_dbLen
	NVAR G_nDets = G_nDets
	NVAR G_rowRngMin = G_rowRngMin
	NVAR G_rowRngMax = G_rowRngMax
	
	dbLength = G_dbLen
	
	if (strlen (WinList ("scanChroms",";", "")) > 0)
		doAlert 1, "You must close the manual integration window before running this macro.  May I close it for you??"
		if (V_flag == 1)
			doWindow /K scanChroms
		else
			return 1
		endif
	endif
			
	if (strtRow > endRow)
		doAlert 0, "First row to delete can not be greater than last row to delete.  Doesn't that make sense?"
		return 1
	endif
	
	if (endRow >= dbLength)
		doAlert 0, "Last row to delete must not exceed last database row (which is "+num2str(dbLength-1)+").  Better try again."
		return 1
	endif
	
	if (strtRow < 0)
		doAlert 0, "Do you really want to delete a row less than zero (there aren't any, you know).  Lets try again."
		return 1
	endif
		
	fromRow = endRow + 1
	toRow = strtRow
	dbFinalLength = dbLength -(fromRow - toRow)

	if (dbFinalLength < 2)
		doAlert 0,"You can not delete so many rows that the database would have fewer than two (2) rows."
		return 1
	endif
	
	//doAlert 1,"You are going to delete rows: "+num2str(strtRow)+" to "+num2str(endRow)+".  The resulting DB will have "+num2str(dbFinalLength)+" rows (of "+num2str(dbLength)+" original rows).  Continue ???"
	//if (V_flag != 1) 
	//	return 1
	//endif
	
	//
	// Shift db column data (waves), and delete rows.
	//
	fromRow = endRow + 1
	toRow = strtRow

	nCols = saLen ("dbColLst")
	do
		colNm = saGet ("dbcollst", inc)
		//  !!!!!!!! I dont work so nether does this rutine!!!!!!!!!
		// deleteDBsubfunction($colNm, toRow, fromRow, dbFinalLength)
		inc += 1
	while (inc < nCols)

	//
	// Delete the rows from the dbrowlsts by clearing them.
	//
	inc = 0
	if (G_nDets > 0)
		do
	 		dbrowlst = saGet ("dbRowLstLst", inc)
			saClear (dbrowlst, strtRow, endRow)
			inc += 1
		while (inc < G_nDets)
	endif
	
	G_dbLen = dbFinalLength

	G_rowRngMin = 0
	G_rowRngMax = dbFinalLength - 1

	// Keeps the active set definition panel consistent with the number of rows in the DB, if it is displayed.
	if (strlen (WinList ("defineASpanel",";", "")) > 0)
		doWindow /F defineASpanel
		SetVariable rowRngMin,limits={0,dbFinalLength,1}
		SetVariable rowRngMax,limits={0,dbFinalLength,1}
	endif
	
	return 0
	
end

proc SetToValue(wavestring, nstart, nstop, value)
	string wavestring
	variable nstart, nstop, nnow, value
	
	// prompt wavestring, "what wave"
	// prompt nstart, "FirstRow"
	// prompt nstop, "LastRow"
	// prompt value, "new value ="
	// prompt wavestring, "what wave"
	
	silent 1

	nnow = nstart
	do  
		//$wavestring[nnow] = poly(w_coef, nnow)
		$wavestring[nnow] = value
		nnow += 1							
	while (nnow <= nstop)				
end

proc SetToPoly(wavestring, nstart, nstop)
	string wavestring
	variable nstart, nstop, nnow
	
	// prompt wavestring, "what wave"
	// prompt nstart, "FirstRow"
	// prompt nstop, "LastRow"
	// prompt value, "new value ="
	// prompt wavestring, "what wave"
	
	silent 1

	nnow = nstart
	do  
		$wavestring[nnow] = poly(w_coef, nnow)
		//$wavestring[nnow] = value
		nnow += 1							
	while (nnow <= nstop)				
end


function  ReplaceCurrentValue(wwavestring, nstart, nstop, valueCurrent,valueNew)
	string wwavestring
	variable nstart, nstop, valueNew, valueCurrent
	// prompt wavestring, "what wave"
	// prompt nstart, "FirstRow"
	// prompt nstop, "LastRow"
	// prompt value, "new value ="
	// prompt wavestring, "what wave"
	wave wavestring = $wwavestring
	variable nnow
	silent 1

	nnow = nstart
	do  
		if (wavestring[nnow] == valueCurrent)
		//$wavestring[nnow] = poly(w_coef, nnow)
		wavestring[nnow] = valueNew
		endif
		nnow += 1							
	while (nnow <= nstop)				
end

proc ReplaceAwithBconditonalC(waveA,waveB,waveC, nstart, nstop, ValueC)
	string waveA,waveB,waveC
	variable nstart, nstop, nnow, ValueC
	// prompt wavestring, "what wave"
	// prompt nstart, "FirstRow"
	// prompt nstop, "LastRow"
	// prompt value, "new value ="
	// prompt wavestring, "what wave"
	
	silent 1

	nnow = nstart
	do  
		if ($waveC[nnow] == ValueC)
		//$wavestring[nnow] = poly(w_coef, nnow)
		$waveA[nnow] = $waveB[nnow]
		endif
		nnow += 1							
	while (nnow <= nstop)				
end

proc ReplaceAwithBconditionNANC(waveA,waveB,waveC, nstart, nstop)
	string waveA,waveB,waveC
	variable nstart, nstop, nnow
	silent 1

	nnow = nstart
	do  
		if ( numtype($waveC[nnow] ) == 2)
		$waveA[nnow] = $waveB[nnow]
		endif
		nnow += 1							
	while (nnow <= nstop)				
end


proc RuberbandToOffset_Win(wavestring,offset, Iancore,Ioffset)
	string wavestring
	variable offset, ancore,konstant
	variable Iancore, Ioffset, Idelta, i
	ancore = $wavestring(Iancore)
	
	i=Iancore
	if (Iancore < Ioffset)
		Idelta  = Ioffset-Iancore
		do
			$wavestring (i)=$wavestring(i) + offset*((i-Iancore)/Idelta)
			i += 1
		while (i <= Ioffset)
	else 
		Idelta = Iancore - Ioffset
		do
			$wavestring (i)=$wavestring(i) + offset*((Iancore-i)/Idelta)
			i -=1
		while (i >= Ioffset)
	endif
end

proc RuberbandTo_Value(wavestring, ValueAtAncore, ValueAtOffset, Offset, Istart, Iend)
	string wavestring
	variable Above_Below
	variable ValueAtOffset, ValueAtAncore, Offset, Correction,Istart,Iend
	variable  Delta, i
	silent 1;pauseupdate
	i=Istart
	delta  = ValueAtOffset - ValueAtAncore
	if (ValueAtAncore < ValueAtOffset)
		do
			if ($wavestring (i) > ValueAtAncore)
				$wavestring (i)=$wavestring(i) + (offset*($wavestring (i) - ValueAtAncore))/Delta
			endif
			i += 1
		while (i <= Iend)
	endif
	
	if (ValueAtAncore > ValueAtOffset )
		do
			if ($wavestring (i) < ValueAtAncore)
				$wavestring (i)=$wavestring(i) + (offset*($wavestring (i) - ValueAtAncore))/Delta
			endif
			i += 1
		while (i <= Iend)
	endif
	
end

proc GapSmoothChroms(det, type, iter,ns,ne)
	variable det = 1, iter=15, type=2, ns=166, ne=366
	prompt det, "Channel:", popup, ListNLong(V_chans,";")+"all"
	prompt type, "Smoothing", popup, "Binomial;Box;2nd Order Savitzky-Golay;4th Order Savitzky-Golay"
	prompt iter, "Iterations.  (There are some limitations depending on smoothing type)"
	prompt ns, "Start point"
	prompt ne, "End point"
	silent 1
	
	GapSmoothChromsFUNCT(det, type, iter, ns,ne)

end
		
function GapSmoothChromsFUNCT(det, type, iter,ns,ne)
	variable det, iter, type,ns,ne
	
	string chrom, stype, com, comment
	variable inc, smoothinc, ch
       Variable nv
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
	do
		chrom = GetIndexedObjName(":", 1, inc)
		
		if (strlen(chrom) == 0)
			break
		endif
          
		if (CmpStr (chrom[0,1], "CH") == 0)
			if (( str2num(chrom[3,3]) == det ) || ( det == V_chans+1))
					   duplicate /o $chrom  backup
				sprintf com, "Smooth %s %d, %s", stype, iter, chrom
				execute com
					duplicate /o $chrom  backupsmooth
						nv =ns
						do
							backup[nv] = backupsmooth[nv]
						nv += 1
						while (nv <= ne )
					duplicate /o backup $chrom  
				sprintf com, "GAP Smoothed (%s, %d,%d,%d) %s, %s", comment, iter, ns,ne,time(), date()
				Note $chrom, com
					nv =ns
					do
						backup[nv] = backupsmooth[nv]
					nv += 1
					while (nv <= ne )
				   
				smoothinc += 1
				
			endif
		endif
		
		inc += 1

	while (1)
	
	print smoothinc, " chromatograms GAP smoothed."
	
	SetDataFolder root:
	
end

