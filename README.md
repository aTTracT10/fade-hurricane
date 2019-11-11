# FADE-HURRICANE
Scripts to predict SRTs for the Hurricance 2.0 challenge natural language data with the Simulation Framework for Auditory Discrimination Experiments ([FADE](http://www.github.com/m-r-s/fade)).

Copyright (C) 2019 Marc René Schädler

E-mail: marc.r.schaedler@uni-oldenburg.de

## Warning
This is a code drop which is largely undocumented.
It comes WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
If you don't understand what the scripts are doing it is very likely that you don't need them.
I am using this code on Ubuntu 19.10 and 19.04.

## Preparation
* You will need a working installation of the Simulation Framework for Auditory Discrimination Experiments ([FADE](http://www.github.com/m-r-s/fade)).
* Place the unzipped natural language data in the "original-data" folder.
* Run `./prepare_data.sh` which converts the data into FADE-suitable formats.

## Usage
* Run a simulation: `./run_simulation.sh <SIMGRID> <SPEECH> <SPEECH_HRIR> <NOISE> <NOISE_HRIR> <PRE_PROCESSING>`
* Example: `./run_simulation.sh "-6:3:24" "GERMAN-mid" "mid" "GERMAN-mid" "" "copy"
* Look at the result in the "results" folder, you can modify the SIMGRID to the required range which MUST at least include the SRT and the best TRAINING SNR, but its better to have some margin.
* Replace the example signal processing with your solution and rerun the simulation.