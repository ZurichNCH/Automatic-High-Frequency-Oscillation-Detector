    function VParams = getVParams(Modality, ChanNames, SelectedChanNames) 
    if nargin == 2
        SelectedChanNames = '';
        disp('Warning: no channels were selected, hence all channels are displayed.')
    end
    
    switch Modality
        case 'iEEG'
            VParams.HFOBand_ToPlot = [1,2]; % 1:ripple 2: fast 
            VParams.HFOType_ToValidate = 3; % 1:ripple 2: fast ripple 3: FRandR
            Channels_ToPlot = find(contains(ChanNames, SelectedChanNames));% 1:nbChannels; 
            VParams.ListOfChannels_ToPlot =  Channels_ToPlot;%Channels_ToPlot;
            VParams.YShift = [250,30,30];
            return
        case 'scalp'
            VParams.HFOBand_ToPlot        = 1; % 1:ripple 2: fast ripple 3: FRandR
            VParams.HFOType_ToValidate    = 1; % 1:ripple 2: fast ripple 3: FRandR
            Channels_ToPlot               = find(contains(ChanNames, SelectedChanNames));% 1:nbChannels; 
            VParams.ListOfChannels_ToPlot = Channels_ToPlot;%1:nbChannels;
            VParams.YShift                = [200,10]; % [800,10];
            return 
        case 'ECoG'
            
            
            
            return
    end
    error('There are one must choose among the following modalities: "iEEG", "scalp" or "ECoG".')
    end