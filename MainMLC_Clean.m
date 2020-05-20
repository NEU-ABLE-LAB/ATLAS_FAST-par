%% Main_Paralell Computes total cost function for  all specified load caces and controll laws in paralell.
%requires paralell processing matlab toolbox. otherwise will compute in series

restoredefaultpath;
clear all
clc
dbstop if error

%% Initialization
% ref: Main.m
addpath(genpath([pwd,'/_Functions']));    % Matlab functions for cost function and running cases - READ ONLY
addpath(genpath([pwd,'/_Controller']));   % Simulink model, where user scripts and models are placed
addpath(genpath([pwd,'/ParforProgMon'])); % Paralell progress monitor (https://github.com/fsaxen/ParforProgMon)

%% User Input Parameter list

% parameters for this analysis & machine
Challenge              = 'Offshore'                          ; % 'Offshore' or 'Onshore', important for cost function
FASTInputFolder        = [pwd '/_Inputs/LoadCases/']         ; % directory of the FAST input files are (e.g. .fst files)
case_file              = [pwd '/_Inputs/_inputs/Cases.csv']  ; % File defining the cases that are run
BaselineFolder         = [pwd '/_BaselineResults/']          ; % Folder where "reference simulations are located"
RootOutputFolder       = [pwd '/_Outputs/']                  ; % Folder where the current simulation outputs will be placed
ctrlFolder             = [pwd '/_Controller/']               ; % Location of Simulink files
verbose                = 1                                   ; % level of verbose output (0, 1, 2)
 
sysMdl                 = 'NREL5MW_Baseline'                  ; % Reference to model for system, AKA simulink model with Fast_SFunction() block in it
ctrlMdls               = {'none'}                            ; % if multiple controller laws are to be tested this should be a cell array of all the controler laws/parameter functions (in a .m file compatible woth the controler blocks in system model) 

%NOTE: if system model is a stand alone simulink model with no variable
%controlers to test input "none" in the ctrlMdls cell

%% Preprocessing Parameters

% Load case and metrics init
CasesBase = fReadCases(case_file);   % load case inputs for Fast environment
runCases = CasesBase.Names;          % the names of the load case files to be run (Cell Array)

% handle to the function which sets the Controller parameter (should be in the folder '_Controller')
hSetControllerParameter = @fSetControllerParametersOffshore; 

%% Baseline statistics

CasesBase = fReadCases(case_file);                                             
pMetricsBC = fMetricVars(CasesBase, Challenge);                                  
PreProFile= [BaselineFolder 'PrePro_' Challenge '.mat'];                         

if ~exist(PreProFile,'file')
    statsBase = fComputeOutStats(BaselineFolder, pMetricsBC, CasesBase);
else
    statsBase = load(PreProFile);
end

metricsBase = fEvaluateMetrics(statsBase, pMetricsBC);

%% Build sreucture of these parameters to pass to the parfor loop    
Parameters = PVar_cfg(runCases ,sysMdl, ctrlMdls, hSetControllerParameter, ...
    ctrlFolder, RootOutputFolder, FASTInputFolder, ...
    Challenge, verbose, statsBase, metricsBase);

%% Setup for evaluation 

% establish loop variables & Prealocate output array
nCases = numel(Parameters.runCases);
nControlers = numel(ctrlMdls);                       
simOut = cell(nControlers,nCases);

%% Create parfor progress monitor            ######(Jim TO DO)######
pp = gcp(); 
ppm = ParforProgMon(...
    sprintf('Fast Turbine Eval - %i controlers w/ %i cases %s: ', ...
        nControlers, nCases, datestr(now,'HH:MM')), ...
   nCases*nControlers, 1,1200,160);

%% Evaluate all the controlerss, and cases

parfor idx = 1 : (nCases * nControlers)
%for idx = 1 : (nCases * nControlers)
    
    [caseN, controlerN] = ind2sub([nCases, nControlers], idx); 

    % Comptue cost of individual 
    
    [~, simOut{idx}] = Par_eval(ctrlMdls{controlerN}, Parameters, [], caseN);
    
    % Close all Simulink system windows unconditionally
    bdclose('all')
    % Clean up worker repositories
    Simulink.sdi.cleanupWorkerResources
    % https://www.mathworks.com/matlabcentral/answers/385898-parsim-function-consumes-lot-of-memory-how-to-clear-temporary-matlab-files
    sdi.Repository.clearRepositoryFile
    
    %ppm.increment(); %#ok<PFBNS>
    
end
