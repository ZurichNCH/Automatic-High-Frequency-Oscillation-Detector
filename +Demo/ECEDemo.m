clear
clc
%parameter path
RParaPath = [pwd, '\+Demo\ZurichDemo1Morph\Parameters\RMorphPara.mat'];
FRParaPath = [pwd, '\+Demo\ZurichDemo1Morph\Parameters\FRMorphPara.mat'];
dataPath = [pwd, '\+Demo\ZurichDemo1Morph\Data\Data.mat'];
channelContains = '';
smoothBool = true;
RefType = 'morph';
CondMulti = true;
%%
% Load data from work space: 
% must contain the following in the following form.
% data.Datasetup
% data.x_bip 
% data.lab_bip
% data.fs
%%
hfo = Core.HFO;
hfo.ParaFileLocation = RParaPath;
hfo.DataFileLocation = dataPath;
load( dataPath,'data')
hfo = getParaAndData(hfo, channelContains, data);
hfo = getFilteredSignal(hfo, smoothBool);
hfo = getBasline(hfo);
hfo = getEvents(hfo, RefType, CondMulti);