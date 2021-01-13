# ProyectoRPI-HimnoAlegria
Proyecto Final E/S
Alumno: Rey Leyva, Alejandro

Este proyecto se ha desarrollado en una Raspberry PI 3B+

Canción: Himno de la Alegría

Patrones LEDs:
    - MODO1 (Botón 1): Encendido secuencial de los leds, uno a uno, hasta que
    se encienden todos. Después se apagan y vuelve el encendido secuencial.
    - MODO2 (Botón 2): Encendido aleatorio de los leds, simulando a un piano que está
    tocando la partitura.

Estructura Principal del Proyecto:
    - index.s: Archivo principal que contiene la lógica principal.
    - inter.inc: Contiene las variables predefinidas de GPIOs, entre
    otras cosas.
    - himnoAlegria.inc: Contiene dos arrays, arrayNotas y arrayDuraciones,
    que almacenan las notas y las duraciones de las mismas, respectivamente.
    - leds.inc: Contiene dos arrays, ledsMODO1 y ledsMODO2, que almacenan 
    los patrones de leds de ambos modos.
    -variablesGlobales.inc: Contiene las variables predefinidas de las
    frecuencias de las respectivas notas musicales, y las direcciones para
    encender cada uno de los leds.

Lógica del Proyecto (index.s):
    - Variables Globales:
        1. botonPulsado: 
            if (boton1 == on) botonPulsado=1 
            else if (boton 2 == on) botonPulsado=2
        2. bitBuzzer: bit que controla el estado del altavoz 
        3. indexNota: index que recorre el array de notas y duraciones (1 <= indexNota <= NUMNOTAS)
        4. indexLed: index que recorre los arrays de patrones de leds ( 1 <= indexLed <= NUMLEDS)

    - Configuraciones Iniciales:
        1. Cambio de modo HYP a SVC por estar en una RPI 3B
        2. Agregamos vectores de interrupcion IRQ
        3. Inicialización de la pila en modos FIQ, IRQ y SVC
        4. Configuracion de los GPIOs como salida
        5. Programamos C1 y C3 para interrupciones añadiendo 2 ns
        6. Habilitamos C1 -> IRQ // C3 -> FIQ
        7. Activamos interrupciones globalmente

    - Lógica Principal:
        1. Bucle que sondea los botones y actualiza la variable botonPulsado. Si se pulsa
        el botón 1 y venimos del MODO2, apaga todos los leds y pone el indexLed = 1.

        2. irq_handler: Rutina de interrupcion IRQ que maneja los leds
        y las duraciones de encendido de los mismos y de las notas de la
        partitura. Para ello, con el indexLed accedemos al array de patrones
        de leds correspondiente al modo en el que estemos. Encendemos dicho
        led y reprogramamos la interrupcion con la duracion de la nota asociada,
        accediendo con el indexNota al array de duraciones.

        3. fiq_handler: Rutina de interrupcion FIQ que maneja el sonido del
        altavoz y las notas que se deben reproducir en cada momento. Cargamos
        la frecuencia de la nota adecuada con ayuda del indexNota y del arrayNotas, 
        y reprogramamos el retardo de la interrupcion con el valor de la nota extraida
        del array, todo esto controlando el estado del altavoz con la variable bitBuzzer

Enlace a demo del proyecto: https://youtu.be/KASM7Ef4fwU