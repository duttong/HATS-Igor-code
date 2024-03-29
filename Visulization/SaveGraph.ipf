// SaveGraph 1.1
//
//  Creates an Igor Text file that will be able to recreate the target graph (including the data)
//  in another experiment.
//
// To use, simply bring the graph you wish to save to the front and select "Save Graph"
// from the Macros menu.  You will be presented with a save dialog. 
// Later, in another experiment, you can use the "Load Igor Text..." item from the Data menu 
// to load the file. The data will be loaded and the graph will be regenerated. 
//
// "Save Graph" makes an Igor Text file that, when later loaded,  will load the data into a data folder
// of the same name as your graph.  If there are conflicts in the wave names, subfolders called
// data1 etc will be created for any subsequent waves.
//
// No data folders or waves are created by the Save Graph macros in the experiment where
// the graph was first created.  All new folders and waves are generated by loading the Igor
// Text file that recreates the graph.  The new folders and waves are in the destination experiment.
//
// NOTE:  The data folder hierarchy from the original experiment is not preserved by Save Graph.
//
// Version 1.1 differs from the first version as follows:
//	Supports Igor 3.0's Data Folders, liberal wave names
//	Supports contour and image graphs.

#pragma rtglobals=1


Menu "Macros"
	"Save Graph", DoSaveGraphToFile()
end

Function DoSaveGraphToFile()
	
	Variable numWaves
	Variable refnum
	Variable i
	Variable pos0, pos1
	Variable FolderLevel=1

	String TopFolder, FolderName
	String WinRecStr
	String fileName
	String wname=  WinName(0,1)
	
	if( strlen(wname) == 0 )
		DoAlert 0,"No graph!"
		return 0
	else
		DoWindow/F $wname
	endif
	
	TopFolder= wname
	
	
	GetWindow kwTopWin, wavelist
	Wave/T wlist=W_WaveList
	numWaves = DimSize(wlist, 0)
	
	Redimension/N=(-1,5) wlist
	
	MakeUniqueFolders(wlist, "data")
	
	Open/D refnum as wname
	filename=S_filename
	
	if (strlen(filename) == 0)
		DoAlert 0, "You cancelled the Save Graph operation"
		KillWaves/Z wlist
		return 0
	endif
	
	Open refnum as filename
	fprintf refnum, "%s", "IGOR\r"
	fprintf refnum, "%s", "X NewDataFolder/S/O "+TopFolder+"\r"
	close refnum
	
	i = 0
	do
		if (strlen(wlist[i][3]) != 0)
			Open/A refnum as filename
			if (FolderLevel > 1)
				fprintf refnum, "%s", "X SetDataFolder ::\r"
			endif
			fprintf refnum, "%s", "X NewDataFolder/S "+wlist[i][3]+"\r"
			FolderLevel=2
			close refnum
		endif
		Execute "Save/A/T "+wlist[i][1]+" as \""+FileName+"\""

		i += 1
	while (i < numWaves)

	if (FolderLevel > 1)
		Open/A refnum as filename
		fprintf refnum, "%s", "X SetDataFolder ::\r"
		close refnum
	endif

	WinRecStr = WinRecreation(wname, 2)
	i = 0
	FolderName = ""
	do
		pos0=0
		if (strlen(wlist[i][3]) != 0)
			FolderName = ":"+wlist[i][3]+":"
		endif
		do
			pos0=strsearch(WinRecStr, wlist[i][2], pos0+1)
			if (pos0 < 0)
				break
			endif
			WinRecStr[pos0,pos0+strlen(wlist[i][2])-1] = FolderName+PossiblyQuoteName(wlist[i][0])
	
		while (1)
		i += 1
	while (i<numWaves)
	
	Open/A refnum as filename
	
	pos0= strsearch(WinRecStr, "\r", 0)
	pos0= strsearch(WinRecStr, "\r", pos0+1)+1
	fprintf refnum,"X Preferences 0\r"
	do
		pos1= strsearch(WinRecStr, "\r", pos0)
		if( (pos1 == -1) %| (cmpstr(WinRecStr[pos0,pos0+2],"End") == 0 ) )
			break
		endif
		fprintf refnum,"X%s%s",WinRecStr[pos0,pos1-1],";DelayUpdate\r"
		pos0= pos1+1
	while(1)
	
	fprintf refnum, "%s", "X SetDataFolder ::\r"
	fprintf refnum,"X Preferences 1\r"
	fprintf refnum,"X KillStrings S_waveNames\r"
	close refnum
	
	KillWaves/Z wlist
	return 0
	
end

Function MakeUniqueFolders(wlist, FBaseName)
	Wave/T wlist
	String FBaseName
	
	Variable i,j, endi = DimSize(wlist, 0), startj = 0
	Variable FolderNum = 0
	
	wlist[0][3] = ""
	
	i = 1
	do
	
		j = startj
		do
			if (cmpstr(wlist[i][0], wlist[j][0]) == 0)
				FolderNum +=1
				wlist[i][3] = FBaseName+num2istr(FolderNum)
				startj = i
				break
			endif
		
			j += 1
		while (j < i)
	
	
		i += 1
	while (i < endi)
end
	
	

