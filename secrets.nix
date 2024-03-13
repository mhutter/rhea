let
  # Users
  mh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOPhRxDZsJ7zFb7Zz7vrRMmIvptWCfA2HgnxYnlmhu24";

  # Systems
  rhea = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBhHDtoGETYvm8EleeFSTRTDnCQRLF9LL+tOaqDnNxzv";

  toSecret = file: {
    name = "secrets/${file}";
    value = { publicKeys = [ mh rhea ]; };
  };

in
builtins.listToAttrs (builtins.map toSecret [
  "docspell-env.age"
  "grafana-env.age"
  "miniflux-env.age"
  "postgresql-init.age"
  "rauthy.age"
  "restic-env.age"
  "restic-password.age"
  "restic-repository.age"
  "vaultwarden.age"
  "wg-psk-tera.age"
])
