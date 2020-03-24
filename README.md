# FADE-HURRICANE
Scripts to optimize signal processing algorithms parameters with respect to the predicted SRT for the Hurricance 2.0 challenge natural language data with the Simulation Framework for Auditory Discrimination Experiments ([FADE](http://www.github.com/m-r-s/fade)).

Copyright (C) 2019-2020 Marc René Schädler

E-mail: marc.r.schaedler@uni-oldenburg.de

## Warning
This is a code drop which is largely undocumented.
It comes WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
If you don't understand what the scripts are doing it is very likely that you don't need them.
I used this code on Ubuntu 19.10.

## Preparation
* You will need a working installation of the Simulation Framework for Auditory Discrimination Experiments ([FADE](http://www.github.com/m-r-s/fade)).
* Place the unzipped natural language data in the "original-data" folder.
* Run `./prepare_data.sh` which converts the data into FADE-suitable formats.

## Run a simulation
* Run `./run_simulation.sh <SIMGRID> <SPEECH> <SPEECH_HRIR> <NOISE> <NOISE_HRIR> <PRE_PROCESSING> <PRE_PROCESSING_OPTIONS>`
* Example: `./run_simulation.sh "-6:3:24" "GERMAN-mid" "mid" "GERMAN-mid" "" "copy"
* Look at the result in the "results" folder, you can modify the SIMGRID to the required range which MUST at least include the SRT and the best TRAINING SNR, but its better to have some margin.
* Replace the example signal processing with your solution and rerun the simulation.

## Run the optimization
* Run `./run_experiment.sh`
* Please have a look at `run_optimization.sh` for the optimization parameters and `run_simulation.sh` for the simulation parameters.

## Run the intelligibility-improving signal processing approach (IISPA) with the optimized parameters
* Run `./process_data.sh` to generate the corpus submitted to the Hurricane Challenge 2.0
* Parameter values are hardcoded in the script
