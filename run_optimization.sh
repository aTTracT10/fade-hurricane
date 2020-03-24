#!/bin/bash

DIR=$(cd "$( dirname "$0" )" && pwd)

# Fixed parameters for optimization
SPEECH="LGEDmid"
SPEECH_HRIR="irDmid"
NOISE="noise-LGEDmid"
NOISE_HRIR=""
PRE_PROCESSING="baseline"
SIMRANGE="-9:3:18"

# Define test grid
PASS_RANGE_LOW=(500)
PASS_RANGE_HIGH=(8000)
SPECTRAL_SLOPE=(-10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0)
SPECTRAL_CURVE=(-4 -3 -2 -1 0 1 2 3 4)
SPECTRAL_MODULATION_HIGH=(1 2 3 4 5)
TEMPORAL_MODULATION=(1 2 3 4 5)
SPECTRAL_MODULATION_MID=(0 1 2 3 4 5)
SPECTRAL_MODULATION_LOW=(0 1 2 3 4 5)

PARAMETERS=(PASS_RANGE_LOW PASS_RANGE_HIGH SPECTRAL_SLOPE SPECTRAL_CURVE SPECTRAL_MODULATION_HIGH TEMPORAL_MODULATION SPECTRAL_MODULATION_MID SPECTRAL_MODULATION_LOW)
ACTIVE_PARAMETERS=("$@")

if [ -e "best_configuration.txt" ]; then
  BEST_CONFIGURATION=($(cat "best_configuration.txt"))
else
  BEST_CONFIGURATION=(500 8000 0 0 1 1 1 1)
fi
if [ -e "best_srt.txt" ]; then
  BEST_SRT=$(cat "best_srt.txt")
else
  BEST_SRT=""
fi

ITERATE=true
COUNT=0
while ${ITERATE} && [ $COUNT -le 100 ]; do
  # Set new base configuration
  BASE_CONFIGURATION=("${BEST_CONFIGURATION[@]}")
  for ((I=0;$I<${#PARAMETERS[@]};I++)); do
    PARAMETER=${PARAMETERS[$I]}
    # Check if this parameter should be considered
    SKIP=true
    for ((J=0;$J<${#ACTIVE_PARAMETERS[@]};J++)); do
      if [ "${PARAMETER}" == "${ACTIVE_PARAMETERS[$J]}" ]; then
        SKIP=false
      fi
    done
    if $SKIP; then
      echo "PARAMETER ${PARAMETER} IS INACTIVE - SKIP!"
      continue
    fi
    OPTIONS=($(eval "echo \${${PARAMETER}[@]}"))
    CONFIGURATION=("${BEST_CONFIGURATION[@]}")
    SRT=""
    # Test performance with all options
    for ((J=0;$J<${#OPTIONS[@]};J++)); do
      OPTION=${OPTIONS[$J]}
      CONFIGURATION[$I]="${OPTION}"

      # Set test configuration
      PASS_RANGE="[${CONFIGURATION[0]},${CONFIGURATION[1]}]"
      SPECTRAL_TUNING="[${CONFIGURATION[2]},${CONFIGURATION[3]}]"
      LAYER_FACTORS="[${CONFIGURATION[4]},${CONFIGURATION[5]},${CONFIGURATION[6]},${CONFIGURATION[7]}]"
      PRE_PROCESSING_OPTIONS="${PASS_RANGE},${SPECTRAL_TUNING},${LAYER_FACTORS}"
      RESULTSFILE="${DIR}/results/${SPEECH}-${SPEECH_HRIR}-${NOISE}-${NOISE_HRIR}-${PRE_PROCESSING}-${PRE_PROCESSING_OPTIONS}.txt"

      # Inform about where we are
      echo "ROUND ${COUNT} PARAMETER ${PARAMETER} OPTION ${OPTION}"
      echo "PASS_RANGE=${PASS_RANGE}"
      echo "SPECTRAL_TUNING=${SPECTRAL_TUNING}"
      echo "LAYER_FACTORS=${LAYER_FACTORS}"

      # Run simulation if data point is missing
      if [ ! -e "${RESULTSFILE}" ]; then
	echo -n "Run simulation... "
	TIC=$(date +%s)
        ${DIR}/run_simulation.sh "${SIMRANGE}" "${SPEECH}" "${SPEECH_HRIR}" "${NOISE}" "${NOISE_HRIR}" "${PRE_PROCESSING}" "${PRE_PROCESSING_OPTIONS}" &>> simulation.log  || exit 1
	TOC=$(date +%s)
	echo "completed in $[${TOC}-${TIC}] seconds"
      fi

      # Check result
      SRT=$(cat "$RESULTSFILE")
      echo "SRT=${SRT}"

      # Store result for next round
      if [ -n "${SRT}" ]; then
        if [ -z "${BEST_SRT}" ] || (( $(bc <<< "${SRT}<${BEST_SRT}") )); then
          BEST_SRT="${SRT}"
          BEST_CONFIGURATION[$I]="$OPTION"
        fi
      fi
      echo "======================================================="
      echo "CURRENT STATE OF CONFIGURATION=${CONFIGURATION[@]} (SRT=${SRT})"
      echo "CURRENT STATE OF BEST_CONFIGURATION=${BEST_CONFIGURATION[@]} (BEST_SRT=${BEST_SRT})"
    done
  done

  # Save current state
  echo "${BEST_CONFIGURATION[@]}" > "best_configuration.txt"
  echo "${BEST_SRT}" > "best_srt.txt"


  # Only iterate once more if parameters changed
  echo "COMPARE BEST AND NEW CONFIGURATION"
  echo "BASE_CONFIGURATION=${BASE_CONFIGURATION[@]}"
  echo "BEST_CONFIGURATION=${BEST_CONFIGURATION[@]}"
  ITERATE=false
  for ((I=0;$I<${#BASE_CONFIGURATION[@]};I++)); do
    if [ ! "${BASE_CONFIGURATION[$I]}" == "${BEST_CONFIGURATION[$I]}" ]; then
      ITERATE=true;
    fi
  done
  COUNT=$((${COUNT}+1))
done
