# Screenshots

The root `README.md` and `walkthrough.md` reference these filenames:

| File | Capture of |
|---|---|
| `inspect.png` | `flinkit inspect orders-rollup --watch` — the live dashboard with failing checkpoints, climbing restarts, and the findings. |
| `doctor.png` | `flinkit doctor` — the ranked `DOC-CKPT-001` / `DOC-STAB-001` findings, with a finding's detail (target/evidence/fix/docs). |

Both are checked in. To refresh them:

## Tips for clean captures

- Give the terminal a dark theme and ~100×30 so the TUI isn't cramped.
- For `inspect`, let it run a minute so checkpoint failures and restarts
  accumulate before you grab the frame.
- macOS: `Cmd-Shift-4` then space to capture just the terminal window.
- Keep images reasonably sized (PNG, ≲ 1600px wide) so the README loads fast.
