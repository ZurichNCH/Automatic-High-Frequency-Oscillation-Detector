function Reff = loadZurichSpecReference(resultPath, loadVar)
    load(resultPath, loadVar)
    % Extract refference information
    if isequal('HFO_R', loadVar)
        Reff.Para     = getReffPara(HFO_R.HFOobj);
        Reff.MetaData = getReffData(HFO_R.HFOobj);
        Reff.Baseline = getReffBaseline(HFO_R.HFOobj);
        Reff.Events   = getReffEvents(HFO_R.results);
        
    elseif  isequal('HFO_FR', loadVar)
        Reff.Para     = getReffPara(HFO_FR.HFOobj);
        Reff.Para.FilterPara.bCoef = HFO_FR.HFOobj.filter.FRb;
        
        Reff.MetaData = getReffData(HFO_FR.HFOobj);
        Reff.Baseline = getReffBaseline(HFO_FR.HFOobj);
        Reff.Events   = getReffEvents(HFO_FR.results);
    end
end

function Para = getReffPara(OBJE)
    Para = struct;
    
    Para.highPass = OBJE.hp;
    Para.lowPass = OBJE.lp; 
    Para.FilterPara.bCoef = OBJE.filter.Rb;
    Para.FilterPara.aCoef = OBJE.filter.Ra;
    Para.MaxEntroFracPARA = OBJE.BLmu;       %max entropy
    Para.CDFlevel = OBJE.CDFlevel;
    Para.StockwellFreqRange = OBJE.BLst_freq;
    Para.STransFreqTrimPARA = OBJE.BLborder;
%     Para.dur = OBJE.dur;
    
    Para.maxcorr = OBJE.maxcorr;
    Para.lowFreqBound = OBJE.lf_bound;
    Para.highFreqBound = OBJE.hf_bound;
    Para.maxAmplBound = OBJE.Ampl_bound;
end

function Data = getReffData(OBJE)
    Data = struct;
    Data.maxIntervalToJoin = OBJE.maxIntervalToJoin;
    Data.sampFreq = OBJE.fs;
    Data.channel_name = OBJE.channel_name;
    Data.MinInterEventDist = OBJE.time_thr;
    Data.nbChannels = OBJE.N_ch;
    Data.dataSetup = OBJE.Datasetup;
end

function Baseline = getReffBaseline(OBJE)
    Baseline.maxNoisemuV    = OBJE.maxNoisemuV;
    Baseline.IndBaseline    = OBJE.indHighEntr_channels;
    Baseline.b_mean         = OBJE.b_mean;
    Baseline.b_sd           = OBJE.b_sd;
    Baseline.THRsss         = OBJE.THRsss;
    Baseline.short_baseline = OBJE.short_baseline;
end

function Events = getReffEvents(OBJERes)
    Events.Event_start = {[OBJERes(1).results.trig_start]',[OBJERes(2).results.trig_start]',[OBJERes(3).results.trig_start]'};
    Events.Amplitude = {[OBJERes(1).results.Amplpp]',[OBJERes(2).results.Amplpp]',[OBJERes(3).results.Amplpp]'};
end
