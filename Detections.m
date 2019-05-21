classdef Detections
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
        
        function obj = runDetector(obj, RefType, CondMulti, analDepth, channelContains, smoothBool, DetecType, ContThresh)
            if nargin < 2
                RefType = 'spec';
                CondMulti = false;
                analDepth = 3;
                channelContains = '';
                smoothBool = false;
                DetecType = 'RipAndFRip';
                ContThresh = 0.8;
            elseif nargin < 3
                CondMulti = false;
                analDepth = 3;
                channelContains = '';
                smoothBool = false;
                DetecType = 'RipAndFRip';
                ContThresh = 0.8;
            elseif nargin < 4
                analDepth = 3;
                channelContains = '';
                smoothBool = false;
                DetecType = 'RipAndFRip';
                ContThresh = 0.8;
            elseif nargin < 5
                channelContains = '';
                smoothBool = false;
                DetecType = 'RipAndFRip';
                ContThresh = 0.8;
            elseif nargin < 6
                smoothBool = false;
                DetecType = 'RipAndFRip';
                ContThresh = 0.8;
            elseif nargin < 7 
                DetecType = 'RipAndFRip';
                ContThresh = 0.8;
            elseif nargin < 8 
                ContThresh = 0.8;
            end

            rparaPath  = obj.rParaPath;
            frparaPath = obj.frParaPath;
            dataDir    = obj.DataDir;
            
            if isequal(DetecType,'Rip') || isequal(DetecType,'RipAndFRip')
                disp('Currently running Ripple detection.')
                obj.rHFOInfo = Detections.getClusterHFOData(...
                    rparaPath, dataDir, RefType, CondMulti, analDepth, channelContains, smoothBool);
            end                                 
            if isequal(DetecType,'FRip') || isequal(DetecType,'RipAndFRip')
                disp('Currently running Fast Ripple detection.')
                obj.frHFOInfo = Detections.getClusterHFOData(...
                    frparaPath, dataDir, RefType,CondMulti, analDepth, channelContains, smoothBool);                        
            end
            if isequal(DetecType,'RipAndFRip')
                disp('Currently running Ripple and Fast Ripple overlap detection.')
                obj.CoOccurenceInfo = Detections.getClusterCoOccurenceInfo(obj.rHFOInfo, obj.frHFOInfo, ContThresh);%%%%%%%%%%%%%%%%%%
            end
            
            [~, obj.numDataFiles] = Detections.getFileNames(dataDir, '*.mat');
            try
                obj.channelNames      =  obj.rHFOInfo.hfoInfo{1}.Data.channelNames;
            catch
                obj.channelNames      =  obj.frHFOInfo.hfoInfo{1}.Data.channelNames;    
            end
        end
        
        function [] = exportHFOsummary(obj)
            dataDir            = obj.DataDir;
            chanNames          = obj.channelNames;
            %% Ripples
            RipInfo            = obj.rHFOInfo;
            saveDir = [dataDir,'RippleHFOSummary\'];
            if ~isdir(saveDir)
                mkdir(dataDir,'RippleHFOSummary')
            end
            Detections.saveHFOCluster(RipInfo, saveDir, chanNames)
             
            %% Fast Ripples
            FRipInfo           = obj.frHFOInfo;
            saveDir = [dataDir,'FastRippleHFOSummary\'];
            if ~isdir(saveDir)
                mkdir(dataDir,'FastRippleHFOSummary')
            end
            Detections.saveHFOCluster(FRipInfo, saveDir, chanNames)
            
            %% Ripples and Fast Ripples 
            CoOccurenceInf = obj.CoOccurenceInfo;
            saveDir = [dataDir,'RAndFRHFOSummary\'];
            if ~isdir(saveDir)
                mkdir(dataDir,'RAndFRHFOSummary')
            end
            Detections.saveCoOccurenceInfo(CoOccurenceInf, saveDir, chanNames)
        end
        
    end
    
    methods(Static)
        %% The workhorse of this script    
        
        function clusterHFO = getClusterHFOData(paraPath, dataDir , RefType, CondMulti, analDepth, channelContains, smoothBool)
            [ListOfFiles, nbFiles] = Detections.getFileNames(dataDir, '*.mat');
            for iFile = 1:nbFiles
                disp(['Currently running interval: ',num2str(iFile), ' of ',num2str(nbFiles)])
                DataPath = [dataDir, ListOfFiles{iFile}];
                
                hfo = Detections.getHFOdata(paraPath, DataPath, RefType,...
                    CondMulti, analDepth, channelContains, smoothBool);
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
                
                hfoInfo{iFile} = hfo ;
            end
            clusterHFO.channelNames = hfo.Data.channelNames;
            clusterHFO.numDataFiles = nbFiles;
            
            clusterHFO.Summary.NoiseThresholds = NoiseMat;
            clusterHFO.Summary.BaseLines = BaseLMat;
            clusterHFO.Summary.HFOrates = HFOraMat;
            
            clusterHFO.hfoInfo = hfoInfo;
        end
        
        function hfo = getHFOdata(ParaPath, DataPath, RefType, CondMulti, analDepth, channelContains, smoothBool)
            if nargin < 3
                RefType = 'spec';
                CondMulti = false;
                analDepth = 3;
                channelContains = {''};
                smoothBool = false;
            elseif nargin < 4
                CondMulti = false;
                analDepth = 3;
                channelContains = {''};
                smoothBool = false;
            elseif nargin < 5
                analDepth = 3;
                channelContains = {''};
                smoothBool = false;
            elseif nargin < 6
                channelContains = {''};
                smoothBool = false;
            elseif nargin < 7
                smoothBool = false;
            end
            
            if  analDepth >= 1
                hfo = Core.HFO;
                hfo.ParaFileLocation = ParaPath;
                hfo.DataFileLocation = DataPath;
                hfo = getParaAndData(hfo, channelContains);
                hfo = getFilteredSignal(hfo, smoothBool); 
                if analDepth >= 2
                    hfo = getBasline(hfo);
                    if analDepth >= 3
                        hfo = getEvents(hfo, RefType, CondMulti);
                    end
                end
            end
        end
       
        function CoOccurence = getClusterCoOccurenceInfo(RhfoInfo, FRhfoInfo, ContThresh)
            nbFiles = RhfoInfo.numDataFiles;
            nbChan  = length(RhfoInfo.channelNames);
            
            EventInfo = cell(1,nbFiles);
            HFOrates = nan(nbFiles, nbChan);
            for iFile = 1:nbFiles
                rhfo = RhfoInfo.hfoInfo{iFile};
                frhfo = FRhfoInfo.hfoInfo{iFile};
                CoOc = Core.CoOccurence;
                EventInfo{iFile} = CoOc.runCoOccurence(rhfo, frhfo, ContThresh);
                
                HFOrates(iFile, :) = EventInfo{iFile}.Rates;
            end
            CoOccurence.EventInfo = EventInfo;
            CoOccurence.Summary.HFOrates  = HFOrates;
        end

        %% Output
        % Export information
        function [] = saveHFOCluster(HFOInfo, saveDir, chanNames)
            NoiseMat   = HFOInfo.Summary.NoiseThresholds;
            BaseLMat   = HFOInfo.Summary.BaseLines;
            HFOraMat   = HFOInfo.Summary.HFOrates;
            hfoSummary = HFOInfo;
            
            Detections.exportNoiseDistribution(NoiseMat, chanNames, saveDir)
            Detections.exportBaselDistribution(BaseLMat, chanNames, saveDir)
            Detections.exportHFOrateDistribution(HFOraMat, chanNames, saveDir)
            Detections.exportHFOdata(hfoSummary, saveDir)
        end
        
        function [] = saveCoOccurenceInfo(CoOccurenceInfo, saveDir, chanNames)
            HFOraMat   = CoOccurenceInfo.Summary.HFOrates;
            hfoSummary = CoOccurenceInfo.EventInfo;
            
            Detections.exportHFOrateDistribution(HFOraMat, chanNames, saveDir)
            Detections.exportHFOdata(hfoSummary, saveDir)
            
        end
        
        function [] = exportHFOdata(HFOSummaryMat, SaveDir)
            fileName = 'HFOSummaryMat';
            dataName = [SaveDir, fileName];
            save(dataName, fileName)
        end
        
        %% Visualizations
        function exportNoiseDistribution(NoiseMat, channelNames, DataDir)
            distPlot = Detections.plotDataDist(NoiseMat, channelNames,  'Noise thresholds distribution by channel');
            saveas(distPlot,[DataDir,'NoiseDistribution','.png'])
            close all
        end
        
        function exportBaselDistribution(BaseLMat, channelNames, DataDir)
            distPlot =  Detections.plotDataDist(BaseLMat, channelNames,  'Baseline thresholds distribution by channel');
            saveas(distPlot,[DataDir,'BaslineDistribution','.png'])
            close all
        end
        
        function exportHFOrateDistribution(HFOraMat, channelNames, DataDir)
            distPlot =  Detections.plotDataDist(HFOraMat, channelNames,  'HFO rate distribution by channel');
            saveas(distPlot,[DataDir,'HFORateDistribution','.png'])
            close all
        end
        
        function fig = plotDataDist(DataMat, chanNames, titleText)
            nbChannels = length(DataMat);
            fig = figure('units','normalized','outerposition',[0 0 1 1]);
            if size(DataMat,1) == 1
                scatter(1:length(DataMat), DataMat')
            else
                boxplot(DataMat)
            end
            set(gca,'xtick',1:nbChannels,'xticklabel',chanNames,'fontsize', 6)
            xtickangle(90)
            title(titleText,'fontsize', 20)
            annotation('textbox', [0.1, 0.83, 0.1, 0.1], 'string',  'uV')
        end
        

        %% File Utility        
        function [ListOfFiles, nbFiles] = getFileNames(LoadDirectory, extension)
            % This function returns the names of .mat files in a given directory.
            % Input: directory location as string e.g. '/home/andries/DataForProjects/SleepData/Patient1/'
            % Output: cell with string entries e.g.  {'pat_1_night_1_interval_1.mat'}...                                             .
            
            if 7~=exist(LoadDirectory,'dir')
                error('This directory does not exist.')
            end
            
            addpath(genpath(LoadDirectory))
            ListOfFiles = dir([LoadDirectory, extension]);
            ListOfFiles = {ListOfFiles.name}';
            nbFiles = length(ListOfFiles);
        end

    end
end
   