{
  services.openssh = {
    enable = true;
    ports = [ 6272 ];

    # We don't have any other users besides root
    settings.PermitRootLogin = "prohibit-password";

    # prevent RSA host key from happening
    hostKeys = [{
      path = "/nix/persist/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };
}
