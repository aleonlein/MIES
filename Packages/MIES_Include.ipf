#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion=6.3

/// @file MIES_Include.ipf
/// @brief Main include

// stock igor
#include <Resize Controls>
#include <ZoomBrowser>

// third party includes
#include "ACL_TabUtilities"
#include "ACL_UserdataEditor"
#include "Arduino_Sequencer_Vs1"
#include "FixScrolling"

// our includes
#include "MIES_AnalysisMaster"
#include "MIES_Menu"
#include "MIES_AmplifierInteraction"
#include "MIES_BackgroundMD"
#include "MIES_BackgroundTimerMD"
#include "MIES_Constants"
#include "MIES_DataAcqITC"
#include "MIES_DataAcqMgmt"
#include "MIES_DataBrowser" menus=0
#include "MIES_DataConfiguratorITC"
#include "MIES_DataManagementNew"
#include "MIES_Debugging"
#include "MIES_Downsample" menus=0
#include "MIES_EnhancedWMRoutines"
#include "MIES_EventDetectionCode"
#include "MIES_ExperimentDocumentation"
#include "MIES_GlobalStringAndVariableAccess"
#include "MIES_GuiUtilities"
#include "MIES_HardwareSetUp"
#include "MIES_IgorHooks"
#include "MIES_Indexing"
#include "MIES_Manipulator"
#include "MIES_MiesUtilities"
#include "MIES_Oscilloscope"
#include "MIES_PanelITC"
#include "MIES_PressureControl"
#include "MIES_ProgrammaticGuiControl"
#include "MIES_RepeatedAcquisition"
#include "MIES_SamplingInterval"
#include "MIES_Structures"
#include "MIES_TestPulse"
#include "MIES_TPBackgroundMD"
#include "MIES_Utilities"
#include "MIES_WaveBuilder"
#include "MIES_WaveBuilderPanel" menus=0
#include "MIES_WaveDataFolderGetters"