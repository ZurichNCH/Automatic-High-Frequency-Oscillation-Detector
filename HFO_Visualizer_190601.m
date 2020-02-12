function varargout = HFO_Visualizer_190601(varargin)
% HFO_VISUALIZER_190601 MATLAB code for HFO_Visualizer_190601.fig
%      HFO_VISUALIZER_190601, by itself, creates a new HFO_VISUALIZER_190601 or raises the existing
%      singleton*.
%
%      H = HFO_VISUALIZER_190601 returns the handle to a new HFO_VISUALIZER_190601 or the handle to
%      the existing singleton*.
%
%      HFO_VISUALIZER_190601('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HFO_VISUALIZER_190601.M with the given input arguments.
%
%      HFO_VISUALIZER_190601('Property','Value',...) creates a new HFO_VISUALIZER_190601 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before HFO_Visualizer_190601_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to HFO_Visualizer_190601_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help HFO_Visualizer_190601

% Last Modified by GUIDE v2.5 20-Aug-2019 12:58:10

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @HFO_Visualizer_190601_OpeningFcn, ...
    'gui_OutputFcn',  @HFO_Visualizer_190601_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before HFO_Visualizer_190601 is made visible.
function HFO_Visualizer_190601_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to HFO_Visualizer_190601 (see VARARGIN)

%% Initialize figure
Initialize_Main_Figure(hObject)

%% Freeze buttons
Obj_ToFreeze = [handles.pushbutton_next_event
    handles.pushbutton_prev_event
    handles.edit_jump_to_event
    handles.edit_yscale_raw
    handles.edit_yscale_filtered_1
    handles.edit_yscale_filtered_2
    handles.pushbutton_raw_zoom_in
    handles.pushbutton_raw_zoom_out
    handles.pushbutton_ripple_zoom_in
    handles.pushbutton_ripple_zoom_out];

set(Obj_ToFreeze,'Enable','off')

%% Read input parameters
InputParams = varargin{1};

%% Check inputs % TODO
PlotParams = Check_Input_Params(InputParams);

% PlotParams.Markings_ToPlot = InputParams.Markings_ToPlot;
% PlotParams.Markings_ToValidate = InputParams.Markings_ToValidate;
PlotParams.HFOType_ToValidate = InputParams.HFOType_ToValidate;
PlotParams.strSaveImagesFolderPath = InputParams.strSaveImagesFolderPath;

%% Put into handles
handles.PlotParams = PlotParams;

%% Initialize radio buttons
handles = Initialize_Radio_Buttons(handles);

%% Handles for axes % TODO for only one band being plotted
handles.axesMain = [handles.axes_raw,handles.axes_filtered_1,handles.axes_filtered_2];

%% Resize and delete axes if only 1 HFO band is plotted
if(length(handles.PlotParams.HFOBand_ToPlot)==1)
    nBand_ToDelete = setdiff([1,2],handles.PlotParams.HFOBand_ToPlot);
    Delete_HFOAxis(hObject,handles,nBand_ToDelete)
end

%% Set names of plots % TODO for only one band being plotted
handles.textbox_raw.String = 'Raw signal';
handles.textbox_raw.Position(1) = handles.axesMain(1).Position(1);
if(ismember(1,handles.PlotParams.HFOBand_ToPlot))
    handles.textbox_filtered_1.String = 'Ripple';
    handles.textbox_filtered_1.Position(1) = handles.axesMain(2).Position(1);
end
if(ismember(2,handles.PlotParams.HFOBand_ToPlot))
    handles.textbox_filtered_2.String = 'FR';
    handles.textbox_filtered_2.Position(1) = handles.axesMain(3).Position(1);
end

%% Plot signals for each band
for nBand_ToPlot = handles.PlotParams.SignalBand_ToPlot
    handles.nBand_ToPlot = nBand_ToPlot;
    handles = Plot_Signal_Single_Band(handles);
    handles = rmfield(handles,'nBand_ToPlot');
end

%% Remove electrode names for filtered signals
for nBand_ToPlot = setdiff(handles.PlotParams.SignalBand_ToPlot,1)
    for iChannel_ToPlot = 1:length(handles.axesSingleChannel{nBand_ToPlot})
        set(handles.axesSingleChannel{nBand_ToPlot},'YTickLabel',[])
    end
end

%% Event table % TODO % TODO % TODO
for nEventType_ToPlot = 1:3
    if(length(InputParams.Markings_ToPlot)>=nEventType_ToPlot)
        if(~isempty(InputParams.Markings_ToPlot{nEventType_ToPlot}))
            handles.MarkingsTable_ToPlot{nEventType_ToPlot} = array2table(InputParams.Markings_ToPlot{nEventType_ToPlot},'VariableNames',{'nChannel','tStart','tStop','tDuration'});
        else
            handles.MarkingsTable_ToPlot{nEventType_ToPlot} = [];
        end
    else
        handles.MarkingsTable_ToPlot{nEventType_ToPlot} = [];
    end
end
% Only events in selected channels
for nEventType_ToPlot = 1:3
    if(~isempty(handles.MarkingsTable_ToPlot{nEventType_ToPlot}))
        handles.MarkingsTable_ToPlot{nEventType_ToPlot} = ...
            handles.MarkingsTable_ToPlot{nEventType_ToPlot}(ismember(handles.MarkingsTable_ToPlot{nEventType_ToPlot}.nChannel,InputParams.ListOfChannels_ToPlot),:);
    else
        handles.MarkingsTable_ToPlot{nEventType_ToPlot} = [];
    end
end

%% Markings and signals to plot
handles.nSignalBand_nHFOType_Pairs_ToPlot = [1,1;1,2;1,3;2,1;2,3;3,2;3,3];
if(length(handles.PlotParams.HFOBand_ToPlot)==1) % TODO this could look better
    handles.nSignalBand_nHFOType_Pairs_ToPlot(handles.nSignalBand_nHFOType_Pairs_ToPlot(:,2)==3,:) = [];
    handles.nSignalBand_nHFOType_Pairs_ToPlot(~ismember(handles.nSignalBand_nHFOType_Pairs_ToPlot(:,2),...
        handles.PlotParams.HFOBand_ToPlot),:) = [];
end

%% Plot HFO for each band %% TODO use defaults for now, make option later
for iSignalBand_HFOType_Pair = 1:size(handles.nSignalBand_nHFOType_Pairs_ToPlot,1)
    handles.nBand_ToPlot = handles.nSignalBand_nHFOType_Pairs_ToPlot(iSignalBand_HFOType_Pair,1);
    handles.nHFOType_ToPlot = handles.nSignalBand_nHFOType_Pairs_ToPlot(iSignalBand_HFOType_Pair,2);
    
    % Plot signals
    handles = Plot_Events_Single_Band(handles);
    
    handles = rmfield(handles,'nHFOType_ToPlot');
    handles = rmfield(handles,'nBand_ToPlot');
end

%% Axes indication yShift
% TODO always update ylims of handles.axesMain(1) then update yscale axes
% also always update yshift in handles todo
handles.axesYScale(1) = handles.axes_yscale_raw; % TODO not always 3 axes used
if(ismember(1,handles.PlotParams.HFOBand_ToPlot))
    handles.axesYScale(2) = handles.axes_yscale_filtered_1;
end
if(ismember(2,handles.PlotParams.HFOBand_ToPlot))
    handles.axesYScale(3) = handles.axes_yscale_filtered_2;
end

handles.PlotParams.YUnit = '\muV';

handles.editYScale(1) = handles.edit_yscale_raw;
if(ismember(1,handles.PlotParams.HFOBand_ToPlot))
    handles.editYScale(2) = handles.edit_yscale_filtered_1;
end
if(ismember(2,handles.PlotParams.HFOBand_ToPlot))
    handles.editYScale(3) = handles.edit_yscale_filtered_2;
end

for nBand_ToPlot = handles.PlotParams.SignalBand_ToPlot
    % Adjust size of axis to give yShift/2
    handles.axesYScale(nBand_ToPlot).Position(4) = ...
        handles.axesMain(nBand_ToPlot).Position(4)/...
        ((length(handles.PlotParams.ListOfChannels_ToPlot)-1+sum(handles.PlotParams.YMargin))*2);
    % Invisible x-axis % TODO before in initialization
    handles.axesYScale(nBand_ToPlot).XColor = 'w';
    % No yticklabel % TODO before in initialization
    handles.axesYScale(nBand_ToPlot).YTick = [];
    handles.axesYScale(nBand_ToPlot).YTickLabel = [];
    % Put arrow on top of axis
    handles.arrowYScale(nBand_ToPlot) = annotation('doublearrow','Units','normalized',...
        'Position',[handles.axesYScale(nBand_ToPlot).Position(1:2),0,handles.axesYScale(nBand_ToPlot).Position(4)]);
    % Freeze text TODO this changes later
    handles.editYScale(nBand_ToPlot).Enable = 'off';
    handles.editYScale(nBand_ToPlot).Visible = 'on'; % TODO TODO TODO TODO
    % TODO change string properly
    handles.axesYScale(nBand_ToPlot).YLabel.String = handles.PlotParams.YUnit;
    handles.axesYScale(nBand_ToPlot).YLabel.Rotation = 0;
    handles.axesYScale(nBand_ToPlot).YLabel.HorizontalAlignment = 'right';
    % Indicate yShift as text % TODO change positions properly
    handles.editYScale(nBand_ToPlot).String{1} = num2str(handles.PlotParams.YShift(nBand_ToPlot));
    handles.editYScale(nBand_ToPlot).Position(1) = handles.axesYScale(nBand_ToPlot).Position(1)-0.09;
    handles.editYScale(nBand_ToPlot).Position(2) = ...
        handles.axesYScale(nBand_ToPlot).Position(2)+handles.axesYScale(nBand_ToPlot).Position(4)/2-handles.editYScale(nBand_ToPlot).Position(4)/2;
    handles.editYScale(nBand_ToPlot).HorizontalAlignment = 'right';
end

%% Initialize text
set(handles.MarkText,'String','Whole signal')

%% HFO markings to validate %% TODO enable taking as table, enable choding from 'Markings_ToPlot'
if(~isempty(InputParams.Markings_ToValidate))
    handles.Markings_ToValidate = array2table(InputParams.Markings_ToValidate,'VariableNames',{'nChannel','tStart','tStop','tDuration'});
    % Add columns for nEventValidity and strEventValidity
    handles.Markings_ToValidate.nEventValidity = NaN(size(handles.Markings_ToValidate,1),1);
    handles.Markings_ToValidate.strEventValidity = cell(size(handles.Markings_ToValidate,1),1);
    % Only events in selected channels
    handles.Markings_ToValidate = ...
        handles.Markings_ToValidate(ismember(handles.Markings_ToValidate.nChannel,InputParams.ListOfChannels_ToPlot),:);
    handles.nTotalNumberOfEvents = size(handles.Markings_ToValidate,1); % TODO
end

%% Initialize event count and center of time axis
handles.nEvent = 0;
handles.tMiddle = [];

%% Save image for whole signal
pushbutton_save_image_Callback(handles.pushbutton_save_image,[],handles)

%% Unfreeze buttons % TODO remove deleted objects from Obj_ToFreeze
for nObject = 1:length(Obj_ToFreeze)
    try
        set(Obj_ToFreeze(nObject),'Enable','on')
    catch
    end
end

%% Choose default command line output for HFO_Visualizer_190601
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% % UIWAIT makes HFO_Visualizer_190601 wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = HFO_Visualizer_190601_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get output from handles structure
varargout{1} = handles.Markings_ToValidate;

% The figure can be deleted now
delete(handles.figure1);


% --- Executes on button press in pushbutton_raw_zoom_out.
function pushbutton_raw_zoom_out_Callback(hObject, ~, handles)
% hObject    handle to pushbutton_raw_zoom_out (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Markings = handles.Markings;
nEvent = handles.nEvent;
EventStartTime    = Markings(nEvent,2);
EventStopTime     = Markings(nEvent,3);
MiddlePoint       = (EventStartTime+EventStopTime)/2;
handles.XMiddle = MiddlePoint;

%%
nNumberOfChannelsToPlot = length(handles.ListOfChannelsToPlot);

y_shiftRaw = handles.y_shiftRaw;
%%
ax1 = handles.ax1;
set(ax1(1),'Ylim',[-y_shiftRaw*nNumberOfChannelsToPlot,y_shiftRaw])
set(ax1(2),'Ylim',[-y_shiftRaw*nNumberOfChannelsToPlot,y_shiftRaw])

%%
xMiddle = handles.XMiddle;

xlimOld = get(ax1(1),'XLim');
xlimWidth = xlimOld(2)-xlimOld(1);
if(xlimWidth<5)
    set(ax1(1),'XLim',[xMiddle-2.5,xMiddle+2.5])
end
handles.ax1 = ax1;

handles.rr = [];

guidata(hObject,handles);


% --- Executes on button press in pushbutton_raw_zoom_in.
function pushbutton_raw_zoom_in_Callback(hObject, ~, handles)
% hObject    handle to pushbutton_raw_zoom_in (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Markings = handles.Markings;
nEvent = handles.nEvent;
EventStartTime    = Markings(nEvent,2);
EventStopTime     = Markings(nEvent,3);
MiddlePoint       = (EventStartTime+EventStopTime)/2;
handles.XMiddle = MiddlePoint;

%%
nNumberOfChannelsToPlot = length(handles.ListOfChannelsToPlot);

y_shiftRaw = handles.y_shiftRaw;

%%
ax1 = handles.ax1;
set(ax1(1),'Ylim',[-y_shiftRaw*nNumberOfChannelsToPlot,y_shiftRaw])
set(ax1(2),'Ylim',[-y_shiftRaw*nNumberOfChannelsToPlot,y_shiftRaw])

%%
xMiddle = handles.XMiddle;

%%
if(strcmpi(handles.strEventType,'ripple'))
    wLim_2 = 0.6;
elseif(strcmpi(handles.strEventType,'fast ripple'))
    wLim_2 = 0.3;
end
%%
% xlimOld = get(ax1(1),'XLim');
% xlimWidth = xlimOld(2)-xlimOld(1);
% if(xlimWidth>4)
set(handles.ax1(1),'XLim',[xMiddle-wLim_2,xMiddle+wLim_2])
% end
handles.ax1 = ax1;

guidata(hObject,handles);


% --- Executes on button press in pushbutton_ripple_zoom_out.
function pushbutton_ripple_zoom_out_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_ripple_zoom_out (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% button under  FAST Ripple "Zoom out"
% increase the ylim by factor 1.2
Markings = handles.Markings;
nEvent = handles.nEvent;
EventStartTime    = Markings(nEvent,2);
EventStopTime     = Markings(nEvent,3);
MiddlePoint       = (EventStartTime+EventStopTime)/2;
handles.XMiddle = MiddlePoint;

%%
nNumberOfChannelsToPlot = length(handles.ListOfChannelsToPlot);

y_shiftRipple = handles.y_shiftRipple;
%%
ax2 = handles.ax2;
set(ax2(1),'Ylim',[-y_shiftRipple*nNumberOfChannelsToPlot,y_shiftRipple])
set(ax2(2),'Ylim',[-y_shiftRipple*nNumberOfChannelsToPlot,y_shiftRipple])

%%
ax2 = handles.ax2;
xMiddle = handles.XMiddle;

xlimOld = get(ax2(1),'XLim');
xlimWidth = xlimOld(2)-xlimOld(1);
if(xlimWidth<0.4)
    set(ax2(1),'XLim',[xMiddle-0.3,xMiddle+0.3])
end
handles.ax2 = ax2;

guidata(hObject,handles);

% --- Executes on button press in pushbutton_ripple_zoom_in.
function pushbutton_ripple_zoom_in_Callback(hObject, ~, handles)
% hObject    handle to pushbutton_ripple_zoom_in (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% button under  FAST Ripple "Zoom out"
% decrease the ylim by factor 1.2

Markings = handles.Markings;
nEvent = handles.nEvent;
EventStartTime    = Markings(nEvent,2);
EventStopTime     = Markings(nEvent,3);
MiddlePoint       = (EventStartTime+EventStopTime)/2;
handles.XMiddle = MiddlePoint;

%%
nNumberOfChannelsToPlot = length(handles.ListOfChannelsToPlot);
y_shiftRipple = handles.y_shiftRipple;
%%
ax2 = handles.ax2;
set(ax2(1),'Ylim',[-y_shiftRipple*nNumberOfChannelsToPlot,y_shiftRipple])
set(ax2(2),'Ylim',[-y_shiftRipple*nNumberOfChannelsToPlot,y_shiftRipple])

%%
ax2 = handles.ax2;
xMiddle = handles.XMiddle;

xlimOld = get(ax2(1),'XLim');
xlimWidth = xlimOld(2)-xlimOld(1);
if(xlimWidth>0.4)
    set(ax2(1),'XLim',[xMiddle-0.15,xMiddle+0.15])
end
handles.ax2 = ax2;

guidata(hObject,handles);

% --- Executes on button press in pushbutton_prev_event.
function pushbutton_next_event_Callback(hObject, ~, handles)
% hObject    handle to pushbutton_prev_event (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If event number is valid, increase by 1 and update figure
if(handles.nEvent<handles.nTotalNumberOfEvents)
    handles.nEvent = handles.nEvent+1;
    
    % Display single event
    handles = Display_Single_Event(handles);
    
    % Update title
    handles = Display_Single_Event_Title(handles);
    
    % Update handles for event validity
    handles = Update_Radio_Button_Event_Validity(handles);
end

guidata(hObject,handles);


% --- Executes on button press in pushbutton_prev_event.
function pushbutton_prev_event_Callback(hObject, ~, handles)
% hObject    handle to pushbutton_prev_event (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If event number is valid, increase by 1 and update figure
if(handles.nEvent>1)
    handles.nEvent = handles.nEvent-1;
    
    % Display single event
    handles = Display_Single_Event(handles);
    
    % Update title
    handles = Display_Single_Event_Title(handles);
    
    % Update handles for event validity
    handles = Update_Radio_Button_Event_Validity(handles);
end


guidata(hObject,handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, ~, ~)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end


% --- Executes when selected object is changed in uibuttongroup1.
function uibuttongroup1_SelectionChangedFcn(~, ~, ~)
% hObject    handle to the selected object in uibuttongroup1
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% class = get(handles.uibuttongroup1.SelectedObject,'Tag');
% handles.ClassifiedVisually(handles.current_event) = str2double(class(end));

% guidata(hObject,handles);


function edit_jump_to_event_Callback(hObject, ~, handles)
% hObject    handle to edit_jump_to_event (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_jump_to_event as text
%        str2double(get(hObject,'String')) returns contents of edit_jump_to_event as a double

% Event to go to
nEvent = str2double(get(handles.edit_jump_to_event,'String'));

% If event number is valid, increase by 1 and update figure
if((nEvent>=1)&&(nEvent<=handles.nTotalNumberOfEvents))
    handles.nEvent = nEvent;
    
    % Display single event
    handles = Display_Single_Event(handles);
    
    % Update title
    handles = Display_Single_Event_Title(handles);
    
    % Update handles for event validity
    handles = Update_Radio_Button_Event_Validity(handles);
end


guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
% function ReverseButton_CreateFcn(~, ~, ~)
% hObject    handle to ReverseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called




function [handles] = Display_Single_Event(handles)

% Plot parametrs
PlotParams = handles.PlotParams;

% Channel for event
nChannel = handles.Markings_ToValidate(handles.nEvent,:).nChannel;
iChannel = find(PlotParams.ListOfChannels_ToPlot==nChannel);

tStart = handles.Markings_ToValidate(handles.nEvent,:).tStart;
tStop = handles.Markings_ToValidate(handles.nEvent,:).tStop;
tMiddle = mean([tStart,tStop]);

% Change x-axis limits of subplots
for iBand_ToPlot = 1:length(PlotParams.SignalBand_ToPlot)
    nBand_ToPlot = PlotParams.SignalBand_ToPlot(iBand_ToPlot);
    tWindow = PlotParams.tWindow(nBand_ToPlot);
    set(handles.axesSingleChannel{nBand_ToPlot}(1),'XLim',tMiddle+tWindow*[-1,1])
end

% Reset y-axis limits of subplots
% YLimit for each axis
for iBand_ToPlot = 1:length(PlotParams.SignalBand_ToPlot)
    nBand_ToPlot = PlotParams.SignalBand_ToPlot(iBand_ToPlot);
    YLim_Ax = [-(PlotParams.YMargin(2)+length(PlotParams.ListOfChannels_ToPlot)-1),...
        PlotParams.YMargin(1)]*PlotParams.YShift(nBand_ToPlot);
    set(handles.axesSingleChannel{nBand_ToPlot}(1),'YLim',YLim_Ax) % TODO for changing ylim
end

% Save values
handles.tMiddle = tMiddle;

% Add marking around event
for iBand_ToPlot = 1:length(PlotParams.SignalBand_ToPlot)
    nBand_ToPlot = PlotParams.SignalBand_ToPlot(iBand_ToPlot);
    % Shift in y-axis
    YShift_SingleChannel = -(iChannel-1)*PlotParams.YShift(nBand_ToPlot);
end

%% Delete all rectangles
% axes(handles.axes_filtered_1)
% chldrn = get(gca,'Children');
%
% for ii = 1:length(chldrn)
%     if(strcmpi(chldrn(ii).Type,'rectangle'))
%         delete(chldrn(ii))
%     end
% end

%%
% handles.rr = rectangle('Position',[MiddlePoint-wRipple,center_point-y_shiftRipple/2,2*wRipple,y_shiftRipple]);
% handles.rr.EdgeColor = 'm';
% handles.rr.LineWidth = 2.5;


% --- Executes when selected object is changed in uipanel1.
function uipanel1_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel1
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

if(handles.nEvent~=0)
    nChild = find([handles.uipanel1.Children.Value]);
    strEventValidity = handles.uipanel1.Children(nChild).String;
    nEventValidity = find(strcmpi(handles.strEventValidityOptions,strEventValidity));
    
    handles.Markings_ToValidate(handles.nEvent,:).nEventValidity = nEventValidity;
    handles.Markings_ToValidate(handles.nEvent,:).strEventValidity{1} = strEventValidity;
end

guidata(hObject,handles);


function [handles] = Update_Radio_Button_Event_Validity(handles)

% Event number
nEvent = handles.nEvent;

% Validty for current event
nEventValidity = handles.Markings_ToValidate(nEvent,:).nEventValidity;

% If an event is seen for the first time, set strEventValidity to 'Unknown'
% Default option to show is 'Uncertain'
if(isnan(nEventValidity))
    nEventValidity = 7;
    handles.Markings_ToValidate(nEvent,:).nEventValidity = nEventValidity;
    handles.Markings_ToValidate(nEvent,:).strEventValidity{1} = handles.strEventValidityOptions{nEventValidity};
end
strEventValidity = handles.strEventValidityOptions{nEventValidity};
nChild = strcmpi({handles.uipanel1.Children.String},strEventValidity);
handles.uipanel1.Children(nChild).Value = 1;


% --- Executes on button press in pushbutton_close.
function pushbutton_close_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(handles.gui)


% --- Executes on button press in pushbutton_save_image.
function pushbutton_save_image_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_save_image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB

nEvent = handles.nEvent;
strSaveImagesFolderPath = handles.PlotParams.strSaveImagesFolderPath;

if(~exist(strSaveImagesFolderPath,'dir'))
    mkdir(strSaveImagesFolderPath)
end

if(nEvent==0)
    strFormatImageFileName = 'Whole_Signal';
    strImageFileName = sprintf(strFormatImageFileName);
else
    strFormatImageFileName = 'Event_Ripple_%.4d';
    strImageFileName = sprintf(strFormatImageFileName,nEvent);
end

set(handles.figure1,'PaperPositionMode','auto')
saveas(handles.figure1,[strSaveImagesFolderPath,strImageFileName],'png');
% export_fig(fig,[strSaveImagesFolderName,strImageFileName,'.','png'],['-','png'],'-transparent','-r100')


guidata(hObject, handles);






function [handles] = Initialize_Radio_Buttons(handles)

switch handles.PlotParams.HFOType_ToValidate % TODO
    case 1
        set(handles.radiobutton_ripple,'String','Ripple')
        set(handles.radiobutton_ripple_on_spike,'String','Ripple on spike')
    case 2
        set(handles.radiobutton_ripple,'String','Fast ripple')
        set(handles.radiobutton_ripple_on_spike,'String','Fast ripple on spike')
    case 3
        set(handles.radiobutton_ripple,'String','FRandR')
        set(handles.radiobutton_ripple_on_spike,'String','FRandR on spike')
end

% String values for radio buttons % TODO make available as input, also make
% sure button values match
% The order of strings indicates number values for buttons
strEventValidityOptions = {get(handles.radiobutton_ripple,'String')
    get(handles.radiobutton_ripple_on_spike,'String')
    'Spike'
    'Muscle activity'
    'Eye movements'
    'Artifact'
    'Uncertain'};

handles.strEventValidityOptions = strEventValidityOptions;


function [handles] = Plot_Signal_Single_Band(handles)

% Band to plot
nBand_ToPlot = handles.nBand_ToPlot;
% Main axis for the band
axMain = handles.axesMain(nBand_ToPlot);
% Plot parameters
PlotParams = handles.PlotParams;

% Make the main axis invisible
axMain.Visible = 'off';

% Clear previously created axes
if(isfield(handles,'axSingleChannel'))
    if(length(handles.axesSingleChannel)>=nBand_ToPlot)
        delete(handles.axesSingleChannel{nBand_ToPlot})
    end
end
% Plot multiple axes on top of the main axis
axSingleChannel = zeros(length(PlotParams.ListOfChannels_ToPlot),1);
for iChannel_ToPlot = 1:length(PlotParams.ListOfChannels_ToPlot)
    % Create axis
    axSingleChannel(iChannel_ToPlot) = axes('Units','Normalized','Position',axMain.Position);
    % No axis color
    set(axSingleChannel(iChannel_ToPlot),'Color','none')
    % No x-axis tick marks except for one of the axis
    if(iChannel_ToPlot~=1)
        set(axSingleChannel(iChannel_ToPlot),'XTick',[])
    end
end
% Fix x and y limits
linkaxes(axSingleChannel,'xy')

% YLimit for each axis
YLim_Ax = [-(PlotParams.YMargin(2)+length(PlotParams.ListOfChannels_ToPlot)-1),...
    PlotParams.YMargin(1)]*PlotParams.YShift(nBand_ToPlot);
% Plot color %% TODO
strPlotColor = 'k';

%% Plot signals with a y-shift for each axis
plSingleChannel = zeros(length(PlotParams.ListOfChannels_ToPlot),1);
for iChannel_ToPlot = 1:length(PlotParams.ListOfChannels_ToPlot)
    nChannel = PlotParams.ListOfChannels_ToPlot(iChannel_ToPlot);
    axes(axSingleChannel(iChannel_ToPlot))
    cla(axSingleChannel(iChannel_ToPlot))
    
    % Shift the signal
    YShift_SingleChannel = -(iChannel_ToPlot-1)*PlotParams.YShift(nBand_ToPlot);
    
    % Remove offset for raw signal
    if(nBand_ToPlot==1)
        PlotParams.dataAll{nBand_ToPlot}(nChannel,:) = PlotParams.dataAll{nBand_ToPlot}(nChannel,:)-mean(PlotParams.dataAll{nBand_ToPlot}(nChannel,:));
    end
    
    % Plot signal
    plSingleChannel(iChannel_ToPlot) = plot(PlotParams.t,PlotParams.dataAll{nBand_ToPlot}(nChannel,:)+YShift_SingleChannel,strPlotColor);
    hold on
    
    % Y-Axis ticks and labels %% TODO for too long labels
    strLabel = PlotParams.ElectrodeLabels{nChannel};
    strLabel = strrep(strLabel,'_','\_');
    strLabel = strrep(strLabel,'\\_','\_');
    set(axSingleChannel(iChannel_ToPlot),'YTick',YShift_SingleChannel)
    set(axSingleChannel(iChannel_ToPlot),'YTickLabel',strLabel)
    
    % No axis color
    set(axSingleChannel(iChannel_ToPlot),'Color','none')
    % Tick directions
    set(axSingleChannel(iChannel_ToPlot),'TickDir','out')
    
    % Grids
    grid on
    grid minor
end

% Xlimit
set(axSingleChannel(end),'XLim',[0,PlotParams.t(end)])
% YLimit
set(axSingleChannel(end),'YLim',YLim_Ax)

% Save handles for the axes for channels and plots
handles.axesSingleChannel{nBand_ToPlot} = axSingleChannel;
handles.plotsSingleChannel{nBand_ToPlot} = plSingleChannel;


function [handles] = Plot_Events_Single_Band(handles)

nHFOType_ToPlot = handles.nHFOType_ToPlot;
nBand_ToPlot = handles.nBand_ToPlot;
PlotParams = handles.PlotParams;

% Markings
Markings_ToPlot = handles.MarkingsTable_ToPlot{nHFOType_ToPlot};

if(isempty(Markings_ToPlot))
%     return;
end

% Plot properties
nPlotColor = PlotParams.nPlotColors_EventType{nHFOType_ToPlot};
strLineStyle = '-'; % TODO different color for different event types

plEvent = {};
for iChannel_ToPlot = 1:length(PlotParams.ListOfChannels_ToPlot)
    nChannel = PlotParams.ListOfChannels_ToPlot(iChannel_ToPlot);
    if(~isempty(Markings_ToPlot))
        Markings_SingleChannel_ToPlot = Markings_ToPlot(Markings_ToPlot.nChannel==nChannel,:);
    else
        Markings_SingleChannel_ToPlot = [];
    end
    
    axes(handles.axesSingleChannel{nBand_ToPlot}(iChannel_ToPlot))
    
    % Shift the signal
    YShift_SingleChannel = -(iChannel_ToPlot-1)*PlotParams.YShift(nBand_ToPlot);
    
    % Plot each event
    plEvent{iChannel_ToPlot} = zeros(size(Markings_SingleChannel_ToPlot,1),1);
    for nEvent = 1:size(Markings_SingleChannel_ToPlot,1)
        % Time of the event
        tStart = Markings_SingleChannel_ToPlot(nEvent,:).tStart;
        tStop = Markings_SingleChannel_ToPlot(nEvent,:).tStop;
        tStop = min(tStop,PlotParams.t(end));
        % Indices of the event
        [~,indStart] = min(abs((PlotParams.t-tStart)));
        [~,indStop] = min(abs((PlotParams.t-tStop)));
        indStart = ceil(indStart);
        indStop = ceil(indStop);
        
        plEvent{iChannel_ToPlot}(nEvent) = ...
            plot(PlotParams.t(indStart:indStop),PlotParams.dataAll{nBand_ToPlot}(nChannel,indStart:indStop)+YShift_SingleChannel,...
            'Color',nPlotColor,'LineStyle',strLineStyle);
    end
end

% No axis color
for iChannel_ToPlot = 1:length(PlotParams.ListOfChannels_ToPlot)
    set(handles.axesSingleChannel{nBand_ToPlot}(iChannel_ToPlot),'Color','none')
end

% Save handles for the axes for channels and plots
handles.plEvent{nBand_ToPlot,nHFOType_ToPlot} = plEvent;


function [PlotParams] = Check_Input_Params(InputParams)

% Raw signal
if(~isfield(InputParams,'data'))
    error('Raw signal ''data'' must be an input!')
end
% Check size of raw signal
siz = size(InputParams.data);
if(siz(2)<siz(1))
    error('Size of ''data'' must be (number of channels)x(number of samples)!')
end
% Assign input signal
PlotParams.data = InputParams.data;

% Sampling frequency
if(~isfield(InputParams,'fs'))
    error('What is the sampling frequency?')
end
PlotParams.fs = InputParams.fs;

% Time axis
if(isfield(InputParams,'t'))
    if(length(InputParams.t)~=size(PlotParams.data))
        error('Sizes of input signal and time axis do not match!')
    end
    PlotParams.t = InputParams.t;
else
    PlotParams.t = 0:1/PlotParams.fs:(size(PlotParams.data,2)-1)/PlotParams.fs;
end

% Electrode labels
if(isfield(InputParams,'ElectrodeLabels'))
    PlotParams.ElectrodeLabels = InputParams.ElectrodeLabels;
else
    PlotParams.ElectrodeLabels = cellfun(@num2str,num2cell((1:size(InputParams.data,1))',ones(size(InputParams.data,1),1),1),'UniformOutput',0);
end

% HFO bands to plot
strInputBandNames = {{'ripple'},{'fastripple','FR'}};
strInputBandNames = cellfun(@lower,strInputBandNames,'UniformOutput',0);
if(isfield(InputParams,'HFOBand_ToPlot'))
    if(isnumeric(InputParams.HFOBand_ToPlot))
        if(find(~ismember(InputParams.HFOBand_ToPlot,[1,2])))
            error('Specified band can take the values: 1 (ripple) or 2 (fast ripple)')
        end
        PlotParams.HFOBand_ToPlot = InputParams.HFOBand_ToPlot;
    elseif(ischar(InputParams.HFOBand_ToPlot))
        InputParams.HFOBand_ToPlot = lower(InputParams.HFOBand_ToPlot);
        InputParams.HFOBand_ToPlot = strrep(InputParams.HFOBand_ToPlot,' ','');
        if(find(~ismember(strrep(lower(InputParams.HFOBand_ToPlot),' ',''),[strInputBandNames{:}])))
            error('Specified band can take the values: ''ripple'',''FR'',''Fast Ripple''')
        end
        switch InputParams.HFOBand_ToPlot
            case strInputBandNames{1}
                PlotParams.HFOBand_ToPlot = 1;
            case strInputBandNames{2}
                PlotParams.HFOBand_ToPlot = 2;
        end
    elseif(iscell(InputParams.HFOBand_ToPlot))
        InputParams.HFOBand_ToPlot = lower(InputParams.HFOBand_ToPlot);
        InputParams.HFOBand_ToPlot = strrep(InputParams.HFOBand_ToPlot,' ','');
        if(find(~ismember(InputParams.HFOBand_ToPlot,[strInputBandNames{:}])))
            error('Specified band can take the values: ''ripple'',''FR'',''Fast Ripple''')
        end
        PlotParams.HFOBand_ToPlot = find(cellfun(@(x) ~isempty(find(x,1)),cellfun(@(x) ismember(x,InputParams.HFOBand_ToPlot),strInputBandNames,'UniformOutput',0)));
    end
else
    % Default is raw signal, signal in ripple band and signal in FR band
    PlotParams.HFOBand_ToPlot = [1,2];
end

% Signal bands to plot
PlotParams.SignalBand_ToPlot = [1,PlotParams.HFOBand_ToPlot+1];

% Filter coefficients
% Needed only if the filtered signal is not provided for all bands to be plotted
cond1 = isfield(InputParams,'dataFiltered'); % Filtered signal is an input
if(cond1)
    cond2 = isempty(find(cellfun(@isempty,InputParams.dataFiltered(PlotParams.HFOBand_ToPlot)),1)); % Filtered signal given for all bands to plot
    cond3 = isempty(find(~cellfun(@(x) isequal(size(x),size(PlotParams.data)),InputParams.dataFiltered(PlotParams.HFOBand_ToPlot),'UniformOutput',1),1)); % Filtered signal has the same size as raw signal
else
    cond2 = 0;
    cond3 = 0;
end
condLoadCoefficients = ~(cond1&&cond2&&cond3);
if(condLoadCoefficients)
    % File name to load filter coefficients
    if(isfield(InputParams,'FilterCoeffFilePath'))
        PlotParams.FilterCoeffFilePath = InputParams.FilterCoeffFilePath;
    else
        PlotParams.FilterCoeffFilePath = 'FIR_2kHz';
    end
    if(isfield(InputParams,'FilterCoeff'))
        if(isempty(InputParams.FilterCoeff)) % Load default if empty
            FilterCoeff = load(PlotParams.FilterCoeffFilePath);
            FilterCoeff = FilterCoeff.filter;
        else
            FilterCoeff = InputParams.FilterCoeff;
        end
    else % Load default if empty
        FilterCoeff = load('FIR_2kHz');
        FilterCoeff = FilterCoeff.filter;
    end
    % Check loaded coefficients
    if(isempty(find(~isfield(FilterCoeff,{'Rb','Ra','FRb','FRa'}),1)))
        PlotParams.FilterCoeff{1}.b = FilterCoeff.Rb;
        PlotParams.FilterCoeff{1}.a = FilterCoeff.Ra;
        PlotParams.FilterCoeff{2}.b = FilterCoeff.FRb;
        PlotParams.FilterCoeff{2}.a = FilterCoeff.FRa;
    else
        % Check whether it is in the cell format
        try
            cond1 = isempty(find(~cellfun(@(x) isempty(find(~x,1)),cellfun(@(x) isfield(x,{'a','b'}),FilterCoeff(PlotParams.HFOBand_ToPlot),'UniformOutput',0),'UniformOutput',1),1));
        catch
            error('Provided filter does not have the right format')
        end
        if(~cond1)
            error('Provided filter does not have the right format')
        end
        PlotParams.FilterCoeff = FilterCoeff;
    end
else
    FilterCoeff = [];
end

% Filtered signal
condFilterSignal = zeros(max(PlotParams.HFOBand_ToPlot),1);
if(isfield(InputParams,'dataFiltered')) % Filtered signal is an input
    if(isempty(find(ismember(find(cellfun(@isempty,InputParams.dataFiltered)),PlotParams.HFOBand_ToPlot),1))) % Filtered signal given for all bands to plot
        for nHFOBand = PlotParams.HFOBand_ToPlot
            PlotParams.dataFiltered{nHFOBand} = InputParams.dataFiltered{nHFOBand};
        end
    else % Filtered signal not given for all bands to plot
        for nHFOBand = PlotParams.HFOBand_ToPlot
            if(nHFOBand<=length(InputParams.dataFiltered))
                if(~isempty(InputParams.dataFiltered{nHFOBand})) % Filtered signal given for this band
                    % Check size of filtered signal
                    if(~isequal(size(InputParams.dataFiltered{nHFOBand}),size(PlotParams.data)))
                        error('Sizes of input raw and filtered signals do not match!')
                    end
                    PlotParams.dataFiltered{nHFOBand} = InputParams.dataFiltered{nHFOBand};
                else % Filtered signal is not an input, filter using default or input coefficients
                    condFilterSignal(nHFOBand) = 1;
                end
            else
                condFilterSignal(nHFOBand) = 1;
            end
        end
    end
else % Filter signal
    for nHFOBand = PlotParams.HFOBand_ToPlot
        condFilterSignal(nHFOBand) = 1;
    end
end
% Filter in bands that are not given
for nHFOBand = PlotParams.HFOBand_ToPlot
    if(condFilterSignal(nHFOBand))
        b = PlotParams.FilterCoeff{nHFOBand}.b;
        a = PlotParams.FilterCoeff{nHFOBand}.a;
        PlotParams.dataFiltered{nHFOBand} = filtfilt(b,a,PlotParams.data')';
    end
end

% Shift in y-axis for plots
% Default values
yShiftRaw = 1000;
yShiftFiltered = [20,10];
if(isfield(InputParams,'YShift')) % Shift in y-axis given for raw signal and filtered signal
    if(length(InputParams.YShift)>=(max(PlotParams.HFOBand_ToPlot)+1)) % Sufficiently many values provided for yShift
        PlotParams.YShift = InputParams.YShift;
    elseif(length(InputParams.YShift)==(length(PlotParams.HFOBand_ToPlot)+1)) % Sufficienlty many values provided for yShift
        PlotParams.YShift(1) = InputParams.YShift(1);
        for nHFOBand = PlotParams.HFOBand_ToPlot
            PlotParams.YShift(nHFOBand+1) = InputParams.YShift(find(PlotParams.HFOBand_ToPlot==nHFOBand)+1);
        end
        % Missing values for yShift
        for nHFOBand = setdiff(1:length(yShiftFiltered),PlotParams.HFOBand_ToPlot)
            PlotParams.YShift(nHFOBand+1) = yShiftFiltered(nHFOBand);
        end
    elseif(length(InputParams.YShift)<(length(PlotParams.HFOBand_ToPlot)+1)) % Sufficiently many values not provided
        if(isempty(InputParams.YShift)) % No value provided, take the defaults
            InputParams.YShift = [yShiftRaw,yShiftFiltered];
        elseif(length(InputParams.YShift)==1) % Only value for raw signal provided
            PlotParams.YShift(1) = InputParams.YShift(1);
            PlotParams.YShift(2:3) = yShiftFiltered;
        else % Values for some filtered signals provided %% TODO
            PlotParams.YShift(1) = InputParams.YShift(1);
            PlotParams.YShift(PlotParams.SignalBand_ToPlot(1:(length(InputParams.YShift)-1))) = InputParams.YShift(2:end);
            PlotParams.YShift(PlotParams.SignalBand_ToPlot(end)) = yShiftFiltered(end);
        end
    end
else % Shift in y-axis not given
    PlotParams.YShift = [yShiftRaw,yShiftFiltered];
end

% Time window for plots
% Default values
tWindowRaw = 1.6;
tWindowFiltered = [0.3,0.3];
if(isfield(InputParams,'tWindow')) % Shift in y-axis given for raw signal and filtered signal
    if(length(InputParams.tWindow)>=(max(PlotParams.HFOBand_ToPlot)+1)) % Sufficiently many values provided for tWindow
        PlotParams.tWindow = InputParams.tWindow;
    elseif(length(InputParams.tWindow)==(length(PlotParams.HFOBand_ToPlot)+1)) % Sufficienlty many values provided for tWindow
        PlotParams.tWindow(1) = InputParams.tWindow(1);
        for nHFOBand = PlotParams.HFOBand_ToPlot
            PlotParams.tWindow(nHFOBand+1) = InputParams.tWindow(find(PlotParams.HFOBand_ToPlot==nHFOBand)+1);
        end
        % Missing values for tWindow
        for nHFOBand = setdiff(1:length(tWindowFiltered),PlotParams.HFOBand_ToPlot)
            PlotParams.tWindow(nHFOBand+1) = tWindowFiltered(nHFOBand);
        end
    elseif(length(InputParams.tWindow)<(length(PlotParams.HFOBand_ToPlot)+1)) % Sufficiently many values not provided
        if(isempty(InputParams.tWindow)) % No value provided, take the defaults
            InputParams.tWindow = [tWindowRaw,tWindowFiltered];
        elseif(length(InputParams.tWindow)==1) % Only value for raw signal provided
            PlotParams.tWindow(1) = InputParams.tWindow(1);
            PlotParams.tWindow(2:3) = tWindowFiltered;
        else % Values for some filtered signals provided %% TODO
            PlotParams.tWindow(1) = InputParams.tWindow(1);
            PlotParams.tWindow(PlotParams.SignalBand_ToPlot(1:(length(InputParams.tWindow)-1))) = InputParams.tWindow(2:end);
            PlotParams.tWindow(PlotParams.SignalBand_ToPlot(end)) = tWindowFiltered(end);
        end
    end
else % Shift in y-axis not given
    PlotParams.tWindow = [tWindowRaw,tWindowFiltered];
end

% List of channels to plot
if(isfield(InputParams,'ListOfChannels_ToPlot')) % List of channels to plot given
    if(isnumeric(InputParams.ListOfChannels_ToPlot)) % Numbers of channels given
        PlotParams.ListOfChannels_ToPlot = InputParams.ListOfChannels_ToPlot;
    elseif(iscell(InputParams.ListOfChannels_ToPlot)) % Names of channels given
        [~,ind1,ind2] = intersect(PlotParams.ElectrodeLabels(:),InputParams.ListOfChannels_ToPlot(:));
        [~,indSort] = sort(ind2);
        PlotParams.ListOfChannels_ToPlot = ind1(indSort)';
    else % Input not understood, use default
        warning('List of channels to plot not given in correct format')
        PlotParams.ListOfChannels_ToPlot = 1:size(PlotParams.data,1);
    end
else
    PlotParams.ListOfChannels_ToPlot = 1:size(PlotParams.data,1);
end

% Margins in the y-axes above and below
if(isfield(InputParams,'YMargin')) % List of channels to plot given
    PlotParams.YMargin = InputParams.YMargin;
else % Use the default values
    PlotParams.YMargin = [1,1];
end

% Signals in different bands together
PlotParams.dataAll{1} = PlotParams.data;
for nHFOBand = PlotParams.HFOBand_ToPlot
    PlotParams.dataAll{nHFOBand+1} = PlotParams.dataFiltered{nHFOBand};
end

% Signal offset % TODO
% Default is removal of mean
strDetrendRawSignalMethod = 'RemoveMean';
if(isfield(InputParams,'DetrendRawSignalMethod'))
    switch(InputParams.DetrendRawSignalMethod)
        case 'RemoveMean'
            PlotParams.DetrendRawSignalMethod = strDetrendRawSignalMethod;
            nBand_ToPlot = 1;
            for nChannel = 1:size(PlotParams.dataAll{nBand_ToPlot},1)
                PlotParams.dataAll{nBand_ToPlot}(nChannel,:) = ...
                    PlotParams.dataAll{nBand_ToPlot}(nChannel,:)-mean(PlotParams.dataAll{nBand_ToPlot}(nChannel,:));
            end
        otherwise
            error('Unknown detrending method')
    end
else
    PlotParams.DetrendRawSignalMethod = strDetrendRawSignalMethod;
    nBand_ToPlot = 1;
    for nChannel = 1:size(PlotParams.dataAll{nBand_ToPlot},1)
        PlotParams.dataAll{nBand_ToPlot}(nChannel,:) = ...
            PlotParams.dataAll{nBand_ToPlot}(nChannel,:)-mean(PlotParams.dataAll{nBand_ToPlot}(nChannel,:));
    end
end

% Plot colors %% TODO default for now  % TODO different color for different event types
PlotParams.nPlotColors_EventType = {[0,0,1];[0,1,1];[1,0,0]}; % Default :'b','c','r'


function [handles] = Display_Single_Event_Title(handles)

set(handles.MarkText,'String',sprintf('Channel %d - %s - Event %d/%d',handles.Markings_ToValidate(handles.nEvent,:).nChannel,...
    handles.PlotParams.ElectrodeLabels{handles.Markings_ToValidate(handles.nEvent,:).nChannel},...
    handles.nEvent,handles.nTotalNumberOfEvents));


function [MonitorPosition, nNumberOfMonitors] = Get_Monitor_Positions_Pixels()

% Get display positions
MonitorPosition = get(0,'MonitorPositions');
% Number of displays
nNumberOfMonitors = size(MonitorPosition,1);


function Make_Fullscreen_Figure_Selected_Monitor(nMonitor, hObject)

% Get display positions
[MonitorPosition,nNumberOfMonitors] = Get_Monitor_Positions_Pixels();

% Do nothing if nMonitor > nNumberOfMonitors
nMonitor = min(nNumberOfMonitors,nMonitor);

% Position of selected display
DisplayPosition = MonitorPosition(nMonitor,:);

% Set figure size to fullscreen in the chosen monitor
set(hObject,'Outerposition',DisplayPosition)

% Make sure that is actually fullscreen
FigureJavaFrame = get(hObject,'JavaFrame');
pause(1);
set(FigureJavaFrame,'Maximized',1);


guidata(hObject);


function Initialize_Main_Figure(hObject)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Visible figure
hObject.Visible = 'on';
% Display menubar and toolbar
hObject.MenuBar = 'figure';
hObject.ToolBar = 'figure';
% Pixels as units
hObject.Units = 'pixels';

% Get display positions
[~,nNumberOfMonitors] = Get_Monitor_Positions_Pixels();

% Display fullscreen figure in chosen monitor, default is monitor 2
nMonitor = min(nNumberOfMonitors,2);

% Make the figure fullscreen in the selected monitor
Make_Fullscreen_Figure_Selected_Monitor(nMonitor,hObject)

guidata(hObject);


function Delete_HFOAxis(hObject, handles, nBand_ToDelete) % TODO better calculation of new positions

if(nBand_ToDelete==1) % Delete ripple axis and related objects
    delete(handles.axes_filtered_1)
    delete(handles.axes_yscale_filtered_1)
    delete(handles.edit_yscale_filtered_1)
    delete(handles.textbox_filtered_1)
elseif(nBand_ToDelete==2) % Delete fast ripple axis and related objects
    delete(handles.axes_filtered_2)
    delete(handles.axes_yscale_filtered_2)
    delete(handles.edit_yscale_filtered_2)
    delete(handles.textbox_filtered_2)
end

%% Resize axis for raw signal
posMainAxisPrev = handles.axes_raw.Position;
handles.axes_raw.Position(3) = 0.4;
if(nBand_ToDelete==2) % Delete fast ripples
    handles.axes_filtered_1.Position(1) = ...
        handles.axes_filtered_1.Position(1)-posMainAxisPrev(1)-posMainAxisPrev(3)+...
        handles.axes_raw.Position(1)+handles.axes_raw.Position(3);
    handles.axes_filtered_1.Position(3) = handles.axes_raw.Position(3);
    handles.axes_yscale_filtered_1.Position(1) = ...
        handles.axes_yscale_filtered_1.Position(1)-posMainAxisPrev(1)-posMainAxisPrev(3)+...
        handles.axes_raw.Position(1)+handles.axes_raw.Position(3);
    handles.edit_yscale_filtered_1.Position(1) = ...
        handles.edit_yscale_filtered_1.Position(1)-posMainAxisPrev(1)-posMainAxisPrev(3)+...
        handles.axes_raw.Position(1)+handles.axes_raw.Position(3);
elseif(nBand_ToDelete==1) % Delete ripples
    handles.axes_yscale_filtered_2.Position(1) = ...
        handles.axes_yscale_filtered_2.Position(1)-posMainAxisPrev(1)-posMainAxisPrev(3)+...
        handles.axes_raw.Position(1)+handles.axes_raw.Position(3)-handles.axes_filtered_2.Position(3);
    handles.edit_yscale_filtered_2.Position(1) = ...
        handles.edit_yscale_filtered_2.Position(1)-posMainAxisPrev(1)-posMainAxisPrev(3)+...
        handles.axes_raw.Position(1)+handles.axes_raw.Position(3)-handles.axes_filtered_2.Position(3);
    handles.axes_filtered_2.Position(1) = ...
        handles.axes_filtered_2.Position(1)-posMainAxisPrev(1)-posMainAxisPrev(3)+...
        handles.axes_raw.Position(1)+handles.axes_raw.Position(3)-handles.axes_filtered_2.Position(3);
    handles.axes_filtered_2.Position(3) = handles.axes_raw.Position(3);
end

handles.pushbutton_ripple_zoom_in.Position(1) = ...
    handles.pushbutton_ripple_zoom_in.Position(1)-posMainAxisPrev(1)-posMainAxisPrev(3)+...
    handles.axes_raw.Position(1)+handles.axes_raw.Position(3);
handles.pushbutton_ripple_zoom_out.Position(1) = ...
    handles.pushbutton_ripple_zoom_out.Position(1)-posMainAxisPrev(1)-posMainAxisPrev(3)+...
    handles.axes_raw.Position(1)+handles.axes_raw.Position(3);

guidata(hObject,handles);



% --- Executes on button press in pushbutton_quit.
function pushbutton_quit_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_quit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close all








%%

% handles.FigureH = figure;
%
% handles.radio(1) = uicontrol('Style', 'radiobutton', ...
%
%                            'Callback', @myRadio, ...
%
%                            'Units',    'pixels', ...
%
%                            'Position', [10, 10, 80, 22], ...
%
%                            'String',   'radio 1', ...
%
%                            'Value',    1);
%
% handles.radio(2) = uicontrol('Style', 'radiobutton', ...
%
%                            'Callback', @myRadio, ...
%
%                            'Units',    'pixels', ...
%
%                            'Position', [10, 40, 80, 22], ...
%
%                            'String',   'radio 2', ...
%
%                            'Value',    0);
%
% ...
%
% guidata(handles.FigureH, handles);
% And the callback:
%
% Copy
%
%
% function myRadio(RadioH, EventData)
%
% handles = guidata(RadioH);
%
% otherRadio = handles.radio(handles.radio ~= RadioH);
%
% set(otherRadio, 'Value', 0);



function edit_yscale_raw_Callback(hObject, eventdata, handles)
% hObject    handle to edit_yscale_filtered_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_yscale_filtered_1 as text
%        str2double(get(hObject,'String')) returns contents of edit_yscale_filtered_1 as a double
nBand_ToPlot = 1;
YShiftRaw = str2double(hObject.String);
if(~isnumeric(YShiftRaw))
    return;
end
% Update yshift value
handles.PlotParams.YShift(1) = YShiftRaw;
% YLimit for each axis
YLim_Ax = [-(handles.PlotParams.YMargin(2)+length(handles.PlotParams.ListOfChannels_ToPlot)-1),...
    handles.PlotParams.YMargin(1)]*handles.PlotParams.YShift(nBand_ToPlot);
% Change ylimits of axes
set(handles.axesSingleChannel{nBand_ToPlot}(1),'YLim',YLim_Ax)



function edit_yscale_filtered_1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_yscale_filtered_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_yscale_filtered_1 as text
%        str2double(get(hObject,'String')) returns contents of edit_yscale_filtered_1 as a double


function edit_yscale_filtered_2_Callback(hObject, eventdata, handles)
% hObject    handle to edit_yscale_filtered_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_yscale_filtered_2 as text
%        str2double(get(hObject,'String')) returns contents of edit_yscale_filtered_2 as a double
