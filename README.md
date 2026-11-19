# Robot por voz – Proyecto de Procesamiento Digital de Señales

Sistema de reconocimiento de voz en MATLAB que controla un robot móvil de dos ruedas
con los comandos **adelante, atrás, izquierda y derecha**. Solo obedece la voz del
usuario registrado gracias a una verificación por tono (frecuencia fundamental).

**Integrantes:** Proaño Bautista Fausto Patricio, Alencastro Caiza Erick Xavier
**Universidad Politécnica Salesiana – Grupo 1 – Docente: Carlos Pillajo**

## Hardware
- Arduino Uno (MATLAB Support Package for Arduino Hardware)
- Driver de motores L298N
- 2 motores DC con reductora
- Micrófono de la laptop

## Archivos
| Archivo | Función |
|---|---|
| `grabar_palabras.m` | Graba 5 repeticiones de cada comando |
| `espectroVoz.m` | Huella espectral: preénfasis, recorte de silencio, FFT en 4 segmentos y 24 bandas |
| `tonoVoz.m` | Estima el tono de la voz por autocorrelación |
| `moverRobot.m` | Controla los motores (dirección y velocidad PWM) |
| `ReconocimientoVozRobot.m` | Interfaz gráfica y reconocimiento |
| `*.wav` | Grabaciones de entrenamiento |

## Cómo usarlo
1. Conectar el Arduino por USB (puerto COM6).
2. Abrir MATLAB en la carpeta del proyecto.
3. Escribir `ReconocimientoVozRobot` en la ventana de comandos.
