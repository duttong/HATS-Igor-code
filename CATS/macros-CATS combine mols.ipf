#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=1		// Use modern global access method.

#include "macros-Strings and Lists"
#include <concatenate waves>

Proc EditCombTable( mol ) : Table
	string mol = G_mol
	prompt mol, "Molecule", popup, "N2O;F11;F12;F113;H1211;"
	
	silent 1
	
	G_mol = mol
	string combdate = mol + "_comb_date"
	string combmeth = mol + "_comb_meth"
	string win = mol + "combTable"
	
	if (exists(combdate) == 0 )
		make /t/n=2 $combdate="19970101.0000"
		make /t/n=2 $combmeth=mol
	endif
	
	DoWindow /K $win
	Edit/W=(892,410,1290,689) $combdate,$combmeth
	ModifyTable width($combdate)=128,width($combmeth)=138
	DoWindow /C $win
EndMacro


Proc CombineDataSets(mol )
	string mol = G_mol
	prompt mol, "Molecule", popup, "N2O;F11;F12;F113;H1211;"
	
	silent 1
	
	if (exists(mol + "_comb_date") == 0 )
		abort "First run EditCombTable to create combine table."
	endif
	
	G_mol = mol

	G_loadMol = AddElementToList(G_loadMol, mol+"comb", ";")
	G_loadMol = Sortlist(G_loadMol)

	// make flag type wave
	make /o/n=(numpnts($mol+"comb_date")) $mol+"comb_flagtype" = NO_FLAG
	
	CombineDataSetsFUNCT( mol )
	
//	WeeklyAvg(mol=mol+"comb", attrib="H")

end

function CombineDataSetsFUNCT( mol )
	string mol
	
	string combdatestr = mol + "_comb_date"
	string combmethstr = mol + "_comb_meth"
	
	string datewvstr = mol + "_comb_date"
	string combstr = mol + "comb_best_conc"
	string d1, d2, datestr, meth, mol1, mol2, mol3, attrib
	variable inc
	variable /d datevalL, datevalR, L, R, IL, IR
	
	if (exists(combdatestr) == 0 )
		abort combdatestr + " does not exists."
	endif
	
	wave /t combdate = $combdatestr
	wave /t combmeth = $combmethstr
	
	make /o/d/n=0 $combstr, $mol + "comb_date"
	make /o/n=0 $combstr, $mol + "comb_H_SD", $mol + "comb_port"
	wave comb = $combstr
	wave combX = $mol + "comb_date"
	wave combSD = $mol + "comb_H_SD"
	wave combport = $mol + "comb_port"
	SetScale d 0,0,"dat", combX
	
	do
		meth = combmeth[inc]
		if ( ItemsInList( meth ) == 1)
			wave conc = $meth + "_best_conc_hourlyY"
			wave concX = $meth + "_date"
			attrib = ReturnIntAttrib(mol=meth) 
			wave concSD = $meth + "_" + attrib + "_SD"
			wave concport = $meth + "_port"
		elseif ( ItemsInList( meth ) == 2)
			mol1 = StringFromList( 0, meth)
			mol2 = StringFromList( 1, meth )
			WeightedAverage($mol1 + "_best_conc_hourlyY", $mol2 + "_best_conc_hourlyY", mol+"mix")
			wave conc = $mol + "mix"
			wave concX = $mol + "mix_date"
			wave concSD = $mol + "mix_H_sd"
			wave concport = $mol + "mix_port"
		elseif ( ItemsInList( meth ) == 3)
			abort "need to program 3 item method."
		else
			abort "Too many molecules in methods list at inc = " + num2str(inc)
		endif
		datevalL = date_return(combdate[inc])
		datevalR = date_return(combdate[inc+1])
		L = BinarySearch(concX, datevalL)
		R = BinarySearch(concX, datevalR)

		if (L == -1 ) 
			L = 0 
		endif
		if (( R == -1 ) + ( R == -2 ))
			R = numpnts(conc) -1
		endif
		if (inc == numpnts(combdate) -1)
			R = numpnts(conc) -1
		endif
//print meth, datevalL, datevalR, L, R	

		IL = numpnts(comb)
		IR = IL + (R-L) + 1
		insertpoints IL, R-L, comb, combX, combSD, combport
		comb[IL, IR] = conc[L+p-IL]
		combX[IL, IR] = concX[L+p-IL]
		combSD[IL, IR] = concSD[L+p-IL]
		combport[IL, IR] = concport[L+p-IL]
		

		// flagging
		make /n=(numpnts(comb))/o $mol+"comb_flag"=1
//		wave flag = $mol+"_flag"
		make /n=(numpnts(comb))/o $mol+"comb_manflag"=1
//		wave manflag = $mol+"comb_manflag"
		
		// use permanent flags
		if (exists(mol+"comb_permflag") == 1)
			preserveflags(mol +"comb")
		else
			make /d/n=(0)/o $mol+"comb_permflag"
			SetScale d 0,0,"dat", $mol+"comb_permflag"
		endif
		
		// Cleanup
		if ( ItemsInList( meth ) == 2)
			killwaves $mol + "mix", $mol + "mix_date", $mol + "mix_H_sd", $mol + "mix_port"
		endif
		
		inc += 1
	while (inc < numpnts(combdate))

	// save all data (flagged and unflagged)
	string all = mol + "comb_best_conc_flg"
	duplicate /o comb, $all
	wave flg = $all

	WeeklyAvg(mol=mol+"comb", attrib="H")
	createYYYYMMDDwaves( mol+"comb" )
	
end

function createYYYYMMDDwaves( combmol )
	string combmol
	
	wave /d concX = $combmol + "_date"
	string YYYYstr = combmol + "_YYYY"
	string MMstr = combmol + "_MM"
	string DDstr = combmol + "_DD"
	
	make /o/n=(numpnts(concX)) $YYYYstr, $MMstr, $DDstr
	wave YYYY = $YYYYstr
	wave MM = $MMstr
	wave DD = $DDstr
	
	YYYY = str2num(StringFromList(2, Secs2Date(concX,-1), "/"))
	MM = str2num(StringFromList(1, Secs2Date(concX,-1), "/"))
	DD = str2num(StringFromList(0, Secs2Date(concX,-1), "/"))
	
end

// function returns a list of unique molecule names in the entire mol_comb_meth wave
function /s  retcompmollist( meth )
	wave /t meth
	
	string uniquemols = "", tmpmols, mol
	variable inc, ind
	
	do
		tmpmols = meth[inc]
		ind = 0
		do
			mol = StringFromList(ind, tmpmols, ";")
			if (FindListItem(mol, uniquemols, ";") == -1 )
				uniquemols = uniquemols + mol + ";"
			endif
			ind += 1
		while ( ind < ItemsInList( tmpmols, ";" ))
		inc += 1
	while (inc < numpnts(meth))
	
	return uniquemols
end

// H is hardwired!!!!! -- FIXED 081221
function WeightedAverage(c1, c2, new)
	wave c1, c2
	string new
	
	variable /d num1 = numpnts(c1), inc1, p1, lastfound
	variable /d num2 = numpnts(c2), inc2, p2
	variable /d num3, inc3, p3
	string mol1 = StringFromList(0, NameOfWave(c1), "_")
	string mol2 = StringFromList(0, NameOfWave(c2), "_")
	string attrib1 = ReturnIntAttrib(mol=mol1) 
	string attrib2 = ReturnIntAttrib(mol=mol2) 
	
	wave /d t1 = $mol1 + "_date"
	wave dc1 = $mol1 + "_" + attrib1 + "_sd"
	wave port1 = $mol1 + "_port"
	wave /d t2 = $mol2 + "_date"
	wave dc2 = $mol2 + "_" + attrib2 + "_sd"
	wave port2 = $mol2 + "_port"
	
	string c3s = new
	string dc3s = new + "_H_sd"		// using H for comb
	string t3s = c3s + "_date"
	string port3s = c3s + "_port"

	CombineTimeWaves(t1, t2, new)

	wave /d t3 = $t3s
	SetScale d 0,0,"dat", t3

	num3 = numpnts(t3)
	make /d/o/n=(num3) $c3s=nan, $dc3s = nan, $port3s = nan
	
	wave c3 = $c3s
	wave dc3 = $dc3s
	wave port3 = $port3s
	
	variable /d delta, dL, dR, greatest
	inc3 = 0
	do
		p3 = t3[inc3]
		p1 = BinarySearch(t1, p3)
		p2 = BinarySearch(t2, p3)
		// print inc3, p3, p1, p2
		if (numtype(c1[p1]) != 0)			// if c1 is a nan use c2
			c3[inc3] = c2[p2]
			dc3[inc3] = dc2[p2]
			port3[inc3] = port2[p2]
		elseif (numtype(c2[p2]) != 0)		// if c2 is a nan use c1
			c3[inc3] = c1[p1]
			dc3[inc3] = dc1[p1]
			port3[inc3] = port1[p1]
		else										// use weighted average of c1 and c2
			dc3[inc3] = ((1/dc1[p1])^2 + (1/dc2[p2])^2)^(-0.5)
			c3[inc3] = (c1[p1]/dc1[p1]^2 + c2[p2]/dc2[p2]^2) * dc3[inc3]^2
			port3[inc3] = port1[p1]
		endif
		inc3 += 1
	while (inc3 < num3)
	
//	print "Used: " + Nameofwave(c1) + " and " + Nameofwave(c2) + " to create:", c3s, dc3s, t3s
		
end


function CombineTimeWaves(time1, time2, new)
	wave time1, time2
	string new
	
	string t3s = new + "_date"
	string flagstr = "timeflagtemp"
	variable delpnt

	make /d/o/n=0 $t3s
	wave timenew = $t3s
	
	ConcatenateWaves(t3s, NameOfWave(time1))
	ConcatenateWaves(t3s, NameOfWave(time2))
	
	make /n=(numpnts(timenew)) $flagstr
	wave flag = $flagstr
	flag = 1
	
	Sort timenew, timenew
	variable inc
	
	do
		if ( timenew[inc] == timenew[inc+1] )
			flag[inc] = 2
		endif
		inc += 1
	while (inc < numpnts(timenew)-1)
	
	sort flag, timenew, flag
	delpnt = BinarySearch(flag, 1) + 1
	deletepoints delpnt, (numpnts(timenew)-delpnt), timenew

	Sort timenew, timenew
	
	killwaves flag

end


