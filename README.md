# Warehouse MCP

Sistema de gestión de patios de contenedores con integración MCP para Claude.

El proyecto tiene dos partes:

1. **Warehouse** — aplicación Rails con interfaz web para gestionar patios, contenedores y camiones.
2. **MCP Server** — servidor que expone las operaciones del warehouse como herramientas para Claude.

---

## Arquitectura

```
┌─────────────────────────────────────────────┐
│               Warehouse (Rails)              │
│                                             │
│  Patios → Slots → Contenedores → Camiones   │
│  Web UI  +  PostgreSQL                      │
└────────────────────┬────────────────────────┘
                     │ ActiveRecord
┌────────────────────▼────────────────────────┐
│              MCP Server (Ruby)               │
│                                             │
│  Tools: buscar, registrar, retirar           │
│  Resources: reglas de patio                 │
│                                             │
│  Transporte: stdio (Claude Desktop)          │
│           o  HTTP  (remoto con token)        │
└─────────────────────────────────────────────┘
```

Un **Patio** tiene una grilla de filas × columnas. Cada celda es un **Slot**. Los **Contenedores** se asignan a slots cuando llega un **Camión**.

---

## Instalación

**Requisitos:** Ruby 3.4.5, PostgreSQL, Bundler

```bash
bundle install
bin/rails db:prepare
```

Configuración de base de datos en `config/database.yml`:
- Usuario: `root` / Contraseña: `password` (desarrollo)

---

## Parte 1 — Warehouse (Web)

```bash
bin/rails server
```

Abre `http://localhost:3000`. Desde ahí podés:

- Crear patios con dimensiones personalizadas
- Registrar llegadas de camiones con múltiples contenedores
- Ver el mapa visual de ocupación de cada patio
- Buscar y gestionar contenedores individualmente

---

## Parte 2 — MCP Server

El servidor expone el warehouse como herramientas que Claude puede usar directamente.

### Modo stdio (Claude Desktop)

```bash
bundle exec ruby lib/mcp_logistica.rb
```

Configurar en Claude Desktop (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "warehouse": {
      "command": "bundle",
      "args": ["exec", "ruby", "lib/mcp_logistica.rb"],
      "cwd": "/ruta/al/proyecto"
    }
  }
}
```

### Modo HTTP (acceso remoto)

```bash
MCP_AUTH_TOKEN="tu-token" bundle exec ruby lib/mcp_logistica.rb
```

El servidor corre en `http://localhost:3001`. Todas las requests requieren:

```
Authorization: Bearer tu-token
```

Para habilitar operaciones de escritura con un token separado:

```bash
MCP_AUTH_TOKEN="token-lectura" MCP_ADMIN_TOKEN="token-escritura" bundle exec ruby lib/mcp_logistica.rb
```

---

## Herramientas MCP disponibles

| Herramienta | Descripción |
|---|---|
| `resumen_patios` | Lista todos los patios con ocupación y espacio libre |
| `estado_ocupacion_yard` | Detalle de un patio específico |
| `buscar_contenedor` | Localiza un contenedor (patio + slot o camión) |
| `contenedores_por_camion` | Lista contenedores de una patente de camión |
| `registrar_contenedor` | Almacena un contenedor en el próximo slot libre |
| `retirar_contenedor` | Retira un contenedor y libera su slot |

Las herramientas de escritura (`registrar`, `retirar`) requieren el header `X-Admin-Token` si `MCP_ADMIN_TOKEN` está configurado.

---

## Variables de entorno

| Variable | Descripción | Default |
|---|---|---|
| `MCP_AUTH_TOKEN` | Activa modo HTTP y define el token de acceso | — |
| `MCP_ADMIN_TOKEN` | Token para operaciones de escritura | — |
| `MCP_PORT` | Puerto del servidor HTTP | `3001` |
