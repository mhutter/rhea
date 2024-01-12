# Configure Tailscale VPN for management access
#
# The firewall on the tailscale network link will be open by default, so no
# custom firewall rules are required
{
  modules.persistence.dirs = [ "/var/lib/tailscale" ];
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
  };
}
