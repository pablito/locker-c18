---
name: pre-mortem
description: >-
  Run a pre-mortem on a plan, idea, or PRD: stress-test a design by assuming it
  failed, then relentlessly interrogate every branch of the decision tree to
  find out why — and fix it before you start. Two modes: (1) idea/plan
  exploration — no document yet, use pre-mortem to surface implications and
  shape a design; (2) PRD stress-test — an existing PRD or design doc, use
  pre-mortem to expose contradictions, missing assumptions, and functional
  ramifications. Use when the user wants to stress-test a plan, asks you to
  "ask me", says "interrogami" or "fammi domande", mentions "pre-mortem",
  "design of design", or wants rigorous design discovery before implementation.
---

# Pre-mortem

**Skill workflow** — pre-mortem can be used standalone or as a gate between steps:
[`create-prd`](#) *(gather requirements)* → **`pre-mortem`** *(stress-test before building)* → [`plan-from-prd`](#) *(phase it out)*

## Two modes

**Mode 1 — Idea exploration**: The user has an idea, not yet a document. Interview them relentlessly to surface assumptions, constraints, and design implications. Help them reach a first draft design.

**Mode 2 — PRD stress-test**: The user has an existing PRD, plan, or design doc. Read it first, then interrogate every assumption, surface contradictions, and explore functional ramifications they may not have considered.

In both modes: walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

If a question can be answered by exploring the codebase, explore the codebase instead. Always use subagents to explore the codebase or for research.

## Complexity challenge

When the scope of what emerges feels large — many moving parts, cross-cutting concerns, or a broad user-facing surface area — challenge the user to identify a first sufficient MVP wave before exploring all edge cases. Ask: *"What is the smallest version of this that delivers real value?"* Encourage decomposing the work into successive waves rather than attempting a complete solution upfront.

## Output

Always produce a written summary of findings and offer two options:

- A **separate findings/risk document** (recommended for PRD stress-tests): saved as `{feature}-premortem.md`
- An **annotated version** of the existing document (recommended for living designs): highlights risks inline

Never apply changes to the codebase directly from this skill. Return control to the user once the output is saved.
