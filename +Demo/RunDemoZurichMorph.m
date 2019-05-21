clear
clc
%% Run Detector for Ripples
ParaPath = [pwd, '/+Demo/ZurichDemo1Morph/Parameters/RMorphPara.mat'];
DataPath = [pwd, '/+Demo/ZurichDemo1Morph/Data/Data.mat'];
Rhfo = Detections.getHFOdata(ParaPath, DataPath ,'morph' , false,3,'',true);
%% Run Detector for Fast Ripples
% ParaPath = [pwd, '\+Demo\ZurichDemo1Morph\Parameters\experimentalFRMorphPara.mat'];
ParaPath = [pwd, '/+Demo/ZurichDemo1Morph/Parameters/FRMorphPara.mat'];
DataPath = [pwd, '/+Demo/ZurichDemo1Morph/Data/Data.mat'];
FRhfo = Detections.getHFOdata(ParaPath, DataPath ,'morph' , false,3,'',true);
%% Obtain Fast Ripples that coOccure with ripples
CoOc = Core.CoOccurence;
CoOccuringEvents = CoOc.runCoOccurence(Rhfo, FRhfo, 0.8);
RandFRhfo = FRhfo;
RandFRhfo.Events = CoOccuringEvents;
%% Load previously obtiained results
resultPath = [pwd,'/+Demo/ZurichDemo1Morph/Reff/HFO_Analysis_Results_Patient_10_Recording_01_Interval_101.mat'];
Reff = Demo.Utility.loadZurichMorphReference(resultPath);
%%
Visualizations.VisualizeHFO(FRhfo,'filt',1,Rhfo)
%% Compare
if 0
% Filter Parameters
% Ripples
norm(Reff.FilterCoef.R - Rhfo.Para.FilterPara.bCoef)
% Fast Ripples
norm(Reff.FilterCoef.FR - FRhfo.Para.FilterPara.bCoef)
end
if 0
% Baseline 
Reff.Baseline
% Ripples
[Rhfo.baseline.baselineThr; Rhfo.baseline.FiltbaselineThr];
% Fast Ripples
[FRhfo.baseline.baselineThr; FRhfo.baseline.FiltbaselineThr]
end
if 0
% Envents
% Ripples don't match on event 28
HRStr = Rhfo.Events.Markings.start{1};
HREnd = Rhfo.Events.Markings.end{1};
%
RRStr = Reff.RipStart;
RREnd = Reff.RipEnd;
%
Demo.Utility.compareEventIntervals(RRStr, RREnd, HRStr, HREnd)
%
Visualizations.VisualizeHFO(Rhfo, 'filt')
% Fast Ripples
HFRStr = FRhfo.Events.Markings.start{1};
HFREnd = FRhfo.Events.Markings.end{1};
RFRStr = Reff.FastRipStart;
RFREnd = Reff.FastRipEnd;
%
Demo.Utility.compareEventIntervals(RFRStr, RFREnd, HFRStr, HFREnd)
% Visualization
Visualizations.VisualizeHFO(FRhfo, 'filt')
end

