% function [HFOobj, results] = getMorpholygyDetections()
function [sig] = getMorpholygyDetections(RParaPath, FRParaPath, DataPath)
%% Data
load(DataPath,'dataBipolarChannel')
signal =dataBipolarChannel.trial{1}';
%% Parameters
load(RParaPath, 'DetPara')
% Define p
p.hp = DetPara.highPass;
p.lp = DetPara.lowPass;
p.filter.Ra = DetPara.FilterPara.aCoef;
p.filter.Rb = DetPara.FilterPara.bCoef;

p.hpFR = 250;
p.lpFR = 500;
load(FRParaPath, 'DetPara')
p.filter.FRa = DetPara.FilterPara.aCoef;
p.filter.FRb = DetPara.FilterPara.bCoef;
p.duration = 120;
p.fs = DetPara.sampFreq;
p.channel_name = {'Channel'};
%%

[ sig] = func_prepareMorphologyDetector_190304(signal(1:600000), p);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


display(['%%%%%%%%%%%%% START ANALYSIS ' datestr(now,'dd-mm-yyyy HH-MM-SS') ' %%%%%%%%%%%%%%%%'])
display(' ')
%% read visual markings and filter data
if 0
sig=struct;
display(['Length Extracted Data = ' num2str(length(data))])

p.limitFrequencyST = p.lp;
sig.signal = data;
sig.signalFilt = filtfilt(p.filter.Rb, p.filter.Ra, sig.signal);
sig.signalFiltFR = filtfilt(p.filter.FRb, p.filter.FRa, sig.signal);
sig.duration = p.duration;

display('***** Start Ripple Detection *****')
input.BLmu = 0.90; % level for maximum entrophy, threshold for /mu
CDFlevelRMS = 0.95;
CDFlevelRMSFR = 0.7;
CDFlevelFiltR = 0.99;
CDFlevelFiltFR = 0.99;
input.DurThr = 0.99;
input.dur = 60;
input.CDFlevelRMS = CDFlevelRMS;
input.CDFlevelFilt = CDFlevelFiltR;
input.time_thr = 0.02;
input.maxNoisemuV = 10;

[HFOobj, results] = func_doMorphologyDetector(sig, p.hp, 'Ripple', p, input);
end
end
