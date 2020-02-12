% d = [23,67,110,25,69,24,102,109];
% d = sort(d);
% d = [23    24    25    67  68  69   102 103 104  109   110];
function m = groupSequentIntegers(d, seperation)
if isempty(d)
    m = []; 
   return 
end
d = sort(d);
if nargin < 2
    seperation = 1;
end
if isequal(seperation, 'avg')
diffy = diff(d);    
seperation = sum(diffy) / length(diffy);
end
m = {[d(1)]};
for iNdex = 2:length(d) 
    iEntry = d(iNdex);
    if (iEntry - m{end}(end) <= seperation)
        m{end} = [m{end},iEntry];
    else
        m = [m, iEntry];
    end
end