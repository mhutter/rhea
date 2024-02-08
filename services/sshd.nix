{ config, ... }:

let
  etc = "${config.modules.persistence.root}/etc/ssh";

in
{
  services.openssh = {
    enable = true;
    ports = [ 6272 ];

    # We connect via Tailscale, which is whitelisted
    openFirewall = false;

    # We don't have any other users besides root
    settings.PermitRootLogin = "prohibit-password";

    # prevent RSA host key from happening
    hostKeys = [{
      path = "${etc}/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  # Ensure host keys are properly secured
  systemd.tmpfiles.settings."10-persistence"."${etc}".d = {
    user = "root";
    group = "root";
    mode = "0700";
  };
}
