---
name: tdd
description: "Test-Driven Development discipline for writing code. Use this skill whenever writing new features, adding behavior, refactoring with tests, fixing bugs with regression tests, or when the user mentions TDD, red-green-refactor, test-first, failing tests, or asks to write tests before implementation. Also triggers when branch plans contain FAILING test tasks or test-first instructions."
---

# TDD Skill — Red-Green-Refactor

This skill enforces Test-Driven Development discipline. The core problem it solves: AI assistants naturally write implementation first and then generate tests that validate what was already written — producing tests that pass immediately and never actually drive the design. This skill inverts that default.

## The Iron Rule

**Never write implementation code without a failing test that demands it.**

A test written after the implementation is a verification test. A test written before is a design tool. TDD uses tests as design tools.

## The Cycle

Each cycle has three distinct phases with a mandatory verification step between each.

### Phase 1: RED — Write exactly one failing test

Write a single test that describes the next small increment of behavior. The test must:

- Be based on the **requirement or specification**, not on any planned implementation
- Test **behavior** ("when I call X with Y, it returns Z"), not structure
- Fail for the **right reason** — because the expected behavior doesn't exist yet, not because of a syntax error, missing import, or typo

After writing the test:

1. **Run only the new test** (or the single file that contains it) — not the whole suite. Use the project's actual test runner (not mental execution), in its quiet / failure-only mode (e.g. `-q`, `--quiet`, `--reporter=dot`) so output stays small.
2. **Confirm the new test fails**. Report just the assertion/failure line, not the full runner output.
3. **If the test passes** — STOP. Something is wrong. Either the behavior already exists (the test is redundant) or the test doesn't actually assert what you think it does. Investigate before proceeding.

### Phase 2: GREEN — Write the minimum code to pass

Write the **simplest, most minimal code** that makes the failing test pass:

- Do not anticipate future tests
- Do not add functionality beyond what the current failing test requires
- Hard-coded return values are acceptable if they make the test pass
- Do not refactor yet — just make it green

After writing the implementation:

1. **Run the affected test file** (in quiet mode). Confirm the new test now passes.
2. **Run the full suite at natural boundaries** — not every cycle. Run it whenever you finish a coherent unit of behavior, before a refactor, and **always at the end of the task**. This catches regressions in other tests without dumping full-suite output into context on every green step.
3. **Confirm the new test passes AND no existing tests broke** at each full-suite run.
4. If other tests broke, fix the implementation — don't change the tests (unless they were wrong).

### Phase 3: REFACTOR — Improve structure, keep behavior

Optional but valuable. Now that you have a green test suite as a safety net:

- Remove duplication
- Improve naming
- Extract methods, consolidate logic
- **Do not add new behavior** — the test count and pass/fail status must not change

After refactoring:

1. **Run the full test suite**.
2. **Confirm everything still passes** — same count, same results.

### Then repeat

Go back to RED with the next behavioral increment. Build complexity gradually through small, verified steps.

## Practical Guidance

### Ordering test cases

Start with the simplest, most degenerate case and build up:

1. **Null/empty/zero** — what happens with no input?
2. **Single/simple** — the simplest meaningful case
3. **Typical** — the common happy path
4. **Edge cases** — boundaries, limits, special values
5. **Error cases** — invalid input, authorization failures

This ordering lets each GREEN phase be a small, manageable step.

### One test at a time — with judgment

The default is one test per RED-GREEN cycle: it prevents over-implementation and keeps each step small. Hold this line strictly for **genuinely complex domain logic**, where each case forces a real design decision.

For **trivial or parallel cases** — the degenerate null/empty/zero cases, or several near-identical variations that exercise the same code path — it is fine to write a small batch in one RED phase and satisfy them together. Forcing a literal single-assertion cycle for logic that a hard-coded return already covers just multiplies test runs and context without improving the design.

Rule of thumb: if the next test would force you to *generalize* the implementation, do it as its own cycle. If it would pass under the code you already have (or a trivial extension), batch it.

If a plan lists multiple test scenarios (e.g., "1.1a FAILING test: ... scenarios X, Y, Z"), use this judgment to decide whether each scenario is its own cycle or part of a batch — don't implement them all blindly at once, but don't mechanically split trivial ones either.

### What "minimal implementation" really means

In early cycles, minimal might mean returning a hard-coded value. That's fine. The next test will force you to generalize. Trust the process:

**Cycle 1**: Test expects `add(1, 1)` to return `2` → Implement: `return 2`
**Cycle 2**: Test expects `add(2, 3)` to return `5` → Now you must generalize: `return a + b`

This feels silly for trivial examples, but for complex domain logic it prevents over-engineering.

### When tests depend on infrastructure

Sometimes you need infrastructure (database, repository, ORM model) before a test can even run. Set up the minimum infrastructure needed to make the test *runnable* (e.g., require the file, create the class skeleton), then let it fail on the behavioral assertion. The infrastructure setup is not the implementation — the behavior is.

### Keeping the session lean

TDD runs many cycles, and test-runner output accumulates in context — long, high-context sessions are the main cost driver. Keep runs cheap and the context small:

- Prefer scoped, quiet runs in the inner loop (see RED/GREEN above); reserve full-suite runs for boundaries and the task end.
- Once a unit of behavior is finished and its full suite is green, the test output from those completed cycles is no longer needed. If context is growing large mid-feature, `/compact` at that boundary before starting the next unit.
- `/clear` when switching to an unrelated task rather than carrying prior cycles forward.

### Refactoring test code

Test code deserves the same care as production code. During REFACTOR, you can extract test helpers, reduce duplication in setup, and improve test readability. Just make sure all tests still pass afterward.

## Anti-Patterns to Avoid

- **Writing tests that assert implementation details** (private methods, internal state) rather than observable behavior
- **Writing all tests first, then all implementation** — this is not TDD, it's "tests-first waterfall"
- **Skipping the test run** — "I can see it will fail" is not the same as confirming it fails
- **Making the test pass by weakening the assertion** — if the test is wrong, delete it and write a better one
- **Adding "one more thing" during GREEN** — if you think of another behavior, write it down for the next RED phase, don't sneak it in now

## References

See `references/sources.md` for the sources researched when creating this skill — Claude Code TDD implementations, AI-assisted TDD analysis, and academic research. Consult these when revisiting design decisions or expanding the skill.

## Integration with Branch Plans

When a branch plan contains tasks labeled "FAILING test" or "test-first":

- Those tasks correspond to the RED phase — the deliverable is a test that **fails**
- The subsequent implementation task is the GREEN phase
- Run tests after each phase and update the plan with results
- Mark the FAILING test task complete only after confirming the test fails for the right reason
- Mark the implementation task complete only after confirming all tests pass
