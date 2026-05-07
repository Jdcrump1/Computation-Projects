% Load ECG data from an Excel file, skipping the first 35 rows
data = readmatrix('/Users/jayc/Desktop/ecgproject/ebme401d_ECG_Project.csv'); % Adjust range if needed

% Extract time and ECG signal columns
time = data(:,1);
ecgsignal = data(:,2);

validIdx = ~isnan(time) & ~isnan(ecgsignal) & isfinite(time) & isfinite(ecgsignal);
time = time(validIdx);
ecgsignal = ecgsignal(validIdx);

% Remove duplicate time points [find unique time values]
[time, uniqueIdx] = unique(time);
ecgsignal = ecgsignal(uniqueIdx);

% Define signal bandwidth (assumption: ECG has components up to 150 Hz)
f_max = 150; % Maximum frequency of interest in Hz

% Compute Nyquist Sampling Rate (twice the highest frequency component)
Fs_nyquist = 2 * f_max;

% Print the Nyquist rate
fprintf('Nyquist Sampling Rate: %.2f Hz\n', Fs_nyquist);

% Define new uniform time vector for resampling
Fs_new = 1000; % Desired new sampling frequency in Hz
t_min = min(time);
t_max = max(time);
time_new = t_min:1/Fs_new:t_max;

% Resample the ECG signal using interp1
ecg_resampled = interp1(time, ecgsignal, time_new, 'linear'); % Linear interpolation

% Plot original and resampled signals
figure;
subplot(2,1,1);
plot(time, ecgsignal, 'b');
xlabel('Time (s)'); ylabel('ECG Signal'); title('Original Signal'); grid on;

subplot(2,1,2);
plot(time_new, ecg_resampled, 'r');
xlabel('Time (s)'); ylabel('ECG Signal'); title('Resampled Signal'); grid on;

% Save resampled data
%save('ecg_resampled.mat', 'time_new', 'ecg_resampled');
