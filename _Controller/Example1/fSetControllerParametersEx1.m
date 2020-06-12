function [Parameter] = fSetControllerParametersEx1(Parameter,...
    Controler, tmpSysMdl, parameters)
% Sets the controller parameter.
% This function takes a structure and supplements it with additional fields for the controller parameters.
% 
% NOTE: THE FIELDS ALREADY PRESENT IN THE INPUT STRUCTURE SHOULD NOT BE CHANGED. IT IS AGAINST THE COMPETITION's RULES.
% 
% 
% INPUTS:
%    Parameter: a structure containing information about the turbine and the operating conditions of the simulation
%
% OUTPUTS:
%    Parameter: the input structure supplemented with additional fields.
%
%    The (read only) fields present in the input structure are: 
%        % --- Turbine
%        Parameter.Turbine.Omega_rated = 12.1*2*pi/60 % Turbine rated rotational speed, 12.1rpm [rad/s]
%        Parameter.Turbine.P_el_rated  = 5e6 ; % Rated electrical power [W]
%        Parameter.Turbine.i           = 1/97; % The gear ratio
%        % --- Generator
%        Parameter.Generator.eta_el       = 0.944;                % [-]
%        Parameter.Generator.M_g_dot_max  = 15e3;                 % [-]
%        % --- PitchActuator, e.g.
%        Parameter.PitchActuator.omega         = 2*pi;             % [rad/s]
%        Parameter.PitchActuator.theta_max     = deg2rad(90);      % [rad]
%        Parameter.PitchActuator.theta_min     = deg2rad(0);       % [rad]
%        Parameter.PitchActuator.Delay         = 0.2;              % [s]
%        % -- Variable speed torque controller
%        Parameter.VSC   % Structure containing the inputs for the variable speed controller. READ ONLY.
%        % -- Initial Conditions, e.g.
%        Parameter.IC.theta   % Pitch angle [rad]              
%        % -- Simulation Params
%        Parameter.Time.TMax  % Simulation length [s]
%        Parameter.Time.dt    % Simulation time step [s]


%% Controller parameters for the Collective Pitch Controller (CPC)

Parameter.CParameter = parameters.outListIdx;


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

% Parse indvidual's expressions 
fcnText = fileread(Controler);

% Get `Fcn` block handle
hblock = find(slroot, '-isa', 'Stateflow.EMChart', 'Path', sprintf('%s/IPC/Control_Law', tmpSysMdl) );

% Insert the expressions into the model 
hblock.Script = fcnText;

end
