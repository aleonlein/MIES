#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function RepeatedAcquisition(PanelTitle)
string PanelTitle
variable ITI
variable IndexingState
variable i = 0
variable/g Count=0
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave TestPulseITC = $WavePath + ":TestPulseITC"

	variable TotTrials

	controlinfo/w=$panelTitle SetVar_DataAcq_TotTrial
	TotTrials=v_value
	ValDisplay valdisp_DataAcq_TrialsCountdown win=$panelTitle, value=_NUM:(TotTrials-(Count+1))//updates trials remaining in panel
	
	controlinfo/w=$panelTitle SetVar_DataAcq_ITI
	ITI=v_value
	
	controlinfo/w=$panelTitle Check_DataAcq1_Indexing
	IndexingState=v_value
	

		
		StoreTTLState(panelTitle)//preparations for test pulse begin here
		TurnOffAllTTLs(panelTitle)
		string TestPulsePath = WavePath + ":TestPulse"
		make/o/n=0 $TestPulsePath
		wave TestPulse = $WavePath + ":TestPulse"
		SetScale/P x 0,0.005,"ms", TestPulse

		AdjustTestPulseWave(TestPulse,panelTitle)
		
		make/free/n=8 SelectedDACWaveList
		StoreSelectedDACWaves(SelectedDACWaveList,panelTitle)
		SelectTestPulseWave(panelTitle)
	
		make/free/n=8 SelectedDACScale
		StoreDAScale(SelectedDACScale, panelTitle)
		SetDAScaleToOne(panelTitle)
		
		ConfigureDataForITC(PanelTitle)
		ITCOscilloscope(TestPulseITC, panelTitle)
		
		controlinfo/w=$panelTitle check_Settings_ShowScopeWindow
		if(v_value==0)
		SmoothResizePanel(340, panelTitle)
		endif
		
		StartBackgroundTestPulse(panelTitle)
		StartBackgroundTimer(ITI, "STOPTestPulse()", "RepeatedAcquisitionCounter()", "", panelTitle)
	
		ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
		RestoreDAScale(SelectedDACScale,panelTitle)
		killwaves/f TestPulse

End

Function RepeatedAcquisitionCounter(DeviceType,DeviceNum,panelTitle)
variable DeviceType,DeviceNum
string panelTitle
NVAR Count
variable TotTrials
variable ITI
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave TestPulseITC = $WavePath + ":TestPulseITC"
	wave TestPulse = $WavePath + ":TestPulse"
	controlinfo/w=$panelTitle SetVar_DataAcq_TotTrial
	TotTrials=v_value
	Count+=1
	controlinfo/w=$panelTitle SetVar_DataAcq_ITI
	ITI=v_value
	ValDisplay valdisp_DataAcq_TrialsCountdown win=$panelTitle, value=_NUM:(TotTrials-(Count+1))// reports trials remaining
	
	controlinfo/w=$panelTitle Check_DataAcq1_Indexing
	If(v_value==1)// if indexing is activated, indexing is applied.
	IndexingDoIt(panelTitle)
	endif
	
	if(Count<TotTrials)
		ConfigureDataForITC(PanelTitle)
		ITCOscilloscope(ITCDataWave, panelTitle)
		
		ControlInfo/w=$panelTitle Check_Settings_BackgrndDataAcq
		If(v_value==0)//No background aquisition
			ITCDataAcq(DeviceType,DeviceNum, panelTitle)
			if(Count<(TotTrials-1)) //prevents test pulse from running after last trial is acquired
				StoreTTLState(panelTitle)
				TurnOffAllTTLs(panelTitle)
				
				make/o/n=0 TestPulse
				SetScale/P x 0,0.005,"ms", TestPulse
				AdjustTestPulseWave(TestPulse, panelTitle)
				
				make/free/n=8 SelectedDACWaveList
				StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
				SelectTestPulseWave(panelTitle)
			
				make/free/n=8 SelectedDACScale
				StoreDAScale(SelectedDACScale, panelTitle)
				SetDAScaleToOne(panelTitle)
				
				ConfigureDataForITC(PanelTitle)
				ITCOscilloscope(TestPulseITC,panelTitle)
				
				controlinfo/w=$panelTitle check_Settings_ShowScopeWindow
				if(v_value==0)
					SmoothResizePanel(340, panelTitle)
				endif
				
				StartBackgroundTestPulse(panelTitle)
				StartBackgroundTimer(ITI, "STOPTestPulse()", "RepeatedAcquisitionCounter()", "", panelTitle)
				
				ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
				RestoreDAScale(SelectedDACScale, panelTitle)
				
				killwaves/f TestPulse
			else
				//ValDisplay valdisp_DataAcq_TrialsCountdown value=_NUM:0
				print "Repeated acquisition is complete"
				Killvariables Count
				killvariables/z Start, RunTime
				Killstrings/z FunctionNameA, FunctionNameB//, FunctionNameC
			endif
		else //background aquisition is on
				ITCBkrdAcq(DeviceType,DeviceNum, panelTitle)
								
		endif
	endif

End

Function BckgTPwithCallToRptAcqContr(PanelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave TestPulseITC = $WavePath + ":TestPulseITC"
	wave TestPulse = $WavePath + ":TestPulse"
	variable ITI
	variable TotTrials
	NVAR count	
	controlinfo/w=$panelTitle SetVar_DataAcq_TotTrial
	TotTrials=v_value
	controlinfo/w=$panelTitle SetVar_DataAcq_ITI
	ITI=v_value
			
			if(Count<(TotTrials-1))
				StoreTTLState(panelTitle)
				TurnOffAllTTLs(panelTitle)
				
				make/o/n=0 TestPulse
				SetScale/P x 0,0.005,"ms", TestPulse
				AdjustTestPulseWave(TestPulse, panelTitle)
				
				make/free/n=8 SelectedDACWaveList
				StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
				SelectTestPulseWave(panelTitle)
			
				make/free/n=8 SelectedDACScale
				StoreDAScale(SelectedDACScale, panelTitle)
				SetDAScaleToOne(panelTitle)
				
				ConfigureDataForITC(panelTitle)
				ITCOscilloscope(TestPulseITC, panelTitle)
				
				controlinfo/w=$panelTitle check_Settings_ShowScopeWindow
				if(v_value==0)
					SmoothResizePanel(340, panelTitle)
				endif
				
				StartBackgroundTestPulse(panelTitle)
				StartBackgroundTimer(ITI, "STOPTestPulse()", "RepeatedAcquisitionCounter()", "", panelTitle)
				
				ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
				RestoreDAScale(SelectedDACScale, panelTitle)
				
				killwaves/f TestPulse
			else
				print "Repeated acquisition is complete"
				Killvariables Count
				killvariables/z Start, RunTime
				Killstrings/z FunctionNameA, FunctionNameB//, FunctionNameC
			endif
End


