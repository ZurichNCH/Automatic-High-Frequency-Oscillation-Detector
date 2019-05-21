function [] = compareEventIntervals(RRStr, RREnd, HRStr, HREnd)
EventInd = mat2cell([HRStr', HREnd'],ones(length(HRStr),1),2);
EventInd = EventInd(cellfun(@isempty,cellfun(@(x) find(x(2)>300*2000),EventInd,'UniformOutput',0)));
EventInd = cell2mat(EventInd);
allind = mat2cell(EventInd,ones(size(EventInd,1),1),2);
allind = cellfun(@(x) x(1):x(2),allind,'UniformOutput',0);
allind = cell2mat(allind');
temp = zeros(300*2000,1);
temp(allind) = 1;

%%
allind_ece = mat2cell(floor([RRStr', RREnd']),ones(length(RRStr),1),2);
allind_ece = cellfun(@(x) x(1):x(2),allind_ece,'UniformOutput',0);
allind_ece = cell2mat(allind_ece');
temp_ece = zeros(300*2000,1);
temp_ece(allind_ece) = 1;

%%
figure
hold on
stem(allind, ones(length(allind),1),'b')
stem(allind_ece, 0.95*ones(length(allind_ece),1),'r')
hold off
end