# 9Router (optional)

Public configurations must explicitly enable Docker and 9Router and provide a
reviewed image digest:

```nix
workstation.development.docker.enable = true;
workstation.applications.router9 = {
  enable = true;
  image = "ghcr.io/decolua/9router@sha256:REPLACE_WITH_REVIEWED_64_CHARACTER_DIGEST";
};
```

The placeholder intentionally fails validation. Obtain and review a real digest
before building. Do not substitute `latest`; the public module rejects mutable
tags. No Docker group membership is added. Build, test and explicitly switch your
own host after reviewing the service.

The service manages a container named `9router`, binds `127.0.0.1:3001`, and keeps
data under `/var/lib/9router`. Enabling it starts the service at boot. The wrapper
supports `9router start|stop|restart|status|logs`. Credentials are configured
through the application's supported UI or secret mechanisms, never installer
command-line arguments. Removing the module does not delete persistent data.

The original personal host retains its legacy `latest` image for compatibility;
this is outside flake reproducibility. Pinning that personal image is a follow-up.
See [configuration](docs/configuration.md) and [recovery](docs/rollback.md).
