%% MLC_eval Evaluates the fitness of an individual for a single case
%
%   INPUTS
%       ind - Current mlc.individual
%       MLC_params - mlc.parameters
%       idvN - Individual number???
%       hFig - Figure handle for plot
%       genN - Current generation
%
function [J, simOut] = Par_evaldebug(Controler, parameters, hFig, caseN)
simOut = {};
%try
    %% Extract MLC problem variables specified when calling `MLC_cfg()`

    % load cases
    runCase = parameters.runCases{caseN};

    % Simulink system model
    sysMdl = parameters.sysMdl;
    
    % Handle to function that sets controller parameters
    hSetControllerParameter = ...
            parameters.hsetctrlparam;

    % Directories
    RootOutputFolder = parameters.RootOutputFolder;
    FASTInputFolder = parameters.FASTInputFolder;

    % Name of challenge
    Challenge = parameters.Challenge;
    
    %% Load the simulink model for editing parameters
    %   Work in a temporary directory
    %   Important for parfor workers

    % Setup tempdir and cd into it
    tmpDir = tempname;
    mkdir(tmpDir);
    cd(tmpDir);

	% Create a copy of the model to make changes
    tmpSysMdl = split(tmpDir,filesep);
    tmpSysMdl = tmpSysMdl{end};
    try
        copyfile([parameters.ctrlFolder sysMdl '.mdl'],...
            ['./' tmpSysMdl '.mdl']);
    catch e
        warning('Could not find system model file to copy')
        rethrow(e);
    end

    % Load the model on the worker
    load_system(tmpSysMdl)
    
    %% Run simulation

    % Choose a design load case in the event that input case number is not given
    if ~(exist('caseN','var') && ~isempty(caseN))
        
        % Chose a random case
        caseN = randi(length(runCase));
        
    end
    
    % Setup simulation with presimulation function
    hws = get_param(tmpSysMdl,'modelWorkspace');
    FASTPreSim(hws,runCase, ...
            hSetControllerParameter, ...
            RootOutputFolder, ...
            FASTInputFolder, ...
            Challenge, Controler);

    % Try running simulation and computing cost
%    try

        % Run simulation
        sim(tmpSysMdl);
        
        % Process output
        simOut = FASTPostSim([],[], runCase, ...
            hws.getVariable('runName'), FASTInputFolder, ...
            hws.getVariable('OutputFolder'), Challenge, parameters.statsBase);

        % Compute cost from output
        J = simOut.CF;

%      catch e
% 
%         warning(e.message)
%         disp('  MLC_EVAL: Simulation returned error');
%         J = 1000;
% 
%         % Switch all of the workers back to their original folder.
%         close_system(tmpSysMdl, 0);
%         cd([parameters.RootOutputFolder '../'])
%         try
%             rmdir(tmpDir,'s');
%         catch e
%             warning(e.message)
%         end
%         
%         clear mex;
%         return
%         
%    end
    
    %% Switch all of the workers back to their original folder.
    
    close_system(tmpSysMdl, 0);
    cd([parameters.RootOutputFolder '../'])
    
    try
        rmdir(tmpDir,'s');
    catch e
        warning(e.message)
    end
    
    %% Plot figure if requested
    if exist('hFig','var') && ~isempty(hFig)
        fCostFunctionPlot(simOut.CF, simOut.CF_Comp, ...
            simOut.CF_Vars, {simOut.CF_Freq}, ...
            fMetricVars(runCase(caseN), Challenge), ...
            {'',sysMdl});
    end
    
% catch e
%     
%     cd([parameters.RootOutputFolder '../'])
%     warning(e.message)    
%     J = 1000;
%    
% end

% Close all Simulink system windows unconditionally
bdclose('all')
% Clean up worker repositories
Simulink.sdi.cleanupWorkerResources
% https://www.mathworks.com/matlabcentral/answers/385898-parsim-function-consumes-lot-of-memory-how-to-clear-temporary-matlab-files
sdi.Repository.clearRepositoryFile



clear mex;
end