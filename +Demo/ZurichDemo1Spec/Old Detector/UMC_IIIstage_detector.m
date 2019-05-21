%% detectorUMC

% =========================================================================
% *** Function UMC_IIIstage_detectorUMC
% ***
% *** automatic time-frequency algorithm for detection of HFOs
% *** for more details refer to the publication
% *** WHEN IT WILL PUBLISHED
% ***
% ***----------------------------------------------------------------------
% *** Analysis:
% *** 0. Preprocessing
%        Filter data in the range [hp lp]
%        Calculate Hilbert envelope of the band passed signal
% *** 1. Stage I
%        Calculate threshold according to entropy based method
%        Detection of Events of Interest
%        Merge EoIs with inter-event-interval less than 10 ms into one EoI
% *** 2. Stage II
%        Compute TF around the EOI and check for contribution in HF
%        Collect statistic of each event
% *** 3. Stage III -recognition of HFOs among EoIs
%        Compute correlation across channel to identify artifacts

% -------------------------------------------------------------------------
% *** input parameteres:
% *** data - raw EEG mulichannel signal
% *** fs - frequency sampling rate
% *** hp - high pass frequency for filtering
% *** lp - low pass frequency for filtering
% *** channel_name - name of the channel
% *** input.time_thr max ripples time duration in ms
% *** ---------------------------------------------------------------------
% ***
% *** ---------------------------------------------------------------------
% *** for Matlab R14a
% *** version 1.0 (Feb 2014)
% *** (c)  Tommaso Fedele 
% *** email: tommaso.fedele@usz.ch

% =========================================================================


function [HFOobj, results] = UMC_IIIstage_detector(Signal, input)



    % ---------------------------------------------------------------------
    % set preprocessing parameters
    HFOobj.hp           = input.hp;      % high pass frequency
    HFOobj.lp           = input.lp;      % low pass frequency
    HFOobj.filter       = input.filter; % pre computed FIR
    HFOobj.fs           = input.fs;     % sampling frequency (for TF)
    HFOobj.channel_name = input.channel_name; % channel labels

    % STAGE I
    HFOobj.BLmu      = 0.85;        %input.BLmu; % level for maximum entrophy, threshold for /mu
    HFOobj.CDFlevel  = 0.995;        %input.CDFlevel; %.99 percentile of detected baselines, incr= incr in trheshold, 
    HFOobj.BLst_freq = HFOobj.hp+1; % frequency range from
    HFOobj.BLborder  = 0.02;        % sec, ignore borders of 1 sec interval because of ST transform
    HFOobj.BLmindist = 0.1*HFOobj.fs;%input.base_length*HFOobj.fs; % pt, min   interval for baseline in po
    HFOobj.dur       = 120;         % number os seconds to take for baseline detection
%     HFOobj.maxNoisemuV = input.maxNoisemuV;
    HFOobj.THRsss = [];
%     HFOobj.time_thr  = ceil(input.time_dur*HFOobj.fs);   % time above threshold for EOI
    
    % merge IoEs
    HFOobj.maxIntervalToJoin = 0.01*HFOobj.fs; % 10 ms
    
        % STAGE II
    HFOobj.EVENTSlabel = {'ch','trig_start','aboveTHR','EnergyLF','EnergyR','EnergyFR',....
                'Amplpp','PowerTrough','Ftrough','PowmaxFR','fmax_FR','THR'}; 
    HFOobj.EVENTS =[];
    
    % STAGEIII
    HFOobj.stageIII_flag = input.stageIII_flag;
    HFOobj.maxcorr  = 0.8;
    if isfield(input,'Datasetup')
        HFOobj.Datasetup =input.Datasetup;
    end
    
     
    
    %----------------------------------------------------------------------
    % Signal must be [points x channel]
    [~, chd] = min(size(Signal)); 
    if chd == 1
        Signal = Signal';
    end
    HFOobj.N_ch = size(Signal,2);


    % ------PREPROCESSING-------------------------------------------------- 
    % filtering
    [Signalfilt, HFOobj] = filter_and_param(Signal, HFOobj);
    
    % envelope
    env = abs(hilbert(Signalfilt));

    for ch = 1:HFOobj.N_ch
        
        tic

    % ------STAGE I-------------------------------------------------------- 
    [HFOobj] = baselinethreshold(Signal(:,ch), Signalfilt(:,ch), env(:,ch), HFOobj);
    HFOobj   = findEOI(env(:,ch),HFOobj,Signalfilt(:,ch));
    stageItoc = toc;
    tic
    % ------STAGE II------------------------------------------------------- 
    HFOobj   = events_validation(Signal(:,ch), Signalfilt(:,ch), HFOobj, ch);
    stageIItoc = toc;
    end
    
    if size(HFOobj.EVENTS,1)>1
        if HFOobj.stageIII_flag == 1
            disp stageIII
            tic
        % ------STAGE III------------------------------------------------------ 
            HFOobj  = multichannel_validation(Signalfilt, HFOobj);
            stageIIItoc = toc;
        end
    end
    [HFOobj, results] = transfer2results(HFOobj);

end


% ========================================================================= 
% =========================================================================
% =========================================================================
% =========================================================================
function [signalfilt, HFOobj] = filter_and_param(Signal, HFOobj)

    % Filter Signal in the range [hp lp]
    
    
    
    
    switch HFOobj.hp
        case 80  % Ripples

            B = HFOobj.filter.Rb;
            A = HFOobj.filter.Ra;
            HFOobj.lf_bound = 60;
            HFOobj.hf_bound = 250;
            HFOobj.Ampl_bound = 500;
            HFOobj.time_thr = 0.02*HFOobj.fs;
            
        case 250    % Fast Ripples

            B = HFOobj.filter.FRb;
            A = HFOobj.filter.FRa;
            HFOobj.lf_bound = 200;
            HFOobj.hf_bound = 450;
            HFOobj.Ampl_bound = 100;
            HFOobj.time_thr = 0.01*HFOobj.fs;
            
        otherwise

           disp 'WHATrUfiltering????'

    end

    signalfilt=filtfilt(B,A,Signal); %zero-phase filtering
    
     
    
end


function [HFOobj] = baselinethreshold(sigfull, sigfiltered, env, HFOobj)

    % distinguish background activity from spikes-HFO-artifacts
    % according to Stockwell entrophy
    % ref: wavelet entrophy: a new tool for analysis...
    % Osvaldo a. Rosso et al, journal of neuroscience methods, 2000

    % ---------------------------------------------------------------------
    % parameters
    
    indHighEntr=[];
    S(HFOobj.fs)=0;
    HFOobj.maxNoisemuV = 2*std(sigfiltered);

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
                            indHighEntr   = [indHighEntr indAboveThr(j)]; %#ok<AGROW>
                        end  
                    end
                end
            end
        end
        clearvars -except  indHighEntr sigfull sec S env HFOobj sigfiltered

    end
    display(['For 1 minute, baseline length = ' num2str(length(indHighEntr)) ])


    %%%%%%%%%%%%%%% check one more time if the lentgh of baseline is too small
    if length(indHighEntr)<2*HFOobj.fs % then take all 5 minutes
        display(['Baseline length < 2 sec, calculating for 5 min '])

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
                                indHighEntr   = [indHighEntr indAboveThr(j)]; %#ok<AGROW>
                            end 
                        end
                    end
                end
            end
            clearvars -except  indHighEntr sigfull sec S env HFOobj sigfiltered   
        end
        display(['For 5 minute, baseline length = ' num2str(length(indHighEntr)) ])
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
        thrCDF   = x(find(f>HFOobj.CDFlevel ,1));
    else
        thrCDF = 1000;
    end

    HFOobj.THRsss           = [HFOobj.THRsss;  thrCDF];
    HFOobj.THR           = thrCDF;
    HFOobj.indHighEntr   = indHighEntr;  
    HFOobj.b_mean        = mean(baseline);
    HFOobj.b_sd          = std(baseline);

end

function HFOobj = findEOI(env,HFOobj,signalfilt) 
    
    env(1)=0; env(length(env))=0; % assign the first and last positions at 0 point
    pred_env(2:length(env))=env(1:length(env)-1);
    pred_env(1)=pred_env(2);
    if size(env,1) ~= size(pred_env,1)
        env = env';
    end
    trig_start = find(pred_env<HFOobj.THR & env>=HFOobj.THR); % check if envelope crosses the THR level rising
    trig_end   = find(pred_env>=HFOobj.THR & env<HFOobj.THR);
    
    aboveTHR = trig_end-trig_start;
    
    switch HFOobj.hp
        case 80  % Ripples

           ciao = [ find(aboveTHR<0.020*HFOobj.fs) find(aboveTHR>.2*HFOobj.fs) ];
            
        case 250  % FR
    
           ciao = [ find(aboveTHR<0.010*HFOobj.fs) find(aboveTHR>.1*HFOobj.fs) ];
           
    end

        
    aboveTHR(ciao) = [];
    trig_start(ciao) = [];
    trig_end(ciao) = [];
    
    % check if there are at least 4 peaks
    ciao2 = [];
    for ev = 1:length(aboveTHR)
         signalfiltOI = signalfilt(trig_start(ev):trig_end(ev));
        put2zero = find(signalfiltOI-HFOobj.THR<=0);
        signalfiltOI(put2zero) = 0; 
        [pks,locs] = findpeaks(signalfiltOI);
        if length(pks)<4
            ciao2 = [ciao2 ev];           
        end  
    end
    
    aboveTHR(ciao2) = [];
    trig_start(ciao2) = [];
    trig_end(ciao2) = [];
    
    HFOobj.aboveTHR   = aboveTHR;
    HFOobj.trig_start = trig_start;
    HFOobj.trig_end   = trig_end;
    
    
       
        
end

function HFOobj  = events_validation(Signal, Signalfilt, HFOobj, ch)

    for triggy = 1:length(HFOobj.trig_end)
%         tic,   triggy     
%         HFOobj.ev_counter =  HFOobj.ev_counter + 1;
       
        intOI = HFOobj.trig_start(triggy)-HFOobj.fs*.5: HFOobj.fs*.5+HFOobj.trig_start(triggy);
        
        intOI(find(intOI>length(Signal))) = [];
        if  find(intOI<1)     
            ciao_init = length( find(intOI<1))   
            intOI(find(intOI<1))              = [];
        else
            ciao_init = 0;
        end
 
             
        Signal_loc          = Signal(intOI);
        [STSignal, t, f]    = st(Signal_loc , 0, 500, 1/HFOobj.fs, 1); % S-transform
        STSignal            = abs(STSignal)';
        
        intEV = -ciao_init+HFOobj.fs*.5: -ciao_init+HFOobj.fs*.5+ HFOobj.aboveTHR(triggy); % time interval of the event
         
        
        EnergyFR          = mean(mean(STSignal(intEV,HFOobj.hp:HFOobj.lp)));
        [peaks , fpeaks ] = findpeaks([0 mean(STSignal(intEV,80:HFOobj.hf_bound))]);
%                     figure,plot(10*log10(mean(STSignal(:,80:450))))
%                     title(num2str(trig_start(triggy)/2048))
        fpeaks  = fpeaks +80;
        np = length(peaks);
        
        if 0,np>1
            npHF = sum((fpeaks > HFOobj.lf_bound & fpeaks <HFOobj.hf_bound));
            if npHF>1
                [peak_ind]          = find(fpeaks>HFOobj.lf_bound); %index of peaks of interest in fpeaks
                peaksHF             = peaks(peak_ind);       %Power of peaks of interest 
                fpeaksHF            = fpeaks(peak_ind);      %freq of peaks of interest 
                [PowmaxFR, fmax_ind]= max(peaksHF);          %Pow,ind of prominent peak
                fmax_FR             = fpeaksHF(fmax_ind);    % freq of prominent peak
                if fmax_ind>1 % find the peak immidatley preceding fmax_FR
                    f_LF       = fpeaksHF(fmax_ind-1);
                else
                    if np==npHF
                        f_LF = HFOobj.lf_bound;
                    else
                        f_LF       = fpeaks(np-npHF);
                    end
                end
            else
                PowmaxFR = peaks(end);
                fmax_FR = fpeaks(end);
                f_LF = fpeaks(end-1);
            end
            [PowerTrough, Ftrough]    = min(mean(STSignal(intEV,f_LF:fmax_FR)));
            Ftrough                    = Ftrough +f_LF;
            EnergyR                    = mean(mean(STSignal(intEV,80:Ftrough)));
            EnergyLF                   = mean(mean(STSignal(intEV,40:80)));
            
        else
            PowmaxFR       = -1;
            fmax_FR        = -1;
            PowerTrough    = -1;
            Ftrough        = -1;
            Ftrough        = -1;
            EnergyR        = -1;
            EnergyLF       = -1;
        end
        
        PowmaxFR           = -1;
            fmax_FR        = 300;
            PowerTrough    = 0;
            Ftrough        = 0;
            Ftrough        = 0;
            EnergyR        = 0;
            EnergyLF       = 100;
        
        
        Amplpp  = range(Signalfilt(intOI));

        HFOobj.EVENTS = [HFOobj.EVENTS;  ch HFOobj.trig_start(triggy) HFOobj.aboveTHR(triggy),...
            EnergyLF  EnergyR EnergyFR  Amplpp PowerTrough Ftrough PowmaxFR fmax_FR HFOobj.THR];
%    toc
    end 
    
   % removing the event not passing stage II
   if size(HFOobj.EVENTS,1)>1
    ciao = [   find(HFOobj.EVENTS(:,3)     <  HFOobj.time_thr)
%                find(HFOobj.EVENTS(:,4)   >  0.040*HFOobj.fs)
               find(HFOobj.EVENTS(:,7)    > HFOobj.Ampl_bound)
               find(HFOobj.EVENTS(:,8)    == -1)               
               find(HFOobj.EVENTS(:,11)    < HFOobj.lf_bound)];
    
    HFOobj.EVENTS2         = HFOobj.EVENTS;      
    HFOobj.EVENTS2(ciao,:) = [];  
   end 
end

function HFOobj  = multichannel_validation(Signalfilt, HFOobj);

    HFOobj.EVENTS3         = HFOobj.EVENTS2;
    
    Nev = size(HFOobj.EVENTS3,1);
    
    % building the strucutre suitable for STAGE III
    
    if Nev>0

        % if there are events
        for ev = 1:Nev

            ch = HFOobj.EVENTS3(ev,1);
            start = HFOobj.EVENTS3(ev,2);
            dur = HFOobj.EVENTS3(ev,3);


           elong = 50;
           interval = (start  - elong) : (start +dur + elong);

           %check borders
           interval(interval<1) = [];
           interval(interval>length(Signalfilt)) = [];

           % correlation across more than 4 channels

           % the artitfact is psread over at least 4 channels
           corr_flag = 1
           ch
           if corr_flag 
               [R,p] = corrcoef(Signalfilt(interval,:));
               Rcol = R(ch,HFOobj.Datasetup(ch).Dist_ord);
               pcol = p(ch,HFOobj.Datasetup(ch).Dist_ord);
           else
               [R ] = cov(SignalFilt(interval,:));
               Rcol = R(ch,HFOobj.Datasetup(ch).Dist_ord)/max(R(ch,HFOobj.Datasetup(ch).Dist_ord));
           end

           clear LimCorr    

           LimCorr = ones(1,length(Rcol))*HFOobj.maxcorr;
           mindist = find(HFOobj.Datasetup(ch).Dist_val <=1 );
           LimCorr(mindist) = 1;


            if length(find(abs(Rcol)> LimCorr))
                stageIIIresp(ev) = 1; % ciao
            else
                stageIIIresp(ev) = 0; % stay
            end
            
        end
        
        HFOobj.EVENTS3(find(stageIIIresp),:) = []; 
        
    end
      
   
end

function [HFOobj, results] = transfer2results(HFOobj);

    for ch = 1:HFOobj.N_ch
        
        if HFOobj.stageIII_flag == 0
            ecco = [];
%             HFOobj.EVENTS2 = [];
%             HFOobj.EVENTS3 = [];
            if isfield(HFOobj, 'EVENTS2')
                if(~isempty(HFOobj.EVENTS2))
                    ecco = find(HFOobj.EVENTS2(:,1) == ch);
                    HFOobj.EVENTS3 = HFOobj.EVENTS2;
                end
            end
        else  
            ecco = [];
            if isfield(HFOobj, 'EVENTS3')
            ecco = find(HFOobj.EVENTS3(:,1)  == ch);
            end
        end
        
        if length(ecco) > 0
            
            for evv = 1:length(ecco)

                results(ch).results(evv).trig_start  = HFOobj.EVENTS3(ecco(evv),2);
                results(ch).results(evv).aboveTHR    = HFOobj.EVENTS3(ecco(evv),3);
                results(ch).results(evv).EnergyLF    = HFOobj.EVENTS3(ecco(evv),4);
                results(ch).results(evv).EnergyR     = HFOobj.EVENTS3(ecco(evv),5);
                results(ch).results(evv).EnergyFR    = HFOobj.EVENTS3(ecco(evv),6);
                results(ch).results(evv).Amplpp      = HFOobj.EVENTS3(ecco(evv),7);
                results(ch).results(evv).PowerTrough = HFOobj.EVENTS3(ecco(evv),8);
                results(ch).results(evv).Ftrough     = HFOobj.EVENTS3(ecco(evv),9);
                results(ch).results(evv).PowmaxFR    = HFOobj.EVENTS3(ecco(evv),10);
                results(ch).results(evv).fmax_FR     = HFOobj.EVENTS3(ecco(evv),11);
                results(ch).results(evv).THR         = HFOobj.EVENTS3(ecco(evv),12);

            end
            
        else
            
                results(ch).results(1).trig_start  = -1;
                results(ch).results(1).aboveTHR    = -1;
                results(ch).results(1).EnergyR     = -1;
                results(ch).results(1).EnergyFR    = -1;
                results(ch).results(1).Amplpp      = -1;
                results(ch).results(1).PowerTrough = -1;
                results(ch).results(1).Ftrough     = -1;
                results(ch).results(1).PowmaxFR    = -1;
                results(ch).results(1).fmax_FR     = -1;
                results(ch).results(1).THR         = -1;      
            
        end
    end
end

function [st,t,f] = st(timeseries,minfreq,maxfreq,samplingrate,freqsamplingrate)
% Returns the Stockwell Transform of the timeseries.
% Code by Robert Glenn Stockwell.
% DO NOT DISTRIBUTE
% BETA TEST ONLY
% Reference is "Localization of the Complex Spectrum: The S Transform"
% from IEEE Transactions on Signal Processing, vol. 44., number 4, April 1996, pages 998-1001.
%
%-------Inputs Needed------------------------------------------------
%  
%   *****All frequencies in (cycles/(time unit))!******
%	"timeseries" - vector of data to be transformed
%-------Optional Inputs ------------------------------------------------
%
%"minfreq" is the minimum frequency in the ST result(Default=0)
%"maxfreq" is the maximum frequency in the ST result (Default=Nyquist)
%"samplingrate" is the time interval between samples (Default=1)
%"freqsamplingrate" is the frequency-sampling interval you desire in the ST result (Default=1)
%Passing a negative number will give the default ex.  [s,t,f] = st(data,-1,-1,2,2)
%-------Outputs Returned------------------------------------------------
%
% st     -a complex matrix containing the Stockwell transform. 
%			 The rows of STOutput are the frequencies and the 
%         columns are the time values ie each column is 
%         the "local spectrum" for that point in time
%  t      - a vector containing the sampled times
%  f      - a vector containing the sampled frequencies
%--------Additional details-----------------------
%   %  There are several parameters immediately below that
%  the user may change. They are:
%[verbose]    if true prints out informational messages throughout the function.
%[removeedge] if true, removes a least squares fit parabola
%                and puts a 5% hanning taper on the edges of the time series.
%                This is usually a good idea.
%[analytic_signal]  if the timeseries is real-valued
%                      this takes the analytic signal and STs it.
%                      This is almost always a good idea.
%[factor]     the width factor of the localizing gaussian
%                ie, a sinusoid of period 10 seconds has a 
%                gaussian window of width factor*10 seconds.
%                I usually use factor=1, but sometimes factor = 3
%                to get better frequency resolution.
%   Copyright (c) by Bob Stockwell
%   $Revision: 1.2 $  $Date: 1997/07/08  $


% This is the S transform wrapper that holds default values for the function.
TRUE = 1;
FALSE = 0;
%%% DEFAULT PARAMETERS  [change these for your particular application]
verbose = FALSE;          
removeedge= FALSE;
analytic_signal =  FALSE;
factor = 1;
%%% END of DEFAULT PARAMETERS

%%%START OF INPUT VARIABLE CHECK
% First:  make sure it is a valid time_series 
%         If not, return the help message

if verbose disp(' '),end  % i like a line left blank

if nargin == 0 
   if verbose disp('No parameters inputted.'),end
   st_help
   t=0;,st=-1;,f=0;
   return
end

% Change to column vector
if size(timeseries,2) > size(timeseries,1)
	timeseries=timeseries';	
end

% Make sure it is a 1-dimensional array
if size(timeseries,2) > 1
   error('Please enter a *vector* of data, not matrix')
	return
elseif (size(timeseries)==[1 1]) == 1
	error('Please enter a *vector* of data, not a scalar')
	return
end

% use defaults for input variables

if nargin == 1
   minfreq = 0;
   maxfreq = fix(length(timeseries)/2);
   samplingrate=1;
   freqsamplingrate=1;
elseif nargin==2
   maxfreq = fix(length(timeseries)/2);
   samplingrate=1;
   freqsamplingrate=1;
   [ minfreq,maxfreq,samplingrate,freqsamplingrate] =  check_input(minfreq,maxfreq,samplingrate,freqsamplingrate,verbose,timeseries);
elseif nargin==3 
   samplingrate=1;
   freqsamplingrate=1;
   [ minfreq,maxfreq,samplingrate,freqsamplingrate] =  check_input(minfreq,maxfreq,samplingrate,freqsamplingrate,verbose,timeseries);
elseif nargin==4   
   freqsamplingrate=1;
   [ minfreq,maxfreq,samplingrate,freqsamplingrate] =  check_input(minfreq,maxfreq,samplingrate,freqsamplingrate,verbose,timeseries);
elseif nargin == 5
      [ minfreq,maxfreq,samplingrate,freqsamplingrate] =  check_input(minfreq,maxfreq,samplingrate,freqsamplingrate,verbose,timeseries);
else      
   if verbose disp('Error in input arguments: using defaults'),end
   minfreq = 0;
   maxfreq = fix(length(timeseries)/2);
   samplingrate=1;
   freqsamplingrate=1;
end
if verbose 
   disp(sprintf('Minfreq = %d',minfreq))
   disp(sprintf('Maxfreq = %d',maxfreq))
   disp(sprintf('Sampling Rate (time   domain) = %d',samplingrate))
   disp(sprintf('Sampling Rate (freq.  domain) = %d',freqsamplingrate))
   disp(sprintf('The length of the timeseries is %d points',length(timeseries)))

   disp(' ')
end
%END OF INPUT VARIABLE CHECK

% If you want to "hardwire" minfreq & maxfreq & samplingrate & freqsamplingrate do it here

% calculate the sampled time and frequency values from the two sampling rates
t = (0:length(timeseries)-1)*samplingrate;
spe_nelements =ceil((maxfreq - minfreq+1)/freqsamplingrate);
f = (minfreq + [0:spe_nelements-1]*freqsamplingrate)/(samplingrate*length(timeseries));
if verbose disp(sprintf('The number of frequency voices is %d',spe_nelements)),end


% The actual S Transform function is here:
st = strans(timeseries,minfreq,maxfreq,samplingrate,freqsamplingrate,verbose,removeedge,analytic_signal,factor); 
% this function is below, thus nicely encapsulated

%WRITE switch statement on nargout
% if 0 then plot amplitude spectrum
if nargout==0 
   if verbose disp('Plotting pseudocolor image'),end
   pcolor(t,f,abs(st))
end


return
end

%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


function st = strans(timeseries,minfreq,maxfreq,samplingrate,freqsamplingrate,verbose,removeedge,analytic_signal,factor); 
% Returns the Stockwell Transform, STOutput, of the time-series
% Code by R.G. Stockwell.
% Reference is "Localization of the Complex Spectrum: The S Transform"
% from IEEE Transactions on Signal Processing, vol. 44., number 4,
% April 1996, pages 998-1001.
%
%-------Inputs Returned------------------------------------------------
%         - are all taken care of in the wrapper function above
%
%-------Outputs Returned------------------------------------------------
%
%	ST    -a complex matrix containing the Stockwell transform.
%			 The rows of STOutput are the frequencies and the
%			 columns are the time values
%
%
%-----------------------------------------------------------------------

% Compute the length of the data.
n=length(timeseries);
original = timeseries;
if removeedge
    if verbose disp('Removing trend with polynomial fit'),end
 	 ind = [0:n-1]';
    r = polyfit(ind,timeseries,2);
    fit = polyval(r,ind) ;
	 timeseries = timeseries - fit;
    if verbose disp('Removing edges with 5% hanning taper'),end
    sh_len = floor(length(timeseries)/10);
    wn = hanning(sh_len);
    if(sh_len==0)
       sh_len=length(timeseries);
       wn = 1&[1:sh_len];
    end
    % make sure wn is a column vector, because timeseries is
   if size(wn,2) > size(wn,1)
      wn=wn';	
   end
   
   timeseries(1:floor(sh_len/2),1) = timeseries(1:floor(sh_len/2),1).*wn(1:floor(sh_len/2),1);
	timeseries(length(timeseries)-floor(sh_len/2):n,1) = timeseries(length(timeseries)-floor(sh_len/2):n,1).*wn(sh_len-floor(sh_len/2):sh_len,1);
  
end

% If vector is real, do the analytic signal 

if analytic_signal
   if verbose disp('Calculating analytic signal (using Hilbert transform)'),end
   % this version of the hilbert transform is different than hilbert.m
   %  This is correct!
   ts_spe = fft(real(timeseries));
   h = [1; 2*ones(fix((n-1)/2),1); ones(1-rem(n,2),1); zeros(fix((n-1)/2),1)];
   ts_spe(:) = ts_spe.*h(:);
   timeseries = ifft(ts_spe);
end  

% Compute FFT's
tic;vector_fft=fft(timeseries);tim_est=toc;
vector_fft=[vector_fft,vector_fft];
tim_est = tim_est*ceil((maxfreq - minfreq+1)/freqsamplingrate)   ;
if verbose disp(sprintf('Estimated time is %f',tim_est)),end

% Preallocate the STOutput matrix
st=zeros(ceil((maxfreq - minfreq+1)/freqsamplingrate),n);
% Compute the mean
% Compute S-transform value for 1 ... ceil(n/2+1)-1 frequency points
if verbose disp('Calculating S transform...'),end
if minfreq == 0
   st(1,:) = mean(timeseries)*(1&[1:1:n]);
else
  	st(1,:)=ifft(vector_fft(minfreq+1:minfreq+n).*g_window(n,minfreq,factor));
end

%the actual calculation of the ST
% Start loop to increment the frequency point
for banana=freqsamplingrate:freqsamplingrate:(maxfreq-minfreq)
   st(banana/freqsamplingrate+1,:)=ifft(vector_fft(minfreq+banana+1:minfreq+banana+n).*g_window(n,minfreq+banana,factor));
end   % a fruit loop!   aaaaa ha ha ha ha ha ha ha ha ha ha
% End loop to increment the frequency point
if verbose disp('Finished Calculation'),end

%%% end strans function
end
%------------------------------------------------------------------------
function gauss=g_window(length,freq,factor)

% Function to compute the Gaussion window for 
% function Stransform. g_window is used by function
% Stransform. Programmed by Eric Tittley
%
%-----Inputs Needed--------------------------
%
%	length-the length of the Gaussian window
%
%	freq-the frequency at which to evaluate
%		  the window.
%	factor- the window-width factor
%
%-----Outputs Returned--------------------------
%
%	gauss-The Gaussian window
%

vector(1,:)=[0:length-1];
vector(2,:)=[-length:-1];
vector=vector.^2;    
vector=vector*(-factor*2*pi^2/freq^2);
% Compute the Gaussion window
gauss=sum(exp(vector));
end
%-----------------------------------------------------------------------

%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
function [ minfreq,maxfreq,samplingrate,freqsamplingrate] =  check_input(minfreq,maxfreq,samplingrate,freqsamplingrate,verbose,timeseries)
% this checks numbers, and replaces them with defaults if invalid

% if the parameters are passed as an array, put them into the appropriate variables
s = size(minfreq);
l = max(s);
if l > 1  
   if verbose disp('Array of inputs accepted.'),end
   temp=minfreq;
   minfreq = temp(1);;
   if l > 1  maxfreq = temp(2);,end;
   if l > 2  samplingrate = temp(3);,end;
   if l > 3  freqsamplingrate = temp(4);,end;
   if l > 4  
      if verbose disp('Ignoring extra input parameters.'),end
   end;

end      
     
   if minfreq < 0 | minfreq > fix(length(timeseries)/2);
      minfreq = 0;
      if verbose disp('Minfreq < 0 or > Nyquist. Setting minfreq = 0.'),end
   end
   if maxfreq > length(timeseries)/2  | maxfreq < 0 
      maxfreq = fix(length(timeseries)/2);
      if verbose disp(sprintf('Maxfreq < 0 or > Nyquist. Setting maxfreq = %d',maxfreq)),end
   end
      if minfreq > maxfreq 
      temporary = minfreq;
      minfreq = maxfreq;
      maxfreq = temporary;
      clear temporary;
      if verbose disp('Swapping maxfreq <=> minfreq.'),end
   end
   if samplingrate <0
      samplingrate = abs(samplingrate);
      if verbose disp('Samplingrate <0. Setting samplingrate to its absolute value.'),end
   end
   if freqsamplingrate < 0   % check 'what if freqsamplingrate > maxfreq - minfreq' case
      freqsamplingrate = abs(freqsamplingrate);
      if verbose disp('Frequency Samplingrate negative, taking absolute value'),end
   end

% bloody odd how you don't end a function
end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
function st_help
   disp(' ')
	disp('st()  HELP COMMAND')
	disp('st() returns  - 1 or an error message if it fails')
	disp('USAGE::    [localspectra,timevector,freqvector] = st(timeseries)')
  	disp('NOTE::   The function st() sets default parameters then calls the function strans()')
   disp(' ')  
   disp('You can call strans() directly and pass the following parameters')
   disp(' **** Warning!  These inputs are not checked if strans() is called directly!! ****')
  	disp('USAGE::  localspectra = strans(timeseries,minfreq,maxfreq,samplingrate,freqsamplingrate,verbose,removeedge,analytic_signal,factor) ')
     
   disp(' ')
   disp('Default parameters (available in st.m)')
	disp('VERBOSE          - prints out informational messages throughout the function.')
	disp('REMOVEEDGE       - removes the edge with a 5% taper, and takes')
   disp('FACTOR           -  the width factor of the localizing gaussian')
   disp('                    ie, a sinusoid of period 10 seconds has a ')
   disp('                    gaussian window of width factor*10 seconds.')
   disp('                    I usually use factor=1, but sometimes factor = 3')
   disp('                    to get better frequency resolution.')
   disp(' ')
   disp('Default input variables')
   disp('MINFREQ           - the lowest frequency in the ST result(Default=0)')
   disp('MAXFREQ           - the highest frequency in the ST result (Default=nyquist')
   disp('SAMPLINGRATE      - the time interval between successive data points (Default = 1)')
   disp('FREQSAMPLINGRATE  - the number of frequencies between samples in the ST results')
	
% end of st_help procedure
end
