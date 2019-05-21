classdef FilterSignal
    properties
        hfo
        Output
    end
    methods
%% Filters the bipolar data signal using predefined parameter
        function obj = filterSignal(obj)
            Signal = obj.hfo.Data.signal;
            B = obj.hfo.Para.FilterPara.bCoef;
            A = obj.hfo.Para.FilterPara.aCoef;
            
            obj.Output.filtSignal = filtfilt(B, A, Signal);
        end
        
%% Find signal envelope
        function obj = getSignalEnvelope(obj, smoothBool)
            smoothWin = obj.hfo.Para.SmoothWindow;
            fs = obj.hfo.Data.sampFreq;
            
            % Classical approach to finding signal envelope
            filterSignal = obj.Output.filtSignal;            
            hilbFiltSignal = hilbert(filterSignal);
            envel = abs(hilbFiltSignal);
            
            
            % Optional smoothing in the case of the morphology detector
             if ~smoothBool 
                 obj.Output.Envelope = envel;
                 return
             end
                 
             smoothPara = smoothWin*fs;
             nbCol = size(hilbFiltSignal,2);
             if nbCol == 1
                 obj.Output.Envelope = smooth(envel, smoothPara);
             else
                 for iCol = 1:nbCol
                     obj.Output.Envelope(:,iCol) = smooth(envel(:,iCol), smoothPara);
                 end
             end
          
        end
 
    end
end
