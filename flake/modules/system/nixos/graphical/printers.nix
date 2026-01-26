{ pkgs, ... }:
{
  # Enable CUPS printing services
  # CUPS (Common Unix Printing System) handles all printer communication
  services.printing = {
    enable = true;

    # Required drivers for most modern printers
    # cups-filters: provides filters for converting documents to printer-ready formats
    # cups-browsed: enables automatic printer discovery on the network
    drivers = with pkgs; [
      cups-filters
      cups-browsed
    ];

    # Uncomment to enable debug logging for troubleshooting
    # View logs with: journalctl --follow --unit=cups
    # logLevel = "debug";

    # Uncomment if you encounter SSL/TLS certificate issues
    # This disables encryption for printer communication
    # extraConf = "DefaultEncryption Never";
  };
}
