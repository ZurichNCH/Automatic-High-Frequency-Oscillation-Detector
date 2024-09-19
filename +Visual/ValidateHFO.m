function [Markings_ToValidate_Out] = ValidateHFO(rhfo, frhfo, RFRhfo,  ValidationInterfaceParams, ImageSaveDir)
if nargin  == 4
   ImageSaveDir = [cd,'\Images\']; 
end
%% %%%%%%%%%%%%%% This comes from ECE
%%Paths
% strPaths.Main = '\\fl-daten\NCH_Forschungen\NCH_FL_Forschungsprojekte\Epilepsy\_Master Students\Katja Rutz\Intraoperative HFO Validation HD 2\';
% strPaths.HFOAnalysisResults = '\\fl-daten\NCH_Forschungen\NCH_FL_Forschungsprojekte\Epilepsy\_Master Students\Maxine Schreiber\HFO Analysis Results\HFO Analysis 1 Extracted Data Added Channels 190111\' ; % [strPaths.Main,'HFO Analysis Results\'];
% strPaths.Data = '\\fl-daten\NCH_Forschungen\NCH_FL_Forschungsprojekte\Epilepsy\_Master Students\Maxine Schreiber\Results\Extracted Data Added Channels\'; % [strPaths.Main,'Data\'];
% strPaths.HFOValidationResults = [strPaths.Main,'HFO Validation Results\'];
% strPaths.ImagesExamplesOfEvents = [strPaths.Main,'Examples of Events\'];
% addpath(genpath(strPaths.Main))

% File names for saving results

%% %%%%%%%%%%%%%%%%%
%% Markings for different HFO bands
if(isempty(rhfo))
    hfo{1} = [];
else
    hfo{1} = rhfo;
end
if(isempty(frhfo))
    hfo{2} = [];
else
    hfo{2} = frhfo;
end
if(isempty(RFRhfo))
    hfo{3} = [];
else
    hfo{3} = RFRhfo;
end
switch ValidationInterfaceParams.HFOType_ToValidate
    case 1
        evClass = 1;
    case 2
        evClass = [1 2];
    case 3
        evClass = [1 2 3];
end
fs = rhfo.Data.sampFreq;
Markings_ToPlot = {};
for iEventType = evClass
    Markings_ToPlot{iEventType} = getEventViewerMatrix(hfo{iEventType},fs);
    % Markings_ToPlot{iEventType} = Markings_ToPlot{iEventType}(1:50,:); % Plot first 50 events
end

%% Data input
dataAll = {};
for nChannel = 1:frhfo.Data.nbChannels
    dataAll{1}(nChannel,:)    = rhfo.Data.signal(:,nChannel)';
    dataAll{2}(nChannel,:)    = rhfo.filtSig.filtSignal(:,nChannel)';
    dataAll{3}(nChannel,:)    = frhfo.filtSig.filtSignal(:,nChannel)';
end

%% Validation GUI inputs
ValidationInterfaceParams.data = dataAll{1};
ValidationInterfaceParams.dataFiltered = dataAll(2:3);
ValidationInterfaceParams.fs = fs;
ValidationInterfaceParams.ElectrodeLabels = strrep(rhfo.Data.channelNames,'_','\_');
ValidationInterfaceParams.Markings_ToPlot = Markings_ToPlot;
ValidationInterfaceParams.strSaveImagesFolderPath = ImageSaveDir;
ValidationInterfaceParams.Markings_ToValidate = ValidationInterfaceParams.Markings_ToPlot{ValidationInterfaceParams.HFOType_ToValidate};
ValidationInterfaceParams.YShift = 350;

%% Run validation GUI
% ValidationInterfaceParams.Markings_ToPlot{1} = [];
% ValidationInterfaceParams.Markings_ToPlot{2} = [];
Markings_ToValidate_Out = ...
    HFO_Visualizer_190601(ValidationInterfaceParams);

end

function Markings = getEventViewerMatrix(hfo,fs)

Markings = [];
marks = hfo.Events.Markings;
for iChannel = 1:length(marks.start)
    nbEvents = length(marks.start{iChannel});
    
%     EventBlock = [ones(nbEvents,1)*iChannel,([marks.start{iChannel}',marks.end{iChannel}',marks.len{iChannel}']-1)/fs];
     try
    EventBlock = [ones(nbEvents,1)*iChannel,([marks.start{iChannel}',marks.end{iChannel}',marks.len{iChannel}']-1)/fs];
    catch
    EventBlock = [ones(nbEvents,1)*iChannel,([marks.start{iChannel},marks.end{iChannel},marks.len{iChannel}]-1)/fs];   
    end
    Markings  = [Markings; EventBlock];
end

end



