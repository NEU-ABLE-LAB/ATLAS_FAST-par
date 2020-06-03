%% Main_Paralell Computes total cost function for  all specified load caces and controll laws in paralell.
%requires paralell processing matlab toolbox. otherwise will compute in series

restoredefaultpath;
clear all
clc
dbstop if error

%% Initialization
% ref: Main.m
addpath(genpath([pwd,'/_Functions']));    % Matlab functions for cost function and running cases - RaddEAD ONLY
addpath(genpath([pwd,'/_Controller']));   % Simulink model, where user scripts and models are placed
addpath(genpath([pwd,'/ParforProgMon'])); % Paralell progress monitor (https://github.com/fsaxen/ParforProgMon)
addpath(genpath([pwd]))

%% User Input Parameter list

% parameters for this analysis & machine
Challenge              = 'Offshore'                          ; % 'Offshore' or 'Onshore', important for cost function
FASTInputFolder        = [pwd '/_Inputs/LoadCases/']         ; % directory of the FAST input files are (e.g. .fst files)
case_file              = [pwd '/_Inputs/_inputs/Cases.csv']  ; % File defining the cases that are run
BaselineFolder         = [pwd '/_BaselineResults/']          ; % Folder where "reference simulations are located"
RootOutputFolder       = [pwd '/_Outputs/']                  ; % Folder where the current simulation outputs will be placed
ctrlFolder             = [pwd '/_Controller/']               ; % Location of Simulink files
verbose                = 1                                   ; % level of verbose output (0, 1, 2)
 
sysMdl                 = 'NREL5MW_Fcnblock_V2'                  ; %  _fcnblock   Reference to model for system, AKA simulink model with Fast_SFunction() block in it

%% Multiple controler models
ctrlMdls               = {[0.006275604 0.0008965149]}        ; % if multiple controller laws are to be tested this should be a cell array of all the controler laws/parameter functions (in a .m file compatible woth the controler blocks in system model) 

%NOTE: if system model is a stand alone simulink model with no variable
%controlers to test input "none" in the ctrlMdls cell

ctrl_names = {'baseline fcnblocky'};



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
simOut = cell(nCases, nControlers);     %Each load case is a row, each controler is a column

%% Create parfor progress monitor
pp = gcp(); 
ppm = ParforProgMon(...
    sprintf('Fast Turbine Eval - %i controlers w/ %i cases %s: ', ...
    nControlers, nCases, datestr(now,'HH:MM')), ...
    nCases*nControlers, 1,1200,160);

%% Evaluate all the controlerss, and cases

%parfor idx = 1 : (nCases * nControlers)
for idx = 1 : (nCases * nControlers)
    [caseN, controlerN] = ind2sub([nCases, nControlers], idx); 
    
    % Comptue cost of individual 
%    [~, simOut{idx}] = Par_eval(ctrlMdls{controlerN}, Parameters, [], caseN);
    [~, simOut{idx}] = Par_evaldebug(ctrlMdls{controlerN}, Parameters, [], caseN);
        
    % increment PPM tracker and ignore the warning
    ppm.increment(); %#ok<PFBNS>
end

%% Compute aggregate cost function of each controler form the simulation output array

CF = struct('CF',-1, 'CF_Comp',-1,'CF_Vars',-1, 'CF_Freq',-1);
CF(nControlers) = CF;

[blCF, blCF_Comp, blCF_Vars, blCF_Freq] = fCostFunction(metricsBase.Values, metricsBase.Values, pMetricsBC);

for cN = 1:nControlers
    % Compute agregate cost function
    [CF(cN).CF, CF(cN).CF_Comp, CF(cN).CF_Vars, CF(cN).CF_Freq, ~, ~, ~]...
    = fCostFunctionSimOut(simOut(:,cN), Challenge, metricsBase, pMetricsBC);
   
    % Plot cost function graph 
    folders = {'','Baseline Results';'',cell2mat(ctrl_names(cN))};
    
    pCF = [blCF CF(cN).CF];
    pCF_Comp = [blCF_Comp; CF(cN).CF_Comp];
    pCF_Vars = [blCF_Vars; CF(cN).CF_Vars];
    pCF_Freq = {blCF_Freq, CF(cN).CF_Freq};
    
    fCostFunctionPlot(pCF, pCF_Comp, pCF_Vars, pCF_Freq, pMetricsBC, folders)
end