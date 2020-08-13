%% Par_eval Evaluates one controller under one run case and produces the simout and cost function of the system
%
%   INPUTS
%       Controller: The controller as specified by the user in Main_Par.m
%       runCase: The name of the load case file for the FAST Turbine model
%       parameters: Structure of user defined and constant parameters, See PVar_cfg()
%
%   OUTPUTS
%       J: The cost function of "Controller" under load case "runcase"
%       simOut: Structure of all simulation input parameters, output signals, and cost function components
%
%Par_eval builds a temporary directory for the Simulink model with the
%specified parameters. This allows each parallel worker to work in its own
%unique directory to prevent the FastSFunc() Simulink block from
%overwriting simulation output from other parallel simulations.


function [J, simOut] = Par_eval(Controller, runCase, parameters)
try
%% Extract useful parameters

% Simulink system model
sysMdl = parameters.sysMdl;
% Handle to function that sets controller parameters
hSetControllerParameter = parameters.hsetctrlparam;
% Directories
RootOutputFolder = parameters.RootOutputFolder;
FASTInputFolder = parameters.FASTInputFolder;
% Name of challenge
Challenge = parameters.Challenge;

%% Load the simulink model for editing parameters
%   Work in a temporary directory, Important for parfor workers to work in unique directory

% Setup temporary directory and change it to the current directory
tmpDir = tempname;
mkdir(tmpDir); 
cd(tmpDir);

% Create a copy of the model to make changes
tmpSysMdl = split(tmpDir,filesep);
tmpSysMdl = tmpSysMdl{end};

try
    copyfile([parameters.ctrlFolder sysMdl '.mdl'], ['./' tmpSysMdl '.mdl']);
catch e
    warning('Could not find system model file to copy, check Main_par where the system model is defined and make sure the system model is in the correct folder')
    rethrow(e);
end

% Load the model on the worker
load_system(tmpSysMdl)

%% Run simulation

% Setup simulation with presimulation function see FASTPreSim()
hws = get_param(tmpSysMdl,'modelWorkspace');
FASTPreSim(hws,...                         % The Model Workspace
           runCase,...                     % The Input load case 
           hSetControllerParameter, ...    % Handel to the user function that establishes the controller parameters
           RootOutputFolder, ...           % Where the output files are to be placed 
           FASTInputFolder, ...            % Where the input files are
           Challenge, ...                  % 'Onshore' or 'Offshore'
           Controller, ...                 % Passed to SetControllerParameters()
           tmpSysMdl, ...                  % Passed to SetControllerParameters()
           parameters);                    % Passed to SetControllerParameters()

% Try running simulation and computing cost
try

    % Run simulation
    sim(tmpSysMdl);

    % Process output files
    simOut = FASTPostSim([],[], runCase, ...
        hws.getVariable('runName'), FASTInputFolder, ...
        hws.getVariable('OutputFolder'), Challenge, parameters.statsBase);

    % Compute cost from output
    J = simOut.CF;

catch e

    warning(e.message)
    disp('PAR_EVAL: Simulation returned error');
    simOut.CF = 1000;
    J = simOut.CF;
    simOut.runCase = runCase;

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
simOut.runCase = runCase;

end

%% Conserve Memory by un-loading the model and C++ files from memory
% Close all Simulink system windows unconditionally
bdclose('all')
% Clean up worker repositories
Simulink.sdi.cleanupWorkerResources
% https://www.mathworks.com/matlabcentral/answers/385898-parsim-function-consumes-lot-of-memory-how-to-clear-temporary-matlab-files
sdi.Repository.clearRepositoryFile
% clear all mex files from memory (important to prevent using too much memory, must be within this function to avoid transparency errors)
clear mex
 
%NOTE: it appears there are still some small memory leaks in the script, If running a large number of simulations a large amount of memory should be allocated to prevent overloading memory the
%   The script cost a little less than 875 MB of ram per worker.   
end