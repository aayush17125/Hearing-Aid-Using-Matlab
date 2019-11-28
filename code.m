clc
clear
close all
% disp('recording...');
% recObj = audiorecorder;
% recordblocking(recObj,5);
% disp('recorded');
% %%
% disp('playing recorded sound...');
% play(recObj);
% pause(7);
%%
% y = getaudiodata(recObj);
% input= 'Counting-16-44p1-mono-15secs.wav';

% input = 'audio.wav';
% [in,fs] = audioread(input);
% [y,fs] = audioread(input);
load handel.mat
fs=Fs;
y = y(:, 1);
%info = audioinfo(input);
sound(y);
pause(10);
figure,plot(y);
title('input');
%%
y = awgn(y,40);
figure,plot(y);
title('awgn');
disp('playing added noise...');
sound(y);
pause(10)
%%
% yd = wdenoise(y,3,'Wavelet','db3','DenoisingMethod','UniversalThreshold','ThresholdRule','Soft','NoiseEstimate','LevelDependent');
disp('playing denoised sound...');
[thr,sorh,keepapp]=ddencmp( 'den' , 'wv' ,y);  
[yd,~,~,~,~]=wdencmp( 'gbl' ,y, 'db3' ,2,thr,sorh,keepapp);  
sound(yd);

figure,plot(yd);
title('denoise');
pause(10)
%% Best till now
%'Fp,Fst,Ap,Ast' (passband frequency, stopband frequency, passband ripple, stopband attenuation)
hlpf = fdesign.lowpass('Fp,Fst,Ap,Ast',3.0e3,3.5e3,0.5,50,fs);
D = design(hlpf);
x = filter(D,y);
disp('playing denoised sound');
sound(x,fs);
figure,plot(x);
title('denoise');
pause(10)
%% freq shaper
g = 45;
freqP = [1000, 1500, 2550, 5000];
T = 1/fs;
len = length(x);
p = log2(len);
p = ceil(p);
N = 2^p;
X = fft(x,N);
gain = linspace(0,0,N);
gain = gain.';
%for first stage
firstC = (0.3*(g-1))/freqP(1);
k = 0;
while (k/N<=freqP(1)/fs)
   gain(k+1) = firstC*k/(N*T) + 1; %paper step 1
   gain(N-k) = gain(k+1);
   k=k+1;
end
% for second stage
secondC = firstC*freqP(1)+1;
secondC2 = (freqP(2)-freqP(1))/5;
while (k/N<= freqP(2)/fs)
    gain(k+1) = ((secondC-1)*exp(-((k/(N*T))-freqP(1))/secondC2)) + 1;
    gain(N-k) = gain(k+1);
    k=k+1;
end

thirdC = ((secondC-1)*exp(-freqP(2)/secondC2)) +1;
thirdC2 = (freqP(3)-freqP(2))/5;
while (k/N<= freqP(3)/fs)
    gain(k+1) = ((thirdC-g)*exp(-((k/(N*T)-freqP(2)))/thirdC2)) +g;
    gain(N-k) = gain(k+1);
    k=k+1;
end

while (k/N<=freqP(4)/fs)
    gain(k+1) = g;
    gain(N-k) = gain(k+1);
    k=k+1;
end

fifthC = g;
fifthC2 = (fs/2-freqP(4))/5;
while (k/N<=0.5)
    gain(k+1) = ((fifthC-1)*exp(-((k/(N*T))-freqP(4))/fifthC2)) +1;
    gain(N-k) = gain(k+1);
    k=k+1;
end
k_v = (0:N-1)/N;
disp(N);
figure,plot(k_v,gain);
title('Gain');
k_v = k_v*fs;
k_v = k_v(1:N/2+1);
figure,plot(k_v,gain(1:N/2+1));
title('Frequency Shaper Transfer Function');
xlabel('Frequency (Hertz)');
ylabel('Gain');
xlim([0 10000]);
Y = X+gain; % for X refer line no.27
y = real(ifft(Y,N));
y = y(1:len);
t=(0:1/fs:(len-1)/fs);
figure;
subplot(2,1,1);
plot(t,y,'r');
title('Signal after addition of gain');
subplot(2,1,2);
plot(t,x);
title('Adjusted Signal');

%%
sound(y,fs);
pause(10);
%% amplitude shaper
out1=fft(y);
phse=angle(out1);
mag=abs(out1)/N;
[magsig,~]=size(mag);
threshold=100;
out=zeros(magsig,1);
for i=1:magsig/2
    if(mag(i)>threshold)
        mag(i)=threshold;mag(magsig-i)=threshold;
    end
    out(i)=mag(i)*exp(j*phse(i));
    out(magsig-i)=out(i);
end
outfinal=real(ifft(out));
sound(outfinal,fs);