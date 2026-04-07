---
name: test-demos
description: Analyze branch changes for test gaps, then generate a demo-based manual test plan that Claude Code can execute
---

# Demo-Based Manual Test Plan Skill

Generate a `PLAN.demo-manual-tests.md` file for the current branch. The plan exercises changed code through the project's demo scripts, filling coverage gaps that the unit-test suite may not reach (e.g., integration flows, visual output, print/summary formatting, multi-step pipelines).

> **Note**: The examples below use an R package layout (`R/`, `tests/testthat/`, `demo/*.R`). The methodology — pairing demos with regression tests to cover gaps the unit suite misses — applies to any language. Adapt the paths, file globs, and tooling to fit your project's layout.

## Usage

```text
/test-demos
```

## Instructions for Claude

### Step 1: Identify changed R source files

Determine the base branch (same logic as `/branch-review`: check for `develop`, fall back to `main`/`master`).

```bash
git diff <base>...HEAD --name-only -- 'R/*.R'
```

Collect the list of changed `R/*.R` files. If no R source files changed, report that and stop.

### Step 2: Catalog testthat coverage of changed files

For each changed file, search for test files that exercise its functions:

1. **Direct references**: `Grep` for the changed file's exported/internal function names across `tests/testthat/test-*.R` and `tests/testthat/test-*.r`.
2. **Fixture usage**: Check if any test fixtures in `tests/testthat/fixtures/` exercise the changed code paths.

Build a coverage map: `{ changed_file → [test_files_that_reference_it] }`.

Flag functions or code paths in changed files that have **no testthat coverage** — these are the "test gaps."

### Step 3: Map test gaps to demo scripts

For each test gap, determine which `demo/*.R` scripts exercise the uncovered code:

1. Read each demo script in `demo/`.
2. Check whether the demo's workflow would invoke the changed function — either directly or through the estimation/evaluation/plotting pipeline.
3. Note which specific refactored code each demo exercises (function names, predicates, accessors).

If a test gap cannot be covered by any demo, note it in the output as "not demo-coverable" so the developer knows manual testing may still be needed.

### Step 4: Design verification checks for each demo section

For each selected demo, design R code checks that verify the changed code works correctly. Follow these patterns:

**Structural checks** (automated PASS/FAIL):
- Object exists and has expected class
- Expected fields/columns present in output
- Numeric values are in valid ranges (e.g., CIs contain point estimates, VIFs < threshold)
- String patterns match expected format (e.g., path labels use `" -> "` separator)
- Key functions complete without error (`tryCatch` wrappers)

**Visual checks** (developer review required):
- Save plots to `test_plots/` using `save_plot()` wrapped in `tryCatch` (some environments lack `DiagrammeRsvg`/`rsvg`)
- Describe what the developer should look for in each saved plot
- Group visual checks at the end of each section

**Check conventions**:
- Print `"PASS: <description>"` for passing checks
- Print `"FAIL: <description>"` for failing checks
- Print `"WARN: <description>"` for non-fatal issues (e.g., missing optional packages)
- Print intermediate values (coefficients, labels, matrices) so the developer can visually inspect them even when automated checks pass

### Step 5: Handle demo quirks

Some demos overwrite variables as they run multiple configurations sequentially. When this happens:

- Note which configuration's objects remain after the demo completes
- Design checks against the final state, not intermediate states
- Mention the full sequence in the section description so the developer knows what ran

Read each selected demo script to understand its variable names, what objects it creates, and whether it overwrites them.

### Step 6: Write the output file

Create `PLAN.demo-manual-tests.md` in the project root with this structure:

```markdown
# Manual Demo Tests for [Branch Name]

> Automated test plan for Claude Code to execute. Each section sources a demo file, then runs verification checks. Plots are saved for developer review.

## Instructions for Claude Code

1. Create `test_plots/` directory for plot output
2. For each section: run the R script via `Rscript` from the package root
3. Check output for any `FAIL:` lines — report these immediately
4. Where indicated, ask the developer to review saved plot files before continuing
5. After all sections pass, delete `test_plots/`

---

## N. Section Title (`demo-name`)

**Refactored code exercised:** `file.R` (`function_name()`, `predicate()`), `other_file.R` (`other_function()`)

[Optional: note about demo behavior, e.g., "The demo runs N configurations sequentially..."]

**Run this R script:**

~~~r
devtools::load_all()
dir.create("test_plots", showWarnings = FALSE)
source("demo/demo-name.R")
cat("PASS: demo completed without error\n")

# Check: [description]
[verification code]

# Save plots (if applicable)
tryCatch({
  plot(model_obj); save_plot("test_plots/Na_description.png")
  cat("PASS: plots saved to test_plots/Na\n")
}, error = function(e) cat("WARN: plot save failed:", e$message, "\n"))
~~~

**Ask developer to verify plots before continuing:** (only if plots were saved)

- `test_plots/Na_description.png` — [what to look for]

---

## Cleanup

After all sections pass:

~~~r
unlink("test_plots", recursive = TRUE)
~~~
```

### Step 7: Report to the user

After writing the file, summarize:

1. How many changed files were analyzed
2. How many test gaps were identified
3. How many demo sections were generated
4. Any test gaps that are **not demo-coverable** (if any)

## Design Principles

- **Targeted, not exhaustive**: Only include demos that exercise changed code. Don't test unchanged functionality.
- **Automated where possible**: Prefer programmatic PASS/FAIL checks. Reserve developer review for visual artifacts only.
- **Self-contained sections**: Each section starts with `devtools::load_all()` so it can be run independently.
- **Graceful degradation**: Wrap plot saves in `tryCatch` since rendering packages may not be installed. Use `WARN` not `FAIL` for optional capabilities.
- **Explicit about what changed**: Every section's "Refactored code exercised" line traces back to the specific functions/predicates that were modified, so the developer knows *why* that demo is included.

## Common Pitfalls

Before writing verification code that accesses summary or model fields, **probe the actual object structure** using `str()` or `class()` on a live R session (or read the relevant `summary.*` / `print.*` S3 methods). Common mistakes to avoid:

- **List fields masquerading as matrices**: Many summary fields (e.g., `$loadings`, `$vif_antecedents`, `$quality$antecedent_vifs`) are nested lists (often class `list_output`), not numeric matrices. You cannot call `round()` directly on them — use `lapply(x, round, 3)` instead.
- **Fit index location**: CFA/CBSEM fit indices like `chisq`, `rmsea`, `cfi`, `tli`, `srmr` live in `$quality$fit$all` (a named numeric vector keyed by name), **not** in `$quality$fit$curated$ordinary` (which contains only a curated subset without those names). Use `names(fit)` not `rownames(fit)` to check for presence.
- **Plot backend differences**: PLS models use DiagrammeR and support `save_plot()`. CFA/CBSEM models use `semPlot` — `save_plot()` is not compatible and will error. Don't wrap CFA/CBSEM plot saves expecting them to work; instead note that the demo's own `plot()` calls already render via semPlot.

## Important

- This skill produces a plan file — it does NOT execute the demos itself.
- The output file is meant to be run by Claude Code in a subsequent session (or by the developer manually).
- Do not modify any R source files. This skill is analysis-only.
- Read the actual demo scripts before writing checks — don't assume what variables or objects they create.
