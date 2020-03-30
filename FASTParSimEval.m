%% FASTParSimEval Simulates FAST in parallel
function [J, simOut] = FASTParSimEval( runCase, sysMdl, ctrlParams, ...
    )

%% Load the simulink model for editing parameters
%   Work in a temporary directory
%   Important for parfor workers

%TODO SEE MLC_eval.com