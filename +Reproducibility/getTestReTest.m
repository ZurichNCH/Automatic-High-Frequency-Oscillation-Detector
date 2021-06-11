%one can use the function below to calculate the reliability in percentage,
%where RevEvSel is a matric of event numbers in fix length interval for
%each channel
% function PatientPercSucceed= ReliabilityCalc(RevEvSel)
% try
%     [RandomDistofSP, ActualDistofSP] = Reproducibility.getTestReTest(RevEvSel',5000); 
%     %             disp('NAn elements')
%     %             disp(sum(isnan(RandomDistofSP)))
%     PerToCompare=97.5;
%     PercentileVal = prctile(RandomDistofSP(:), PerToCompare);
%     PatientPercSucceed = (1 - mean(ActualDistofSP(~isnan(ActualDistofSP)) < PercentileVal))*100;
% catch
%     PatientPercSucceed= NaN;
%     
% end
% 
% 
% end



%% For each night pair, form the random dist
function [RandomDistofSP, ActualDistofSP] = getTestReTest(HFOrateMat, nbPermutations)
if nargin < 2
    nbPermutations = 10000;
end

rateMatrix       = HFOrateMat'; % channel X Interval
nbRecordings     = size(HFOrateMat,1);
[RandomDistofSP, ActualDistofSP] = getPairswiseRandomSP(rateMatrix, nbRecordings, nbPermutations);
end

%% Getting the random distribution:
function [SortedSPAllNightPairs, pairswiseSP] = getPairswiseRandomSP(rateMatrix, nbRecordings, M )
AllNightCombinations = nchoosek(1:nbRecordings, 2);
nbNightCombos = size(AllNightCombinations,1);
SortedSPAllNightPairs = nan(M/2, nbNightCombos);
pairswiseSP = nan(1,nbNightCombos);
for iComb = 1:nbNightCombos
    InterVal1 = AllNightCombinations(iComb,1);
    InterVal2 = AllNightCombinations(iComb,2);
    
    RatePair = rateMatrix(:, [InterVal1, InterVal2]);
    
    SortedSP = getRandomDistribution(RatePair, M);
    SortedSPAllNightPairs(:,iComb) = SortedSP(:);
    %pairswiseSP(iComb) =  (RatePair(:,1)/norm(RatePair(:,1)))'*(RatePair(:,2)/norm(RatePair(:,2)));
    
    ToNorm1=RatePair(:,1);
    ToNorm2=RatePair(:,2);
    % for the scalar product remove the NANs
    Mult1=RatePair(:,1);
    Mult2=RatePair(:,2);
    Mult1(isnan(Mult1))=0;
    Mult2(isnan(Mult2))=0;
    %         ScalarProduct(iter) = Mult1'*Mult2/...
    %             norm(ToNorm1(~isnan(ToNorm1)))/norm(ToNorm2(~isnan(ToNorm2)));
    pairswiseSP(iComb) =  Mult1'*Mult2/...
        norm(ToNorm1(~isnan(ToNorm1)))/norm(ToNorm2(~isnan(ToNorm2)));
    
    
    
end
end

function [SortedScalarProduct ] = getRandomDistribution(RatePair, M )
N = size(RatePair,1);
PermutationBank = Get_M_Combinations_to_N(M,N);
% M = min(size(PermutationBank,1),M/2);
CombinationsForNight1 = PermutationBank(1:M/2,:);
CombinationsForNight2 = PermutationBank(M/2+1:M,:);
RatesForNights1 = RatePair(:,1);
RatesForNights2 = RatePair(:,2);

ScalarProduct = zeros(M/2,1);
for iter = 1:M/2
    TempComb1 = CombinationsForNight1(iter,:);
    TempComb2 = CombinationsForNight2(iter,:);
    ToNorm1=RatesForNights1(TempComb1);
    ToNorm2=RatesForNights2(TempComb2);
    % for the scalar product remove the NANs
    Mult1=RatesForNights1(TempComb1);
    Mult2=RatesForNights2(TempComb2);
    Mult1(isnan(Mult1))=0;
    Mult2(isnan(Mult2))=0;
    ScalarProduct(iter) = Mult1'*Mult2/...
        norm(ToNorm1(~isnan(ToNorm1)))/norm(ToNorm2(~isnan(ToNorm2)));
end
SortedScalarProduct = sort(ScalarProduct);
SortedScalarProduct = SortedScalarProduct(:);
end

%% utility
function [PermutationBank] = Get_M_Combinations_to_N( M, N )
PermutationBank = nan(1.5*M, N);
for iter = 1:1.5*M
    PermutationBank(iter,:) = randperm(N);
end
PermutationBank = unique(PermutationBank,'rows');

if(~(size(PermutationBank,1)<M))
    PermutationBank = PermutationBank(1:M,:);
end
end

%% Getting the actual distribution:

function pairswiseSP = getPairswiseSP(rateMatrix, nbRecordings)

AllNightCombinations = nchoosek(1:nbRecordings,2);
nbNightCombos = size(AllNightCombinations,1);
pairswiseSP = nan(1,nbNightCombos);
for iComb = 1:nbNightCombos
    InterVal1 = AllNightCombinations(iComb,1);
    InterVal2 = AllNightCombinations(iComb,2);
    
    RatePair = rateMatrix(:, [InterVal1, InterVal2]);
    
    pairswiseSP(iComb) =  RatePair(:,1)*RatePair(:,2)';
end

end