    %% Load ECG Data
clc; clear; close all;

% Load ECG data from CSV
data1 = '/Users/jayc/Desktop/ecgproject/ebme401d_ECG_Project.csv';
data2 = '/Users/jayc/Desktop/ecgproject/cleanecg.csv';

ecgoutput = readmatrix(data1);
uncorrupted = readmatrix(data2);

% Extract time and ECG signal for both datasets
raw_time1 = ecgoutput(:,1);
raw_ecg1 = ecgoutput(:,2);
raw_time2 = uncorrupted(:,1);
raw_ecg2 = uncorrupted(:,2);

% Remove NaN and non-finite values for both
validIdx1 = ~isnan(raw_time1) & ~isnan(raw_ecg1) & isfinite(raw_time1) & isfinite(raw_ecg1);
time1 = raw_time1(validIdx1);
ecgsignal1 = raw_ecg1(validIdx1);

validIdx2 = ~isnan(raw_time2) & ~isnan(raw_ecg2) & isfinite(raw_time2) & isfinite(raw_ecg2);
time2 = raw_time2(validIdx2);
ecgsignal2 = raw_ecg2(validIdx2);

% Remove duplicate time points
[time1, uniqueIdx1] = unique(time1);
ecgsignal1 = ecgsignal1(uniqueIdx1);
[time2, uniqueIdx2] = unique(time2);
ecgsignal2 = ecgsignal2(uniqueIdx2);

% Ensure time2 is strictly increasing
[time2, uniqueIdx2] = unique(time2);
ecgsignal2 = ecgsignal2(uniqueIdx2);


%% Resample ECG Signal
Fs_new = 1000; % Resampling frequency in Hz
time_new = min(time1):1/Fs_new:max(time1);
ecgsignal_resampled = interp1(time1, ecgsignal1, time_new, 'linear');

%% Compute and Plot Frequency Spectrum for Both Signals
N = length(ecgsignal_resampled);
freqs = (0:N-1)*(Fs_new/N);
ECG_FFT_resampled = abs(fft(ecgsignal_resampled));
ECG_FFT2 = abs(fft(ecgsignal2));

figure;
subplot(2,1,1);
plot(freqs(1:N/2), ECG_FFT_resampled(1:N/2), 'b');
hold on;
plot(freqs(1:N/2), ECG_FFT2(1:N/2), 'r');
legend('Resampled', 'Uncorrupted');
xlabel('Frequency (Hz)'); ylabel('Magnitude');
title('Frequency Spectrum Comparison'); grid on;

% Plot uncorrupted ECG signal
figure;
plot(time2, ecgsignal2, 'b'); % Plot the uncorrupted ECG signal in blue
xlabel('Time (s)');
ylabel('ECG Signal');
title('Uncorrupted ECG Signal');
grid on;


%% Heart Rate Detection using Peak Detection (Uncorrupted Signal)
threshold = 0.5 * max(ecgsignal2); % Set threshold for R-peaks
% Compute average time step (ensuring it's within limits)
avg_time_step = mean(diff(time2));
min_peak_dist = max(0.6, avg_time_step * 2); % Ensure it's not too small

[pks, locs] = findpeaks(ecgsignal2, time2, 'MinPeakHeight', threshold, 'MinPeakDistance', min_peak_dist);

heart_rate = 60 ./ diff(locs); % Compute instantaneous heart rate
HR_avg = mean(heart_rate);

figure;
plot(time2, ecgsignal2); hold on;
plot(locs, pks, 'ro'); % Mark detected R-peaks
xlabel('Time (s)'); ylabel('ECG Signal'); title('Detected R-peaks (Uncorrupted)'); grid on;

%% Design Digital Filters for Resampled ECG
Fs = Fs_new;

% 1. High-pass filter (Remove 1Hz baseline drift)
hp_cutoff = 1;
[b_hp, a_hp] = butter(2, hp_cutoff/(Fs/2), 'high');
ecgsignal_hp = filtfilt(b_hp, a_hp, ecgsignal_resampled);

figure;
freqz(b_hp, a_hp, 1024, Fs);
title('High-Pass Filter (1 Hz cutoff)');


% Design a 60 Hz notch filter manually
notch_freq = 60; % Notch at 60 Hz
bandwidth = 7; % Define the notch width
order = 4
%wo = notch_freq / (Fs/2); % Normalize frequency
%bw = bandwidth / notch_freq; % Define relative bandwidth
%[b_notch, a_notch] = iirnotch(wo, bw);
%ecgsignal_notch = filtfilt(b_notch, a_notch, ecgsignal_hp);

Wn = [notch_freq - bandwidth/2, notch_freq + bandwidth/2] / (Fs/2); % Normalize
[b_notch, a_notch] = butter(2, Wn, 'stop'); % 2nd-order band-stop filter
ecgsignal_notch = filtfilt(b_notch, a_notch, ecgsignal_hp);

figure;
freqz(b_notch, a_notch, 1024, Fs);
title('Notch Filter (60 Hz)');



% 3. Low-pass filter (Remove 20 kHz noise)
lp_cutoff = 200; % Adjusted to keep ECG components while removing HF noise
[b_lp, a_lp] = butter(2, lp_cutoff/(Fs/2), 'low');
figure;
freqz(b_lp, a_lp, 1024, Fs);
title('Low-Pass Filter (200 Hz cutoff)');


ecgsignal_filtered = filtfilt(b_lp, a_lp, ecgsignal_notch);


%% Compare Filter Effects
figure('Name','Filter Effects','Position',[100 100 800 900]);

% High-Pass Filter
subplot(3,2,1);
plot(time_new, ecgsignal_resampled);
title('Before High-Pass (1 Hz)'); xlabel('Time (s)'); ylabel('ECG');
grid on;
subplot(3,2,2);
plot(time_new, ecgsignal_hp);
title('After High-Pass'); xlabel('Time (s)'); ylabel('ECG');
grid on;

% Notch Filter
subplot(3,2,3);
plot(time_new, ecgsignal_hp);
title('Before Notch (60 Hz)'); xlabel('Time (s)'); ylabel('ECG');
grid on;
subplot(3,2,4);
plot(time_new, ecgsignal_notch);
title('After Notch'); xlabel('Time (s)'); ylabel('ECG');
grid on;

% Low-Pass Filter
subplot(3,2,5);
plot(time_new, ecgsignal_notch);
title('Before Low-Pass (200 Hz)'); xlabel('Time (s)'); ylabel('ECG');
grid on;
subplot(3,2,6);
plot(time_new, ecgsignal_filtered);
title('After Low-Pass'); xlabel('Time (s)'); ylabel('ECG');
grid on;

% Final Overlay
figure('Name','Original vs. Filtered','Position',[950 100 800 400]);
plot(time_new, ecgsignal_resampled,'b','DisplayName','Resampled');
hold on;
plot(time_new, ecgsignal_filtered,'r','DisplayName','Filtered');
title('Original vs. Fully Filtered ECG');
xlabel('Time (s)'); ylabel('ECG');
legend('Location','best'); grid on;


%% Compare Before/After Filtering in Time & Frequency Domains
figure;
subplot(2,1,1);
plot(time_new, ecgsignal_resampled, 'b'); hold on;
plot(time_new, ecgsignal_filtered, 'r');
legend('Resampled', 'Filtered');
xlabel('Time (s)'); ylabel('ECG Signal'); title('Time-Domain Comparison'); grid on;

% Frequency Spectrum Comparison
Nf = length(ecgsignal_filtered);
freqs = (0:Nf-1)*(Fs/Nf);
FFT_filtered = abs(fft(ecgsignal_filtered));

subplot(2,1,2);
plot(freqs(1:Nf/2), ECG_FFT_resampled(1:Nf/2), 'b'); hold on;
plot(freqs(1:Nf/2), FFT_filtered(1:Nf/2), 'r');
legend('Resampled', 'Filtered');
xlabel('Frequency (Hz)'); ylabel('Magnitude'); title('Frequency-Domain Comparison'); grid on;

%% Compute SNR Before and After Filtering
%signal_power = rms(ecgsignal2).^2; % Power of clean ECG signal
%noise_power_before = rms(ecgsignal2 - ecgsignal_resampled).^2; % Noise before filtering
%noise_power_after = rms(ecgsignal2 - ecgsignal_filtered).^2;   % Noise after filtering
%min_length = min(length(ecgsignal2), length(ecgsignal_resampled));

%min_length = min([length(ecgsignal2), length(ecgsignal_resampled), length(ecgsignal_filtered)]);

% Trim all signals to the same length
%ecgsignal2_trimmed = ecgsignal2(1:min_length);
%ecgsignal_resampled_trimmed = ecgsignal_resampled(1:min_length);
%ecgsignal_filtered_trimmed = ecgsignal_filtered(1:min_length);

% Compute noise power before filtering
%noise_power_before = rms(ecgsignal2_trimmed - ecgsignal_resampled_trimmed).^2;

% Compute noise power after filtering
%noise_power_after = rms(ecgsignal2_trimmed - ecgsignal_filtered_trimmed).^2;



%SNR_before = 10 * log10(signal_power / noise_power_before);
%SNR_after = 10 * log10(signal_power / noise_power_after);

%fprintf('SNR Before Filtering: %.2f dB\n', SNR_before);
%fprintf('SNR After Filtering: %.2f dB\n', SNR_after);



%% Heart Rate Detection After Filtering
[pks_filt, locs_filt] = findpeaks(ecgsignal_filtered, time_new, 'MinPeakHeight', threshold, 'MinPeakDistance', min_peak_dist);
heart_rate_filt = 60 ./ diff(locs_filt);
HR_avg_filt = mean(heart_rate_filt);

figure;
plot(time_new, ecgsignal_filtered); hold on;
plot(locs_filt, pks_filt, 'ro');
xlabel('Time (s)'); ylabel('ECG Signal'); title('Filtered ECG with Detected R-peaks'); grid on;

figure;
plot(time_new, ecgsignal_filtered, 'b'); hold on;
plot(locs_filt, pks_filt, 'ro', 'MarkerFaceColor', 'r'); % Mark detected QRS peaks
text(locs_filt, pks_filt, "R", 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center');
xlabel('Time (s)');
ylabel('Filtered ECG Signal');
title('Detected QRS Complexes (Filtered Signal)');
grid on;

%% Display Results
fprintf('Average Heart Rate (Unfiltered - Uncorrupted): %.2f BPM\n', HR_avg);
fprintf('Average Heart Rate (Filtered - Resampled): %.2f BPM\n', HR_avg_filt);



%Save filtered data
%save('ecg_filtered.mat', 'time_new', 'ecgsignal_filtered');

