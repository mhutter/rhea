# Installation instructions

## CoreOS Installation

```sh
# (optional) Nuke disks first
ls -1 /dev/md* | while read -r md; do mdadm --stop "$md"; done
wipefs -a /dev/nvme0n1
wipefs -a /dev/nvme1n1

# Install podman
apt-get update
apt-get install -y podman
update-alternatives --set iptables /usr/sbin/iptables-legacy

# Install CoreOS
podman run --privileged --rm -v /dev:/dev -v /run/udev:/run/udev -v .:/data -w /data quay.io/coreos/coreos-installer:release install /dev/nvme0n1 -i config.ign
sync
```

Then reboot.

To bootstrap K3s:

```sh
kubectl create namespace argocd
kubectl -n argocd apply -k ./apps/argocd
kubectl -n argocd apply -f ./clusters/mhnet/00root.yaml
```
