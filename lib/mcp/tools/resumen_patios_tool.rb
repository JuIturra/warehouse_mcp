class ResumenPatiosTool < FastMcp::Tool
  tool_name "resumen_patios"
  description "Lista todos los patios con su capacidad total, slots ocupados, libres y porcentaje de ocupacion."

  def call
    patios = Yard.order(:id)
    { total_patios: patios.count, patios: patios.map { |y| format_yard(y) } }
  end

  private

  def format_yard(yard)
    total    = yard.total_slots
    occupied = yard.occupied_slots
    {
      id:             yard.id,
      nombre:         yard.name,
      tamano:         "#{yard.rows}x#{yard.columns}",
      capacidad_total: total,
      ocupados:        occupied,
      libres:          total - occupied,
      ocupacion_pct:   yard.occupancy_percentage
    }
  end
end
