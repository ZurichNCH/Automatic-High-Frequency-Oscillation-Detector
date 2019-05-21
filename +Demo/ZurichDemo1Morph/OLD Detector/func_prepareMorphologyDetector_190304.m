% ===================================================================================
% *** Function DETECTOR MCGILL
% 181015 by borec: FRandR not defined
function [ sig ] = func_prepareMorphologyDetector_190304(data, p)
p.limitFrequencyST = p.lp;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%% reading the signals
display(['%%%%%%%%%%%%% START ANALYSIS ' datestr(now,'dd-mm-yyyy HH-MM-SS') ' %%%%%%%%%%%%%%%%'])
display(' ')

%% read visual markings and filter data
sig=struct;

display(['Length Extracted Data = ' num2str(length(data))])

sig.signal = data;
sig.signalFilt = filtfilt(p.filter.Rb, p.filter.Ra, sig.signal);
sig.signalFiltFR = filtfilt(p.filter.FRb, p.filter.FRa, sig.signal);
sig.duration = p.duration;

%% %%%%%%%%---- AUTOMATIC DETECTION ----%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% look for ripples %%%%%%%%%%%%%%%%%%%%%%%%
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
      
sig.THR = HFOobj.THR;
sig.THRfiltered = HFOobj.THRfiltered;
sig.baselineInd = HFOobj.baselineInd;
sig.short_baseline = HFOobj.short_baseline;
sig.dur = HFOobj.dur;

HFOobj = rmfield(HFOobj,'env');
sig.HFOobj = HFOobj;

% Find peaks of HFOs
if exist('results', 'var')==1
    for iDet=1:length(results)
        if iDet==1
            sig.autoSta = results(iDet).start/p.fs;
            sig.autoEnd = results(iDet).stop/p.fs;
            sig.mark = 1;
            sig.peakAmplitude = results(iDet).peakAmplitude;
        else
            sig.autoSta = [sig.autoSta results(iDet).start/p.fs];
            sig.autoEnd = [sig.autoEnd results(iDet).stop/p.fs];
            sig.mark = [sig.mark 1];
            sig.peakAmplitude = [sig.peakAmplitude,results(iDet).peakAmplitude];
        end
    end
else
    sig.autoSta=[];
    sig.autoEnd=[];
    sig.mark=[];
    sig.peakAmplitude=[];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% look for FRs %%%%%%%%%%%%%%%%%%%%%%%%%%%%
display('***** Start Fast Ripple Detection *****')
input.time_thr = 0.01;
input.CDFlevelRMS = CDFlevelRMSFR;
input.CDFlevelFilt = CDFlevelFiltFR;

[HFOobj, results] = func_doMorphologyDetector(sig, p.hpFR, 'FastRipple', p, input);

sig.THRFR = HFOobj.THR;
sig.THRfilteredFR = HFOobj.THRfiltered;
sig.baselineIndFR = HFOobj.baselineInd;
sig.short_baselineFR = HFOobj.short_baseline;
sig.durFR = HFOobj.dur;

HFOobj = rmfield(HFOobj,'env');
sig.HFOobjFR = HFOobj;

% Find peaks of HFOs
if exist('results', 'var')==1
    for iDet=1:length(results)
        if iDet==1
            temp.autoSta = results(iDet).start/p.fs;
            temp.autoEnd = results(iDet).stop/p.fs;
            temp.mark = 2;
            temp.peakAmplitude = results(iDet).peakAmplitude;
        else
            temp.autoSta = [temp.autoSta results(iDet).start/p.fs];
            temp.autoEnd = [temp.autoEnd results(iDet).stop/p.fs];
            temp.mark = [temp.mark 2];
            temp.peakAmplitude = [temp.peakAmplitude,results(iDet).peakAmplitude];
        end
    end
else
    temp.autoSta=[];
    temp.autoEnd=[];
    temp.mark=[];
    temp.peakAmplitude=[];
end

sig.autoSta = [sig.autoSta temp.autoSta];
sig.autoEnd = [sig.autoEnd temp.autoEnd];
sig.mark = [sig.mark temp.mark];
sig.peakAmplitude = [sig.peakAmplitude temp.peakAmplitude];

[~,sorted_inds] = sort(sig.autoSta);
sig.autoSta  = sig.autoSta(sorted_inds) ;
sig.autoEnd  = sig.autoEnd(sorted_inds) ;
sig.mark = sig.mark(sorted_inds);
sig.peakAmplitude = sig.peakAmplitude(sorted_inds);

% events: 1-ripple, 2-FR

% check the 0 detection
ToDelete = find(sig.autoSta==0);
sig.autoSta(ToDelete)=[];sig.autoEnd(ToDelete)=[];sig.mark(ToDelete)=[];sig.peakAmplitude(ToDelete)=[];

sig.fs = p.fs;

display(['%%%%%%%%%%%%% END ANALYSIS ' datestr(now,'dd-mm-yyyy HH-MM-SS') ' %%%%%%%%%%%%%%%%'])

end

% % ===================================================================================
% % *** END of FUNCTION Morphology DETECTOR
% % ===================================================================================
