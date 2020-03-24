#!/usr/bin/octave_config_info
close all
clear
clc

graphics_toolkit qt;

addpath('../signal-processing/baseline');

fs = 48000;
pass_range = [500, 8000];
spectral_tuning = [-9 1]; % GERMAN
%spectral_tuning = [-6 0]; % SPANISH
%spectral_tuning = [-3 0]; % ENGLISH
layer_factors = [3 2 1 0];

speech = audioread('../prepared-data/speech/LGEDmid/00456.wav'); % GERMAN
%speech = audioread('../prepared-data/speech/LSPDmid/03213.wav'); % SPANISH
%speech = audioread('../prepared-data/speech/LENDmid/00407.wav'); % ENGLISH

noise = audioread('../prepared-data/noise/noise-LGEDmid.wav'); % GERMAN
%noise = audioread('../prepared-data/noise/noise-LSPDmid.wav'); % SPANISH
%noise = audioread('../prepared-data/noise/noise-LENDmid.wav'); % ENGLISH

hrir = audioread('../prepared-data/speech-hrir/irDmid/RIR_mid.wav');

SNR = 0;

hrir = hrir .* 10.^((65+SNR)./20);

speech_mod = process(speech,fs,pass_range,spectral_tuning,layer_factors);
20*log10(rms(speech_mod))
speech_mod = speech_mod ./ rms(speech_mod) .* rms(speech);

speech_rev = real(fftconv2(speech,hrir,'full'));
speech_mod_rev = real(fftconv2(speech_mod,hrir,'full'));

mix = speech_rev + noise(1:size(speech_rev,1));
mix_mod = speech_mod_rev + noise(1:size(speech_mod_rev));

scalerange = [0 65];

h = 15;
w = 5;
figure('Position',[0 0 h*100 w*100]);
subplot = @(m,n,p) axes('Position',subposition(m,n,p))
colormap('cubehelix');
subplot(2,3,1);
imagesc(log_mel_spectrogram(speech_rev,fs,[],[],[64 24000]),scalerange);
colorbar;

subplot(2,3,2);
imagesc(log_mel_spectrogram(mix,fs,[],[],[64 24000]),scalerange);
colorbar;

subplot(2,3,4);
imagesc(log_mel_spectrogram(speech_mod_rev,fs,[],[],[64 24000]),scalerange);
colorbar;

subplot(2,3,5);
imagesc(log_mel_spectrogram(mix_mod,fs,[],[],[64 24000]),scalerange);
colorbar;

subplot(2,3,3);
plot(prctile(log_mel_spectrogram(noise,fs,[],[],[64 24000]),[5 50 95 100],2),'b');
hold on;
plot(prctile(log_mel_spectrogram(speech_rev,fs,[],[],[64 24000]),[5 50 95 100],2),'r');
ylim(scalerange);

subplot(2,3,6);
plot(prctile(log_mel_spectrogram(noise,fs,[],[],[64 24000]),[5 50 95 100],2),'b');
hold on;
plot(prctile(log_mel_spectrogram(speech_mod_rev,fs,[],[],[64 24000]),[5 50 95 100],2),'r');
ylim(scalerange);
set(gcf,'PaperUnits','inches','PaperPosition',1.4.*[0 0 h w]);
print('-depsc2','-r600','demo.eps');

audiowrite('unprocessed.wav',mix,fs);
audiowrite('processed.wav',mix_mod,fs);
audiowrite('processed_clean.wav',speech_mod,fs);
