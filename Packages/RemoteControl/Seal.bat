@echo off
SET IGOR="C:\Program Files (x86)\WaveMetrics\Igor Pro Folder\Igor.exe"
%IGOR% /Q/X P_UpdatePressureMode("ITC1600_Dev_0", 1,"button_DataAcq_Seal",0)