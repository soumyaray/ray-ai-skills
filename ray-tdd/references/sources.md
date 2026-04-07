# TDD Skill — Reference Sources

Sources researched when creating this skill. Organized by depth of relevance.

## Claude Code TDD Implementations

These have concrete skill/hook implementations we drew from directly:

- **AI Hero's TDD Skill** — <https://www.aihero.dev/skill-test-driven-development-claude-code>
  Vertical slicing ("tracer bullets"), one-test-at-a-time constraint, forcing honest tests through constrained cycles. Most directly comparable to our skill.

- **Agentic Red-Green-Refactor Loop (alexop.dev)** — <https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/>
  Multi-agent approach using separate subagents for test-writing vs. implementation to prevent context pollution. Key insight: when the test-writer can't see implementation plans, tests are more honest.

- **tdd-guard (hooks-based enforcement)** — <https://github.com/nizos/tdd-guard>
  Real-time file monitoring that blocks TDD violations via Claude Code hooks. Supports Go, Rust, PHP, Python, JS/TS. Worth revisiting if we want automated enforcement beyond skill instructions.

- **ATDD Plugin (swingerman)** — <https://github.com/swingerman/atdd>
  Acceptance Test Driven Development with Given/When/Then specs and mutation testing. Uncle Bob-inspired. Useful reference for expanding to acceptance-level tests.

- **Claude Code TDD Guide (community)** — <https://github.com/FlorianBruniaux/claude-code-ultimate-guide/blob/main/guide/workflows/tdd-with-claude.md>
  Community-maintained workflow guide for TDD with Claude Code.

## AI-Assisted TDD Patterns and Analysis

These informed the anti-patterns and practical guidance sections:

- **Simon Willison — Red/Green TDD as Agentic Pattern** — <https://simonwillison.net/guides/agentic-engineering-patterns/red-green-tdd/>
  Argues "use red/green TDD" is a powerful four-word prompt. Confirms tests-first before implementation as sufficient instruction. Parent guide: <https://simonwillison.net/guides/agentic-engineering-patterns/>

- **Taming GenAI Agents with TDD (Nathan Fox)** — <https://www.nathanfox.net/p/taming-genai-agents-like-claude-code>
  Practical guide on embedding TDD rules into CLAUDE.md. Good example of minimal instructions that still produce discipline.

- **Why TDD Works Well with AI (Codemanship)** — <https://codemanship.wordpress.com/2026/01/09/why-does-test-driven-development-work-so-well-in-ai-assisted-programming/>
  Analysis of why small-step continuous-testing maps naturally to constraining AI. Explains the theoretical basis for why TDD is even more valuable with AI than without.

- **Claude Code and the Art of TDD (The New Stack)** — <https://thenewstack.io/claude-code-and-the-art-of-test-driven-development/>
  Experience report emphasizing human control over test execution rather than letting AI loop on itself.

- **TDD Resurgence in the LLM Age (Stride)** — <https://www.stride.build/blog/the-resurgence-of-tdd-in-the-age-of-large-language-models>
  Argues TDD is experiencing a resurgence because LLM-generated code needs pre-written tests as a safety net.

## Academic Research

For deeper investigation into LLM + TDD effectiveness:

- **Test-Driven Development for Code Generation** — <https://arxiv.org/abs/2402.13521>
  Demonstrates that including test cases leads to higher LLM success rates on programming challenges.

- **TDD-Bench Verified** — <https://arxiv.org/abs/2412.02883>
  Benchmarks whether LLMs can generate tests for issues before resolution — measuring true test-first capability.

- **LLM4TDD: Best Practices** — <https://arxiv.org/pdf/2312.04687>
  Academic analysis of best practices specifically for TDD with LLMs.

## General AI Coding Workflow

Broader context on AI-assisted development where TDD is one component:

- **Addy Osmani's LLM Coding Workflow** — <https://addyo.substack.com/p/my-llm-coding-workflow-going-into>
  Advocates small iterative chunks and quality gates including tests.

- **TDD with AI: Writing Tests Before Code (Kinde)** — <https://www.kinde.com/learn/ai-for-software-engineering/ai-devops/test-driven-development-with-ai-writing-tests-before-code-but-backwards/>
  The "backwards" pattern where AI generates tests from requirements before code exists.

- **Complete Guide for TDD with LLMs** — <https://rchavesferna.medium.com/the-complete-guide-for-tdd-with-llms-1dfea9041998>
  Covers the full TDD-with-LLM workflow including prompt engineering for test-first development.

- **Harnessing LLMs with TDD (Rotem Tam)** — <https://rotemtam.com/2024/10/18/harnessing-llms-with-tdd/>
  Experience report writing tests first then using LLMs to generate passing implementations; notes strong typing provides clearer signals for LLM iteration.
