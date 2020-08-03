%% Main_Par Computes total cost function for  all specified load cases and control laws in parallel.
% requires parallel processing MATLAB toolbox. Otherwise will compute in series

%% Initialization
restoredefaultpath;

addpath(genpath([pwd,'/_Functions']));    % Matlab functions for cost function and running cases - RaddEAD ONLY
addpath(genpath([pwd,'/_Controller']));   % Simulink model, where user scripts and models are placed
addpath(genpath([pwd,'/ParforProgMon'])); % Paralell progress monitor (https://github.com/fsaxen/ParforProgMon)
addpath(genpath(['D:\Documents\GitHub\ATLAS_Offshore\OpenMLC-Matlab-2'])) % Needed for MLC object MLCParameters

%% User Input Parameters
%____________________________________________________________________________________________________________________________________
% parameters for this analysis & machine
Challenge               = 'Offshore'                                        ; % 'Offshore' or 'Onshore', important for cost function

% -- Load cases and OpenFAST inputs 
FASTInputFolder         = [pwd '/_Inputs/LoadCases/']                       ; % directory of the FAST input files are (e.g. .fst files)
case_file               = [pwd '/_Inputs/_inputs/Cases.csv']                ; % File defining the cases that are run
case_subset             = MLC_Runcase                                       ; % run a subset of cases specified in the case_file, 
                                                                              % Eg: [3 5 7] will run the third, fifth, and 7th load cases specified in case_file
                                                                              % Leave empty [] to run all cases specified in case_file
                                                                              % incert 'random' to run 1 random load case for easch controler specified 
if case_subset == 'random'          %needs to be a number
    case_subset = [];
end                                                                              
                                                                              
                                                                              
                                                                              
% -- Output Folders                                                                 
BaselineFolder          = [pwd '/_BaselineResults/']                        ; % Folder where reference simulations Of baseline controler are located
PreProFile              = []                                                ; % preprocessed baseline file to speed up preprocessing, leave empty to compute baseline stats from case file 
RootOutputFolder        = [pwd '/_Outputs/']                                ; % Folder where the current simulation outputs will be placed
 
% -- Plotting
%which figures should be plotted at the end of simulation,  
%'plot'   will plot the figure specified in the line 
plotTag = struct('Rel_FreqComp',             'no  ', ...                    % Relative contribution by frequency and component                             
                 'Rel_Comp',                 'no  ', ...                    % Relative contribution per component
                 'Abs_FreqComp',             'no  ', ...                    % Absolute contribution by frequency and component
                 'Abs_Comp',                 'no  ', ...                    % Absolute contribution per component
                 'Combine',                  'no  ');                       % 'yes' will combine all controlers into one plot, 
                                                                            % else will plot all requested charts against the base line in individual plots

% -- Other User Options                                                                
verbose                 = 1                                                 ; % level of verbose output (0, 1, 2) Currently Unused
                                                                                                                                
%_____________________________________________________________________________________________________________________________________
% Multiple controller models (should be in the folder ctrlFolder specified below)

ctrlFolder              = [pwd '/_Controller/MLC/'];        

% Reference to model for system, AKA Simulink model with FAST_SFunc() block in it
sysMdl                  = 'NREL5MW_Fcnblock_MLC_2018'; 

% if multiple controller laws/parameters are to be tested ctrlMdls should be a cell array of all the
% laws/parameters and should be compatible with the commands in the fSetControllerParameters.m file 
ctrlMdls                = fcnText;    

% handle to the function which sets the Controller parameter 
hSetControllerParameter = @fSetControllerParametersMLC; 

% for plotting purposes only, what name do you want it to be called in the graphics
ctrl_names              = {};

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

Parameters.MLC_parameters = MLC_params;
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
if MLC_Runcase == 'random' 
    nCases = 1;
end

parfor idx = 1 : (nCases * nControlers)
    [caseN, controlerN] = ind2sub([nCases, nControlers], idx);    
    
    if MLC_Runcase == 'random'
        caseN = randi(12)
    end
    
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

