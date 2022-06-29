classdef massHFO
    properties
        rParaPath
        frParaPath
        DataDir
        
        numDataFiles
        channelNames
        
        rHFOInfo
        frHFOInfo
        CoOccurenceInfo
    end
    
    methods
        function obj = setPDPaths(obj, rparaPath, frparaPath, dataDir)
            obj.rParaPath  = rparaPath;
            obj.frParaPath = frparaPath;
            obj.DataDir    = dataDir;
        end
        
        function obj = runDetector(obj, RefType, CondMulti, anaDepth, channelContains, smoothBool, DetecType)
            if nargin < 2
                RefType = 'spec';
                CondMulti = false;
                anaDepth = 3;
                channelContains = '';
                smoothBool = false;
                DetecType = 'RipAndFRip';
            elseif nargin < 3
                CondMulti = false;
                anaDepth = 3;
                channelContains = '';
                smoothBool = false;
                DetecType = 'RipAndFRip';
            elseif nargin < 4
                anaDepth = 3;
                channelContains = '';
                smoothBool = false;
                DetecType = 'RipAndFRip';
            elseif nargin < 5
                channelContains = '';
                smoothBool = false;
                DetecType = 'RipAndFRip';
            elseif nargin < 6
                smoothBool = false;
                DetecType = 'RipAndFRip';
            elseif nargin < 7 
                DetecType = 'RipAndFRip';
            end
            % Paths
            rparaPath  = obj.rParaPath;
            frparaPath = obj.frParaPath;
            dataDir    = obj.DataDir;
            %% Ripples
            if isequal(DetecType,'Rip') || isequal(DetecType,'RipAndFRip')
                disp('Currently running Ripple detection.')
                obj.rHFOInfo = Core.massHFO.getMassHFOData(...
                    rparaPath, dataDir, RefType, CondMulti, anaDepth, channelContains, smoothBool);
            end  
            %% Fast Ripples
            if isequal(DetecType,'FRip') || isequal(DetecType,'RipAndFRip')
                disp('Currently running Fast Ripple detection.')
                obj.frHFOInfo = Core.massHFO.getMassHFOData(...
                    frparaPath, dataDir, RefType,CondMulti, anaDepth, channelContains, smoothBool);                        
            end
            %% Ripple And Fast Ripples
            if isequal(DetecType,'RipAndFRip')
                disp('Currently running Ripple and Fast Ripple overlap detection.')
                obj.CoOccurenceInfo = Core.massHFO.getClusterCoOccurenceInfo(obj.rHFOInfo, obj.frHFOInfo);%%%%%%%%%%%%%%%%%%
            end
            
            [~, obj.numDataFiles]  = Core.massHFO.getFileNames(dataDir, '*.mat');
            obj.channelNames       = obj.rHFOInfo.hfoInfo{1}.Data.channelNames; 
        end 
    end
    
    methods(Static)
        %% HFO processing
        % Processing HFO on mass   
        function massHFO = getMassHFOData(paraPath, dataDir , RefType, anaDepth, channelContains, smoothBool, SaveDir)
            % This is a wrapper funciton for the call and processing of a
            % directory containing data.mat form with standard format. It
            % repeatedly calls the getHFOData function and also stores the
            % combined rates, noise and baseline for each file in a matrix
            if isempty(SaveDir)
                SaveDir = dataDir;
            end
            [ListOfFiles, nbFiles] = Utility.getFileNames(dataDir, '*.mat');
            
            for iFile = 1:nbFiles
                disp(['Currently running interval: ',num2str(iFile), ' of ',num2str(nbFiles)])
                FileName = ListOfFiles{iFile};
                DataPath = [dataDir, FileName];
                
                hfo = Core.massHFO.getHFOdata(paraPath, DataPath, RefType,...
                     anaDepth, channelContains, smoothBool);
                massHFO.channelNames = hfo.Data.channelNames;
                if iFile == 1
                    nbChan   = length(hfo.baseline.maxNoisemuV);
                    NoiseMat = nan(nbFiles, nbChan);
                    BaseLMat = nan(nbFiles, nbChan);
                    HFOraMat = nan(nbFiles, nbChan);
                    
                end
                NoiseMat(iFile, :) = hfo.baseline.maxNoisemuV;
                BaseLMat(iFile, :) = hfo.baseline.baselineThr;
                HFOraMat(iFile, :) = hfo.Events.Rates;
 
                % Strip Big variables of low information density
                hfo.Data     = rmfield(hfo.Data,{'signal'});
                hfo.filtSig  = [];
                hfo.baseline = rmfield(hfo.baseline,{'IndBaseline'});
                hfo.Events   = rmfield(hfo.Events,{'EventProp'});
                % and make it a struckt
                hfo      = struct(hfo) ;
                savePath = [SaveDir, 'HFO_',FileName];
                save(savePath, 'hfo');
            end
            
            massHFO.numDataFiles = nbFiles;
            massHFO.Summary.NoiseThresholds = NoiseMat;
            massHFO.Summary.BaseLines       = BaseLMat;
            massHFO.Summary.HFOrates        = HFOraMat;
        end
        % Processing a single HFO
        function hfo = getHFOdata(ParaPath, Data, RefType, anaDepth, channelContains, smoothBool)
            if nargin < 2
                RefType = 'spec';
                anaDepth = 3;
                channelContains = {''};
                smoothBool = false;
            elseif nargin < 3
                anaDepth = 3;
                channelContains = {''};
                smoothBool = false;
            elseif nargin < 4
                anaDepth = 3;
                channelContains = {''};
                smoothBool = false;
            elseif nargin < 5
                channelContains = {''};
                smoothBool = false;
            elseif nargin < 6
                smoothBool = false;
            end
            
%             try
            if  anaDepth >= 1
                hfo = Core.HFO;
                hfo.ParaFileLocation = ParaPath;

                if isstruct(Data)
                    hfo.DataFileLocation = Data;
                    hfo = hfo.getParaAndData(channelContains);
                elseif ischar(Data)
                    hfo.DataFileLocation = Data;
                    hfo = hfo.getParaAndData(channelContains);
                end
                
                hfo = hfo.getFilteredSignal(smoothBool); 
                if anaDepth >= 2
                    if  contains(RefType,{'quick'})
                        hfo = hfo.getBaselineSTD;
                    else
                        hfo = hfo.getBaselineEntropy;
                    end
                    if anaDepth >= 3
                        hfo = hfo.getEventsOfInterest(RefType);
                        hfo = hfo.getRefinementMasks(RefType);
                        if  contains(RefType,{'spec'})
                            CondMask = hfo.Refinement.maskEventCondSelect;
                            if strcmp({'specECoG'}, RefType)
                                Events = hfo.Events;
                                maskPassMultiChan  = hfo.Refinement.maskMultChanRefine;
                                hfo = hfo.RefineEvents(Events,1,CondMask, maskPassMultiChan);
                            end
                            if strcmp({'specScalp'}, RefType)
                                maskPassMultiChan  = hfo.Refinement.maskMultChanRefine;
                                maskPassSNR        = hfo.Refinement.maskSNR;

                                hfo                = hfo.getMultChanCoOccurence(maskPassSNR);
                                maskPassCoOcc      = hfo.MultChanCoOccurence.Mask;
                                
                                maskPassAbsAmpl    = hfo.Refinement.AbsAmplpass;                             
                                %% This is some patchy
                                nbChan = length(maskPassAbsAmpl);
                                CombinedPassMask = cell(1,nbChan);
                                for iChan = 1:nbChan
                                    maskPassCoOcc{iChan}(~maskPassSNR{iChan}) = -1;
                                    maskPassAbsAmpl{iChan} = double(maskPassAbsAmpl{iChan});
                                    maskPassAbsAmpl{iChan}((maskPassCoOcc{iChan} ~= 1))  = -1;
                                    
                                    maskPassMultiChan{iChan} = double(maskPassMultiChan{iChan});
                                    maskPassSNR{iChan}       = double(maskPassSNR{iChan});
%                               CombinedMask                                    
                                    CombinedPassMask{iChan} = maskPassMultiChan{iChan} & maskPassSNR{iChan} & logical(maskPassCoOcc{iChan}) & logical(maskPassAbsAmpl{iChan});
                               
                                
                                end
                                %%
                                Events = hfo.Events;
                                hfo = hfo.RefineEvents(Events, 1,CombinedPassMask);
                                
                                hfo.Refinement.maskMultChanRefine = maskPassMultiChan;
                                hfo.Refinement.maskSNR            = maskPassSNR;
                                hfo.MultChanCoOccurence.Mask      = maskPassCoOcc;
                                hfo.Refinement.AbsAmplpass        = maskPassAbsAmpl;
                            end
                        end
                        if  contains(RefType,{'morph'})
                            hfo                = hfo.getMultChanCoOccurence(hfo.Refinement.maskSNR);
%                             maskPassCoOcc      = hfo.MultChanCoOccurence.Mask;
                        end
                        if anaDepth >= 4
                        hfo = hfo.getEventPropTable;
                        end
                    end
                end
            end
%             catch
%                 disp('HFO object computation interupted returning partial result!!!')
%             end
        end
       
        %% Co-Occurence 
        function CoOccurence = getClusterCoOccurenceInfo(RhfoInfo, FRhfoInfo)
            nbFiles = RhfoInfo.numDataFiles;
            nbChan  = length(RhfoInfo.channelNames);
            
            EventInfo = cell(1,nbFiles);
            HFOrates = nan(nbFiles, nbChan);
            for iFile = 1:nbFiles
                rhfo = RhfoInfo.hfoInfo{iFile};
                frhfo = FRhfoInfo.hfoInfo{iFile};
                
                EventInfo{iFile}   = Core.CoOccurence.getECECoOccurence(rhfo, frhfo);
                HFOrates(iFile, :) = EventInfo{iFile}.Rates.RippleANDFastRipple;
            end
            CoOccurence.EventInfo = EventInfo;
            CoOccurence.Summary.HFOrates = HFOrates;
        end
            
        %% Export
        % Export information
%         function [] = saveHFOCluster(RipInfo, FRipInfo, CoOccurInfo, saveDir, chanNames)
%             %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Rates %%%%%%%%%%%%%%%%%%%%
%             RHFOraMat      = RipInfo.Summary.HFOrates;
%             FRHFOraMat     = FRipInfo.Summary.HFOrates;
%             RandFRHFOraMat = CoOccurInfo.Summary.HFOrates;
%             [HFOArea, maskHFOArea, valMeanTHR, presenceVec] = Core.massHFO.GetHFOAreaMat(RandFRHFOraMat');
%              
%             Core.massHFO.exportHFOrateDistribution(RHFOraMat, FRHFOraMat, RandFRHFOraMat, HFOArea, maskHFOArea, valMeanTHR, chanNames, saveDir)
%             Core.massHFO.exportHFOrateDistribution([], [], RandFRHFOraMat, HFOArea, maskHFOArea, valMeanTHR, chanNames, saveDir,'R&FR')
%             %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Noise %%%%%%%%%%%%%%%%%%%%
%             RNoiseMat   = RipInfo.Summary.NoiseThresholds;
%             RBaseLMat   = RipInfo.Summary.BaseLines;
%             
%             FRNoiseMat  = FRipInfo.Summary.NoiseThresholds;
%             FRBaseLMat  = FRipInfo.Summary.BaseLines;
%             
%             Core.massHFO.exportNoiseDist(RBaseLMat, FRBaseLMat, RNoiseMat, FRNoiseMat, HFOArea, chanNames, saveDir)
%             
%             %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DATA %%%%%%%%%%%%%%%%%%%%
%             % HFO intermediate inforamtion
%             hfoSummary.Ripples     = RipInfo.hfoInfo;
%             hfoSummary.FastRipples = FRipInfo.hfoInfo;
%             hfoSummary.RandFR      = CoOccurInfo.EventInfo;
%             % HFO summary inforamtion
%             hfoSummary.Rates.RHFO        = RHFOraMat;
%             hfoSummary.Rates.FRHFO       = FRHFOraMat;
%             hfoSummary.Rates.RandFRHFO   = RandFRHFOraMat;
%             
%             hfoSummary.Area.HFOArea      = HFOArea;
%             hfoSummary.Area.HFOthreshold = valMeanTHR;
%             hfoSummary.Area.maskHFOArea  = maskHFOArea;
%             hfoSummary.Area.presenceVec  = presenceVec;
%             
%             hfoSummary.Noise.Ripples        = RNoiseMat;
%             hfoSummary.Noise.FastRipples    = FRNoiseMat;
%             hfoSummary.Baseline.Ripples     = RBaseLMat;
%             hfoSummary.Baseline.FastRipples = FRBaseLMat;
%             
%             Core.massHFO.exportHFOdata(hfoSummary, saveDir)
% 
%         end
              
%         function [] = exportHFOdata(HFOSummaryMat, SaveDir)
%             fileName = 'HFOSummaryMat';
%             dataName = [SaveDir, fileName];
%             save(dataName, fileName)
%         end
        
        
        %% Utility 


    end
end
   