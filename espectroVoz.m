function F = espectroVoz(x, Fs)
% Huella de una palabra usando la Transformada de Fourier:
% preénfasis, recorte de silencio, normalización y FFT de 4 segmentos
% medida en 24 bandas de 100 a 4000 Hz (vector de 96 valores).
nSeg    = 4;
nBandas = 24;

x = x(:,1);
x = x - mean(x);
x = filter([1 -0.95], 1, x);          % preénfasis

% Recortar el silencio (tramos de 20 ms)
win = round(0.02*Fs);
nFr = floor(length(x)/win);
E   = sum(reshape(x(1:nFr*win), win, nFr).^2, 1);
act = find(E > 0.05*max(E));
if ~isempty(act) && max(E) > 0
    x = x((act(1)-1)*win+1 : act(end)*win);
end

% Normalización
x = x / (max(abs(x)) + eps);
minLen = nSeg*2048;
if length(x) < minLen
    x = [x; zeros(minLen-length(x),1)];
end

% FFT por segmentos y energía por bandas
bordes = logspace(log10(100), log10(4000), nBandas+1);
L = floor(length(x)/nSeg);
w = 0.5 - 0.5*cos(2*pi*(0:L-1)'/(L-1));   % ventana de Hann
f = (0:L-1)' * Fs / L;
F = zeros(nSeg, nBandas);
for s = 1:nSeg
    seg = x((s-1)*L+1 : s*L) .* w;
    X   = abs(fft(seg)).^2;
    for b = 1:nBandas
        F(s,b) = sum(X(f >= bordes(b) & f < bordes(b+1)));
    end
end

F = log(F + 1e-10);
F = F(:)';
F = (F - mean(F)) / (std(F) + eps);
end