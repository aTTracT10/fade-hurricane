#!/bin/bash

DIR=$(cd "$( dirname "$0" )" && pwd)

# Modules:
# PASS_RANGE_LOW
# PASS_RANGE_HIGH
# SPECTRAL_SLOPE
# SPECTRAL_CURVE
# SPECTRAL_MODULATION_HIGH
# TEMPORAL_MODULATION
# SPECTRAL_MODULATION_MID
# SPECTRAL_MODULATION_LOW

COMMAND="${DIR}/run_optimization.sh"

# Strategy
for I in 1 2 3; do
  # Optimize bandwidth and spectral shape
  for J in 1 2 3; do
    "${COMMAND}" PASS_RANGE_LOW PASS_RANGE_HIGH
    "${COMMAND}" SPECTRAL_SLOPE SPECTRAL_CURVE
  done
  "${COMMAND}" PASS_RANGE_LOW PASS_RANGE_HIGH SPECTRAL_SLOPE SPECTRAL_CURVE

  # Optimize high spectral modulations and temporal modulations
  #    and mid and low spectral modulations
  for J in 1 2 3; do
    "${COMMAND}" SPECTRAL_MODULATION_HIGH TEMPORAL_MODULATION
    "${COMMAND}" SPECTRAL_MODULATION_MID SPECTRAL_MODULATION_LOW
  done
  "${COMMAND}" SPECTRAL_MODULATION_HIGH TEMPORAL_MODULATION SPECTRAL_MODULATION_MID SPECTRAL_MODULATION_LOW
done

# Optimize all parameter togehter
"${COMMAND}" PASS_RANGE_LOW PASS_RANGE_HIGH SPECTRAL_SLOPE SPECTRAL_CURVE SPECTRAL_MODULATION_HIGH TEMPORAL_MODULATION SPECTRAL_MODULATION_MID SPECTRAL_MODULATION_LOW

ls -tr "${DIR}/results/"*.txt | while read line; do echo -n $line | sed -e 's/^.*baseline-//g' -e 's/.txt/ /g' -e 's/,\[/ \[/g'; cat $line; echo ""; done | sed -r '/^\s*$/d' > "${DIR}/results.txt"
cat "${DIR}/results.txt" | sort -k 4,4nr | tail | column -t
