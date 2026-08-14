# SPH4U — curriculum built, course not yet authored

The `shared/Curriculum/` folder here is finished: all 17 overall and 71
specific expectations for Physics, Grade 12, University Preparation,
captured verbatim from the Ministry's 2008 science document, plus the
index and the citation page.

The rest of the course — concepts, investigations, tasks, class pages — is
not written yet, so **this is deliberately not a usable payload**:
`manifest.json` is parked as `manifest.json.pending` so the wizard and the
app do not offer it. A course code with no manifest falls back to the
physics skeleton, which is the honest behaviour until the content exists.

To finish it: author the content the way SPH3U is written, rename the
manifest back, and run `lint_payload.py SPH4U`.

The planned arc, from the research already done:

- **Unit 1 — Dynamics.** The flying pig conical pendulum is the hero
  investigation (B2.6, B3.2, B3.3): measure the radius, the angle from the
  vertical, and the time for ten revolutions; predict the speed from
  $v = \sqrt{gr\tan\theta}$ and measure it as $2\pi r / t$; compare. Paul
  Robinson's version of this lab (laserpablo.com) is the reference
  procedure.
- **Unit 2 — Energy and Momentum.** Collisions, and a callback to the
  Grade 11 [[Model Roller Coaster]]: the loop analysed properly, now that
  circular motion and rotational energy are available.
- **Unit 3 — Gravitational, Electric, and Magnetic Fields.**
- **Unit 4 — The Wave Nature of Light.**
- **Unit 5 — Revolutions in Modern Physics**, ending in the culminating
  task.
