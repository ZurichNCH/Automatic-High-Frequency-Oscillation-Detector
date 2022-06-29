classdef FilterSignal
    properties
        hfo
        Output
    end
    methods
%% Filters the bipolar data signal using predefined parameter
        function obj = filterSignal(obj)
            % Input: Data(signal matrix) and filter parameters
            % Simply filter the signal with specified filter coefficients
            % Output: Filtered signal (matrix) 
            Signal = obj.hfo.Data.signal;
            B = obj.hfo.Para.FilterPara.bCoef;
            A = obj.hfo.Para.FilterPara.aCoef;
            disp(['Filtering the signal'])
            obj.Output.filtSignal = filtfilt(B, A, Signal);
        end
        
%% Find signal envelope
        function obj = getSignalEnvelope(obj, smoothBool)
            % input: filtered data signal
            % output: Envelope of filtered signal (smoothing option)
            disp(['Find envelope'])
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
