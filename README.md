# Ambulance-Siren-Detection
Traffic Noise Analysis and Ambulance Siren Detection using various Matlab Audio filtering and transform

💡 Why This Project?
In dense urban environments, the rapid and safe passage of emergency vehicles is critical. Standard traffic noise can easily mask the sound of an ambulance siren, leading to delayed response times. This project aims to solve this problem by creating an intelligent system that can automatically detect the specific acoustic signature of an ambulance siren in real-time, even amidst loud and chaotic background noise. By isolating and identifying the siren's unique pattern, this system can be a foundational component for smart traffic management systems, automated alerts, and other technologies designed to clear the way for emergency responders.

🛠️ How It Works: A Technical Breakdown
The entire detection process is implemented in a single MATLAB script. It uses a multi-layered approach based on digital signal processing techniques to distinguish a siren's sound from ambient noise with high accuracy. The core logic does not rely on pre-trained models but rather on the fundamental acoustic properties of a siren.

Here is a step-by-step explanation of the code's functionality:

1. Audio Input & Preprocessing
File Input: The script begins by prompting the user to select a .wav audio file.

Signal Standardization: The audio is loaded, and if it's a stereo recording, it's converted to a single-channel (mono) signal by averaging the left and right channels. The signal's amplitude is then normalized to a range of [-1, 1] to ensure consistent processing regardless of the original recording volume.

Bandpass Filtering: This is a crucial step for noise reduction. A digital IIR (Infinite Impulse Response) bandpass filter is applied to the audio. This filter is designed to only allow frequencies between 500 Hz and 2000 Hz to pass through, which is the typical operational range for most ambulance sirens. This immediately discards a significant amount of irrelevant low-frequency (e.g., engine rumbles) and high-frequency noise.

2. Frame-by-Frame Analysis
The filtered audio signal is not analyzed all at once. Instead, it's broken down into small, overlapping chunks or "frames" (each 0.25 seconds long). This allows the system to analyze how the sound's properties change over time. For each frame, the script performs:

Windowing: A Hamming window is applied to the frame to prevent spectral leakage, a phenomenon that can create false frequency components during analysis.

FFT (Fast Fourier Transform): The FFT is used to transform the time-domain signal of the frame into the frequency domain. This reveals which frequencies are present in that specific moment of audio and how strong they are.

3. "Smart" Feature Extraction & Detection Logic
This is the core intelligence of the script. A simple check for energy in the siren's frequency band is not enough to avoid false positives from other noises like car horns or alarms. Therefore, the system looks for a combination of four distinct characteristics in each frame:

High Energy Ratio: It calculates the ratio of energy within the 500-2000 Hz band to the total energy in the frame. A siren will cause this ratio to be high. The detection is triggered if this ratio exceeds a threshold_energy_ratio of 0.12.

Frequency Sweep Detection: Sirens are characterized by their "wailing" sound, which is a rapid change (or sweep) in frequency. The script identifies the peak frequency (the strongest one) in each frame and then calculates the rate of change between consecutive frames. A sweep is detected if this change is greater than 30 Hz.

Sweep Smoothness: A true siren sweep is smooth and continuous, not jagged or random. The script verifies this by calculating the standard deviation of the frequency changes over a small window of frames. A low standard deviation indicates a smooth, consistent sweep, characteristic of a real siren.

Energy Concentration (Tonal Quality): A siren produces a strong, tonal sound at a specific frequency. In contrast, noise is typically broadband (spread across many frequencies). The script measures how concentrated the energy is around the peak frequency. A high concentration confirms the sound is a strong, narrowband signal, like a siren.

A frame is marked as containing a "siren" only if all four of these conditions are met simultaneously. This multi-layered verification makes the detection robust and significantly reduces the chance of false alarms.

4. Visualization & Output
After analyzing the entire audio file, the script provides a clear summary of its findings:

Console Output: It prints a message indicating whether a siren was detected and in how many frames.

Visual Plots:

If a siren is detected, a multi-panel figure is generated showing:

The original audio waveform.

A plot of the peak frequency over time, visually demonstrating the frequency sweep.

A timeline that clearly marks the exact moments the siren was detected.

Regardless of the result, the script also displays a Continuous Wavelet Transform (CWT) of the filtered signal. The CWT provides a detailed time-frequency heatmap of the audio, offering an excellent visual confirmation of the siren's energy signature.

📜 License
This project is licensed under the MIT License.
