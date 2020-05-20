%% MLC_eval Evaluates the fitness of an individual for a single case
%
%   INPUTS
%       ind - Current mlc.individual
%       MLC_params - mlc.parameters
%       idvN - Individual number???
%       hFig - Figure handle for plot
%       genN - Current generation
%
function [J, simOut] = Par_eval(Controler, parameters, hFig, caseN)
simOut = {};
%try
    %% Extract MLC problem variables specified when calling `MLC_cfg()`

    % load cases
    runCase = parameters.runCases{caseN};

    % Simulink system model
    sysMdl = parameters.sysMdl;

    % Controler law function (if applicable)
    controlerflag = 0;
    if parameters.ctrlMdl{1} ~= 'none'
        Ctrllaw  = parameters.ctrlMdls(Controler);
        controlerflag = 1;
    end
    
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
    
    %% Setup simulation
    
%    Need to incert the controlers function into the system model, Depends on how we want to set this up?

%     % Parse indvidual's expressions 
%     [~,fcnText] = MLC_exprs(Controler.formal, parameters);
%     
%     % Get `Fcn` block handle
%     hb = find(slroot, '-isa', 'Stateflow.EMChart', 'Path', ...
%         sprintf('%s/MLC_IPC/control_law', tmpSysMdl) );
% 
% 	% Insert the expressions into the model    	
% 	hb.Script = fcnText;

    %% Run simulation

    % Choose a design load case in the event that input case number is not given
    if ~(exist('caseN','var') && ~isempty(caseN))
        
        % Chose a random case
        caseN = randi(length(runCase));
        
    end
    
    % Setup simulation with presimulation function
    hws = get_param(tmpSysMdl,'modelWorkspace');
    FASTPreSim(hws,runCase, ...
            @(pSim)hSetControllerParameter(pSim), ...
            RootOutputFolder, ...
            FASTInputFolder, ...
            Challenge, []);

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
        disp('  MLC_EVAL: Simulation returned error');
        J = parameters.badvalue;

        % Switch all of the workers back to their original folder.
        close_system(tmpSysMdl, 0);
        cd([parameters.problem_variables.RootOutputFolder '../'])
        try
            rmdir(tmpDir,'s');
        catch e
            warning(e.message)
        end
        
        clear mex;
        return
        
    end
    
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
%     J = parameters.badvalue;
%    
%end

clear mex;
end