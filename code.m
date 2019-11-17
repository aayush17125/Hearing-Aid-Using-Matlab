clc
clear
close all
disp('recording...');
recObj = audiorecorder;
recordblocking(recObj,5);
disp('recorded');
%%
disp('playing recorded sound...');
play(recObj);
pause(7);
%%
Fs = 8000;
fs = Fs;
y = getaudiodata(recObj);
figure,plot(y);
title('input');
y = awgn(y,40);

figure,plot(y);
title('awgn');
disp('playing added noise...');
sound(y);
pause(7)
%%
% yd = wdenoise(y,3,'Wavelet','db3','DenoisingMethod','UniversalThreshold','ThresholdRule','Soft','NoiseEstimate','LevelDependent');
disp('playing denoised sound...');
[thr,sorh,keepapp]=ddencmp( 'den' , 'wv' ,y);  
yd=wdencmp( 'gbl' ,y, 'db3' ,2,thr,sorh,keepapp);  
sound(yd);
figure,plot(yd);
title('denoise');
%% Best till now
%'Fp,Fst,Ap,Ast' (passband frequency, stopband frequency, passband ripple, stopband attenuation)
Fs = 8000;
hlpf = fdesign.lowpass('Fp,Fst,Ap,Ast',3.0e3,3.5e3,0.5,50,Fs);
D = design(hlpf);
yd = filter(D,y);
disp('playing denoised sound');
sound(yd,Fs);
figure,plot(yd);
title('denoise');

%% freq shaper
g = 45;
freqP = [1000, 1500, 2550, 5000];
fs = Fs;
T = 1/fs;
len = length(yd);
p = log2(len);
p = ceil(p);
N = 2^p;
x = fft(yd,N);
gain = linspace(0,0,N);
%for first stage
firstC = (0.3*(g-1))/freqP(1);
k = 0;
while (k<=freqP(1)*N/fs)
   gain(k+1) = firstC*k/(N*T) + 1; %paper step 1
    gain(N-k) = gain(k+1);
    k=k+1;
end
% for second stage
secondC = firstC*freqP(1)+1;
secondC2 = (freqP(2)-freqP(1))/5;
while (K<= freqP(2)*N/fs)
    gain(k+1) = ((secondC-1)*exp(-((k/(N*T))-freqP(1))/secondC2)) + 1;
    gain(N-k) = gain(k+1)
    k=k+1;
end
%% amplitude shaper
out1=fft(out);
phse=angle(out1);
mag=abs(out1)/N;
threshold=100
for i=1:size(mag)
    if(mag((i)>threshold)
        mag(i)=threshold
    end
    out(i)=mag(i)*exp(j*phse(i));
end
outfinal=ifft(out);
