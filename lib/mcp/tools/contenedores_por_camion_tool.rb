class ContenedoresPorCamionTool < FastMcp::Tool
  tool_name "contenedores_por_camion"
  description "Lista todos los codigos de contenedores asociados a la patente de un camion."

  arguments do
    required(:patente).filled(:string).description("Patente del camion")
  end

  def call(patente:)
    plate = patente.strip
    t     = Truck.includes(:containers).find_by(plate: plate)
    raise "Camion con patente '#{plate}' no encontrado" unless t

    { patente: t.plate, contenedores: t.containers.pluck(:code) }
  end
end
