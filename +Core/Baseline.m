classdef Baseline
    properties
        hfo
        Output
    end
    methods
    %% test
%% Set the noise threshold        
        function obj = setBaselineMaxNoisemuV(obj)
            % input: parameters, data and signal
            % output: maximum noise threshold
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
        function obj = getBaselineEntropy(obj)
            % input: parameters, channel labels and filtered signal
            % output: Baseline threshold for aeach channel
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
                disp(['Getting baseline for channel ',num2str(iChan),' of ',num2str(nbChannels)])
                EnvelopeCHAN                            = Envelope(:,iChan);
                FiltSigCHAN                             = FiltSig(:,iChan);
                
                [IndBaseline, tookFullSig]              = Core.Baseline.getIndBaseline(Hfo, maxNoise(iChan), iChan);
                [BaselineStr, BaselineLen, BaselineEnd] = Core.Baseline.getBaselineIndCHAN(IndBaseline);
                
                obj.Output.HiEntropyIntv.IntvStr{iChan} = BaselineStr;
                obj.Output.HiEntropyIntv.IntvLen{iChan} = BaselineLen;
                obj.Output.HiEntropyIntv.IntvEnd{iChan} = BaselineEnd;
                obj.Output.IndBaseline{iChan}           = IndBaseline;
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                baselineValsCHAN      = Core.Baseline.getBaselineCHAN(IndBaseline, EnvelopeCHAN);
                baselineThr           = Core.Baseline.getBaslineThresholdCHAN(baselineValsCHAN, IndBaseline, cdfLev);
                FilltBaselineValsCHAN = Core.Baseline.getBaselineCHAN(IndBaseline, FiltSigCHAN);
                filtBaselineThr       = Core.Baseline.getBaslineThresholdCHAN(FilltBaselineValsCHAN, IndBaseline, filtCdfLev);
                
%               obj.Output.baselineValues{iChan}        = baselineValsCHAN;
                obj.Output.baselineFullSig(iChan)       = tookFullSig;
                obj.Output.baselineThr(iChan)           = baselineThr;
                obj.Output.FiltbaselineThr(iChan)       = filtBaselineThr;
            end
            
        end 
        
%% Calculate alternative baseline 
% (much quicker but differs from entropy baseline by as much as 15%)  
        function obj = getBaselineSTD(obj)
            Hfo           = obj.hfo;
            cdflev        = Hfo.Para.CDFlevelFilt;
            nbChan        = Hfo.Data.nbChannels;
            indBaseline   = cell(1, nbChan);
            STDthrCDF     = NaN(1, nbChan);
            FiltSTDthrCDF = NaN(1, nbChan);
            OutlierSTDThr =  3; %HFfo.Para.STDthreshPara
            
            
            for iChan = 1:nbChan
                disp(['Getting entropy for channel ',num2str(iChan),' of ',num2str(nbChan)])
                envFiltSigOneChan =  Hfo.filtSig.Envelope(:,iChan );
                FiltSigOneChan    =  Hfo.filtSig.filtSignal(:,iChan );

                TempSTD = std(envFiltSigOneChan);
                TempSTD = std(envFiltSigOneChan(abs(envFiltSigOneChan) <  TempSTD*OutlierSTDThr));
                indBaseline{iChan} = (envFiltSigOneChan < TempSTD*2);
                baseline = envFiltSigOneChan(indBaseline{iChan});
                FiltBaseline = FiltSigOneChan(indBaseline{iChan});

                [EmpCDFvals, EmpCDFLocs] = ecdf(baseline);
                indTooHighCDFvals = find(EmpCDFvals > cdflev, 1);
                STDthrCDF(iChan) = EmpCDFLocs(indTooHighCDFvals);
                
                
                [EmpCDFvals, EmpCDFLocs] = ecdf(FiltBaseline);
                indTooHighCDFvals = find(EmpCDFvals > cdflev, 1);
                FiltSTDthrCDF(iChan) = EmpCDFLocs(indTooHighCDFvals);
                
            end
            obj.Output.baselineThr   = STDthrCDF;
            obj.Output.HiEntropyIntv = 'Standard deviation mthod used method used.';
            obj.Output.IndBaseline   = indBaseline;
            obj.Output.baselineFullSig = ones(1,nbChan);
            
            obj.Output.FiltbaselineThr = FiltSTDthrCDF;
        end
        
    end
   
    methods(Static)       
%% Obtaining indeces of high entropy
        function [IndBaseline, tookFullSig] = getIndBaseline(hfo, maxNoise, chan)
        % Using thresholding this function selects intervals in the
        % filtered signal and envelop of
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
  
            maxEntropy = log((lp - stRange + 1)/stSampRate);
            
            lambdagetInd = @(timeSeg) Core.Baseline.getIndPreBaseline(...
                timeSeg,SampFreq, signal, chan, lp,...
                stRange, stSampRate, MaxEntPARA, maxEntropy,...
                IndecesTrim, maxNoise, MinHEIvLen, filtSignal);
            
            try
                cellTinterval = num2cell(tInterval(1) : tStep : tInterval(2));
                cellOfIndHighEnt = cellfun(lambdagetInd , cellTinterval , 'UniformOutput' , false);
            catch
                tInterval = [1, length(filtSignal)/SampFreq];
                cellTinterval = num2cell(tInterval(1) : tStep : tInterval(2));
                cellOfIndHighEnt = cellfun(lambdagetInd , cellTinterval , 'UniformOutput' , false);
            end
            IndBaseline = cell2mat(cellOfIndHighEnt);
            %%%%%%%%%%%%%%%%%%%%%%%%%%This is suspect%%%%%%%%%%%%%%%%%%%%%%
            isBaslineTooShort = (length(IndBaseline) < 2*SampFreq);
            if isBaslineTooShort  
                tookFullSig = 1;
%                 disp(['Warning: Baseline is too short taking the whole duration of the signal for channel.',ChanNames{chan}])
                
                tInterval = [1, length(filtSignal)/SampFreq];
                lambdagetInd = @(timeSeg) Core.Baseline.getIndPreBaseline(...
                    timeSeg,SampFreq, signal, chan, lp,...
                    stRange, stSampRate, MaxEntPARA, maxEntropy,...
                    IndecesTrim, maxNoise, MinHEIvLen, filtSignal);
                
                cellTinterval = num2cell(tInterval(1) : tStep : tInterval(2));
                cellOfIndHighEnt = cellfun(lambdagetInd , cellTinterval , 'UniformOutput' , false);
                IndBaseline = cell2mat(cellOfIndHighEnt);
            else
                tookFullSig = 0;
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end

        function IndPreBaseline = getIndPreBaseline(timeSeg,SampFreq, signal, chan,...
                                                    lp, stRange, stSampRate, MaxEntPARA,...
                                                    maxEntropy, IndecesTrim, maxNoise, MinHEIvLen,...
                                                    filtSignal)
                                                
            signalSeg                 = Core.Baseline.getSignalSeg(SampFreq, signal, timeSeg, chan);
            StockwellOutput           = Core.Baseline.getStockwellOutput(SampFreq, lp, stRange, stSampRate, signalSeg);
            freqEntropy               = Core.Baseline.getEntropy(StockwellOutput);
            indAboveEntrThr           = Core.Baseline.getIndAboveEntrThr(MaxEntPARA, maxEntropy, freqEntropy);
            indAboveEntrThr           = Core.Baseline.trimIndBorder(SampFreq,IndecesTrim, indAboveEntrThr);
            indBrake                  = Core.Baseline.getIndBrake(SampFreq, IndecesTrim, indAboveEntrThr);
            
            if isnan(indBrake)
                warning('No brake points found setting indeces of high entropy to empty.')
                indHighEntr = [];
            else
                indHighEntr = Core.Baseline.getIndHighEntr(maxNoise, SampFreq, MinHEIvLen, filtSignal, chan, indAboveEntrThr, indBrake, timeSeg);
            end
             IndPreBaseline = indHighEntr;
        end

        function signalSeg = getSignalSeg(sampFreq, signal, timeSeg, Channel)
            % sub selects a segment from a signal on a specified channel
            if min(size(signal)) == 1
                SignalChan    =  signal;
            else
                SignalChan    = signal(:,Channel);
            end
            
            sampleSegInd = (1+(timeSeg-1)*sampFreq) : (timeSeg*sampFreq);
            try
                signalSeg = SignalChan(sampleSegInd);
            catch
                signalSeg = SignalChan((1+(timeSeg-1)*sampFreq):length(SignalChan));   
            end
        end
        
        function STdata = getStockwellOutput(SampFreq, LowPass, FreqRange, StocSampRate, signalSeg)
             % returns the stockwell transform of the signal segment
            [STdata, ~, ~] = Transform.StockwellTransform(signalSeg, FreqRange, LowPass, 1/SampFreq, StocSampRate);
        end
        
        function freqEntropy = getEntropy(StockwellOutput)
            % returns entropy values from stockwell transformed signal segment.
            StockwellPower = abs(StockwellOutput).^2;
            % Stockwell entrophy
            stTotalEnergy = sum(StockwellPower,1);
            stRelativEnregy = bsxfun(@rdivide, StockwellPower, stTotalEnergy);
            freqEntropy= -diag(stRelativEnregy'*log(stRelativEnregy))';
        end
        
        function indAboveEntrThr = getIndAboveEntrThr(MaxEntropyPARA, maxEntropy, freqEntropy)  
            % uses entropy from above to find indeces of intervals of high entropy.
            ENtropyThr = MaxEntropyPARA*maxEntropy;
            indAboveEntrThr = find(freqEntropy > ENtropyThr);
        end
        
        function indAboveThr = trimIndBorder(SampFreq, IndecesTrim, indAboveThr)
        % refine the indeces obtained in getIndAboveEntrThr because
        % stockwell does strange things at the border. 
            if  isempty(indAboveThr)
                warning('No Indeces above threshold.')
                indAboveThr = [];
                return
            end
            
            % dont take border points because of stockwell transf
            upperTimeBorder = SampFreq*IndecesTrim;
            lowerTimeBorder = SampFreq*(1-IndecesTrim);
            
            indBelowBorder = (indAboveThr < upperTimeBorder);
            indAboveBorder = (indAboveThr > lowerTimeBorder);
            
            indAboveThr(indBelowBorder | indAboveBorder) = [];

        end
        
        function indBrake = getIndBrake(SampFreq, IndecesTrim, indAboveThr)
        % returns break indeces used to select intervals of high entropy.   
            upperTimeBorder = SampFreq*IndecesTrim;
            lowerTimeBorder = SampFreq*(1-IndecesTrim);
            
            % contingency for empty input
            if isempty(indAboveThr)
                warning('No Indeces above threshold.')
                indBrake = nan;
                return
            end
            
            % check for the length
            maskBrake = indAboveThr(2:end) - indAboveThr(1:end-1) > 1 ;
            indBrake = find(maskBrake);
            
            % check if it starts already above or the last point is above the threshold
            if indAboveThr(1) == upperTimeBorder
                indBrake = [1, indBrake];
            end
            % consider the special case at the boundary
            if indAboveThr(end) == lowerTimeBorder
                indBrake = [indBrake, length(indAboveThr)];
            end
            
            % contingency for empty output
            if isempty(indBrake)
                indBrake = length(indAboveThr);
                warning('No brake indeces could be found, taking the whole interval.')
            end

        end
        
        function indHighEntr = getIndHighEntr(maxNoise, SampFreq, MinHEntIntvLen, filtSignal, channel, indAboveThr, indBrake, timeSeg)           
        % returns indices of intervals of high entropy in the signal segment
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
        
        function  [BaselineStr, BaselineLen, BaselineEnd] = getBaselineIndCHAN(IndBaseline)
            %Input: indeces of baseline
            %Output: the start , end and length of the interval spaning the indeces
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
            %Selects  part of the envelope that correspond to high entropy
            baselineCHAN = EnvelopeCHAN(IndBaseline);
        end

%% From the baseline calcualte a CDF threshold based
        
        function baselineThr = getBaslineThresholdCHAN(baseline, IndBaseline, cdflev)
            %Input: Indeces of the Baseline, Baseline values at indeces and cdf-level paramater
            % returns the baseline threshold for a channel by finding the CDF level of all the baseline values on said channel
            %Output: baseline threshold
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
