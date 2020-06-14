function [Parameter] = fSetControllerParametersFcnblock1(Parameter, Controller, tmpSysMdl, parameters)
%% Controller parameters for the Collective Pitch Controller (CPC)

%for matlab functionblock model, must be a structure called Parameter.CParameter

%Cparameter structure is extraced from Parameter structure  and sent as a structurere to the
%simulink workspace

%CParameter must be a one level structure of static values, or else simulink will return an error.  

Parameter.CParameter = parameters.outListIdx;    %names of signals in outlist, for ease of calling within custom function

%Controler Parameters:
%Parameter.CParameter.Parameter1 = 
%Parameter.CParameter.Parameter2 = 
%Parameter.CParameter.Parameter3 = 

%% Insert controler login into matlab function block
%coppies text from specified matlab function and pastes it into the matlab
%finction block of the simulink model.

% Parse indvidual's expressions 
fcnText = fileread(Controller);

% Get `Fcn` block handle
hblock = find(slroot, '-isa', 'Stateflow.EMChart', 'Path', sprintf('%s/IPC/Control_Law', tmpSysMdl) );

% Insert the expressions into the mode-l 
hblock.Script = fcnText;

end
