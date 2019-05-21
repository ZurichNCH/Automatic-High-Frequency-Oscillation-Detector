clear
clc
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Ripples %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load previously obtiained results
resultPath = [pwd,'/+Demo/ZurichDemo1Spec/Reference/RippleResults.mat'];
RReff = Demo.Utility.loadZurichSpecReference(resultPath, 'HFO_R');
%% Load parameters, data and previously obtained results for reference.
ParaPath = [pwd, '/+Demo/ZurichDemo1Spec/Parameters/RSpecPara.mat'];
DataPath = [pwd, '/+Demo/ZurichDemo1Spec/Data/Data.mat'];
Rhfo = Detections.getHFOdata(ParaPath, DataPath,'spec', true);
%% Comapare 
Demo.Utility.testDemoZurichSpec(RReff, Rhfo)
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Fast Ripples %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load previously obtiained results
resultPath = [pwd,'/+Demo/ZurichDemo1Spec/Reference/FastRippleResults.mat'];
FRReff = Demo.Utility.loadZurichSpecReference(resultPath, 'HFO_FR');
%% Load parameters, data and previously obtained results for reference.
ParaPath = [pwd, '/+Demo/ZurichDemo1Spec/Parameters/FRSpecPara.mat'];
DataPath = [pwd, '/+Demo/ZurichDemo1Spec/Data/Data.mat'];
FRhfo = Detections.getHFOdata(ParaPath, DataPath,'spec', true);
%% Comapare 
Demo.Utility.testDemoZurichSpec(FRReff, FRhfo)
%% View
Visualizations.VisualizeHFO(FRhfo,'filt',1:3,Rhfo)