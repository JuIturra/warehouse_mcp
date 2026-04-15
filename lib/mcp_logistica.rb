# lib/mcp_logistica.rb
require_relative "../config/environment"
require "fast_mcp"

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

class RegistrarContenedorTool < FastMcp::Tool
  tool_name "registrar_contenedor"
  description "Registra un contenedor en un patio y lo asigna a un slot libre. Permite asociar patente de camion opcional."

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

server = FastMcp::Server.new(name: "Logistica-Local-GTX1060", version: "1.2.0")
server.register_tools(
  ResumenPatiosTool,
  EstadoOcupacionYardTool,
  BuscarContenedorTool,
  ContenedoresPorCamionTool,
  RegistrarContenedorTool,
  RetirarContenedorTool
)
server.start
