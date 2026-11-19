function moverRobot(a, comando)
% Mueve el robot con el driver L298N
% comando: 'Adelante', 'Atras', 'Izquierda', 'Derecha' o 'Alto'

% ---- Pines (corregidos según las pruebas) ----
ENA = 'D6';  IN1 = 'D12'; IN2 = 'D8';    % motor izquierdo
ENB = 'D5';  IN3 = 'D7';  IN4 = 'D4';    % motor derecho

% ---- Velocidades (0 a 1) ----
velIzq = 0.7;   % motor izquierdo
velDer = 0.8;   % motor derecho

switch comando
    case 'Adelante',  izq =  1; der =  1; t = 1.0;
    case 'Atras',     izq = -1; der = -1; t = 1.0;
    case 'Izquierda', izq = -1; der =  1; t = 0.4;
    case 'Derecha',   izq =  1; der = -1; t = 0.4;
    otherwise,        izq =  0; der =  0; t = 0;
end

writeDigitalPin(a, IN1, double(izq > 0));
writeDigitalPin(a, IN2, double(izq < 0));
writeDigitalPin(a, IN3, double(der > 0));
writeDigitalPin(a, IN4, double(der < 0));
writePWMDutyCycle(a, ENA, velIzq*abs(izq));
writePWMDutyCycle(a, ENB, velDer*abs(der));

if t > 0
    pause(t);
    moverRobot(a, 'Alto');
end
end