#pragma rtGlobals=1		// Use modern global access method.

Proc GenAlgoSolution(mol, fit, iter)
	string mol=StrMakeOrDefault("root:G_mol", "F11")
	variable iter=NumMakeOrDefault("root:G_genIter", 100)
	variable fit=NumMakeOrDefault("root:G_calfit", 1)
	prompt mol, "Which molecule", popup, G_loadMol
	prompt fit, "What type of fit?", popup, "Linear (sd weighting);one-to-one;poly 3 (sd weighting)" 
	prompt iter, "Number of iterations"
	
	silent 1
	
	G_mol = mol
	G_genIter = iter
	G_calfit = fit
	string win = "GenAlgo_Goodness"
	string fldrSav = GetDataFolder(1)

	string genfunct 
	sprintf genfunct, "%sGenAlgo( \"%s\", %d)", G_site3, mol, iter
	execute genfunct
	
	Dowindow /k $win
	SetDataFolder root:GenAlgo:
	Display /W=(28,142,522,508) sol_improve
	SetDataFolder fldrSav
	ModifyGraph mode=6
	ModifyGraph lSize=3
	Label left "Solution to GenAlgo function"
	Label bottom "Iteration"
	SetAxis/A/E=1 left
	Dowindow /c $win
	
	Ratio_CalCurve(mol,"H",fit,2)
	
end

// updated Aug 2001
// Dec 2001 update (found bug missing ALM65166????)
// Have NOT added poly 3 support.  March 2002
function mloGenAlgo(mol, iter)
	string mol
	variable iter
	
	wave calratio = $mol+"_calRatios"
	wave caltankratio = $mol + "_calTankRatios"
	wave lcal = $mol + "_lcalval"
	wave hcal = $mol + "_hcalval"
	wave fitcoefs = $mol + "_fitcoefs"
	variable numvars, inc
	string com

	string tanklst = "ALM52817;ALM59963;ALM65166;ALM64608;ALM52817a;ALM67679;ALM67725;ALM67708;ALM67718;ALM67694;"
	MakeTextWaveFromList(tanklst, "tankwv", ";")
	wave /t tankwv = tankwv

	numvars = numpnts(tankwv)					// one for each unknown variable.
	Variable l1 = GetALMconc(mol,  tankwv[0])
	Variable h1 = GetALMconc(mol,  tankwv[1])
	Variable l2 =  GetALMconc(mol,  tankwv[2])
	Variable h2 = GetALMconc(mol,  tankwv[4])
	Variable l3 = GetALMconc(mol,  tankwv[3])
	Variable h3 =  GetALMconc(mol,  tankwv[6])
	Variable l4 = GetALMconc(mol,  tankwv[5])
	Variable h4 =  GetALMconc(mol,  tankwv[8])
	Variable l5 =  GetALMconc(mol,  tankwv[7])
	Variable l6 =  GetALMconc(mol,  tankwv[9])
	Variable AA = fitcoefs[0]
	Variable BB = fitcoefs[1]
	Variable R11 = calratio[0]
	Variable R21 = calratio[1]
	Variable R32 = calratio[4]
	Variable R43 = calratio[7]
	Variable R53 = calratio[8]
	Variable R54 = calratio[9]
	Variable R64 = calratio[10]
	
	make /d/o params = {l1,h1,l2,l3,h2,l4,h3,l5,h4,l6,AA,BB,R11,R21,R32,R43,R53, R54, R64}
	freplace(params, nan, -1)

	// Calculation begins... All code below here is identical for all sites.
	GenAlgo( iter, params, numvars )
	
	wave bestsolution = root:GenAlgo:solution0

	// Set the K variables to the best solution
	variable sol = mlo_GenAnswer(params, bestsolution, numvars)
	print "Best solution: "+ num2str(sol) + "  with " + num2str(K10) + " penalty."

	// Create the adjust wave
	CreateAdjustWave(mol)

end

// Returns the value from min function
Function/d mlo_GenAnswer(params, deltas, numvars)
	wave /d params, deltas
	variable numvars
	
	Variable l1 = params[0]  	// deltas[0]
	Variable h1 = params[1]	// deltas[1]
	Variable l2 = params[2]	// deltas[2]
	Variable h2 = params[3]	// deltas[3]
	Variable l3 = params[4]	// deltas[4]
	Variable h3 = params[5]
	Variable l4 = params[6]
	Variable h4 = params[7]
	Variable l5 = params[8]
	Variable l6 = params[9]
	Variable AA = params[10]
	Variable BB = params[11]
	Variable R11 = params[12]
	Variable R21 = params[13]
	Variable R32 = params[14]
	Variable R43 = params[15]
	Variable R53 = params[16]
	Variable R54 = params[17]
	Variable R64 = params[18]
	variable/d val

	variable/d f11 = (l1+deltas[0])/(h1+deltas[1]) * BB + AA
	variable/d f21 = (l2+deltas[2])/(h1+deltas[1]) * BB + AA
	variable/d f32 = (l3+deltas[4])/(h2+deltas[3]) * BB + AA
	variable/d f43 = (l4+deltas[6])/(h3+deltas[5]) * BB + AA
	variable/d f53 = (l5+deltas[8])/(h3+deltas[5]) * BB + AA
	variable/d f54 = (l5+deltas[8])/(h4+deltas[7]) * BB + AA
	variable/d f64 = (l6+deltas[9])/(h4+deltas[7]) * BB + AA
	
	if (R11 == -1)
		f11 = -1
	endif
	if (R21 == -1)
		f21 = -1
	endif
	if (R32 == -1)
		f32 = -1
	endif
	if (R43 == -1)
		f43 = -1
	endif
	if (R53 == -1)
		f53 = -1
	endif
	if (R54 == -1)
		f54 = -1
	endif
	if (R64 == -1)
		f64 = -1
	endif

	val += abs((R11-f11)) 
	val += abs((R21-f21)) 
	val += abs((R32-f32)) 
	val += abs((R43-f43)) 
	val += abs((R53-f53)) 
	val += abs((R54-f54)) 
	val += abs((R64-f64)) 
	
	K1 = abs((R11-f11)) 
	K2 = abs((R32-f32)) 
	K3 = abs((R43-f43)) 
	K4 = abs((R53-f53)) 
	K5 = abs((R54-f54)) 
	K6 = abs((R64-f64)) 
	K0 = val

	// Calculate a penalty
	variable pen, mr, del, inc = 0
	do
		del = deltas[inc]
		mr = params[inc] * 0.005
//		mr = params[inc] * 0.01
		if (( abs(del) > mr) *  (params[inc] != 1))
			pen += abs(del-mr) / 5
		endif
		inc += 1	
	while (inc < numvars)
	
	K10 = pen
	
	return val + pen
	
End

// Updated in March 2002
// Added poly 3
function smoGenAlgo(mol, iter)
	string mol
	variable iter
	
	wave calratio = $mol+"_calRatios"
	wave calratioN = $mol + "_calRatios_num"
	wave lcal = $mol + "_lcalval"
	wave hcal = $mol + "_hcalval"
	wave fitcoefs = $mol + "_fitcoefs"
	variable numvars, inc
	string com
	
	string tanklst = "ALM52762;ALM59981;ALM65142;ALM65178;ALM64466;ALM64461;ALM67714;ALM66000;ALM66023a"
	MakeTextWaveFromList(tanklst, "tankwv", ";")
	wave /t tankwv = tankwv

	numvars = numpnts(tankwv)					// one for each unknown variable.
	Variable l1 = GetALMconc(mol, tankwv[0])
	Variable h1 = GetALMconc(mol, tankwv[1])
	Variable l2 = GetALMconc(mol, tankwv[2])
	Variable h2 = GetALMconc(mol, tankwv[3])
	Variable l3 = GetALMconc(mol, tankwv[4])
	Variable h3 =  GetALMconc(mol, tankwv[5])
	Variable l4 =  GetALMconc(mol, tankwv[6])
	Variable h4 =  GetALMconc(mol, tankwv[7])
	Variable l5 =  GetALMconc(mol, tankwv[8])
	Variable R11 = calratio[0]
	Variable R21 = calratio[1]
	Variable R22 = calratio[2]
	Variable R32 = calratio[3]
	Variable R33 = calratio[5]
	Variable R43 = calratio[6]
	Variable R44 = calratio[7]
	Variable R54 = calratio[8]
	
	make /d/o params = {l1,h1,l2,h2,l3,h3,l4,h4,l5,    R11,R21,R22,R32,R33,R43,R44,R54}
	freplace(params, nan, -1)

	// Calculation begins... All code below here is identical for all sites.
	GenAlgo( iter, params, numvars )
	
	wave bestsolution = root:GenAlgo:solution0

	// Set the K variables to the best solution
	variable sol = smo_GenAnswer(params, bestsolution, numvars, fitcoefs)
	print "Best solution: "+ num2str(sol) + "  with " + num2str(K10) + " penalty."

	// Create the adjust wave
	CreateAdjustWave(mol)

end

// Returns the value from min function
Function/d smo_GenAnswer(params, deltas, numvars, fitcoefs)
	wave /d params, deltas, fitcoefs
	variable numvars
	
	Variable l1 = params[0]
	Variable h1 = params[1]
	Variable l2 = params[2]
	Variable h2 = params[3]
	Variable l3 = params[4]
	Variable h3 = params[5]
	Variable l4 = params[6]
	Variable h4 = params[7]
	Variable l5 = params[8]
	Variable R11 = params[9]
	Variable R21 = params[10]
	Variable R22 = params[11]
	Variable R32 = params[12]
	Variable R33 = params[13]
	Variable R43 = params[14]
	Variable R44 = params[15]
	Variable R54 = params[16]
	variable/d val

	// Ratio of cals
	variable/d x11 = (l1+deltas[0])/(h1+deltas[1])
	variable/d x21 = (l2+deltas[2])/(h1+deltas[1])
	variable/d x22 = (l2+deltas[2])/(h2+deltas[3])
	variable/d x32 = (l3+deltas[4])/(h2+deltas[3])
	variable/d x33 = (l3+deltas[4])/(h3+deltas[5])
	variable/d x43 = (l4+deltas[6])/(h3+deltas[5])
	variable/d x44 = (l4+deltas[6])/(h4+deltas[7])
	variable/d x54 = (l5+deltas[8])/(h4+deltas[7])

	//  Determine which fit was used (linear or poly 3)
	Variable AA = fitcoefs[0]
	Variable BB = fitcoefs[1]
	Variable CC = 0
	if (numpnts(fitcoefs) == 3)
		CC = fitcoefs[3]
	endif

	variable/d f11 = x11^2 * CC + x11 * BB + AA
	variable/d f21 = x21^2 * CC + x21 * BB + AA
	variable/d f22 = x22^2 * CC + x22 * BB + AA
	variable/d f32 = x32^2 * CC + x32 * BB + AA
	variable/d f33 = x33^2 * CC + x33 * BB + AA
	variable/d f43 = x43^2 * CC + x43 * BB + AA
	variable/d f44 = x44^2 * CC + x44 * BB + AA
	variable/d f54 = x54^2 * CC + x54 * BB + AA
		
	if (R11 == -1) 
		f11 = -1
	endif
	if (R21 == -1)
		f21 = -1
	endif
	if (R22 == -1)
		f22 = -1
	endif
	if (R32 == -1)
		f32 = -1
	endif
	if (R33 == -1)
		f33 = -1
	endif
	if (R43 == -1)
		f43 = -1
	endif
	if (R44 == -1)
		f44 = -1
	endif
	if (R54 == -1)
		f54 = -1
	endif

	val += abs((R11-f11)) 
	val += abs((R21-f21)) 
	val += abs((R22-f22)) 
	val += abs((R32-f32)) 
	val += abs((R33-f33)) 
	val += abs((R43-f43)) 
	val += abs((R44-f44)) 
	val += abs((R54-f54)) 
	
//	K1 = abs((R11-f11)) 
//	K2 = abs((R21-f21)) 
//	K3 = abs((R22-f22)) 
//	K4 = abs((R32-f32)) 
//	K5 = abs((R33-f33)) 
//	K6 = abs((R43-f43)) 
//	K7 = abs((R44-f44)) 
//	K8 = abs((R54-f54)) 
	K0 = val

	// Calculate a penalty
	variable pen, mr, del, inc = 0
	do
		del = deltas[inc]
		mr = params[inc] * 0.005
//		mr = params[inc] * 0.01
		if (( abs(del) > mr) *  (params[inc] != 1))
//			if (inc >= 2)
				pen += abs(del-mr) / 5
//			endif
		endif
		inc += 1	
	while (inc < numvars)
	
	K10 = pen
	
	return val + pen
	
End

// Updated Feb. 2002
// Added poly 3
function brwGenAlgo(mol, iter)
	string mol
	variable iter
	
	wave calratio = $mol+"_calRatios"
	wave calratioN = $mol + "_calRatios_num"
	wave lcal = $mol + "_lcalval"
	wave hcal = $mol + "_hcalval"
	wave fitcoefs = $mol + "_fitcoefs"
	variable numvars, inc
	string com

	string tanklst = "ALM65130;ALM66834;ALM65158;ALM38422;ALM65994;ALM64612a;ALM64445;ALM67682;"
	MakeTextWaveFromList(tanklst, "tankwv", ";")
	wave /t tankwv = tankwv

	numvars = numpnts(tankwv)					// one for each unknown variable.
	Variable l1 = GetALMconc(mol, tankwv[0])
	Variable h1 = GetALMconc(mol, tankwv[1])
	Variable l2 = GetALMconc(mol, tankwv[2])
	Variable h2 = GetALMconc(mol, tankwv[3])
	Variable l3 = GetALMconc(mol, tankwv[4])
	Variable h3 = GetALMconc(mol, tankwv[5])
	Variable l4 = GetALMconc(mol, tankwv[6])
	Variable h4 = GetALMconc(mol, tankwv[7])
	Variable R11 = calratio[0]
	Variable R21 = calratio[1]
	Variable R22 = calratio[2]
	Variable R32 = calratio[3]
	Variable R33 = calratio[4]
	Variable R43 = calratio[5]
	
	make /d/o params = {l1,h1,l2,h2,l3,h3,l4,h4,   R11,R21,R22,R32,R33,R43}
	freplace(params, nan, -1)

	// Calculation begins... All code below here is identical for all sites.
	GenAlgo( iter, params, numvars )
	
	wave bestsolution = root:GenAlgo:solution0

	// Set the K variables to the best solution
	variable sol = brw_GenAnswer(params, bestsolution, numvars, fitcoefs)
	print "Best solution: "+ num2str(sol) + "  with " + num2str(K10) + " penalty."

	// Create the adjust wave
	CreateAdjustWave(mol)

end

// Returns the value from min function
Function/d brw_GenAnswer(params, deltas, numvars, fitcoefs)
	wave /d params, deltas, fitcoefs
	variable numvars
	
	Variable l1 = params[0]
	Variable h1 = params[1]
	Variable l2 = params[2]
	Variable h2 = params[3]
	Variable l3 = params[4]
	Variable h3 = params[5]
	Variable l4 = params[6]
	Variable h4 = params[7]
	Variable R11 = params[8]
	Variable R21 = params[9]
	Variable R22 = params[10]
	Variable R32 = params[11]
	Variable R33 = params[12]
	Variable R43 = params[13]
	Variable R44 = params[14]

	variable/d val
	variable/d x11 = (l1+deltas[0])/(h1+deltas[1])
	variable/d x21 = (l2+deltas[2])/(h1+deltas[1])
	variable/d x22 = (l2+deltas[2])/(h2+deltas[3])
	variable/d x32 = (l3+deltas[4])/(h2+deltas[3])
	variable/d x33 = (l3+deltas[4])/(h3+deltas[5])
	variable/d x43 = (l4+deltas[6])/(h3+deltas[5])
	variable/d x44 = (l4+deltas[6])/(h4+deltas[7])

	//  Determine which fit was used (linear or poly 3)
	Variable AA = fitcoefs[0]
	Variable BB = fitcoefs[1]
	Variable CC = 0
	if (numpnts(fitcoefs) == 3)
		CC = fitcoefs[3]
	endif

	// Calculate answers
	variable/d f11 = x11^2 * CC + x11 * BB + AA
	variable/d f21 = x21^2 * CC + x21 * BB + AA
	variable/d f22 = x22^2 * CC + x22 * BB + AA
	variable/d f32 = x32^2 * CC + x32 * BB + AA
	variable/d f33 = x33^2 * CC + x33 * BB + AA
	variable/d f43 = x43^2 * CC + x43 * BB + AA
	variable/d f44 = x44^2 * CC + x44 * BB + AA
		
	if (R11 == -1)
		f11 = -1
	endif
	if (R21 == -1)
		f21 = -1
	endif
	if (R22 == -1)
		f22 = -1
	endif
	if (R32 == -1)
		f32 = -1
	endif
	if (R33 == -1)
		f33 = -1
	endif
	if (R43 == -1)
		f43 = -1
	endif
	if (R44 == -1)
		f44 = -1
	endif

	val += abs((R11-f11)) 
	val += abs((R21-f21)) 
	val += abs((R22-f22)) 
	val += abs((R32-f32)) 
	val += abs((R33-f33)) 
	val += abs((R43-f43)) 
	val += abs((R44-f44)) 
	
	K1 = abs((R11-f11)) 
	K2 = abs((R21-f21)) 
	K3 = abs((R22-f22)) 
	K4 = abs((R32-f32)) 
	K5 = abs((R33-f33)) 
	K6 = abs((R43-f43)) 
	K7 = abs((R44-f44)) 
	K0 = val

	// Calculate a penalty
	variable pen, mr, del, inc = 0
	do
		del = deltas[inc]
		mr = params[inc] * 0.005
		if (( abs(del) > mr) *  (params[inc] != 1))
			pen += abs(del-mr) / 5
		endif
		inc += 1	
	while (inc < numvars)
	
	K10 = pen
	
	return val //+ pen
	
End

// Updated March 2002
function spoGenAlgo(mol, iter)
	string mol
	variable iter
	
	wave calratio = $mol+"_calRatios"
	wave calratioN = $mol + "_calRatios_num"
	wave lcal = $mol + "_lcalval"
	wave hcal = $mol + "_hcalval"
	wave fitcoefs = $mol + "_fitcoefs"
	variable numvars, inc
	string com

	string tanklst = "ALM32489;ALM38416;ALM52764;ALM52780;ALM52750;ALM64981;ALM66008;ALM64446;ALM66844;ALM66027;ALM65178a;ALM65130a;"
	
	MakeTextWaveFromList(tanklst, "tankwv", ";")
	wave /t tankwv = tankwv

	numvars = numpnts(tankwv)	// one for each unknown variable.
	Variable l1 = GetALMconc(mol,  tankwv[0])
	Variable h1 = GetALMconc(mol,  tankwv[1])
	Variable l2 = GetALMconc(mol,  tankwv[2])
	Variable h2 = GetALMconc(mol,  tankwv[3])
	Variable l3 = GetALMconc(mol,  tankwv[4])
	Variable h3 = GetALMconc(mol,  tankwv[5])
	Variable l4 = GetALMconc(mol,  tankwv[6])
	Variable h4 = GetALMconc(mol,  tankwv[7])
	Variable l5 = GetALMconc(mol,  tankwv[8])
	Variable h5 =  GetALMconc(mol,  tankwv[9])
	Variable l6 =  GetALMconc(mol,  tankwv[10])
	Variable h6 =  GetALMconc(mol,  tankwv[11])
	Variable R11 = calratio[0]
	Variable R21 = calratio[1]
	Variable R22 = calratio[2]
	Variable R32 = calratio[3]
	Variable R33 = calratio[4]
	Variable R43 = calratio[6]
	Variable R44 = calratio[7]
	Variable R45 = calratio[8]
	Variable R55 = calratio[9]
	Variable R54 = calratio[10]
	Variable R64 = calratio[11]
	Variable R66 = calratio[12]
	
	make /d/o params = {l1,h1,l2,h2,l3,h3,l4,h4,l5,h5,l6,h6,   R11,R21,R22,R32,R33,R43,R44,R45,R55,R54,R64,R66}
	freplace(params, nan, -1)

	// Calculation begins... All code below here is identical for all sites.
	GenAlgo( iter, params, numvars )
	
	wave bestsolution = root:GenAlgo:solution0

	// Set the K variables to the best solution
	variable sol = spo_GenAnswer(params, bestsolution, numvars, fitcoefs)
	print "Best solution: "+ num2str(sol) + "  with " + num2str(K10) + " penalty."

	// Create the adjust wave
	CreateAdjustWave(mol)
	
	// Extra for the SPO function...
	wave adj = $(mol + "_adjust")
	insertpoints numpnts(adj), 1, adj, tankwv
	tankwv[numpnts(adj)-1] = "ALM64446r"
	adj[numpnts(adj)-1] = adj[7]
	
end

// Returns the value from min function
Function/d spo_GenAnswer(params, deltas, numvars, fitcoefs)
	wave /d params, deltas, fitcoefs
	variable numvars
	
	Variable l1 = params[0]
	Variable h1 = params[1]
	Variable l2 = params[2]
	Variable h2 = params[3]
	Variable l3 = params[4]
	Variable h3 = params[5]
	Variable l4 = params[6]
	Variable h4 = params[7]
	Variable l5 = params[8]
	Variable h5 = params[9]
	Variable l6 = params[10]
	Variable h6 = params[11]
	Variable R11 = params[12]
	Variable R21 = params[13]
	Variable R22 = params[14]
	Variable R32 = params[15]
	Variable R33 = params[16]
	Variable R43 = params[17]
	Variable R44 = params[18]
	Variable R45 = params[19]
	Variable R55 = params[20]
	Variable R54 = params[21]
	Variable R64 = params[22]
	Variable R66 = params[23]
	variable/d val

	variable/d x11 = (l1+deltas[0])/(h1+deltas[1])
	variable/d x21 = (l2+deltas[2])/(h1+deltas[1])
	variable/d x22 = (l2+deltas[2])/(h2+deltas[3])
	variable/d x32 = (l3+deltas[4])/(h2+deltas[3])
	variable/d x33 = (l3+deltas[4])/(h3+deltas[5])
	variable/d x43 = (l4+deltas[6])/(h3+deltas[5])
	variable/d x44 = (l4+deltas[6])/(h4+deltas[7])
	variable/d x45 = (l4+deltas[6])/(h5+deltas[9])
	variable/d x55 = (l5+deltas[8])/(h5+deltas[9])
	variable/d x54 = (l5+deltas[8])/(h4+deltas[7])		// ALM64446r
	variable/d x64 = (l6+deltas[10])/(h4+deltas[7])
	variable/d x66 = (l6+deltas[10])/(h6+deltas[11])

	//  Determine which fit was used (linear or poly 3)
	Variable AA = fitcoefs[0]
	Variable BB = fitcoefs[1]
	Variable CC = 0
	if (numpnts(fitcoefs) == 3)
		CC = fitcoefs[3]
	endif

	variable/d f11 = x11^2 * CC + x11 * BB + AA
	variable/d f21 = x21^2 * CC + x21 * BB + AA
	variable/d f22 = x22^2 * CC + x22 * BB + AA
	variable/d f32 = x32^2 * CC + x32 * BB + AA
	variable/d f33 = x33^2 * CC + x33 * BB + AA
	variable/d f43 = x43^2 * CC + x43 * BB + AA
	variable/d f44 = x44^2 * CC + x44 * BB + AA
	variable/d f45 = x45^2 * CC + x45 * BB + AA
	variable/d f55 = x55^2 * CC + x55 * BB + AA
	variable/d f54 = x54^2 * CC + x54 * BB + AA
	variable/d f64 = x64^2 * CC + x64 * BB + AA
	variable/d f66 = x66^2 * CC + x66 * BB + AA

		
	if (R11 == -1)
		f11 = -1
	endif
	if (R21 == -1)
		f21 = -1
	endif
	if (R22 == -1)
		f22 = -1
	endif
	if (R32 == -1)
		f32 = -1
	endif
	if (R33 == -1)
		f33 = -1
	endif
	if (R43 == -1)
		f43 = -1
	endif
	if (R44 == -1)
		f44 = -1
	endif
	if (R45 == -1)
		f45 = -1
	endif
	if (R55 == -1)
		f55 = -1
	endif
	if (R54 == -1)
		f54 = -1
	endif
	if (R64 == -1)
		f64 = -1
	endif
	if (R66 == -1)
		f66 = -1
	endif

	val += abs((R11-f11)) 
	val += abs((R21-f21)) 
	val += abs((R22-f22)) 
	val += abs((R32-f32)) 
	val += abs((R33-f33)) 
	val += abs((R43-f43)) 
	val += abs((R44-f44)) 
	val += abs((R45-f45)) 
	val += abs((R55-f55)) 
	val += abs((R54-f54)) 
	val += abs((R64-f64)) 
	val += abs((R66-f66)) 
	
	K0 = val

	// Calculate a penalty if the delta is greater that 0.5% of the mixing ratio assigned.
	variable pen, mr, del, inc = 0
	do
		del = deltas[inc]
		mr = params[inc] * 0.005
//		mr = params[inc] * 0.01
		if (( abs(del) > mr) *  (params[inc] != 1))
			pen += abs(del-mr) / 5
		endif
	
		inc += 1	
	while (inc < numvars)
	
	K10 = pen
	
	return val + pen
	
End




Function GenAlgo( iter, params, numDep )
	variable iter 							// Number of iterations
	wave params							// parameterized wave
	variable numDep 						// Number of dependent variables to solve for. (the deltas)

	variable numSolutions = 15				// Number of soultion to carry each step.
	
	String savedDF= GetDataFolder(1)	
	NewDataFolder /o/s root:GenAlgo
	
	make /o/d/n=(numSolutions) solutions = nan, solind = nan

	string sol
	variable inc  = 0

	// intial stats
	do
		sol = "solution" + num2str(inc)
		make /o/n=(numDep) $sol = gnoise(1)
		inc += 1
	while (inc < numSolutions)
	// A few pre-defined solutions
	make /o/n=(numDep) solution0 = 0
	make /o/n=(numDep) solution1 = 0.1
	do
		if (mod(inc,2) == 0)
			solution1 *= -1
		endif
		inc +=1
	while (inc < numDep)
	make /o/n=(numDep) solution2 = solution1 * -1
	make /o/n=(numDep) solution3 = gnoise(.5)
	make /o/n=(numDep) solution4 = gnoise(.5)
	make /o/n=(numDep) solution5 = gnoise(.5) * solution1
	make /o/n=(numDep) solution6 = gnoise(.5) * solution2

	// Create temp Solution Waves
	inc  = 0
	string tmpsol
	do
		tmpsol = "tmpsol" + num2str(inc)
		make /o/n=(numDep) $tmpsol = 0
		inc += 1
	while (inc < numSolutions)
	
	make /o/n=(iter) sol_improve = nan
	
	inc = 0	
	do
		CalculateSolutions(numSolutions, solutions, solind, params, numDep)
		sol_improve[inc] = solutions[0]
		PruneChromasomes(solutions, solind, 7, numSolutions)
		FillChromasomes(solutions, solind, 7, numSolutions)
		inc += 1
	while (inc < iter)

	SetDataFolder savedDF

end

function CalculateSolutions(numSolutions, solutions, solind, params, numDep)
	variable numSolutions, numDep
	wave/d solutions, params
	wave solind

	variable inc =0
	string solStr
	SVAR site = root:G_site3
	SVAR mol = root:G_mol
	wave fitcoefs = root:$mol + "_fitcoefs"
	
	do
		solStr = "solution" + num2str(inc)
		wave sol = $solStr
		if (cmpstr(site, "mlo") == 0)
			solutions[inc] = mlo_GenAnswer(params, sol, numDep)
		elseif (cmpstr(site, "brw") == 0)
			solutions[inc] = brw_GenAnswer(params, sol, numDep, fitcoefs)
		elseif (cmpstr(site, "smo") == 0)
			solutions[inc] = smo_GenAnswer(params, sol, numDep, fitcoefs)
		elseif (cmpstr(site, "spo") == 0)
			solutions[inc] = spo_GenAnswer(params, sol, numDep, fitcoefs)
		endif
		solind[inc] = inc
		inc += 1
	while (inc < numSolutions)	
	
end

// Keeps the best solutions
function PruneChromasomes(solutions, solind, keep, numSolutions)
	wave/d solutions
	wave solind
	variable keep, numSolutions
	
	variable inc
	string tmpSTR, solSTR
	
	// sort best to worst solutions
	Sort solutions solind,solutions
	
	do
		tmpSTR = "tmpsol" + num2str(inc)
		solSTR = "solution" + num2str(solind[inc])
		wave tmp = $tmpSTR
		wave sol = $solSTR
		tmp = sol
		if (inc >= keep)
			tmp = 0
		endif
		inc += 1
	while ( inc < numSolutions )
	
end	

// Removes the worst solutions and replaces with new chromasomes.
function FillChromasomes(solutions, solind, keep, numSolutions)
	wave/d solutions
	wave solind
	variable keep, numSolutions
	
	variable inc = keep
	variable good1, good2, meth
	string sol1str, sol2str
	string tmpSTR, solSTR
	variable /d solscale = solutions[0]

	inc = keep
	do
		tmpSTR = "tmpsol" + num2str(inc)
		good1 = round(abs(enoise(1) * (keep-1)))
		do 
			good2 = round(abs(enoise(1) * (keep-1)))
		while (good2 == good1)
		
		sol1str = "solution" + num2str(good1)
		sol2str = "solution" + num2str(good2)
		wave tmp = $tmpSTR
		wave sol1 = $sol1str
		wave sol2 = $sol2str
		
		// fill in missing chroms.
		meth = round(abs(enoise(10)))
		if (meth == 1)
			CrossGenes (sol1, sol2, tmp)
		elseif ((meth == 2) + (meth > 6))
			MutateGenes (sol1, tmp)			// Used more often then the other methods
		elseif (meth == 3)
			TweekGenes (sol1, tmp)
		elseif (meth == 4)
			tmp = (sol1 + sol2)/2 + gnoise(solscale*10)
		elseif (meth == 5)
			tmp = sol1 * gnoise(solscale*10)
		elseif (meth == 6)
			ShiftGenes(sol1, tmp)
		endif

		inc += 1
	while (inc < numSolutions)
	
	// put tmpsol to solutions
	inc = 0
	do
		tmpSTR = "tmpsol" + num2str(inc)
		solSTR = "solution" + num2str(inc)
		wave tmp = $tmpSTR
		wave sol = $solSTR
		sol = tmp
		inc += 1
	while (inc < numSolutions)

end


// Mutate genes from two good solutions to generate a new solution
function MutateGenes(sol, newsol)
	wave sol, newsol
	
	
	variable numChroms = numpnts(sol), inc
	variable num2mut = round(abs(enoise(3)))
	variable tweekgene

	newsol = sol	
	do
		tweekgene = abs(enoise(numChroms-1))
		newsol[tweekgene] =  gnoise(newsol[tweekgene])
		inc += 1
	while (inc < num2mut)

end

// Mix or mutate genes from two good solutions to generate a new solution
function CrossGenes(sol1, sol2, newsol)
	wave sol1, sol2, newsol
	
	
	variable numChroms = numpnts(sol), inc
	variable num2cross = round(abs(enoise(3)))
	variable tweekgene
	wave solutions = root:genalgo:solutions
	variable /d solscale = solutions[0]
	
	newsol = sol1
	do
		tweekgene = abs(enoise(numChroms-1))
		newsol[tweekgene] =  sol2[tweekgene] + gnoise(solscale * 5)
		inc += 1
	while (inc < num2cross)

end

// Move values of genes
function TweekGenes (sol, newsol)
	wave sol, newsol
	
	variable numChroms = numpnts(sol), inc
	variable num2tweek = round(abs(enoise(3)))
	variable tweekgene
	wave solutions = root:genalgo:solutions
	variable /d solscale = solutions[0]

	newsol = sol	
	do
		tweekgene = abs(enoise(numChroms-1))
		newsol[tweekgene] +=  gnoise(solscale * 10)
		inc += 1
	while (inc < num2tweek)

end

// Shift each chromisome in gene
function ShiftGenes(sol, newsol)
	wave sol, newsol
	
	variable numChroms = numpnts(sol), inc, tmp
	
	do
		newsol[inc] = sol[inc+1]
		inc += 1
	while (inc < numChroms)
	newsol[inc] = sol[0]

end


function testeql(wv1, wv2)
	wave wv1, wv2
	
	variable num = numpnts(wv1), inc
	
	do
		if (wv1[inc]!= wv2[inc])
			return 0
		endif
		Inc += 1
	while (inc < num)

	return 1
	
end


Function CreateAdjustWave(mol)
	string mol
	
	string adjSTR = mol + "_adjust"
	wave tank = $"tankwv"
	
	// Remove old string variable technique
	if (exists(adjSTR) == 2)
		execute("killstrings " + mol + "_adjust")
	endif
	
	make /o/d/n=(numpnts(tank)) $adjSTR
	wave adj = $adjSTR
	wave bestsolution = root:GenAlgo:solution0

	variable inc = 0	
	do
		adj[inc] = bestsolution[inc]
		inc += 1
	while (inc < numpnts(tank))
	
end

//Function adjustWv_toSolutionWv(mol)
	string mol
	
	string adjustSTR = mol + "_adjust"
	string adjust = ReturnList(adjustSTR)
	wave sol = $"root:genalgo:solution0"
	variable inc, num =  ItemsInList(adjust, ";")
	
	do
		if (mod(inc,2) == 1)
			if (cmpstr(StringFromList(inc-1, adjust), "ALM64446r") != 0)		// Special case for SPO re-run tank
				sol[floor(inc/2)] = str2num(StringFromList(inc, adjust))
			endif
		endif
		inc += 1
	while (inc < num)
	
end

Function adjustWv_toSolutionWv(mol)
	string mol
	
	wave adj = $(mol + "_adjust")
	wave tank = $"tankwv"
	wave sol = $"root:genalgo:solution0"
	sol = adj

end


// Genalgo solution using cal1 and cal2
#include "macros-CATS GenAlgo"
function conc_genAlg(mol, attrib)
	string mol, attrib
	
	string MR = mol + "_genAlg_conc"
	
	cal12withAdjust( mol, attrib, MR)
end

// Genalgo solution using only cal1
function conc_genAlg1(mol, attrib)
	string mol, attrib
	
	string MR = mol + "_genAlg1_conc"
	
	cal1withAdjust( mol, attrib, MR)
end

// Genalgo solution using only cal2
function conc_genAlg2(mol, attrib)
	string mol, attrib
	
	string MR = mol + "_genAlg2_conc"
	
	cal2withAdjust( mol, attrib, MR)
end

// Genalgo solution using cal1 and cal2 average
function conc_genAlg12a(mol, attrib)
	string mol, attrib
	
	string MR = mol + "_genAlg12a_conc"
	
	conc_genAlg1(mol, attrib)
	conc_genAlg2(mol, attrib)

	wave g1 = $(mol + "_genAlg1_conc")
	wave g2 = $(mol + "_genAlg2_conc")
	make /n=(numpnts(g1)) /o $MR=nan
	wave MRwv = $MR
	MRwv = (g1 + g2) / 2
	
end

// Uses genalgo solution and cal curve fit (function Ratio_CalCurve)
// Average method using both cal1 and cal2
function conc_genAlgFit(mol, attrib)
	string mol, attrib
	
	string MR = mol + "_genAlgFit_conc"
//	SVAR adjust = $mol + "_adjust"
	
	conc_genAlgFit1(mol, attrib)
	wave MR1 = $mol + "_genAlgFit1_conc"
	conc_genAlgFit2(mol, attrib)
	wave MR2 = $mol + "_genAlgFit2_conc"

	make /o/n=(numpnts(MR1)) $MR=nan, MRtemp=NaN, dcal1 = nan, dcal2 = nan
	wave MRwv = $MR

	MRwv = (MR1 + MR2) / 2
	
end

// Uses genalgo solution and cal curve fit (function Ratio_CalCurve)
// Based on only having a cal1 measurment
function conc_genAlgFit1(mol, attrib)
	string mol, attrib
	
	string MR = mol + "_genAlgFit1_conc"
	string stat = mol + "_stat2cal1_conc"
	
	stat2calfit_cal1(mol, attrib, 1)
	wave statwv = $stat

	duplicate /o statwv, $MR
	killwaves statwv

end

// Uses genalgo solution and cal curve fit (function Ratio_CalCurve)
// Based on only having a cal2 measurment
function conc_genAlgFit2(mol, attrib)
	string mol, attrib
	
	string MR = mol + "_genAlgFit2_conc"
	string stat = mol + "_stat2cal2_conc"
	
	stat2calfit_cal2(mol, attrib, 1)
	wave statwv = $stat

	duplicate /o statwv, $MR
	killwaves statwv
	
end


// Uses statistical 2-cal fit (not adjustments due to gen algo).
// Based on only having a cal1 measurment
function conc_stat2cal(mol, attrib)
	string mol, attrib

	string MR = mol + "_stat2cal_conc"
	
	conc_stat2cal1(mol, attrib)
	wave MR1 = $mol + "_stat2cal1_conc"
	conc_stat2cal2(mol, attrib)
	wave MR2 = $mol + "_stat2cal2_conc"

	make /o/n=(numpnts(MR1)) $MR=nan, MRtemp=NaN, dcal1 = nan, dcal2 = nan
	wave MRwv = $MR

	MRwv = (MR1 + MR2) / 2
	
	stat2calfit_cal1(mol, attrib, 0)
	
end


// Uses statistical 2-cal fit (not adjustments due to gen algo).
// Based on only having a cal1 measurment
function conc_stat2cal1(mol, attrib)
	string mol, attrib
	
	stat2calfit_cal1(mol, attrib, 0)
	
end

// Uses statistical 2-cal fit (not adjustments due to gen algo).
// Based on only having a cal2 measurment
function conc_stat2cal2(mol, attrib)
	string mol, attrib
	
	stat2calfit_cal2(mol, attrib, 0)
	
end

// statistical 2-cal fit useing cal1 as reference 
// choise of using genalgo adjusted waves or not
function stat2calfit_cal1(mol, attrib, adj)
	string mol, attrib
	variable adj
	
	string MR = mol + "_stat2cal1_conc"
	
	if (adj == 1)
		MakeStandardWaves_addjust(mol)
	else
		MakeStandardWaves(mol)
	endif
	
	wave day = $(mol + "_date")
	wave lstd = $(mol + "_lstd_conc")
//	wave hstd = $(mol + "_hstd_conc")
	wave flag = $(mol + "_flag")
	wave/d coef = $(mol + "_fitcoefs")			// wave generated by Ratio_CalCurve
	
	wave c1 = $(mol + "_" + attrib + "_2")
	wave a1 = $(mol + "_" + attrib + "_4")
//	wave c2 = $(mol + "_" + attrib + "_6")
	wave a2 = $(mol + "_" + attrib + "_8")
	wave ssv = $(mol + "_port")
	
	variable/d m = coef[1], b = coef[0], c
	
	make /d/o/n=(numpnts(day)) $MR=nan
	wave MRwv = $MR
	print MR

	variable inc = 0
	do
		if (ssv[inc] == 4)	// air1 found
			if ((ssv[inc-1] == 2) * (ssv[inc+3] == 2))
				c = (0.75*c1[inc-1] + 0.25*c1[inc+3])		* flag[inc] * flag[inc-1] * flag[inc+3]
			elseif ((ssv[inc-1] == 2) * (ssv[inc+2] == 2))	// handles case when there is no ssv port 6 in data file
				c = (0.75*c1[inc-1] + 0.25*c1[inc+2])		* flag[inc] * flag[inc-1] * flag[inc+2]
			endif
			MRwv[inc] =m * lstd[inc] / (c/a1[inc] - b)	
		elseif (ssv[inc] == 8) // air2 found
			if ((ssv[inc+1] == 2) * (ssv[inc-3] == 2))
				c = (0.75*c1[inc+1] + 0.25*c1[inc-3])		* flag[inc] * flag[inc+1] * flag[inc-3]
			elseif ((ssv[inc+1] == 2) * (ssv[inc-2] == 2))	// handles case when there is no ssv port 6 in data file
				c = (0.75*c1[inc+1] + 0.25*c1[inc-2])		* flag[inc] * flag[inc+1] * flag[inc-2]
			endif
			MRwv[inc] = m * lstd[inc] / (c/a2[inc] - b)	
		endif
		inc += 1
	while (inc < numpnts(day))

end

// statistical 2-cal fit useing cal2 as reference 
// choise of using genalgo adjusted waves or not
function stat2calfit_cal2(mol, attrib, adj)
	string mol, attrib
	variable adj
	
	string MR = mol + "_stat2cal2_conc"
	
	if (adj == 1)
		MakeStandardWaves_addjust(mol)
	else
		MakeStandardWaves(mol)
	endif
	
	wave day = $(mol + "_date")
//	wave lstd = $(mol + "_lstd_conc")
	wave hstd = $(mol + "_hstd_conc")
	wave flag = $(mol + "_flag")
	wave/d coef = $(mol + "_fitcoefs")			// wave generated by Ratio_CalCurve
	
//	wave c1 = $(mol + "_" + attrib + "_2")
	wave a1 = $(mol + "_" + attrib + "_4")
	wave c2 = $(mol + "_" + attrib + "_6")
	wave a2 = $(mol + "_" + attrib + "_8")
	wave ssv = $(mol + "_port")

	variable/d m = coef[1], b = coef[0], c
	
	make /d/o/n=(numpnts(day)) $MR=nan
	wave/d MRwv = $MR

	variable inc = 0
	do
		if (ssv[inc] == 4)	// air1 found
			if ((ssv[inc+1] == 6) * (ssv[inc-3] == 6))
				c = (0.75*c2[inc+1] + 0.25*c2[inc-3])			* flag[inc]*flag[inc+1]*flag[inc-3]
			elseif ((ssv[inc+1] == 6) * (ssv[inc-2] == 6))	// handles case when there is no ssv port 2 in data file
				c = (0.75*c2[inc+1] + 0.25*c2[inc-2]) 			* flag[inc]*flag[inc+1]*flag[inc-2]
			endif
			MRwv[inc] = hstd[inc]/m * (a1[inc]/c - b)
		elseif (ssv[inc] == 8) // air2 found
			if ((ssv[inc-1] == 6) * (ssv[inc+3] == 6))
				c = (0.75*c2[inc-1] + 0.25*c2[inc+3])			* flag[inc]*flag[inc-1]*flag[inc+3]
			elseif ((ssv[inc-1] == 6) * (ssv[inc+2] == 6))	// handles case when there is no ssv port 2 in data file
				c = (0.75*c2[inc-1] + 0.25*c2[inc+2])			* flag[inc]*flag[inc-1]*flag[inc+2]
			endif
			MRwv[inc] = hstd[inc]/m * (a2[inc]/c - b)	
		endif
		inc += 1
	while (inc < numpnts(day))
	
end

function cal1withAdjust( mol, attrib, MR)
	string mol, attrib, MR

	MakeStandardWaves_addjust(mol)
	
	wave day = $(mol + "_date")
	wave lstd = $(mol + "_lstd_conc")
	wave hstd = $(mol + "_hstd_conc")
	wave flag = $(mol + "_flag")
	
	wave c1 = $(mol + "_" + attrib + "_2")
	wave a1 = $(mol + "_" + attrib + "_4")
//	wave c2 = $(mol + "_" + attrib + "_6")
	wave a2 = $(mol + "_" + attrib + "_8")
	wave ssv = $(mol + "_port")
	
	make /d/o/n=(numpnts(day)) $MR=nan
	wave MRwv = $MR

	variable inc = 0
	do
		if (ssv[inc] == 4)	// air1 found
			if ((ssv[inc-1] == 2) * (ssv[inc+3] == 2))
				MRwv[inc] = lstd[inc] * a1[inc] / ((c1[inc-1] - c1[inc+3])*0.25 + c1[inc-1])	* flag[inc-1] * flag[inc+3]
			elseif ((ssv[inc-1] == 2) * (ssv[inc+2] == 2))	// handles case when there is no ssv port 6 in data file
				MRwv[inc] = lstd[inc] * a1[inc] / ((c1[inc-1] - c1[inc+2])*0.25 + c1[inc-1])	* flag[inc-1] * flag[inc+2]
			endif
		elseif (ssv[inc] == 8) // air2 found
			if ((ssv[inc+1] == 2) * (ssv[inc-3] == 2))
				MRwv[inc] = lstd[inc] * a2[inc] / ((c1[inc-3] - c1[inc+1])*0.75 + c1[inc-3])	* flag[inc+1] * flag[inc-3]
			elseif ((ssv[inc+1] == 2) * (ssv[inc-2] == 2))	// handles case when there is no ssv port 6 in data file
				MRwv[inc] = lstd[inc] * a2[inc] / ((c1[inc-2] - c1[inc+1])*0.75 + c1[inc-2])	* flag[inc+1] * flag[inc-2]
			endif
		endif
		inc += 1
	while (inc < numpnts(day))
	
//	MRwv = 	lstd[p] * a1[p] / ((c1[p-1] - c1[p+3])*0.25 + c1[p-1])	* flag[p-1] * flag[p+3]
//	MRtemp = 	lstd[p] * a2[p] / ((c1[p-3] - c1[p+1])*0.75 + c1[p-3])	* flag[p+1] * flag[p-3]
	
//	freplace(MRwv, NaN, 0)
//	freplace(MRtemp, NaN, 0)
//	MRwv += MRtemp
//	freplace(MRwv, 0, NaN)
	
//	MRwv *= flag
	
end

function cal2withAdjust( mol, attrib, MR)
	string mol, attrib, MR

	MakeStandardWaves_addjust(mol)
	
	wave day = $(mol + "_date")
	wave lstd = $(mol + "_lstd_conc")
	wave hstd = $(mol + "_hstd_conc")
	wave flag = $(mol + "_flag")
	wave ssv = $(mol + "_port")
	
//	wave c1 = $(mol + "_" + attrib + "_2")
	wave a1 = $(mol + "_" + attrib + "_4")
	wave c2 = $(mol + "_" + attrib + "_6")
	wave a2 = $(mol + "_" + attrib + "_8")
	
	make /d/o/n=(numpnts(day)) $MR=nan, MRtemp
	wave MRwv = $MR	
	
	variable inc = 0
	do
		if (ssv[inc] == 4)	// air1 found
			if ((ssv[inc+1] == 6) * (ssv[inc-3] == 6))
				MRwv[inc] = hstd[inc] * a1[inc] / ((c2[inc+1] - c2[inc-3])*0.25 + c2[inc+1])
			elseif ((ssv[inc+1] == 6) * (ssv[inc-2] == 6))	// handles case when there is no ssv port 2 in data file
				MRwv[inc] = hstd[inc] * a1[inc] / ((c2[inc+1] - c2[inc-2])*0.25 + c2[inc+1])
			endif
		elseif (ssv[inc] == 8) // air2 found
			if ((ssv[inc-1] == 6) * (ssv[inc+3] == 6))
				MRwv[inc] = hstd[inc] * a2[inc] / ((c2[inc-1] - c2[inc+3])*0.75 + c2[inc-1])	
			elseif ((ssv[inc-1] == 6) * (ssv[inc+2] == 6))	// handles case when there is no ssv port 2 in data file
				MRwv[inc] = hstd[inc] * a2[inc] / ((c2[inc-1] - c2[inc+2])*0.75 + c2[inc-1])	
			endif
		endif
		inc += 1
	while (inc < numpnts(day))

	MRwv *= flag
	
	killwaves /Z MRtemp

end

function cal12withAdjust( mol, attrib, MR)
	string mol, attrib, MR

	MakeStandardWaves_addjust(mol)
	
	wave day = $(mol + "_date")
	wave lstd = $(mol + "_lstd_conc")
	wave hstd = $(mol + "_hstd_conc")
	wave flag = $(mol + "_flag")
	
	wave c1 = $(mol + "_" + attrib + "_2")
	wave a1 = $(mol + "_" + attrib + "_4")
	wave c2 = $(mol + "_" + attrib + "_6")
	wave a2 = $(mol + "_" + attrib + "_8")
	wave ssv = $(mol + "_port")
	
	make /d/o/n=(numpnts(day)) $MR=nan
	wave MRwv = $MR
	
	variable /d inc, d1, d2
	
	do
		d1 = nan
		d2 = nan
		if (ssv[inc] == 4)  			// air 1 found
			if ((ssv[inc+3] == 2) * (ssv[inc-1] == 2) * (ssv[inc+1] == 6) * (ssv[inc-3] == 6))	// check for correct cal ssv ports
				//d1 = (c1[inc+3] - c1[inc-1])*0.25 + c1[inc-1]
				d1 = c1[inc+3]*0.25 + c1[inc-1]*0.75
				//d2 = (c2[inc+1] - c2[inc-3])*0.75 + c2[inc-3]
				d2 = c2[inc+1]*0.75 + c2[inc-3]*0.25
				MRwv[inc] = lstd[inc] + (hstd[inc] - lstd[inc]) * (a1[inc] - d1)/(d2 - d1)		* flag[inc-3] * flag[inc-1] * flag[inc+1] * flag[inc+3]
			endif
		elseif (ssv[inc] == 8)  		// air 2 found
			if ((ssv[inc+1] == 2) * (ssv[inc-3] == 2) * (ssv[inc-1] == 6) * (ssv[inc+3] == 6))	// check for correct cal ssv ports
				//d1 = (c1[inc+1] - c1[inc-3])*0.75 + c1[inc-3]
				d1 = c1[inc+1]*0.75 + c1[inc-3]*0.25
				//d2 = (c2[inc-1] - c2[inc+3])*0.25 + c2[inc+3]    <--- this is wrong!  GSD 030128
				d2 = c2[inc-1]*0.75 + c2[inc+3]*0.25 
				MRwv[inc] = lstd[inc] + (hstd[inc] - lstd[inc]) * (a2[inc] - d1)/(d2 - d1)		* flag[inc-3] * flag[inc-1] * flag[inc+1] * flag[inc+3]
			endif
		endif
		inc += 1
	while (inc < numpnts(day))


//  Only works if the ssv is 2, 4, 6, 8, 2, ...
//	dcal1 = (c1[p+3] - c1[p-1])*0.25 + c1[p-1]
//	dcal2 = (c2[p+1] - c2[p-3])*0.75 + c2[p-3]
//	MRwv = lstd[p] + (hstd[p] - lstd[p]) * (a1[p] - dcal1)/(dcal2 - dcal1)	* flag[p-3] * flag[p-1] * flag[p+1] * flag[p+3]

//	dcal1 = nan
//	dcal2 = nan
//	dcal1 = (c1[p+1] - c1[p-3])*0.75 + c1[p-3]
//	dcal2 = (c2[p-1] - c2[p+3])*0.25 + c2[p+3]
//	MRtemp = lstd[p] + (hstd[p] - lstd[p]) * (a2[p] - dcal1)/(dcal2 - dcal1)	* flag[p-3] * flag[p-1] * flag[p+1] * flag[p+3]
		
//	freplace(MRwv, NaN, 0)
//	freplace(MRtemp, NaN, 0)
//	MRwv += MRtemp
//	freplace(MRwv, 0, NaN)

//	MRwv *= flag

//	killwaves /Z MRtemp, dcal1, dcal2

end


