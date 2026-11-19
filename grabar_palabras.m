%% GRABACIÓN DE PALABRAS DE REFERENCIA
% Graba varias repeticiones de cada comando: Adelante, Atras, Izquierda, Derecha.
% Se guardan como Adelante_1.wav ... Adelante_5.wav, etc.
clc
clear
close all

palabras = {'Adelante','Atras','Izquierda','Derecha'};
Fs   = 44100;   % frecuencia de muestreo
dur  = 1.5;     % TODAS las grabaciones duran lo mismo
nRep = 5;       % repeticiones por palabra (más = mejor reconocimiento)

disp('Ingrese 1 para Adelante')
disp('Ingrese 2 para Atras')
disp('Ingrese 3 para Izquierda')
disp('Ingrese 4 para Derecha')
disp('Ingrese 5 para grabar TODAS'), disp(' ')
z = input('Seleccione la grabación que desea guardar: ');

if z == 5
    lista = 1:4;
else
    lista = z;
end

y = audiorecorder(Fs,16,1);

for p = lista
    fprintf('\n===== %s =====\n', upper(palabras{p}));
    for k = 1:nRep
        fprintf('Repetición %d de %d. ', k, nRep);
        pause(1)
        disp('Iniciando grabación. Hable ahora')
        recordblocking(y, dur);
        disp('Ha finalizado la grabación')
        yy = getaudiodata(y);
        sound(yy, Fs);
        audiowrite(sprintf('%s_%d.wav', palabras{p}, k), yy, Fs);
        pause(dur + 0.3);   % esperar a que termine de reproducirse
    end

    % --- Gráficas de la última grabación (señal normalizada y su TF) ---
    norm = yy / max(abs(yy));
    TF   = abs(fft(norm));
    f    = (0:length(TF)-1) * Fs / length(TF);
    t    = (0:length(norm)-1) / Fs;
    figure('Name', palabras{p})
    subplot(2,1,1), plot(t, norm, 'r'), title(['NORM ' upper(palabras{p})]), xlabel('Tiempo (s)')
    subplot(2,1,2), plot(f(f<4000), TF(f<4000), 'r'), title(['TF ' upper(palabras{p})]), xlabel('Frecuencia (Hz)')
end

disp(' '), disp('Grabaciones guardadas.')
