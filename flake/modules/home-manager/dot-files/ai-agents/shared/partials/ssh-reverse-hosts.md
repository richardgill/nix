## SSH reverse hosts

Detect SSH context with `source ~/Scripts/lib/ssh && is_ssh_session`. Probe reverse tunnel:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=2 -p ${TUNNEL_PORT:-1999} localhost hostname
```

If it works, SSH back with `ssh -p ${TUNNEL_PORT:-1999} localhost`; one-offs: `tunnel-exec <command>`.

```bash
# remote -> originating machine
scp -P ${TUNNEL_PORT:-1999} ./file localhost:~/Downloads/
scp -P ${TUNNEL_PORT:-1999} ./screenshot.png localhost:~/Screenshots/

# originating machine -> remote
scp -P ${TUNNEL_PORT:-1999} localhost:~/Downloads/file ./
scp -P ${TUNNEL_PORT:-1999} localhost:~/Screenshots/screenshot.png ./
```
