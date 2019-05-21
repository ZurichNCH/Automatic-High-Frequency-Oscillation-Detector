clear
clc
ThisDir = pwd;
MasterDir = ThisDir(1:end-36);
RParaPath = [MasterDir,'\+Demo\ZurichDemo1Morph\Parameters\RMorphPara.mat'];
FRParaPath = [MasterDir,'\+Demo\ZurichDemo1Morph\Parameters\FRMorphPara.mat'];
DataPath = [MasterDir,'\+Demo\ZurichDemo1Morph\Data\Bipolar_Data_Patient_10_SO_Recording_01_Interval_01_Channel_021_mPHR1_mPHR2.mat'];

[sig] = getMorpholygyDetections(RParaPath, FRParaPath, DataPath);
%% Markings for start end indices of:
%% ripples 
REvent_start_sec = sig.autoSta(sig.mark==1);
REvent_end_sec   = sig.autoEnd(sig.mark==1);

REvent_start = REvent_start_sec*2000;
REvent_end = REvent_end_sec*2000; 

%% fast ripples
FREvent_start_sec = sig.autoSta(sig.mark==2);
FREvent_end_sec   = sig.autoEnd(sig.mark==2);

FREvent_start = FREvent_start_sec*2000;
FREvent_end = FREvent_end_sec*2000; 

%% Beyond here is the realm of Ece

% IndEvent_start = [results.start];
% IndEvent_end = [results.stop];
%
% [IndEvent_start(1:10)', IndEvent_end(1:10)']
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HFOAnalysisResultsSingleChannel.autoRipSta = HFOAnalysisResultsSingleChannel.autoSta(HFOAnalysisResultsSingleChannel.mark==1);
% HFOAnalysisResultsSingleChannel.autoRipEnd = HFOAnalysisResultsSingleChannel.autoEnd(HFOAnalysisResultsSingleChannel.mark==1);
% HFOAnalysisResultsSingleChannel.peakAmplitudeRip = HFOAnalysisResultsSingleChannel.peakAmplitude(HFOAnalysisResultsSingleChannel.mark==1);
% 
% 
% Parameters implicite in the detector:

% input.BLmu = 0.90; % level for maximum entrophy, threshold for /mu
%
% CDFlevelRMS = 0.95;
% CDFlevelRMSFR = 0.7;
%
% CDFlevelFiltR = 0.99;
% CDFlevelFiltFR = 0.99;
%
% input.DurThr = 0.99;
% input.dur = 60;
%
% input.CDFlevelRMS = CDFlevelRMS;
% input.CDFlevelFilt = CDFlevelFiltR;
%
% input.time_thr = 0.02;
% input.maxNoisemuV = 10;
%
% HFOobj.BLborder  = 0.02; % sec, ignore borders of 1 sec interval because of ST transform
% HFOobj.BLmindist = 10*p.fs/1e3;

% HFOobj.maxAmplitudeFiltered = 30;
% HFOobj.minNumberOscillations = 6;  %
% HFOobj.maxAmplitudeFiltered = 30
% Utility

% data.x_bip = dataBipolarChannel.trial{1}';
% data.fs = 2000;
% data.lab_bip = dataBipolarChannel.label';
% data.Datasetup = [];


