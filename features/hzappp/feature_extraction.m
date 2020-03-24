function [features, signal, log_melspec] = feature_extraction(signal, fs, individualization, id)
%
% Feature extraction for simulating HZ study experiments
%

if nargin < 3 || isempty(individualization)
  individualization = '';
end

if nargin < 4 || isempty(id)
  id = 'P-0-0';
end

% config cache
persistent config;

% Config id string
configid = sprintf('fs%.0fIND%sID%s', fs, individualization, id);

% Hearing status can be cached
if isempty(config) || ~isfield(config, configid)
  % Load hearing thresholds (ht) and level uncertainty (ul)
  [f, ht, ul] = load_hearingstatus(id, individualization);
  config.(configid).ht = ht;
  config.(configid).ul = ul;
  config.(configid).f = f;
else
  ht = config.(configid).ht;
  ul = config.(configid).ul;
  f = config.(configid).f;
end

% Skip the first 100ms of the output
% Randomize the start sample by another 10ms
signal = signal(1+round(fs.*(0.100+rand(1).*0.010)):end,:);
signal_left = signal(:,1);
#signal_right = signal(:,2);

% Calculate log Mel-spectrogram
[log_melspec_left, melspec_freqs] = log_mel_spectrogram(signal_left, fs, [], [], [64 16384]);
#[log_melspec_right, melspec_freqs] = log_mel_spectrogram(signal_right, fs, [], [], [64 16384]);

% Apply absolute hearing threshold
ht_mel = interp1(f(:), ht(:), melspec_freqs(:), 'linear', 'extrap');
log_melspec_left = max(bsxfun(@minus, log_melspec_left, ht_mel), randn(size(log_melspec_left)));
#log_melspec_right = max(bsxfun(@minus, log_melspec_right, ht_mel), randn(size(log_melspec_right)));

% Apply frequency-dependent level-uncertainty
ul_mel = interp1(f(:), ul(:), melspec_freqs(:), 'linear', 'extrap');
ul_mel(isnan(ul_mel)) = 0.1;
log_melspec_left = bsxfun(@times,log_melspec_left,1./ul_mel) + randn(size(log_melspec_left));
#log_melspec_right = bsxfun(@times,log_melspec_right,1./ul_mel) + randn(size(log_melspec_right));

% SGBFB feature extraction and mean-and-variance normalization
#features = mvn([sgbfb(log_melspec_left);sgbfb(log_melspec_right)]);
features = mvn(sgbfb(log_melspec_left));
end

