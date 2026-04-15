# lib/mcp_logistica.rb
require_relative "../config/environment"
require "fast_mcp"

# Tools
Dir[File.join(__dir__, "mcp/tools/**/*.rb")].each { |f| require f }

# Resources
Dir[File.join(__dir__, "mcp/resources/**/*.rb")].each { |f| require f }

server = FastMcp::Server.new(name: "Logistica-Local-GTX1060", version: "1.2.0")
server.register_tools(
  ResumenPatiosTool,
  EstadoOcupacionYardTool,
  BuscarContenedorTool,
  ContenedoresPorCamionTool,
  RegistrarContenedorTool,
  RetirarContenedorTool
)
server.register_resources(ReglasPatioResource)
server.start
