# Screenshots

Drop the captures here with these exact filenames — the root `README.md` and
`walkthrough.md` reference them:

| File | Capture of |
|---|---|
| `inspect.png` | `flinkit inspect <job-id> --watch` — the live dashboard, ideally once the aggregation is busy / backpressured and a checkpoint has completed. Expand the config panel (`c`) for a fuller shot. |
| `doctor.png` | `flinkit doctor` — showing the `DOC-CFG-003` (RocksDB incremental disabled) finding. |
| `bottleneck.png` | `flinkit bottleneck <job-id>` — the constrained-operator verdict. |

## Tips for clean captures

- Give the terminal a dark theme and ~100×30 so the TUI isn't cramped.
- For `inspect`, let it run ~30s first so throughput, checkpoints, and the
  bottleneck have populated before you grab the frame.
- macOS: `Cmd-Shift-4` then space to capture just the terminal window.
- Keep images reasonably sized (PNG, ≲ 1600px wide) so the README loads fast.
