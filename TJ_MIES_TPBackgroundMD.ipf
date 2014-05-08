#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ITC_BkrdTPMD(DeviceType, DeviceNum, TriggerMode, panelTitle) // if start time = 0 the variable is ignored
 	variable DeviceType, DeviceNum, TriggerMode
	string panelTitle
	string WavePath
	sprintf WavePath, "%s" HSU_DataFullFolderPathString(PanelTitle)
	string  ITCDataWavePath
	sprintf ITCDataWavePath, "%s:ITCDataWave" WavePath
	string ITCChanConfigWavePath
	sprintf ITCChanConfigWavePath, "%s:ITCChanConfigWave" WavePath
	string ITCDeviceIDGlobalPath
	sprintf ITCDeviceIDGlobalPath, "%s:ITCDeviceIDGlobal" WavePath
	string ITCFIFOAvailAllConfigWavePath
	sprintf ITCFIFOAvailAllConfigWavePath, "%s:ITCFIFOAvailAllConfigWave" WavePath
	string cmd
	sprintf cmd, ""
	
	variable StopCollectionPoint = DC_CalculateLongestSweep(panelTitle) // used to determine when a sweep should terminate
	variable ADChannelToMonitor = (DC_NoOfChannelsSelected("DA", "Check", panelTitle)) // channel that is monitored to determine when a sweep should terminate
	NVAR ITCDeviceIDGlobal = $ITCDeviceIDGlobalPath
	
	WAVE ITCDataWave = $ITCDataWavePath // ITC data wave is the wave that is uploaded to the DAC and contains the DA (output) data and place holder for the input data
	WAVE ITCFIFOAvailAllConfigWave = $ITCFIFOAvailAllConfigWavePath
	
	ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, 1)
	ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, 1)
	
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd
	

	
	if (TP_IsBackgrounOpRunning(panelTitle, "ITC_BkrdTPFuncMD") == 0)
		CtrlNamedBackground TestPulseMD, period = 1, burst = 1, proc = ITC_BkrdTPFuncMD
		CtrlNamedBackground TestPulseMD, start
	endif

	if(TriggerMode == 0) // Start data acquisition triggered on immediate - triggered is used for syncronizing/yoking multiple DACs
		Execute "ITCStartAcq" 
	elseif(TriggerMode > 0)
		sprintf cmd, "ITCStartAcq 1, %d" TriggerMode  // Trigger mode 256 = use external trigger
		Execute cmd	
	endif

End

//======================================================================================

Function ITC_BkrdTPFuncMD(s)
	STRUCT WMBackgroundStruct &s
	String cmd, Keyboard, panelTitle
	
	WAVE ActiveDeviceList = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDeviceList // column 0 = ITCDeviceIDGlobal; column 1 = ADChannelToMonitor; column 2 = StopCollectionPoint
	WAVE /T ActiveDeviceTextList = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDeviceTextList
	WAVE /WAVE ActiveDeviceWavePathWave = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDevWavePathWave
	
	variable i = 0
	variable NumberOfActiveDevices
	string WavePath
	string CountPath
	string oscilloscopeSubWindow
	variable ADChannelToMonitor
	variable StopCollectionPoint
	variable NumberOfChannels
	variable sweepCount
	variable startPoint
	variable PointsInTP
	string TPDurationGlobalPath 
	//NVAR FifoOffset = root:FifoOffset
	variable PointsInTPITCDataWave

	
	do // works through list of active devices
		// update parameters for a particular active device
		panelTitle = ActiveDeviceTextList[i]
		WavePath = HSU_DataFullFolderPathString(panelTitle)
		sprintf TPDurationGlobalPath, "%s:TestPulse:Duration" WavePath
		NVAR GlobalTPDurationVariable = $TPDurationGlobalPath // number of points in a single test pulse
		
		WAVE ITCDataWave = ActiveDeviceWavePathWave[i][0]
		WAVE ITCFIFOAvailAllConfigWave = ActiveDeviceWavePathWave[i][1]
		WAVE ITCFIFOPositionAllConfigWavePth = ActiveDeviceWavePathWave[i][2] //  ActiveDeviceWavePathWave contains wave references
		// WAVE ResultsWavePath = ActiveDeviceWavePathWave[i][3]
		//ITCFIFOAvailAllConfigWave[][2] = 0
		CountPath = GetWavesDataFolder(ActiveDeviceWavePathWave[i][0],1) + "count"
		oscilloscopeSubWindow = ActiveDeviceTextList[i] + "#oscilloscope"
		ADChannelToMonitor = ActiveDeviceList[i][1]
	//	StopCollectionPoint = ActiveDeviceList[i][2]
		//variable ScalingAdjustment = (deltax(ITCDataWave)) // 0.01 //0.01) // / 2
		//variable PointsInITCData = numpnts(ITCDataWave)
	//	print ScalingAdjustment
		PointsInTP = (GlobalTPDurationVariable * 2)// /100) //* (ScalingAdjustment/0.005)
		PointsInTPITCDataWave = dimsize(ITCDataWave,0)
		//print "PointsInTP =",PointsInTP
		// works with a active device
		sprintf cmd, "ITCSelectDevice %d" ActiveDeviceList[i][0] // ITCDeviceIDGlobal
		execute cmd		
	
		sprintf cmd, "ITCFIFOAvailableALL /z = 0 , %s" (WavePath + ":ITCFIFOAvailAllConfigWave")
		Execute cmd	
			
		//	variable PointsCompletedInNextChunk = mod((ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2]), PointsInTP)
		//	variable MaxPossibleCompletedChunks = ((mod(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] / PointsInTPITCDataWave)) - PointsCompletedInNextChunk) / PointsInTP
			
			//variable ITCDataWaveCompleteSweeps = floor(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] / PointsInTPITCDataWave)
			//variable PointsCompletedInITCDataWave = mod(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2], ITCDataWaveCompleteSweeps)
			variable PointsCompletedInITCDataWave = PointsInTPITCDataWave - (mod(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2], PointsInTPITCDataWave)
			//startPoint = ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] - PointsCompletedInNextChunk - PointsInTP
			//variable PointsInActiveTP = mod(PointsCompletedInITCDataWave / (PointsInTP*2))
			variable ActiveChunk =  floor(PointsCompletedInITCDataWave /  (PointsInTP*2))
			startPoint = (ActiveChunk * (PointsInTP*2)) 
			if(startPoint < PointsInTP)
				startPoint = 0
			endif
			//startPoint = 0// PointsInTP * (MaxPossibleCompletedChunks - 1)
			DM_CreateScaleTPHoldWaveChunk(panelTitle, startPoint, PointsInTP)
			TP_Delta(panelTitle, WavePath + ":TestPulse") 
			ActiveDeviceList[i][4] += 1
			print ActiveChunk
		
		
		
		if(PointsCompletedInITCDataWave >= (StopCollectionPoint * 1)) // advances the FIFO is the TP sweep has reached it's end

			duplicate /o /r = [0, (ADChannelToMonitor-1)][0,3] ITCFIFOAvailAllConfigWave, $WavePath + ":FifoAdvance" // creates a wave that will take DA FIFO advance parameter
			// the above line of code won't handle acquisition with only AD channels - this is probably more generally true as well - need to work this into the code
			WAVE FIFOAdvance = $WavePath + ":FifoAdvance"
			FIFOAdvance[][2] = ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2]
			sprintf cmd, "ITCUpdateFIFOPositionAll , %s" (WavePath + ":FifoAdvance") // goal is to move the FIFO pointers back to the start
			execute cmd
		endif
		
		//print "fifo = ",(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2]), "NextChunkPoints =", (PointsInTP * (ActiveDeviceList[i][4]))// + ((ActiveDeviceList[i][3] - 1) * PointsInITCData)
		//if((ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] -((ActiveDeviceList[i][3] - 2^16) * PointsInITCData)) > (PointsInTP * ActiveDeviceList[i][4]))

		//if((ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2]  > (PointsInTP * (ActiveDeviceList[i][4]))))// the +2 adds a delay so that the chunking is always a little behind // chops up 100 pulse TP wave into single pulses based on location in data acquisition
		//variable PointsCompletedInNextChunk = mod(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2], PointsInTP)
		//print "PointsCompletedInNextChunk=",PointsCompletedInNextChunk
		//	if((ActiveDeviceList[i][4]) >= ActiveDeviceList[0][5])
		//		ActiveDeviceList[i][4] = 1
		//	endif
			//print "inside"
			ITCDataWave[0][0] =+ 0
			//startPoint = 0//((PointsInTP / 4))// * ActiveDeviceList[i][4])
//			startPoint = ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] - PointsCompletedInNextChunk - PointsInTP
//			DM_CreateScaleTPHoldWaveChunk(panelTitle, startPoint, PointsInTP)
//			TP_Delta(panelTitle, WavePath + ":TestPulse") 
//			ActiveDeviceList[i][4] += 1
//			print startpoint
		//endif
		
		
		//print "FIFOAvailable =", ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2]
		//print "Stop collection point =", StopCollectionPoint*ActiveDeviceList[i][3]
		
		//if(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] >= (StopCollectionPoint * .05 * ActiveDeviceList[i][3])) // advances the FIFO is the TP sweep has reached it's end
			//print "advancing FIFO"
			
			//print StopCollectionPoint*ActiveDeviceList[i][3]

			//FIFOoffset += ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2]
			//FIFOAdvance[][2] = 0
			//ITCFIFOAvailAllConfigWave[][2] =0
			ITCDataWave[0][0] =+ 0
			
			if(mod(s.curRunTicks, 100) == 0)// || BackgroundTPCount == 1) // switches autoscale on and off in oscilloscope Graph
				ModifyGraph /w = $oscilloscopeSubWindow Live = 0
				ModifyGraph /w = $oscilloscopeSubWindow Live = 1
			endif
			
			ActiveDeviceList[i][3] += 1
			//ActiveDeviceList[i][4] = 1 // resets the test pulse chunk to use back to 1 every time the DA wave loops
		//endif
		
		if(exists(countPath) == 0)// uses the presence of a global variable that is created by the activation of repeated aquisition to determine if the space bar can turn off the TP
			Keyboard = KeyboardState("")
			if (cmpstr(Keyboard[9], " ") == 0)	// Is space bar pressed (note the space between the quotations)?
				panelTitle = DAP_ReturnPanelName()
				//PRINT PANELTITLE
				if(stringmatch(panelTitle,ActiveDeviceTextList[i]) == 1) // makes sure the panel title being passed is a data acq panel title -  allows space bar hit to apply to a particualr data acquisition panel
					beep 
					sprintf cmd, "ITCStopAcq"
					execute cmd
					ITC_MakeOrUpdateTPDevLstWave(panelTitle, ActiveDeviceList[i][0], 0, 0, -1) // ActiveDeviceList[i][0] = device ID global
					ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, -1)
					if (dimsize(ActiveDeviceTextList, 0) == 0) 
						CtrlNamedBackground TestPulseMD, stop
						print "Stopping test pulse"
						ITC_FinishTestPulseMD(panelTitle) // stops the test pulse on the top data acq panel
					endif
				endif
			endif
		endif
		
		
		
		NumberOfActiveDevices = numpnts(ActiveDeviceTextList)
		i += 1
	while(i < NumberOfActiveDevices)	
	
	return 0
End
//======================================================================================

Function ITC_FinishTestPulseMD(panelTitle)
	string panelTitle
	string cmd
	// CtrlNamedBackground TestPulse, stop
	// sprintf cmd, "ITCCloseAll" 
	// execute cmd

	controlinfo /w = $panelTitle check_Settings_ShowScopeWindow
	if(v_value == 0)
		DAP_SmoothResizePanel(-340, panelTitle)
		setwindow $panelTitle + "#oscilloscope", hide = 1
	endif

	ControlInfo /w = $panelTitle StartTestPulseButton
	if(V_disable == 2) // 0 = normal, 1 = hidden, 2 = disabled, visible
		Button StartTestPulseButton, win = $panelTitle, disable = 0
	endif
	
	if(V_disable == 3) // 0 = normal, 1 = hidden, 2 = disabled, visible
		V_disable = V_disable & ~0x2
		Button StartTestPulseButton, win = $panelTitle, disable =  V_disable
	endif
	killvariables /z  StopCollectionPoint, ADChannelToMonitor, BackgroundTaskActive
	killstrings /z root:MIES:ITCDevices:PanelTitleG
End


//======================================================================================

Function ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, AddorRemoveDevice)
	string panelTitle
	Variable ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, AddorRemoveDevice // when removing a device only the ITCDeviceIDGlobal is needed
	//Variable start = stopmstimer(-2)

	string WavePath = "root:MIES:ITCDevices:ActiveITCDevices:TestPulse"
	WAVE /z ActiveDeviceList = $WavePath + ":ActiveDeviceList"
	string TPFolderPath
	sprintf TPFolderPath, "%s:TestPulse:TPPulseCount" HSU_DataFullFolderPathString(PanelTitle)
	NVAR TPPulseCount = $TPFolderPath
	if (AddorRemoveDevice == 1) // add a ITC device
		if (waveexists($WavePath + ":ActiveDeviceList") == 0) 
			Make /o /n = (1,6) $WavePath + ":ActiveDeviceList"
			WAVE /Z ActiveDeviceList = $WavePath + ":ActiveDeviceList"
			ActiveDeviceList[0][0] = ITCDeviceIDGlobal
			ActiveDeviceList[0][1] = ADChannelToMonitor
			ActiveDeviceList[0][2] = StopCollectionPoint
			ActiveDeviceList[0][3] = 1 // sweep count
			ActiveDeviceList[0][4] = 1 // TP count
			ActiveDeviceList[0][5] = TPPulseCount // pulses in TP ITC data wave
		elseif (waveexists($WavePath + ":ActiveDeviceList") == 1)
			variable numberOfRows = DimSize(ActiveDeviceList, 0)
			// print numberofrows
			Redimension /n = (numberOfRows + 1, 6) ActiveDeviceList
			ActiveDeviceList[numberOfRows][0] = ITCDeviceIDGlobal
			ActiveDeviceList[numberOfRows][1] = ADChannelToMonitor
			ActiveDeviceList[numberOfRows][2] = StopCollectionPoint
			ActiveDeviceList[0][3] = 1 // sweep count
			ActiveDeviceList[0][4] = 1 // TP count
			ActiveDeviceList[0][5] = TPPulseCount// pulses in TP ITC data wave
		endif
	elseif (AddorRemoveDevice == -1) // remove a ITC device
		Duplicate /FREE /r = [][0] ActiveDeviceList ListOfITCDeviceIDGlobal // duplicates the column that contains the global device ID's
		// wavestats ListOfITCDeviceIDGlobal
		// print "ITCDeviceIDGlobal = ", ITCDeviceIDGlobal
		FindValue /V = (ITCDeviceIDGlobal) ListOfITCDeviceIDGlobal // searchs the duplicated column for the device to be turned off
		DeletePoints /m = 0 v_value, 1, ActiveDeviceList // removes the row that contains the device 
	endif
	//print "text wave creation took (ms):", (stopmstimer(-2) - start) / 1000
End // Function 	ITC_MakeOrUpdateTPDevLstWave(panelTitle)
//=============================================================================================================================

 Function ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, AddorRemoveDevice) // creates or updates wave that contains string of active panel title names
 	string panelTitle
 	Variable AddOrRemoveDevice
 	//Variable start = stopmstimer(-2)

 	String WavePath = "root:MIES:ITCDevices:ActiveITCDevices:TestPulse"
 	WAVE /z /T ActiveDeviceTextList = $WavePath + ":ActiveDeviceTextList"
 	if (AddOrRemoveDevice == 1) // Add a device
 		if(WaveExists($WavePath + ":ActiveDeviceTextList") == 0)
 			Make /t /o /n = 1 $WavePath + ":ActiveDeviceTextList"
 			WAVE /Z /T ActiveDeviceTextList = $WavePath + ":ActiveDeviceTextList"
 			ActiveDeviceTextList = panelTitle
 		elseif (WaveExists($WavePath + ":ActiveDeviceTextList") == 1)
 			Variable numberOfRows = numpnts(ActiveDeviceTextList)
 			Redimension /n = (numberOfRows + 1) ActiveDeviceTextList
 			ActiveDeviceTextList[numberOfRows] = panelTitle
 		endif
 	elseif (AddOrRemoveDevice == -1) // remove a device 
 		FindValue /Text = panelTitle ActiveDeviceTextList
 		Variable RowToRemove = v_value
 		DeletePoints /m = 0 RowToRemove, 1, ActiveDeviceTextList
 	endif
 	 		//print "text wave creation took (ms):", (stopmstimer(-2) - start) / 1000

 	ITC_MakeOrUpdtTPDevWvPth(panelTitle, AddOrRemoveDevice, RowToRemove)

 End // ITC_MakeOrUpdtTPDevListTxtWv(panelTitle)
//=============================================================================================================================

Function ITC_MakeOrUpdtTPDevWvPth(panelTitle, AddOrRemoveDevice, RowToRemove) // creates wave that contains wave references
	String panelTitle
	Variable AddOrRemoveDevice, RowToRemove
	//Variable start = stopmstimer(-2)
	string DeviceFolderPath = HSU_DataFullFolderPathString(panelTitle)
	WAVE /Z /WAVE ActiveDevWavePathWave = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDevWavePathWave
	if (AddOrRemoveDevice == 1) 
		if (WaveExists(root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDevWavePathWave) == 0)
			Make /WAVE /n = (1,4) root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDevWavePathWave
			WAVE /Z /WAVE ActiveDevWavePathWave = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDevWavePathWave
			// print devicefolderpath + ":itcdatawave"
			ActiveDevWavePathWave[0][0] = $(DeviceFolderPath + ":ITCDataWave") 
			ActiveDevWavePathWave[0][1] = $(DeviceFolderPath + ":ITCFIFOAvailAllConfigWave") 
			ActiveDevWavePathWave[0][2] = $(DeviceFolderPath + ":ITCFIFOPositionAllConfigWave") 
			ActiveDevWavePathWave[0][3] = $(DeviceFolderPath + ":ResultsWave") 			
		elseif (WaveExists(root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDevWavePathWave) == 1)
			Variable numberOfRows = DimSize(ActiveDevWavePathWave, 0)
			Redimension /n = (numberOfRows + 1,4) ActiveDevWavePathWave
			ActiveDevWavePathWave[numberOfRows][0] = $(DeviceFolderPath + ":ITCDataWave") 
			ActiveDevWavePathWave[numberOfRows][1] = $(DeviceFolderPath + ":ITCFIFOAvailAllConfigWave") 
			ActiveDevWavePathWave[numberOfRows][2] = $(DeviceFolderPath + ":ITCFIFOPositionAllConfigWave") 
			ActiveDevWavePathWave[numberOfRows][3] = $(DeviceFolderPath + ":ResultsWave")
		endif
	elseif (AddOrRemoveDevice == -1)
		DeletePoints /m = 0 RowToRemove, 1, ActiveDevWavePathWave
	endif
	//print "reference wave creation took (ms):", (stopmstimer(-2) - start) / 1000
End // Function ITC_MakeOrUpdtTPDevWvPth(panelTitle, AddorRemoveDevice)
//=============================================================================================================================
//BELOW  ARE THE OLD TP FUNCTIONS FOR MULTIPLE DEVICES AND YOKING.
//=============================================================================================================================


Function ITC_StartBackgroundTestPulseMD(DeviceType, DeviceNum, panelTitle)
	variable DeviceType, DeviceNum	// ITC-1600
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	// string /G root:MIES:ITCDevices:panelTitleG //$WavePath + ":PanelTitleG" = panelTitle
	// SVAR panelTitleG = root:MIES:ITCDevices:panelTitleG// = $WavePath + ":PanelTitleG"
	string cmd
	variable i = 0
	//variable StopCollectionPoint = DC_CalculateITCDataWaveLength(panelTitle) / 5
	variable StopCollectionPoint = DC_CalculateLongestSweep(panelTitle)
	variable ADChannelToMonitor = (DC_NoOfChannelsSelected("DA", "Check", panelTitle))
	variable /G root:MIES:ITCDevices:BackgroundTPCount = 0
	WAVE ITCDataWave = $WavePath + ":ITCDataWave"
	WAVE ITCFIFOAvailAllConfigWave = $WavePath + ":ITCFIFOAvailAllConfigWave"//
	string  ITCDataWavePath = WavePath + ":ITCDataWave"
	string ITCChanConfigWavePath = WavePath + ":ITCChanConfigWave"
	NVAR ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"
	//print "global device ID = ", ITCDeviceIDGlobal
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd
	sprintf cmd, "ITCconfigAllchannels, %s, %s" ITCChanConfigWavePath, ITCDataWavePath
	execute cmd
	
	ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, 1)
	ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, 1)
	
//			sprintf cmd, "ITCUpdateFIFOPositionAll , %s" WavePath + ":ITCFIFOPositionAllConfigWave" // I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
//			execute cmd // this also seems necessary to update the DA channel data to the board!!
//			
//			sprintf cmd, "ITCStartAcq /R = %d /Z = %d %d, %d, %d" 0, 0, -1, -1, 0//, -1 , %d, %d, %d
//			execute cmd
	
	if (TP_IsBackgrounOpRunning(panelTitle, "ITC_TestPulseFuncMD") == 0)
		CtrlNamedBackground TestPulse, period = 1, proc = ITC_TestPulseFuncMD
		CtrlNamedBackground TestPulse, start
	endif

End
//======================================================================================

Function ITC_TestPulseFuncMD(s)
	STRUCT WMBackgroundStruct &s
	String cmd, Keyboard, panelTitle
	
	// UInt32 curRunTicks	// Tick count when task was called
	// Int32 started	// TRUE when CtrlNamedBackground start is issued
	// UInt32 nextRunTicks
	// print s.started
	// print s.curRunTicks
	WAVE ActiveDeviceList = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDeviceList // column 0 = ITCDeviceIDGlobal; column 1 = ADChannelToMonitor; column 2 = StopCollectionPoint
	WAVE /T ActiveDeviceTextList = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDeviceTextList
	WAVE /WAVE ActiveDeviceWavePathWave = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDevWavePathWave
	
	variable i = 0
	variable BackgroundTPCount = 0
	variable NumberOfActiveDevices
	string WavePath
	string CountPath
	string oscilloscopeSubWindow
	variable ADChannelToMonitor
	variable StopCollectionPoint
	
		//	ActiveDevWavePathWave[0][0] = ITCDataWave
		//	ActiveDevWavePathWave[0][1] = ITCFIFOAvailAllConfigWave 
		//	ActiveDevWavePathWave[0][2] = ITCFIFOPositionAllConfigWave
		//	ActiveDevWavePathWave[0][3] = ResultsWave
	do
		panelTitle = ActiveDeviceTextList[i]
		WavePath = HSU_DataFullFolderPathString(panelTitle)
		WAVE ITCDataWave = ActiveDeviceWavePathWave[i][0]
		WAVE ITCFIFOAvailAllConfigWave = ActiveDeviceWavePathWave[i][1]
		WAVE ITCFIFOPositionAllConfigWavePth = ActiveDeviceWavePathWave[i][2]
		WAVE ResultsWavePath = ActiveDeviceWavePathWave[i][3]
		CountPath = GetWavesDataFolder(ActiveDeviceWavePathWave[i][0],1) + "count"
		oscilloscopeSubWindow = ActiveDeviceTextList[i] + "#oscilloscope"
		ADChannelToMonitor = ActiveDeviceList[i][1]
		StopCollectionPoint = ActiveDeviceList[i][2]
	
		sprintf cmd, "ITCSelectDevice %d" ActiveDeviceList[i][0]// ITCDeviceIDGlobal
		execute cmd
		// print WavePath + ":ITCFIFOPositionAllConfigWave"
		sprintf cmd, "ITCUpdateFIFOPositionAll , %s" WavePath + ":ITCFIFOPositionAllConfigWave" // I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		execute cmd // this also seems necessary to update the DA channel data to the board!!
		
		sprintf cmd, "ITCStartAcq /R = %d /Z = %d %d, %d, %d" 0, 0, -1, -1, 0//, -1 , %d, %d, %d
		Execute cmd	
		// print "FIFOSize", ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2]
		// ITC_StartBckgrdFIFOMonitor()
		// print WavePath + ":ITCFIFOPositionAllConfigWave"
			//print "AD channel to monitor = ", adchanneltomonitor
		do
			sprintf cmd, "ITCFIFOAvailableALL /z = 0 , %s" (WavePath + ":ITCFIFOAvailAllConfigWave")
			// print cmd
			Execute cmd	
			ITCFIFOAvailAllConfigWave[0][0]+=0
			// doxopidle
			// print "FIFOSize = ", ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2]
		while (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] < StopCollectionPoint)// 
		// Check Status


//		sprintf cmd, "ITCGetState /R /O /C /E %s" ResultsWavePath
//		Execute cmd
		
//		sprintf cmd, "ITCConfigChannelReset"
//		Execute cmd
////		sprintf cmd, "ITCUpdateFIFOPositionAll , %s" WavePath + ":ITCFIFOPositionAllConfigWave" // I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
////		execute cmd 


		
		sprintf cmd, "ITCStopAcq /z = 0"
		Execute cmd
//		
		sprintf cmd, "ITCConfigChannelUpload /f /z = 0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
		Execute cmd
		
		DM_CreateScaleTPHoldingWave(panelTitle)
		TP_ClampModeString(panelTitle)
		TP_Delta(panelTitle, WavePath + ":TestPulse") 
	
		//BackgroundTPCount += 1
		if(mod(s.curRunTicks, 100) == 0)// || BackgroundTPCount == 1) // switches autoscale on and off in oscilloscope Graph
			ModifyGraph /w = $oscilloscopeSubWindow Live = 0
			ModifyGraph /w = $oscilloscopeSubWindow Live = 1
		endif
		
		if(exists(countPath) == 0)// uses the presence of a global variable that is created by the activation of repeated aquisition to determine if the space bar can turn off the TP
			Keyboard = KeyboardState("")
			if (cmpstr(Keyboard[9], " ") == 0)	// Is space bar pressed (note the space between the quotations)?
				panelTitle = DAP_ReturnPanelName()
				//PRINT PANELTITLE
				if(stringmatch(panelTitle,ActiveDeviceTextList[i]) == 1) // makes sure the panel title being passed is a data acq panel title
					beep 
//					sprintf cmd, "ITCStopAcq"
//					execute cmd
					ITC_MakeOrUpdateTPDevLstWave(panelTitle, ActiveDeviceList[i][0], 0, 0, -1) // ActiveDeviceList[i][0] = device ID global
					ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, -1)
					if (dimsize(ActiveDeviceTextList, 0) == 0) 
						CtrlNamedBackground TestPulse, stop
						print "stopping test pulse"
						ITC_STOPTestPulseMD(panelTitle) // stops the test pulse on the top data acq panel
					endif
				endif
			endif
		endif
		
		NumberOfActiveDevices = numpnts(ActiveDeviceTextList)
		//print "Number Of Active Devices = ", NumberOfActiveDevices
		i += 1
//		if(i > NumberOfActiveDevices)
//			i = 0 // reinitiates loop through active devices
//		endif
		//print "background loop took (ms):", (stopmstimer(-2) - start) / 1000
		// single loop with one device takes between XXXX micro seconds (micro is the correct prefix)
	while(i < NumberOfActiveDevices)	
	
	return 0
	
End
//======================================================================================

Function ITC_STOPTestPulseMD(panelTitle)
	string panelTitle
	string cmd
	// CtrlNamedBackground TestPulse, stop
	// sprintf cmd, "ITCCloseAll" 
	// execute cmd

	controlinfo /w = $panelTitle check_Settings_ShowScopeWindow
	if(v_value == 0)
		DAP_SmoothResizePanel(-340, panelTitle)
		setwindow $panelTitle + "#oscilloscope", hide = 1
	endif

	//DAP_RestoreTTLState(panelTitle)
	// killwaves /z root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse// this line generates an error. hence the /z. not sure why.
	ControlInfo /w = $panelTitle StartTestPulseButton
	if(V_disable == 2) // 0 = normal, 1 = hidden, 2 = disabled, visible
		Button StartTestPulseButton, win = $panelTitle, disable = 0
	endif
	
	if(V_disable == 3) // 0 = normal, 1 = hidden, 2 = disabled, visible
		V_disable = V_disable & ~0x2
		Button StartTestPulseButton, win = $panelTitle, disable =  V_disable
	endif
	killvariables /z  StopCollectionPoint, ADChannelToMonitor, BackgroundTaskActive
	killstrings /z root:MIES:ITCDevices:PanelTitleG
End