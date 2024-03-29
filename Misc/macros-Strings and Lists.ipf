#pragma rtGlobals=1		// Use modern global access method.

// GSD 080327 -- removed need to use obsolete igor proceedure file <Strings as Lists>
//			added UniqueList
//			added AddListItemUnique

//#include <strings as lists>

function NumElementsInList(list, separator)
	string list, separator

	return ItemsInList(list, separator)

end	

// Adds elem to a list, lst, if the element is not already in the list.
function/s AddElementToList(lst, elem, separator)			// ***** use AddListItem now *********
	string lst, elem, separator

	variable len = strlen(lst)-1
	if ((cmpstr(lst[len, len], separator) != 0) * (len > 0))
		lst += separator
	endif

	if (FindListItem(elem, lst, separator, 0) == -1)
		lst =  lst + elem + separator
	endif

	return lst
end

// similare to AddListItem but will only add the elem if it is not in the lst
// added GSD 080326
function /s AddListItemUnique(elem, lst, [sep])
	string elem, lst, sep

	if ( ParamIsDefault(sep)	)
		sep = ";"
	endif
	
	variable i
	string item
	
	for (i=0; i<ItemsInList(lst, sep); i+=1 )
		item = StringFromList(i, lst, sep)
		if ( cmpstr(item, elem) == 0 )
			return lst
		endif
	endfor
	
	string last = lst[strlen(lst)-1,strlen(lst)]
	if ( cmpstr(last, sep) != 0 )
		return lst + sep + elem + sep
	else
		return lst + elem + sep
	endif

end

// returns a list of unique elements
// example: a list of "a;b;a;c" will be "a;b;c"
// added GSD 080327
function /s UniqueList(lst, [sep])
	string lst, sep

	if ( ParamIsDefault(sep)	)
		sep = ";"
	endif

	variable i
	string item, ulst = ""
	
	for( i=0; i<ItemsInList(lst, sep); i+=1 )
		item = StringFromList(i, lst, sep)
		if ( WhichListItem(item, ulst, sep) == -1 )
			ulst += item + sep
		endif
	endfor

	return ulst

end

******************************************
//Retun list item givin a list location
//   first element in list is number 0
//PAR, 1-22-98, adding wildcard * to the item. No wildcards in the first position, of course.
//Also, only the FIRST position will be returned if there is more than 1 item that matches a wildcard.

Function ReturnListPosition(lst, item, separator)
	string lst, item, separator
	
	// This is the wildcard part. I did not need more than just a * in the middle of the item.
	// If a * is at the beginning of the item it is considered part of the item not wildcard.
	if(strSearch(item,"*",0)>0)
		variable StartItem=StrSearch(lst,item[0,StrSearch(item,"*",0)-1],0)
			if(StartItem<0)	// This happens if there is no item like this in the list.
				return -1
			endif
		variable EndItem=StrSearch(lst,separator,StartItem)-1
			if(EndItem<0)	// This only can happen if "item" is the last item one in the list.
			EndItem=strlen(lst)
			endif
		string itemFull=lst[StartItem,EndItem]
		StartItem=ReturnListPosition(lst, itemFull, separator)
		return StartItem
	endif
	
	string tmpLst = lst
	variable len = strlen(tmpLst), inc=0, loc=0
	variable num = ItemsInList(lst, separator)
	variable itemLoc = FindListItem(item, lst, separator, 0)
	
	if ((num <= 0) + (itemLoc < 0))
		return -1
	endif

	// Remove any leading or trailing separator
	if (cmpstr(tmpLst[0,0], separator)==0)
		tmpLst = tmplst[1, len-1]
		len -= 1
	endif
	if (cmpstr(tmpLst[len-1,len-1], separator)==0)
		tmpLst = tmplst[0, len-2]
		len -= 1
	endif
if(itemLoc==0)
return 0
endif
	do
		loc = strsearch(tmplst, separator, loc)+1
		inc += 1
	while (loc != itemLoc)
	return inc
end


// will sort a list in either ascending or descending order
// For aORd variable:  0 = ascending, 1 = descending
// For tORN variable: 0 = text wave, 1 = numerical wave
// 
// Igor 4 has added a built in function called SortList -- our function is obsolete.
Function/S SortListOld(lst, aORd, tORN, separator)
	string lst, separator
	variable aORd, tORn
	
	string tmpLst = lst, com
	variable len = strlen(tmpLst), inc=0
	variable n = ItemsInList(lst, separator)

	if (cmpstr(tmpLst[0,0], separator)==0)
		tmpLst = tmplst[1, len-1]
		len -= 1
	endif
	if (cmpstr(tmpLst[len-1,len-1], separator)==0)
		tmpLst = tmplst[0, len-2]
		len -= 1
	endif
	
	if (!tORN)
		Make /t/n=(n) Junk_SortList_t
		do
			Junk_SortList_t[inc] = StringFromList(inc, tmpLst, separator)
			inc += 1
		while (inc < n)
		if (!aORd)
			sort Junk_SortList_t, Junk_SortList_t
		else
			sort /r Junk_SortList_t, Junk_SortList_t
		endif
		lst = WaveToList("Junk_SortList_t", separator)	
		killwaves Junk_SortList_t
	else
		Make /d/n=(n) Junk_SortList_d
		do
			Junk_SortList_d[inc] = str2num(StringFromList(inc, tmpLst, separator))
			inc += 1
		while (inc < n)
		if (!aORd)
			sort Junk_SortList_d, Junk_SortList_d
		else
			sort /r Junk_SortList_d, Junk_SortList_d
		endif
		lst = WaveToList("Junk_SortList_d", separator)	
		killwaves Junk_SortList_d	
	endif
		
	return lst
		
end

function/s WaveToList(wvStr, separator)
	string wvStr, separator
	
	wave /t wv=$wvStr
	variable n = numpnts(wv), wvtype = WaveType(wv), inc
	string lst="", elem=""
	
	// added GSD 080326
	if ( n == 0 )
		return ""
	endif
	
	do
		if (wvtype == 0)
			elem = (wv[inc])
		else
			elem = wv[inc]
		endif
		lst = lst + elem + separator
		inc += 1
	while (inc < n)
	
	return lst
end
	
// Creates a global list
proc SaveNewList(lstnm, lst)
	string lstnm="NewLst", lst
	prompt lstnm, "List Name"
	prompt lst, "List (use \";\" as the separator)"
	
	silent 1
	
	string com
	sprintf com, "String /g %s = \"\"", lstnm; execute com
	
	$lstnm = lst
	
	string /g S_userStr = lstnm
end

//Kills a global list
proc KillAString(lstnm)
	string lstnm
	prompt lstnm, "Kill which list or string variable", popup, StringList("*",";")
	
	killstrings $lstnm
end

//Given a list name, lstnm, ReturnList returns a string of list.
function/s ReturnList(lstnm)
	string lstnm
	
	SVAR lst = $lstnm
	if (cmpstr(lstnm, " ") == 0)
		lst = " "
	endif
	return lst	
end

// Returns a list of the differences between two lists.
Function/S ReturnListDiff(lst1, lst2, separator)
	string lst1, lst2, separator
	
	variable numLst1 = ItemsInList(lst1, separator), inc, found
	variable numLst2 = ItemsInList(lst2, separator), terminateLen
	string elem, diffLst = "", useLst1, useLst2
	
	if (numLst1 > numLst2)
		useLst1 = lst1;	useLst2 = lst2; terminateLen = numLst1
	else
		useLst1 = lst2;	useLst2 = lst1; terminateLen = numLst2
	endif
	
	do
		elem = StringFromList(inc, useLst1, separator)
		found = FindListItem(elem, useLst2, separator, 0)
		if (found == -1)
			diffLst += elem + separator
		endif
		inc += 1
	while (inc < terminateLen)
	
	return diffLst
	
end
	
// Return a list with n counting elements.
function/s ListNLong(n, separator)
	variable n
	string separator
	
	if (n <= 0) 
		abort "ListNLong requires a number greater than 0"
	endif
	
	variable inc = 1
	string lst = ""
	do
		lst = lst + num2str(inc) + separator
		inc += 1
	while (inc <= n)
	
	return lst
	
end

function MakeTextWaveFromList(lst, newWvStr, separator)
	string lst, newWvStr, separator

	string com
	variable numElems = ItemsInList(lst, separator), inc
	
	sprintf com, "make /o/t/n=%d %s", numElems, newWvStr; execute com
	wave /t newWv = $newWvStr
	do
		newWv[inc] = StringFromList(inc, lst, separator)
		inc += 1
	while (inc < numElems)
end

// Function will pad the front of a number with "padStrChar".  Returns a string.
//  Example: print PadStr( 5, 3, "0")  returns 005
function/s PadStr (var, len, padStrChar)
	variable var, len
	string padStrChar
	
	string varStr = num2str(var)
	variable varStrlen = strlen(varStr)
	do
		if (varStrlen < len)
			varStr = padStrChar + varStr
			varStrLen += 1
		endif
	while (varStrLen < len)
		
	return varStr
	
end