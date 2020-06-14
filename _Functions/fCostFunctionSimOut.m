%% fCostFunctionSimOut Compute the aggregate cost function across and array of simOut
function [CF, CF_Comp, CF_Vars, CF_Freq, pMetrics, Metrics, RunsStats] = ...
    fCostFunctionSimOut(simOut, Challenge, metricsBase, pMetrics)

%   Check for missing simulations (caused by simulink model failing)
if any(cellfun(@isempty, simOut))
    CF = 1000;
    CF_Comp = 1000 * ones(1,length(pMetrics.uComponents));
    CF_Vars = 1000 * ones(1,length(pMetrics.VarsWeights));
    CF_Freq = struct('MRi',nan(12,10), 'MAbs',nan(12,10));
    pMetrics = [];
    Metrics = [];
    RunsStats = [];
else
    try
        %% Load case and metrics initialize
        % Parameters for the metrics computation
        if isa(simOut,'Simulink.SimulationOutput')
            
            Cases = fRegExpCases({simOut.runCase});
            
        elseif isa(simOut,'cell')
            
            Cases = fRegExpCases( cellfun(@(x)(x.runCase), ...
                simOut, 'UniformOutput',false) );
            
        end
               
        %% Loop on results folder, compute cost function1
        
        RunsStats = fComputeOutStats(simOut, pMetrics, Cases);
        
        % --- Safety checks
        id =find(ismember(RunsStats.ChanName, 'Wave1Elev'));
        if isequal(lower(Challenge),'onshore') && ~isempty(id)
            error('You are trying to evaluate results from the "Offshore" challenge, but you provided the option "Onshore" to the cost function method. Most likely you are running in the wrong challenge folder.')
        end
        if isequal(lower(Challenge),'offshore') && isempty(id)
            error('You are trying to evaluate results from the "Onshore" challenge, but you provided the option "Offshore" to the cost function method. Most likely you are running in the wrong challenge folder.')
        end
        
        % --- Evaluate metrics and cost function
        [Metrics] = fEvaluateMetrics(RunsStats, pMetrics);
        
        [CF, CF_Comp, CF_Vars, CF_Freq] = ...
            fCostFunction(Metrics.Values, metricsBase.Values, pMetrics);
                
        % --- Safety check
        if length(RunsStats.OutFiles)~=length(Cases.Names)
            warning('Only %d/%d files found in %s.', ...
                length(RunsStats.OutFiles), length(Cases.Names), folder);
        end
        
        
    catch
        % Assume failed simulation if something is wrong
        CF = 1000;
        CF_Comp = 1000 * ones(1,length(pMetrics.uComponents));
        CF_Vars = 1000 * ones(1,length(pMetrics.VarsWeights));
        CF_Freq = struct('MRi',nan(12,10), 'MAbs',nan(12,10));
        pMetrics = [];
        Metrics = [];
        RunsStats = [];
    end
end