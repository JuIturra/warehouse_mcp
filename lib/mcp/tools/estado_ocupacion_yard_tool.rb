class EstadoOcupacionYardTool < FastMcp::Tool
  tool_name "estado_ocupacion_yard"
  description "Muestra capacidad, ocupados, libres y porcentaje en un patio especifico."

  arguments do
    required(:yard_id).filled(:integer).description("ID del patio")
  end

  def call(yard_id:)
    y        = Yard.find(yard_id)
    total    = y.total_slots
    occupied = y.occupied_slots
    {
      id:          y.id,
      nombre:      y.name,
      total_slots: total,
      ocupados:    occupied,
      libres:      total - occupied,
      ocupacion_pct: y.occupancy_percentage
    }
  end
end
