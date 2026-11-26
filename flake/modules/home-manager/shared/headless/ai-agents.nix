{
  config,
  lib,
  ...
}:
let
  catalog = (builtins.fromJSON (builtins.readFile ./mcp.json)).mcpServers;
in
{
  options.custom.aiAgents.pi.mcp = {
    servers = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (builtins.attrNames catalog));
      default = [ ];
      description = "Names of Pi MCP servers to configure on this machine.";
    };

    rendered = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      internal = true;
      description = "The Pi MCP configuration as JSON.";
    };
  };

  config = {
    custom.aiAgents.pi.mcp.rendered = builtins.toJSON {
      mcpServers = lib.getAttrs config.custom.aiAgents.pi.mcp.servers catalog;
    };

    home.file.".pi/agent/mcp.json".text = config.custom.aiAgents.pi.mcp.rendered;
  };
}
