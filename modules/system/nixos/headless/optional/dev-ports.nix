{config, ...}: {
  # Bind dev servers to 0.0.0.0 so they're accessible from other machines (Vite, Next.js, etc.)
  environment.sessionVariables = {
    HOST = "0.0.0.0";
    # Vite built-in env var for additional allowed hosts (comma-separated)
    __VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS = config.networking.hostName;
  };

  networking.firewall = {
    allowedTCPPorts = [
      1234 # Parcel bundler
      4200 # Angular CLI
      4321 # Astro
      5432 # PostgreSQL
      6379 # Redis
      8888 # Jupyter notebooks
      9000 # PHP-FPM, various services
      27017 # MongoDB
      5173 # Vite dev server
    ];

    allowedTCPPortRanges = [
      {
        from = 3000;
        to = 3010;
      } # Next.js, Create React App, Express, Node.js apps
      {
        from = 4000;
        to = 4010;
      } # GraphQL servers, Apollo, misc Node services
      {
        from = 5000;
        to = 5200;
      } # Flask, Vite alt ports, general Python web frameworks
      {
        from = 8000;
        to = 8090;
      } # Django, Spring Boot, backend APIs, general HTTP servers
      {
        from = 9200;
        to = 9300;
      } # Elasticsearch
    ];
  };
}
