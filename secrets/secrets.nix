let
  # Users
  mh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOPhRxDZsJ7zFb7Zz7vrRMmIvptWCfA2HgnxYnlmhu24";

  # Systems
  rhea = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBhHDtoGETYvm8EleeFSTRTDnCQRLF9LL+tOaqDnNxzv";
in
{
  "rauthy.age".publicKeys = [ mh rhea ];
}
