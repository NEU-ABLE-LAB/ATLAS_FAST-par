# OpenFast - Parallel

This code package enables multiple instances of OpenFAST to be run in parallel. This could be useful for example, to simulate a suite of input cases and/or to test multiple controllers. 

This code is based off of the OpenFAST code provided to participants of the [ARPA-E ATLAS competition](https://arpa-e.energy.gov/?q=site-page/atlas-competition). 

See [ATLAS-modeling-control-simulation-final.pdf](docs/ATLAS-modeling-control-simulation-final.pdf) for full details.


# Usage

To begin the simulation, metrics calculation, and controller scoring process, open Matlab and point it to the folder containing this `readme` file. This folder contains the following Matlab script. In each of these scripts, only modify code in the `%% User Input Parameters` code section.

This package contains the main function and 2 example setups as discribed below:

`Main_Par.m` runs the entire suite of load cases run by `Main.m` in the origional ATLAS competition pacage, but in parallel simulations.

`Main_Par_EX1.m` is an example preset up to run 3 controllers under all 12 load cases in parallel using the MATLAB custom function block (FcnBlock) Simulink model 
	
`Main_Par_EX2.m` is an example preset up to run 1 controller under all 12 load cases in parallel using the MATLAB baseline pitch controller Simulink model. To run this example, input the command into the command window: `TunedGains = fminsearch(@(U)fMain_Par_Ex2(U),[0.006275604; 0.0008965149])`
	
# Overview of Parallelization Method
Parallelization is accomplished by establishing a worker pool using the MATLAB parallel processing toolbox. Each worker is set up in a temporary directory with a temporary version of the Simulink model with one of the controllers and one of the load cases as parameters for the Simulink model. Temporary models and directories must be used to prevent the temporary output of the `FAST_SFunc()` block from conflicting with other parallel simulations in the same directory.  Once the model is run, the output and cost function are computed for each load case and controller and sent to the workspace. the temporary files and Simulink are then closed and unloaded from the worker and Memory in order to prevent the parallel simulations from taking up large amounts of memory. See `Par_sim()` in the functions folder for more details. 


# Git Repository Structure

	* `_Controller/` contains the Simulink models for the NREL Baseline controller `NREL5MW_Baseline.mdl` and the example controllers used in the example scripts. Additionaly there is a black version of the Matlab functionblock controler which users can use to build their own custom functions. In addition, the m-file that contains the controller parameters is located here [(`fSetControllerParametersOn(Off)shore.m` for the baseline and `fSetControllerParametersFcnBlock.m`). The participants should add their own controller parameters in this file, rather than creating a new one. The contents of this folder may be modified. 

	* `_Functions/` contains all of the files used in the script that performs post-processing, calculates key turbine metrics, and finally calculates the controller performance metric (cost function). It also contains the sub-folder named `OpenFASTLibraries` that contain the DLLs and mex-function needed to run Simulink. These executable files correspond to OpenFAST compiled for Windows 64-bit operating systems. The contents of this folder should not be modified.

	* `ParforProgMon/` contains a simple progress monitoring tool for the parfor loop. See https://github.com/fsaxen/ParforProgMon

	* `docs/` contains usefull referance material 

Additional folders to be potentialy added at a later date:

	* `_Inputs/` contains all of the necessary OpenFAST and OpenFAST module input files needed for a particular challenge. These input files are separated out in terms of load case name and the particular module they represent (see Table 1 in [ATLAS-modeling-control-simulation-final.pdf](docs/ATLAS-modeling-control-simulation-final.pdf) ). The contents folder should, generally, not be modified.
	
	* `_Outputs/` collects the output files for the simulated load cases. This depends on the particular challenge selected for simulation as will be described below. The output files are named `x.SFunc.outb`, where the load case name is substituted for the symbol `x` in the file name. When OpenFAST is run parallelized, each output instance is saved in a corresponding folder. The outputs files can be visualized using the tool pyDatview or using the matlab function `_Functions\fReadFASTBinary.m`. The folder `_Outputs` is automatically updated with the participant output files.

	
## Large file not included in Git Repo

Large input and output files are not included in the repository to better manage space. Specifically the following files and folders are included in `.gitignore` and can be downloaded in the [ATLAS Offshore Challenge Submission Packet](https://s3-us-west-2.amazonaws.com/atlas-challenges/ATLAS-Offshore-Challenge.zip). Additional smaller input and output files are included in the repository. 

  	* `_Inputs/*` (~152MB) - Turbine Load Cases. Additional load cases may be created as described in [Section 5.1](ATLAS-modeling-control-simulation-final.pdf)
	
	* `_BaselineResults/*` (~112MB) - contains output files for the various load cases from simulations using the NREL Baseline Controller Simulink model. The contents of this folder are already populated with the baseline controller results, which have already been simulated for use by the participants in judging their own controller results. *The contents of this folder should not be modified.*
	
	* `_Outputs/*` (~112MB)- collects the output files for the simulated load cases. This depends on the particular challenge selected for simulation as will be described below. The output files are named `x.SFunc.outb`, where the load case name is substituted for the symbol `x` in the file name. The outputs files can be visualized using the tool pyDatview or using the matlab function `_Functions\fReadFASTBinary.m`. *The folder `_Outputs` is automatically updated with the participant output files.* Results from key outputs are uploaded to the Google Drive.

