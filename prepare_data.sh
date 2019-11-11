#!/bin/bash
#
# Copyright (C) 2019 Marc René Schädler

DIR=$(cd "$( dirname "$0" )" && pwd)

LANGUAGES=("SPANISH" "ENGUS" "GERMAN") # ENGUS, GERMAN, SPANISH
DISTANCES=("far" "mid" "near") # far,mid,near
SNR="mid" # hi,low,mid

for LANGUAGE in ${LANGUAGES[@]}; do
  for DISTANCE in ${DISTANCES[@]}; do
    RIR_SOURCE="${DIR}/original-data/HC2_natural_data/room_impulse_responses/${RIR_SOURCE_DIR}/RIR_${DISTANCE}.wav"
    SAN_SOURCE_DIR="${DIR}/original-data/HC2_natural_data/speech_and_noise/${DISTANCE}/clean_${LANGUAGE}/${SNR}/"

    RIR_TARGET_DIR="${DIR}/prepared-data/speech-hrir/${DISTANCE}"
    SPEECH_TARGET_DIR="${DIR}/prepared-data/speech/${LANGUAGE}-${DISTANCE}"
    NOISE_TARGET="${DIR}/prepared-data/noise/${LANGUAGE}-${DISTANCE}.wav"

    mkdir -p "${RIR_TARGET_DIR}"
    mkdir -p "${SPEECH_TARGET_DIR}"
    mkdir -p "${DIR}/prepared-data/noise"

    FILELIST=$(mktemp) || exit 1

    find "${SAN_SOURCE_DIR}" -iname "*.wav" | sort > "${FILELIST}"

    octave --eval "
      targetfs = 48000;
      filelist = textread('${FILELIST}','%s');
      noise = [];
      for i=1:length(filelist)
        [in, fs] = audioread(filelist{i});
        if (targetfs ~= fs)
          in = resample(in,targetfs,fs);
        end
        speech = in(:,1);
        [~, name, extension] = fileparts(filelist{i});
        audiowrite(['${SPEECH_TARGET_DIR}/',name,extension],speech,targetfs,'BitsPerSample',32);
        noise = [noise;in(:,2:3)];
      end
      audiowrite('${NOISE_TARGET}',noise(1:60*targetfs,:),targetfs,'BitsPerSample',32);
      "
    octave --eval "
      targetfs = 48000;
      [in, fs] = audioread('${RIR_SOURCE}');
      if (targetfs ~= fs)
        in = resample(in,targetfs,fs);
      end
      [~, name, extension] = fileparts('${RIR_SOURCE}');
      audiowrite(['${RIR_TARGET_DIR}/',name,extension],in.*10.^(-65./20),targetfs,'BitsPerSample',32);
      "
  done
done
