function [f, ht, ul] = load_hearingstatus(id, individualization);

% Detect requested profiles P-<HL profile>-<UL profile>
if strncmp(id,'P',1)
  % Split string
  profile = strsplit(id,'-');
  hl_profile = profile{2};
  ul_profile = profile{3};
  % Frequencies
  f =  [125  250  375  500  750  1000  1500  2000  3000  4000  6000  8000]; % Hz

  % Bisgaard profile hearing loss
  hl_profiles = [...
    10    10    10    10    10    10    10    15    20    30    40    40; ... % N1
    20    20    20    20    22.5  25    30    35    40    45    50    50; ... % N2
    35    35    35    35    35    40    45    50    55    60    65    65; ... % N3
    55    55    55    55    55    55    60    65    70    75    80    80; ... % N4
    65    65    67.5  70    72.5  75    80    80    80    80    80    80; ... % N5
    75    75    77.5  80    82.5  85    90    90    95   100   100   100; ... % N6
    90    90    92.5  95   100   105   105   105   105   105   105   105; ... % N7
    10    10    10    10    10    10    10    15    30    55    70    70; ... % S1
    20    20    20    20    22.5  25    35    55    75    95    95    95; ... % S2
    30    30    30    35    47.5  60    70    75    80    80    85    85; ... % S3
  ];
  hl_profile = str2num(hl_profile);
  ul_profile = str2num(ul_profile);
  if hl_profile == 0
    hl = zeros(size(f));
  else
    hl = hl_profiles(hl_profile,:);
  end
  if ul_profile > 0
    ul = ul_profile .* ones(size(f));
  else
    ul = nan(size(f));
  end
  ht = ff2ed(f,hl2spl(f,hl)); % Level at eardrum
else
  f = [125 250 500 750 1000 1500 2000 3000 4000 6000 8000]; % Hz
  f_ht_siam = [250 500 1000 2000 4000 8000]; % Hz
  f_ul_siam = [500 1000 2000 4000]; % Hz
  switch id
    case 'normal'
    ht_siam = ff2ed(f_ht_siam,hl2spl(f_ht_siam,zeros(size(f_ht_siam)))); % Level at eardrum
    tin_siam = [-3.50 -2.00 2.00 4.50]; % Relative level to noise
    ht_ag = ff2ed(f,hl2spl(f,zeros(size(f)))); % Level at eardrum

    otherwise
    error('listener not found');
  end

  % No hearing loss (default)
  ht = zeros(size(f));
  ul = ones(size(f));
  
  switch tolower(individualization)
    case 'ag' % Use hearing thresholds at eardrum derived from audiogram
      ht = ht_ag;

    case 'agl' % Same as 'ag' but with frequency resolution comparable to siam
      ht = interp1(f, ht_ag, f_ht_siam);
      ht = interp1(f_ht_siam, ht, f, 'linear', 'extrap');

    case 'a' % Use hearing thresholds from tone in quiet detection
      ht = interp1(f_ht_siam, ht_siam, f, 'linear', 'extrap');
      ht = max(0,min(130,ht));

    case {'ad','ada'} % Use both
      % Frequencies to interpolate.
      f = [125 250 500 750 1000 1500 2000 3000 4000 6000 8000]; % Hz

      % Frequencies of tone detection thresholds.
      f_ht_siam = [250 500 1000 2000 4000 8000]; % Hz

      % Frequencies of tone-in-noise detection thresholds.
      f_ul_siam = [500 1000 2000 4000]; % Hz

      % Tone-in-noise detection thresholds.
      % Example values for normal-hearing.
      tin_siam_nh = [-3.5 -2.0 2.0 4.5]; % Relative level to noise

      % We need to consider three cases:
      % 1) The TIN experiment was clearly supra-threshold (as intended)
      % 2) The TIN was clearly sub-threshold
      % 3) Something in between.
      
      % We will use the "normal hearing" thresholds as "separator"
      % between these cases.
      ul_siam_nh = tin2ul(f_ul_siam, tin_siam_nh);

      % Represent the tone detection levels in dB SPL at eardrum.
      tone_in_quiet_level = ht_siam;
      tone_in_noise_level = calcorr(f_ul_siam,tin_siam + 65);
      tone_in_noise_level_normal = calcorr(f_ul_siam,tin_siam_nh + 65);

      % Define a soft (continuous) criterion for which rule to apply:
      % 1) Tone-in-noise detection threshold more than 5 dB 
      % below normal-hearing tone-in-noise detection threshold
      % -> supra-threshold,
      % 2) Tone-in-quiet detection threshold more than 5 dB 
      % above normal-hearing tone-in-noise detection threshold 
      % -> sub-threshold,
      % 3) Interpolate between both to make the transition smooth.
      thresholdness = tone_in_quiet_level(2:end-1) - tone_in_noise_level_normal;
      criterion = interp1([-100;-5;0;5;100],[0;0;0.5;1;1], ...
        thresholdness, 'linear','extrap');
      
      % If requested, assume "normal" supra-threshold listening, i.e.
      % criterion == 1
      if strcmp(tolower(individualization),'ada')
        criterion = ones(size(criterion));
      end
        
      % Calculate a conservative maximum value
      % for the level uncertainty ul.
      % First calculate ul from tone-in-noise experiments.
      ul_noise = tin2ul(f_ul_siam, tin_siam);
      % Then calculate which values would be indicated
      % only by absolute hearing threshold.
      ul_quiet = tin2ul(f_ul_siam, tone_in_quiet_level(2:end-1) - 65);
      % Subtract any effect due to the absolute hearing threshold.
      ul_diff = ul_noise - (ul_quiet-1);

      % Use the criterion to make the transition between the estimates.
      % If the experiment was sub-threshold we can't separate ul and ht.
      % Hence, if the criterion is 1, ul_eff is ul of normal hearing.
      % Limit the maximum to 20 dB.
      ul_eff = tin2ul(f_ul_siam, tin_siam_nh).*criterion ...
        + min(20, ul_diff.*(1-criterion));    
            
      % Estimate the corresponding increase in tone detection threshold
      % due to the level uncertainty.
      dl_eff = max(0,ul2tin(f_ul_siam,ul_eff) ...
        - ul2tin(f_ul_siam,zeros(size(ul_eff))));

      % Calculate the effective hearing loss due to attenuation ONLY
      % by removing the estimated effect of the level uncertainty using
      % values from 500Hz and 4000Hz at 250Hz and 8000Hz, respectively.
      ht_eff = ht_siam - dl_eff([1,1:end,end]);

      % Interpolate the parameters that describe 
      % attenuation loss (ht_eff) and distiortion loss (ul_eff).
      ht = interp1(f_ht_siam, ht_eff, f, ...
        'linear', 'extrap');
      ul = interp1(f_ht_siam, ul_eff([1,1:end,end]), f, ...
        'linear', 'extrap');
      ul_nh = interp1(f_ht_siam, ul_siam_nh([1,1:end,end]), f, ...
        'linear', 'extrap');

      % Keep values in reasonable ranges.
      ht = max(0,min(130,ht));
      ul = max(ul_nh,min(20,ul));
    otherwise
      error('no such mode');
  end
end
