%% Main_Par Computes total cost function for  all specified load cases and control laws in parallel.
% requires parallel processing MATLAB toolbox. Otherwise will compute in series

%% Example 1
% Example 1 computes the cost function for 3 controllers under 6 of the origional 12 load cases useing the Fcnblock model.
% the three controlers are:
%       the baseline controler
%       the baseline controler with larger gains (Kp = Kp_baseline * 5)
%       the baseline controler with smaller gains (Kp = Kp_baseline / 5)
%
% Results should be
%       the baseline controler will result in a cost function of 0.9999
%       the large gain controler will result in a cost function of 3.3762
%       the small gain controler will result in a cost function of 1000, as load case 11 results in the roter speed cronstraint being exceeded
%
%

%% Initialization
restoredefaultpath;
clear all; clc; dbstop if error

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
case_subset             = [1 2 3 5 7 11]                                    ; % run a subset of cases specified in the case_file, 
                                                                              % Eg: [3 5 7] will run the third, fifth, and 7th load cases specified in case_file
                                                                              % Leave empty [] to run all cases specified in case_file 

% -- Output Folders                                                                 
BaselineFolder          = [pwd '/_BaselineResults/']                        ; % Folder where reference simulations Of baseline controler are located
PreProFile              = []                                                ; % preprocessed baseline file to speed up preprocessing, leave empty to compute baseline stats from case file 
RootOutputFolder        = [pwd '/_Outputs/']                                ; % Folder where the current simulation outputs will be placed
 
% -- Plotting
%which figures should be plotted at the end of simulation,  
%'plot'   will plot the figure specified in the line 
plotTag = struct('Rel_FreqComp',             'plot', ...                    % Relative contribution by frequency and component                             
                 'Rel_Comp',                 'plot', ...                    % Relative contribution per component
                 'Abs_FreqComp',             'plot', ...                    % Absolute contribution by frequency and component
                 'Abs_Comp',                 'plot', ...                    % Absolute contribution per component
                 'Combine',                  'yes'  );                      % 'yes' will combine all controlers into one plot, 
                                                                            % else will plot all requested charts against the base line in individual plots

% -- Other User Options                                                                
verbose                 = 1                                                 ; % level of verbose output (0, 1, 2) Currently Unused
                                                                                                                                
%_____________________________________________________________________________________________________________________________________
% Multiple controller models (should be in the folder ctrlFolder specified below)

ctrlFolder              = [pwd '/_Controller/Example1/'];        

% Reference to model for system, AKA Simulink model with FAST_SFunc() block in it
sysMdl                 = 'NREL5MW_Fcnblock_V2_2018'; 

% if multiple controller laws/parameters are to be tested ctrlMdls should be a cell array of all the
% laws/parameters and should be compatible with the commands in the fSetControllerParameters.m file 
ctrlMdls                = {['Baseline_fcnblock.m'], ['Baseline_fcnblock_BigGain.m'], ['Baseline_fcnblock_SmallGain.m']};

% handle to the function which sets the Controller parameter 
hSetControllerParameter = @fSetControllerParametersEx1; 

% for plotting purposes only, what name do you want it to be called in the graphics
ctrl_names              = {'baseline fcnblock model', 'BL fcnblock, Big Gain', 'BL fcnblock, Big Gain'};

%% Preprocessing 

% Baseline statistics
CasesBase = fReadCases(case_file, case_subset); 
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

