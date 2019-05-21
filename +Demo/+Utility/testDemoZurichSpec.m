function [] = testDemoZurichSpec(Reff, hfo)
%% parameters
% Reff.Para
% hfo.Para
assert(Reff.Para.highPass           - hfo.Para.highPass            == 0)
assert(Reff.Para.lowPass            - hfo.Para.lowPass             == 0)
assert(Reff.Para.MaxEntroFracPARA   - hfo.Para.MaxEntroFracPARA    == 0)
assert(Reff.Para.CDFlevel           - hfo.Para.CDFlevel            == 0)
assert(Reff.Para.StockwellFreqRange - hfo.Para.StockwellFreqRange  == 0)
assert(Reff.Para.STransFreqTrimPARA - hfo.Para.STransFreqTrimPARA  == 0)
assert(Reff.Para.maxcorr            - hfo.Para.maxcorr             == 0)
assert(Reff.Para.lowFreqBound       - hfo.Para.lowFreqBound        == 0)
assert(Reff.Para.highFreqBound      - hfo.Para.highFreqBound       == 0)
assert(Reff.Para.maxAmplBound       - hfo.Para.maxAmplBound        == 0)
assert(norm(Reff.Para.FilterPara.bCoef   - hfo.Para.FilterPara.bCoef)< 10^(-13))
%% Meta Data
% Reff.MetaData
% hfo.Data
assert(Reff.MetaData.maxIntervalToJoin - hfo.Data.maxIntervalToJoin == 0)
assert(Reff.MetaData.sampFreq          - hfo.Data.sampFreq == 0)
assert(Reff.MetaData.MinInterEventDist - hfo.Data.minEventTime == 0)
assert(Reff.MetaData.nbChannels        - hfo.Data.nbChannels == 0)
assert(isequal(Reff.MetaData.dataSetup,  hfo.Data.dataSetup))
%% Baseline
% Reff.Baseline.
% hfo.baseline.
assert(Reff.Baseline.maxNoisemuV  - hfo.baseline.maxNoisemuV(3) < 10^(-13))
assert(norm(Reff.Baseline.THRsss' - hfo.baseline.baselineThr)   < 10^(-12))

assert(norm(Reff.Baseline.IndBaseline{1} - hfo.baseline.IndBaseline{1})==0)
assert(norm(Reff.Baseline.IndBaseline{2} - hfo.baseline.IndBaseline{2})==0)
assert(norm(Reff.Baseline.IndBaseline{3} - hfo.baseline.IndBaseline{3})==0)
%% Events (you have to suppress selection for peaks and peak amplitude)
% Reff.Events
% hfo.Events
assert(norm(hfo.Events.Markings.start{1} - Reff.Events.Event_start{1}) == 0)
assert(norm(hfo.Events.Markings.start{2} - Reff.Events.Event_start{2}) == 0)
assert(norm(hfo.Events.Markings.start{3} - Reff.Events.Event_start{3}) == 0)

assert(norm(hfo.Events.EventProp{1}.Amplpp - Reff.Events.Amplitude{1})/norm(Reff.Events.Amplitude{1})< 10^(-14)) 
assert(norm(hfo.Events.EventProp{2}.Amplpp - Reff.Events.Amplitude{2})/norm(Reff.Events.Amplitude{1})< 10^(-14))
assert(norm(hfo.Events.EventProp{3}.Amplpp - Reff.Events.Amplitude{3})/norm(Reff.Events.Amplitude{1})< 10^(-14))

%%%%%%%%%%%
end