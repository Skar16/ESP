%% ESP Lab 1 - Preparation (Task 3), lab group ESPL/02
%  M = L = 4, chirp 14...17 kHz, 3.0 s, f_bat = 15 kHz, fs = 50 kHz, lambda = 0 / 3
%  Needs Signal Processing Toolbox. Local function at the end (R2016b or newer).
clear; close all; clc;

M = 4;  L = 4;
f0 = 14e3;  f1 = 17e3;  T = 3.0;
fbat = 15e3;
fs   = 50e3;
fsp  = fs/M;                 % fs' = 12.5 kHz
lam  = [0 3];                % polyphases at DAC CH0 / CH1

%% 3.1 Chirp signal
n = 0:round(T*fs)-1;   t = n/fs;
x = chirp(t, f0, T, f1, 'linear');

n1 = 1000;  n2 = 1060;
figure('Name','3.1');
subplot(2,1,1); spectrogram(x, hann(1024), 768, 1024, fs, 'yaxis');
title('Spectrogram X[l,k] of x[n]');
subplot(2,1,2); stem(n1:n2, x(n1+1:n2+1), 'filled'); grid on;
xlabel('n'); title(sprintf('x[n], n = %d ... %d', n1, n2));

%% 3.2 Downsampling and polyphase components x_lambda[m] = x[M m + lambda]
xl = cell(1, M);
figure('Name','3.2');
for k = 0:M-1
    xl{k+1} = x(k+1:M:end);
    subplot(M,1,k+1); stem(0:99, xl{k+1}(1:100), 'filled'); grid on;
    ylabel(sprintf('x_{%d}[m]', k));
    if k == 0, title('First 100 samples of the polyphase signals (fs'' = 12.5 kHz)'); end
end
xlabel('m');
figure('Name','3.2 spectrogram');
spectrogram(xl{1}, hann(1024), 768, 1024, fsp, 'yaxis'); title('x_0[m]: aliased chirp');

%% 3.3 Upsampling without interpolation filter
yp = zeros(size(x));
yp(1:L:end) = xl{lam(1)+1};          % zero stuffing of x_0[m]
figure('Name','3.3');
subplot(2,1,1); spectrogram(yp, hann(1024), 768, 1024, fs, 'yaxis');
title('Spectrogram Y''[l,k] (no interpolation filter)');
subplot(2,1,2); stem(n1:n2, yp(n1+1:n2+1), 'filled'); grid on;
xlabel('n'); title(sprintf('y''[n], n = %d ... %d', n1, n2));

%% 3.4 Interpolation filter (Parks-McClellan)
dpass = 0.001;  dstop = 0.001;       % -60 dB
fpass = fsp/2 - 0.5e3;               % 5.75 kHz
fstop = fsp/2 + 0.5e3;               % 6.75 kHz  (transition width 1 kHz)
[N, fo, ao, w] = firpmord([fpass fstop], [1 0], [dpass dstop], fs);
h = firpm(N, fo, ao, w);             % unity DC gain
fprintf('Filter order = %d, number of coefficients = %d\n', N, numel(h));

figure('Name','3.4 filter');
[H, f] = freqz(h, 1, 16384, fs);
subplot(2,1,1); plot(f/1e3, 20*log10(abs(H)+1e-12)); grid on; ylim([-100 5]);
xlabel('f [kHz]'); ylabel('|H| [dB]'); title('Interpolation filter');
subplot(2,1,2); stem(h, 'filled'); grid on; title('h[n]');

y = L * filter(h, 1, yp);            % gain L compensates zero stuffing
d = round((numel(h)-1)/2);           % group delay (samples)
figure('Name','3.4');
subplot(2,1,1); spectrogram(y, hann(1024), 768, 1024, fs, 'yaxis');
title('Spectrogram Y[l,k] after interpolation filter');
subplot(2,1,2); stem(n1+d:n2+d, y(n1+d+1:n2+d+1), 'filled'); grid on;
xlabel('n'); title('y[n] (section shifted by the filter delay)');

%% Bat frequency check (question in 3.3)
xb  = cos(2*pi*fbat*n/fs);
ypb = zeros(size(xb));  ypb(1:L:end) = xb(lam(1)+1:M:end);
yb  = L * filter(h, 1, ypb);
Nf  = numel(xb);  fax = (0:Nf/2)*fs/Nf;
A1  = abs(fft(ypb.*hann(Nf)'))/(Nf/4);   % no filter
A2  = abs(fft(yb .*hann(Nf)'))/(Nf/4);   % with filter
figure('Name','bat 15 kHz');
subplot(2,1,1); plot(fax/1e3, A1(1:Nf/2+1)); grid on; title('15 kHz input, no filter');
subplot(2,1,2); plot(fax/1e3, A2(1:Nf/2+1)); grid on; title('15 kHz input, with filter');
xlabel('f [kHz]');

%% 3.5 Export of coefficients (Q15)
hq = round(h * 2^15);
fprintf('N = %d, max = %d (%.4f), min = %d (%.4f)\n', numel(hq), max(hq), max(h), min(hq), min(h));
assert(max(hq) <= 32767 && min(hq) >= -32768, 'coefficients do not fit into int16');
write_coeff_local('fir_coeffs.h', hq);

function write_coeff_local(fname, hq)   % use Moodle write_coeff() if you prefer
    fid = fopen(fname, 'w');
    fprintf(fid, '// FIR interpolation filter ESPL/02, Q15 coefficients\n#include <stdint.h>\n');
    fprintf(fid, '#define FIR_NCOEF %d\n', numel(hq));
    fprintf(fid, 'int16_t FIR_delays[FIR_NCOEF] = {0};\n');
    fprintf(fid, 'int16_t FIR_coe[FIR_NCOEF] = {\n');
    for i = 1:8:numel(hq)
        blk = hq(i:min(i+7, numel(hq)));
        fprintf(fid, '    %s', strjoin(arrayfun(@num2str, blk, 'UniformOutput', false), ', '));
        if i+7 < numel(hq), fprintf(fid, ','); end
        fprintf(fid, '\n');
    end
    fprintf(fid, '};\n');
    fclose(fid);
end
