function f0 = tonoVoz(x, Fs)
% Estima el tono promedio de la voz (frecuencia fundamental en Hz)
% usando autocorrelación en tramos de 40 ms.
x = x(:,1) - mean(x(:,1));
win = round(0.04*Fs); hop = round(0.02*Fs);
lagMin = floor(Fs/400); lagMax = ceil(Fs/70);   % voz humana: 70-400 Hz
nFr = floor((length(x)-win)/hop) + 1;
energia = zeros(1,nFr);
for i = 1:nFr
    seg = x((i-1)*hop+1 : (i-1)*hop+win);
    energia(i) = sum(seg.^2);
end
f = nan(1,nFr);
for i = 1:nFr
    if energia(i) < 0.1*max(energia), continue; end
    seg = x((i-1)*hop+1 : (i-1)*hop+win);
    r = zeros(1,lagMax);
    for lag = lagMin:lagMax
        r(lag) = sum(seg(1:end-lag) .* seg(1+lag:end));
    end
    [pico, L] = max(r(lagMin:lagMax));
    if pico > 0.3*energia(i)          % solo tramos con voz clara
        f(i) = Fs / (L + lagMin - 1);
    end
end
f0 = median(f(~isnan(f)));
end