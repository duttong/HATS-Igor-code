#pragma rtGlobals=1		// Use modern global access method.


// Notes on compiling Noahchrom.
// Try to compile.  It will fail.  Then run initDB().  This will fail part-way through.
// Then run ConvertTo64BitFlags().  This will also fail once.  Recompile and run it again.
// Follow subsequent prompts.

// General macros
#include "macros-Utilities"

// Base NoahChrom macros
#include "macros-jmg NC Initialization"		// Intialization for NoahChrom
#include "macros-jmg Averaging"				// Various spaceing and median/avg functions
#include "macros-jmg NC ActiveSet"			// Active set declarations
#include "macros-jmg NC Concentration"		// Concentration calc methods
#include "macros-jmg NC Concentration pnl"	//              panel
#include "macros-jmg NC Integration"			// Peak integration
#include "macros-NC IntegParams pnls"		//              panel
#include "macros-jmg NC Loading"				// Chromatogram loading
#include "macros-jmg NC PeakDetect"			// Peak detection methods
#include "macros-NC PeakDetect pnls"			//              panel
#include "macros-jmg NC Structure"			// Database structure
#include "macros-NC Structure pnls"			//              panel
#include "macros-jmg NC utilities"				// NoahChrom utilities
#include "macros-jmg NC Visualization"		// Plotting routines
#include "macros-NC ActivePeaks"				// Active peak and detector macros
#include "macros-NC ActiveSet pnls"			//               panel
#include "macros-NC Flag64"					// 64 bit flags
#include "macros-NC Flag64 pnls"				//		      panel
#include "macros-NC ManInteg"					// Chromatogram display routines
#include "macros-NC ManInteg pnls"			//               panel
#include "macros-NC Smoothing"				// Smoothing and filtering routines

// ACATS specific macros
// critical
//#include "macros-TJB NC Utilities"				// Has routines to handle 6 min injections
//#include "macros-cmv NC post proc"			// Post processing -- Smoothed drift correction
	
// special occasions
//#include "macros-gsd NC ECD Calibration"		// Apply ECD calibrations to ASHOE data
//#include "macros-gsd NC Aircraft"				// Writting exchange files
//#include "macros-gsd submit"					// Prepareing ASHOE flights for submition
//#include "macros-jmg NC ASHOE Graphs"		// Various pre-made plots
//#include "macros-jmg NC cloud1"				// Used to read Cloud1 submitted data
//#include "macros-jmg NC Cly"					// Total Cly Calculation (used during ASHOE)
//#include "macros-jmg NC Delay"				// Calculates ACATS injection time delay
//#include "macros-NC sub inj"					// For "wrapped" chromatograms
//#include "macros-TJB Load-N-Go"				// Reads and displays real time integration results

// STEALTH specific macros
#include "macros-NC load STEALTH"


menu  "macros"
	submenu "STEALTH Step-By-Step"
		"Load STEALTH File"
		"Load Many STEALTH Files"
		"Smooth Chroms"
		"-"
		"Active Rows"	
		"Active Peaks"
		"Manual Integration"
		"Define Peak Detect Params "
		"-"
		"Peak Diagnostics Layout"
	end
		
	submenu "Database Structure"
		"Init DB"
		"-"
		"Add Detector"
		"Remove Detector"
		"-"
		"Define Peak List"
		"Copy Peak List"
		"-"
		"Create New DB Columns"
		"Kill DB Columns"
		"-"
		"Insert DB Rows"
		"Delete DB Rows"
	end
	"-"
	"Active Rows /1"	
	"Active Peaks  /2"
	"-"
	submenu "Loading Operations"
		"Load Many ITX Files"
		"Load Chroms From ITX File"
		"Date Jims Sister"
		"-"
		"Load Real-Time Results"
		"Load and Go"
		"Nuclear Load-N-Go"
		"Real-Time Load And Quick Look"
		"-"
		"Load AS Chroms"
		"Load AS Chroms Many Paths"
		"Unload AS Chroms"
		"-"
		"Set Injection Offset"
		"-"
		"Load CO2"
		"Load O3"
		"Load NOy"
		"-"
		submenu "Loading Waves From BWAV Files"
			"Load New Chroms"
			"Insert New Loaded Chroms"
			"-"
			"Make List Of Files"
			"Load All Files In List"
		end
		"-"
		"AS Chrom Note 2 DB"
		"-"
		"Respace XY Avg"
	end
	"-"
	submenu  "Integration"
		"Manual Integration /4"
		"Show Integration Results /5"
		"Def Peak Fit Specs /6"
		"Def Curve Fit Exclude Regions /7"
		"Define Peak Detect Params /8"
		"-"
		"Set Auto-Scale Margins /9"
	end
	submenu "Concentration"
		"Compute Concentration"
		"-"
		"ECD Calibration Panel"
	end
	submenu "Analysis"
		"Peak Diagnostics Layout"
		"Air-Cal Plot"
		"Area-Hght Ratio Plot"
		"Active Set Trend Anal"
		"-"
		"Display Active Set"
		"Active Set 2  X-Y waves /3"
		"-"
		"Init Cly Budget"
		"AS Cly Budget"
		"-"
		"Compute Delay"
		"-"
		"Plot AS chroms"
		"List AS Chroms"
	end
	"-"
	submenu "DB Row Locking Operations"
		"Write Protect Active Set"
		"Unlock Active Set"
	end	
	"-"
	submenu "Smoothing And Filtering"
		"Bunch Chromatograms"
		"Do Loess"
		"-"
		"Smooth Wave Spikes"
		"Smooth CSR point"
		"Interpolate Between Csrs"
		"Delete Points Between Cursors"
		"-"
		"subtract Zero Airs From AS"
		"add Zero Airs From AS"
	end		
	submenu "NOAHchrom Utilities"
		"Save Recreation Macro"
		"-"
		"Print All Displayed Graphs"
		"-"
		"Remove Displayed Graphs"
		"Remove Displayed Tables"
		"Remove Displayed Objects"
		"-"
		"Replace"
		"-"
		"Convert X-Y To Scaled Wave"
		"Change Data Spacing"
		"Change Data Spacing Median"
		"-"
		"PrintFlagList"
	end
end
