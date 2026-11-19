function ReconocimientoVozRobot(puerto, placa)
% INTERFAZ DE RECONOCIMIENTO DE VOZ PARA EL ROBOT
% Con verificación del hablante: solo obedece la voz registrada.
if nargin < 1, puerto = 'COM6'; end
if nargin < 2, placa  = 'Uno'; end

palabras = {'Adelante','Atras','Izquierda','Derecha'};
Fs   = 44100;
dur  = 1.5;
nRep = 5;
umbralSimilitud = 0.5;    % parecido mínimo con tus grabaciones
umbralEnergia   = 0.005;  % por debajo de esto se considera silencio
tolTono         = 0.20;   % tolerancia del tono de voz (20 %)
vozActual = [];

%% Base de datos: huellas y tono de las palabras grabadas
plantillas = cell(1,4);
tonos = [];
for p = 1:4
    plantillas{p} = [];
    for k = 1:nRep
        archivo = sprintf('%s_%d.wav', palabras{p}, k);
        if exist(archivo, 'file')
            [y, fsa] = audioread(archivo);
            plantillas{p}(end+1,:) = espectroVoz(y, fsa);
            tonos(end+1) = tonoVoz(y, fsa);
        end
    end
    if isempty(plantillas{p})
        error('No hay grabaciones de %s. Ejecuta primero grabar_palabras.m', palabras{p});
    end
end
tonoRef = median(tonos(~isnan(tonos)));   % tu tono promedio
fprintf('Tono de referencia (tu voz): %.0f Hz\n', tonoRef);

%% Conexión con Arduino
try
    a = arduino(puerto, placa);
    moverRobot(a, 'Alto');
catch err
    a = [];
    warndlg(['No se pudo conectar al Arduino (' err.message '). ' ...
             'La interfaz funcionará sin mover el robot.']);
end

%% Ventana
fig = figure('Name','Reconocimiento de voz - Robot','NumberTitle','off', ...
    'MenuBar','none','Position',[150 120 960 540],'CloseRequestFcn',@salir);

uicontrol(fig,'Style','text','String','RECONOCIMIENTO DE VOZ', ...
    'FontSize',16,'FontWeight','bold','Units','normalized','Position',[0.02 0.9 0.4 0.07]);

uicontrol(fig,'Style','text','String','BASE DE DATOS','FontWeight','bold', ...
    'Units','normalized','Position',[0.03 0.78 0.16 0.05]);
for p = 1:4
    uicontrol(fig,'Style','pushbutton','String',palabras{p},'Units','normalized', ...
        'Position',[0.04 0.78-0.11*p 0.14 0.08],'Callback',@(~,~) reproducir(p));
end

uicontrol(fig,'Style','text','String','RECONOCEDOR DE AUDIO','FontWeight','bold', ...
    'Units','normalized','Position',[0.21 0.78 0.2 0.05]);
uicontrol(fig,'Style','pushbutton','String','HABLAR','Units','normalized', ...
    'Position',[0.24 0.67 0.14 0.08],'Callback',@hablar);
uicontrol(fig,'Style','pushbutton','String','Escuchar','Units','normalized', ...
    'Position',[0.24 0.56 0.14 0.08],'Callback',@escuchar);
uicontrol(fig,'Style','pushbutton','String','Reconocer','Units','normalized', ...
    'Position',[0.24 0.45 0.14 0.08],'Callback',@reconocer);
tbAuto = uicontrol(fig,'Style','togglebutton','String','Modo automático','Units','normalized', ...
    'Position',[0.24 0.34 0.14 0.08],'Callback',@modoAutomatico);
txt = uicontrol(fig,'Style','edit','String','---','FontSize',16,'Enable','inactive', ...
    'Units','normalized','Position',[0.04 0.14 0.37 0.1]);
uicontrol(fig,'Style','pushbutton','String','Salir','Units','normalized', ...
    'Position',[0.3 0.03 0.11 0.07],'Callback',@salir);

ax1 = axes(fig,'Position',[0.5 0.6 0.46 0.32]); title(ax1,'Señal de entrada');
ax2 = axes(fig,'Position',[0.5 0.12 0.46 0.36]); title(ax2,'Huella espectral (FFT)');

%% ================= FUNCIONES =================
    function reproducir(p)
        [y, f] = audioread(sprintf('%s_1.wav', palabras{p}));
        sound(y, f);
    end

    function y = grabar()
        set(txt,'String','Grabando...'); drawnow
        rec = audiorecorder(Fs,16,1);
        recordblocking(rec, dur);
        y = getaudiodata(rec);
        if ishandle(fig)
            t = (0:length(y)-1)/Fs;
            plot(ax1, t, y); title(ax1,'Señal de entrada'); xlabel(ax1,'Tiempo (s)');
        end
    end

    function hablar(~,~)
        vozActual = grabar();
        audiowrite('voz.wav', vozActual, Fs);
        set(txt,'String','Listo');
    end

    function escuchar(~,~)
        if ~isempty(vozActual), sound(vozActual, Fs); end
    end

    function cmd = clasificar(y)
        cmd = '';
        % 1) ¿Hay voz o solo silencio?
        if sqrt(mean(y.^2)) < umbralEnergia
            set(txt,'String','(silencio)'); return
        end
        % 2) ¿Es la voz registrada? (verificación por tono)
        tono = tonoVoz(y, Fs);
        fprintf('Tono detectado: %.0f Hz (referencia %.0f Hz)\n', tono, tonoRef);
        if isnan(tono) || abs(tono - tonoRef)/tonoRef > tolTono
            set(txt,'String',sprintf('Voz no autorizada (%.0f Hz)', tono)); return
        end
        % 3) ¿Qué palabra dijo? (comparación de huellas FFT)
        Fv = espectroVoz(y, Fs);
        puntaje = zeros(1,4);
        mejorPlantilla = cell(1,4);
        for p = 1:4
            r = zeros(1, size(plantillas{p},1));
            for k = 1:size(plantillas{p},1)
                c = corrcoef(Fv, plantillas{p}(k,:));
                r(k) = c(1,2);
            end
            [puntaje(p), kk] = max(r);
            mejorPlantilla{p} = plantillas{p}(kk,:);
        end
        [mejor, idx] = max(puntaje);

        plot(ax2, Fv, 'b'); hold(ax2,'on');
        plot(ax2, mejorPlantilla{idx}, 'r'); hold(ax2,'off');
        legend(ax2, 'Entrada', palabras{idx});
        title(ax2, sprintf('Similitud: Ad %.2f | At %.2f | Iz %.2f | De %.2f', puntaje));

        if mejor >= umbralSimilitud
            cmd = palabras{idx};
            set(txt,'String',sprintf('%s (%.0f Hz)', cmd, tono));
        else
            set(txt,'String','No reconocido');
        end
    end

    function mover(cmd)
        if ~isempty(a) && ~isempty(cmd)
            moverRobot(a, cmd);
        end
    end

    function reconocer(~,~)
        if isempty(vozActual)
            set(txt,'String','Primero presiona HABLAR'); return
        end
        mover(clasificar(vozActual));
    end

    function modoAutomatico(~,~)
        if get(tbAuto,'Value') == 0, return; end
        set(txt,'String','Silencio... calibrando'); drawnow
        rec = audiorecorder(Fs,16,1);
        recordblocking(rec, 1);
        umbralEnergia = max(3*sqrt(mean(getaudiodata(rec).^2)), 0.003);
        while ishandle(fig) && get(tbAuto,'Value') == 1
            y = grabar();
            if ~ishandle(fig), return; end
            mover(clasificar(y));
            drawnow
        end
    end

    function salir(~,~)
        if ishandle(fig) && get(tbAuto,'Value') == 1
            set(tbAuto,'Value',0);
        end
        try moverRobot(a,'Alto'); catch, end
        delete(fig);
    end
end