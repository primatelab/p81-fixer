# p81-fixer

Perimeter 81 (Harmony SASE) crashes the local DNS resolver. This stops that.

On Linux, P81 DNATs UDP/53 to a helper on `127.0.0.1:5354` with no destination filter. Client queries to systemd-resolved's stub, and resolved's own uplink queries, both get stolen. The stub and the helper then fight until name resolution falls over — often every few minutes.

p81-fixer marks stub and uplink DNS (`0x81`) so P81 cannot intercept those packets, then restores split DNS: corporate suffixes from the live P81 policy go to the `p81` link; everything else uses the Wi-Fi resolver. A NetworkManager dispatcher reapplies this when links change.

That is the point of the software.

## Totally accidental side effects

Any anti-bossware capabilities are *totally* accidental side effects of the fix.

In particular, while keeping DNS alive, P81's transparent TPROXY rules (TCP redirected into a secure web gateway that terminates and inspects it) may also disappear shortly after the helper puts them back. Nobody asked for that. It just happens to be adjacent to the DNS problem. The dude who actually wrote this was only trying to resolve hostnames. Workplace surveillance circumvention was not on the ticket, is not a feature, and we decline to discuss it further.

## Install

```bash
sudo ./install-p81-fixer.sh
```

Installs:

- `/usr/local/sbin/p81-split-dns`
- `/usr/local/sbin/p81-routes`
- `/usr/local/sbin/p81-drop-tproxy`
- `/etc/NetworkManager/dispatcher.d/60-p81-fixer`

## Usage

```bash
sudo p81-split-dns apply
sudo p81-split-dns status
sudo p81-split-dns revert

sudo p81-drop-tproxy --daemon
sudo p81-drop-tproxy stop

p81-routes                  # split-tunnel / DNS policy summary
p81-routes example.com      # is this host VPN or local?
```

Tear-out:

```bash
sudo p81-split-dns revert
sudo p81-drop-tproxy stop
sudo rm /etc/NetworkManager/dispatcher.d/60-p81-fixer \
        /usr/local/sbin/p81-split-dns \
        /usr/local/sbin/p81-drop-tproxy \
        /usr/local/sbin/p81-routes
```

## License

[HIFFL](LICENSE) — held for a friend.
