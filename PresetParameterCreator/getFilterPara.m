function [] = getFilterPara(bandString)
    SampFreq = 2000;
    switch bandString
        case 'ripple'
            subSampFreq = SampFreq;
            FilterPara = rippleFilter(SampFreq, subSampFreq);

        case 'fripple'
            subSampFreq = SampFreq;
            FilterPara = fastRippleFilter(SampFreq, subSampFreq);
    end

    % Save filter
    fileName = ['/', 'FilterPara', bandString];
    save([pwd, fileName],'FilterPara')
end

function [ FilterPara ] = rippleFilter(sampFreq, subSampFreq)

    % Sampling frequency: 2000
    % Passbands:
    % Ripple: 70,80-240,250
    % Hence a 10 Hz error room.

    % Sampling frequency
    FilterPara.sampFreq = sampFreq;
    FilterPara.subSampRate = subSampFreq;

    % Ripple band
    FilterPara.BandFreq.highCut   = 70;
    FilterPara.BandFreq.highPass  = 80;
    FilterPara.BandFreq.lowPass  = 240;
    FilterPara.BandFreq.lowCut   = 250;

    FilterPara.Attenu.highCut       = 60;
    FilterPara.Ripple.AllowedRip  = 1;
    FilterPara.Attenu.lowCut       = 60;

    D = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2',...
        FilterPara.BandFreq.highCut,...
        FilterPara.BandFreq.highPass,...
        FilterPara.BandFreq.lowPass,...
        FilterPara.BandFreq.lowCut,...
        FilterPara.Attenu.highCut,...
        FilterPara.Ripple.AllowedRip,...
        FilterPara.Attenu.lowCut,...
        FilterPara.sampFreq );

    % Band pass FIR filter
    FilterDesign = design(D,'equiripple');
    b = FilterDesign.Numerator;
    a = 1;
    FilterPara.bCoef = b;
    FilterPara.aCoef = a;

end

function [ FilterPara ] = fastRippleFilter(sampFreq, subSampFreq)

    % Sampling frequency: 2000
    % Passbands:
    % FR: 240,250 - 490,500
    % Hence a 10 Hz error room.

    FilterPara.sampFreq = sampFreq;
    FilterPara.subSampRate = subSampFreq;

    % Fast Ripple
    FilterPara.BandFreq.highCut   = 240;
    FilterPara.BandFreq.highPass  = 250;
    FilterPara.BandFreq.lowPass  = 490;
    FilterPara.BandFreq.lowCut   = 500;

    FilterPara.Attenu.highCut      = 60;
    FilterPara.Ripple.AllowedRip = 1;
    FilterPara.Attenu.lowCut      = 60;

    D = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2',...
        FilterPara.BandFreq.highCut,...
        FilterPara.BandFreq.highPass,...
        FilterPara.BandFreq.lowPass,...
        FilterPara.BandFreq.lowCut,...
        FilterPara.Attenu.highCut,...
        FilterPara.Ripple.AllowedRip,...
        FilterPara.Attenu.lowCut,...
        FilterPara.sampFreq );

    % Band pass FIR filter
    FilterDesign = design(D,'equiripple');
    b = FilterDesign.Numerator;
    a = 1;
    FilterPara.bCoef = b;
    FilterPara.aCoef = a;
end
