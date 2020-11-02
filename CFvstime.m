clc
clear


addpath(genpath([pwd,'/_Functions']));    % Matlab functions for cost function and running cases - RaddEAD ONLY

load('BaselineSimout.mat')
BLSimOut = simOut; 
clearvars -except BLSimOut

%% Load simulation output to look at
load('ChampsAllCasesComplete.mat')

%% 

for Case = 1 : nCases
SiminCF  = [];
if isempty(case_subset)
    BLCase = Case;    
else    
    BLCase = case_subset(Case);
end

[Tmax,~] = size(simOut{Case}.Channels);
Tmax = (Tmax-1)/80 ;

pMetrics = simOut{Case}.pMetrics;

Stats.Maxes = zeros(1,12);
Stats.STD = zeros(1,12);
Stats.Mean = zeros(1,12);
Stats.Trvl = zeros(1,12);

for Time  = [150 : Tmax]
    %trim simout information & baseline information
    TimeSimOut = {simOut{Case}};
    TimeBLSimOut = {BLSimOut{BLCase}};
        
    TimeSimOut{1}.Channels = simOut{Case}.Channels(1:Time*80+1,:);
    TimeBLSimOut{1}.Channels = BLSimOut{BLCase}.Channels(1:Time*80+1,:);
    
    TimeCases = fRegExpCases( cellfun(@(x)(x.runCase), TimeSimOut, 'UniformOutput',false) );
    TimeBLCases = fRegExpCases( cellfun(@(x)(x.runCase), TimeBLSimOut, 'UniformOutput',false) );
    
    TimeCases.tSim = Time;
    TimeBLCases.tSim = Time;
    
    SimRunsStats = fComputeOutStats(TimeSimOut, pMetrics, TimeCases);
    BLRunsStats = fComputeOutStats(TimeBLSimOut, pMetrics, TimeBLCases);
    
    [SimMetrics] = fEvaluateMetrics(SimRunsStats, pMetrics);
    [BLMetrics] = fEvaluateMetrics(BLRunsStats, pMetrics);
    
    [SiminCF(Time), ~, ~, ~] = fCostFunction(SimMetrics.Values, BLMetrics.Values, pMetricsBC);
    
    
    Stats.Maxes(Time,:) = [SimRunsStats.Max(9),SimRunsStats.Max(34),SimRunsStats.Max(46),SimRunsStats.Max(47),SimRunsStats.Max(74),SimRunsStats.Max(91),SimRunsStats.Max(99),SimRunsStats.Max(111),SimRunsStats.Max(114),SimRunsStats.Max(116),SimRunsStats.Max(117),SimRunsStats.Max(118)];
    Stats.STD(Time,:) = [SimRunsStats.Std(9),SimRunsStats.Std(34),SimRunsStats.Std(46),SimRunsStats.Std(47),SimRunsStats.Std(74),SimRunsStats.Std(91),SimRunsStats.Std(99),SimRunsStats.Std(111),SimRunsStats.Std(114),SimRunsStats.Std(116),SimRunsStats.Std(117),SimRunsStats.Std(118)];
    Stats.Mean(Time,:) = [SimRunsStats.Mean(9),SimRunsStats.Mean(34),SimRunsStats.Mean(46),SimRunsStats.Mean(47),SimRunsStats.Mean(74),SimRunsStats.Mean(91),SimRunsStats.Mean(99),SimRunsStats.Mean(111),SimRunsStats.Mean(114),SimRunsStats.Mean(116),SimRunsStats.Mean(117),SimRunsStats.Mean(118)];
    Stats.Trvl(Time,:) = [SimRunsStats.Trvl(9),SimRunsStats.Trvl(34),SimRunsStats.Trvl(46),SimRunsStats.Trvl(47),SimRunsStats.Trvl(74),SimRunsStats.Trvl(91),SimRunsStats.Trvl(99),SimRunsStats.Trvl(111),SimRunsStats.Trvl(114),SimRunsStats.Trvl(116),SimRunsStats.Trvl(117),SimRunsStats.Trvl(118)];
end
    
     
SimCF{Case} = SiminCF ;
RunStats{Case} = Stats;
end


figure
hold on
for x = 1:6
plot(SimCF{x})
end
%%

% Time = [1:600];
% figure 
% plot(Time,SimCF{1},Time,RunStats{1}.Trvl(:,6))
% 
% 





