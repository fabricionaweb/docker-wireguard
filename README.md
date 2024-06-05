Just another wireguard image. But compiled from the source.

---

**Environments**

- `WG_FILE` name of config file at /config folder. Defaults to wg0.conf

**Needed docker arguments**

- `--cap-add=NET_ADMIN`
- `--sysctl="net.ipv4.conf.all.src_valid_mark=1"`
- `--sysctl="net.ipv6.conf.all.disable_ipv6=1"`
