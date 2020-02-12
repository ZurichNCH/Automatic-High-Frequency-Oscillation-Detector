classdef HFO
   properties
%% Meta 
      ParaFileLocation = 'No set path'; 
      DataFileLocation = 'No set path'; 
%% STAGE O.1 Parameters
      Para           
%% STAGE O.2 Data
      Data             
%% STAGE I
      filtSig  
%% STAGE II
      baseline          
%% STAGE III
      Events 
%% STAGE IV
      Refinement
%% STAGE VI
      RefinedEvents
%% STAGE V      
      MultChanCoOccurence
 %% STAGE ??      
      EventPropTable
      
      Rates
      Thresholds
   end
   methods
       %% STAGE O: Loading
       function obj = getParaAndData(obj, strChanContains)%, data)
           if nargin < 2
               strChanContains = {''};
           end
           
           pad = Core.ParaAndData;
           assert(~isequal(obj.ParaFileLocation, 'No set path'),'Parameter file path invalid.');
           pad.ParaFileLocation = obj.ParaFileLocation;
           
           
           assert(~isequal(obj.DataFileLocation, 'No set path'),'Data file path invalid.');
           pad.DataFileLocation = obj.DataFileLocation;
           
           % loading
           pad = pad.loadParameters;
           pad = pad.loadData(strChanContains);
           
           testParameters(pad);
           
           obj.Para = pad.Para;
           obj.Data = pad.Data;
       end
       
       %% STAGE I: Filtering
       function obj = getFilteredSignal(obj, smoothBool)
           filtsig = Core.FilterSignal;
           filtsig.hfo = obj;
           
           filtsig = filterSignal(filtsig);
           filtsig = getSignalEnvelope(filtsig, smoothBool);
           
           obj.filtSig = filtsig.Output;
       end
       
       %% STAGE II: Baselining
       function obj = getBaseline(obj, timeIntervalSec)

           bl = Core.Baseline;
           bl.hfo = obj;
           
           bl = setBaselineMaxNoisemuV(bl);
           if nargin == 1
               bl = getBaselineEntropy(bl);
           else
               bl = getBaselineEntropy(bl, timeIntervalSec);
           end
           
           obj.baseline = bl.Output;
       end
       
       %% STAGE III: Event finding
       function obj = getEvents(obj, RefType)
           assert(any(contains({'morph','spec','specECoG','specScalp'},RefType)) ,[RefType,' is an invalid detector choice.'])
           
           eoi = Core.EventsOfInterest;
           eoi.hfo = obj;
           if isequal(RefType,'morph')
               eoi = findEvents(eoi, RefType);
               eoi = creatEventPropTable(eoi);
           elseif isequal(RefType,'spec') ||  isequal(RefType,'specECoG') ||  isequal(RefType,'specScalp')
               eoi = findEvents(eoi, RefType);
               eoi = creatEventPropTable(eoi);
           end
           obj.Events  = eoi.Output;
       end
       
       %% STAGE III.I: Event Refining
       function obj = getRefinements(obj,RefType)
           eoi = Core.EventsOfInterest;
           eoi.hfo = obj;
           eoi.Output = obj.Events;
           if isequal(RefType,'morph')
               obj.Refinement.maskEventCondSelect = condRefineEvents(eoi, RefType);
           elseif  contains(RefType,'spec') 
               obj.Refinement.maskEventCondSelect = condRefineEvents(eoi, RefType);
           end
           obj.Refinement.maskMultChanRefine = eoi.multChanRefineEvents;
           obj.Refinement.maskSNR            = eoi.Output.Properties.SNRProperties.mask.SNRpass;
           obj.Refinement.AbsAmplpass        = eoi.Output.Properties.SNRProperties.mask.AbsAmplpass;
           obj.Refinement.RelAmplpass        = eoi.Output.Properties.SNRProperties.mask.RelAmplpass;
       end
       
       %% STAGE IV: Event SNR Properties
       function obj = getEventProperties(obj)
           SNRsurSec    = obj.Para.SNRsurSec;
           SNRthres     = obj.Para.SNRthres;
           absAmplthres = obj.Para.absAmplthres;
           relAmplthres = obj.Para.relAmplthres;
           
           eventProp = Core.eventProperties;
           
           warning ('off','all');
           hFo = struct(obj);
           warning ('on','all');
           
           eventProp.hfo = hFo;
           eventProp = eventProp.loadHFOoject(SNRsurSec, SNRthres, absAmplthres, relAmplthres);
           eventProp = eventProp.getEventProperties;
           eventProp = eventProp.getSummary;
           
           warning ('off','all');
           eventPropStruct     = struct(eventProp);
           warning ('on','all');
           obj.Events.Properties = rmfield(eventPropStruct,'hfo');
       end
       
       %% STAGE VI: Refine events
       function obj = RefineEvents(obj, fieldEvents, Iteration, varargin)
           if length(varargin) <= 1 
             combinedMask = varargin{1}; 
           else
             combinedMask = Core.HFO.combineMask(varargin); 
           end
           durationMin = obj.Data.sigDurTime/60;
           EventsTemp  = fieldEvents;
           eventdata   = EventsTemp.Properties.EventData;
           surdata     = EventsTemp.Properties.SuroundingData;
           
           RefEvents = [];
           if isfield(obj.RefinedEvents, 'combinedMask')
               RefEvents.combinedMask = [obj.RefinedEvents.combinedMask,{combinedMask}];
           else
               RefEvents.combinedMask = {combinedMask};
           end 
           markings   = EventsTemp.Markings;
           propTables = EventsTemp.EventProp;
           
           % Refine the markings
           RefEvents.Markings.start = cellfun(@ Core.HFO.getMySlice,markings.start,combinedMask,'UniformOutput', false);
           RefEvents.Markings.end   = cellfun(@ Core.HFO.getMySlice,markings.end,combinedMask,'UniformOutput', false);
           RefEvents.Markings.len   = cellfun(@ Core.HFO.getMySlice,markings.len,combinedMask,'UniformOutput', false);
           
           % Refine the EventProp
           RefEvents.EventProp      = cellfun(@ Core.HFO.getMySlash, propTables,combinedMask,'UniformOutput', false);
           
           % Refine the Properties
           RefEvents.Properties.thresholds     = obj.Events.Properties.thresholds;
           RefEvents.Properties.EventData      = Core.HFO.selectStruct(eventdata, combinedMask);
           RefEvents.Properties.SuroundingData = Core.HFO.selectStruct(surdata , combinedMask);
           
           % SNR properties
           snrprop        = EventsTemp.Properties.SNRProperties;
           selectedStruct = Core.HFO.selectStruct(snrprop, combinedMask);
           RefEvents.Properties.SNRProperties = selectedStruct;
               
           
           % EventNumber
           TempNumber = cellfun(@sum,combinedMask);
           RefEvents.EventNumber = TempNumber; 
           % Rates 
           RefEvents.Rates  = TempNumber/durationMin;
           %%
           obj.RefinedEvents{Iteration} = RefEvents;
       end
       
       %% STAGE V: Get CoOccurence
       function obj = getMultChanCoOccurence(obj,LetSlipMask)
           obj.MultChanCoOccurence = Core.CoOccurence.getMultChanCoOccurece(obj,LetSlipMask);
       end
       
       %% STAGE X: Event visuallization
       %Tables
       function obj = getEventPropTable(obj)
           if nargin < 2
               EventsOfChoice   = obj.Events;
           end
           chanNames       = obj.Data.channelNames;

           EventMarkings   = EventsOfChoice.Markings;
           EventEnergyProp = EventsOfChoice.EventProp;
           EventProp       = EventsOfChoice.Properties.SNRProperties;
           
           nbChan          = length(EventProp.SNR);
           eChanPropTable  = cell(nbChan, 1);
           
           maskEventCondSelect = obj.Refinement.maskEventCondSelect ;
           maskMultChanRefine  = obj.Refinement.maskMultChanRefine;
           maskSNR             = obj.Refinement.maskSNR; 
           maskMultiChanCoOcc  = obj.MultChanCoOccurence.Mask;
           maskAbsAmplpass     = obj.Refinement.AbsAmplpass;
%            RelAmplpass         = obj.Refinement.RelAmplpass;
%            combinedMask        = Core.HFO.combineMask({maskEventCondSelect, maskMultChanRefine, maskSNR, maskAbsAmplpass});
           

            for iChan = 1:nbChan
                chanName = chanNames{iChan};
                eChanPropTable{iChan} = Core.HFO.getEventChanPropTable(EventMarkings, EventProp, EventEnergyProp, chanName, iChan,...
                    maskEventCondSelect, maskMultChanRefine, maskSNR, maskMultiChanCoOcc, maskAbsAmplpass);
            end
           obj.EventPropTable = vertcat(eChanPropTable{:});
       end
       
       %%
       function [] = displayCoOccuringHFO(obj, EventsOfChoice,iBlock)
           fs = obj.Data.sampFreq;
           ChannelNames = obj.Data.channelNames;
           EventProps   = EventsOfChoice.Properties;
           blocks       = obj.MultChanCoOccurence.MultChan.Block;
           nbEventsinBLocks = cellfun(@ length,blocks);
           %         iBlock = find(nbEventsinBLocks == max(nbEventsinBLocks));
           %         iBlock = iBlock(1);
           if nargin < 3
               iBlock = randi([1 length(nbEventsinBLocks)],1,1);
           end
           
           figure('units','normalized','outerposition',[0 0 1 1]);
           hold on
           nbEventInBlock = size(blocks{iBlock},2);
           for iFig = 1:nbEventInBlock
               iChan       = blocks{iBlock}(1,iFig);
               iEvent      = blocks{iBlock}(2,iFig);
               
               if iFig == 1
                   fChan       = iChan;
                   fEvent      = iEvent;
                   eventInfo      = Core.HFO.loadEventInfo(EventProps.EventData,fs,fChan,fEvent);
                   EdgesOfEvent = eventInfo.IndecesSec([1,end]);
               end
               
               ChannelName = ChannelNames{iChan};
               subplot(ceil(nbEventInBlock/2),2,iFig)
               obj.displaySpecificHFO(EventsOfChoice,ChannelName, iEvent);
               xlim([EdgesOfEvent(1)-1/2 ,EdgesOfEvent(end)+1/2])
           end
           hold off
           
       end
         
   end
   methods(Static) 
       % selecting events based on SNR
       function combinedMask = combineMask(cellOFMasks)
           nbChan = length(cellOFMasks{1});
           nbMask = length(cellOFMasks);
           combinedMask = cell(1,nbChan);
           for iChan = 1:nbChan
               combinedMask{iChan} = cellOFMasks{1}{iChan}; 
               for iMask = 2:nbMask
                    combinedMask{iChan} = combinedMask{iChan} & cellOFMasks{iMask}{iChan};
               end
           end
       end
       
       function selectedStruct =  selectStruct(oldStruct, mask)
           try
               oldStruct = rmfield(oldStruct,'mask');
           catch
               
           end
           fieldsSNRprop = fields(oldStruct);
           nbFields      = length(fieldsSNRprop);
           S = struct();
           for iField = 1:nbFields
               try
               FieldName = fieldsSNRprop{iField};
               valanara = oldStruct.(FieldName);
               valanaraNew = cellfun(@ Core.HFO.getMySlice,valanara,mask,'UniformOutput', false);
               S.(FieldName) = valanaraNew;
               catch
                   continue
               end
           end
           selectedStruct = S;
       end
       
       function myslice = getMySlice(Vecy, index)
           try
           myslice = Vecy(logical(index));
           catch
           myslice = Vecy;    
           end
       end

       function myslash = getMySlash(Tably, index)
           myslash = Tably(logical(index),:);
       end
       %% Visualizations
       %table
       function  eventChanPropTable = getEventChanPropTable(EventMarkings, EventProp, EventEnergyProp,...
                                                            chanName,chan, maskEventCondSelect, maskMultChanRefine,...
                                                            maskSNR, maskMultiChanCoOcc, maskAbsAmplpass)
          nbEvents = length(EventMarkings.start{chan}); 
          
          Chan     = repmat(chan,nbEvents,1); 
          [ChanName{1:nbEvents}] = deal(chanName);
          ChanName = ChanName';
          
          starts   =  EventMarkings.start{chan};
          ends     =  EventMarkings.end{chan};
          len      =  EventMarkings.len{chan};
          if size(ends,2) > 1
              starts   =  starts';
              ends     =  ends';
              len      =  len';
          end
         
          % events
          eventRMS           = EventProp.EventRMS{chan}';
          EventP2P           = EventProp.EventP2P{chan}';
          eventMaxAbsAmpl    = EventProp.EventMaxAbsAmpl{chan}';
          
          % surrounding
          surRMS             = EventProp.SurRMS{chan}';
          surMaxAbsAmpl      = EventProp.SurMaxAbsAmpl{chan}';
          
          % over all
          snr                = EventProp.SNR{chan}';
          
          % masks
          maskEventCondSelectCHAN =  maskEventCondSelect{chan}';
          maskMultChanCorrCHAN    =  maskMultChanRefine{chan}';
          maskSNRCHAN             =  maskSNR{chan}';
          ECEmaskSNRCHAN          =  maskSNRCHAN;
          ECEmaskSNRCHAN(maskSNRCHAN == 1) = 0; 
          ECEmaskSNRCHAN(maskSNRCHAN == 0) = 1; 
          
          maskAbsAmplpassCHAN     =  maskAbsAmplpass{chan}';
          ECEmaskAbsAmplpassCHAN   = maskAbsAmplpassCHAN; 
          ECEmaskAbsAmplpassCHAN(maskAbsAmplpassCHAN == 1) = 0;
          ECEmaskAbsAmplpassCHAN(maskAbsAmplpassCHAN == 0) = 1;
          
          
          maskMultiChanCoOccCHAN  =  maskMultiChanCoOcc{chan}';
          ECEmaskMultiChanCoOccCHAN  = maskMultiChanCoOccCHAN;
          ECEmaskMultiChanCoOccCHAN(maskMultiChanCoOccCHAN == 1) = 0;
          ECEmaskMultiChanCoOccCHAN(maskMultiChanCoOccCHAN == 0) = 1;
          
         if isempty(Chan) 
            eventChanPropTable = []; 
            return
         end
         eventChanPropTableTemp = table(Chan, ChanName, starts, ends, len, eventRMS, surRMS, EventP2P, snr,  eventMaxAbsAmpl, surMaxAbsAmpl, maskEventCondSelectCHAN, maskMultChanCorrCHAN, ECEmaskSNRCHAN, ECEmaskMultiChanCoOccCHAN, ECEmaskAbsAmplpassCHAN);
         eventChanPropTableTemp.Properties.VariableNames = {'nChannel'  'strChannelName'  'indStart'  'indStop'  'indDuration'  'Event_RMS' 'Window_RMS' 'EventPeak2Peak' 'SNR'  'event_MaxAbsAmpl'   'baseline_MaxAbsAmpl' ,'pass_Event_Cond', 'pass_Mult_Chan_Corr', 'nLowSNR', 'nBilateral', 'nHighAmplitude' }; 
         eventChanPropTable = [eventChanPropTableTemp, EventEnergyProp{chan}];
         eventChanPropTable = eventChanPropTable(:,[1:12,17:24,13:16]);
       end
            
       %% figures
       function []             = barPlotWithChans(DataThing,chanNames,FieldName,HFOArea,Units)
           if iscell(DataThing)
               Data = cellfun(@ nanmedian,DataThing);
           else
               Data  = DataThing;
           end
           nbChannels = length(chanNames);
           bar(Data, 1,  'red');
           xtikkis = 1:nbChannels;
           set(gca,'xtick',[])
           ax = copyobj(gca,gcf);
           ax(1,1).XTickLabelRotation = 90;
           set(ax(1,1),'xtick',xtikkis(~HFOArea), 'xticklabel', chanNames(~HFOArea), 'yticklabel', [],'fontsize', 4)
           ax2  = copyobj(gca,gcf);
           set(ax2(1,1),'ytick',[],'xtick',xtikkis(HFOArea), 'XColor', 'red','xticklabel', chanNames(HFOArea), 'fontsize', 4)
           ax2(1,1).XTickLabelRotation = 90;
           
           ylabel(Units)
           title([FieldName, ' median by channel'],'fontsize', 12)
       end
         
       function SNRbyChan      = showSNRbyChan(meanSNR, meanEnvSNR, chanNames, titleStr)
           SNRbyChan = figure('units','normalized','outerposition',[0 0 1 1]);
           b1 = bar([meanSNR',meanEnvSNR']);
           
           %            ylim([0 5])
           xticks(1:length(chanNames))
           xticklabels(chanNames)
           set(gca, 'XTickLabelRotation', 90);
           
           legend([b1(1) b1(2)], 'Filtered Data','Envelope of Filtered Data')
           xlabel('Channels')
           ylabel('SNR')
           title(['Mean hfo-SNR per channel: ',titleStr])
       end
       
       function AmplbyChan     = showAmplitudebyChan(meanAmplitude, meanEnvAmplitude, chanNames, titleStr)
           AmplbyChan = figure('units','normalized','outerposition',[0 0 1 1]);
           b1 = bar([meanAmplitude', meanEnvAmplitude']);
           %            ylim([0 20])
           xticks(1:length(chanNames))
           xticklabels(chanNames)
           set(gca, 'XTickLabelRotation', 90);
           
           legend([b1(1) b1(2)], 'Filtered Data', 'Envelope of Filtered Data')
           xlabel('Channels')
           ylabel('Amplitude [uV]')
           title(['Mean hfo-SNR per channel: ', titleStr])
       end
        
       function eventInfo      = loadEventInfo(Events,fs,iChan,iEvent)
           eventInfo.Indeces      = Events.indeces{iChan}{iEvent};
           eventInfo.IndecesSec   = eventInfo.Indeces/fs;
           eventInfo.Data         = Events.data{iChan}{iEvent};
           eventInfo.EnvData      = Events.envData{iChan}{iEvent};
       end
       
       function suroundingInfo = loadSuroundingInfo(EventSuroundings,fs,iChan,iEvent)
           suroundingInfo.Indeces    = EventSuroundings.indeces{iChan}{iEvent};
           suroundingInfo.IndecesSec = suroundingInfo.Indeces/fs;
           suroundingInfo.Data       = EventSuroundings.data{iChan}{iEvent};
           suroundingInfo.EnvData    = EventSuroundings.envData{iChan}{iEvent};
       end
       
   end
end