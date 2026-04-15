class RegistrarContenedorTool < FastMcp::Tool
  tool_name "registrar_contenedor"
  description "Registra un contenedor en un patio y lo asigna a un slot libre. Permite asociar patente de camion opcional."

  # ── Autorizacion por tool ────────────────────────────────────────────────────
  # Si MCP_ADMIN_TOKEN esta definido, exige el header X-Admin-Token en el request.
  # Esto permite tener un token de solo lectura (MCP_AUTH_TOKEN) y uno de escritura
  # (MCP_ADMIN_TOKEN) de forma independiente.
  # En modo stdio (sin MCP_ADMIN_TOKEN) el bloque siempre permite la ejecucion.
  authorize do
    admin_token = ENV["MCP_ADMIN_TOKEN"]
    next true if admin_token.nil? || admin_token.empty?

    headers["X-Admin-Token"] == admin_token
  end

  arguments do
    required(:codigo).filled(:string).description("Codigo del contenedor")
    required(:yard_id).filled(:integer).description("ID del patio donde almacenar")
    optional(:patente).filled(:string).description("Patente del camion (opcional)")
  end

  def call(codigo:, yard_id:, patente: nil)
    code = codigo.strip
    raise "El contenedor ya existe" if Container.exists?(code: code)

    truck_plate = patente.to_s.strip

    created = ActiveRecord::Base.transaction do
      yard = Yard.lock.find(yard_id)
      slot = yard.next_free_slot
      raise "No hay espacio disponible en el patio" if slot.nil?

      truck = truck_plate.empty? ? nil : Truck.find_or_create_by!(plate: truck_plate)
      Container.create!(code: code, truck: truck, slot: slot)
    end

    {
      status:         "stored",
      codigo:         created.code,
      patio_id:       created.slot.yard_id,
      patio_nombre:   created.slot.yard.name,
      fila:           created.slot.row,
      columna:        created.slot.column,
      camion_patente: created.truck&.plate
    }
  end
end
