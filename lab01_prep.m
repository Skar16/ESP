%%
% filename: lab01_prep.m
% date: 2026-10-21
% author: torben burandt
% Preperation for ESP lab01 
clear; close all; clc;
addpath('/home/torben/Github/ESP/MATLAB_support/');
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
    lam = lambda(k);

    x_lambda{k}=downsample(x,M,lam); %downsample with iterating polyphase
    N_plot = min(N, length(x_lambda{k})); % get first 100 samples
    m = 0:N_plot-1; % x-axis

    subplot(M,1,k);
    stem(m,x_lambda{k}(1:N_plot), 'filled');
    grid on;

    ylabel(sprintf('x_{%d}[m]', lam));
    title(sprintf('\\lambda = %d', lam));
    xlim([0 N-1]);

end
xlabel('Sample index m');
sgtitle(sprintf('Polyphase Signals, f_s'' = %.1f kHz', ...
    fs_down/1e3));
%% 3.3 Upsample no Interpolation

y_prime_0=upsample(x_lambda{1}, L); % upsample polyphase 0 

n1 = 1000;  n2 = 1030;
figure('Name','3.3 Upsampled no Interpolation');
subplot(2,1,1); spectrogram(y_prime_0, hann(1024), 768, 1024, F_s, 'yaxis'); % hanning window, 768 overlapping data points i+=256 with each step, 1024 dft points as approximation
title('Spectrogram Y[l,k] of y[n]');
subplot(2,1,2); stem(n1:n2, y_prime_0(n1+1:n2+1), 'filled'); grid on; % narrow window of signal
xlabel('n'); title(sprintf('y[n], n = %d ... %d', n1, n2));

%% 3.4 Interpolation Filter

d_pass = 0.001;
d_stop = 0.001; % -60db
f_pass = F_s/(2*M) -0.5e3; % F_S/M /2 to get nyquiest cirteria, add half bw of 0.5khz
f_stop = F_s/(2*M) +0.5e3;

[N_FIR,fo,mo,w] = firpmord([f_pass f_stop],[1 0] ,[d_pass d_stop], F_s); % design filter
b = firpm(N_FIR,fo,mo,w);
b = round(b*32768)/32768; % round them to 16 bits


y_prime_0f=conv(y_prime_0,b); % apply FIR to upsampled signal

figure('Name', 'Filter Response')
freqz(b, 1, F_s); % plot filter response

% same plot as above 3.3 but with interpolation filter
n1 = 1000;  n2 = 1030;
figure('Name','3.3 Upsampled Interpolation');
subplot(2,1,1); spectrogram(y_prime_0f, hann(1024), 768, 1024, F_s, 'yaxis'); % hanning window, 768 overlapping data points i+=256 with each step, 1024 dft points as approximation
title('Spectrogram Y[l,k] of y[n]');
subplot(2,1,2); stem(n1:n2, y_prime_0f(n1+1:n2+1), 'filled'); grid on; % narrow window of signal
xlabel('n'); title(sprintf('y[n], n = %d ... %d', n1, n2));

%% 3.5 Write coefficents to file
%---------------------------------------------------------------------------
% write to file !
% create header file and info
fprintf('coefficients are written to file ==> ');
filename = 'ESP_Lab01_coeffiecents.h';
fprintf(filename);
fprintf('\n\n');

file_ID = fopen(filename, 'w');		% generate include-file
fprintf(file_ID, '//------------------------------------------- \n');
fprintf(file_ID, '// designed with -- lab01_prep.m -- \n');
fprintf(file_ID, ['// ',date,'\n'] );
fprintf(file_ID, '// Fs = %6.2f\n', F_s );
fprintf(file_ID, '// fstop = %6.2f\n', f_stop);
fprintf(file_ID, '// fpass = %6.2f\n', f_pass);
fprintf(file_ID, '// delta_pass = %6.2f\n', d_pass);
fprintf(file_ID, '// delta_stop_dB = %6.2f\n', d_stop);
fprintf(file_ID, '// N_FIR = %d\n',  N_FIR);
fprintf(file_ID, '//------------------------------------------- \n');

fprintf(file_ID, '#define N_DELAYS_FIR %d\n', length(b));
fprintf(file_ID, 'short H_filt_FIR_McBsp0[N_DELAYS_FIR]; \n');
write_coeff(file_ID, 'b_coef', b, length(b));

fclose(file_ID);