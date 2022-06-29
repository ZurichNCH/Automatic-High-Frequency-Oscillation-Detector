classdef EventsOfInterestProperties
   properties
    hfo 
    hfoType
    thresholds
    
    EventData
    SuroundingData
    SNRProperties
    EventEnergyTable
    Summary
   end
   
   methods
       function obj = loadHFOoject(obj,SecRad,SNRthres,absAmplthres,relAmplthres)
           % load the HFO object as input and classifies it by frequency
           Hfo = obj.hfo;
           nbChan = Hfo.Data.nbChannels;
           if Hfo.Para.highPass == 80
               hfoT = 'ripple';
           elseif Hfo.Para.highPass == 250
               hfoT = 'fastripple';
           else
               hfoT = 'unknown';
           end
           obj.hfoType  = hfoT;
           obj.thresholds.secRadius = SecRad;

           
           SNRthresholdCell      = cell(1, nbChan);
           [SNRthresholdCell{:}] = deal(SNRthres);
           obj.thresholds.SNR    = SNRthresholdCell;
           
           absAmplthresholdCell      = cell(1, nbChan);
           [absAmplthresholdCell{:}] = deal(absAmplthres);
           obj.thresholds.absAmpl    = absAmplthresholdCell;
           
           obj.thresholds.relAmpl = relAmplthres;
       end
       
       function obj = getEventsOfInterestProperties(obj)
           % the main work horse of the script
           markingsCell = obj.hfo.Events.Markings;
           sampFreq     = obj.hfo.Data.sampFreq;
           secRad       = obj.thresholds.secRadius;
           SNRthres     = obj.thresholds.SNR;
           absAmplthres = obj.thresholds.absAmpl;
           relAmplthres = obj.thresholds.relAmpl;
           
           Hfo          = obj.hfo;
           dataMat      = Hfo.filtSig.filtSignal;
           dataEnvMat   = Hfo.filtSig.Envelope;
          
           
           startCell = markingsCell.start;
           endCell   = markingsCell.end;
           [event, surounding, EvProp] = Core.EventsOfInterestProperties.getEOIProp(startCell, endCell, dataMat, dataEnvMat, sampFreq,  secRad);
           
           % SNR mask
           maskSNRpass         = cellfun(@ge, EvProp.SNR, SNRthres, 'UniformOutput', false);
           EvProp.mask.SNRpass = maskSNRpass; % must exceed SNR threshold
           
           % Max. Abs. Ampliture mask
           maskAbsAmplpass         = cellfun(@le, EvProp.EventMaxAbsAmpl, absAmplthres, 'UniformOutput', false);
           EvProp.mask.AbsAmplpass = maskAbsAmplpass;
           
           % Max. Rel. Ampliture mask
           multSurAmpl     = cellfun(@(x) x*relAmplthres, EvProp.SurMaxAbsAmpl, 'UniformOutput', false);
           maskRelAmplpass = cellfun(@le, EvProp.EventMaxAbsAmpl, multSurAmpl, 'UniformOutput', false);
           EvProp.mask.RelAmplpass = maskRelAmplpass;
           
           % load the results into the class:
           obj.EventData            = event;
           obj.SuroundingData       = surounding;
           obj.SNRProperties        = EvProp;
       end
       
       function obj = getEOISummary(obj)
           hfoEventSur  = obj.SuroundingData ;
           EventProp    = obj.SNRProperties;
           
           nbChan = length(hfoEventSur.indeces);
           hfoEventSur.lengths = cell(nbChan, 1);
           for iChan = 1:nbChan
               suroundingLengths = cellfun(@length, hfoEventSur.indeces{iChan});
               hfoEventSur.lengths{iChan} = suroundingLengths;
           end

           % SNR
           obj.Summary.SNR.medianByChan        = cellfun(@median, EventProp.SNR);
           obj.Summary.SNR.passCount       = cellfun(@sum,  EventProp.mask.SNRpass);
           
           % Amplitude
           obj.Summary.MaxAbsAmpl.event.medianByChan   = cellfun(@median, EventProp.EventMaxAbsAmpl);
           obj.Summary.MaxAbsAmpl.Sur.medianByChan     = cellfun(@median, EventProp.SurMaxAbsAmpl);
           obj.Summary.MaxAbsAmpl.passCount            = cellfun(@sum, EventProp.mask.AbsAmplpass);
       end
       
       function obj = creatEventPropTable(obj)
           %Input: Event markings and signal
           %OutPut: Tabel containg the properties of the events
           Hfo         = obj.hfo;
           Event_start = Hfo.Events.Markings.start;
           Event_len   = Hfo.Events.Markings.len;
           
           
           signal      = Hfo.Data.signal;
           signalfilt  = Hfo.filtSig.filtSignal;
           
           nbChan      = Hfo.Data.nbChannels;
           obj.EventEnergyTable = cell(1,nbChan);
           for iChan = 1:nbChan
               disp(['Finding events energy table for channel ',num2str(iChan),' of ',num2str(nbChan)])
               signalCHAN      = signal(:,iChan);
               signalFiltCHAN  = signalfilt(:,iChan);
               Event_startCHAN = Event_start{iChan};
               Event_lenCHAN   = Event_len{iChan};
               
               summaryTable = ...
                   Core.EventsOfInterest.createEventTableCHAN(Hfo, signalCHAN, signalFiltCHAN, Event_startCHAN, Event_lenCHAN);
               
               obj.EventEnergyTable{iChan} = summaryTable;
           end
       end
    
       
   end
   
   methods(Static)
       %% extracting event information
       function [event, surounding, EventProps] = getEOIProp(startCell, endCell, dataMat, dataEnvMat, sampFreq, secRadius) 
           nbChan = size(startCell,2);
           nbSamp = size(dataMat,1);
           %% preset the size
           event.indeces       = cell(1,nbChan);
           event.data          = cell(1,nbChan);
           event.envData       = cell(1,nbChan);
           
           surounding.indeces  = cell(1,nbChan);
           surounding.data     = cell(1,nbChan);
           surounding.envData  = cell(1,nbChan);
           
           EventProps.SNR              = cell(1,nbChan);
           EventProps.EventMaxAbsAmpl  = cell(1,nbChan);
           EventProps.SurMaxAbsAmpl    = cell(1,nbChan);
           %%
           for iChan = 1:nbChan % iterate over channels.
               nbEvents = length(startCell{iChan});
               %% preset the size
               event.indeces {iChan}              = cell(1,nbEvents);
               event.data{iChan}                  = cell(1,nbEvents);
               event.envData{iChan}               = cell(1,nbEvents);
               
               surounding.indeces {iChan}         = cell(1,nbEvents);
               surounding.data{iChan}             = cell(1,nbEvents);
               surounding.envData{iChan}          = cell(1,nbEvents);
               % Event 
               EventProps.EventP2P{iChan}         = zeros(1,nbEvents);
               EventProps.EventMaxAbsAmpl{iChan}  = zeros(1,nbEvents);
               EventProps.EventRMS{iChan}         = zeros(1,nbEvents);
               % Surroundings
               EventProps.SurP2P{iChan}           = zeros(1,nbEvents);
               EventProps.SurMaxAbsAmpl{iChan}    = zeros(1,nbEvents);
               EventProps.SurRMS{iChan}           = zeros(1,nbEvents);
               % SNR
               EventProps.SNR{iChan}              = zeros(1,nbEvents);
               %%
               for iEvent = 1:nbEvents % iterate over events.
                   try
                   % Event
                   TempSampIndecesEvent           = startCell{iChan}(iEvent):endCell{iChan}(iEvent);
                   eventData                      = dataMat(TempSampIndecesEvent, iChan);
                   eventEnvData                   = dataEnvMat(TempSampIndecesEvent, iChan);
                   
                   event.indeces{iChan}{iEvent}   = TempSampIndecesEvent;
                   event.data{iChan}{iEvent}      = eventData;
                   event.envData{iChan}{iEvent}   = eventEnvData;

                   % Suroundings
                   Radi = sampFreq*secRadius/2;
                   SuroundingsIndeces = ...
                      Core.EventsOfInterestProperties.getEventSurrounding(endCell,startCell,iChan,iEvent,nbSamp,Radi,true);
                   SuroundingsIndecesWithOtherHFO = ...
                      Core.EventsOfInterestProperties.getEventSurrounding(endCell,startCell,iChan,iEvent,nbSamp,Radi,false);

                   SuroundingData                = dataMat(SuroundingsIndeces, iChan);
                   SuroundingEnvData             = dataEnvMat(SuroundingsIndeces, iChan);
                   SuroundingDataWithOtherHFO    = dataMat(SuroundingsIndecesWithOtherHFO, iChan);

                   surounding.indeces{iChan}{iEvent} = SuroundingsIndeces;
                   surounding.data{iChan}{iEvent}    = SuroundingData;  
                   surounding.envData{iChan}{iEvent} = SuroundingEnvData;
                   
                   %% Porperties
                   %Event
                   EventProps.EventP2P{iChan}(iEvent)           = peak2peak(eventData);
                   EventProps.EventMaxAbsAmpl{iChan}(iEvent)    = max(abs(eventData));
                   EventProps.EventRMS{iChan}(iEvent)           = rms(eventData);
                   
                   %Surrounding
                   EventProps.SurP2P{iChan}(iEvent)           = peak2peak(SuroundingDataWithOtherHFO);
                   EventProps.SurMaxAbsAmpl{iChan}(iEvent)    = max(abs(SuroundingDataWithOtherHFO));
                   EventProps.SurRMS{iChan}(iEvent)           = rms(SuroundingDataWithOtherHFO); % the way that matches ECE

                   %OverAll 
                   EventProps.SNR{iChan}(iEvent)                =(rms(eventData)/rms(SuroundingData))^2;
                   catch
                       continue
                   end
               end
           end
       end
       
       % utility level 1
       function SuroundingsIndeces = getEventSurrounding(endCell,startCell,iChan,iEvent,nbSamp,Radi,isClean)
           % This function takes as input a markings cell from the HFO class
           % It then give as output a markings cell containg the markings of 1/2
           % radius in seconds around each event.
           eventStr     = startCell{iChan}(iEvent);
           eventEnd     = endCell{iChan}(iEvent);
           [preEventEnd, postEventStr] = ...
               Core.EventsOfInterestProperties.getFirstAndLastEventCase(eventStr, eventEnd, nbSamp, Radi);

           maxBefor = preEventEnd;
           minAfter = postEventStr;
           SuroundingsIndeces = [maxBefor:(eventStr-1), (1+eventEnd):minAfter];
           if isClean
           surEventMask = Core.EventsOfInterestProperties.getSuroundingEventsMask(endCell,startCell,iChan,SuroundingsIndeces);
           SuroundingsIndeces(surEventMask) = []; 
           end
       end
       
           % utility level 2
           function [preEventEnd, postEventStr] = getFirstAndLastEventCase(eventStr, eventEnd, nbSamp, Radi)
           % this funciton handels the special cases when the event in question
           % is the first or the last of its channel
               if  1 > (eventStr - Radi)
                   preEventEnd  = 1;
               else
                   preEventEnd  = eventStr - Radi;
               end

               if nbSamp < (eventEnd + Radi)
                   postEventStr = nbSamp;
               else
                   postEventStr = eventEnd + Radi;
               end
           end

           function surEventMask = getSuroundingEventsMask(endCell,startCell,iChan,SuroundingsIndeces)
               eventStr      = startCell{iChan};
               eventEnd      = endCell{iChan};
               startsInSur   = ismember(eventStr,SuroundingsIndeces);
               endInSur      = ismember(eventEnd,SuroundingsIndeces);
               EitherInSur   = startsInSur | endInSur;
               otherEventStr = startCell{iChan}( EitherInSur);
               otherEventEnd = endCell{iChan}( EitherInSur);

               otherEventIndeces = [];
               for iOtherEvents = 1:sum(EitherInSur)
                 otherEventIndeces = [otherEventIndeces, otherEventStr(iOtherEvents): otherEventEnd(iOtherEvents)]; 
               end
               surEventMask = ismember(SuroundingsIndeces,otherEventIndeces);
           end


   end
end
   
