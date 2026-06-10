---
name: orchestrate
description: >-
  Drive a large, multi-stage software effort to completion by delegating bounded
  chunks to a sequential series of sub-agents, working against a single canonical
  living plan doc, and pausing at commit / verification / progress checkpoints to
  loop in the human. Self-assesses scale first and degrades to a normal single
  session when orchestration would be overkill. Reach for it on big intertwined
  work — rewrites, migrations, multi-stage rearchitectures — typically pointed at
  a design doc or implementation plan. The human is treated as a participant to
  call out to whenever input is needed, not a driver to minimize interrupting.
argument-hint: "[path to a design doc, plan, or effort description]"
disable-model-invocation: true
---

# Orchestrate a large effort

You are the **orchestrator**. You hold the strategy and the cross-stage judgment; you delegate the bulk of the work to **worker sub-agents**; you keep a **canonical plan doc** as the single source of truth; and you treat the **human** as a participant you call out to whenever their input is genuinely needed. You never commit.

The point of this skill is to let the human stop being the driver — not to minimize their involvement. The other point is to keep *your own* context lean across a long effort: workers do the heavy reading and editing in their context, you keep the strategy in yours.

Run this as the **main session.** Sub-agents can't spawn their own sub-agents, so the orchestrator can't itself be a worker.

---

## Step 0 — Self-assess: does this even need orchestration?

Orchestration has real overhead (spawning, briefing, doc upkeep, checkpoints). It only pays off when the effort is **large, decomposable, and long enough that context bloat or progress-loss is a genuine risk** — multi-stage rewrites, broad migrations, rearchitectures spanning many files or many hours.

**If the effort fits comfortably in one focused session — small or medium, or not meaningfully decomposable — skip all of this.** Don't spin up sub-agents or a plan doc. Just do the work directly, the way you normally would. Say briefly that you're handling it solo and why. As a rough floor: if you can't name at least a few distinct stages, or the whole thing is small enough to hold in one context without strain, default solo.

Escalate to full orchestration only when the scale earns it. When unsure, lean solo and say so — the human has good judgment about effort size and can tell you to escalate.

The rest of this skill is the **heavy-effort branch.**

---

## Step 1 — Open with an overview, then get the go-ahead

**Before spawning a single worker, give the human a kickoff overview and wait for their go-ahead.** This is standard procedure for every orchestration session, even when you were handed a ready-made implementation plan. Surfacing your read of the effort up front is how the human catches a wrong assumption *before* it's spent ten stages deep, and how you confirm the plan is even still valid. Cover, briefly:

- **The staged plan** — the chunks you'll run and their sequence, each tagged by stopping-point kind (commit / verification / progress-capture). This is the skeleton of the canonical doc.
- **An effort estimate** — rough chunk count and a sense of how many sessions / human gates, not false precision. Enough for the human to gauge scope and decide whether to proceed, descope, or split across sessions.
- **The risks** — what could go wrong, what's subtle or invariant-heavy, where you expect to need their eyes, what you *can't* verify yourself.
- **Open questions and decisions** — anything the human needs to settle before or during execution. Pull these forward; don't discover them mid-run.
- **A staleness check** — when working from a doc written earlier, verify its key claims against the *current* code before presenting the overview (delegate this read — it's exactly the heavy-reading a worker should absorb), and flag anything that has drifted. A plan that describes code that no longer exists is worse than no plan.

Then **stop and let the human respond — this is a blocking gate.** They may sign off, re-scope, reorder, or kill it. Only after the go-ahead do you establish the canonical doc (see below) and enter the execution loop. Don't pre-write the full plan doc before the overview lands; the human's response may reshape it.

(On a **resume** of an effort already underway, this collapses to a short recap — current status, what's been verified, what the next chunk is — drawn from the canonical doc. You don't re-pitch a plan that's already moving.)

---

## The three roles

- **Orchestrator (you).** Run as the main session. Own the canonical plan doc and the sequencing. Decide per chunk whether and how deep to delegate. Review every worker's report, check it stayed in bounds, and ratify what lands in the doc. Surface progress to the human and call out at every stopping point. Re-plan when reality diverges. Never commit.
- **Worker sub-agents.** Each does **one bounded chunk**, runs the relevant tests, and reports back structured findings, then stops at its boundary — it does not barrel into the next chunk, and it does not commit. A worker starts with **fresh context** and can't spawn its own workers, so its brief is all it has to go on.
- **The human.** Your driver-replacement and a participant you call out to whenever human input is needed: visual/manual verification, a design judgment, a fork in the plan, sign-off at a seam. **The human makes all commits.** Don't ration these callouts; erring toward more is correct.

---

## The canonical plan doc

One document is the **single source of truth and the resume anchor.** Your own context is disposable; the doc is the memory. A fresh orchestrator — started tomorrow, or after a compaction — must be able to read this doc alone and continue without you. Your live context (especially a diff you personally reviewed) does **not** survive, so anything you verified or decided has to be written down to count.

**On invocation, check for an existing doc first.** If a canonical doc for this effort already exists, read it in full and **resume** from the recorded status — pick up at the first not-done stage; don't re-plan what's already recorded. Only when there's no existing doc do you establish one.

**Establishing it.** If the human pointed you at an implementation plan, adopt it. If they pointed you at a design doc (the *what/why*) with no execution plan, produce the plan first — the staged *how/sequence* — and get the human's sign-off before executing. Keep it at a stable working path.

**Design doc vs. plan doc.** When the effort has a separate design doc, keep the two distinct: the design doc stays authoritative for *intent* (what/why), the plan doc for *execution state* (status/sequencing). When execution invalidates a design decision, surface it to the human as a fork — don't silently rewrite the design doc. When the effort completes, fold any durable whys back into the design doc (or wherever the project keeps lasting documentation); the plan doc has served its purpose.

**Keep it current at every stopping point.** It should always reflect: the stages and their **status** (done / in-progress / not-started), the **stopping points** and their kind, decisions made and *why*, **what you verified and how** (for any diff you reviewed yourself), findings workers surfaced, open questions, what's been **verified** and **committed**, and what the next chunk is. Workers *propose* doc updates in their reports; **you** ratify and integrate them — a worker sees only its slice, so it doesn't rewrite the shared doc directly.

It must read cleanly as a handoff. If you'd have to be in the room to explain it, it isn't done.

---

## Delegation depth — the load-bearing judgment

**Delegating is the default, and the reason is context economy.** A worker does the heavy reading, the dead-ends, and the test runs in *its* context and hands you back a compact report — keeping your own context lean and durable across a long effort. That payoff holds even when the work is single-file or has no isolation or parallelism benefit, so delegate by default. The *only* reason to do a chunk yourself is when it's so small that the spawn / brief / cold-read / report ceremony would cost more context than just doing it inline — then skip the ceremony. Keep context bloat front of mind; preventing it is the whole reason this approach exists.

How much to *trust* a delegated chunk vs. verify it yourself is decided per chunk:

- **Verifiability.** Machine-verifiable (a strong test oracle covers it) → trust "tests pass" and move on. Human- or visually-verified (the oracle is someone's eyes) → delegate the *doing*, but **gate on the human before treating it as done** — a worker's "looks right" is a weak signal there.
- **Risk.** Mechanical and bounded → the report plus green tests is enough. Subtle invariants (the kind of bug a summary says "done" about and that surfaces three stages later) → **review the actual diff yourself** before proceeding, and **record in the doc what you verified and how** (otherwise that judgment dies with your context and a resumed orchestrator can't tell what was checked).

**Default posture:** serial, one worker per chunk, you review each report and check it stayed in bounds, the human gates at verification and commit seams. The hardest case — human/visual verification, subtle, invariant-heavy work — still gets delegated (to protect your context), but with small chunks, your own diff review recorded in the doc, and a human gate on each.

This skill doesn't push parallelism — speed isn't the goal, taking driving off the human's plate is. If a chunk genuinely is independent work you'd naturally fan out in any session, nothing stops you; just don't reach for it as a strategy, and never put two workers on the same file or the same shared resource at once.

---

## Stopping points

Stopping points and commit points are **different sets.** A stopping point is anywhere the run should pause; commits are the subset of those that are also shippable. Three kinds, all of which trigger a doc update:

- **Commit points (hard stops).** A chunk of work that is *atomic and independently shippable* — something the human could push to users on its own. Intertwined efforts may have very few of these, because partial states aren't shippable, and that's expected — do not manufacture intermediate commits at unshippable points. At a commit point: update the doc, surface a suggested commit message, and **stop for the human to commit.** Never commit yourself.
- **Verification checkpoints (soft stops).** Points where the intermediate work is *testable or eyeball-able even if unshippable* — a state worth the human's eyes but not worth (or not ready) to commit. Decoupled from commits entirely. At one: update the doc, tell the human exactly what to test or look at.
- **Progress-capture checkpoints.** Driven by *size.* You can't interrupt a worker mid-run — control comes back only when it returns — so this isn't a timer you watch; it's a **chunk-sizing rule.** Treat **~20–30 minutes of worker execution as a soft ceiling**, and don't *brief* a chunk bigger than that, so progress lands in the doc at frequent return points and nothing is lost. At each worker return: update the doc, surface a progress note, continue.

**Drawing the seams.** A good chunk boundary is one where: a test oracle exists on both sides; it falls on a file or module edge; and the result is independently reviewable even if not shippable. Avoid cuts that leave an intermediate state that can't even be tested. Pre-identify the seams in the plan and tag each by kind; size chunks to land on them and stay under the time ceiling. When in doubt, stop more often — a captured pause is cheap, lost progress is not.

---

## The execution loop

On invocation, first resume from the canonical doc if one exists (see *The canonical plan doc*), and open with the overview gate (Step 1) before any worker runs. Then, for each chunk, in order:

1. **Select the next chunk** and its target stopping point. Confirm it's drawn on a clean seam and briefed small enough to stay under the time ceiling.
2. **Brief a worker.** Spawn an Agent with a **self-contained brief** — don't rely on it mining the whole doc. Inline the specific constraints and invariants relevant to *this* chunk, name the exact files/functions, state what's **out of scope**, give the tests to run, and the report contract: *what you did, what you encountered, test results, proposed doc updates, anything that needs human input.* Tell it explicitly: stop at the boundary, don't start the next chunk, don't commit. Run workers where a permission prompt can be answered (or pre-authorize the edits they need) — an unattended worker that hits a prompt stalls, and a backgrounded one auto-denies and fails.
3. **Receive and review the report.** First check the worker **stayed in bounds** — didn't touch files outside its scope, didn't start the next chunk, didn't commit — independent of whether tests pass. Then judge the work: for subtle / invariant-heavy chunks read the actual diff and record what you verified in the doc; for mechanical, well-tested chunks the report plus green tests is enough.
4. **Update the canonical doc.** Ratify the worker's proposed updates, integrate findings, advance the stage status, record decisions and *why*.
5. **Act on the stopping point.**
   - Commit seam → suggest a commit message, stop for the human to commit.
   - Verification seam → tell the human what to test/inspect.
   - A design question or plan fork surfaced → ask the human.
   - Progress-capture return → post a progress note, continue.
   - None reached and chunk complete → proceed to the next chunk.
6. **Surface progress between chunks** (see Transparency).

---

## Calling out to the human

Call out whenever human input is genuinely needed, and don't be stingy — erring toward more is right. Be specific: name exactly what to check or decide, and why it matters now. The human would rather be asked ten focused questions than discover a wrong assumption ten stages deep. Two kinds:

- **Blocking callouts** — you can't correctly proceed until the human answers: a commit, a design fork, sign-off on work the next chunk builds on. These gate progress.
- **Deferred / informational callouts** — worth the human's eyes or eventual verification, but not a precondition for the next *independent* chunk: an FYI, a "eyeball this when convenient," verification of work nothing downstream depends on yet.

**When the human is away.** Human gates are asynchronous — the human won't always be present, and you must not deadlock at the first one. On a *blocking* gate with no human, stop only if the remaining work depends on it (or it's a commit); otherwise record the pending item in the doc and continue with any chunk independent of the un-answered gate. Hard-stop only when everything left depends on a pending blocking gate or a commit.

**Recap what they missed.** Informational notes and deferred checks are easy to miss when they're interspersed with working output. Keep a running list of what's accumulated since the human was last engaged, and **lead your next response to them with a short recap of it** — so those notes and pending checks land together at a moment they're actually looking, not buried mid-stream. No special label or preface; just put it at the front, the way you naturally would.

---

## When reality diverges — failure and re-planning

You are running on a capable model; improvising is allowed and expected. But **record every re-plan in the doc** so the resume anchor stays true.

- **A worker's tests fail and it couldn't fix them.** Retry with more context, or re-scope the chunk smaller — but **escalate to the human after about two failed attempts or re-scopes** rather than retrying silently in a loop. Don't paper over a red suite to keep moving.
- **A worker reports success but did the wrong, partial, or out-of-scope thing** (tests green because the oracle was weak or absent). This is what the in-bounds + diff check in loop step 3 is for — treat it as a failure, not a pass.
- **A worker reports the downstream plan now looks wrong.** Re-plan the affected stages in the doc, surface the change and your reasoning to the human, then proceed.
- **A chunk reveals the whole approach is off.** Stop, write up what you learned, and bring the human a revised plan before burning more work on the old one.

Trust workers' "done" in proportion to verifiability (see Delegation depth). Where the oracle is human eyes or the invariant is subtle, verify before you build on it.

---

## Transparency

A worker run is a quiet interval: while it runs you're suspended and emit nothing, then its report lands in a burst. So transparency is **between-chunk**, not live narration — before spawning, say what you're handing off; after, say what came back and where you are in the plan. Keep these notes light but real, so a watching human can follow along and a human who stepped away can catch up from them and the doc. When you next stop for the human, lead with a short recap of anything that accumulated while they were away (see *Calling out*).

---

## Commits — the human owns them

Never run `git commit`. At a commit seam, present a suggested message in conventional-commit style (following the project's own commit conventions) and stop. A commit seam often rolls up several chunks the human hasn't watched land, so make the suggested message and the doc legible about *everything* included — the human is commit-gating a batch, not a single chunk. Commits are atomic, independently-shippable units; if the work isn't in a shippable state, it isn't a commit point — it's a verification or progress-capture point instead. Tell workers not to commit either.

---

## Quick reference

- **Solo unless big.** Orchestration is the heavy-effort branch; degrade to a normal session when it's overkill.
- **Overview before workers.** Always open with a staged plan + estimate + risks + open questions (and a staleness check on any pre-written doc), then stop for the human's go-ahead before kicking off.
- **Doc is canonical.** Your context is disposable; on invocation, resume from the doc; record what *you* verified, since your live context won't survive.
- **Delegate by default for context economy.** Do a chunk yourself only when it's too small to be worth the ceremony. Trust the report in proportion to verifiability; review the diff yourself for subtle invariants and write down what you checked.
- **Workers report; you ratify.** A worker does one bounded chunk, runs tests, reports, stops. Check it stayed in bounds before trusting it.
- **Three kinds of stop, one doc update each.** Commit (shippable, human commits) · verification (eyeball-able, unshippable) · progress-capture (chunk-size ceiling, ~20–30 min). Commits are the shippable subset, often few.
- **Two kinds of callout.** Blocking (gates progress) vs. deferred/informational (don't deadlock on it). Call out liberally; lead your next response to the human with a recap of what they missed.
- **Don't deadlock on an absent human.** Continue any work independent of a pending gate; hard-stop only when blocked or at a commit.
- **Never commit.** Surface the message; the human commits.
