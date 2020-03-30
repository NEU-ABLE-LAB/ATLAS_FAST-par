%% Combine results from multiple MainMLC_FinalEval runs
%% Initialization
% ref: Main.m
addpath(genpath([pwd,'/_Functions']));  % Matlab functions for cost function and running cases - READ ONLY
addpath(genpath([pwd,'/_Controller'])); % Simulink model, where user scripts and models are placed
addpath(genpath([pwd,'/OpenMLC-Matlab-2'])); % OpenMLC classes and functions
addpath(pwd);

%% Combine results from multiple MainMLC_FinalEval runs
fNames = {
    'G:\Team Drives\ABLE_ATLAS_OffShore\save_GP\20190429-0228\20190429_193904mlc_ae.mat'
    'G:\Team Drives\ABLE_ATLAS_OffShore\save_GP\20190429-0228\20190430_002148mlc_ae.mat'
    'G:\Team Drives\ABLE_ATLAS_OffShore\save_GP\20190429-0228\20190430_044406mlc_ae.mat'
    'G:\Team Drives\ABLE_ATLAS_OffShore\save_GP\20190429-0228\20190430_094841mlc_ae.mat'
    'G:\Team Drives\ABLE_ATLAS_OffShore\save_GP\20190429-0228\20190430_141710mlc_ae.mat'
    'G:\Team Drives\ABLE_ATLAS_OffShore\save_GP\20190429-0228\20190430_194146mlc_ae.mat'
    'G:\Team Drives\ABLE_ATLAS_OffShore\save_GP\20190429-0228\20190430_194146mlc_ae.mat'
    'G:\Team Drives\ABLE_ATLAS_OffShore\save_GP\20190429-0228\20190430_224048mlc_ae.mat'
    };

results = cell(50,1);

for fN = 1:length(fNames)

    fprintf('Loading: %s\n', fNames{fN});
    d = load(fNames{fN});
    fprintf('Loaded: %s\n', fNames{fN});

    lastGenN = length(d.mlc.population);

    for backNGens = 1:size(d.simOutSmall,3)

        genN = lastGenN - backNGens + 1;

        % Get the aggregate results for that generation
        results(genN) = {d.CF(:,backNGens)};

        % Get the results for each of the cases
        % for n = 1:numel(d.simOutSmall(:,:,backNGens))
        for idvN = 1:size(d.simOutSmall(:,:,backNGens),1)
            
            nCases = length(d.simOutSmall(idvN,:,backNGens));
            results{genN}(idvN).CF_Cases = zeros(1, nCases);
            for caseN = 1:nCases
                if isfield(d.simOutSmall{idvN,caseN,backNGens}, 'CF')
                    results{genN}(idvN).CF_Cases(caseN) = ...
                        d.simOutSmall{idvN,caseN,backNGens}.CF;
                else
                    results{genN}(idvN).CF_Cases(caseN) = nan;
                end
            end
            
            [exprs, fcnStr] = ...
                MLC_exprs( ...
                    d.mlc.table.individuals( ...
                        d.mlc.population(genN).individuals(idvN)).formal,...
                    d.mlc.parameters);
            
            results{genN}(idvN).exprs = exprs;
            results{genN}(idvN).fcnStr = fcnStr;

        end

    end
    
end

%% Plot results

d.mlc.show_convergence
hold on

genCFs = (cellfun(@(x)(min([x.CF])), ...
    results(~cellfun(@isempty,results))));
genIdxs = find(~cellfun(@isempty,results));

line( genIdxs, genCFs, ones(size(genCFs))*1, ...
    'color','blue', ...
    'linestyle','-', ...
    'linewidth', 4)
hold off;

[bestCF,bestCFGenIdx] = min( genCFs );
title(sprintf('Population Fitness Histogram (Best = %d @ Gen. %i)', ...
    bestCF, genIdxs(bestCFGenIdx)))

ylabel('Cost Function')
set(gca,'yscale','linear')
ylim([0 2])
ylim([0.5 2])

xlabel('(Generation)(DLC)')
xticks(1:length(d.mlc.population))
xticklabels( arrayfun(@(x,y)(sprintf('%02d:%02d', x,y)), ...
        1:length(d.mlc.population), ...
        [d.mlc.population.caseN], ...
        'UniformOutput',false))
xtickangle(90)
    
legend({'Single DLC', 'Best All DLC'})


%% Get the best individuals
nBest = 10;
bestIdvs = cell(nBest,1);

CF = cell2mat( cellfun( @(x)([x.CF]), ...
    results( ~cellfun(@isempty,results) ), ...
    'UniformOutput',false));

[CF_best, CF_best_idx] = sort(CF);
CF_best = CF_best(1:nBest);
CF_best_idx = CF_best_idx(1:nBest);
[CF_best_genN, CF_best_genIdv] = ind2sub(size(CF), CF_best_idx);
CF_best_genN = genIdxs(CF_best_genN);

for bestN = 1:nBest
    
    bestIdvs{bestN} = results{CF_best_genN(bestN)}(...
        CF_best_genIdv(bestN));
    
    bestIdvs{bestN}.genN = CF_best_genN(bestN);
    
    bestIdvs{bestN}.idvN = CF_best_genIdv(bestN);
    
end

fcnText = cellfun(@(x)(x.fcnStr), bestIdvs, 'UniformOutput',false);

% Calculate how often each sensor is used
outListNames = fieldnames(d.mlc.parameters.problem_variables.outListIdx);
outListLen = length(outListNames);
outListIdxs = regexp(fcnText,'u\((\d*)\)','tokens');

for k = 1:length(outListIdxs)
    
    outListIdxs{k} = cellfun(@(sensorIdx)str2double(sensorIdx{1}),outListIdxs{k});
    
    outListIdxs{k} = full(sparse(...
        ones(size(outListIdxs{k})),...
        outListIdxs{k},...
        ones(size(outListIdxs{k})),...
        1, outListLen));
end

outListIdxs = cell2mat(outListIdxs);
sensorIdxs = outListIdxs(:,d.mlc.parameters.problem_variables.sensorIdxs);

% Plot sensor use statistics
figure('windowstyle','docked')
bar(mean(sensorIdxs));

xticks(1:length(d.mlc.parameters.problem_variables.sensorIdxs));
xticklabels(d.mlc.parameters.problem_variables.sensorNames)
xtickangle(90)
xlabel('Sensor')

ylabel('Avg. Count');

title('Sensors Used by Controllers')

%% Plot aggregate metrics
figure('windowstyle','docked')

folders = cell(nBest,2);
folders(:) = '';
folders(:,2) = cellfun( @(x)sprintf('G%i:I%i', x.genN, x.idvN ), ...
    bestIdvs, ...
    'UniformOutput',false);

% Extract costs
tmp_CF = cellfun(@(x)x.CF, bestIdvs)';

tmp_CF_Comp = cell2mat( cellfun( @(x)x.CF_Comp, ...
    bestIdvs, 'UniformOutput',false));

tmp_CF_Vars = cell2mat( cellfun( @(x)x.CF_Vars, ...
    bestIdvs, 'UniformOutput',false));

tmp_CF_Freq = cellfun(@(x)x.CF_Freq, bestIdvs);

fCostFunctionPlot(...
    tmp_CF, ...
    tmp_CF_Comp, ...
    tmp_CF_Vars, ...
    tmp_CF_Freq, ...
    d.simOutSmall{1}.pMetrics, folders,'absVar')

ylim([0 1.1]);
ylabel('Cost')

%% Plot Comparison of each case
    
figure('windowstyle','docked')

tmp_CF = cell2mat( cellfun( @(x)x.CF_Cases, ...
    bestIdvs, 'UniformOutput',false));
%TODO there's a bug in the way CF_Cases is computed. All case values are
%identical.

bar(tmp_CF')

title('Performance on Cases');
xlabel('Case #')
ylim([0 2])
    