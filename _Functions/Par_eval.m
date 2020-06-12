%% MLC_eval Evaluates the fitness of an individual for a single case
%
%   INPUTS
%
function [J, simOut] = Par_eval(Controler, runCase, parameters)
try
    %% Extract MLC problem variables specified when calling `MLC_cfg()`

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
    
    % Setup simulation with presimulation function
    hws = get_param(tmpSysMdl,'modelWorkspace');
    FASTPreSim(hws,runCase, ...
        hSetControllerParameter, ...
        RootOutputFolder, ...
        FASTInputFolder, ...
        Challenge, Controler, tmpSysMdl);
    
    % Try running simulation and computing cost
    try
        
        % Run simulation
        sim(tmpSysMdl);
        
        % Process output
        simOut = FASTPostSim([],[], runCase, ...
            hws.getVariable('runName'), FASTInputFolder, ...
            hws.getVariable('OutputFolder'), Challenge, parameters.statsBase);
        
        % Compute cost from output
        J = simOut.CF;
        
    catch e
        
        warning(e.message)
        disp('  PAR_EVAL: Simulation returned error');
        simOut.CF = 1000;
        J = simOut.CF;
        
    end
    
    %% Switch all of the workers back to their original folder.
    
    close_system(tmpSysMdl, 0);
    cd([parameters.RootOutputFolder '../'])
    
    try
        rmdir(tmpDir,'s');
    catch e
        warning(e.message)
    end
    
catch e
    
    cd([parameters.RootOutputFolder '../'])
    warning(e.message)
    simOut.CF = 1000;
    J = simOut.CF;
    
end

% Close all Simulink system windows unconditionally
bdclose('all')
% Clean up worker repositories
Simulink.sdi.cleanupWorkerResources
% https://www.mathworks.com/matlabcentral/answers/385898-parsim-function-consumes-lot-of-memory-how-to-clear-temporary-matlab-files
sdi.Repository.clearRepositoryFile
% ckear all mex foles from memoory (important to prevent useing too much
% memory, must be within this function to avoid trainsparency errors)
clear mex

end