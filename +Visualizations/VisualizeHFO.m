function []  = VisualizeHFO(hfo, SigString, chanInd, extraHFO)
    if nargin < 2
        SigString = 'filt';
        chanInd = 1:hfo.Data.nbChannels;
        extraHFO = [];
    elseif nargin < 3
        SigString = 'filt';
        chanInd = 1:hfo.Data.nbChannels;
        extraHFO = [];
    elseif nargin < 4
        extraHFO = [];
    end
    
    
    switch SigString
        case 'raw'
            signal   = hfo.Data.signal;
            envel    = [] ;
            shiftMag = 125;
            TitlePrefix = 'Raw data:';
        case 'filt'
            signal   = hfo.filtSig.filtSignal;
            envel    = hfo.filtSig.Envelope;
            shiftMag = 70; 
            TitlePrefix = 'Filterd data and envelope:';
        otherwise
    end
    TitleString = [TitlePrefix,hfo.DataFileLocation];
    

    %% Load data info
    chanName = hfo.Data.channelNames(chanInd);
    nbChan   = length(chanInd);
    
    nbSamp   = hfo.Data.nbSamples;
    Sampels  = 1:nbSamp;
    
    %% The plot
    figure('units','normalized','outerposition',[0 0 1 1])
    a = gca;
    hold on
    
    % loop over channels
    sigPlot = cell(nbChan,1);
    for  iChan = 1:nbChan
       %% Show signal 
       Chan = chanInd(iChan);
       y1 = signal(:,Chan); 
       % make a shift, This can be improved
       shift = shiftMag*(iChan-1);
       % plot signal
       sigPlot{iChan} = plot(y1 - shift ,'color', 'blue','DisplayName','Signal');
       % plot a zero line for viewing
       RefLine = refline(0,-shift);
       RefLine.Color = 'black';
       
       %% Show envelope
       if ~isempty(envel)
          EnvelopeValues = envel(:,Chan); 
          plot(EnvelopeValues - shift ,'color', 'red','DisplayName','Envelope');
       end

       %% Show baseline information.
       if ~isempty(hfo.baseline)
           [~, ~, ~] =  showBaselineInfo(hfo, shift, Chan);
       end
       
       %% Show event information.
       if ~isempty(hfo.Events)
          [~] = showEventInfo(hfo, shiftMag, shift, iChan);
          if ~isempty(extraHFO)
            [~] = showEventInfo(extraHFO, shiftMag, shift, iChan , 'blue');
          end
       end
       
       %% Channel labels 
       plotChannelLable(chanName, nbChan, iChan)

    end 
    
    %% cosmetics
%     Legend = legend([sigPlot{1} envPlot BaselineTHresh NoiseLine BaslinePatches EventPatches],...
%         {'Signal','Envelope','Baseline Threshold', 'Noise Threshold' ,'Baseline', 'Events'},...
%         'Location','northwest');

    title(TitleString)

    annotation('textbox', [0.1, 0.83, 0.1, 0.1], 'string',  'uV')
    
    hold off
    
    %% All the scroller control stuff
    ButtonStepDist = fix(nbSamp/100);
    
    set(gca,'ytick',-100:50:100)
    set(gcf,'doublebuffer','on');
    set(a,'xlim',[0 ButtonStepDist]);
    set(a,'ylim',[min(-shiftMag*iChan) max(shiftMag)]);
    
    pos = get(a,'position');
    Newpos = [pos(1) pos(2)-0.1 pos(3) 0.05];
    
    ButtonMax = max(Sampels);
    S = ['set(gca,''xlim'',get(gcbo,''value'')+[0 ' num2str(ButtonStepDist) '])'];
    h = uicontrol('style', 'slider', 'units', 'normalized', 'position', Newpos, 'callback', S, 'min', 0, 'max', ButtonMax-ButtonStepDist);
end


%% Baseline visualization
function [ShiftedBaselineThrLine, ShiftedMaxNoisemuVLine, BaslinePatches] = ...
                            showBaselineInfo(hfo, shift, Chan)
    % Load baseline info
    bsline      = hfo.baseline;
    baselineThr = bsline.baselineThr;
    maxNoisemuV = bsline.maxNoisemuV;

    % plot basline threshold
    ShiftedBaselineThr =  baselineThr(Chan) - shift;
    ShiftedBaselineThrLine = refline(0, ShiftedBaselineThr);
    ShiftedBaselineThrLine.Color = 'red';
    ShiftedBaselineThrLine.LineStyle = ':';
    % BaselineTHresh     = yline(ShiftedBaselineThr,':r');

    ShiftedMaxNoisemuV = maxNoisemuV(Chan) - shift;
    ShiftedMaxNoisemuVLine = refline(0, ShiftedMaxNoisemuV);
    ShiftedMaxNoisemuVLine.Color = 'red';
    ShiftedMaxNoisemuVLine.LineStyle = '-.';
    % NoiseLine          = yline(ShiftedMaxNoisemuV,'-.r');

    % Highlight baseline intervals verteces for the see-through blocks
    BaselineStr = hfo.baseline.HiEntropyIntv.IntvStr;
    BaselineEnd = hfo.baseline.HiEntropyIntv.IntvEnd;
    YLimits     = baselineThr(Chan);
    BaslinePatchVert = getEvenPatchVert(hfo, BaselineStr, BaselineEnd, YLimits);

    % Plot the tansparent block highlighting egments chosen to represetn the baseline.
    PatchVerts = BaslinePatchVert{Chan};
    XVerts = PatchVerts.XVerts;
    YVerts = PatchVerts.YVerts;
    BaslinePatches = patch(XVerts, YVerts - shift,'red');
    alpha(BaslinePatches, 0.15);
end

%% Event visualization
function [EventPatches] = showEventInfo(hfo, shiftMag, shift, Chan, blockColour)
    if nargin < 5
       blockColour = 'green'; 
    end
    % load event info
    EventRate = hfo.Events.Rates;
    YLimits = shiftMag/2;

    % Highlight event intervals
    EventStr = hfo.Events.Markings.start;
    EventEnd = hfo.Events.Markings.end;
    EventPatchVert = getEvenPatchVert(hfo, EventStr, EventEnd, YLimits);

    PatchVerts = EventPatchVert{Chan};
    XVerts = PatchVerts.XVerts;
    YVerts = PatchVerts.YVerts;
    EventPatches = patch(XVerts, YVerts - shift, blockColour);
    alpha(EventPatches, 0.15);

    % Rates
%     plotChannelEventRates(EventRate,nbChan,iChan)
end

function [] = plotChannelEventRates(EventRate, nbChan, iChan)
    boxSize = [ 0.1, 0.1];
    BoxPos = [0.925, (0.6/nbChan)*(nbChan-iChan)+0.25];
    TextInput = [num2str(EventRate(iChan)),'hfo/min'];
    annotation('textbox', [BoxPos(1), BoxPos(2), boxSize(1), boxSize(2)], 'string',  TextInput)
end

%% Patches
function EventPatchVert = getEvenPatchVert(hfo, Stats, Ends, YLimits)
    nbChan     = hfo.Data.nbChannels;  
    Verts = cell(nbChan,1); 
    for iChan = 1:nbChan
        EventStatCHAN = Stats{iChan};
        EventEndCHAN  = Ends{iChan};
        Verts{iChan} = getEvenPatchVertCHAN(EventStatCHAN, EventEndCHAN, YLimits);
    end
    EventPatchVert = Verts;
end

function Verts = getEvenPatchVertCHAN(EventStatsCHAN, EventEndsCHAN, YLimits)
    nbEvents = length(EventStatsCHAN);
    
    if size(EventStatsCHAN,1) == 1
        XVerts = [EventStatsCHAN', EventEndsCHAN', EventEndsCHAN', EventStatsCHAN']; 
    else
        XVerts = [EventStatsCHAN, EventEndsCHAN, EventEndsCHAN, EventStatsCHAN];   
    end
    
    YVerts = YLimits*[-1, -1, 1, 1];
    YVerts = repmat(YVerts,nbEvents,1);
    
    Verts.XVerts = XVerts';
    Verts.YVerts = YVerts';
end

%% Channel labels on y axis
function [] = plotChannelLable(chanName, nbChan, iChan)
    boxSize = [ 0.1, 0.1];
    BoxPos = [0.000, (0.99/(nbChan+2))*(nbChan - iChan) + (0.99/(nbChan+2)) ];
    TextInput =chanName{iChan};
    annotation('textbox', [BoxPos(1), BoxPos(2), boxSize(1), boxSize(2)], 'string',  TextInput)
end

