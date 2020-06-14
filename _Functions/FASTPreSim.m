%% FASTPreSim Simulink presimulation file
% ref: fRunFAST.m from non-parallel ATLAS challenge
%    INPUTS
%       in                         % The Model Workspace
%       runCase                    % The Input load case 
%       hSetControllerParameter    % Handel to the user function that establishes the controller parameters
%       RootOutputFolder           % Where the output files are to be placed 
%       FASTInputFolder            % Where the input files are
%       Challenge                  % 'Onshore' or 'Offshore'
%       Controller                 % Passed to SetControllerParameters()
%       tmpSysMdl                  % Passed to SetControllerParameters()
%       parameters                 % Passed to SetControllerParameters()
%
% This function copies all the required input files for the Simulink
% workspace and sets all model parameters, including the user parameters
% defined in the set model parameters file.
%
function in = FASTPreSim(in, runCase, hSetControllerParameter, RootOutputFolder, FASTInputFolder, Challenge, Controller, tmpSysMdl, parameters)
%% Prepend simulation name with timestamp & (hopefully) unique 4 character tag
tStamp = [datestr(now,'YYYYmmDD-HHMMSS') '_' dec2hex(randi(2^16),4)]; % Add a random 4 char in case two parallel processes start at the same time (occurs at the initial simulations)
runName = [tStamp '_' runCase];
OutputFolder = [RootOutputFolder runName '/'];
mkdir(OutputFolder);

%% Copy FAST case input files
% This way the output file automatically has the time-stamped name
copyfile([FASTInputFolder runCase '.fst'], [FASTInputFolder runName '.fst'])
copyfile([FASTInputFolder runCase '_ED.dat'], [FASTInputFolder runName '_ED.dat'])
copyfile([FASTInputFolder runCase '_HD.dat'], [FASTInputFolder runName '_HD.dat'])
copyfile([FASTInputFolder runCase '_IW.dat'], [FASTInputFolder runName '_IW.dat'])
copyfile([FASTInputFolder runCase '_SD.dat'], [FASTInputFolder runName '_SD.dat'])

%% constants and specific to a given simulation.
fstFName  = [FASTInputFolder runName '.fst'];
    fprintf('\n');
    fprintf('-----------------------------------------------------------------------------\n');
    fprintf('>>> Simulating: %s \n',fstFName);
    fprintf('-----------------------------------------------------------------------------\n');

%% set model and user controler parameters 
Parameter = fSetSimulinkParameters(fstFName, hSetControllerParameter, Controller, tmpSysMdl, parameters);     
    
%% Send parameters to model
if isa(in, 'Simulink.SimulationInput')
    
    % Input is a Simulink simulation input object
    in = in.setVariable('runCase', runCase);
    in = in.setVariable('runName', runName);
    in = in.setVariable('Challenge', Challenge);
    in = in.setVariable('RootOutputFolder', RootOutputFolder);
    in = in.setVariable('OutputFolder', OutputFolder);
    in = in.setVariable('FASTInputFolder', FASTInputFolder);
    in = in.setVariable('Parameter', Parameter);
    in = in.setVariable('CParameter', Parameter.CParameter);
 
elseif isa(in, 'Simulink.ModelWorkspace')
    
    % Input is a model workspace handle
    in.assignin('runCase', runCase);
    in.assignin('runName', runName);
    in.assignin('Challenge', Challenge);
    in.assignin('RootOutputFolder', RootOutputFolder);
    in.assignin('OutputFolder', OutputFolder);
    in.assignin('FASTInputFolder', FASTInputFolder);
    in.assignin('Parameter', Parameter) ;
    in.assignin('CParameter', Parameter.CParameter);
    
else
    error('Unknown Model type, check the simulink system model file');
end
end