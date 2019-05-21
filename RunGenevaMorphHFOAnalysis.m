% warning('on','all')
% warning('off','all')
clear
clc
warning('off','all')
%% Load parameters and data
 PatNum = {'1757' '1785' '1785' '1786' '1786' '1806' '1806' '1823' '1823' '2012' '2012' '2091' '2091'};
 EEGNum = {'224081' '236222' '242175' '221485' '225402' '231685' '231697' '254169' '254172' '255619' '257707' '247134' '247147'};
for iFile = 1:13
    disp(['Currently running patient: ',num2str(PatNum{iFile}), ' recording number: ',num2str(EEGNum{iFile})])
    RParaPath = [pwd, '\+Demo\ZurichDemo1Morph\Parameters\RMorphPara.mat'];
    FRParaPath = [pwd, '\+Demo\ZurichDemo1Morph\Parameters\FRMorphPara.mat'];
    DataDir  = ['E:\GENEVA\Processed Data\PAT_',num2str(PatNum{iFile}),'\',num2str(EEGNum{iFile}),'\Data\'];
    %% Run the detecor
    hfodet = Detections;
    hfodet = hfodet.setPDPaths(RParaPath, FRParaPath, DataDir);
    hfodet = hfodet.runDetector('morph', false,3,'',true,'RipAndFRip',0.8);
    hfodet.exportHFOsummary
end
