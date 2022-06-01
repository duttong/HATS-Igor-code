#pragma rtGlobals=1		// Use modern global access method.


function/S ReturnMolUnits(mol)
	string mol
	
	if ( cmpstr(mol, "N2O")== 0 )
		return "(ppb)"
	elseif ( cmpstr(mol, "CO")== 0 )
		return "(ppb)"
	elseif ( cmpstr(mol, "CH4")== 0 )
		return "(ppb)"
	elseif ( cmpstr(mol, "O3")== 0 )
		return "(ppb)"
	else
		return "(ppt)"
	endif
end		

// returns a string to display subscripts in a legend
function/s ReturnMolSubscriptTxt(mol)
	string mol
	
	if ( cmpstr(mol, "N2O")== 0 )
		return "\\[0N\\B2\\M\\]0O"
	elseif ( cmpstr(mol, "SF6")== 0 )
		return "\\[0SF\\B6\\M\\]0"
	elseif ( cmpstr(mol, "MC")==0)
		return "\\[0CH\\B3\\MCCl\\B3\\M\\]0"
	elseif ( cmpstr(mol, "CCl4")== 0 )
		return "\\[0CCl\\B4\\M\\]0"
	elseif ( cmpstr(mol, "C2Cl4")== 0 )
		return "\\[0C\\B2\\MCl\\B4\\M\\]0"
	elseif ( cmpstr(mol, "CH2Cl2")== 0 )
		return "\\[0CH\\B2\\MCl\\B2\\M\\]0"
	elseif ( cmpstr(mol, "CHCl3")== 0 )
		return "\\[0CHCl\\B3\\M\\]0"
	elseif ( cmpstr(mol, "CH3Cl")== 0 )
		return "\\[0CH\\B3\\MCl\\]0"
	elseif ( cmpstr(mol, "CH3Br")== 0 )
		return "\\[0CH\\B3\\MBr\\]0"
	elseif ( cmpstr(mol, "CH3Br")== 0 )
		return "\\[0CH\\B3\\MBr\\]0"
	elseif ( cmpstr(mol, "CH4")== 0 )
		return "\\[0CH\\B4\\M\\]0"
	elseif ( cmpstr(mol, "H2")== 0 )
		return "\\[0H\\B2\\M\\]0"
	elseif ( cmpstr(mol, "O3")== 0 )
		return "\\[0O\\B3\\M\\]0"
	elseif ( cmpstr(mol, "C2H6")== 0 )
		return "\\[0C\\B2\\MH\\B6\\]0"
	elseif ( cmpstr(mol, "C3H8")== 0 )
		return "\\[0C\\B3\\MH\\B8\\]0"
	elseif ( cmpstr(mol, "CF4")== 0 )
		return "\\[0CF\\B4\\M\\]0"
	elseif ( cmpstr(mol, "NF3")== 0 )
		return "\\[0NF\\B3\\M\\]0"
	elseif ( cmpstr(mol, "SO2F2")== 0 )
		return "\\[0SO\\B2\\MF\\B2\\M\\]0"
	else
		return mol
	endif

end	

// returns a string for axis labels
Function/S FullMolName(mol, [units])
	string mol
	variable units
	
	if ( ParamIsDefault(units) )
		units = 1
	endif
	
	string txt

	if (GrepString(mol, "N2O|n2o"))
		txt = ReturnMolSubscriptTxt(mol)
	elseif (GrepString(mol, "SF6|sf6"))
		txt = ReturnMolSubscriptTxt(mol)

	elseif (GrepString(mol, "F113|f113"))
		txt = "CFC-113"
	elseif (GrepString(mol, "F11|f11"))
		txt = "CFC-11"
	elseif (GrepString(mol, "F12|f12"))
		txt = "CFC-12"

	elseif (GrepString(mol, "HCFC22|hcfc22"))
		txt = "HCFC-22"
	elseif (GrepString(mol, "141b"))
		txt = "HCFC-141b"
	elseif (GrepString(mol, "142b"))
		txt = "HCFC-142b"
	elseif (GrepString(mol, "134"))
		txt = "HFC-134a"
	elseif (GrepString(mol, "152"))
		txt = "HFC-152a"
	elseif (GrepString(mol, "125"))
		txt = "HFC-125"
	elseif (GrepString(mol, "143a"))
		txt = "HFC-143a"
	elseif (GrepString(mol, "HFC32|hfc32"))
		txt = "HFC-32"
	elseif (GrepString(mol, "227"))
		txt = "HFC-227ea"
	elseif (GrepString(mol, "365"))
		txt = "HFC-365mfc"
	elseif (GrepString(mol, "236"))
		txt = "HFC-236fa"

	elseif (GrepString(mol, "MC|mc"))
		txt = ReturnMolSubscriptTxt(mol)
	elseif (GrepString(mol, "CCl4|ccl4"))
		txt = ReturnMolSubscriptTxt(mol)
	elseif (GrepString(mol, "CHCl3|chcl3"))
		txt = ReturnMolSubscriptTxt(mol)
	elseif (GrepString(mol, "C2Cl4|c2cl4"))
		txt = ReturnMolSubscriptTxt(mol)
	elseif (GrepString(mol, "CH2Cl2|ch2cl2"))
		txt = ReturnMolSubscriptTxt(mol)
		
	elseif (GrepString(mol, "C2H6|c2h6"))
		txt = ReturnMolSubscriptTxt(mol)
	elseif (GrepString(mol, "C3H8|c3h8"))
		txt = ReturnMolSubscriptTxt(mol)

	elseif (GrepString(mol, "CF4|cf4"))
		txt = ReturnMolSubscriptTxt(mol)
	elseif (GrepString(mol, "NF3|nf3"))
		txt = ReturnMolSubscriptTxt(mol)
	elseif (GrepString(mol, "SO2F2|so2f2"))
		txt = ReturnMolSubscriptTxt(mol)

	elseif (GrepString(mol, "CH3Cl|ch3cl"))
		txt = ReturnMolSubscriptTxt(mol)
	elseif (GrepString(mol, "CH3Br|ch3br"))
		txt = ReturnMolSubscriptTxt(mol)

	elseif (GrepString(mol, "1211"))
		txt = "halon-1211"
	elseif (GrepString(mol, "1301"))
		txt = "halon-1301"
	elseif (GrepString(mol, "2402"))
		txt = "halon-2402"

	elseif (GrepString(mol, "PFC116|pfc116"))
		txt = "PFC-116"
		
	elseif (GrepString(mol, "COS|cos|OCS|ocs"))
		txt = "OCS"
		
	elseif (GrepString(mol, "CO|co"))
		txt = "CO"
	elseif (GrepString(mol, "H2|h2"))
		txt = ReturnMolSubscriptTxt(mol)
	elseif (GrepString(mol, "CH4|ch4"))
		txt = ReturnMolSubscriptTxt(mol)
	else
		txt = mol		
	endif	

	if (units)
		return txt + " " + ReturnMolUnits(mol)
	else
		return txt
	endif

end

Function/S FullStationName(sta)
	string sta
	
	if (GrepString(sta, "BRW|brw"))
		return "Barrow, Alaska"
	elseif (GrepString(sta, "SUM|sum"))
		return "Summit, Greenland"
	elseif (GrepString(sta, "MLO|mlo"))
		return "Mauna Loa, Hawaii"
	elseif (GrepString(sta, "NWR|nwr"))
		return "Niwot Ridge, Colorado"
	elseif (GrepString(sta, "SMO|smo"))
		return "American Samoa"
	elseif (GrepString(sta, "SPO|spo"))
		return "South Pole, Antarctica"
	else
		return ""
	endif

end