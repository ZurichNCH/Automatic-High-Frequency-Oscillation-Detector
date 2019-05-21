classdef ParaAndData
    properties
        %Input
        ParaFileLocation
        DataFileLocation      
        %Output
        Para
        Data
    end
    methods     
        %% Load predetermined parameters from a saved .mat file
        function obj = loadParameters(obj)
            load(obj.ParaFileLocation);
            obj.Para = DetPara;
            obj.Para.ParaFileLocation = obj.ParaFileLocation;
        end
        
        %% Load data and relavant meta-data
        function obj = loadData(obj, chanContains, data)
            maxToJoinPARA = obj.Para.maxIntervalToJoinPARA;
            MinHiEntrPARA = obj.Para.MinHighEntrIntvLenPARA;
            minETPARA     = obj.Para.minEventTimePARA;
            durFrac       = obj.Para.durFrac;
            durBaseline   = obj.Para.DurBaseline; 
            
            if nargin <= 2
                obj.Data.DataFileLocation  = obj.DataFileLocation; 
                load(obj.DataFileLocation, 'data')
            end
            
            % read
            if  isfield(data, 'Datasetup')
                obj.Data.dataSetup = data.Datasetup;% Electrode dimensions  
            else
                obj.Data.dataSetup = [];
            end
            [sign, chanNames]           = Core.ParaAndData.getSignal(data.x_bip ,data.lab_bip, chanContains);
            obj.Data.signal             = sign;
            obj.Data.channelNames       = chanNames;  
            obj.Data.sampFreq           = data.fs;  
            
            
            % intermediate values
            lenSig = length(obj.Data.signal);
            nbChan = length(obj.Data.channelNames);
            nbSamples = size(obj.Data.signal,1);
            fs =  obj.Data.sampFreq;
            sigdur = lenSig/fs;
            % computed
            obj.Data.maxIntervalToJoin  = maxToJoinPARA*fs;
            obj.Data.MinHighEntrIntvLen = MinHiEntrPARA*fs;
            obj.Data.minEventTime       = minETPARA*fs;
            obj.Data.sigDurTime         = sigdur;
            obj.Data.timeInterval       = [1, min([durFrac*sigdur, durBaseline])];
            obj.Data.nbChannels         = nbChan;
            obj.Data.nbSamples          = nbSamples;
        end
        
        %% Test detector parameters against data for consistency
        function [] = testParameters(obj)
            LowPass  = obj.Para.lowPass; 
            HighPass = obj.Para.highPass;
            if HighPass > LowPass
                warning(['Low pass frequency ' ,char(LowPass), ' must be higher than High pass frequency ', char(HighPass)])
            end
              
        end
        
    end
    methods(Static)
        function [signal, chanNames] = getSignal(x_bip, lab_bip, chanContains)
            maskChanContains = contains(lab_bip, chanContains);
            if min(size(x_bip)) == 1
                signal        = x_bip';
            else
                signal        = x_bip(maskChanContains ,:)';
            end
            chanNames = lab_bip(maskChanContains);
            
        end
    end
end