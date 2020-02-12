function [ Markings_ToValidate_Out ] = ValidateHFO( rhfo, frhfo, RFRhfo, ValidationInterfaceParams )

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

fs = rhfo.Data.sampFreq;
Markings_ToPlot = {};
for iEventType = 1:3
    if(~isempty(hfo{iEventType}))
        Markings_ToPlot{iEventType} = getEventViewerMatrix(hfo{iEventType},fs);
    end
end

%% Data input
dataAll = {};
for nChannel = 1:frhfo.Data.nbChannels
    if(~isfield(VParams.FilterCoeff))
    dataAll{1}(nChannel,:)    = rhfo.Data.signal(:,nChannel)';
    dataAll{2}(nChannel,:)    = rhfo.filtSig.filtSignal(:,nChannel)';
    dataAll{3}(nChannel,:)    = frhfo.filtSig.filtSignal(:,nChannel)';
    else
        % Filter data TODO
        fprintf('\n\n\n')
        warning('Think about filtering!!!')
        fprintf('\n\n\n')
        dataAll{1}(nChannel,:)    = rhfo.Data.signal(:,nChannel)';
        dataAll{2}(nChannel,:)    = filtfilt(rhfo.Data.signal(:,nChannel),VParams.FilterCoeff.Rb,VParams.FilterCoeff.Ra)';
        dataAll{3}(nChannel,:)    = filtfilt(rhfo.Data.signal(:,nChannel),VParams.FilterCoeff.FRb,VParams.FilterCoeff.FRa)';
    end
end

%% Validation GUI inputs
ValidationInterfaceParams.data = dataAll{1};
ValidationInterfaceParams.dataFiltered = dataAll(2:3);
ValidationInterfaceParams.fs = fs;
ValidationInterfaceParams.ElectrodeLabels = strrep(rhfo.Data.channelNames,'_','\_');
ValidationInterfaceParams.Markings_ToPlot = Markings_ToPlot;
ValidationInterfaceParams.strSaveImagesFolderPath = [cd,'\Images\'];
ValidationInterfaceParams.Markings_ToValidate = ValidationInterfaceParams.Markings_ToPlot{ValidationInterfaceParams.HFOType_ToValidate};

%% Run validation GUI
if(isempty(ValidationInterfaceParams.Markings_ToValidate))
    Markings_ToValidate_Out = [];
else
    Markings_ToValidate_Out = ...
        HFO_Visualizer_190601(ValidationInterfaceParams);
end

end

function [ Markings ] = getEventViewerMatrix( hfo, fs )

Markings = [];
marks = hfo.RefinedEvents{1}.Markings;
for iChannel = 1:length(marks.start)
    nNumberOfEvents = length(marks.start{iChannel});
    EventBlock = [ones(nNumberOfEvents,1)*iChannel,([marks.start{iChannel}(:),marks.end{iChannel}(:),marks.len{iChannel}(:)]-1)/fs];
    Markings = [Markings;EventBlock];
end

end
