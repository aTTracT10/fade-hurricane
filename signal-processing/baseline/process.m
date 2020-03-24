function out = process(in, fs, pass_range, spectral_tuning, layer_factors)

  % Convert potential string arguments to numbers
  if ischar(pass_range)
    pass_range = str2num(pass_range);
  end
  if ischar(spectral_tuning)
    spectral_tuning = str2num(spectral_tuning);
  end
  if ischar(layer_factors)
    layer_factors = str2num(layer_factors);
  end
  
  % Parameters (keep it simple!)
  win_shift = 10; % ms
  win_length = 25; % ms
  freq_range = [64 16384]; % Hz
  band_factor = 2; % Over-sampling of bands
  
  %% Signal analysis
  % with ordinary log Mel-spectrogram
  [log_mel_spec, freq_centers, frames, M, N] = log_mel_spectrogram(in, fs, win_shift, win_length, freq_range, [], band_factor);
  [num_channels, num_frames] = size(log_mel_spec);

  %% Manipulations
  
  % Manipulation 1: Initial spectral gains
  gains_db = polyval([-spectral_tuning(2) -spectral_tuning(1) 0],log2(freq_centers.'./2000)) * ones(1,size(log_mel_spec,2));
  
  % Manipulation 2: Band pass
  band_pass = freq_centers >= pass_range(1) & freq_centers <= pass_range(2);
  gains_db(~band_pass,:) = -inf;
  
  % Manipulation 3: Dynamic range compression/expansion
  
  % 6 layers available for expansion/compression
  kernel{1} = hann_win(2*2*2)./4; % 2 ERB
  kernel{2} = hann_win(4*2*2)./8; % 4 ERB
  kernel{3} = hann_win(4*2*2)./8 * hann_win(3*2).'/3; % 4 ERB * 30ms
  kernel{4} = hann_win(8*2*2)./16 * hann_win(3*2).'/3; % 8 ERB * 30ms
  kernel{5} = hann_win(16*2*2)./32 * hann_win(3*2).'/3; % 16 ERB * 30ms
  kernel{6} = hann_win(32*2*2)./64 * hann_win(3*2).'/3; % 32 ERB * 30ms
  log_mel_spec_ext = [ones(64,1) * log_mel_spec(1,:); log_mel_spec; ones(64,1) * log_mel_spec(end,:)];
  log_mel_spec_ext = [log_mel_spec_ext(:,1) * ones(1,10), log_mel_spec_ext, log_mel_spec_ext(:,end) * ones(1,10)];
  
  % Calculate layers (low-pass)
  log_mel_spec_ext_smooth = cell(length(kernel)+1,1);
  log_mel_spec_ext_smooth{1} = log_mel_spec_ext;
  for i=1:length(kernel)
    log_mel_spec_ext_smooth{i+1} = conv2(log_mel_spec_ext,kernel{i},'same');
  end
  
  % Calculate difference layers (band-pass)
  log_mel_spec_ext_diff = cell(length(kernel),1);
  for i=1:length(kernel)
    log_mel_spec_ext_diff{i} = log_mel_spec_ext_smooth{i} - log_mel_spec_ext_smooth{i+1};
  end
  
  % Manipulate and add difference layers
  log_mel_spec_ext_target = log_mel_spec_ext_smooth{end};
  layer_factors = [1, layer_factors(1:4), 1]; % Only expose 2:5
  for i=1:length(kernel)
    log_mel_spec_ext_target += layer_factors(i) .* log_mel_spec_ext_diff{i};
  end
  
  % Desired spectro-temporal signal manipulation
  spectro_temporal_modification = log_mel_spec_ext_target(65:end-64,11:end-10) - log_mel_spec;
  
  % Add desired dynamic spectro-temporal manipulations
  gains_db += spectro_temporal_modification;
  
  %% Perform manipulation
  % Interpolate spectral effect for FFT bins
  amplitude_gains = interp1(freq_centers.', 10.^(gains_db./20), linspace(0,fs-1/N,N).', 'extrap');
  amplitude_gains([1 end/2+1],:) .*= 0.5;
  amplitude_gains(end/2+2:end,:) = 0;
  
  % Zero padding and windowing for overlap-add
  window_function = hanning(2.*M,'periodic');
  
  % Apply time- and frequency dependent gains
  frames_filtered = real(ifft(fft(frames) .* (2.*amplitude_gains)));

  % Window for overlap-add after manipulation
  frames_filtered .*= [zeros(N-2.*M,1); window_function];

  out = zeros(size(in));
  % Resynthesis with overlap-add
  for i=1:num_frames
    out(1+(i-1).*M:N+(i-1).*M) += frames_filtered(:,i);
  end
end
