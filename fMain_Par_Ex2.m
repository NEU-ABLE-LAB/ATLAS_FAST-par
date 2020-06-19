function Cost = fMain_Par_Ex2(U)
%% This function acts as a wrapper function for optimising gains on the baseline PI controler
% to run this example input the command below into the command window:

%      TunedGains = fminsearch(@(U)fMain_Par_Ex2(U),[0.006275604; 0.0008965149])

Main_Par_Ex2
Cost = CF.CF       %display current cost for this fminsearch() itteration       
end

