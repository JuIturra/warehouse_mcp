class BuscarContenedorTool < FastMcp::Tool
  tool_name "buscar_contenedor"
  description "Encuentra la ubicacion fisica (Patio, Fila, Columna) de un contenedor por su codigo."

  arguments do
    required(:codigo).filled(:string).description("Codigo del contenedor")
  end

  def call(codigo:)
    code = codigo.strip
    c    = Container.includes(slot: :yard, truck: []).find_by(code: code)
    raise "Contenedor '#{code}' no encontrado" unless c

    slot = c.slot
    yard = slot&.yard
    {
      codigo:        c.code,
      patio:         yard&.name,
      fila:          slot&.row,
      columna:       slot&.column,
      camion_patente: c.truck&.plate
    }
  end
end
