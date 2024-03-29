%% Main_Par Computes total cost function for  all specified load cases and control laws in parallel.
% requires parallel processing MATLAB toolbox. Otherwise will compute in series

%% Example 2
% Example 2 attempts to tune the Proportional and Integral Gains on the baseline PI controller 
% to run this example input the command below into the command window:

%      TunedGains = fminsearch(@(U)fMain_Par_Ex2(U),[0.006275604; 0.0008965149])

%NOTE 1: Initial conditiona are set to the initial tuned gains of the
%baseline controler, changing these may cause this example to TAKE A VERY 
%LONG TIME TO FINISH AND WILL CONSUME A LOT OF MEMORY

%NOTE 2: the clear all comand a the begining is modified to prevent the
%fminsearch variables from being cleared from workspace

%% Initialization
restoredefaultpath;
clearvars -except U
clc; dbstop if error

addpath(genpath([pwd,'/_Functions']));    % Matlab functions for cost function and running cases - RaddEAD ONLY
addpath(genpath([pwd,'/_Controller']));   % Simulink model, where user scripts and models are placed
addpath(genpath([pwd,'/ParforProgMon'])); % Paralell progress monitor (https://github.com/fsaxen/ParforProgMon)
addpath(genpath([pwd]))

%% User Input Parameters
%____________________________________________________________________________________________________________________________________
% parameters for this analysis & machine
Challenge               = 'Offshore'                                        ; % 'Offshore' or 'Onshore', important for cost function

% -- Load cases and OpenFAST inputs 
FASTInputFolder         = [pwd '/_Inputs/LoadCases/']                       ; % directory of the FAST input files are (e.g. .fst files)
case_file               = [pwd '/_Inputs/_inputs/Cases.csv']                ; % File defining the cases that are run
case_subset             = []                                                ; % run a subset of cases specified in the case_file, 
                                                                              % Eg: [3 5 7] will run the third, fifth, and 7th load cases specified in case_file
                                                                              % Leave empty [] to run all cases specified in case_file 

% -- Output Folders                                                                 
BaselineFolder          = [pwd '/_BaselineResults/']                        ; % Folder where reference simulations Of baseline controler are located
PreProFile              = [BaselineFolder 'PrePro_' Challenge '_AllCases.mat']; % preprocessed baseline file to speed up preprocessing, leave empty to compute baseline stats from case file 
RootOutputFolder        = [pwd '/_Outputs/']                                ; % Folder where the current simulation outputs will be placed
 
% -- Plotting
%which figures should be plotted at the end of simulation,  
%'plot'   will plot the figure specified in the line 
plotTag = struct('Rel_FreqComp',             'no  ', ...                    % Relative contribution by frequency and component                             
                 'Rel_Comp',                 'no  ', ...                    % Relative contribution per component
                 'Abs_FreqComp',             'no  ', ...                    % Absolute contribution by frequency and component
                 'Abs_Comp',                 'plot', ...                    % Absolute contribution per component
                 'Combine',                  'no'  );                       % 'yes' will combine all controlers into one plot, 
                                                                            % else will plot all requested charts against the base line in individual plots

% -- Other User Options                                                                
verbose                 = 1                                                 ; % level of verbose output (0, 1, 2) Currently Unused
                                                                                                                                
%_____________________________________________________________________________________________________________________________________
% Multiple controller models (should be in the folder ctrlFolder specified below)

ctrlFolder              = [pwd '/_Controller/Example2/'];        

% Reference to model for system, AKA Simulink model with FAST_SFunc() block in it
sysMdl                  = 'NREL5MW_Baseline'; 

% if multiple controller laws/parameters are to be tested ctrlMdls should be a cell array of all the
% laws/parameters and should be compatible with the commands in the fSetControllerParameters.m file 
ctrlMdls                = {[U(1); U(2)]};    % PI Gains from the FMINSEARCH function    

% handle to the function which sets the Controller parameter 
hSetControllerParameter = @fSetControllerParametersEx2; 

% for plotting purposes only, what name do you want it to be called in the graphics
ctrl_names              = {'Tuned Baseline Controler'};

%% Preprocessing 

% Baseline statistics
CasesBase = fReadCases(case_file,case_subset); 
runCases = CasesBase.Names;
pMetricsBC = fMetricVars(CasesBase, Challenge);                                  

if ~exist(PreProFile,'file') 
    statsBase = fComputeOutStats(BaselineFolder, pMetricsBC, CasesBase);
else
    statsBase = load(PreProFile);
end

metricsBase = fEvaluateMetrics(statsBase, pMetricsBC);

% Build structure of these parameters to pass to the parfor loop    
Parameters = PVar_cfg(runCases ,sysMdl, ctrlMdls, hSetControllerParameter, ctrlFolder,...
    RootOutputFolder, FASTInputFolder, Challenge, verbose, statsBase, metricsBase);

%% evaluation 

% establish loop variables & Preallocate output array
nCases = numel(Parameters.runCases);
nControlers = numel(ctrlMdls);                       
J = cell(nCases, nControlers);
simOut = J;

% Create parfor progress monitor
pp = gcp(); 
ppm = ParforProgMon(sprintf('Fast Turbine Eval - %i controlers w/ %i cases %s: ', ...
    nControlers, nCases, datestr(now,'HH:MM')), nCases*nControlers, 1,1200,160);

% Evaluate all the controllers, and cases
parfor idx = 1 : (nCases * nControlers)
    [caseN, controlerN] = ind2sub([nCases, nControlers], idx);    

    [J{idx}, simOut{idx}] = Par_eval(ctrlMdls{controlerN},Parameters.runCases{caseN}, Parameters);

    %increment PPM tracker and ignore the warning
    ppm.increment(); %#ok<PFBNS>
end

%% Compute aggregate cost function of each controller form the simulation output array

%preallocate 
CF = struct('CF',-1, 'CF_Comp',-1,'CF_Vars',-1, 'CF_Freq',-1);
CF(nControlers) = CF;

%Baseline Stats 
[blCF, blCF_Comp, blCF_Vars, blCF_Freq] = fCostFunction(metricsBase.Values, metricsBase.Values, pMetricsBC);
BL = struct('blCF',blCF,'blCF_Comp',blCF_Comp,'blCF_Vars',blCF_Vars,'blCF_Freq',blCF_Freq);

for cN = 1:nControlers
    % Compute agregate cost function
    [CF(cN).CF, CF(cN).CF_Comp, CF(cN).CF_Vars, CF(cN).CF_Freq, ~, ~, ~]...
    = fCostFunctionSimOut(simOut(:,cN), Challenge, metricsBase, pMetricsBC);
end

%plot the figures the user asked for 
fBuildPlots(CF, BL, pMetricsBC, plotTag, ctrl_names)

