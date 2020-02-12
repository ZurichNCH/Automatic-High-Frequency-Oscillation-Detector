classdef CoOccurence
   properties
       Rhfo
       FRhfo
       ContThresh
       maskCellMultiFR2R
       maskCellCoOccurence
       Events 
   end
   
   methods
       function Events = runCoOccurence(obj, Rhfo, FRhfo, ContThresh)
           CoOc = obj;
           if nargin < 4
               CoOc.ContThresh = 1;
           end
           CoOc = CoOc.loadHFO(Rhfo, FRhfo);
           CoOc = CoOc.setContainmentThreshold(ContThresh);
           
           CoOc = CoOc.getCoOccurence;
           CoOc = CoOc.getCoOccuredEvents;
           Events = CoOc.Events;
           Events.maskMultiFR2R = CoOc.maskCellMultiFR2R;
           Events.countMultiFR2R = cellfun(@sum,CoOc.maskCellMultiFR2R);
       end
       
       function obj = loadHFO(obj, Rhfo, FRhfo)
           obj.Rhfo = Rhfo;
           obj.FRhfo = FRhfo;
       end
              
       function obj = getCoOccurence(obj)
           rhfo  = obj.Rhfo;
           frhfo = obj.FRhfo;
           CoThr = obj.ContThresh;
           CoOccure = Core.CoOccurence.getRandFRCoOccurence(rhfo, frhfo, CoThr);
           
           obj.maskCellMultiFR2R = CoOccure.maskMultiFR2R;
           obj.maskCellCoOccurence = CoOccure.maskContained;
       end
       
       function obj = getCoOccuredEvents(obj)
            durSec   = (obj.FRhfo.Data.nbSamples / obj.FRhfo.Data.sampFreq);
            durMin   = durSec/60;
            frEvents = obj.FRhfo.Events;
            CoOcc    = obj.maskCellCoOccurence;
            nbChan   = length(CoOcc);
              
            for iChan = 1:nbChan
                maskCoOccChan = CoOcc{iChan};
                EventNumber            = cellfun(@sum,CoOcc);
                Markings.start{iChan}  = frEvents.Markings.start{iChan}(maskCoOccChan);
                Markings.end{iChan}    = frEvents.Markings.end{iChan}(maskCoOccChan);
                Markings.len{iChan}    = frEvents.Markings.len{iChan}(maskCoOccChan);
                
                Rates                  = EventNumber/durMin;
            end
            obj.Events.EventNumber     = EventNumber;
            obj.Events.Markings.start  = Markings.start;
            obj.Events.Markings.end    = Markings.end;
            obj.Events.Markings.len    = Markings.len;
            
            obj.Events.Rates           = Rates;
       end
   end
   
   methods(Static)
       %% Obtaining co-occuring same HFO over multiple channels
       
       function MultChanCoOcc = getMultChanCoOccurece(HFOobj,LetSlipMask)
            indeces                     = HFOobj.Events.Properties.EventData.indeces;
            nbChan                      = HFOobj.Data.nbChannels;
            chanNames                   = HFOobj.Data.channelNames;
            
            if nargin ==2
                for iChan = 1:nbChan
                indeces{iChan}(~LetSlipMask{iChan}) = {[]}; 
                end
            end

            Map                 = Core.CoOccurence.getCoOccurenceMap(indeces);
            Block = Core.CoOccurence.getCoOccurenceBlock(Map, nbChan);
            MultChanCoOcc.Block = Block;
            MultChanCoOcc.Mask  = Core.CoOccurence.getCoOccurenceMask(Block,nbChan,chanNames,indeces);
        end

       function Map = getCoOccurenceMap(indeces)
           nbChan  = length(indeces);
           CoOcMap = cell(1,nbChan);
           for iChan = 1:nbChan
               nbEvents = length(indeces{iChan});
               CoOcMap{iChan} = cell(1, nbEvents);
               for iEvent = 1:nbEvents
                   eventIndeces = indeces{iChan}{iEvent};
                   if isempty(eventIndeces)
                       continue
                   end
                   for jChan = (iChan+1):nbChan
                       eventCoOcc = find(cellfun(@(x) any(intersect(x, eventIndeces)),indeces{jChan}));
                       if ~isempty(eventCoOcc)
                           CoOcMap{iChan}{iEvent} = [CoOcMap{iChan}{iEvent}, [repmat(jChan,1,length(eventCoOcc)); eventCoOcc]];
                       end
                   end
                   
               end
           end
           Map = CoOcMap;
       end
       
       function Blocks = getCoOccurenceBlock(CoOcMap, nbChan)
%            nbChan  = obj.hfo.Data.nbChannels;
%            CoOcMap = obj.CoOcc.Map;
           iCount = 1;
           for iChan = 1:nbChan
               nbEvent = length(CoOcMap{iChan});
               for iEvent = 1:nbEvent
                   nbOtherEvents = size(CoOcMap{iChan}{iEvent},2);
                   if nbOtherEvents ~= 0
                       CoOcBlock{iCount} =[[iChan; iEvent] ,CoOcMap{iChan}{iEvent}];
                       CoOcMap{iChan}{iEvent} = [];
                   end
                   for iOtherEvents = 1:nbOtherEvents
                       rChan = CoOcBlock{iCount}(1,iOtherEvents);
                       rEvent = CoOcBlock{iCount}(2,iOtherEvents);
                       CoOcBlock{iCount} = [CoOcBlock{iCount}, CoOcMap{rChan}{rEvent}];
                       CoOcMap{rChan}{rEvent} = [];
                   end
                   if nbOtherEvents ~= 0
                       CoOcBlock{iCount} = unique(CoOcBlock{iCount}','rows','stable')';
                       iCount = iCount + 1;
                   end
               end
               if isempty([CoOcMap{:}]) || isequal([CoOcMap{:}],{[]}) || (nbEvent == 0)
                   CoOcBlock = {};
               end
           end
           Blocks = CoOcBlock;
       end
       
       function CoOccMask = getCoOccurenceMask(CoOccBlocks,nbChan,chanNames,indeces)
         
           CoOccMask = cell(1, nbChan);
           for iChan = 1:nbChan
               nbEvents = length(indeces{iChan});
               CoOccMask{iChan} = ones(1, nbEvents);
           end
           
           nbBlocks = length(CoOccBlocks);
           for iBlock = 1:nbBlocks
               block = CoOccBlocks{iBlock};
               if isempty(block)
                   continue
               end
               chanNamesOFBlock = {chanNames{block(1,:)}} ;
               isLeft     = any(contains(chanNamesOFBlock,{'1' '3' '5' '7'}));
               isRight    = any(contains(chanNamesOFBlock,{'2' '4' '6' '8'}));
               % excluded events: conra-laterality
               if (isLeft && isRight)
                   for iBlockEntries = 1:size(block,2)
                       rChan  = block(1,iBlockEntries);
                       rEvent = block(2,iBlockEntries);
                       CoOccMask{rChan}(rEvent) = 0;
                   end
               end
               
           end
       end
       
       %% Obtaining co-occuring different HFO over same channel
        
        % This is the work horse, it is an old horse
        function CoOccurenceInfo  = getECECoOccurence(Rhfo, FRhfo)
            nbChan = Rhfo.Data.nbChannels;
            CoOccurenceInfo.maskCell.Ripples             = cell(nbChan,1);
            CoOccurenceInfo.maskCell.FastRipples         = cell(nbChan,1);
            CoOccurenceInfo.maskCell.RippleANDFastRipple = cell(nbChan,1);
            merged = cell(nbChan,1);
            for iChan = 1:nbChan
                maskOfContainmentRFR = Core.CoOccurence.getIndOfContainment(Rhfo, FRhfo, iChan); %Ind (mark = 3)
                % ~maskOfContainmentRFR % is (mark = 1)        %         (mark1 | mark3)  (OLD RIPPLE MASK)
                maskOfContainmentFRR = Core.CoOccurence.getIndOfContainment(FRhfo, Rhfo, iChan); %Ind (OLD FAST RIPPLE MASK)
                
                CoOccurenceInfo.maskCell.Ripples{iChan}             =  true(1,length(maskOfContainmentRFR));
                CoOccurenceInfo.maskCell.FastRipples{iChan}         =  {maskOfContainmentRFR, ~maskOfContainmentFRR}; % for a concatinated Ripples and fast ripples
                CoOccurenceInfo.maskCell.RippleANDFastRipple{iChan} =  maskOfContainmentRFR; % taken from the ripples
                
                merged{iChan} = [maskOfContainmentRFR, ~maskOfContainmentFRR];
                
            end
            CoOccurenceInfo.Count.Ripple              = cellfun(@sum,CoOccurenceInfo.maskCell.Ripples);
            CoOccurenceInfo.Count.FastRipple          = cellfun(@sum,merged);
            CoOccurenceInfo.Count.RippleANDFastRipple = cellfun(@sum,CoOccurenceInfo.maskCell.RippleANDFastRipple);
            
            durationMin = (Rhfo.Data.nbSamples/Rhfo.Data.sampFreq)/60;
            
            CoOccurenceInfo.Rates.Ripple              = CoOccurenceInfo.Count.Ripple/durationMin;
            CoOccurenceInfo.Rates.FastRipple          = CoOccurenceInfo.Count.FastRipple/durationMin;
            CoOccurenceInfo.Rates.RippleANDFastRipple = CoOccurenceInfo.Count.RippleANDFastRipple/durationMin;
        end
        
        function IndOfContainment = getIndOfContainment(Rhfo, FRhfo, iChan)
            fs      = Rhfo.Data.sampFreq;
            nbEvent = Rhfo.Events.EventNumber(iChan);
            Ind1    = zeros(1,nbEvent);
            for iEvent = 1:nbEvent
                Rs  = Rhfo.Events.Markings.start{iChan}/fs;
                Re  = Rhfo.Events.Markings.end{iChan}/fs;
                FRe = FRhfo.Events.Markings.end{iChan}/fs;
                FRs = FRhfo.Events.Markings.start{iChan}/fs;
                
                maskRipFRipStart = (Rs(iEvent) < FRe);
                maskRipFRipEnd   = (Re(iEvent) > FRs);
                maskRipFRipBoth  = (maskRipFRipStart & maskRipFRipEnd);
                
                Ind1(iEvent)     =  any(maskRipFRipBoth);
            end
            IndOfContainment = logical(Ind1);
        end
        
        function RFRhfo = getRFRevents(Rhfo, FRhfo, CoOccurenceInfo)
            for ichan = 1:Rhfo.Data.nbChannels
                maskCoOcc = CoOccurenceInfo.maskCell.RippleANDFastRipple{ichan};
                RFRhfo.Events.Markings.start{ichan} = Rhfo.Events.Markings.start{ichan}(maskCoOcc);
                RFRhfo.Events.Markings.end{ichan}   = Rhfo.Events.Markings.end{ichan}(maskCoOcc);
                RFRhfo.Events.Markings.len{ichan}   = Rhfo.Events.Markings.len{ichan}(maskCoOcc);
                
                
                Rhfo.Events.Properties.hfoType = 'Ripple and Fast-Ripple';
                
                % SNRProperties
                RFRhfo.Events.Properties.SNRProperties.SNR{ichan}             = Rhfo.Events.Properties.SNRProperties.SNR{ichan}(maskCoOcc);
                RFRhfo.Events.Properties.SNRProperties.EventMaxAbsAmpl{ichan} = Rhfo.Events.Properties.SNRProperties.EventMaxAbsAmpl{ichan}(maskCoOcc);
                RFRhfo.Events.Properties.SNRProperties.SurMaxAbsAmpl{ichan}   = Rhfo.Events.Properties.SNRProperties.SurMaxAbsAmpl{ichan}(maskCoOcc);
                RFRhfo.Events.Properties.SNRProperties.EventP2P{ichan}        = Rhfo.Events.Properties.SNRProperties.EventP2P{ichan}(maskCoOcc);
                RFRhfo.Events.Properties.SNRProperties.EventRMS{ichan}        = Rhfo.Events.Properties.SNRProperties.EventRMS{ichan}(maskCoOcc);
                RFRhfo.Events.Properties.SNRProperties.SurP2P{ichan}          = Rhfo.Events.Properties.SNRProperties.SurP2P{ichan}(maskCoOcc);
                RFRhfo.Events.Properties.SNRProperties.SurRMS{ichan}          = Rhfo.Events.Properties.SNRProperties.SurRMS{ichan}(maskCoOcc);
                % events
                RFRhfo.Events.Properties.EventData.indeces{ichan}             = Rhfo.Events.Properties.EventData.indeces{ichan}(maskCoOcc);
                RFRhfo.Events.Properties.EventData.data{ichan}                = Rhfo.Events.Properties.EventData.data{ichan}(maskCoOcc);
                RFRhfo.Events.Properties.EventData.envData{ichan}             = Rhfo.Events.Properties.EventData.envData{ichan}(maskCoOcc);
                % Suroundings
                RFRhfo.Events.Properties.SuroundingData.indeces{ichan}        = Rhfo.Events.Properties.SuroundingData.indeces{ichan}(maskCoOcc);
                RFRhfo.Events.Properties.SuroundingData.data{ichan}           = Rhfo.Events.Properties.SuroundingData.data{ichan}(maskCoOcc);
                RFRhfo.Events.Properties.SuroundingData.envData{ichan}        = Rhfo.Events.Properties.SuroundingData.envData{ichan}(maskCoOcc);
                 
                nbEvent = length(RFRhfo.Events.Markings.start{ichan});
                FR2R = cell(nbEvent,1);
                R2R  = cell(nbEvent,1);
                for iEvent = 1:nbEvent
                    CoOcEventStart = RFRhfo.Events.Markings.start{ichan}(iEvent);
                    CoOcEventEnd   = RFRhfo.Events.Markings.end{ichan}(iEvent);
                    RipInterval  = CoOcEventStart:CoOcEventEnd;
                    
                    FREventEndind = FRhfo.Events.Markings.end{ichan};
                    REventEndind  = Rhfo.Events.Markings.end{ichan};
                    
                    FR2R{iEvent} = ismember(FREventEndind , RipInterval);
                    R2R{iEvent}  = ismember(REventEndind, RipInterval(end));
                end
                RFRhfo.Events.FRcorrespondingToEvent{ichan} = FR2R;
                RFRhfo.Events.RcorrespondingToEvent{ichan} = R2R;
            end
            RFRhfo.Events.Rates = CoOccurenceInfo.Rates.RippleANDFastRipple';
        end

%%        % a better version of the above that was never implemented because
        % it does not match with the sacrosanct SciRep paper.
%         function CoOccurence = getRandFRCoOccurence(Rhfo, FRhfo, CoThr)
%             RMarkings  = Rhfo.Events.Markings;
%             FRMarkings = FRhfo.Events.Markings;
%             
%             RMarkingInterval   = Core.CoOccurence.getMarkingsInterval(RMarkings);
%             FRMarkingInterval  = Core.CoOccurence.getMarkingsInterval(FRMarkings);
%             CoOccurence        = Core.CoOccurence.checkCoOccurence(RMarkingInterval, FRMarkingInterval, CoThr);
%         end
%         
%         function MarkingsIntervalCell = getMarkingsInterval(markings)
%             nbChan = length(markings.start);
%             MarkingsIntervalCell = cell(nbChan,1);
%             for iChan = 1:nbChan
%                 strIndeces = markings.start{iChan};
%                 endIndeces = markings.end{iChan};
%                 
%                 nbEvents = length(strIndeces);
%                 EventIntervalChan = cell(1, nbEvents);
%                 for iEvent = 1:nbEvents
%                     EventIntervalChan{iEvent} = strIndeces(iEvent):endIndeces(iEvent);
%                 end
%                 MarkingsIntervalCell{iChan} = EventIntervalChan;
%             end
%         end
%         
%         function coOccurence = checkCoOccurence(EventIntervalBigCell, EventIntervalSmallCell, ContThresh)
%            
%            nbChan       = length(EventIntervalBigCell);
%            coOccurence.ContainmentCell = cell(1, nbChan);
%            coOccurence.maskMultiFR2R   = cell(1, nbChan);
%            coOccurence.maskContained   = cell(1, nbChan);
%            for iChan = 1:nbChan
%                EventIntervalSmall = EventIntervalSmallCell{iChan};
%                EventIntervalBig   = EventIntervalBigCell{iChan};
%                nbBigEvent   = length(EventIntervalBig);
%                nbSmallEvent = length(EventIntervalSmall);
%                ContainmentMat = zeros(nbBigEvent, nbSmallEvent);
%                for iBigEvent = 1:nbBigEvent
%                    for iSmallEvent = 1:nbSmallEvent
%                        smallEvent = EventIntervalSmall{iSmallEvent};
%                        bigEvent   = EventIntervalBig{iBigEvent};
%                        maskMember = ismember(smallEvent, bigEvent);
%                        containmentFraction = sum(maskMember)/length(maskMember);
%                        ContainmentMat(iBigEvent, iSmallEvent) = containmentFraction;
%                    end
%                end
%                coOccurence.ContainmentCell{iChan}  = ContainmentMat;
%                maskThress                          = (ContainmentMat >  ContThresh);
%                coOccurence.maskMultiFR2R{iChan}    =  (sum(maskThress,2) > 1);
%                coOccurence.maskContained{iChan}  = logical(sum(maskThress,1));
%            end
%        end


   end  
end