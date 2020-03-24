#!/bin/bash

DIR=$(cd "$( dirname "$0" )" && pwd)

LANGUAGES=("SPANISH" "ENGUS" "GERMAN") # ENGUS, GERMAN, SPANISH
DISTANCES=("far" "mid" "near") # far,mid,near
SNR="mid" # hi,low,mid

for LANGUAGE in ${LANGUAGES[@]}; do
  for DISTANCE in ${DISTANCES[@]}; do
    RIR_SOURCE="${DIR}/original-data/HC2_natural_data/room_impulse_responses/${RIR_SOURCE_DIR}/RIR_${DISTANCE}.wav"
    SAN_SOURCE_DIR="${DIR}/original-data/HC2_natural_data/speech_and_noise/${DISTANCE}/clean_${LANGUAGE}/${SNR}/"

    RIR_TARGET_DIR="${DIR}/prepared-data/speech-hrir/irD${DISTANCE}"
    SPEECH_TARGET_DIR="${DIR}/prepared-data/speech/L${LANGUAGE:0:2}D${DISTANCE}"
    NOISE_TARGET="${DIR}/prepared-data/noise/noise-L${LANGUAGE:0:2}D${DISTANCE}.wav"

    mkdir -p "${RIR_TARGET_DIR}" || exit 1
    mkdir -p "${SPEECH_TARGET_DIR}" || exit 1
    mkdir -p "${DIR}/prepared-data/noise" || exit 1

    FILELIST=$(mktemp) || exit 1

    find "${SAN_SOURCE_DIR}" -iname "*.wav" | sort > "${FILELIST}" || exit 1

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
      audiowrite('${NOISE_TARGET}',noise(1:60*targetfs,1),targetfs,'BitsPerSample',32);
      " || exit 1
    octave --eval "
      targetfs = 48000;
      [in, fs] = audioread('${RIR_SOURCE}');
      if (targetfs ~= fs)
        in = resample(in,targetfs,fs);
      end
      [~, name, extension] = fileparts('${RIR_SOURCE}');
      audiowrite(['${RIR_TARGET_DIR}/',name,extension],in(:,1).*10.^(-65./20),targetfs,'BitsPerSample',32);
      " || exit 1
    rm "${FILELIST}"
  done
done
