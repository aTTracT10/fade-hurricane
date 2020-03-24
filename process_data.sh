#!/bin/bash

DIR=$(cd "$( dirname "$0" )" && pwd)

LANGUAGES=("SPANISH" "ENGUS" "GERMAN") # ENGUS, GERMAN, SPANISH
DISTANCES=("far" "mid" "near") # far,mid,near
SNRS=("low" "mid" "hi") # hi,low,mid

for LANGUAGE in ${LANGUAGES[@]}; do
  # Set language/talker-specific parameters
  case ${LANGUAGE} in
    SPANISH)
      PASS_RANGE="[500,8000]"
      SPECTRAL_TUNING="[-6,0]"
      LAYER_FACTORS="[3,2,1,0]"
    ;;
    ENGUS)
      PASS_RANGE="[500,8000]"
      SPECTRAL_TUNING="[-3,0]"
      LAYER_FACTORS="[3,2,1,0]"
    ;;
    GERMAN)
      PASS_RANGE="[500,8000]"
      SPECTRAL_TUNING="[-9,1]"
      LAYER_FACTORS="[3,2,1,0]"
    ;;
  esac

  for DISTANCE in ${DISTANCES[@]}; do
    for SNR in ${SNRS[@]}; do
      echo "Language: ${LANGUAGE}  Distance: ${DISTANCE}  SNR: ${SNR}"
      SOURCE_DIR="${DIR}/original-data/HC2_natural_data/speech_and_noise/${DISTANCE}/clean_${LANGUAGE}/${SNR}/"
      TARGET_DIR="${DIR}/processed-data/speech_and_noise/${DISTANCE}/clean_${LANGUAGE}/${SNR}/"

      mkdir -p "${TARGET_DIR}" || exit 1

      FILELIST=$(mktemp) || exit 1

      find "${SOURCE_DIR}" -iname "*.wav" | sort > "${FILELIST}" || exit 1

      octave --eval "
        addpath('${DIR}/signal-processing/baseline');
        filelist = textread('${FILELIST}','%s');
        for i=1:length(filelist)
          [in, fs] = audioread(filelist{i});
          out = process(in(:,1), fs, ${PASS_RANGE}, ${SPECTRAL_TUNING}, ${LAYER_FACTORS});
          out ./= max(abs(out)).*0.99;
          [~, name, extension] = fileparts(filelist{i});
          audiowrite(['${TARGET_DIR}',name,extension],out,fs);
          printf('.');
        end
        printf('\n');
        " || exit 1
      rm "${FILELIST}"
    done
  done
done

