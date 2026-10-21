%%
% filename: lab01_prep.m
% date: 2026-10-21
% author: torben burandt
% Preperation for ESP lab01 
clear; close all; clc;

M = 4; % down/up sample constant
L = 4;
lambda = 0:3; 

F_bat = 15e3; % 15kHz Bat signal
F_s = 50e3; % 50kHz sample freuqncy

%% 3.1 Chirp 
t_1 = 3; % duration of chirp
n = 0:F_s*t_1-1; % sample points in 3s, -1 for 0 start
t_0 = n/F_s; % sample points at time with fs frequency

fs1=14e3; % start frequency
fs2=17e3; % stop frequency
%f_range = [14e3:17e3]; %14-17kHz


x=chirp(t_0,fs1,t_1,fs2, 'linear'); % from 0 to 3s with linear method

n1 = 1000;  n2 = 1030;
figure('Name','3.1 Chirpsignal');
subplot(2,1,1); spectrogram(x, hann(1024), 768, 1024, F_s, 'yaxis'); % hanning window, 768 overlapping data points i+=256 with each step, 1024 dft points as approximation
title('Spectrogram X[l,k] of x[n]');
subplot(2,1,2); stem(n1:n2, x(n1+1:n2+1), 'filled'); grid on; % narrow window of signal
xlabel('n'); title(sprintf('x[n], n = %d ... %d', n1, n2));

%% 3.2 Downsample M4, lambad 0/3

fs_down =  F_s/M; % new downsampled fs
N = 100; % points for new plot

% Plot all M polyphase signals
figure('Name', 'Polyphase Signals');

% Downsample signal x, by factor M=4, and polyphase lambda
for k=1:M
    lam = lambda(k)

    x_lambda=downsample(x,M,lam); %downsample with iterating polyphase
    N_plot = min(N, length(x_lambda)); % get first 100 samples
    m = 0:N_plot-1; % x-axis

    subplot(M,1,k);
    stem(m,x_lambda(1:N_plot), 'filled');
    grid on;

    ylabel(sprintf('x_{%d}[m]', lam));
    title(sprintf('\\lambda = %d', lam));
    xlim([0 N-1]);

end
xlabel('Sample index m');
sgtitle(sprintf('Polyphase Signals, f_s'' = %.1f kHz', ...
    fs_down/1e3));