% this script creats a struct containing preset parameter for HFO detection
% and saves it a .mat file. The values must be set here by hand.
clear
clc

%% STAGE I : filtering
load([pwd,'/FilterParaRipple.mat'])
DetPara.FilterPara = FilterPara;

%% STAGE O : loading
DetPara.maxIntervalToJoinPARA  = 0.01;  % parameter used in the computation of maxIntervalToJoin
DetPara.MinHighEntrIntvLenPARA = 0.01;   % parameter used in the computation of MinHighEntrIntvLen
DetPara.minEventTimePARA       = 0.01;  % parameter used in the computation of minEventTime
DetPara.durFrac                = 1;     % Fraction of signal, from the start for high entropy intv search
DetPara.DurBaseline            = 30;   % This is the duration of time considerd for the baseline calc
DetPara.highPass               = FilterPara.BandFreq.highPass;  % high pass frequency (lower limit of the frequency band of interest)
%% Filtering
DetPara.lowPass                = FilterPara.BandFreq.lowPass;  % low pass frequency (upper limit of the band of interest)
DetPara.SmoothWindow           = 1/DetPara.highPass; % optional smoothing in for envelope, used in morphology
%% STAGE II : baselining
DetPara.maxNoisePARA          = 2;     % parameter for Standard deviations for noise rejection
DetPara.ConstMaxNoisemuV      = [];    % Basline noise threshold, sets maxNoisemuV (optional)
DetPara.timeStep              = 1;     %The time steps taken over the timeInterval in second.
DetPara.StockwellFreqRange    = DetPara.highPass+1;  % frequency range for the ST transform
DetPara.StockwellSampRate     = 1;     % Probably not even used in stockwell transform
DetPara.MaxEntroFracPARA      = 0.9;  % Fraction: used to set pow. spec. entropy threshold 
DetPara.STransFreqTrimPARA    = 0.02;  % discards S-transform spectrum at low and high freq.
DetPara.CDFlevel              = 0.7; % percentile of amplitude distribution of detected baselines
DetPara.CDFlevelFilt         = 0.99;   % Calculate the baseline threshold using filtered signal and not envelope.

%% STAGE III
DetPara.lowFreqBound          = 60;    % lower bound for the frequencies.
DetPara.maxAmplBound          = 500;   % Maximum acceptable amplitude before rejection as artifact. 
DetPara.minAmplBound          = 10;    % Min acceptable amplitude before rejection as non-event. 

DetPara.maxcorr               = 0.8;   % Maximum correlation between signals before rejection.
DetPara.MaxInterElectNeig     = 1;     % Electrod neighbor exemption criteria for multi-chan correlation. 
DetPara.multChanEvnRad        = 50;    % Multi channel event radius.

DetPara.EventThrHighPARA      = 0.02;  % A parameter usded in thresholding triggers/events.
DetPara.EventThrLowPARA       = 0.2;   % A parameter usded in thresholding triggers/events.
DetPara.PeaksCount            = 4;     % Events must have this many or more peaks. 
DetPara.maxAmplitudeFiltered  = 30;       % Used in morphology detector.
DetPara.MinInterEventDist     = 40;    % Lower Bound for how many samples there must be between events.
 
DetPara.MinPeakAmpl           = 0;     % The peaks of events must all be above this value.  
DetPara.intIORadiusPARA       = 0.5;   % Determines the the size of the intervals of interest.
DetPara.highFreqBound         = 250;   % upper bound for the frequencies.  
                                       
%% Save
fileName = [char(date), 'TESTpara'];
saveLocation = pwd;
parameterFileLocation = [saveLocation,'/',fileName];

save(parameterFileLocation, 'DetPara')