classdef EventsOfInterest
    properties
      hfo        
      Output
    end
    
    methods
%% Finds the beginning and ends of events across channels 
        function obj = findEvents(obj, RefType)
            Hfo = obj.hfo;
            nbChannels = Hfo.Data.nbChannels;
            for iChan = 1 : nbChannels
                [Event_lenCHAN, Event_startCHAN, Event_endCHAN] = ...
                    Core.EventsOfInterest.findEventsCHAN(Hfo, iChan ,RefType);
                
                obj.Output.EventNumber(iChan)    = length(Event_lenCHAN); 
                obj.Output.Markings.start{iChan} = Event_startCHAN;
                obj.Output.Markings.len{iChan}   = Event_lenCHAN;
                obj.Output.Markings.end{iChan}   = Event_endCHAN;
            end
        end          
        
%% Returns various energy properties associated with the events.
        function obj = creatEventPropTable(obj)
            Event_start= obj.Output.Markings.start;
            Event_len  = obj.Output.Markings.len;
            
            Hfo       = obj.hfo;
            signal    = Hfo.Data.signal;
            signalfilt= Hfo.filtSig.filtSignal;
            
            nbChan    = Hfo.Data.nbChannels;
            obj.Output.EventProp = cell(1,nbChan);
            for iChan = 1:nbChan
                signalCHAN      = signal(:,iChan);
                signalFiltCHAN  = signalfilt(:,iChan);
                Event_startCHAN = Event_start{iChan};
                Event_lenCHAN   = Event_len{iChan};
                
                summaryTable = ...
                    Core.EventsOfInterest.createEventTableCHAN(Hfo, signalCHAN, signalFiltCHAN, Event_startCHAN, Event_lenCHAN);

                obj.Output.EventProp{iChan} = summaryTable;
            end
        end
    
%% Removes events bases on a variety of conditions imposed on event prop. 
        function obj = condRefineEvents(obj, RefType)
            EveTab    = obj.Output.EventProp;
            EveIndLen = obj.Output.Markings.len;
            EventStr  = obj.Output.Markings.start;
            EventEnd  = obj.Output.Markings.end;
            
            Hfo      = obj.hfo;
            lFqBnd   = Hfo.Para.lowFreqBound;
            AmplBnd  = Hfo.Para.maxAmplBound;
            
            minEvT   = Hfo.Data.minEventTime;
            sampFreq = Hfo.Data.sampFreq;
            nbChan   = Hfo.Data.nbChannels;
            durSec   = Hfo.Data.sigDurTime;
            durationMin  = durSec/60;
            
            
            RefinedEventTable = cell(1,nbChan);
            for iChan = 1:nbChan    
                EventTableCHAN  = EveTab{iChan};
                Event_lenCHAN   = EveIndLen{iChan};
                Event_startCHAN = EventStr{iChan};
                Event_endCHAN   = EventEnd{iChan};
                if  strcmp(RefType,'spec')
                    maskEventSelect = Core.EventsOfInterest.SpectrumCondSelectCHAN(...
                        sampFreq, lFqBnd, AmplBnd, minEvT, EventTableCHAN, Event_lenCHAN);
                    
                elseif strcmp(RefType,'morph')
%                     maskEventSelect = Core.EventsOfInterest.MorphCondSelectCHAN(Hfo,Event_startCHAN, Event_endCHAN);
                    maskEventSelect = true(1,length(Event_startCHAN));
                end
                
                %%%
                RefinedEventTable{iChan} = EventTableCHAN(maskEventSelect,:);
                
                obj.Output.Markings.len{iChan}   = Event_lenCHAN(maskEventSelect);
                obj.Output.Markings.start{iChan} = Event_startCHAN(maskEventSelect);
                obj.Output.Markings.end{iChan}   = Event_endCHAN(maskEventSelect);
                
                EventNumber                            = length(Event_lenCHAN(maskEventSelect));
                obj.Output.EventNumber(iChan)          = EventNumber;
                obj.Output.Rates(iChan)            = EventNumber/durationMin;
            end
            obj.Output.EventProp = RefinedEventTable;
        end
        
%% Remove events that occur on multiple channels.
        function obj = multChanRefineEvents(obj)
            Hfo      = obj.hfo;
            maxcorr           = Hfo.Para.maxcorr;
            MaxInterElectNeig = Hfo.Para.MaxInterElectNeig;
            multChanEvnRad    = Hfo.Para.multChanEvnRad;
            
            Datasetup         = Hfo.Data.dataSetup;
            nbChan            = Hfo.Data.nbChannels;
            datSet            = Hfo.Data.dataSetup; 
            durationSec       = Hfo.Data.sigDurTime;
            
            Signalfilt        = Hfo.filtSig.filtSignal;
            
            EveTab            = obj.Output.EventProp;
            
            durationMin       = durationSec/60;
            RefinedEventTable = cell(1,nbChan);
            for iChan    = 1:nbChan
                EventStartCHAN = obj.Output.Markings.start{iChan};
                EventLenCHAN = obj.Output.Markings.len{iChan};
                EventEndCHAN = obj.Output.Markings.end{iChan};
                EventTableCHAN  = EveTab{iChan};
                nbEvents = length(EventLenCHAN);
                
                isNoDatasetup = isempty(datSet);
                if  isNoDatasetup
                    maskMultChan = true(ones(1,nbEvents));
                else
                    maskMultChan = Core.EventsOfInterest.MultChanSelectCHAN(...
                        maxcorr, MaxInterElectNeig, multChanEvnRad, Datasetup, Signalfilt,...
                         iChan, EventStartCHAN, EventLenCHAN, nbEvents);
                end
                
                RefinedEventTable{iChan} = EventTableCHAN(maskMultChan,:);
                
                obj.Output.Markings.len{iChan}   = EventLenCHAN(maskMultChan);
                obj.Output.Markings.start{iChan} = EventStartCHAN(maskMultChan);
                obj.Output.Markings.end{iChan}   = EventEndCHAN(maskMultChan);
                
                EventNumberCHAN                        = length(EventLenCHAN(maskMultChan));
                obj.Output.EventNumber(iChan)          = EventNumberCHAN;
                obj.Output.Rates(iChan)            = EventNumberCHAN/durationMin;
            end
            obj.Output.EventProp = RefinedEventTable;
        end
        
    end

    methods(Static)
%% Find event indeces
        % returns the start and end indeces of the events
        function [Event_len, Event_start, Event_end] = findEventsCHAN(hfo, channel, RefType)
           EventThrHighPARA  = hfo.Para.EventThrHighPARA;
           EventThrLowPARA   = hfo.Para.EventThrLowPARA;
           PeaksCount        = hfo.Para.PeaksCount ;
           maxAmplFilt       = hfo.Para.maxAmplitudeFiltered;
           MinIEveGap        = hfo.Para.MinInterEventDist;
           
           SampFreq          = hfo.Data.sampFreq;
           MinIEveDur        = hfo.Data.minEventTime;
           
           env               = hfo.filtSig.Envelope(:,channel);
           filtSignal        = hfo.filtSig.filtSignal(:,channel);
           
           blThr             = hfo.baseline.baselineThr(channel);
           filtBlThr         = hfo.baseline.FiltbaselineThr(channel);


           [env, shiftEnv] = Core.EventsOfInterest.shiftEvelope(env);
   
           if isequal(RefType,'morph')
             [Event_len, Event_start, Event_end] = ...
                 Core.EventsOfInterest.findMorphologyEventInd(...
                 env, shiftEnv, blThr, filtBlThr, filtSignal, PeaksCount,...
                 maxAmplFilt, MinIEveGap, MinIEveDur );
           end
           
           if isequal(RefType,'spec') 
               [Event_len, Event_start, Event_end] = ...
                   Core.EventsOfInterest.findSpectrumEventInd(...
                   env, shiftEnv, blThr, filtSignal, PeaksCount,...
                   SampFreq, EventThrHighPARA, EventThrLowPARA);
           end
           
        end
        
        % returns processed and shifted envelope
        function [env, shift_env] = shiftEvelope(env)
            env(1)   = 0;
            env(end) = 0; 
            nbEnv    = length(env);
            
            shift_env(2:nbEnv) = env(1:end-1);
            shift_env(1)       = shift_env(2);
            
            shift_env = shift_env';
        end
               
%% Morphology 
        function [Event_len, Event_start, Event_end] = ...
                findMorphologyEventInd(env, shift_env, blThr, filtBlThr, filtSignal, minOsci,  maxAmplFilt, MinIEveGap, MinIEveDur)
   
            [~, Event_start, Event_end] = ...
               Core.EventsOfInterest.findEventInd(env, shift_env, blThr);
            
            [Event_len, Event_start, Event_end] = ...
                Core.EventsOfInterest.SmallAmpEvents(MinIEveDur, maxAmplFilt, Event_start, Event_end, env, shift_env, blThr);
            
            [Event_len, Event_start, Event_end] = ...
                Core.EventsOfInterest.checkOscillations(minOsci, Event_start, Event_end, Event_len, filtSignal, filtBlThr);
            
            [Event_len, Event_start, Event_end] = ...
                Core.EventsOfInterest.joinDetections(MinIEveGap, Event_len, Event_start, Event_end);
        end
        
        function [Event_len, Event_start, Event_end] = ...
            SmallAmpEvents(MinIEveDur, maxAmplFilt, Event_start, Event_end, env, shift_env, blThr)
        
        durThr = 0.99;

        SEnvBelow = (shift_env <  (blThr*durThr));
        EnvAbove  = (env       >= (blThr*durThr));
        EnvBelow  = (env       <= (blThr*durThr));
        SEnvAbove = (shift_env >  (blThr*durThr));
        
        Crossings1 = find( SEnvBelow & EnvAbove);    % find zero crossings rising
        Crossings2 = find( SEnvAbove & EnvBelow);    % find zero crossings falling
        
        nbEvents = numel(Event_start);
        CandidateInterval = nan(nbEvents,2);
        count = 0;
        for iEvent = 1:nbEvents
            % check for time threshold duration, all times are in pt
            EventStart = Event_start(iEvent);
            EventEnd = Event_end(iEvent);
            eventBigEnough = ((EventEnd - EventStart) >= MinIEveDur);
            
            if eventBigEnough
                StartInd = (Crossings1 <= EventStart);
                StartEnd = (Crossings2 >= EventStart);
                
                k = find(StartInd & StartEnd); % find the starting and end points of envelope
                
                [MaxAmplitude ,ArgMaxAmplitude] = max(env(Crossings1(k) : Crossings2(k)));
                if MaxAmplitude <= maxAmplFilt
                    count = count + 1 ;
                    CandidateInterval(count,:) = [Crossings1(k), Crossings2(k)];
                end
            end
            
        end
        CandidateInterval(isnan(CandidateInterval(:,1)),:) = [];
        
        Event_start = CandidateInterval(:,1);
        Event_end   = CandidateInterval(:,2);
        Event_len  = Event_end - Event_start;
        end
        
        % still morphology
        function  [Event_len, Event_start, Event_end] = ...
                checkOscillations(minOsci, Event_start, Event_end, Event_len, filtSignal, filtBlThr)
            
            nbEvents = length(Event_len);
            nDetectionCounter = 0;
            Event_startTEMP = [];
            Event_endTEMP = [];
            for iEvent = 1 : nbEvents
                SignalOfInterest = filtSignal(Event_start(iEvent) : Event_end(iEvent));
                absSignalOfInterest = abs(SignalOfInterest);
                
                zeroVec=find(SignalOfInterest(1:end-1).*SignalOfInterest(2:end) < 0); % look for zeros
                nbZeros = numel(zeroVec);
                nMaxCounter = zeros(1,nbZeros-1);
                if nbZeros > 0
                    % look for maxima with sufficient amplitude between zeros
                    for iZeroCross = 1 : nbZeros-1
                        lStart = zeroVec(iZeroCross);
                        lEnd   = zeroVec(iZeroCross+1);
                        dMax   = max(absSignalOfInterest(lStart:lEnd));
                        
                        if dMax > filtBlThr
                            nMaxCounter(iZeroCross) = 1;
                        else
                            nMaxCounter(iZeroCross) = 0;
                        end
                    end
                end
                
                nMaxCounter = [0 nMaxCounter 0]; %#ok<*AGROW>
                
                if any(diff(find(nMaxCounter == 0)) > minOsci)
                    nDetectionCounter = nDetectionCounter + 1;
                    Event_startTEMP(nDetectionCounter)    = Event_start(iEvent);
                    Event_endTEMP(nDetectionCounter)      = Event_end(iEvent);
                end
            end
            
            Event_start = Event_startTEMP;
            Event_end   = Event_endTEMP;
            Event_len   = Event_end - Event_start;
        end
        
        function [Event_len, Event_start, Event_end] = ...
                joinDetections(MinIEveGap, Event_len, Event_start, Event_end)
            
            if isempty(Event_start)
                return
            end
            
            % fill result with first detection
            TEMPEvent_start(1) =  Event_start(1);
            TEMPEvent_end(1)   =  Event_end(1);
            
            nDetectionCounter = 1;
            nOrigDetections    = length(Event_len);
            for iEvent = 2 : nOrigDetections
                % join detection
                if Event_start(iEvent) > TEMPEvent_start(nDetectionCounter)
                    
                    nDiff = Event_start(iEvent) - TEMPEvent_end(nDetectionCounter);
                    
                    if nDiff < MinIEveGap
                        
                        TEMPEvent_end(nDetectionCounter) = Event_end(iEvent);
                        
%                         if joinedDetections(nDetectionCounter).peakAmplitude < Detections(iEvent).peakAmplitude
%                             joinedDetections(nDetectionCounter).peakAmplitude = Detections(iEvent).peakAmplitude;
%                             joinedDetections(nDetectionCounter).peak=Detections(iEvent).peak;
%                         end
                        
                        
                    else
                        % initialize struct
                        nDetectionCounter = nDetectionCounter + 1;
                        TEMPEvent_start(nDetectionCounter) =  Event_start(iEvent);
                        TEMPEvent_end(nDetectionCounter) =  Event_end(iEvent);
                    end
                end
            end
            Event_start =  TEMPEvent_start;
            Event_end   = TEMPEvent_end;
            Event_len   = Event_end - Event_start;
        end
              
%% Spectrum
        function [Event_len, Event_start, Event_end] = ...
                findSpectrumEventInd(env, shift_env, blThr, filtSignal, PeaksCount, Frequency, TrigThrHighPARA, TrigThrLowPARA)
            [Event_len, Event_start, Event_end] = ...
               Core.EventsOfInterest.findEventInd(env, shift_env, blThr);
           
            [Event_len, Event_start, Event_end] = ...
                Core.EventsOfInterest.trimLongShortEvents(Frequency, TrigThrHighPARA, TrigThrLowPARA, Event_len, Event_start, Event_end);
            
            [Event_len, Event_start, Event_end] = ...
                Core.EventsOfInterest.checkPeakCount(filtSignal, PeaksCount, blThr, Event_len, Event_start, Event_end);
        end

        % returns events selected on length criteria
        function [Event_len, Event_start, Event_end] = ...
                trimLongShortEvents(Frequency, TrigThrHighPARA, TrigThrLowPARA, Event_len, Event_start, Event_end)
            
            isFreqSAbvThr = Event_len < TrigThrHighPARA*Frequency;
            isFreqSBelThr = Event_len > TrigThrLowPARA*Frequency;
            
            indDelAbv = find(isFreqSAbvThr);
            indDelBel = find(isFreqSBelThr);
            indDelete = [ indDelAbv; indDelBel];
            
            Event_len(indDelete) = [];
            Event_start(indDelete) = [];
            Event_end(indDelete) = [];
        end
        
        % return events selected on a peak count criteria
        function [Event_len, Event_start, Event_end] = ...
                checkPeakCount(signalfilt, PeaksCount, blThr, Event_len, Event_start, Event_end) 
            
            nbEven = length(Event_len);
            indDelete = nan(1, nbEven);
            
            for iEvent = 1:nbEven
                IntervalOI = Event_start(iEvent):Event_end(iEvent);
                signalfiltOI = signalfilt(IntervalOI);
                
                signalfiltOIThr = signalfiltOI-blThr;
                maskPut2Zero = (signalfiltOIThr <= 0);
                
                signalfiltOI(maskPut2Zero) = 0;
                [peaks, ~] = findpeaks(signalfiltOI);
                
                isTooFewPeaks = length(peaks) < PeaksCount;
                if isTooFewPeaks
                    indDelete(iEvent) = iEvent;
                end   
            end
            
            isNotNanInd = ~isnan(indDelete);
            indDelete = indDelete(isNotNanInd);
            
            Event_len(indDelete) = [];
            Event_start(indDelete) = [];
            Event_end(indDelete) = [];
        end
        
%% Both
        % returns start and end of events
        function [Event_len, Event_start, Event_end] = findEventInd(env, shift_env, blThr)
            isSEnvLess = (shift_env <  blThr);
            isSEnvMore = ~isSEnvLess ;
            isEnvLess = (env < blThr);
            isEnvMore = ~isEnvLess;

            trig_start_condition = (isSEnvLess & isEnvMore);
            trig_end_condition   = (isSEnvMore & isEnvLess);

            Event_start = find(trig_start_condition);
            Event_end   = find(trig_end_condition);

            Event_len = Event_end - Event_start;
        end
               
%% Find Event Energy Properties
        % Returns a table containing various properties of the events
        function summaryTable = createEventTableCHAN(Hfo, signalCHAN, signalfiltCHAN, Event_startCHAN, Event_lenCHAN)
            nbEventCHAN = length(Event_startCHAN);
            summaryMatrix = nan(nbEventCHAN, 8);
            
            for iEvent = 1:nbEventCHAN
                [intOI, intEV] = ...
                    Core.EventsOfInterest.getIntermediates(Hfo, signalCHAN, Event_startCHAN, iEvent, Event_lenCHAN);
                
                EnergySummary = ...
                    Core.EventsOfInterest.getEnergySummary(Hfo, signalfiltCHAN, intOI, intEV);%, peaks, fpeaks);
               
                summaryMatrix(iEvent,:) = EnergySummary;
            end
            
            TableVarNames = {'EnergyLF', 'EnergyR', 'EnergyFR', 'Amplpp', 'PowerTrough', 'Ftrough', 'PowmaxFR', 'fmax_FR'};
            summaryTable = array2table(summaryMatrix);
            summaryTable.Properties.VariableNames = TableVarNames;
        end
                
%% Intermediates
        % returns various intermediat variable needed for calculations
        function [intOI, intEV] = ...
                getIntermediates(hfo, signal, Event_start, iEvent, Event_len)
            intRadPARA   = hfo.Para.intIORadiusPARA;
            hf_b         = hfo.Para.highFreqBound;
            lf_b         = hfo.Para.lowFreqBound;
            StocSampRate = hfo.Para.StockwellSampRate;
            sampFreq     = hfo.Data.sampFreq;
            
            [intOI, ciao_init] = Core.EventsOfInterest.getIntOI(intRadPARA, sampFreq, signal, Event_start, iEvent);
            intEV              = Core.EventsOfInterest.getIntEV(sampFreq, intRadPARA, ciao_init, Event_len, iEvent);
%             STSignal           = Core.EventsOfInterest.getAbsStockwellData(sampFreq, hf_b, lf_b, signal, StocSampRate, intOI);
%             [peaks, fpeaks]    = Core.EventsOfInterest.getPeaks(hf_b, lf_b, intEV, STSignal);
        end
        
        % returns intervals of interest
        function [intOI, ciao_init] = getIntOI(intRadPARA, sampFreq, Signal, Event_start, iEvent)
            
            lenSig   = length(Signal);
            RadiusOI = sampFreq*intRadPARA;
            
            intOIStrt = Event_start(iEvent) - RadiusOI;
            intOIEnd = RadiusOI + Event_start(iEvent);
            intOI = intOIStrt : intOIEnd;
            
            maskDelete = intOI > lenSig;
            intOI(maskDelete) = [];
            
            indBlw1 = find(intOI < 1);
            
            intOI(indBlw1) = [];
            ciao_init = length(indBlw1);
             
%             if   indBlw1
%                 intOI(indBlw1) = [];
%                 ciao_init = length(indBlw1);
%             else
%                 ciao_init = 0;
%             end
            
        end
        
        % returns in tervals of events
        function intEV = getIntEV(SampFreq, intIOPARA, ciao_init, Event_len, iEvent)
            RadiusOI      =  SampFreq*intIOPARA;
            intermediate2 =  RadiusOI - ciao_init;

            intEV = intermediate2:(intermediate2 + Event_len(iEvent));
        end
        
        % returns the absolute stockwell transform of the signal
        function STSignal = getAbsStockwellData(SampFreq, hf_b, lf_b, signal, StocSampRate, intOI)
            Signal_loc   = signal(intOI);
            [STdata, ~, ~] = Transform.StockwellTransform(Signal_loc, lf_b, hf_b, 1/SampFreq, StocSampRate);% THESE VALUES ARE HARD SET
            STSignal       = abs(STdata)';
        end
        
        % returns the peaks and indeces of the stockwell transformed data
        function [peaks , indPeaks] = getPeaks(hf_b, lf_b, intEV, STSignal)
           
           segSTSignal        = STSignal(intEV, 1:(hf_b-lf_b) );
           meanSegSTSignal    = mean(segSTSignal);
           searchInterval     = [0 ,meanSegSTSignal];
           [peaks , indPeaks] = findpeaks(searchInterval);
           indPeaks = indPeaks + 80; % THESE VALUES ARE HARD SET for some damb reason
        end
        
%%%%%%%%%%%%%%%%% Summary
        % returns a vector of quantities characterising the event.
        function EnergySummary = getEnergySummary(Hfo, SignalfiltCHAN, intOI, intEV)%, peaks, fpeaks)
%             highPass      = Hfo.Para.highPass;
%             lowPass       = Hfo.Para.lowPass;
%             lFqB          = Hfo.Para.lowFreqBound;
%             hFqB          = Hfo.Para.highFreqBound; 
            
            
            Amplpp       = Core.EventsOfInterest.getAmplpp(intOI, SignalfiltCHAN);
%             EnergyFR     = Core.EventsOfInterest.getStockwellEnergy(intEV, STSignal, 1:(lowPass-highPass)); 
            EnergyFR     = nan;
%             [fmax_FR, f_LF] = Core.EventsOfInterest.getPeakProperties(lFqB, hFqB, peaks, fpeaks);
%             [PowerTrough, Ftrough] = Core.EventsOfInterest.getStockwellPower(intEV, STSignal, f_LF:fmax_FR);
%             Ftrough      = Ftrough + f_LF;
%             PowmaxFR = peaks(end);
%             EnergyR      = Core.EventsOfInterest.getStockwellEnergy(intEV, STSignal, 80:Ftrough);
%             EnergyLF     = Core.EventsOfInterest.getStockwellEnergy(intEV, STSignal, 40:80);
            
            %% % G0d this look ugly I know. THis is only for developemental 
            PowmaxFR = -1;
            fmax_FR = 300;
            PowerTrough = 0;
            Ftrough = 0;
            EnergyR = 0;
            EnergyLF = 100;
            %%
            
            EnergySummary = [EnergyLF, EnergyR, EnergyFR, Amplpp, PowerTrough, Ftrough, PowmaxFR, fmax_FR];
        end
        
        % returns the amplitude of an event 
        function Amplpp = getAmplpp(intOI, SignalfiltCHAN)
           Amplpp= range(SignalfiltCHAN(intOI)); 
        end
        
        % returns the stockwell energy of an event 
        function Energy = getStockwellEnergy(intEvent, STSignal, FreqInter)
            segSTSignal = STSignal(intEvent, FreqInter); 
            Energy    = mean(mean(segSTSignal));
        end
        
        % returns the stockwell power of an event 
        function [Power, indMin] = getStockwellPower(intEvent, STSignal, FreqInter)
            segSTSignal      = STSignal(intEvent, FreqInter); 
            [Power, indMin]  = min(mean(segSTSignal));
        end
             
        % Don't know what this does.
        function [fPeakMax, f_LF] = getPeakProperties(lFqB, hFqB, peaks)
            % Defaults incase the whole structure below fails
            fPeakMax = 300;
            f_LF     = 100;
            %

            nbPeaks      = length(peaks);
            isThereAPeak = (nbPeaks > 1);
            %%%%%%%%%%%%%%%%%%%%%%%%%LOOK AT THIS CRAP %%%%%%%%%%%%%%%%%%%%
            if  1 %%%%%,isThereAPeak    %%%%%%%%%%%%%%%%%%% Fix this
                maskLowBnd         = fpeaks > lFqB;
                maskHghBnd         = fpeaks < hFqB;
                nbPeaksOutOfBounds = sum(maskLowBnd & maskHghBnd);
                isPeaksOutOfBounds = ( nbPeaksOutOfBounds > 1) ;
                if isPeaksOutOfBounds
                    %
                    maskPkAbvBnd  = fpeaks > lFqB;
                    indPkAbvBnd   = find(maskPkAbvBnd);   % index of peaks of interest in fpeaks
                    
                    peaksAbvBnd   = peaks(indPkAbvBnd);   % Power of peaks of interest
                    fpeaksAbvBnd  = fpeaks(indPkAbvBnd);  % freq of peaks of interest
                    
                    [~,indPeakMax]= max(peaksAbvBnd);         % Pow,ind of prominent peak
                    fPeakMax      = fpeaksAbvBnd(indPeakMax);   % freq of prominent peak
                    %
                    isPeakAbove1 = (indPeakMax > 1);
                    if isPeakAbove1
                        f_LF = fpeaksAbvBnd(indPeakMax-1);
                    else
                        if nbPeaks == nbPeaksOutOfBounds
                            f_LF = lFqB;
                        else
                            f_LF = fpeaks(nbPeaks-nbPeaksOutOfBounds);
                        end
                    end
                else
                    f_LF     = fpeaks(end-1);
                end
            end
        end
           
%% Refine Event table
        % returns a refined version of the Events table based on pre-sets.
        function maskSpectrumEventSelect = ...
                SpectrumCondSelectCHAN(sampFreq, lFqBnd, AmplBnd, minEvT, EventTableCHAN, Event_lenCHAN)          
            
            EventLen     = Event_lenCHAN;
            %EnergyLF     = EventTableCHAN.('EnergyLF');
            Amplpp       = EventTableCHAN.('Amplpp');
            fmax_FR      = EventTableCHAN.('fmax_FR');
            PowerTrough  = EventTableCHAN.('PowerTrough');
            
            % masks
            maskShortEvents        = (EventLen < minEvT);
            %maskLowEnergyLF        = (EnergyLF > 0.040*sampFreq);
            maskAmplTooHigh        = (Amplpp > AmplBnd);
            maskPowerTroughDefault = (PowerTrough ==  -1);
            maskLowBound           = (fmax_FR < lFqBnd );
                        
            
            maskCombined    = maskShortEvents + maskPowerTroughDefault +...
                 maskAmplTooHigh + maskLowBound;
            maskCombined    = logical(maskCombined);
            
            maskSpectrumEventSelect = ~maskCombined;
            
        end
        
        function maskMorphEventSelect = ...
                MorphCondSelectCHAN(hfo, Event_startCHAN, Event_endCHAN)
                        PCntThr  = hfo.Para.PeaksCount;
                        PAmplThr = hfo.Para.MinPeakAmpl;
                        FiltSignal = hfo.filtSig.filtSignal;
            
                        EventNumber = length(Event_startCHAN);
                        [maskTooFewOsc, maskTooLowAmpl] = ...
                            Core.EventsOfInterest.checkPeakCHAN(PCntThr, PAmplThr, FiltSignal, EventNumber, Event_startCHAN, Event_endCHAN);
                        
            maskMorphEventSelect = ~logical(maskTooFewOsc + maskTooLowAmpl); 
        end
        
        % returns a mask of all events that do not have a pre-set number of
        % oscillations above a a pre-set threshold
        function [maskTooFewOsc, maskTooLowAmpl] = checkPeakCHAN(PCntThr, PAmplThr, FiltSignal, EventNumber, Event_start, Event_end)
            
            nbEvents = EventNumber;
            maskTooFewOsc = zeros(nbEvents,1);
            maskTooLowAmpl = zeros(nbEvents,1);
            
            for iEvent = 1:nbEvents
                Event_interval = Event_start(iEvent) : Event_end(iEvent);
                SignalSeg = FiltSignal(Event_interval);
                [PeakVals, IndPeaks] = findpeaks(SignalSeg);
                
                maskTooFewOsc(iEvent) = ~(length(IndPeaks) >= PCntThr);
                maskTooLowAmpl(iEvent) = ~(min(PeakVals) > PAmplThr);
            end
            
            
    end

%% Validate Multi-channel Events
        % looks across all channels to see if events occur across multiple
        % channels and removes them because of it.
        function maskMultchan = MultChanSelectCHAN(maxcorr, MaxInterElectNeig, multChanEvnRad, Datasetup, Signalfilt, iChan, EventStr, EventLen, nbEvents)
            stageIIIresp = zeros(1,nbEvents);
            for iEvent = 1:nbEvents
                TEMPch   = iChan;
                start    = EventStr(iEvent);
                TEMPdur  = EventLen(iEvent);
                
                interval = Core.EventsOfInterest.setInterval(multChanEvnRad, Signalfilt, start, TEMPdur);
                InterChanCorr = Core.EventsOfInterest.getCorrelation(Signalfilt, interval, Datasetup, TEMPch);
                LimCorr  = Core.EventsOfInterest.getLimCorr(InterChanCorr, maxcorr, Datasetup, MaxInterElectNeig, TEMPch);
                
                isRcolAbvLimCorr = length(find(abs(InterChanCorr) > LimCorr));
                if  isRcolAbvLimCorr
                    stageIIIresp(iEvent) = 1;
                end
                
            end
            maskMultchan = ~logical(stageIIIresp) ;

        end

        function interval = setInterval(multChanEvnRad, Signalfilt, start, TEMPdur)
            lenSigFilt = length(Signalfilt);
            
            interval = (start  - multChanEvnRad ) : (start + TEMPdur + multChanEvnRad);
            
            maskLessThan1     = (interval<1);
            maskLongerThanSig = (interval > lenSigFilt);
            
            interval(maskLessThan1) = [];
            interval(maskLongerThanSig) = [];
        end

        function Rcol = getCorrelation(Signalfilt, interval, Datasetup, TEMPch)
            corr_flag = 1; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% THIS IS NOT OK%%%%%%%%%%%%%%%%%%%%
            if corr_flag
                [R,~] = corrcoef(Signalfilt(interval,:));
                Rcol  = R(TEMPch, Datasetup(TEMPch).Dist_ord);
                %pcol = p(TEMPch, obj.Datasetup(TEMPch).Dist_ord);
            else
                %R = cov(SignalFilt(interval,:));
                %Rcol = R(TEMPch,obj.Datasetup(TEMPch).Dist_ord)/max(R(TEMPch,obj.Datasetup(TEMPch).Dist_ord));
            end
        end
        
        function upBoundCorr = getLimCorr(InterChanCorr, maxcorr, Datasetup, MaxInterElectNeig, TEMPch)
            lenRcol = length(InterChanCorr);
            
            upBoundCorr = ones(1,lenRcol)*maxcorr;
            
            maskMindist = Datasetup(TEMPch).Dist_val <= MaxInterElectNeig;
            upBoundCorr(maskMindist) = 1;
        end
    end
end
