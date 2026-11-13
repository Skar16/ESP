
%% High and Low pass
clc; clear; close all;
fs = 50e3;  M = 5;
dp = 0.01;  ds = 10^(-40/20);               % 0.01 each
[n,fo,ao,w] = firpmord([2700 2900],[1 0],[dp ds],fs);
%n    = n + mod(n,2);                        % force EVEN order -> type I, integer delay
b_lp = firpm(n,fo,ao,w);
b_hp = [zeros(1,n/2) 1 zeros(1,n/2)] - b_lp;   % complementary HP

[H1,f] = freqz(b_lp,1,2^16,fs);  H2 = freqz(b_hp,1,2^16,fs);
subplot(211); plot(f,20*log10(abs(H1))); grid; title('Lowpass'); ylim([-50 10])
subplot(212); plot(f,20*log10(abs(H2))); grid; title('Highpass'); ylim([-50 10])
max(abs(abs(H1(f<=2700))-1))                % passband deviation
20*log10(max(abs(H1(f>=2900))))             % stopband level in dB



%% Optimal M 
Mv = 2:0.001:8; E = zeros(size(Mv));
for i = 1:numel(Mv)
    Nd = firpmord([2700 fs/Mv(i)-2700],[1 0],[dp/3 ds],fs); % lowpass
    Nk = firpmord([2700 2900],[1 0],[dp/3 ds],fs/Mv(i)); % lowpass
    E(i) = (2*(Nd+1)+(Nk+1))/Mv(i);
end
[~,k] = min(E); M_opt = Mv(k)
% Optimum 6


%% Decomposition decimation, interpolation, kernel
M = 5;
[nd,fo,ao,w] = firpmord([2700 fs/M-2700],[1 0],[dp/3 ds],fs);  nd = nd+mod(nd,2);
hd = firpm(nd,fo,ao,w);                                  % decimator = interpolator (N=26)
[nk,fo,ao,w] = firpmord([2700 2900],[1 0],[dp/3 ds],fs/M); nk = nk+mod(nk,2);
hk = firpm(nk,fo,ao,w);                                  % kernel at 10 kHz (N=116)

% Polyphase components (zero-pad to multiple of M: 27 -> 30 taps, 6 per phase)
hdp = [hd zeros(1,M*ceil(numel(hd)/M)-numel(hd))];
for lam = 1:M, Hpoly{lam} = hdp(lam:M:end); end         % H_{M,lambda}

% Equivalent high-rate cascade (for plotting)
hku = zeros(1,M*nk+1); hku(1:M:end) = hk;                % H_kern(z^M)
hcas = conv(conv(hd,hku),hd);                            % interp gain M cancels the 1/M
plot_mag(hd), plot_mag(hk), plot_mag(hcas)               % your plotting routine
%write_coeff(...)                                         % write Hpoly{1..5}, hk to dec_kernel_int.h