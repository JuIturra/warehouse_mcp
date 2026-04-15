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

if (auth_token = ENV["MCP_AUTH_TOKEN"])
  # ── Modo HTTP con autenticacion ──────────────────────────────────────────────
  # Requiere: MCP_AUTH_TOKEN=<token>
  # Opcional: MCP_PORT=<puerto>  (default: 3001)
  #
  # Cada request debe incluir el header:
  #   Authorization: Bearer <token>
  #
  # El AuthenticatedRackTransport rechaza con HTTP 401 cualquier request
  # que no lleve el token correcto, antes de que llegue a un tool.
  require "rack"
  require "rack/handler/webrick"

  port = ENV.fetch("MCP_PORT", "3001").to_i
  app  = server.start_rack(
    ->(_env) { [404, {}, ["Not Found"]] },
    transport: FastMcp::Transports::AuthenticatedRackTransport,
    auth_token: auth_token
  )

  $stderr.puts "[MCP] Modo HTTP en puerto #{port} con autenticacion activada"
  Rack::Handler::WEBrick.run(app, Port: port, Logger: WEBrick::Log.new($stderr), AccessLog: [])
else
  # ── Modo stdio (Claude Desktop, uso local) ───────────────────────────────────
  # Sin token de entorno → transporte stdio, sin capa de red.
  server.start
end
