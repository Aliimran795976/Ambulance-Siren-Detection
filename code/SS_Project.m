% -------------------------------------------------------------------------
% Smarter Siren Detection with Sweep Smoothness and Energy Concentration
% -------------------------------------------------------------------------

clc;
clear;
close all;

%% 1. Audio Input and Preprocessing
disp('Select an audio (.wav) file to analyze...');
[file, path] = uigetfile('*.wav', 'Select an audio file');

if isequal(file,0) || isequal(path,0)
    disp('File selection cancelled.');
    return;
end

filename = fullfile(path, file);
[x, fs] = audioread(filename);

if size(x,2) > 1
    x = mean(x,2); % Convert stereo to mono
end
x = x / max(abs(x)); % Normalize

fprintf('Loaded file: %s\n', file);
fprintf('Sampling Rate: %d Hz\n', fs);

%% 2. Bandpass Filter to Focus on Siren Range
bpFilt = designfilt('bandpassiir', 'FilterOrder', 6, ...
    'HalfPowerFrequency1', 500, 'HalfPowerFrequency2', 2000, ...
    'SampleRate', fs);
x_filtered = filtfilt(bpFilt, x);

%% 3. Parameters
frame_duration = 0.25;               % Smaller frame size for faster reaction
frame_length = round(frame_duration * fs);
overlap = round(0.125 * frame_length); % 50% overlap
threshold_energy_ratio = 0.12;         % Lower energy threshold
siren_band = [500 2000];               % Siren frequency band (Hz)
nFrames = floor((length(x_filtered) - frame_length) / (frame_length - overlap)) + 1;

sirens_detected = zeros(1, nFrames);
peak_freqs = zeros(1, nFrames);
energy_ratios = zeros(1, nFrames);
energy_concentration = zeros(1, nFrames);
time_axis = zeros(1, nFrames);

win = hamming(frame_length);

%% 4. Frame Processing: FFT, Energy, Peak Frequency
for k = 1:nFrames
    start_idx = (k-1)*(frame_length-overlap) + 1;
    frame = x_filtered(start_idx : start_idx + frame_length -1);
    frame = frame .* win;

    Y = fft(frame);
    f = (0:length(Y)-1) * fs / length(Y);
    magY_sq = abs(Y).^2;
    magY_sq(1) = 0; % Ignore DC

    idx_band = find(f >= siren_band(1) & f <= siren_band(2));
    band_energy = sum(magY_sq(idx_band));
    total_energy = sum(magY_sq);
    energy_ratio = band_energy / total_energy;

    energy_ratios(k) = energy_ratio;

    [~, idx_peak_local] = max(magY_sq(idx_band));
    peak_freqs(k) = f(idx_band(idx_peak_local));

    % Energy Concentration (around peak)
    idx_peak = idx_band(idx_peak_local);
    idx_range = max(idx_peak-2,1):min(idx_peak+2,length(magY_sq));
    energy_peak_band = sum(magY_sq(idx_range));
    energy_full_band = sum(magY_sq(idx_band));
    energy_concentration(k) = energy_peak_band / energy_full_band;

    time_axis(k) = (start_idx + frame_length/2) / fs;
end

%% 5. Detection Logic

% Smooth energy ratio across frames
energy_ratios_smooth = movmean(energy_ratios, 3);

% Basic energy-based detection
energy_based_detection = energy_ratios_smooth > threshold_energy_ratio;

% Sweep detection
peak_diff = diff(peak_freqs);
peak_diff_smooth = movmean(peak_diff, 3);
sweep_detect = [abs(peak_diff_smooth) > 30 0]; % 30 Hz sweep threshold

% Smoothness of sweep detection
peak_slope_std = movstd(peak_diff,5);
smooth_sweep = [peak_slope_std < 50 0]; % smooth sweeping pattern

% Concentrated energy near peak
narrowband_signal = energy_concentration > 0.4;

% Raw detection: Energy + Sweep
raw_detection = energy_based_detection & sweep_detect;

% Smart detection: add Smoothness + Energy Concentration
smart_detection = raw_detection & smooth_sweep & narrowband_signal;

% Require group of frames
min_cluster_size = 1; % Allow short bursts
final_detection = bwareaopen(smart_detection, min_cluster_size);

%% 6. Output
disp('Detection complete.');
num_detections = sum(final_detection);
fprintf('Siren detected in %d frames out of %d total frames.\n', num_detections, nFrames);

%% 7. Plotting depending on detection result

if num_detections > 0
    % Plot signal, peak frequencies, and detection
    figure;
    subplot(3,1,1);
    plot((1:length(x))/fs, x, 'b');
    xlabel('Time (s)');
    ylabel('Amplitude');
    title('Audio Signal');
    legend('Audio Signal');
    grid on;
    
    subplot(3,1,2);
    plot(time_axis, peak_freqs, 'k', 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Peak Frequency (Hz)');
    title('Peak Frequency Over Time');
    legend('Peak Frequency');
    ylim([500 2000]);
    grid on;
    
    subplot(3,1,3);
    stem(time_axis, final_detection, 'r','filled','LineWidth',1.5);
    xlabel('Time (s)');
    ylabel('Siren Detected');
    title('Siren Detection Timeline');
    legend('Detected Siren Frames');
    ylim([-0.2 1.2]);
    grid on;
    
    sgtitle('Smart Siren Detection System');

    
else
    disp('No siren detected in the audio.');
end

% Always show CWT regardless of detection
figure;
cwt(x_filtered, fs);
title('Continuous Wavelet Transform (Filtered Audio)');
