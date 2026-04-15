class ReglasPatioResource < FastMcp::Resource
  uri          "logistica://reglas-patio"
  resource_name "Reglas del Patio"
  description  "Documento de referencia con las reglas operativas del sistema de patios."
  mime_type    "text/plain"

  def content
    <<~REGLAS
      === REGLAS OPERATIVAS DEL PATIO ===

      1. INGRESO DE CONTENEDORES
         - Todo contenedor debe tener un codigo unico (ej: MSCU1234567).
         - Se asigna automaticamente al primer slot libre (fila x columna).
         - Opcionalmente se puede vincular a una patente de camion.

      2. CAPACIDAD
         - Cada patio tiene una grilla de N filas x M columnas.
         - Un slot solo puede alojar un contenedor a la vez.
         - Si no hay slots libres, el ingreso es rechazado.

      3. RETIRO
         - Al retirar un contenedor su slot queda libre de inmediato.
         - El contenedor deja de existir en el sistema (no hay historial).

      4. LIMITES OPERATIVOS
         - Ocupacion maxima recomendada: 85% de la capacidad total del patio.
         - Por encima del 85% se considera patio en estado CRITICO.

      5. PATENTES
         - Una patente puede estar asociada a multiples contenedores.
         - No es obligatorio registrar patente al ingresar un contenedor.
    REGLAS
  end
end
