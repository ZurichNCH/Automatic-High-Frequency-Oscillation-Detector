% =========================================================================
% *** Function nbt_doHFO
% ***
% ***----------------------------------------------------------------------
% *** Analysis:
% *** 1. Filter data in the range [hp lp]
% *** 2. Calculate Hilbert envelope of the band passed signal
% *** 3. Calculate threshold according to baseline detection
% *** 4. Stage 1 - detection of Events of Interest
% *** 5. Reject events not having a minimum of 6 peaks above threshold
% *** 6. Merge EoIs with inter-event-interval less than 10 ms into one EoI
% ***
% -------------------------------------------------------------------------
% *** input parameteres:
% *** data - raw EEG signal
% *** fs - frequency sampling rate
% *** hp - high pass frequency for filtering
% *** lp - low pass frequency for filtering
% *** channel_name - name of the channel
% ***
% *** ---------------------------------------------------------------------
% *** for Matlab R14a
% *** version 2.0 (May 2016)
% ***
% *** ---------------------------------------------------------------------
% *** History
% *** 140408 sb created v1.0
% *** 140507 sb changed algorithm for low frequency peak
% *** 140508 sb added baselinedetector
% *** 150319 sb changed filters, application for FR and ripples
% *** 150603 sb adopted to detect in a similar way as in visaul Stellate
% *** 160203 sb added rejecting of artifacts by the absolutel amplitude
% *** 
% =========================================================================
function [HFOobj, results] = func_doMorphologyDetector(sig, hp, mark, p, input)

% ---------------------------------------------------------------------
% set parameters
HFOobj.hp = hp;
HFOobj.hpHigh = p.hpFR;
HFOobj.lp = p.lp;
% main parameters
HFOobj.time_thr = ceil(input.time_thr*p.fs);
HFOobj.fs = p.fs;
HFOobj.channel_name = p.channel_name;
% duration
HFOobj.durThr = input.DurThr;
HFOobj.smoothWindow = 1*1/HFOobj.hp; % RMS smoothing window, in sec
% threshold
HFOobj.BLmu      = input.BLmu; % level for maximum entrophy, threshold for /mu
HFOobj.CDFlevelRMS  = input.CDFlevelRMS; % percentile of detected baselines, incr= incr in trheshold,
HFOobj.CDFlevelFilt  = input.CDFlevelFilt; % percentile of detected baselines, incr= incr in trheshold,       
HFOobj.BLst_freq = HFOobj.hp+1; % frequency range from
HFOobj.BLborder  = 0.02; % sec, ignore borders of 1 sec interval because of ST transform
HFOobj.BLmindist = 10*p.fs/1e3; % pt, min disance interval for baseline in po
HFOobj.dur       = input.dur; % number os seconds to take for baseline detection
HFOobj.maxNoisemuV = input.maxNoisemuV;
% from 160203 added
if  strcmp(mark, 'Ripple')
    HFOobj.maxAmplitudeFiltered = 30;  % max amplitude of ripple, artifact rejection, in muV
elseif strcmp(mark, 'FastRipple')
    HFOobj.maxAmplitudeFiltered = 20;  % max amplitude of FR, artifact rejection, in muV
end
% merge IoEs
HFOobj.maxIntervalToJoin = 0.02*HFOobj.fs; % 10 ms, varies for Ripple and FR
% reject events with less than N peaks
if  strcmp(mark, 'Ripple')
    HFOobj.minNumberOscillations = 6;  % 
elseif strcmp(mark, 'FastRipple')
    HFOobj.minNumberOscillations = 6;  % 
end

% ---------------------------------------------------------------------
% 1.
% filtering
if  strcmp(mark, 'Ripple')
    Signal_filtered = sig.signalFilt;
elseif strcmp(mark, 'FastRipple')
    Signal_filtered = sig.signalFiltFR;
    HFOobj.hp = p.hpFR;
    HFOobj.lp = p.lpFR;
end
% ---------------------------------------------------------------------
% 2.
% envelope
env = smooth(abs(hilbert(Signal_filtered)), HFOobj.smoothWindow*p.fs);
HFOobj.env = env;
 
% ---------------------------------------------------------------------
% 3.
% threshold
res = baselinethreshold(sig.signal,Signal_filtered, env, HFOobj);
HFOobj.THR =res.thr;
HFOobj.THRfiltered =res.thrFilt;
HFOobj.baselineInd = res.baselineInd;
HFOobj.short_baseline = res.short_baseline;
HFOobj.dur = res.dur;

clear res

% display warning that baseline is too short
if length(HFOobj.baselineInd)<2*p.fs
    display('!!! Short baseline !!!')
    % if the baseline is too short, choose a longer interval for baseline
    % detection HFOobj.dur 
end

% ---------------------------------------------------------------------
% 4.
% Stage 1 - detection of EoIs
env(1)=0; env(length(env))=0; % assign the first and last positions at 0 point

pred_env(2:length(env))=env(1:length(env)-1);
pred_env(1)=pred_env(2);
if size(pred_env,1)~=size(env,1) % check the size if it's not been transposed
    pred_env=pred_env';
end

t1=find(pred_env<(HFOobj.THR*HFOobj.durThr) & env>=(HFOobj.THR*HFOobj.durThr));    % find zero crossings rising
t2=find(pred_env>(HFOobj.THR*HFOobj.durThr) & env<=(HFOobj.THR*HFOobj.durThr));    % find zero crossings falling

trig=find(pred_env<HFOobj.THR & env>=HFOobj.THR); % check if envelope crosses the THR level rising
trig_end=find(pred_env>=HFOobj.THR & env<HFOobj.THR); % check if envelope crosses the THR level falling

nDetectionCounter = 0;
% initialize struct
Detections=struct('channel_name','','start','','peak','', 'stop','','peakAmplitude', '');

% check every trigger point, where envelope crosses the threshold,
% find start and end points (t1 and t2), t2-t1 = duration of event;
% start and end points defined as the envelope crosses half of the
% threshold for each EoIs

for i=1:numel(trig)
    
    % check for time threshold duration, all times are in pt
    if trig_end(i)-trig(i) >= HFOobj.time_thr
        
        nDetectionCounter = nDetectionCounter + 1;
        k=find(t1<=trig(i) & t2>=trig(i)); % find the starting and end points of envelope
        Detections(nDetectionCounter).channel_name = HFOobj.channel_name;
        
        % check if it does not start before 0 moment
        if t1(k)>0
            Detections(nDetectionCounter).start = t1(k);
        else
            Detections(nDetectionCounter).start = 1;
        end
        
        % check if it does not end after last moment
        if t2(k) <= length(env)
            Detections(nDetectionCounter).stop = t2(k);
        else
            Detections(nDetectionCounter).stop = length(env);
        end
        
        [ peakAmplitude , ind_peak ]   = max(env(t1(k):t2(k)));
        
        Detections(nDetectionCounter).peak = (ind_peak + t1(k));
        Detections(nDetectionCounter).peakAmplitude = peakAmplitude;
        
        % check if the peak Amplitude below the maximum
        if Detections(nDetectionCounter).peakAmplitude>HFOobj.maxAmplitudeFiltered
            Detections(nDetectionCounter)=[];
            nDetectionCounter = nDetectionCounter-1;
        end          
                
    end
end

if (nDetectionCounter > 0)
    
    % -----------------------------------------------------------------
    % 5.
    % Check for sufficient number of oscillations
    Detections = checkOscillations(Detections, Signal_filtered, HFOobj);
    
     % -----------------------------------------------------------------
    % 6.
    % Merge EoIs
    results = joinDetections(Detections, HFOobj);
    
    
else
    % initialize struct
    results(1).channel_name =  HFOobj.channel_name;
    results(1).start  =  0;
    results(1).stop   =  0;
    results(1).peak   =  0;
    results(1).peakAmplitude   =  0;

end

end


% =========================================================================
function joinedDetections = joinDetections(Detections, HFOobj)

% Merge EoIs with inter-event-interval less than 10 ms into one EoI
nOrigDetections    = length(Detections);

% fill result with first detection
joinedDetections = struct('channel_name','','start','','peak','', 'stop', '');
joinedDetections(1).channel_name   =  Detections(1).channel_name;
joinedDetections(1).start    =  Detections(1).start;
joinedDetections(1).stop  =  Detections(1).stop;
joinedDetections(1).peak  =  Detections(1).peak;
joinedDetections(1).peakAmplitude  =  Detections(1).peakAmplitude;
nDetectionCounter = 1;

for n = 2 : nOrigDetections
    
    % join detection
    if Detections(n).start > joinedDetections(nDetectionCounter).start
        
        nDiff = Detections(n).start - joinedDetections(nDetectionCounter).stop;
        
        if nDiff < HFOobj.maxIntervalToJoin
            
            joinedDetections(nDetectionCounter).stop = Detections(n).stop;
            
            if joinedDetections(nDetectionCounter).peakAmplitude < ...
                    Detections(n).peakAmplitude
                
                joinedDetections(nDetectionCounter).peakAmplitude = ...
                    Detections(n).peakAmplitude;
                joinedDetections(nDetectionCounter).peak=Detections(n).peak;
                
            end
            
        else
            
            % initialize struct
            nDetectionCounter = nDetectionCounter + 1;
            joinedDetections(nDetectionCounter).channel_name   =  Detections(n).channel_name;
            joinedDetections(nDetectionCounter).start =  Detections(n).start;
            joinedDetections(nDetectionCounter).stop =  Detections(n).stop;
            joinedDetections(nDetectionCounter).peak  =  Detections(n).peak;
            joinedDetections(nDetectionCounter).peakAmplitude  =  Detections(n).peakAmplitude;
            
        end
    end
end

end

% =========================================================================
function checkedOscillations = checkOscillations(Detections, Signal, HFOobj)

% Reject events not having a minimum of 8 peaks above threshold
% ---------------------------------------------------------------------
% set parameters
nDetectionCounter = 0;

for n = 1 : length(Detections)
    
%     Detections(n).start/2000
    
    %detrend data
%     ToDetrend = median(Signal(Detections(n).start: Detections(n).stop));
    ToDetrend = 0;
    
    % get EEG for interval
    intervalEEG = Signal(Detections(n).start : Detections(n).stop)-ToDetrend;
    
    % compute abs values for oscillation interval
    absEEG = abs(intervalEEG);
    
    % look for zeros
    zeroVec=find(intervalEEG(1:end-1).*intervalEEG(2:end)<0);
    nZeros=numel(zeroVec);
    
    nMaxCounter = zeros(1,nZeros-1);
    
    if nZeros > 0
        
        % look for maxima with sufficient amplitude between zeros
        for iZeroCross = 1 : nZeros-1
            
            lStart = zeroVec(iZeroCross);
            lEnd   = zeroVec(iZeroCross+1);
            dMax = max(absEEG(lStart:lEnd));
            
            if dMax > HFOobj.THRfiltered;
                
                nMaxCounter(iZeroCross) = 1;
            else
                nMaxCounter(iZeroCross) = 0;
                
            end
        end
        
    end
    
    nMaxCounter = [0 nMaxCounter 0]; %#ok<*AGROW>
    
    if any(diff(find(nMaxCounter==0))>HFOobj.minNumberOscillations)
        
        nDetectionCounter = nDetectionCounter + 1;
        
        checkedOscillations(nDetectionCounter).channel_name  = ...
            Detections(n).channel_name; 
        checkedOscillations(nDetectionCounter).start    = ...
            Detections(n).start; 
        checkedOscillations(nDetectionCounter).stop     = ...
            Detections(n).stop; 
        checkedOscillations(nDetectionCounter).peak     = ...
            Detections(n).peak; 
        checkedOscillations(nDetectionCounter).peakAmplitude    = ...
            Detections(n).peakAmplitude; 
        
    end
end

if nDetectionCounter < 1
    
    % initialize struct
    checkedOscillations(1).channel_name =  HFOobj.channel_name;
    checkedOscillations(1).start =  0;
    checkedOscillations(1).stop =  0;
    checkedOscillations(1).peak =  0;
    checkedOscillations(1).peakAmplitude    =  0;
    
end
end


% ===================================================================================
function result = baselinethreshold(sigfull,sigfiltered, env, HFOobj)

% distinguish background activity from spikes-HFO-artifacts
% according to Stockwell entrophy
% ref: wavelet entrophy: a new tool for analysis...
% Osvaldo a. Rosso et al, journal of neuroscience methods, 2000

% -------------------------------------------------------------------------
% parameters
indHighEntr=[];
S(HFOobj.fs)=0;

% check duration
if HFOobj.dur>length(sigfull)/HFOobj.fs
    HFOobj.dur=floor(length(sigfull)/HFOobj.fs);
end

% -------------------------------------------------------------------------
for sec=1:floor(HFOobj.dur) % calculate ST for every second
    
    signal = sigfull(1+(sec-1)*HFOobj.fs:sec*HFOobj.fs); % read signal by one sec
    
    % ------------------------------------------------------------
    % S transform
    [STdata, ~ , ~] = st(signal, HFOobj.BLst_freq, HFOobj.lp, 1/HFOobj.fs, 1); % S-transform
    stda=abs(STdata(:,:)).^2;
    
    %     [STdata, t , f] = st(signal, HFOobj.BLst_freq, HFOobj.lp, 1/HFOobj.fs, 1); % S-transform
    %     Clim=[0 20];
    %     imagesc(t,f, stda, Clim)
    %     set(gca,'YDir','normal');
    % %
    
    % ------------------------------------------------------------
    % Stockwell entrophy
    % total energy
    std_total=sum(stda,1);
    
    % relative energy
    prob = bsxfun(@rdivide, stda, std_total);
    
    % total entropy
    for ifr=1:size(stda,2) % for all frequency from 81 to 500
        S(ifr)=-sum(prob(:, ifr).*log(prob(:, ifr)));
    end
    Smax=log(size(stda, 1)); % maximum entrophy = log(f_ST), /mu in mni,
    
    % ------------------------------------------------------------
    % threshold and baseline
    thr=HFOobj.BLmu*Smax; % threshold at mu*Smax, in mni BLmu=0.67
    indAboveThr=find(S>thr); % find pt with high entrophy
    
    if isempty(indAboveThr)~=1
        
        % dont take border points because of stockwell transf
        indAboveThr(indAboveThr<HFOobj.fs*HFOobj.BLborder)=[];
        indAboveThr(indAboveThr>HFOobj.fs*(1-HFOobj.BLborder))=[];
        
        if isempty(indAboveThr)~=1
            
            % ------------------------------------------------------------
            % check for the length
            indAboveThrN=indAboveThr(2:end);
            indBrake=find(indAboveThrN(1:end)-indAboveThr(1:end-1)>1);
            % check if it starts already above or the last point is abover the threshold
            if indAboveThr(1)==HFOobj.fs*HFOobj.BLborder
                indBrake=[1 indBrake];
            end
            if indAboveThr(end)==HFOobj.fs*(1-HFOobj.BLborder)
                indBrake=[indBrake length(indAboveThr)];
            end
            
            if isempty(indBrake)==1
                indBrake=length(indAboveThr);
            end
%             per.baseline{1}=env(indAboveThr(1)+(sec-1)*HFOobj.fs:indAboveThr(indBrake(1))+(sec-1)*HFOobj.fs);
%             indHighEntr
%             per.baseline{1}=env(indAboveThr(1)+(sec-1)*HFOobj.fs:indAboveThr(indBrake(2))+(sec-1)*HFOobj.fs);
%             per.mean{1}  = mean(per.baseline{1});
%             per.sd{1}  = std(per.baseline{1});
            
            for iper=1:length(indBrake)-1             
                j=indBrake(iper)+1:indBrake(iper+1);
                if (length(j)>=HFOobj.BLmindist) 
                    indAboveThr(j)= indAboveThr(j)+(sec-1)*HFOobj.fs;
                    if sum(abs(sigfiltered(indAboveThr(j)))>HFOobj.maxNoisemuV)==0 % check that filtered signal is below max Noise level
                        indHighEntr   = [indHighEntr indAboveThr(j)]; 
                    end  
                end
            end
        end
    end
    clearvars -except  indHighEntr sigfull sec S env HFOobj sigfiltered
    
end
display(['For ' num2str(floor(HFOobj.dur)) ' sec, baseline length = ' num2str(length(indHighEntr)) ])

result.short_baseline = 1;
result.dur = floor(HFOobj.dur);

%% %%%%%%%%%%%%% check one more time if the lentgh of baseline is too small
if length(indHighEntr)<2*HFOobj.fs % then take all 5 minutes
    display('Baseline length < 2 sec, calculating for 5 min ')
    
    for sec=floor(HFOobj.dur)+1:floor(length(sigfull)/HFOobj.fs) % calculate ST for every second
    
        signal = sigfull(1+(sec-1)*HFOobj.fs:sec*HFOobj.fs); % read signal by one sec

        % ------------------------------------------------------------
        % S transform
        [STdata, ~ , ~] = st(signal, HFOobj.BLst_freq, HFOobj.lp, 1/HFOobj.fs, 1); % S-transform
        stda=abs(STdata(:,:)).^2;

%             [STdata, t , f] = st(signal, HFOobj.BLst_freq, HFOobj.lp, 1/HFOobj.fs, 1); % S-transform
%             Clim=[0 20];
%             imagesc(t,f, stda, Clim)
%             set(gca,'YDir','normal');
        % %

        % ------------------------------------------------------------
        % Stockwell entrophy
        % total energy
        std_total=sum(stda,1);

        % relative energy
        prob = bsxfun(@rdivide, stda, std_total);

        % total entropy
        for ifr=1:size(stda,2) % for all frequency from 81 to 500
            S(ifr)=-sum(prob(:, ifr).*log(prob(:, ifr)));
        end
        Smax=log(size(stda, 1)); % maximum entrophy = log(f_ST), /mu in mni,

        % ------------------------------------------------------------
        % threshold and baseline
        thr=HFOobj.BLmu*Smax; % threshold at mu*Smax, in mni BLmu=0.67
        indAboveThr=find(S>thr); % find pt with high entrophy

        if isempty(indAboveThr)~=1

            % dont take border points because of stockwell transf
            indAboveThr(indAboveThr<HFOobj.fs*HFOobj.BLborder)=[];
            indAboveThr(indAboveThr>HFOobj.fs*(1-HFOobj.BLborder))=[];

            if isempty(indAboveThr)~=1

                % ------------------------------------------------------------
                % check for the length
                indAboveThrN=indAboveThr(2:end);
                indBrake=find(indAboveThrN(1:end)-indAboveThr(1:end-1)>1);
                % check if it starts already above or the last point is abover the threshold
                if indAboveThr(1)==HFOobj.fs*HFOobj.BLborder
                    indBrake=[1 indBrake];
                end
                if indAboveThr(end)==HFOobj.fs*(1-HFOobj.BLborder)
                    indBrake=[indBrake length(indAboveThr)];
                end

                if isempty(indBrake)==1
                    indBrake=length(indAboveThr);
                end
    %             per.baseline{1}=env(indAboveThr(1)+(sec-1)*HFOobj.fs:indAboveThr(indBrake(1))+(sec-1)*HFOobj.fs);
    %             indHighEntr
    %             per.baseline{1}=env(indAboveThr(1)+(sec-1)*HFOobj.fs:indAboveThr(indBrake(2))+(sec-1)*HFOobj.fs);
    %             per.mean{1}  = mean(per.baseline{1});
    %             per.sd{1}  = std(per.baseline{1});

                for iper=1:length(indBrake)-1

                    j=indBrake(iper)+1:indBrake(iper+1);
                    if length(j)>=HFOobj.BLmindist
                        indAboveThr(j)= indAboveThr(j)+(sec-1)*HFOobj.fs;
                        if sum(abs(sigfiltered(indAboveThr(j)))>HFOobj.maxNoisemuV)==0 % check that filtered signal is below max Noise level
                            indHighEntr   = [indHighEntr indAboveThr(j)]; 
                        end 
                    end
                end
            end
        end
        clearvars -except  indHighEntr sigfull sec S env HFOobj sigfiltered   
    end
    display(['For ' num2str(floor(length(sigfull)/HFOobj.fs)) ' sec, baseline length = ' num2str(length(indHighEntr)/HFOobj.fs) ' sec'])
    
    result.short_baseline = 0;
    result.dur = floor(length(sigfull)/HFOobj.fs);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% end checking additional

% save baseline
% baseline.IndR = indHighEntr;


% ------------------------------------------------------------
% save values
baseline   = env(indHighEntr);
b.baseline = baseline;

% with CDF at CDFlevel level
if ~isempty(indHighEntr)
    [f,x] = ecdf(baseline);
    % stairs(x,f);
    thrCDF   = x(find(f>HFOobj.CDFlevelRMS ,1));
else
    thrCDF = 1000;
end
b.thr = thrCDF;

b.baselineFiltered = sigfiltered(indHighEntr);
% with CDF at CDFlevel level
if ~isempty(indHighEntr)
    [f,x] = ecdf(b.baselineFiltered);
    % stairs(x,f);
    thrCDF   = x(find(f>HFOobj.CDFlevelFilt ,1));
else
    thrCDF = 1000;
end
b.thrFilt = thrCDF;

% show thresholds
display(['ThrEnv = '  num2str(b.thr) ', ThrFiltSig = ' num2str(b.thrFilt) ])

result.thr = b.thr;
result.thrFilt = b.thrFilt;
result.baselineInd = indHighEntr;


end
