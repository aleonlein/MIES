#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SWS
#endif

/// @file MIES_SweepSaving.ipf
/// @brief __SWS__ Scale and store acquired data

/// @brief Save the acquired sweep permanently
///
/// @param panelTitle device
/// @param forcedStop [optional, defaults to false] if DAQ was aborted (true) or stopped by itself (false)
Function SWS_SaveAndScaleITCData(panelTitle, [forcedStop])
	string panelTitle
	variable forcedStop

	variable sweepNo

	forcedStop = ParamIsDefault(forcedStop) ? 0 : !!forcedStop

	sweepNo = GetSetVariable(panelTitle, "SetVar_Sweep")

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	SCOPE_UpdateOscilloscopeData(panelTitle, DATA_ACQUISITION_MODE, fifoPos=stopCollectionPoint)

	DFREf dfr = GetDeviceDataPath(panelTitle)

	WAVE dataWave = SWS_StoreITCDataWaveScaled(panelTitle, dfr, sweepNo)
	note dataWave, Time()
	note dataWave, GetExperimentName()  + " - Igor Pro " + num2str(igorVersion())
	AppendMiesVersionToWaveNote(dataWave)

	Duplicate/O GetITCChanConfigWave(panelTitle), dfr:$("Config_Sweep_" + num2str(sweepNo))/Wave=configWave

	SetVariable SetVar_Sweep, Value = _NUM:(sweepNo + 1), limits={0, sweepNo + 1, 1}, win = $panelTitle

	// Add labnotebook entries for the acquired sweep
	ED_createWaveNoteTags(panelTitle, sweepNo)

	if(GetCheckBoxState(panelTitle, "Check_Settings_NwbExport"))
		NWB_AppendSweep(panelTitle, dataWave, configWave, sweepNo)
	endif

	AM_analysisMasterPostSweep(panelTitle, sweepNo)

	if(!forcedStop)
		AFM_CallAnalysisFunctions(panelTitle, POST_SWEEP_EVENT)
	endif

	SWS_AfterSweepDataSaveHook(panelTitle)
End

/// @brief General hook function which gets always executed after sweep data saving
static Function SWS_AfterSweepDataSaveHook(panelTitle)
	string panelTitle

	string panelList, dataPath, panel, panelType
	variable numPanels, i

	panelList = WinList("DB_*", ";", "WIN:64")

	numPanels = ItemsInList(panelList)
	for(i = 0; i < numPanels; i += 1)
		panel = StringFromList(i, panelList)

		panelType = GetUserData(panel, "", MIES_PANEL_TYPE_USER_DATA)
		if(!cmpstr(panelType, MIES_DATABROWSER_PANEL))
			dataPath   = GetUserData(panel, "", "DataFolderPath")
			if(!cmpstr(dataPath, GetDevicePathAsString(panelTitle)))
				DB_UpdateToLastSweep(panel)
			endif
		endif
	endfor
End

/// @brief Create a sweep wave holding the scaled contents of ITCDataWave
///
/// Only the x-range up to `stopCollectionPoint` is stored.
static Function/WAVE SWS_StoreITCDataWaveScaled(panelTitle, dfr, sweepNo)
	string panelTitle
	DFREF dfr
	variable sweepNo

	variable numEntries, numDACs, numADCs, numTTLs
	variable numRows, numCols
	string sweepWaveName

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)

	ASSERT(DimSize(ITCChanConfigWave, ROWS) == DimSize(ITCDataWave, COLS), "ITC Data and config wave differ in the number of channels, this must NOT happen!")

	WAVE DA_EphysGuiState = GetDA_EphysGuiStateNum(panelTitle)
	WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
	WAVE DACs = GetDACListFromConfig(ITCChanConfigWave)
	WAVE TTLs = GetTTLListFromConfig(ITCChanConfigWave)

	numRows = stopCollectionPoint
	numCols = DimSize(ITCDataWave, COLS)
	ASSERT(numCols > 0, "Expected at least one channel")

	numADCs = DimSize(ADCs, ROWS)
	numDACs = DimSize(DACs, ROWS)
	numTTLs = DimSize(TTLs, ROWS)

	Make/FREE/N=(numCols) gain

	// DA: w' = w / (s / g)
	if(numDACs > 0)
		gain[0, numDACs - 1] = HARDWARE_ITC_BITS_PER_VOLT / DA_EphysGuiState[DACs[p]][%DAGain]
	endif

	// AD: w' = w  / (g * s)
	if(numADCs > 0)
		gain[numDACs, numDACs + numADCs - 1] = DA_EphysGuiState[ADCs[p - numDACs]][%ADGain] * HARDWARE_ITC_BITS_PER_VOLT
	endif

	// no scaling done for TTL
	if(numTTLs > 0)
		gain[numDACs + numADCs, *] = 1
	endif

	sweepWaveName = "Sweep_" +  num2str(sweepNo)
	Make/O/N=(numRows, numCols)/Y=(SWS_GetRawDataFPType(panelTitle)) dfr:$sweepWaveName/Wave=sweepWave

	MultiThread sweepWave[][] = ITCDataWave[p][q] / gain[q]
	CopyScales/P ITCDataWave, sweepWave

	return sweepWave
End

/// @brief Delete all sweep and config waves having a sweep number
/// of `sweepNo` and higher
Function SWS_DeleteDataWaves(panelTitle)
	string panelTitle

	string list, path, name
	variable i, numItems, waveSweepNo, sweepNo

	sweepNo   = GetSetVariable(panelTitle, "SetVar_Sweep")
	path      = GetDeviceDataPathAsString(panelTitle)
	DFREF dfr = GetDeviceDataPath(panelTitle)
	list      = GetListOfObjects(dfr, DATA_SWEEP_REGEXP, waveProperty="MINCOLS:2")
	list     += GetListOfObjects(dfr, DATA_SWEEP_REGEXP_BAK, waveProperty="MINCOLS:2")
	list     += GetListOfObjects(dfr, DATA_CONFIG_REGEXP, waveProperty="MINCOLS:2")
	list     += GetListOfObjects(dfr, DATA_CONFIG_REGEXP_BAK, waveProperty="MINCOLS:2")
	list     += GetListOfObjects(dfr, ".*", typeFlag=COUNTOBJECTS_DATAFOLDER)

	numItems = ItemsInList(list)
	for(i = 0; i < numItems; i += 1)
		name = StringFromList(i, list)
		waveSweepNo = ExtractSweepNumber(name)

		if(waveSweepNo < sweepNo)
			continue
		endif
		KillOrMoveToTrashPath(path + ":" + name)
	endfor
End

/// @brief Return the floating point type for storing the raw data
///
/// The returned values are the same as for `WaveType`
static Function SWS_GetRawDataFPType(panelTitle)
	string panelTitle

	return GetCheckboxState(panelTitle, "Check_Settings_UseDoublePrec") ? IGOR_TYPE_64BIT_FLOAT : IGOR_TYPE_32BIT_FLOAT
End