#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @brief Create MIES data folder architecture and create some panels
Function IM_InitiateMIES()
	createDFWithAllParents("root:MIES:Amplifiers:Settings")

	// stores lists of data that the background timer uses
	GetActiveITCDevicesTimerFolder()

	// the arduino sequencer does not handle datafolder creation reliable
	createDFWithAllParents("root:ImageHardware:Arduino")

	// stores lists of data related to ITC devices actively running a test pulse
	createDFWithAllParents("root:MIES:ITCDevices:ActiveITCDevices:TestPulse")
	createDFWithAllParents("root:MIES:LabNoteBook")
	createDFWithAllParents("root:MIES:Camera")
	createDFWithAllParents("root:MIES:Manipulators")

	string /G root:MIES:ITCDevices:ITCPanelTitleList

	WBP_CreateWaveBuilderPanel()
	execute "DA_Ephys()"
	execute "DataBrowser()"
End

/// @brief Returns 1 if the user cancelled, zero if SaveExperiment was called
///
/// It is currently not possible to check if SaveExperiment was successfull
/// (E-Mail from Howard Rodstein WaveMetrics, 30 Jan 2015)
Function SaveExperimentWithDialog(path, filename)
	string path, filename

	variable refNum

	Open/D/M="Save experiment"/F="All Files:.*;"/P=$path refNum as filename

	if(isEmpty(S_fileName))
		return 1
	endif

	SaveExperiment as S_fileName
	return 0
End

/// @brief Save the current experiment under a new name and clear all data
/// @param fileNameSuffix   [optional: default current timestamp]     suffix for the new experiment name
/// @param zeroSweeps       [optional: default true]                  should the sweep number be resetted to zero
/// @param keepOtherWaves   [optional: default false]                 only delete the sweep and sweep config waves
/// @param untitledSaveName [optional: default `UNTITLED_EXPERIMENT`] initial suggestion for the filename in the save dialog
Function IM_SaveAndClearExperiment([fileNameSuffix, zeroSweeps, keepOtherWaves, untitledSaveName])
	string fileNameSuffix
	variable zeroSweeps, keepOtherWaves
	string untitledSaveName

	variable numDevices, i, ret, pos
	string path, devicesWithData, activeDevices, device, expLoc, list, refNum
	string expName, substr

	if(ParamIsDefault(fileNameSuffix))
		fileNameSuffix = "_" + GetTimeStamp()
	elseif(!isEmpty(fileNameSuffix))
		fileNameSuffix = "_" + fileNameSuffix
	endif

	if(ParamIsDefault(zeroSweeps))
		zeroSweeps = 1
	else
		zeroSweeps = !!zeroSweeps
	endif

	if(ParamIsDefault(keepOtherWaves))
		keepOtherWaves = 0
	else
		keepOtherWaves = !!keepOtherWaves
	endif

	if(ParamIsDefault(untitledSaveName))
		untitledSaveName = UNTITLED_EXPERIMENT
	endif

	ASSERT(strlen(untitledSaveName) > 0, "Can not proceed with an empty untitledSaveName")

	// We want never to loose data so we do the following:
	// Case 1: Unitled experiment
	// - Save with dialog without fileNameSuffix suffix
	// - Save with dialog with fileNameSuffix suffix
	// - Clear data
	// - Save without dialog
	//
	// Case 2: Experiment with name
	// - Save without dialog
	// - Save with dialog with fileNameSuffix suffix
	// - Clear data
	// - Save without dialog
	//
	// User aborts in the save dialogs always results in a complete abort

	expName = GetExperimentName()

	if(!cmpstr(expName, UNTITLED_EXPERIMENT))
		ret = SaveExperimentWithDialog("", GetTimeStamp() + PACKED_FILE_EXPERIMENT_SUFFIX)

		if(ret)
			return NaN
		endif

		// the user might have changed the experimet name in the dialog
		expName = GetExperimentName()
	else
		SaveExperiment
	endif

	// Remove a possibly existing sibling suffix
	expName = RemoveEnding(expName, "_" + SIBLING_FILENAME_SUFFIX)

	// and a numerical suffix, 0 to 999, from earlier saving
	pos = strsearch(expName, "_", inf, 1)
	if(pos > 0)
		substr = expName[pos + 1, inf]
		if(strlen(substr) <= 3 && IsFinite(str2num(substr)))
			expName = RemoveEnding(expName, substr)
		endif
	endif

	expName += fileNameSuffix

	// saved experiments are stored in the symbolic path "home"
	expLoc  = "home"
	expName = UniqueFile(expLoc, expName, PACKED_FILE_EXPERIMENT_SUFFIX)

	ret = SaveExperimentWithDialog(expLoc, expName)

	if(ret)
		return NaN
	endif

	FUNCREF CALL_FUNCTION_LIST_PROTOTYPE killFunc = KillOrMoveToTrash

	// remove sweep data from all devices with data
	devicesWithData = GetAllDevicesWithData()
	numDevices = ItemsInList(devicesWithData)
	for(i = 0; i < numDevices; i += 1)
		device = StringFromList(i, devicesWithData)

		path = GetDeviceDataPathAsString(device)
		killFunc(path)

		if(windowExists(device) && zeroSweeps)
			SetSetVariable(device, "SetVar_Sweep", 0)
		endif
	endfor

	if(!keepOtherWaves)
		// remove labnotebook
		path = GetLabNotebookFolderAsString()
		killFunc(path)

		// remove other waves from active devices
		activeDevices = GetAllActiveDevices()
		numDevices = ItemsInList(activeDevices)
		for(i = 0; i < numDevices; i += 1)
			device = StringFromList(i, activeDevices)

			DFREF dfr = GetDevicePath(device)
			list = GetListOfWaves(dfr, "ChanAmpAssign_Sweep_*", fullPath=1)
			CallFunctionForEachListItem(killFunc, list)

			DFREF dfr = GetDeviceTestPulse(device)
			list = GetListOfWaves(dfr, "TPStorage_*", fullPath=1)
			CallFunctionForEachListItem(killFunc, list)
		endfor
	endif

	SaveExperiment
End

Function IM_MakeGlobalsAndWaves(panelTitle)// makes the necessary parameters for the locked device to function.
	string panelTitle

	HSU_CreateDataFolderForLockdDev(panelTitle)
	HSU_UpdateChanAmpAssignStorWv(panelTitle)
	DAP_FindConnectedAmps(panelTitle)

	dfref data = GetDevicePath(panelTitle)
	make /o /n= (1,8) data:ITCDataWave
	make /o /n= (2,4) data:ITCChanConfigWave
	make /o /n= (2,4) data:ITCFIFOAvailAllConfigWave
	make /o /n= (2,4) data:ITCFIFOPositionAllConfigWave
	make /o /i /n = 4 data:ResultsWave

	dfref dfr = GetDeviceTestPulse(panelTitle)
	make /o /n= (1,8) dfr:TestPulseITC
	make /o /n= (1,8) dfr:InstResistance
	make /o /n= (1,8) dfr:Resistance
	make /o /n= (1,8) dfr:SSResistance
End

/// @brief Remove all strings/variables/waves which should not
/// survive experiment reload/quit/saving
///
/// Mainly useful for temporaries which you want to recreate on initialization
static Function KillTemporaries()

	string trashFolders, path, allFolders
	variable numFolders, i

	DFREF dfr = GetMiesPath()

	KillStrings/Z dfr:version
	KillVariables/Z dfr:skip_free_memory_warning

	// try to delete all trash folders
	allFolders = StringByKey("FOLDERS", DataFolderDir(1, dfr))
	trashFolders = ListMatch(allFolders, TRASH_FOLDER_PREFIX + "*", ",")

	numFolders = ItemsInList(trashFolders, ",")
	for(i = 0; i < numFolders; i += 1)
		path = GetDataFolder(1, dfr) + StringFromList(i, trashFolders, ",")
		KillDataFolder/Z $path
	endfor

	RemoveEmptyDataFolder(dfr)
End

Function BeforeExperimentSaveHook(rN, fileName, path, type, creator, kind)
	Variable rN, kind
	String fileName, path, type, creator

	KillTemporaries()
End

static Function IgorBeforeQuitHook(igorApplicationNameStr)
	string igorApplicationNameStr

	DAP_UnlockAllDevices()
	KillTemporaries()
	return 0
End

static Function IgorBeforeNewHook(igorApplicationNameStr)
	string igorApplicationNameStr

	DAP_UnlockAllDevices()
	KillTemporaries()
	return 0
End
