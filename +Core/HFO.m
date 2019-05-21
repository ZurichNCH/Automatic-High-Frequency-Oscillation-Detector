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
   end
   methods
%% STAGE O: Loading 
     function obj = getParaAndData(obj, strChanContains, data)
         if nargin < 2
             strChanContains = {''};
         end         
         
         pad = Core.ParaAndData;
         assert(~isequal(obj.ParaFileLocation, 'No set path'),'Parameter file path invalid.'); 
         pad.ParaFileLocation = obj.ParaFileLocation;
         
         
         assert(~isequal(obj.DataFileLocation, 'No set path'),'Data file path invalid.'); 
         pad.DataFileLocation = obj.DataFileLocation;
         
         
         pad = loadParameters(pad);
         if nargin > 2
             pad = loadData(pad, strChanContains, data);
         else
             pad = loadData(pad, strChanContains);
         end
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
     function obj = getBasline(obj)
         bl = Core.Baseline;
         bl.hfo = obj;
         
         bl = setBaselineMaxNoisemuV(bl);
         bl = getBaseline(bl);         
         
         obj.baseline = bl.Output; 
     end
     
%% STAGE III: Event finding 
     function obj = getEvents(obj, RefType, isMultiChanRefine)
         if nargin < 2
             RefType = 'spec';
             isMultiChanRefine = false;  
         elseif nargin < 3
             isMultiChanRefine = false;
         end
         assert(any(contains({'morph','spec'},RefType)) ,[RefType,' is an invalid detector choice.'])
         
         
         eoi = Core.EventsOfInterest;
         eoi.hfo = obj;
         if isequal(RefType,'morph')
             eoi = findEvents(eoi, RefType);
             eoi = creatEventPropTable(eoi);
             eoi = condRefineEvents(eoi, RefType);
         elseif isequal(RefType,'spec')
             eoi = findEvents(eoi, RefType);
             eoi = creatEventPropTable(eoi);
             eoi = condRefineEvents(eoi, RefType);
         end
         
         if isMultiChanRefine 
            eoi = multChanRefineEvents(eoi);
         end
         
         obj.Events  = eoi.Output;
     end
     
   end
   methods (Static)
   end
end