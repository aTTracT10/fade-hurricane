#!/usr/bin/octave
close all
clear
clc

graphics_toolkit qt;

fs = 48000;

% Parameters
pass_range = [500, 8000]; % Hz
spectral_tuning = [0 0]; % ploynomial coefficients roughly in interval [-10 10]
layer_factors = [3 2 1 0]; % factors in interval [0 5]

figure;
[in, fs] = audioread('aeiou.wav');
in = in(:,1);
in = in./std(in).*10.^(-65/20);
out = process(in,fs,pass_range,spectral_tuning,layer_factors);
out = out./std(out).*10.^(-65/20);
in_logms = log_mel_spectrogram(in,fs);
out_logms = log_mel_spectrogram(out,fs);
subplot(3,1,1);
imagesc(in_logms,[0 80]);colorbar;
subplot(3,1,2);
imagesc(out_logms,[0 80]);colorbar;
subplot(3,1,3);
imagesc(out_logms-in_logms,[-15 15]);colorbar;
