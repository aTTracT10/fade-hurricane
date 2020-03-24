function window_function = hann_win(width)
  % A hanning window of "width" with the maximum centered on the center sample
  x_center = 0.5;
  step = 1/width;
  right = x_center:step:1;
  left = x_center:-step:0;
  x_values = [left(end:-1:1) right(2:end)].';
  valid_values_mask = (x_values > 0) & (x_values < 1);
  window_function = 0.5 * (1 - ( cos(2*pi*x_values(valid_values_mask))));
end
