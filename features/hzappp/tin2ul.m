function ul = tin2ul(f, t)
[ul_data, freq_data, threshold_data] = textread(fullfile(fileparts(mfilename('fullpath')),'ul2tintable.txt'),'%f %f %f\n');
uls = sort(unique(ul_data));
freqs = sort(unique(freq_data)).';

table = nan(length(uls),length(freqs));
for i=1:length(uls)
  for j=1:length(freqs)
    idx = find(ul_data == uls(i) & freq_data == freqs(j));
    if ~isempty(idx) && length(idx)>0
      table(i,j) = mean(threshold_data(idx));
    end
  end
end

% Fit polynomial
ps = zeros(3,length(freqs));
for i=1:length(freqs)
  ps(:,i) = polyfit(uls, table(:,i), 2);
end

if numel(f) == 1 && numel(t) > 1
  f = f.*ones(size(t));
end

ul = nan(size(f));
% Output values
for i=1:length(f)
  p = interp1(freqs.',ps.',f(i),'linear','extrap');
  if t(i) > polyval(p,26)
    ul(i) = 26;
  elseif t(i) < polyval(p,1)
    ul(i) = 1;
  else
    ul(i) = interp1(polyval(p,linspace(1,26,100)),linspace(1,26,100),t(i),'linear','extrap');
  end
end
