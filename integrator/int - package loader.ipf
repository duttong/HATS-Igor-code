#pragma rtGlobals=1		// Use modern global access method.

// General macros
#include "macros-Utilities"
#include "macros-Strings and Lists"
#include <strings as lists>
#include "macros-Geoff"

#include "int - chrom loader"
#include "int - integration panel"
#include "int - chrom panel"
#include "int - AS functions"
#include "int - detection"
#include "int - integration"
#include "int - results"
#include "int - detrend"

Menu "Macros"
	Submenu "Stationery Configuration"
		"Integrator Configuration", INTconfigPanel()
		"Prepare Chroms Configuration", PrepConfigTable()
		"-"
		"Convert Experiment to Stationery", ConvertToStationary()
	end
	"-"
	"<B Integration Panel /F1", INTpanel()
	"<B Chroms Panel /F2", MANpanel()
	"<B Detrend Panel /F3", CreateNormPanel()
	"-"
	Submenu "Chromatogram Manipulation"
		"Load Chroms", ChromLoader()
		"Prepare Chroms"
		"-"
		"Smooth Chroms"
		"Shift Chroms", ShiftTheChroms()
		"Concatenate Chroms", concatChroms()
	//	"Split Chroms"
	End
	Submenu "Integration Techniques"
		"Find Retention Time", FindRetOnePeak_Proc()
		"-"
		"Edges - Fixed Window", Edges_FixedWindow_Proc()
		"Edges - Tangent Skim", Edges_TangentSkim_Proc()
		"Edges - Tangent Fixed Start", Edges_FixedStart_Proc
		"Edges - Tangent Fixed Stop", Edges_FixedStop_Proc
		"-"
		"Display Alogrithum Results", DisplayChromTmp()
	End
	Submenu "Integration Results"
		"Reset All Result Waves", ResetResultWaves()
		"Reset One Result Wave", ResetOneResWaves()
		"Set Missing Retention Times", SetMissingRets()
		"-"
		"Manually set precision", INTerrorPanel()
	End
	"-"
	"Remove All Displayed Graphs", removeDisplayedGraphs()
	"-"
	"Convert Old NOAHchrom Experiment", convertNoahchrom()
end


function ConvertToStationary()

	DoAlert 1, "Pressing the \"Yes\" button will delete all loaded chromatograms and integration results.  Proceed?"
	
	if ( V_flag == 2)
		abort "Aborted"
	endif
	
	SVAR S_date = root:S_date

	wave DBnormFirst = root:DB:DB_normFirst
	wave DBnormLast = root:DB:DB_normLast
	wave DBmanERR = root:DB:DB_manERR

	wave /t config = root:config
	variable inc
	string wv
	
	DoWindow /K ChromPanel
	removeDisplayedGraphs()
	removeDisplayedTables()
	
	// set norm points to default
	DBnormFirst = 0
	DBnormLast = 1
	
	// set man error to default (0 = auto)
	DBmanERR = 0
	
	// Empty data folders except the root:DB
	KillDataFolder root:chroms
	NewDataFolder root:chroms
	KillDataFolder root:AS
	NewDataFolder root:AS
	KillDataFolder root:temp
	NewDataFolder root:temp
	KillDataFolder root:norm
	NewDataFolder root:norm

	do
		wv = GetIndexedObjName("root:", 1, inc)
		if ( strlen(wv) == 0 )
			break
		endif
		if ( (cmpstr(wv,"config") == 0) || (cmpstr(wv,"configNotes") == 0) || (cmpstr(wv,"prepConfig") == 0) || (cmpstr(wv,"prepNotes") == 0) || (cmpstr(wv,"SmoothConf") == 0) || (cmpstr(wv,"SmoothNotes") == 0) )
			// save these waves
		else
			killwaves $wv
			inc -= 1
		endif
		inc += 1
	while(1)
	
	// set experiment data to null
	config[4] = "000000"
	S_date = "000000"
	
	// delete any paths created
	KillPath/A/Z
	
	DoWindow /K IntegrationPanel
	INTpanel()
	
	DoAlert 1, "Do you want to save this experiment as an Igor stationary?"
	if ( V_flag == 1)
		DoIgorMenu "File", "Save Experiment As"
	endif
	
end

Function ConvertNoahchrom()

	NVAR calssv = root:norm:V_calssv
	SVAR inst = root:S_instrument

	string datatype
	string helptext = "Load integration results from an old Noahchrom experiment."
	Prompt datatype, "Is the old NOAHchrom experiment...", popup, "Packed;Unpacked"
	DoPrompt /HELP=helptext "Loading NOAHchrom results.", datatype
	
	if (V_flag == 1)
		abort
	endif
	
	String objName, mol
	Variable index = 0, i, mollen
	
	wave /t DBmols = root:DB:DB_mols
	wave DBactive = root:DB:DB_activePeak
	wave DBexpStart = root:DB:DB_expStart
	wave DBexpStop = root:DB:DB_expStop
	wave DBnormFirst = root:DB:DB_normFirst
	wave DBnormLast = root:DB:DB_normLast
	string dest
	variable DBrow, pt

	KillDataFolder root:chroms
	NewDataFolder root:chroms
	KillDataFolder root:temp
	NewDataFolder root:temp

	setDataFolder root:temp

	if ( cmpstr(datatype, "Packed") == 0)
		LoadData /O
	else
		LoadData /O/D
	endif
	
	// move chroms first	
	do
		objName = GetIndexedObjName(":", 1, index)
		if (strlen(objName) == 0)
			break
		endif
		
		// move chroms
		if ( (cmpstr(objName[0,2], "chr") == 0) && (cmpstr(objName[4,5], "_")) )
			dest = "root:chroms:" + objName
			duplicate /o $objName, $dest
		endif

		index += 1
	while(1)
	
	CreateChromAS()
	variable oldDBpadding = returnMINchromNum(1)
	print "deleting ", oldDBpadding, " points from results waves"
	setDataFolder root:temp
	
	// move result waves
	index = 0		
	do
		objName = GetIndexedObjName(":", 1, index)
		if (strlen(objName) == 0)
			break
		endif

		// look for result waves
		for(i=0; i<numpnts(DBmols); i+= 1)
			mol = DBmols[i]
			mollen = strlen(mol)
			if (cmpstr(objName[0,mollen-1], mol) == 0 )
				if ( cmpstr(objName, mol+"_ret") == 0 )
					dest = "root:" + mol + "_ret"
					duplicate /o $objName, $dest
					deletepoints 0, oldDBpadding, $dest
				elseif ( cmpstr(objName, mol+"_strt") == 0 )
					dest = "root:"+mol+"_start"
					duplicate /o $objName, $dest
					wave destwv = $dest
					deletepoints 0, oldDBpadding, destwv
					Extract /O destwv, expTempWv, destwv > 0
					DBrow = returnMolDBrow(mol)
					DBexpStart[DBrow] = Median(expTempWv, 5, numpnts(expTempWv)-5)
				elseif ( cmpstr(objName, mol+"_end") == 0 )
					dest = "root:"+mol+"_stop"
					duplicate /o $objName, $dest
					wave destwv = $dest
					deletepoints 0, oldDBpadding, destwv
					Extract /O destwv, expTempWv, destwv > 0
					DBrow = returnMolDBrow(mol)
					DBexpStop[DBrow] = Median(expTempWv, 5, numpnts(expTempWv)-5)
				elseif ( cmpstr(objName, mol+"_area") == 0 )
					dest = "root:"+mol+"_area"
					duplicate /o $objName, $dest
					deletepoints 0, oldDBpadding, $dest
				elseif ( cmpstr(objName, mol+"_hght") == 0 )
					dest = "root:"+mol+"_height"
					duplicate /o $objName, $dest
					deletepoints 0, oldDBpadding, $dest
				elseif ( cmpstr(objName, mol+"_respHght") == 0 )
					dest = "root:"+mol+"_resp"
					duplicate /o $objName, $dest
					deletepoints 0, oldDBpadding, $dest
				elseif ( cmpstr(objName, mol+"goodCalXHght") == 0 )
					wave calX = $mol+"goodCalXHght"
					DBrow = returnMolDBrow(mol)
					DBnormFirst[DBrow] = calX[0]
					DBnormLast[DBrow] = calX[numpnts(calX)-1]
				endif
			endif		
		endfor
		
		index += 1
	while(1)
	
	Killwaves expTempWv
	
	setDataFolder root:
	KillDataFolder root:temp
	NewDataFolder root:temp
	
	CreateDBwaves()			// also calls CreateChromAS()
	
	// ACATS code
	if (cmpstr(inst, "ACATS") == 0 )
		// hard code ACATS AS waves to first channel.  This solves concantination problem.
		wave AS1 = root:AS:CH1_All
		variable ch
		for(ch=2; ch <= 4; ch += 1)
			wave ASother = $("root:AS:CH" + num2str(ch) + "_All")
			duplicate /o AS1, ASother
		endfor
		SetASchroms(1)
	endif
	
	print "Loading Wave Notes"
	LoadWaveNotes()
	
	print "Trimming DB waves"
	TrimDBwaves()
	
	DetermineFlightDate()		// sets S_date
	
	print "Fixing Tsecs"
	FixupTsecs()
	MakeTsecs1904()

	// make flag waves
	for (i=0; i<numpnts(DBmols); i+= 1)
		mol = DBmols[i]
		dest = mol + "_flagMan"
		make/o/n=(numpnts($mol+"_ret")) $dest = 0
		dest = mol + "_flagBad"
		make/o/n=(numpnts($mol+"_ret")) $dest = 0
		if (WaveExists(	$mol+"_resp") == 1)
			wave resp = $mol+"_resp"
			wave flagBad = $dest
			flagBad = selectNumber(numtype(resp)==2, 0, 1)
		endif
	endfor
	

	// ACATS code
	if (cmpstr(inst, "ACATS") == 0 )
		// set ret = -1 to badflag
		for (i=0; i<numpnts(DBmols); i+= 1)
			mol = DBmols[i]
			if (WaveExists(	$mol+"_resp") == 1)
				wave ret = $"root:" + mol + "_ret"
				wave bad = $"root:" + mol + "_flagBad"
				wave start = $"root:" + mol + "_start"
				wave stop = $"root:" + mol + "_stop"
				wave are = $"root:" + mol + "_area"
				wave hgt = $"root:" + mol + "_height"
				wave resp = $"root:" + mol + "_resp"
				bad = SelectNumber(ret == -1, bad, 1)
				start = SelectNumber(start == -1, start, nan)
				stop = SelectNumber(stop == -1, stop, nan)
				are = SelectNumber(are == -1, are, nan)
				hgt = SelectNumber(hgt == -1, hgt, nan)
				resp = SelectNumber(resp == -1, resp, nan)
				ret = SelectNumber(ret == -1, ret, nan)
			endif
		endfor
	endif

	setDataFolder root:
	
end

// function used to delete short chroms that are left over from concatination.
function RemoveShortChroms( ch )
	variable ch
	
	variable tooFew = (8*70)		// 8Hz * 70 secs, chroms with fewer than this many point will be eliminated.

	variable inc = 0, chromNum
	string objName
	do
		objName = GetIndexedObjName("root:chroms:", 1, inc)
		if (strlen(objName) == 0)
			break
		endif
		
		if ( (cmpstr(objName[0,2], "chr") == 0) && (cmpstr(objName[4,5], "_")) && (str2num(objName[3,3]) == ch) )
			wave chrom = $"root:chroms:" + objName
			chromNum = str2num(objName[6,10])
			if (numpnts(chrom) < tooFew)
				Killwaves /Z chrom
				Print "Deleted chromatogram: " + objName
			endif
		endif
		inc += 1
	while(1)

end