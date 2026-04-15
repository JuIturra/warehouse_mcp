class RetirarContenedorTool < FastMcp::Tool
  tool_name "retirar_contenedor"
  description "Retira un contenedor del patio por su codigo y libera su slot."

  arguments do
    required(:codigo).filled(:string).description("Codigo del contenedor")
  end

  def call(codigo:)
    code      = codigo.strip
    container = Container.includes(slot: :yard, truck: []).find_by(code: code)
    raise "Contenedor '#{code}' no encontrado" unless container

    slot = container.slot
    yard = slot&.yard

    if slot.nil?
      { codigo: code, status: "already_in_transit", detalle: "El contenedor ya estaba fuera del patio" }
    else
      container.destroy!
      {
        codigo:              code,
        status:              "retirado",
        patio_origen_id:     yard&.id,
        patio_origen_nombre: yard&.name,
        fila_origen:         slot.row,
        columna_origen:      slot.column,
        camion_patente:      container.truck&.plate
      }
    end
  end
end
