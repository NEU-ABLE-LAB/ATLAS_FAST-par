function [Parameter] = fSetControllerParametersEx1(Parameter,...
    Controler, tmpSysMdl, parameters)
%% Controller parameters for the Collective Pitch Controller (CPC)

%for matlab functionblock model, must be a structure called Parameter.CParameter

%Cparameter structure is extraced from Parameter structure  and sent as a structurere to the
%simulink workspace

%CParameter must be a one level structure of static values, or else simulink will return an error.  

Parameter.CParameter = parameters.outListIdx;    %names of signals in outlist, for ease of calling within custom function

%BASELINE CPC Parameters

KP          = 0.006275604;               % [s] detuned gains
KI          = 0.0008965149;              % [-]
                  
Parameter.CParameter.kp                  = KP;                                % [s]
Parameter.CParameter.Ti                  = KP/KI;                             % [s] 
Parameter.CParameter.theta_K             = deg2rad(6.302336);                 % [rad]
Parameter.CParameter.Omega_g_rated       = Parameter.Turbine.Omega_rated/Parameter.Turbine.i;  % [rad/s]
Parameter.CParameter.theta_max           = Parameter.PitchActuator.theta_max; % [rad]
Parameter.CParameter.theta_min           = Parameter.PitchActuator.theta_min; % [rad]
Parameter.CParameter.Enable              = Parameter.Filter.FilterGenSpeed.Omega_g.Enable;
Parameter.CParameter.T63                 = Parameter.Filter.FilterGenSpeed.T63;
Parameter.CParameter.theta_dot_FF        = 0;                                 % Hard coded as zero into origional simulink model

%% Insert controler login into matlab function block
%coppies text from specified matlab function and pastes it into the matlab
%finction block of the simulink model.

% Parse indvidual's expressions 
fcnText = fileread(Controler);

% Get `Fcn` block handle
hblock = find(slroot, '-isa', 'Stateflow.EMChart', 'Path', sprintf('%s/IPC/Control_Law', tmpSysMdl) );

% Insert the expressions into the mode-l 
hblock.Script = fcnText;

end
