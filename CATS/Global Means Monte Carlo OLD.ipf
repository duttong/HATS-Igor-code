#pragma rtGlobals=1		// Use modern global access method.

/// Function below are for Monte Carlo simulation where a fraction of the original data is used to calculate
/// hemispheric and global means as well as global growth rate

menu "Monte-Carlo"
	"Run simulation",MC_Simulation()
	"Display Previous simulation", DisplayMC_Matrix()
end


function MC_Simulation([sims, frac, type, loc, insts, mol, prefix])
	variable sims, frac, type 
	string loc, insts
	string prefix, mol

	SVAR mollst = root:G_molLst
	SVAR Gmol = root:G_mol
	SVAR GinstList = root:global:S_InstList
	SVAR Gpre = root:global:S_prefix
	NVAR MCsim = root:simulation:G_MC
	
	if ( ParamIsDefault(sims) )
		sims = 500
		frac = 0.3
		type = 4
		insts = "CATS+RITS+OTTO+OldGC"
	endif
	if ( ParamIsDefault(mol) )
		mol = Gmol
	endif
	if ( ParamIsDefault(prefix) )
		prefix = Gpre
	endif
	Prompt sims, "Number of simulations"
	Prompt frac, "Fraction of original data effected"
	Prompt type, "Which simulation", popup, "Remove Data;Change Data;Both;Adjust Lats"
	Prompt loc, "Region", popup, "Global;NH;SH;BRW"
	Prompt insts, "Select a set of instruments", popup, AllInsts
	Prompt mol, "Which gas?", popup, mollst
	Prompt prefix, "Name waves with the following prefix:"

	DoPrompt "Global Mean Monte Carlo:", sims, frac, type, loc, insts, mol, prefix
	if (V_flag)
		return -1
	endif
	
	string txt
	sprintf txt, "MC_Simulation(sims=%d, frac=%f, type=%d, loc=\"%s\", insts=\"%s\", mol=\"%s\", prefix=\"%s\")", sims, frac, type, loc, insts, mol, prefix
	print txt

	Variable timerRefNum, microSeconds
	timerRefNum = startMSTimer

	Gmol = mol
	Gpre = prefix
	GinstList = insts

	Variable i, NumSimulations = sims, RemoveFraction = frac
	String cmd, nte

	String Gpath = "root:global:"
	String MCstr = prefix + "_GlobalMC" + num2str(type) + "_" + mol
	String MCgrstr = prefix + "_GlobalMC" + num2str(type) +"gr_" + mol
	String MCNHstr = prefix + "_NHMC" + num2str(type) + "_" + mol
	String MCNHgrstr = prefix + "_NHMC" + num2str(type) +"gr_" + mol
	String MCSHstr = prefix + "_SHMC" + num2str(type) + "_" + mol
	String MCSHgrstr = prefix + "_SHMC" + num2str(type) +"gr_" + mol
	String MCBRWstr = prefix + "_BRWMC" + num2str(type) + "_" + mol
	String MCBRWgrstr = prefix + "_BRWMC" + num2str(type) + "gr_" + mol
	
	NewDataFolder /O/S root:simulation
	MCsim = 1
	Make /n=(0,NumSimulations) /o $MCstr/WAVE=MC, $MCgrstr/WAVE=MCgr
	Make /n=(0,NumSimulations) /o $MCNHstr/WAVE=MCNH, $MCNHgrstr/WAVE=MCNHgr
	Make /n=(0,NumSimulations) /o $MCSHstr/WAVE=MCSH, $MCSHgrstr/WAVE=MCSHgr
	Make /n=(0,NumSimulations) /o $MCBRWstr/WAVE=MCBRW, $MCBRWgrstr/WAVE=MCBRWgr
	SetDataFolder root:

	for(i=0; i<NumSimulations; i+=1)
		SaveOriginalData(insts, mol)
		
		// tweak data
		if (type == 1)
			RemoveSomeData(insts, mol, RemoveFraction)
			nte = "data removed"
		elseif (type == 2)
			ChangeSomeData(insts, mol, RemoveFraction)
			nte = "date changed"
		elseif (type == 3)
			ChangeSomeData(insts, mol, RemoveFraction)
			RemoveSomeData(insts, mol, RemoveFraction)
			nte = "data changed and removed"
		elseif (type == 4)
			ChangeSomeData(insts, mol, RemoveFraction)
			RemoveSomeData(insts, mol, RemoveFraction)
			MCsim = 4
			nte = "adjust latitudes 10-deg"
		else
			abort "wronge type"
		endif
		
		// global mean
		Global_Mean(prefix=prefix, insts=insts, mol=mol, plot=1, offsets=2)
		Wave glb = $Gpath + prefix + "_Global_" + mol
		Wave glbNH = $Gpath + prefix + "_NH_" + mol
		Wave glbSH = $Gpath + prefix + "_SH_" + mol
		Wave glbT = $Gpath + prefix + "_" + mol + "_date"
		Wave sites = $Gpath + prefix + "_Sites_" + mol			// sites matrix
		Variable col = WhichListItem("brw", AllSites)
		if (i==0)
			Redimension/N=(numpnts(glb),-1) MC, MCgr, MCNH, MCNHgr, MCSH, MCSHgr, MCBRW, MCBRWgr
			String BRWs = Gpath + prefix + "_BRW_" + mol
			Make /o/n=(DimSize(sites,0)) $BRWs/Wave=BRW, $BRWs+"_sd", $BRWs+"_gr", $BRWs+"_grsd"
			BRW = sites[p][col]
		endif
		
		// global growth rate
		SetDataFolder root:global
		GrowthRate(glb, glbT, 12, 0)
		GrowthRate(glbNH, glbT, 12, 0)
		GrowthRate(glbSH, glbT, 12, 0)
		GrowthRate(BRW, glbT, 12, 0)
		Wave glbgr = $Gpath + prefix + "_Global_" + mol + "_gr"
		Wave glbNHgr = $Gpath + prefix + "_NH_" + mol + "_gr"
		Wave glbSHgr = $Gpath + prefix + "_SH_" + mol + "_gr"
		Wave BRWgr = $Gpath + prefix + "_BRW_" + mol + "_gr"
		SetDataFolder root:
		
		MC[][i] = glb[p]
		MCgr[][i] = glbgr[p]
		MCNH[][i] = glbNH[p]
		MCNHgr[][i] = glbNHgr[p]
		MCSH[][i] = glbSH[p]
		MCSHgr[][i] = glbSHgr[p]
		MCBRW[][i] = sites[p][col]
		
		RestoreOriginalData(insts, mol)
		
		// a little feedback every 100 iters
		if ((mod(i,100) == 0) && (i>0))
			DisplayMC_Matrix(prefix=prefix, mol=mol, loc=loc, type=type, grth=1)
			TextBox/C/N=iters "iters: " + num2str(i)
			DoUpdate
		endif
		
	endfor
	
	// redo calcs with original full data sets
	MCsim = 0
	Global_Mean(prefix=prefix, insts=insts, mol=mol)
	SetDataFolder root:global
	GrowthRate(glb, glbT, 12, 6)
	SetDataFolder root:
	
	Sprintf cmd, "%d simulations\r%d-percent %s \r%s", NumSimulations, RemoveFraction*100, nte, insts
	Note MC, cmd
	Note MCgr, cmd
	Note MCNH, cmd
	Note MCNHgr, cmd
	Note MCSH, cmd
	Note MCSHgr, cmd
	
	DisplayMC_Matrix(prefix=prefix, mol=mol, loc=loc, type=type, grth=1)

	KillBackupData(insts)
	MCsim = 0
	
	microSeconds = stopMSTimer(timerRefNum)
	Print "It took ", num2str(microSeconds/1e6), " seconds to execute. "

	
end


function SaveOriginalData(insts, mol)
	string insts, mol
	
	variable i, w
	string inst, org, bak, wvs, wv
	
	insts = ReplaceString("+", insts, ";")
	
	SetDataFolder root:
	
	for(i=0; i<ItemsInList(insts); i+=1)
		inst = StringFromList(i, insts)
		
		org = inst
		if (cmpstr(inst, "CATS") == 0 )
			org = "month"
		endif
		bak = org + "_bak"
		
		NewDataFolder /O $"root:" + bak
		SetDataFolder $"root:" + org
		
		wvs = WaveList("*"+mol+"*", ";", "")
		for(w=0; w<ItemsInList(wvs); w+=1)
			wv = StringFromList(w, wvs)
			Duplicate/O $wv, $"root:"+bak + ":" +wv
		endfor
		
		SetDataFolder root:
		
	endfor
	
end


function RestoreOriginalData(insts, mol)
	string insts, mol
	
	variable i, w
	string inst, org, bak, wvs, wv
	
	insts = ReplaceString("+", insts, ";")
	
	SetDataFolder root:
	
	for(i=0; i<ItemsInList(insts); i+=1)
		inst = StringFromList(i, insts)
		
		org = inst
		if (cmpstr(inst, "CATS") == 0 )
			org = "month"
		endif
		bak = org + "_bak"
		
		SetDataFolder $"root:" + bak
		wvs = WaveList("*"+mol+"*", ";", "")
		for(w=0; w<ItemsInList(wvs); w+=1)
			wv = StringFromList(w, wvs)
			Duplicate/O $wv, $"root:"+org + ":" +wv
		endfor
		
		SetDataFolder root:
//		KillDataFolder /Z $bak
		
	endfor

end

function KillBackupData(insts)
	string insts
	
	variable i
	string inst, org, bak
	
	insts = ReplaceString("+", insts, ";")
	
	SetDataFolder root:
	
	for(i=0; i<ItemsInList(insts); i+=1)
		inst = StringFromList(i, insts)
		
		org = inst
		if (cmpstr(inst, "CATS") == 0 )
			org = "month"
		endif
		bak = org + "_bak"
		
		KillDataFolder /Z $bak
		
	endfor

end

function RemoveSomeData(insts, mol, fraction)
	string insts, mol
	variable fraction

	string inst, fld, site, wv, wvsd
	variable i, s
	
	insts = ReplaceString("+", insts, ";")
	
	for(i=0; i<ItemsInList(insts); i+=1)
		inst = StringFromList(i, insts)
		
		fld = inst
		if (cmpstr(inst, "CATS") == 0 )
			fld = "month"
		endif
		
		SetDataFolder $"root:"+fld
		
		for(s=0; s<ItemsInList(Allsites); s+=1)
			site = StringFromList(s, Allsites)
			if (cmpstr(inst, "CATS") == 0 )
				wv = site + "_" + mol
				wvsd = wv + "_sd"
			elseif (cmpstr(inst, "RITS") == 0 )
				wv = "RITS_" + site + "_" + mol + "_new"
				wvsd = wv + "_sd"
			elseif (cmpstr(inst, "otto") == 0 )
				wv = "otto_" + site + "_" + mol
				wvsd = wv + "_sd"
			elseif (cmpstr(inst, "oldGC") == 0 )
				wv = mol + site
				wvsd = wv + "sd"
			endif
			
			// if wave exists remove some fraction data
			if (exists(wv) == 1 )
				wave MR = $wv
				wave SD = $wvsd
				Make/FREE/n=(numpnts(MR)) rmvpnts = NaN
				rmvpnts = SelectNumber((numtype(MR)==0) && (abs(enoise(1)) < fraction), 1, nan)
				MR *= rmvpnts
				SD *= rmvpnts
			endif
			
		endfor
		
	endfor
	
	SetDataFolder root:
	
end


function ChangeSomeData(insts, mol, fraction)
	string insts, mol
	variable fraction

	variable i, s
	string inst, fld, site, wv, wvsd
	
	insts = ReplaceString("+", insts, ";")
	
	for(i=0; i<ItemsInList(insts); i+=1)
		inst = StringFromList(i, insts)
		
		fld = inst
		if (cmpstr(inst, "CATS") == 0 )
			fld = "month"
		endif
		
		SetDataFolder $"root:"+fld
		
		for(s=0; s<ItemsInList(Allsites); s+=1)
			site = StringFromList(s, Allsites)
			if (cmpstr(inst, "CATS") == 0 )
				wv = site + "_" + mol
				wvsd = wv + "_sd"
			elseif (cmpstr(inst, "RITS") == 0 )
				wv = "RITS_" + site + "_" + mol + "_new"
				wvsd = wv + "_sd"
			elseif (cmpstr(inst, "otto") == 0 )
				wv = "otto_" + site + "_" + mol
				wvsd = wv + "_sd"
			elseif (cmpstr(inst, "oldGC") == 0 )
				wv = mol + site
				wvsd = wv + "sd"
			endif
			
			// if wave exists remove some fraction data
			if (exists(wv) == 1 )
				wave MR = $wv
				wave SD = $wvsd
				//Make/FREE/n=(numpnts(MR)) pnts = NaN
				//pnts = SelectNumber((numtype(MR)==0) && (abs(enoise(1)) < fraction), 1, nan)
				//MR = SelectNumber((numtype(MR)==0) && (abs(enoise(1)) < fraction), (MR + gnoise(SD*1)), MR)
				MR = (MR+gnoise(SD*2))
			endif
			
		endfor
		
	endfor
	
	SetDataFolder root:
	
end


Function DisplayMC_Matrix([prefix, mol, loc, type, grth])
	String prefix, mol, loc
	variable type, grth

	SVAR mollst = root:G_molLst
	SVAR Gmol = root:G_mol
	SVAR Gpre = root:global:S_prefix

	if ( ParamIsDefault(mol) )
		mol = Gmol
	endif
	if ( ParamIsDefault(prefix) )
		prefix = Gpre
	endif
	if ( ParamIsDefault(loc) )
		loc = "Global"
	endif
	if ( ParamIsDefault(type) )
		type = 4
	endif
	if ( ParamIsDefault(grth) )
		grth = 1
	endif
	if ( ParamIsDefault(mol) || ParamIsDefault(prefix) ||  ParamIsDefault(loc) || ParamIsDefault(type) )
		Prompt mol, "Which gas?", popup, mollst
		Prompt prefix, "Name waves with the following prefix:"
		Prompt type, "Which simulation", popup, "Remove Data;Change Data;Both;include lat"
		Prompt loc, "Region", popup, "Global;NH;SH;BRW"
		Prompt grth, "Display Growth Rate", popup, "Yes;No"
		DoPrompt "Plot Monte Carlo Results:", mol, prefix, type, loc, grth
		if (V_flag)
			return -1
		endif
		Gmol = mol
		Gpre = prefix
	endif
		
	
	SetDataFolder root:global:
	String gblstr = prefix + "_" + loc + "_" + mol
	String gblsdstr = prefix + "_" + loc + "_" + mol + "_sd"
	String gblgrstr = prefix + "_" + loc + "_" + mol + "_gr"
	String gblTstr = prefix + "_" + mol + "_date"
	Wave gbl = $gblstr
	Wave gblsd = $gblsdstr
	Wave gblT = $gblTstr
		
	Variable i
	String txt
	
	GrowthRate(gbl, gblT, 12, 6)

	SetDataFolder root:simulation:
	String MCstr = prefix + "_" + loc + "MC" + num2str(type) + "_" + mol
	String MCgrstr = prefix + "_" + loc + "MC" + num2str(type) + "gr_" + mol
	If (exists(MCstr) == 0 )
		return 0
	endif
	Wave MC = $MCstr
	Wave MCgr = $MCgrstr
	
	// mean of simulations
	MC_MatrixAvg_Row(MC)
	String avg = MCstr + "_mean"
	String sd = MCstr + "_sd"
	MC_MatrixAvg_Row(MCgr)
	String avggr = MCgrstr + "_mean"
		
	String win = "MonteCarlo" + num2str(type) + "_"+prefix+"_"+mol+"_"+loc
	DoWindow /K $win
	Display /K=1 /W=(35,44,812,506)
	DoWindow /C $win
	
	// global mean
	for(i=0; i<DimSize(MC, 1); i+=1)
		AppendToGraph MC[][i] vs gblT
	endfor
	SetDataFolder root:global:
	AppendToGraph gbl vs gblT
	
	SetDataFolder root:simulation:
	// growth rate
	if (grth==1)
		for(i=0; i<DimSize(MCgr, 1); i+=1)
			AppendToGraph/L=gr MCgr[][i] vs gblT
		endfor
		AppendToGraph/L=gr $avggr vs gblT
	endif
	
	//ModifyGraph msize=1,mode=3,marker=19
	ModifyGraph lstyle=1
	ModifyGraph rgb=(21845,21845,21845)

	AppendToGraph $avg vs gblT
	ModifyGraph rgb($avg)=(0,65535,65535)
	
	if (grth==1)
		SetDataFolder root:global:
		AppendToGraph/L=gr $gblgrstr vs gblT
		ModifyGraph lstyle($avggr)=0
		ModifyGraph lsize($avggr)=2
	endif

	SetDataFolder root:global:
	ModifyGraph rgb($gblstr)=(65535,1,1)
	ModifyGraph mode($gblstr)=0
	ModifyGraph lsize($gblstr)=2
	ModifyGraph lstyle($gblstr)=0
	ModifyGraph mirror=2	
	ModifyGraph lblPos(left)=61
	ModifyGraph dateInfo(bottom)={0,0,0}

	ErrorBars $gblstr Y,wave=($"root:global:"+gblsdstr,$"root:global:"+gblsdstr)
	ErrorBars $avg Y,wave=($"root:simulation:"+sd,$"root:simulation:"+sd)
	
	Label left mol + " " + ReturnMolUnits(mol)
	Label bottom "Date"

	if (grth==1)	
		ModifyGraph axisEnab(left)={0,0.6}
		ModifyGraph rgb($gblgrstr)=(65535,1,1)
		ModifyGraph lsize($gblgrstr)=2
		ModifyGraph lblPosMode(gr)=2
		ModifyGraph freePos(gr)=0
		ModifyGraph axisEnab(gr)={0.65,1}
		ModifyGraph rgb($avggr)=(0,65535,65535)
		Label gr "Annual Growth Rate" + " " + ReturnMolUnits(mol)
	endif
	
	if (strlen(note(MC)) > 0)
		TextBox/X=2.51/Y=77.94/C/N=sim note(MC)
		AppendText /N=sim loc
	endif

	sprintf txt, "\\s(%s) Mean of simulations\r\\s(%s) Algorithm", avg, gblstr
	TextBox/C/N=leg/X=73.16/Y=41.10 txt

	SetDataFolder root:

end


// mean and sd of each row in matrix
function MC_MatrixAvg_Row(MC)
	wave MC
	
	variable rows = DimSize(MC,0), cols = DimSize(MC,1), i, j
	String MCmeans = NameOfWave(MC) + "_mean"
	String MCsds = NameOfWave(MC) + "_sd"
	
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:simulation:
	
	Make /o /n=(rows) $MCmeans/Wave=MCmean, $MCsds/Wave=MCsd
	for (i=0; i<rows; i+=1)
		MatrixOp /FREE/o slice = row(MC, i)
		Redimension/N=(cols) slice
		WaveStats /q slice
		MCmean[i] = V_avg
		MCsd[i] = V_sdev
	endfor
	
	SetDataFolder fldrSav0
	
end

// mean (or median) and sd of each col in matrix
function MC_MatrixAvg_Col(MC, [med])
	wave MC
	Variable med
	
	// set med=1 for median results instead of mean
	if (ParamIsDefault(med))
		med = 0
	endif
	
	variable rows = DimSize(MC,0), cols = DimSize(MC,1), i, j
	String MCmeans = NameOfWave(MC) + "_av"
	String MCsds = NameOfWave(MC) + "_sd"
	
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:simulation:
	
	Make /o /n=(cols) $MCmeans/Wave=MCmean, $MCsds/Wave=MCsd
	for (i=0; i<cols; i+=1)
		MatrixOp /FREE/o slice = col(MC, i)
		Redimension/N=(rows) slice
		RemoveNaNs(slice)
		if (numpnts(slice) > 0)
			Sort slice, slice
			// Remove min and max points
			//slice[0] = nan
			//slice[numpnts(slice)-1] = nan
			WaveStats /Q slice
			MCmean[i] = SelectNumber(med, v_avg, slice[numpnts(slice)/2])
			MCsd[i] = V_sdev
		else
			MCmean[i] = Nan
			MCsd[i] = Nan
		endif
	endfor
	
	SetDataFolder fldrSav0
	
end


Function Diff_from_MC_mean(prefix, mol, type)
	string prefix, mol
	variable type
	
	string tstr
	if (type != 1)
		tstr = num2str(type)
	endif
	string sP = "root:simulation:"
	string MC = prefix + "_GlobalMC" + tstr + "_" + mol

	MC_MatrixAvg_Row($sP+MC)

	SetDataFolder $sP
	wave MCmean = $MC + "_mean"
	wave Glb = $"root:global:" + prefix + "_Global_" + mol
	wave GT = $"root:global:" + prefix + "_" + mol + "_date"
	string diff = prefix + "_" + mol + "_diff"
	string win = "MC_diff_" + prefix + "_" + mol
	
	Duplicate /o MCmean, $diff/Wave=diffwv
	diffwv = Glb - MCmean

	DoWindow /K $win
	Display /W=(35,44,896,266) /K=1 diffwv vs GT
	DoWindow /C $win
	ModifyGraph zero(left)=1
	ModifyGraph dateInfo(bottom)={0,0,0}
	SetAxis/A/N=1/E=2 left
	
end
	
	
	
/// Functions for interpolating missing data

Function seasonal_poly3(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = a + b * x + c * x^2 + d * sin(f * x + phi)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 6
	//CurveFitDialog/ w[0] = a
	//CurveFitDialog/ w[1] = b
	//CurveFitDialog/ w[2] = c
	//CurveFitDialog/ w[3] = d
	//CurveFitDialog/ w[4] = f
	//CurveFitDialog/ w[5] = phi

	variable year = 1/(60*60*24*365.25)
	return w[0] + w[1] * x + w[2] * x^2 +  w[3] * sin(w[4] * year * x + w[5])
End

Function seasonal_poly4_harms(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = a + b * x + c * x^2 + d * x^3 + amp1 * sin(wid1 * x + phi1) + amp2 * sin(2*wid2 * x + phi2) + amp3 * sin(4*wid3 * x + phi3)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 12
	//CurveFitDialog/ w[0] = a
	//CurveFitDialog/ w[1] = b
	//CurveFitDialog/ w[2] = c
	//CurveFitDialog/ w[3] = d
	//CurveFitDialog/ w[4] = sk1
	//CurveFitDialog/ w[5] = ck1
	//CurveFitDialog/ w[6] = sk2
	//CurveFitDialog/ w[7] = ck2
	//CurveFitDialog/ w[8] = sk3
	//CurveFitDialog/ w[9] = ck3
	//CurveFitDialog/ w[10] = sk4
	//CurveFitDialog/ w[11] = ck4

	variable year = 1/(60*60*24*365.25)			// 1 /secs in a year
	variable sin1 = w[4]*sin(2*pi*year*x)
	variable cos1 = w[5]*cos(2*pi*year*x)
	variable sin2 = w[6]*sin(4*pi*year*x)
	variable cos2 = w[7]*cos(4*pi*year*x)
	variable sin3 = w[8]*sin(6*pi*year*x)
	variable cos3 = w[9]*cos(6*pi*year*x)
	variable sin4 = w[10]*sin(8*pi*year*x)
	variable cos4 = w[11]*cos(8*pi*year*x)

	return w[0] + w[1] * x + w[2] * x^2 +  w[3] * x^3 + sin1 + cos1 + sin2 + cos2  + sin3 + cos3 + sin4 + cos4 
	
End

Function seasonal_poly4_harmsMore(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = a + b * x + c * x^2 + d * x^3 + amp1 * sin(wid1 * x + phi1) + amp2 * sin(2*wid2 * x + phi2) + amp3 * sin(4*wid3 * x + phi3)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 12
	//CurveFitDialog/ w[0] = a
	//CurveFitDialog/ w[1] = b
	//CurveFitDialog/ w[2] = c
	//CurveFitDialog/ w[3] = d
	//CurveFitDialog/ w[4] = sk1
	//CurveFitDialog/ w[5] = ck1
	//CurveFitDialog/ w[6] = sk2
	//CurveFitDialog/ w[7] = ck2
	//CurveFitDialog/ w[8] = sk3
	//CurveFitDialog/ w[9] = ck3
	//CurveFitDialog/ w[10] = sk4
	//CurveFitDialog/ w[11] = ck4

	variable year = 1/(60*60*24*365.25)			// 1 /secs in a year
	variable sin1 = w[4]*sin(2*pi*year*x)
	variable cos1 = w[5]*cos(2*pi*year*x)
	variable sin2 = w[6]*sin(4*pi*year*x)
	variable cos2 = w[7]*cos(4*pi*year*x)
	variable sin3 = w[8]*sin(6*pi*year*x)
	variable cos3 = w[9]*cos(6*pi*year*x)
	variable sin4 = w[10]*sin(8*pi*year*x)
	variable cos4 = w[11]*cos(8*pi*year*x)
	variable sin5 = w[12]*sin(1*pi*year*x)
	variable cos5 = w[13]*cos(1*pi*year*x)
//	variable sin6 = w[14]*sin(1/2*pi*year*x)
//	variable cos6 = w[15]*cos(1/2*pi*year*x)

	return w[0] + w[1] * x + w[2] * x^2 +  w[3] * x^3 + sin1 + cos1 + sin2 + cos2  + sin3 + cos3 + sin4 * cos4  + sin5 + cos5  //+ sin6 + cos6
	
End


Function seasonal_exp_harms(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = a + b * x + c * x^2 + d * x^3 + amp1 * sin(wid1 * x + phi1) + amp2 * sin(2*wid2 * x + phi2) + amp3 * sin(4*wid3 * x + phi3)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 12
	//CurveFitDialog/ w[0] = a
	//CurveFitDialog/ w[1] = b
	//CurveFitDialog/ w[2] = c
	//CurveFitDialog/ w[3] = d
	//CurveFitDialog/ w[4] = sk1
	//CurveFitDialog/ w[5] = sk2
	//CurveFitDialog/ w[6] = sk3
	//CurveFitDialog/ w[7] = sk4
	//CurveFitDialog/ w[8] = ck1
	//CurveFitDialog/ w[9] = ck2
	//CurveFitDialog/ w[10] = ck3
	//CurveFitDialog/ w[11] = ck4

	variable year = 1/(60*60*24*365.25)
	variable sin1 = w[4]*sin(2*pi*year*x)
	variable sin2 = w[5]*sin(4*pi*year*x)
	variable sin3 = w[6]*sin(6*pi*year*x)
	variable sin4 = w[7]*sin(8*pi*year*x)
	variable cos1 = w[8]*cos(2*pi*year*x)
	variable cos2 = w[9]*cos(4*pi*year*x)
	variable cos3 = w[10]*cos(6*pi*year*x)
	variable cos4 = w[11]*cos(8*pi*year*x)

	return w[0] + w[1] * x + w[2] * x^2 +  w[3] * x^3 + sin1 + cos1 + sin2 + cos2 + sin3 + cos3 + sin4 + cos4
	
End


// set f to (2*pi)/(60*60*24*365)
Function seasonal_poly4(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = a + b * x + c * x^2 + d * x^3 + e * sin(f * x + phi)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = a
	//CurveFitDialog/ w[1] = b
	//CurveFitDialog/ w[2] = c
	//CurveFitDialog/ w[3] = d
	//CurveFitDialog/ w[4] = e
	//CurveFitDialog/ w[5] = f
	//CurveFitDialog/ w[6] = phi

	variable year = 1/(60*60*24*365.25)
	return w[0] + w[1] * x + w[2] * x^2 + w[3] * x^3 + w[4] * sin(w[5] * year * x + w[6])
End


Function Poly3_cust(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = a + b * x + c * x^2
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = a
	//CurveFitDialog/ w[1] = b
	//CurveFitDialog/ w[2] = c

	variable val = w[0] + w[1] * x + w[2] * x^2
	return val
End

Function Poly4_cust(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = a + b * x + c * x^2 + d * x^3 
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = a
	//CurveFitDialog/ w[1] = b
	//CurveFitDialog/ w[2] = c
	//CurveFitDialog/ w[3] = d

	variable val = w[0] + w[1] * x + w[2] * x^2  + w[3] * x^3
	return val
End

// prototype functions for FUNCREF in SeasonalFit_auto
Function SeasonalFitProto(w, x)
	Wave w
	Variable x
end

Function AutoFitProto(xx, yy, sd, [d1,d2,v])
	wave xx, yy, sd
	variable d1, d2, v
end

Function Poly3_auto(xx, yy, sd, [d1, d2, v])
	Wave xx, yy, sd
	Variable d1, d2, v

	Variable p1, p2, q, i
	if (!ParamIsDefault(d1))
		p1 = BinarySearchInterp(xx, d1)
		p2 = BinarySearchInterp(xx, d2)
		if (numtype(p2) == 2)
			p2 = numpnts(xx)-1
		endif
	else
		p1 = 0
		p2 = numpnts(xx)-1
	endif

	Wavestats/Q/M=1/R=[p1,p2] yy
	if (V_npnts < 5)
		return -1
	endif
	CurveFit/M=2/Q/NTHR=0/W=0 poly 3, yy[p1,p2] /X=xx /W=sd /I=1
	Wave coef = W_coef
	Duplicate /O coef, Seas_coef
end

Function Poly4_auto(xx, yy, sd, [d1, d2, v])
	Wave xx, yy, sd
	Variable d1, d2, v

	Variable p1, p2, q, i
	if (!ParamIsDefault(d1))
		p1 = BinarySearchInterp(xx, d1)
		p2 = BinarySearchInterp(xx, d2)
		if (numtype(p2) == 2)
			p2 = numpnts(xx)-1
		endif
	else
		p1 = 0
		p2 = numpnts(xx)-1
	endif

	Wavestats/Q/M=1/R=[p1,p2] yy
	if (V_npnts < 5)
		return -1
	endif
	CurveFit/M=2/Q/NTHR=0/W=0 poly 3, yy[p1,p2] /X=xx /W=sd /I=1
	Wave coef = W_coef
	Duplicate /O coef, Seas_coef
end

//Function SeasonalFit_auto(xx, yy, sd, [d1,d2,v,ply])
	Wave xx, yy, sd
	Variable d1, d2, v,ply

	if ((ParamIsDefault(ply)) || (ply==4))
		ply = 4
	else
		ply = 3
	endif
	FUNCREF SeasonalFitProto seasonfit = $"seasonal_poly" + num2str(ply)
	
	Variable p1, p2, q, i
	String hold = ""
	if (!ParamIsDefault(d1))
		p1 = BinarySearchInterp(xx, d1)
		p2 = BinarySearchInterp(xx, d2)
		if (numtype(p2) == 2)
			p2 = numpnts(xx)-1
		endif
	else
		p1 = 0
		p2 = numpnts(xx)-1
	endif
	
	// first fit poly 3 to get coef guesses
//	CurveFit/M=2/Q/W=0 poly ply, yy[p1,p2] /X=xx 
	CurveFit/M=2/Q/W=0 poly ply, yy[p1,p2] /X=xx /W=sd /I=1
	Wave coef = W_coef

	Variable year_rad = 2*pi / (60*60*24*365.25)
	Make /d/o/n=(numpnts(coef)+3) Seas_coef
	
	// fill in coef wave
	Seas_coef = coef[p]
	Seas_coef[numpnts(coef)] = 0.1
	Seas_coef[numpnts(coef)+1] = year_rad
	Seas_coef[numpnts(coef)+2] = 0.1
	for(i=0; i<numpnts(coef); i+=1)
		hold += "0"
	endfor
//	hold += "010"		// hold the year_rad variable 
	hold += "000"
	
	// for text box use /TBOX=792
	if (v)
		FuncFit/Q=(v)/H=hold/NTHR=0 seasonfit Seas_coef  yy[p1,p2] /X=xx /W=sd /I=1
	else
		FuncFit/Q=(v)/H=hold/NTHR=0 seasonfit Seas_coef  yy[p1,p2] /X=xx /W=sd /I=1 /D
	endif
	//print "Reduced chi-square = ", V_chisq/(V_npnts - numpnts(Seas_coef))
	
end

// function to determine initial guess a parameter for the seasonal_poly4_harms fit
Function SeasonalFit_auto_harms(xx, yy, sd, [d1,d2,v])
	Wave xx, yy, sd
	Variable /d d1, d2, v

	Variable NumHarms = 8
	FUNCREF SeasonalFitProto seasonfit = seasonal_poly4_harms
	//Variable NumHarms = 10
	//FUNCREF SeasonalFitProto seasonfit = seasonal_poly4_harmsMore
	
	Variable p1, p2, q, i
	String hold = ""
	if (!ParamIsDefault(d1))
		p1 = BinarySearchInterp(xx, d1)
		p2 = BinarySearchInterp(xx, d2)
		if (numtype(p2) == 2)
			p2 = numpnts(xx)-1
		endif
	else
		p1 = 0
		p2 = numpnts(xx)-1
	endif
	
	// first fit poly 4 to get coef guesses 
	WaveStats /M=1/Q /R=[p1,p2] yy
	if (V_npnts < 5)
		return -1
	endif
	CurveFit/Q/M=0/NTHR=0/W=0 poly 4, yy[p1,p2] /X=xx /W=sd /I=1
	wave tmp_coef = W_coef

	// fill in coef wave
	Make /d/o/n=(numpnts(tmp_coef)+NumHarms) Seas_coef
	Seas_coef = tmp_coef[p]
	Seas_coef[numpnts(tmp_coef),Inf] = .1
	
	// for text box use /TBOX=792
	if (v)
		Wavestats/Q/M=1/R=[p1,p2] yy
		if (V_npnts < 15)
			return -1
		endif
		FuncFit/Q=(v)/NTHR=0 seasonfit Seas_coef  yy[p1,p2] /X=xx /W=sd /I=1
	else
		Wave /Z res = $"Res_" + NameOfWave(yy)
		if (WaveExists(res))
			res = NaN
		endif
		FuncFit/Q=(v)/NTHR=0 seasonfit Seas_coef  yy[p1,p2] /X=xx /W=sd /I=1 /D/R
	endif
	
	// make fit wave with more points than the default of 200
	if (v!=1)
		string fitwv = "fit_" + NameOfWave(yy)
		Make /n=2000 /o $fitwv/Wave=fit
		SetScale x, xx[p1], xx[p2], fit
		fit = seasonfit(Seas_coef, x)
		//display fit
	endif

end

// wrapper function to MonteCarlo_Fit, mainly used for looking at fits for various programs and molecules.
Function MCfit(prog, site, mol, [iters])
	string prog, site, mol
	variable iters

	if (ParamIsDefault(iters))
		iters = 100
	endif

	string P = "root:", D, M, S

	if (cmpstr(prog, "CATS") == 0 )
		P += "month:"
		D = P + site + "_time"
		M = P + site + "_" + mol
		S = P + site + "_" + mol + "_sd"
	elseif (cmpstr(prog, "OTTO") == 0 )
		P += "OTTO:"
		D = P + "OTTO_" + site + "_" + mol + "_date"
		M = P + "OTTO_" + site + "_" + mol
		S = P + "OTTO_" + site + "_" + mol + "_sd"
	elseif (cmpstr(prog, "CCGG") == 0 )
		P += "CCGG:"
		D = P + "CCGG_" + site + "_" + mol + "_date"
		M = P + "CCGG_" + site + "_" + mol + "_mn"
		S = P + "CCGG_" + site + "_" + mol + "_sd"
	elseif (cmpstr(prog, "MSD") == 0 )
		P += "MSD:"
		D = P + "MSD_" + site + "_" + mol + "_date"
		M = P + "MSD_" + site + "_" + mol
		S = P + "MSD_" + site + "_" + mol + "_sd"
	elseif (cmpstr(prog, "RITS") == 0 )
		P += "RITS:"
		D = P + "RITS_" + site + "_" + mol + "_new_date"
		M = P + "RITS_" + site + "_" + mol + "_new"
		S = P + "RITS_" + site + "_" + mol + "_new_sd"
	elseif (cmpstr(prog, "oldgc") == 0 )
		P += "oldgc:"
		D = P + mol + site + "_time"
		M = P +mol + site
		S = P + mol + site + "sd"
	else
		abort "Unknown measurement program."
	endif
	
	if (WaveExists($D))
		MonteCarlo_Fit($D, $M, $S, iters=iters, plt=1)
	else
		print "Missing Wave: ", D
	endif

end

// Monte Carlo fitting routine that determines which fit.  Seasonal_poly4_harms or poly4
Function MonteCarlo_fit(xx, yy, sd, [iters,plt])
	wave xx, yy, sd
	variable iters, plt
	
	if (ParamIsDefault(iters))
		iters = 100
	endif
	if (ParamIsDefault(plt))
		plt = 0
	endif
	
	string df = GetWavesDataFolder(xx,1)

	variable gp1 = FirstGoodPt(yy)
	variable gp2 = LastGoodPt(yy)
	variable gpH = (gp2-gp1)/2
	variable gpDur = (xx[gp2]-xx[gp1])

	FUNCREF SeasonalFitProto fiteq = seasonal_poly4_harms
	FUNCREF AutoFitProto seedfit = SeasonalFit_auto_harms
	
	WaveStats/Q/M=1/R=[gp1, gp2] yy
	//print Nameofwave(yy), V_numNans/V_npnts
	if (V_numNans/V_npnts > 0.5)			// If a large portion  of the data set is NaNs, use lower order fits... no harmonics
		if (V_numNans/V_npnts > 0.9)		
			printf "Poly 3 used: %d points %3.2f, wave: %s\r", v_npnts, V_numNans/V_npnts, nameofwave(yy)
			FUNCREF SeasonalFitProto fiteq = poly3_cust
			FUNCREF AutoFitProto seedfit = poly3_auto
		else
			printf "Poly 4 used: %d points, %3.2f, wave: %s\r", v_npnts, V_numNans/V_npnts, nameofwave(yy)
			FUNCREF SeasonalFitProto fiteq = poly4_cust
			FUNCREF AutoFitProto seedfit = poly4_auto
		endif
	endif

	String fldrSav0= GetDataFolder(1), notestr
	SetDataFolder root:simulation:
	
	string fitst = "fx_" + NameOfWave(yy)
	// +6 for the last few full data fits
	Make /o/n=(iters+6,numpnts(xx)) $fitst/WAVE=fit=Nan
	Sprintf notestr, "xwave:%s;ywave:%s;sdwave:%s;df:%s;iters=%d", NameOfWave(xx), NameOfWave(yy), NameOfWave(sd), GetWavesDataFolder(xx, 1), iters
	Note fit, notestr

	variable MinDur = gpDur * 0.2
	variable MaxDur = gpDur * 0.7   // was 0.5

	variable i, d1, d2, tmp, idx, high, low
	variable clip = 0.1
	variable n = numpnts(xx)

	Killwaves /Z Seas_coef
	seedfit(xx, yy, sd, v=1)
	Wave /Z coef = Seas_coef
	if (WaveExists(coef) == 0)
		return 0
	endif

	// Front of data wave for 10% of the iterations
	for (i=0; i<iters/10; i+=1)
		d1 = gp1
		d2 = gp1 + gpH*0.3  + (gpH*0.7)/(iters/10)*i
		seedfit(xx, yy, sd, d1=xx[d1], d2=xx[d2], v=1)
		// filter out large fit deviations
		WaveStats /Q/M=1/R=[d1,d2] yy
		high = V_max + clip*(V_max-V_min)
		low = V_min - clip*(V_max-V_min)
		fit[i][d1,d2] = SelectNumber((fiteq(coef, xx[q]) > low) && (fiteq(coef, xx[q]) < high), NaN, fiteq(coef, xx[q]))
	endfor
	idx = i
	
	// End of data wave for 10% of the iterations
	for (i=0; i<iters/10; i+=1)
		d1 = gp2 - gpH*0.3 - (gpH*0.7)/(iters/10)*i
		d2 = gp2
		seedfit(xx, yy, sd, d1=xx[d1], d2=xx[d2], v=1)
		// filter out large fit deviations
		WaveStats /Q/M=1/R=[d1,d2] yy
		high = V_max + clip*(V_max-V_min)
		low = V_min - clip*(V_max-V_min)
		fit[i+idx][d1,d2] = SelectNumber((fiteq(coef, xx[q]) > low) && (fiteq(coef, xx[q]) < high), NaN, fiteq(coef, xx[q]))
	endfor
	idx += i
	
	// Middle of data wave for 80% of the iterations
	for(i=0; i<iters*0.8; i+=1)
		// find good starting and ending points for fit
		do
			d1 = enoise(gpH) + gpH + gp1		// random number between gp1 and gp2
			d2 = enoise(gpH) + gpH + gp1
			// d2 should be larger than d1
			if (d1 > d2)
				tmp = d1; d1 = d2; d2 = tmp
			endif
		while(((xx[d2]-xx[d1]) < MinDur) || ((xx[d2]-xx[d1]) > MaxDur))
		seedfit(xx, yy, sd, d1=xx[d1], d2=xx[d2], v=1)
		WaveStats /Q/M=1/R=[d1,d2] yy
		high = V_max + clip*(V_max-V_min)
		low = V_min - clip*(V_max-V_min)
		fit[i+idx][d1,d2] = SelectNumber((fiteq(coef, xx[q]) > low) && (fiteq(coef, xx[q]) < high), NaN, fiteq(coef, xx[q]))
	endfor
	
	// fit the full range of data with seedfit and a linear fit
	// this works well for very long gaps.
//	idx += i
//	for(i=0; i<3; i+=1)
//		seedfit(xx, yy, sd, d1=xx[gp1+i], d2=xx[gp2-i], v=1)
//		fit[idx][gp1+i, gp2-i] = fiteq(coef, xx[q])
//		idx += 1
//		
//		CurveFit/M=2/Q/W=0 line, yy[gp1+i,gp2-i] /X=xx /W=sd
//		Wave cof = W_coef
//		fit[idx][gp1+i,gp2-i] = cof[0] + cof[1]*xx[q]
//		idx += 1
//	endfor
	
	if (plt)
		Plot_MonteCarlo_matrix(fit)
	else
		MC_MatrixAvg_Col(fit, med=1)
	endif
	
	// Add precision noise to MC fit?
	Wave MCsd = $"root:simulation:" + fitst + "_sd"
	MCsd = SelectNumber(numtype(yy)==2, MCsd, sqrt(MCsd^2 + (medianEO(sd, -inf, inf)/2)^2))
	
	Killwaves coef
	SetDataFolder fldrSav0
	
end

// Removes fit data that are far away from the measurements.  These fits arrise due to being underconstrained.
// Very simple version
function RemoveBadFits(MC, yy)
	wave MC, yy
	
	WaveStats /Q yy
	variable high = V_max + 0.15*(V_max-V_min)
	variable low = V_min - 0.15*(V_max-V_min)
	
	MatrixOp /O/FREE mask = greater(MC, low) * greater(high, MC)
	MatrixOp /FREE mr = Replace(mask, 0, NaN) * MC
	MC = MR
	
end

Function Plot_MonteCarlo_matrix(mat)
	wave mat

	string P = "root:simulation:"
	string win = NameofWave(mat) + "plot"
	MC_MatrixAvg_Col(mat, med=1)
	string avg = NameOfWave(mat) + "_av"
	wave avgwv = $P+avg
	string sd = NameOfWave(mat) + "_sd"
	Wave xx = $StringByKey("df", note(mat)) + StringByKey("xwave", note(mat))
	Wave yy = $StringByKey("df", note(mat)) + StringByKey("ywave", note(mat))
	Wave yysd = $StringByKey("df", note(mat)) + StringByKey("sdwave", note(mat))
	
//	string mr =  StringByKey("ywave", note(mat))
//	if (strsearch(StringByKey("df", note(mat)), "oldgc", 0, 2) > -1)
//		Wave yysd = $StringByKey("df", note(mat)) + mr + "sd"
//	elseif (strsearch(mr, "CCGG", 0, 2) > -1)
//		string tmp = mr[0, strlen(tmp)-4]
//		Wave yysd = $StringByKey("df", note(mat)) + tmp + "_sd"
//	else
//		Wave yysd = $StringByKey("df", note(mat)) + mr + "_sd"
//	endif
	Variable i, rows = Dimsize(mat, 0), pt

	DoWindow /k $win
	Display /W=(35,44,699,421)/K=1
	DoWindow /C $win
	for(i=0; i<rows; i+=1)
		AppendtoGraph mat[i][] vs xx
	endfor
	AppendToGraph $p+avg vs xx
	ModifyGraph lsize($avg)=2,rgb($avg)=(0,0,0)
	ErrorBars $avg Y,wave=($p+sd,$p+sd)
	
	// Calculate residual
	SetDatafolder P
	string resid = NameOfWave(mat) + "_res"
	Make /o/n=(numpnts(xx)) $resid/WAVE=res
	res = yy-avgwv
	AppendToGraph /l=residual res vs xx
	ModifyGraph axisEnab(left)={0,0.75},axisEnab(residual)={0.8,1}
	ModifyGraph freePos(residual)=0, zero(residual)=1
	ModifyGraph mode($resid)=3, marker($resid)=8, rgb($resid)=(3,52428,1)
	AppendToGraph yy vs xx
	ModifyGraph mode($StringByKey("ywave", note(mat)))=3, marker($StringByKey("ywave", note(mat)))=8, rgb($StringByKey("ywave", note(mat)))=(3,3,65000)
	
	ErrorBars $StringByKey("ywave", note(mat)) Y,wave=(yysd,yysd)
	
	cd root:
		
end
