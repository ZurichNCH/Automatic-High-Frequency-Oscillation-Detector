classdef Baseline
    properties
        hfo
        Output
    end
    methods
%% Set the noise threshold        
        function obj = setBaselineMaxNoisemuV(obj)
             maxNoisePARA     = obj.hfo.Para.maxNoisePARA; 
             ConstMaxNoisemuV = obj.hfo.Para.ConstMaxNoisemuV; 
             nbChan           = obj.hfo.Data.nbChannels;
             filtSignal       = obj.hfo.filtSig.filtSignal;
             
             isNoisePreSet = ~isempty(ConstMaxNoisemuV);
             if isNoisePreSet 
                obj.Output.maxNoisemuV = ConstMaxNoisemuV.*ones(1, nbChan) ;
             else
                obj.Output.maxNoisemuV = maxNoisePARA.*std(filtSignal);
             end
        end       
        
%% Calculate the baseline threshold        
        function obj = getBaseline(obj)
            maxNoise     = obj.Output.maxNoisemuV;
            Hfo          = obj.hfo;
            cdfLev       = Hfo.Para.CDFlevel;
            filtCdfLev   = Hfo.Para.CDFlevelFilt;
            nbChannels   = Hfo.Data.nbChannels;
            Envelope     = Hfo.filtSig.Envelope;
            FiltSig      = Hfo.filtSig.filtSignal;
                        
            % Pre-allocate variable sizes
            obj.Output.baselineThr = nan(1,nbChannels);
            for iChan = 1 : nbChannels
                EnvelopeCHAN = Envelope(:,iChan);
               
                IndBaseline = Core.Baseline.getIndBaseline(Hfo, maxNoise(iChan), iChan);
                [BaselineStr, BaselineLen, BaselineEnd] = Core.Baseline.getBaselineIndCHAN(IndBaseline);
                
                obj.Output.HiEntropyIntv.IntvStr{iChan} = BaselineStr;
                obj.Output.HiEntropyIntv.IntvLen{iChan} = BaselineLen;
                obj.Output.HiEntropyIntv.IntvEnd{iChan} = BaselineEnd;
                obj.Output.IndBaseline{iChan}           = IndBaseline;
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                baselineValsCHAN = Core.Baseline.getBaselineCHAN(IndBaseline, EnvelopeCHAN);
                baselineThr      = Core.Baseline.getBaslineThresholdCHAN(baselineValsCHAN, IndBaseline, cdfLev);
                
                FilltBaselineValsCHAN = Core.Baseline.getBaselineCHAN(IndBaseline, FiltSig);
                filtBaselineThr  = Core.Baseline.getBaslineThresholdCHAN(FilltBaselineValsCHAN, IndBaseline, filtCdfLev);
                
%                 obj.Output.baselineValues{iChan}        = baselineValsCHAN;
                obj.Output.baselineThr(iChan)           = baselineThr;
                obj.Output.FiltbaselineThr(iChan)       = filtBaselineThr;
            end
            
        end 
        
    end
   
    methods(Static)       
%% Obtaining indeces of high entropy
        % Using thresholding this function selects intervals in the
        % filtered signal and envelop of 
        function IndBaseline = getIndBaseline(hfo, maxNoise, chan)
            tStep       = hfo.Para.timeStep;        
            lp          = hfo.Para.lowPass;
            stRange     = hfo.Para.StockwellFreqRange;
            stSampRate  = hfo.Para.StockwellSampRate;
            MaxEntPARA  = hfo.Para.MaxEntroFracPARA;
            IndecesTrim = hfo.Para.STransFreqTrimPARA;
            tInterval   = hfo.Data.timeInterval; 
            SampFreq    = hfo.Data.sampFreq;
            signal      = hfo.Data.signal;
            MinHEIvLen  = hfo.Data.MinHighEntrIntvLen;   
            filtSignal  = hfo.filtSig.filtSignal;
            
            
            nbTimeSteps = floor(tInterval(2) - tInterval(1))/tStep;
            cellOfIndHighEnt = cell(1,nbTimeSteps);
            stepCount = 1;
            
            maxEntropy = log((lp - stRange + 1)/stSampRate);
            for timeSeg = tInterval(1) : tStep : tInterval(2) 
                signalSeg                 = Core.Baseline.getSignalSeg(SampFreq, signal, timeSeg, chan);
                StockwellOutput           = Core.Baseline.getStockwellOutput(SampFreq, lp, stRange, stSampRate, signalSeg);
                freqEntropy               = Core.Baseline.getEntropy(StockwellOutput);
                indAboveEntrThr           = Core.Baseline.getIndAboveEntrThr(MaxEntPARA, maxEntropy, freqEntropy);
                indAboveEntrThr           = Core.Baseline.trimIndBorder(SampFreq,IndecesTrim, indAboveEntrThr);
                indBrake                  = Core.Baseline.getIndBrake(SampFreq, IndecesTrim, indAboveEntrThr);
                indHighEntr               = Core.Baseline.getIndHighEntr(maxNoise, SampFreq, MinHEIvLen, filtSignal, chan, indAboveEntrThr, indBrake, timeSeg);
                
                cellOfIndHighEnt{stepCount} = indHighEntr;
                stepCount = 1 + stepCount;
            end
            IndBaseline = cell2mat(cellOfIndHighEnt);
        end

        % returns a segments of the whole signal
        function signalSeg = getSignalSeg(sampFreq, signal, timeSeg, Channel)
            
            if min(size(signal)) == 1
                SignalChan    =  signal;
            else
                SignalChan    = signal(:,Channel);
            end
            
            sampleSeg = (1+(timeSeg-1)*sampFreq) : (timeSeg*sampFreq);
            signalSeg = SignalChan(sampleSeg);
        end
        
        % returns the stockwell transform of the signal segment.
        function STdata = getStockwellOutput(SampFreq, LowPass, FreqRange, StocSampRate, signalSeg)
            [STdata, ~, ~] = Transform.StockwellTransform(signalSeg, FreqRange, LowPass, 1/SampFreq, StocSampRate);
        end
        
        % returns entropy values from stockwell transformed signal segment.
        function freqEntropy = getEntropy(StockwellOutput)
            StockwellPower = abs(StockwellOutput).^2;
            % Stockwell entrophy
            stTotalEnergy = sum(StockwellPower,1);
            stRelativEnregy = bsxfun(@rdivide, StockwellPower, stTotalEnergy);
            freqEntropy= -diag(stRelativEnregy'*log(stRelativEnregy))';
        end
        
        % uses entropy from above to find intervals of high entropy.
        function indAboveEntrThr = getIndAboveEntrThr(MaxEntropyPARA, maxEntropy, freqEntropy)  
            ENtropyThr = MaxEntropyPARA*maxEntropy;
            indAboveEntrThr = find(freqEntropy > ENtropyThr);
        end
        
        % refine the indeces obtained in getIndAboveEntrThr because
        % stockwell does strange things at the border. 
        function indAboveThr = trimIndBorder(SampFreq, IndecesTrim, indAboveThr)

            if  isempty(indAboveThr)
                error('No Indeces above threshold.')
            end
            
            % dont take border points because of stockwell transf
            upperTimeBorder = SampFreq*IndecesTrim;
            lowerTimeBorder = SampFreq*(1-IndecesTrim);
            
            indBelowBorder = (indAboveThr < upperTimeBorder);
            indAboveBorder = (indAboveThr > lowerTimeBorder);
            
            indAboveThr(indBelowBorder | indAboveBorder) = [];

        end
        
        % returns break indeces used to select intervals of high entropy.
        function indBrake = getIndBrake(SampFreq, IndecesTrim, indAboveThr)
            
            upperTimeBorder = SampFreq*IndecesTrim;
            lowerTimeBorder = SampFreq*(1-IndecesTrim);
            
            if isempty(indAboveThr)
                error('No Indeces above threshold.')
            end
            
            % check for the length
            maskBrake = indAboveThr(2:end) - indAboveThr(1:end-1) > 1 ;
            indBrake = find(maskBrake);
            
            % check if it starts already above or the last point is above the threshold
            if indAboveThr(1) == upperTimeBorder
                indBrake = [1, indBrake];
            end
            
            if indAboveThr(end) == lowerTimeBorder
                indBrake = [indBrake, length(indAboveThr)];
            end
            
            if isempty(indBrake)
                indBrake = length(indAboveThr);
                warning('No brake indeces could be found, taking the whole interval.')
            end

        end
        
        % returns indices of intervals of high entropy in the signal segment
        function indHighEntr = getIndHighEntr(maxNoise, SampFreq, MinHEntIntvLen, filtSignal, channel, indAboveThr, indBrake, timeSeg)           
     
                nbIndBrake = length(indBrake);
                indHighEntrCELL = cell(1,nbIndBrake-1);
                for iBreak = 1 : nbIndBrake-1
                    interLen = (indBrake(iBreak)+1):indBrake(iBreak+1);
                    isIntvLong = length(interLen) >= MinHEntIntvLen;
                    
                    indAboveThr(interLen) = indAboveThr(interLen) + (timeSeg-1)*SampFreq;
                    isFiltSingalBelowNoise = ~any(abs(filtSignal(indAboveThr(interLen), channel)) > maxNoise);
                    
                    if isIntvLong && isFiltSingalBelowNoise
                        indHighEntrCELL{iBreak} = indAboveThr(interLen);
                    end
                end
                indHighEntr = cell2mat(indHighEntrCELL);
        end
              
%% Represent the intervals of high entropy as indeces       
        % returns intervals as opposed to indeces
        function  [BaselineStr, BaselineLen, BaselineEnd] = getBaselineIndCHAN(IndBaseline)
            absDiffIndBaseline = abs(diff(IndBaseline));
            
            IndBLInterStrEnd = [1,find(absDiffIndBaseline > 1)];
            nbBLIntervals = length(IndBLInterStrEnd)/2;
            maskBLInterEnd = logical(repmat([0,1], 1, fix(nbBLIntervals)));
            maskBLInterStr = ~maskBLInterEnd;
            
            BaselineStr = IndBaseline(IndBLInterStrEnd(maskBLInterStr))';
            BaselineEnd = IndBaseline(IndBLInterStrEnd(maskBLInterEnd))';
            BaselineLen = BaselineEnd - BaselineStr;
        end
      
%% Using indeces of high entropy to define basline
        % Uses the Indeces of high entropy to select pieces of the envelope
        function [baselineCHAN] = getBaselineCHAN(IndBaseline, EnvelopeCHAN)
            baselineCHAN = EnvelopeCHAN(IndBaseline);
        end

%% From the baseline calcualte a CDF threshold based
        % returns the baseline threshold using CDFlevel thresholding
        function baselineThr = getBaslineThresholdCHAN(baseline, IndBaseline, cdflev)
            isNoBaselineInd = ~isempty(IndBaseline);
            if  isNoBaselineInd
                [EmpCDFvals, EmpCDFLocs] = ecdf(baseline);
                indTooHighCDFvals = find(EmpCDFvals > cdflev, 1);
                thrCDF = EmpCDFLocs(indTooHighCDFvals);
            else
                thrCDF = NaN;
                warning('Baseline threshold could not be set.')
            end
            baselineThr = thrCDF;
        end
        
    end
end
