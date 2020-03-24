#!/bin/bash

DIR=$(cd "$( dirname "$0" )" && pwd)

TARGETFS=48000

DATADIR="${DIR}/prepared-data"

SIMRANGE="$1"
SPEECH="$2"
SPEECH_HRIR="$3"
NOISE="$4"
NOISE_HRIR="$5"
PRE_PROCESSING="$6"
PRE_PROCESSING_OPTIONS="$7"
SIL="[0,0]"
TRAINING=""
FEATURES="${DIR}/features/hzappp"
FEATURES_OPTIONS=('AD' 'normal')
FIGURES_OPTIONS=('word' '0.90')

mkdir -p "${DIR}/results"

WORKDIR=$(mktemp -d)
PROJECT="${WORKDIR}/simulation"

RESULTSFILE="${DIR}/results/${SPEECH}-${SPEECH_HRIR}-${NOISE}-${NOISE_HRIR}-${PRE_PROCESSING}-${PRE_PROCESSING_OPTIONS}.txt"
[ -e "$RESULTSFILE" ] && continue

echo "create project"
fade "${PROJECT}" corpus-matrix 400 100 "${SIMRANGE}" "${SIL}" || exit 1
fade "${PROJECT}" parallel

echo "set up project"
cp -L -r "${DATADIR}/speech/${SPEECH}/"* "${PROJECT}/source/speech/" || exit 1
cp -L -r "${DATADIR}/noise/${NOISE}.wav" "${PROJECT}/source/noise/" || exit 1
if [ -n "${SPEECH_HRIR}" ]; then
  cp -L "${DATADIR}/speech-hrir/${SPEECH_HRIR}/"* "${PROJECT}/source/hrir-speech/" || exit 1
fi
if [ -n "${NOISE_HRIR}" ]; then
  cp -L "${DATADIR}/noise-hrir/${NOISE_HRIR}/"* "${PROJECT}/source/hrir-noise/" || exit 1
fi
if [ -n "${TRAINING}" ]; then
  cp -L "${TRAINING}/"* "${PROJECT}/config/training/environment/" || exit 1
fi

echo "pre-process data"
find "${PROJECT}/source/speech/" -iname "*.wav" > "${PROJECT}/filelist-process.txt"
octave-cli --eval "
  cd('${DIR}/signal-processing/${PRE_PROCESSING}');
  filelist = textread('${PROJECT}/filelist-process.txt','%s');
  for i=1:length(filelist)
    [in, fs] = audioread(filelist{i});
    in_rms = rms(in);
    out = process(in, fs, ${PRE_PROCESSING_OPTIONS});
    out = out .* (in_rms./rms(out));
    audiowrite(filelist{i},out,fs,'BitsPerSample',32);
    printf('%i',floor((i-1)./length(filelist).*10));
  end
  " || exit 1
echo ""

# Make sure everything has the same samplerate (if not resample)
fade "${PROJECT}" resample "${TARGETFS}" || exit 1

echo "run simulation"
fade "${PROJECT}" corpus-generate || exit 1
fade "${PROJECT}" corpus-format || exit 1
fade "${PROJECT}" features "${FEATURES}" "${FEATURES_OPTIONS[@]}" || exit 1
rm -r "${PROJECT}/corpus"
fade "${PROJECT}" training "8" "6" "1" "12" "mvwt" "0" "1"  || exit 1
fade "${PROJECT}" recognition || exit 1
rm -r "${PROJECT}/features"
fade "${PROJECT}" evaluation || exit 1
fade "${PROJECT}" figures "${FIGURES_OPTIONS[@]}" || exit 1

sed -n '2{p;q}' "${PROJECT}/figures/table.txt" | tr -s ' ' | cut -d' ' -f2 > "${RESULTSFILE}" || exit 1
cp "${PROJECT}/figures/table.txt" "${RESULTSFILE/%.txt/.tab}"
cp "${PROJECT}/figures/"*".eps" "${RESULTSFILE/%.txt/.eps}"

[ -e "${WORKDIR}" ] && rm -rf "${WORKDIR}"
