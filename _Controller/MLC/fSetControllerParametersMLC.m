function [Parameter] = fSetControllerParametersMLC(Parameter, Controller, tmpSysMdl, parameters)
%% Controller parameters for the Collective Pitch Controller (CPC)

%for matlab functionblock model, must be a structure called Parameter.CParameter

%Cparameter structure is extraced from Parameter structure  and sent as a structurere to the
%simulink workspace

%CParameter must be a one level structure of static values, or else simulink will return an error.  

Parameter.CParameter = parameters.outListIdx;    %names of signals in outlist, for ease of calling within custom function

%BASELINE CPC Parameters

KP          = 0.006275604;               % [s] detuned gains
KI          = 0.0008965149;              % [-]
                  
Parameter.CPC.kp                  = KP;                                % [s]
Parameter.CPC.Ti                  = KP/KI;                             % [s] 
Parameter.CPC.theta_K             = deg2rad(6.302336);                 % [rad]
Parameter.CPC.Omega_g_rated       = Parameter.Turbine.Omega_rated/Parameter.Turbine.i;  % [rad/s]
Parameter.CPC.theta_max           = Parameter.PitchActuator.theta_max; % [rad]
Parameter.CPC.theta_min           = Parameter.PitchActuator.theta_min; % [rad]

%% MLC Control parameters

% System information
Parameter.MLC.totNSensors = 110;
Parameter.MLC.gain = 1E-2;

% Constraints
Parameter.assert.pitchVLim = 10;    % [deg/s]
Parameter.assert.twrClear = -4;     % [m]
Parameter.assert.twrTopAcc = 3.3;   % [m/s2]
Parameter.assert.rotSpeed = 15.73;  % [rpm]
Parameter.assert.minGenPwr = 1;     % [W]

%% Derived MLC parameters
    
    % FAST Output Array index names
    Parameter.outListIdx = parameters.MLC_parameters.problem_variables.outListIdx;
    Parameter.outListLen = length(fieldnames(parameters.outListIdx));
    Parameter.sensorIdxs = parameters.MLC_parameters.problem_variables.sensorIdxs;

    % Values for signal normalization
    Parameter.sensorsNormOffset = ...
        parameters.MLC_parameters.problem_variables.BaselineMean;    
    Parameter.sensorNormGain = ...
        parameters.MLC_parameters.problem_variables.BaselineDetrendRMS;
    Parameter.sensorNormGain(isinf(Parameter.sensorNormGain)) = 0;
    


%% Insert controler login into matlab function block
%coppies text from specified matlab function and pastes it into the matlab
%finction block of the simulink model.

% Parse indvidual's expressions 
fcnText = Controller;

% Get `Fcn` block handle
hblock = find(slroot, '-isa', 'Stateflow.EMChart', 'Path', sprintf('%s/MLC_IPC/Control_Law', tmpSysMdl) );

% Insert the expressions into the mode-l 
hblock.Script = fcnText;

end
