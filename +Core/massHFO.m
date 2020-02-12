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
        
        function obj = runDetector(obj, RefType, CondMulti, analysisDepth, channelContains, smoothBool, DetecType)
            if nargin < 2
                RefType = 'spec';
                CondMulti = false;
                analysisDepth = 3;
                channelContains = '';
                smoothBool = false;
                DetecType = 'RipAndFRip';
            elseif nargin < 3
                CondMulti = false;
                analysisDepth = 3;
                channelContains = '';
                smoothBool = false;
                DetecType = 'RipAndFRip';
            elseif nargin < 4
                analysisDepth = 3;
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
                    rparaPath, dataDir, RefType, CondMulti, analysisDepth, channelContains, smoothBool);
            end  
            %% Fast Ripples
            if isequal(DetecType,'FRip') || isequal(DetecType,'RipAndFRip')
                disp('Currently running Fast Ripple detection.')
                obj.frHFOInfo = Core.massHFO.getMassHFOData(...
                    frparaPath, dataDir, RefType,CondMulti, analysisDepth, channelContains, smoothBool);                        
            end
            %% Ripple And Fast Ripples
            if isequal(DetecType,'RipAndFRip')
                disp('Currently running Ripple and Fast Ripple overlap detection.')
                obj.CoOccurenceInfo = Core.massHFO.getClusterCoOccurenceInfo(obj.rHFOInfo, obj.frHFOInfo);%%%%%%%%%%%%%%%%%%
            end
            
            [~, obj.numDataFiles]  = Core.massHFO.getFileNames(dataDir, '*.mat');
            obj.channelNames       = obj.rHFOInfo.hfoInfo{1}.Data.channelNames; 
            
        end
        
        function [] = exportHFOsummary(obj)
            dataDir            = obj.DataDir;
            chanNames          = obj.channelNames;
            RipInfo            = obj.rHFOInfo;
            FRipInfo           = obj.frHFOInfo;
            CoOccurenceInf     = obj.CoOccurenceInfo;
            
            saveDir = [dataDir,'HFOSummary\'];
            if ~isdir(saveDir)
                mkdir(dataDir,'HFOSummary')
            end
            Core.massHFO.saveHFOCluster(RipInfo, FRipInfo, CoOccurenceInf, saveDir, chanNames)
        end
    end
    
    methods(Static)
        %% HFO processing
        % Processing HFO on mass   
        function massHFO = getMassHFOData(paraPath, dataDir , RefType, analysisDepth, channelContains, smoothBool)
            [ListOfFiles, nbFiles] = Core.massHFO.getFileNames(dataDir, '*.mat');
            
            for iFile = 1:nbFiles
                disp(['Currently running interval: ',num2str(iFile), ' of ',num2str(nbFiles)])
                DataPath = [dataDir, ListOfFiles{iFile}];
                
                hfo = Core.massHFO.getHFOdata(paraPath, DataPath, RefType,...
                     analysisDepth, channelContains, smoothBool);
                massHFO.channelNames = hfo.Data.channelNames;
                if iFile == 1
                    nbChan   = length(hfo.baseline.maxNoisemuV);
                    NoiseMat = nan(nbFiles, nbChan);
                    BaseLMat = nan(nbFiles, nbChan);
                    HFOraMat = nan(nbFiles, nbChan);
                    
                    hfoInfo = cell(1,nbFiles);
                end
                NoiseMat(iFile, :) = hfo.baseline.maxNoisemuV;
                BaseLMat(iFile, :) = hfo.baseline.baselineThr;
                HFOraMat(iFile, :) = hfo.Events.Rates;
 
                % Strip Big variables of low information density
                hfo.Data = rmfield(hfo.Data,{'signal'});
                hfo.filtSig = [];
                hfo.baseline = rmfield(hfo.baseline,{'IndBaseline'});
                hfo.Events   = rmfield(hfo.Events,{'EventProp'});
                % and make it a struckt
                hfoInfo{iFile} = struct(hfo) ;
            end
            
            massHFO.numDataFiles = nbFiles;
            
            massHFO.Summary.NoiseThresholds = NoiseMat;
            massHFO.Summary.BaseLines       = BaseLMat;
            massHFO.Summary.HFOrates        = HFOraMat;
            
            massHFO.hfoInfo = hfoInfo;
        end
        % Processing a single HFO
        function hfo = getHFOdata(ParaPath, Data, RefType, analysisDepth, channelContains, smoothBool)
            if nargin < 2
                RefType = 'spec';
                analysisDepth = 3;
                channelContains = {''};
                smoothBool = false;
            elseif nargin < 3
                analysisDepth = 3;
                channelContains = {''};
                smoothBool = false;
            elseif nargin < 4
                analysisDepth = 3;
                channelContains = {''};
                smoothBool = false;
            elseif nargin < 5
                channelContains = {''};
                smoothBool = false;
            elseif nargin < 6
                smoothBool = false;
            end
            
            if  analysisDepth >= 1
                hfo = Core.HFO;
                hfo.ParaFileLocation = ParaPath;

                if isstruct(Data)
                    hfo.DataFileLocation = Data;
                    hfo = getParaAndData(hfo, channelContains);
                elseif ischar(Data)
                    hfo.DataFileLocation = Data;
                    hfo = getParaAndData(hfo, channelContains);
                end
                
                hfo = getFilteredSignal(hfo, smoothBool);
                if analysisDepth >= 2
                    hfo = hfo.getBaseline();
                    if analysisDepth >= 3
                        hfo = getEvents(hfo, RefType);
                        hfo = hfo.getEventProperties;
                        hfo = hfo.getRefinements(RefType);
                        
                        if  contains(RefType,{'spec'})
                            CondMask = hfo.Refinement.maskEventCondSelect;
                            if strcmp({'spec'}, RefType)
                                Events = hfo.Events;
                                hfo = hfo.RefineEvents(Events,1, CondMask);
                            end
                            if strcmp({'specECoG'}, RefType)
                                maskPassMultiChan  = hfo.Refinement.maskMultChanRefine;
                                Events = hfo.Events;
                                hfo = hfo.RefineEvents(Events,1,CondMask, maskPassMultiChan);
                            end
                            if strcmp({'specScalp'}, RefType)
                                maskPassMultiChan  = hfo.Refinement.maskMultChanRefine;
                                maskPassSNR        = hfo.Refinement.maskSNR;

                                hfo                = hfo.getMultChanCoOccurence(maskPassSNR);
                                maskPassCoOcc      = hfo.MultChanCoOccurence.Mask;
                                
                                maskPassAbsAmpl    = hfo.Refinement.AbsAmplpass;                             

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
                                
                                Events = hfo.Events;
                                hfo = hfo.RefineEvents(Events, 1,CombinedPassMask);
                                
                                hfo.Refinement.maskMultChanRefine = maskPassMultiChan;
                                hfo.Refinement.maskSNR            = maskPassSNR;
                                hfo.MultChanCoOccurence.Mask      = maskPassCoOcc;
                                hfo.Refinement.AbsAmplpass        = maskPassAbsAmpl;
                            end
                        end
                        if analysisDepth >= 4
                        	hfo = hfo.getEventPropTable;
                        end
                    end
                end
            end
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
        function [] = saveHFOCluster(RipInfo, FRipInfo, CoOccurInfo, saveDir, chanNames)
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Rates %%%%%%%%%%%%%%%%%%%%
            RHFOraMat      = RipInfo.Summary.HFOrates;
            FRHFOraMat     = FRipInfo.Summary.HFOrates;
            RandFRHFOraMat = CoOccurInfo.Summary.HFOrates;
            [HFOArea, maskHFOArea, valMeanTHR, presenceVec] = Core.massHFO.GetHFOAreaMat(RandFRHFOraMat');
             
            Core.massHFO.exportHFOrateDistribution(RHFOraMat, FRHFOraMat, RandFRHFOraMat, HFOArea, maskHFOArea, valMeanTHR, chanNames, saveDir)
            Core.massHFO.exportHFOrateDistribution([], [], RandFRHFOraMat, HFOArea, maskHFOArea, valMeanTHR, chanNames, saveDir,'R&FR')
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Noise %%%%%%%%%%%%%%%%%%%%
            RNoiseMat   = RipInfo.Summary.NoiseThresholds;
            RBaseLMat   = RipInfo.Summary.BaseLines;
            
            FRNoiseMat  = FRipInfo.Summary.NoiseThresholds;
            FRBaseLMat  = FRipInfo.Summary.BaseLines;
            
            Core.massHFO.exportNoiseDist(RBaseLMat, FRBaseLMat, RNoiseMat, FRNoiseMat, HFOArea, chanNames, saveDir)
            
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DATA %%%%%%%%%%%%%%%%%%%%
            % HFO intermediate inforamtion
            hfoSummary.Ripples     = RipInfo.hfoInfo;
            hfoSummary.FastRipples = FRipInfo.hfoInfo;
            hfoSummary.RandFR      = CoOccurInfo.EventInfo;
            % HFO summary inforamtion
            hfoSummary.Rates.RHFO        = RHFOraMat;
            hfoSummary.Rates.FRHFO       = FRHFOraMat;
            hfoSummary.Rates.RandFRHFO   = RandFRHFOraMat;
            
            hfoSummary.Area.HFOArea      = HFOArea;
            hfoSummary.Area.HFOthreshold = valMeanTHR;
            hfoSummary.Area.maskHFOArea  = maskHFOArea;
            hfoSummary.Area.presenceVec  = presenceVec;
            
            hfoSummary.Noise.Ripples        = RNoiseMat;
            hfoSummary.Noise.FastRipples    = FRNoiseMat;
            hfoSummary.Baseline.Ripples     = RBaseLMat;
            hfoSummary.Baseline.FastRipples = FRBaseLMat;
            
            Core.massHFO.exportHFOdata(hfoSummary, saveDir)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Reproducibiility
            
%             Core.massHFO.exportReproducibilityPlots(RandFRHFOraMat, HFOArea, maskHFOArea, chanNames, saveDir)
        end
              
        function [] = exportHFOdata(HFOSummaryMat, SaveDir)
            fileName = 'HFOSummaryMat';
            dataName = [SaveDir, fileName];
            save(dataName, fileName)
        end
        
        %% Visualizations
       
        %Reproducibility
%         function exportDistScalarFig(RandFRHFOraMat, saveDir, saveStr)
%             [RandomDistofSP, ActualDistofSP] = Reproducibility.getTestReTest(RandFRHFOraMat);
%             
%             custom_map = [1,1,1; 0.8,0.8,0.8; 1,0,0];
%             
%             distScalarFig = Core.massHFO.plotdistScalarFig(RandomDistofSP, ActualDistofSP, custom_map);
%             saveas(distScalarFig, [saveDir, 'ReproducibilityEstimate', saveStr, '.png'])
%             close
%         end
        
%         function distScalarFig = plotdistScalarFig(RandomDistofSP, ActualDistofSP, custom_map)
%             PercentileVal = prctile(RandomDistofSP(:), 95);
%             PersentageOfDataThatsucceed = (1 - mean(ActualDistofSP(:) < PercentileVal))*100;
%             binStarts = 0:0.01:1;
%             distScalarFig = figure('units','normalized','outerposition',[0 0 1 1]);
%             colormap(custom_map)
%             hold on
%             hist1 = histogram(RandomDistofSP(:), binStarts,'Normalization','probability','facecolor',[0.8,0.8,0.8],'facealpha', 0.85);
%             hist2 = histogram(ActualDistofSP(:), binStarts,'Normalization','probability','facecolor',[1,0,0],'facealpha', 0.85);
%             PercentileLine = line([PercentileVal, PercentileVal], [0, 0.1]);
%             PercentileLine.LineWidth = 2;
%             hold off
%             ylabel('Probability Desnity')
%             xlabel('Scalar Product')
%             ylim([0 max([hist1.Values, hist2.Values])+0.01])
%             title(['Random HFO rate distribution in time vs. Measured HFO rate distribution in time.',num2str(round(PersentageOfDataThatsucceed)),'% exceed the 95th persentile of random distribution.'])
%             legend([hist1(1), hist2(1), PercentileLine(1)],{'Random Distribution','Measured Distibution','95th percentile of random distribution.'});
%             Core.massHFO.makeFigureTight(gca, 2);
%         end

%         function distScalarFig = plotdistScalarMultiFig(RandomDistofSP, ActualDistofSP, custom_map)
% %             PercentileVal = prctile(RandomDistofSP(:), 95);
%             binStarts = 0:0.01:1;
%             distScalarFig = figure('units','normalized','outerposition',[0 0 1 1]);
%             colormap(custom_map)
%             for iPair = 1:40
%             hold on
%             subplot(5,8,iPair)
%             hist1 = histogram(RandomDistofSP(:,iPair), binStarts,'Normalization','probability','facecolor',[0.8,0.8,0.8],'facealpha', 0.85);
% %             hist2 = histogram(ActualDistofSP(iPair), binStarts,'Normalization','probability','facecolor',[1,0,0],'facealpha', 0.85);
%             line([ActualDistofSP(iPair), ActualDistofSP(iPair)], [0, max(RandomDistofSP(:,iPair))]);
% %             PercentileLine = line([PercentileVal, PercentileVal], [0, max(RandomDistofSP(:,iPair))]);
% %             PercentileLine.LineWidth = 2;
%             ylim([0, 0.1])
%             hold off
% %             ylabel('Probability Desnity')
% %             xlabel('Scalar Product')
%             end
%             
% %             title('Random HFO rate distribution in time vs. Measured HFO rate distribution in time.')
% %             legend([hist1(1), hist2(1), PercentileLine(1)],{'Random Distribution','Measured Distibution','95th percentile of random distribution.'});
% %             Core.HFOSummary.makeFigureTight(gca, 2);
%         end
        
        %% Utility 
        function ax = makeFigureTight(gca, tightness)
            ax = gca;
            outerpos = ax.OuterPosition;
            ti = ax.TightInset*tightness;
            left = outerpos(1) + 0.7*ti(1);
            bottom = outerpos(2) + ti(2);
            ax_width = outerpos(3) - ti(1) - ti(3);
            ax_height = outerpos(4) - ti(2) - ti(4);
            ax.Position = [left bottom ax_width ax_height];
        end

    end
end
   