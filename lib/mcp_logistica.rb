# lib/mcp_logistica.rb
require_relative "../config/environment"
require "json"

# Definicion de herramientas para que la IA sepa que puede preguntar
TOOLS = [
  {
    name: "listar_patios",
    description: "Retorna todos los patios (Yards) con dimensiones, capacidad y disponibilidad.",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "resumen_patios",
    description: "Entrega capacidad total, ocupados, libres y porcentaje de ocupacion por cada patio.",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "estado_ocupacion_yard",
    description: "Muestra capacidad, ocupados, libres y porcentaje en un patio especifico.",
    inputSchema: {
      type: "object",
      properties: { yard_id: { type: "integer" } },
      required: ["yard_id"]
    }
  },
  {
    name: "buscar_contenedor",
    description: "Encuentra la ubicacion fisica (Patio, Fila, Columna) de un contenedor por su codigo.",
    inputSchema: {
      type: "object",
      properties: { codigo: { type: "string" } },
      required: ["codigo"]
    }
  },
  {
    name: "contenedores_por_camion",
    description: "Lista todos los codigos de contenedores asociados a la patente de un camion.",
    inputSchema: {
      type: "object",
      properties: { patente: { type: "string" } },
      required: ["patente"]
    }
  },
  {
    name: "registrar_contenedor",
    description: "Registra un contenedor en un patio y lo asigna a un slot libre. Permite asociar patente de camion opcional.",
    inputSchema: {
      type: "object",
      properties: {
        codigo: { type: "string" },
        yard_id: { type: "integer" },
        patente: { type: "string" }
      },
      required: ["codigo", "yard_id"]
    }
  },
  {
    name: "retirar_contenedor",
    description: "Retira un contenedor del patio por nombre (codigo) y libera su slot.",
    inputSchema: {
      type: "object",
      properties: {
        nombre: { type: "string" }
      },
      required: ["nombre"]
    }
  }
]

# Metodo auxiliar para responder en formato JSON-RPC
def reply(id, result)
  puts({ jsonrpc: "2.0", id: id, result: result }.to_json)
  $stdout.flush
end

def reply_error(id, code, message, data = nil)
  error_payload = { code: code, message: message }
  error_payload[:data] = data if data
  puts({ jsonrpc: "2.0", id: id, error: error_payload }.to_json)
  $stdout.flush
end

def format_yard(yard)
  total = yard.total_slots
  occupied = yard.occupied_slots
  free = total - occupied

  {
    id: yard.id,
    nombre: yard.name,
    tamano: "#{yard.rows}x#{yard.columns}",
    capacidad_total: total,
    ocupados: occupied,
    libres: free,
    ocupacion_pct: yard.occupancy_percentage
  }
end

def text_content(payload)
  { content: [{ type: "text", text: JSON.pretty_generate(payload) }] }
end

def normalized_string(value)
  value.to_s.strip
end

def parse_integer(value, field_name)
  Integer(value)
rescue ArgumentError, TypeError
  raise ArgumentError, "#{field_name} debe ser un entero"
end

# Bucle principal de escucha (STDIN)
$stdin.each_line do |line|
  begin
    request = JSON.parse(line)
    id = request["id"]

    case request["method"]
    when "initialize"
      reply(id, {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        serverInfo: { name: "Logistica-Local-GTX1060", version: "1.2.0" }
      })

    when "notifications/initialized"
      # Notificacion del cliente sin respuesta esperada.

    when "tools/list"
      reply(id, { tools: TOOLS })

    when "tools/call"
      name = request.dig("params", "name")
      args = request.dig("params", "arguments") || {}

      result_data = case name
      when "listar_patios"
        patios = Yard.order(:id)
        { patios: patios.map { |yard| format_yard(yard) } }

      when "resumen_patios"
        patios = Yard.order(:id)
        {
          total_patios: patios.count,
          patios: patios.map { |yard| format_yard(yard) }
        }

      when "estado_ocupacion_yard"
        yard_id = args["yard_id"]
        raise ArgumentError, "Falta argumento obligatorio: yard_id" if yard_id.nil?

        y = Yard.find(yard_id)
        total = y.total_slots
        occupied = y.occupied_slots
        {
          id: y.id,
          nombre: y.name,
          total_slots: total,
          ocupados: occupied,
          libres: total - occupied,
          ocupacion_pct: y.occupancy_percentage
        }

      when "buscar_contenedor"
        code = normalized_string(args["codigo"])
        raise ArgumentError, "Falta argumento obligatorio: codigo" if code.empty?

        c = Container.includes(slot: :yard, truck: []).find_by(code: code)
        if c
          slot = c.slot
          yard = slot&.yard

          {
            codigo: c.code,
            patio: yard&.name,
            fila: slot&.row,
            columna: slot&.column,
            camion_patente: c.truck&.plate
          }
        else
          { error: "Contenedor no encontrado" }
        end

      when "contenedores_por_camion"
        plate = normalized_string(args["patente"])
        raise ArgumentError, "Falta argumento obligatorio: patente" if plate.empty?

        t = Truck.includes(:containers).find_by(plate: plate)
        t ? { patente: t.plate, contenedores: t.containers.pluck(:code) } : { error: "Camion no encontrado" }

      when "registrar_contenedor"
        code = normalized_string(args["codigo"])
        raise ArgumentError, "Falta argumento obligatorio: codigo" if code.empty?

        yard_id = args["yard_id"]
        raise ArgumentError, "Falta argumento obligatorio: yard_id" if yard_id.nil?
        yard_id = parse_integer(yard_id, "yard_id")

        raise ArgumentError, "El contenedor ya existe" if Container.exists?(code: code)

        truck_plate = normalized_string(args["patente"])

        created = ActiveRecord::Base.transaction do
          yard = Yard.lock.find(yard_id)
          slot = yard.next_free_slot
          raise ArgumentError, "No hay espacio disponible en el patio" if slot.nil?

          truck = truck_plate.empty? ? nil : Truck.find_or_create_by!(plate: truck_plate)

          Container.create!(code: code, truck: truck, slot: slot)
        end

        {
          status: "stored",
          codigo: created.code,
          patio_id: created.slot.yard_id,
          patio_nombre: created.slot.yard.name,
          fila: created.slot.row,
          columna: created.slot.column,
          camion_patente: created.truck&.plate
        }

      when "retirar_contenedor"
        # Soporta ambos nombres de argumento: `nombre` (preferido) y `codigo`.
        code = normalized_string(args["nombre"])
        code = normalized_string(args["codigo"]) if code.empty?
        raise ArgumentError, "Falta argumento obligatorio: nombre" if code.empty?

        container = Container.includes(slot: :yard, truck: []).find_by(code: code)
        return_payload = { codigo: code }

        if container.nil?
          return_payload.merge(status: "not_found", error: "Contenedor no encontrado")
        else
          slot = container.slot
          yard = slot&.yard

          if slot.nil?
            return_payload.merge(status: "already_in_transit", detalle: "El contenedor ya estaba fuera del patio")
          else
            container.destroy!
            return_payload.merge(
              status: "retirado",
              patio_origen_id: yard&.id,
              patio_origen_nombre: yard&.name,
              fila_origen: slot.row,
              columna_origen: slot.column,
              camion_patente: container.truck&.plate
            )
          end
        end

      else
        raise ArgumentError, "Herramienta no soportada: #{name}"
      end

      reply(id, text_content(result_data))

    else
      reply_error(id, -32601, "Metodo no soportado: #{request['method']}")
    end
  rescue ActiveRecord::RecordNotFound => e
    reply_error(id, -32004, "Registro no encontrado", e.message)
  rescue ArgumentError => e
    reply_error(id, -32602, "Parametros invalidos", e.message)
  rescue => e
    # Enviar error basico si algo falla en parseo o ejecucion
    reply_error(id, -32000, "Error interno", e.message)
    $stderr.puts "Error: #{e.class} - #{e.message}"
  end
end
