classdef CoOccurence
   properties
       Rhfo
       FRhfo
       ContThresh
       maskCellCoOccurence
       Events 
   end
   
   methods
       function Events = runCoOccurence(obj, Rhfo, FRhfo, ContThresh)

           CoOc = obj;
           CoOc = CoOc.loadHFO(Rhfo, FRhfo);
           CoOc = CoOc.setContainmentThreshold(ContThresh);
           CoOc = CoOc.getCoOccurence;
           CoOc = CoOc.getCoOccuredEvents;
           Events = CoOc.Events;
       end
       
       function obj = loadHFO(obj, Rhfo, FRhfo)
           obj.Rhfo = Rhfo;
           obj.FRhfo = FRhfo;
       end
       
       function obj = setContainmentThreshold(obj,ContThresh)
           obj.ContThresh = ContThresh;
       end
       
       function obj = getCoOccurence(obj)
           rhfo  = obj.Rhfo;
           frhfo = obj.FRhfo;
           CoThr = obj.ContThresh;
           CoOccure = Core.CoOccurence.getRandFRCoOccurence(rhfo, frhfo, CoThr);
           
           obj.maskCellCoOccurence = CoOccure.maskContained;
       end
       
       function obj = getCoOccuredEvents(obj)
            durSec = (obj.FRhfo.Data.nbSamples / obj.FRhfo.Data.sampFreq);
            durMin = durSec/60;
            frEvents = obj.FRhfo.Events;
            CoOcc = obj.maskCellCoOccurence;
            nbChan = length(CoOcc);
              
            for iChan = 1:nbChan
                maskCoOccChan = CoOcc{iChan};
                EventNumber            = cellfun(@sum,CoOcc);
                Markings.start{iChan}  = frEvents.Markings.start{iChan}(maskCoOccChan);
                Markings.end{iChan}    = frEvents.Markings.end{iChan}(maskCoOccChan);
                Markings.len{iChan}    = frEvents.Markings.len{iChan}(maskCoOccChan);
%                 EventProp              = frEvents.EventProp{iChan}(maskCoOccChan,:);
                Rates                  = EventNumber/durMin;
            end
            obj.Events.EventNumber     = EventNumber;
            obj.Events.Markings.start  = Markings.start;
            obj.Events.Markings.end    = Markings.end;
            obj.Events.Markings.len    = Markings.len;
%             obj.Events.EventProp       = EventProp; 
            obj.Events.Rates           = Rates;
       end
   end
   
   methods(Static)
       function CoOccurence = getRandFRCoOccurence(Rhfo, FRhfo, CoThr)
           RMarkings  = Rhfo.Events.Markings;
           FRMarkings = FRhfo.Events.Markings;
           
           RMarkingInterval   = Core.CoOccurence.getMarkingsInterval(RMarkings);
           FRMarkingInterval  = Core.CoOccurence.getMarkingsInterval(FRMarkings);
           CoOccurence        = Core.CoOccurence.checkCoOccurence(RMarkingInterval, FRMarkingInterval, CoThr);
       end
       
       function MarkingsIntervalCell = getMarkingsInterval(markings)
           nbChan = length(markings.start);
           MarkingsIntervalCell = cell(nbChan,1);
           for iChan = 1:nbChan
               strIndeces = markings.start{iChan};
               endIndeces = markings.end{iChan};
               
               nbEvents = length(strIndeces);
               EventIntervalChan = cell(1, nbEvents);
               for iEvent = 1:nbEvents
                   EventIntervalChan{iEvent} = strIndeces(iEvent):endIndeces(iEvent);
               end
               MarkingsIntervalCell{iChan} = EventIntervalChan;
           end
       end
       
       function coOccurence = checkCoOccurence(EventIntervalBigCell, EventIntervalSmallCell, ContThresh)
           
           nbChan       = length(EventIntervalBigCell);
           coOccurence.ContainmentCell = cell(1, nbChan);
           coOccurence.maskContained   = cell(1, nbChan);
           for iChan = 1:nbChan
               EventIntervalSmall = EventIntervalSmallCell{iChan};
               EventIntervalBig   = EventIntervalBigCell{iChan};
               nbBigEvent   = length(EventIntervalBig);
               nbSmallEvent = length(EventIntervalSmall);
               ContainmentMat = zeros(nbBigEvent, nbSmallEvent);
               for iBigEvent = 1:nbBigEvent
                   for iSmallEvent = 1:nbSmallEvent
                       smallEvent = EventIntervalSmall{iSmallEvent};
                       bigEvent   = EventIntervalBig{iBigEvent};
                       maskMember = ismember(smallEvent, bigEvent);
                       containmentFraction = sum(maskMember)/length(maskMember);
                       ContainmentMat(iBigEvent, iSmallEvent) = containmentFraction;
                   end
               end
               coOccurence.ContainmentCell{iChan}  = ContainmentMat;
               maskThress                          = (ContainmentMat >=  ContThresh);
               coOccurence.maskContained{iChan}  = logical(sum(maskThress,1));
           end
       end
       
   end  
end