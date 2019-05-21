function [Reff] = loadZurichMorphReference(resultPath)
    load(resultPath, 'HFOAnalysisResults');
    load(resultPath, 'LoadRecordingParams');

    sampFreq = LoadRecordingParams.fs;    
    %% Baseline
    Reff.FilterCoef.R = HFOAnalysisResults.FilterCoeff.Rb;
    Reff.FilterCoef.FR = HFOAnalysisResults.FilterCoeff.FRb;
    

    Reff.Baseline.Rip = HFOAnalysisResults.Thresholds.RippleTHR(21);
    Reff.Baseline.RipFilt = HFOAnalysisResults.Thresholds.RippleTHRFiltered(21);
    
    Reff.Baseline.FRip = HFOAnalysisResults.Thresholds.FRTHR(21);
    Reff.Baseline.FRipFilt = HFOAnalysisResults.Thresholds.FRTHRFiltered(21);
    
    
    %% Indeces of Ripples and fast Ripples
    mask1Markings = (HFOAnalysisResults.HFOAnalysisResultsAllChannels{21}.mark == 1);
    mask2Markings = (HFOAnalysisResults.HFOAnalysisResultsAllChannels{21}.mark == 2);
    mask3Markings = (HFOAnalysisResults.HFOAnalysisResultsAllChannels{21}.mark == 3);

    maskRipple = mask1Markings | mask3Markings;
    maskFastRipple = mask2Markings | mask3Markings;

    maskLongerThan5Min = (HFOAnalysisResults.HFOAnalysisResultsAllChannels{21}.autoSta <= 300);

    Reff.RipStart = HFOAnalysisResults.HFOAnalysisResultsAllChannels{21}.autoSta(maskRipple & maskLongerThan5Min)*sampFreq;
    Reff.RipEnd   = HFOAnalysisResults.HFOAnalysisResultsAllChannels{21}.autoEnd(maskRipple & maskLongerThan5Min)*sampFreq;

    Reff.FastRipStart = HFOAnalysisResults.HFOAnalysisResultsAllChannels{21}.autoSta(maskFastRipple & maskLongerThan5Min)*sampFreq;
    Reff.FastRipEnd   = HFOAnalysisResults.HFOAnalysisResultsAllChannels{21}.autoEnd(maskFastRipple & maskLongerThan5Min)*sampFreq;
end
