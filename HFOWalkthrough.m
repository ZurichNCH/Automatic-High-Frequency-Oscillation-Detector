% This script is created with the purpose of serving as tutorial on AHFOD
% start by clearing the work space and console

%% %%%%%%%%%%%%%%%%%%%%%%%% Basics %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
clc
%% Basic data-structure of this code is the hfo-object which is used as follows:
%create an hfo-object by calling the following:
hfo =  Core.HFO;
%% specify .mat-filepaths to parameters and data (see readme for format of these files)
hfo.ParaFileLocation = [pwd, '/+Demo/ZurichDemo1Spec/Parameters/RSpecPara.mat'];
% see the contents of the folder "PresetParameterCreator" for the format.
hfo.DataFileLocation = [pwd, '/+Demo/ZurichDemo1Spec/Data/Data.mat'];
% Data must be called "data" and must contain the following fields
% data.Datasetup
% data.x_bip 
% data.lab_bip
% data.fs
%% Load the parameters and data, this extracts relavant information from the
% above mentioned files to the hfo-object.
chanContains    = '';
hfo = getParaAndData(hfo, chanContains);%, data);
% data: optional imput to overide the file path, useful for running from
% work space. Must be in correct format.
%% This step produces filtered siganl based on specification given in the
% parameters file. The envelope of the filtered signal is also computed.
smoothBool = false;
hfo = getFilteredSignal(hfo, smoothBool);
% smoothBool: boolean value specifying if the envelope is to be smoothed.
%% Events are described in contradisticiton to the background which is
% defind by the baseline. This code computes the baseline using entropy.
hfo = getBasline(hfo); 
%% Events are detected by various means
RefType   = 'spec';
CondMulti = true;
hfo = getEvents(hfo, RefType, CondMulti);
% RefType: is a string value, either 'morph' or 'spec'
% CondMulti: is a boolean value that determines multi-channel analysis
%% Visualiye the HFO by calling
SigString = 'filt';
chanInd = [1,2,3];
Visualizations.VisualizeHFO(hfo, SigString, chanInd)
% SigString: is a string variable which is either: 'filt' or 'raw'
% chanInd: are the indeces of the channels from which to view the data
%% %%%%%%%%%%%%%%%%%%%%%%%% Wrapped %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
clc
%% The above can be collected in the following  wrapper:
ParaPath = [pwd, '\+Demo\ZurichDemo1Morph\Parameters\RMorphPara.mat'];
DataPath = [pwd, '\+Demo\ZurichDemo1Morph\Data\Data.mat'];
RefType         = 'morph'; 
CondMulti       = false;
AnalysisDepth   = 3;
chanContains    = '';
smoothBool      = true;
hfo = Detections.getHFOdata(ParaPath, DataPath ,RefType , CondMulti, AnalysisDepth ,chanContains, smoothBool);
% AnalysisDepth: 1: Load parmeters,Data and filter the signal.
%                2: Compute the baseline and associated values.
%                3: Find events of interest(hfo) and associated values.
SigString = 'raw';
Visualizations.VisualizeHFO(hfo, SigString)
%% %%%%%%%%%%%% Combining ripples and fast ripples %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
clc
%% Difference in ripples and fast ripples is that they are computed using different parameters.
rParaPath       = [pwd, '\+Demo\ZurichDemo1Morph\Parameters\RMorphPara.mat'];
frParaPath      = [pwd, '\+Demo\ZurichDemo1Morph\Parameters\FRMorphPara.mat'];
DataPath        = [pwd, '\+Demo\ZurichDemo1Morph\Data\Data.mat'];
RefType         = 'morph'; 
CondMulti       = false;
AnalysisDepth   = 3;
chanContains    = '';
smoothBool      = true;
ContThresh      = 0.8;
rhfo = Detections.getHFOdata(rParaPath, DataPath ,RefType , CondMulti, AnalysisDepth ,chanContains, smoothBool);
frhfo = Detections.getHFOdata(frParaPath, DataPath ,RefType , CondMulti, AnalysisDepth ,chanContains, smoothBool);
% what we do now is look to see which of the fast ripples are contained in
% ripples as the cooccurence of the two is a good predictor of the HFO area
CoOc = Core.CoOccurence;
CoOccuringEvents = CoOc.runCoOccurence(Rhfo, FRhfo, ContThresh);
Visualizations.VisualizeHFO(frhfo,'filt',1,rhfo)
%% %%%%%%%%%%%%%%%%%%%%%%%% Advanced %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Thee problem now is to run the detector over a set of data files and in
% doing so extract relavant summary statistics
% the 
PatNum = {'TEST' '02' '05' '07' '08' '09' '11' '14'};
RParaPath       = [pwd, '\+Demo\ZurichDemo1Morph\Parameters\RMorphPara.mat'];
FRParaPath      = [pwd, '\+Demo\ZurichDemo1Morph\Parameters\FRMorphPara.mat'];
RefType         = 'morph'; 
CondMulti       = false;
AnalysisDepth   = 3;
chanContains    = '';
smoothBool      = true;
ContThresh      = 0.8;
AnalysisType    = 'RipAndFRip';

for iFile = 2:length(PatNum)
    disp(['Currently running patient: ',num2str(PatNum{iFile})])
    DataDir  = ['E:\GENEVA\AnalizeHFO\LearningDataForMo\Pat',num2str(PatNum{iFile}),'\'];
    %% Run the detecor
    hfodet = Detections;
    hfodet = hfodet.setPDPaths(RParaPath, FRParaPath, DataDir);
    hfodet = hfodet.runDetector(RefType, CondMulti, AnalysisDepth, chanContains, smoothBool, AnalysisType, ContThresh);
    % Export the computed resutls in the form of .mat-files and .png
    hfodet.exportHFOsummary
end

