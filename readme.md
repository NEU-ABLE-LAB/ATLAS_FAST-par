# OpenFast - Parallel

This code package enables multiple instances of OpenFAST to be run in parallel. This could be useful for example, to simulate a suite of input cases and/or to test multiple controllers. 

This code is based off of the OpenFAST code provided to participants of the [ARPA-E ATLAS competition](https://arpa-e.energy.gov/?q=site-page/atlas-competition). 

See [ATLAS-modeling-control-simulation-final.pdf](docs/ATLAS-modeling-control-simulation-final.pdf) for full details.

# Usage

To begin the simulation, metrics calculation, and controller scoring process, open Matlab and point it to the folder containing this `readme` file. This folder contains the following Matlab scripts. In each of these scripts, only modify code in the `%% USer Parameters` code section.

	* `Main.m` runs the entire process in the traditional single-threaded serial simulations. To begin the process, the user types in `Main` at the Matlab command line. This initiates simulation of the full set of load cases for a particular challenge as well as the performance and cost function calculations.
	
	* `MainParsimRun.m` runs the entire suite of load cases run by `Main.m`, but in parallel simulations. Specify  one of the following computation types in :
	

	
# Overview of Parallelization Method

# Git Repository Structure

	* `_Controller/` contains the Simulink models for the NREL Baseline controller `NREL5MW_Baseline.mdl` and the example controller in which the participants replace the NREL baseline pitch controller with their own controller `NREL5MW_Example_IPC.mdl`. In addition, the m-file that contains the controller parameters is located here (`fSetControllerParametersOn(Off)shore.m`). The participants should add their own controller parameters in this file, rather than creating a new one. The contents of this folder may be modified. 

	* `_Functions/` contains all of the files used in the script that performs post-processing, calculates key turbine metrics, and finally calculates the controller performance metric (cost function). It also contains the sub-folder named `OpenFASTLibraries` that contain the DLLs and mex-function needed to run Simulink. These executable files correspond to OpenFAST compiled for Windows 64-bit operating systems. The contents of this folder should not be modified.

	* `_Inputs/` contains all of the necessary OpenFAST and OpenFAST module input files needed for a particular challenge. These input files are separated out in terms of load case name and the particular module they represent (see Table 1 in [ATLAS-modeling-control-simulation-final.pdf](docs/ATLAS-modeling-control-simulation-final.pdf) ). The contents folder should, generally, not be modified.
	
	* `_Outputs/` collects the output files for the simulated load cases. This depends on the particular challenge selected for simulation as will be described below. The output files are named `x.SFunc.outb`, where the load case name is substituted for the symbol `x` in the file name. When OpenFAST is run parallelized, each output instance is saved in a corresponding folder. The outputs files can be visualized using the tool pyDatview or using the matlab function `_Functions\fReadFASTBinary.m`. The folder `_Outputs` is automatically updated with the participant output files.
	
## Large file not included in Git Repo

Large input and output files are not included in the repository to better manage space. Specifically the following files and folders are included in `.gitignore` and can be downloaded in the [ATLAS Offshore Challenge Submission Packet](https://s3-us-west-2.amazonaws.com/atlas-challenges/ATLAS-Offshore-Challenge.zip). Additional smaller input and output files are included in the repository. 

  * `_Inputs/LoadCases/Turb/*` (~152MB) - Turbine Load Cases. Additional load cases may be created as described in [Section 5.1](ATLAS-modeling-control-simulation-final.pdf)
	
	* `_BaselineResults/*` (~112MB) - contains output files for the various load cases from simulations using the NREL Baseline Controller Simulink model. The contents of this folder are already populated with the baseline controller results, which have already been simulated for use by the participants in judging their own controller results. *The contents of this folder should not be modified.*
	
	* `_Outputs/*` (~112MB)- collects the output files for the simulated load cases. This depends on the particular challenge selected for simulation as will be described below. The output files are named `x.SFunc.outb`, where the load case name is substituted for the symbol `x` in the file name. The outputs files can be visualized using the tool pyDatview or using the matlab function `_Functions\fReadFASTBinary.m`. *The folder `_Outputs` is automatically updated with the participant output files.* Results from key outputs are uploaded to the Google Drive.
