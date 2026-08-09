# 9. The macOS App

[◀ Previous: course_config.json Reference](08-course-config-reference.md) · [Back to index](README.md)

`mac-app/` contains a native macOS application (Swift / SwiftUI) that wraps
the command-line toolchain in a graphical interface: a collapsible sidebar of
courses and sections, a settings form mirroring the setup wizard's choices,
an embedded website preview, one-click deploys, and a New Course wizard.

Its design principle is strict: **the app performs no toolchain work
itself.** It reads and writes the same [`course_config.json`](08-course-config-reference.md)
the wizard writes, and every action shells out to the real scripts under a
pseudo-terminal — so anything the app does can be reproduced (and debugged)
at the command line, and improvements to the scripts benefit both interfaces
automatically.

| App action | Toolchain mechanism used |
|---|---|
| Save | Writes `course_config.json`; [`build_site.py`](05-build-pipeline.md) applies it on the next build |
| Cancel | Reverts the form to the last-saved file contents |
| Preview | Runs [`preview.sh`](03-launcher-scripts.md) (serve mode) and embeds `http://localhost:8081` in a web view once it responds |
| Deploy | Runs [`deploy.sh`](07-deployment.md) with output streamed into the app (prompts can be answered inline) |
| New Course | Writes the collected answers as `course_config.json`, then runs the real `./setup.sh`, accepting each prompt's default — the wizard re-reads the file as its saved answers, so scaffolding/backups/Quartz patches are all the wizard's own work |

Architecture, build instructions (XcodeGen + Xcode), the three-layer test
suite, and the CLI-equivalence testing approach are documented in
[`mac-app/README.md`](../mac-app/README.md).

---

[◀ Previous: course_config.json Reference](08-course-config-reference.md) · [Back to index](README.md)
