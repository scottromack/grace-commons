#!/usr/bin/env python3
"""Worst-case landing time for a sweep-closed act, enumerated over adversary
schedules, against the candidate window inequalities.

WHY THIS EXISTS. Gate 8's F2 says the window inequality under-budgets a dead
sweep run by one whole `run_bound`. The campaign's own lesson from gate 7 is
that a gate's prescribed remedy is a hypothesis: the F2 remedy proposed there
did not work until the margin was minted into every fence instant. So the
correction is derived here from the page's stated timeline semantics and
searched, rather than patched by adding the term the gate named.

The formal model cannot answer this. It carries leases, fences and a window,
but it has no backlog and therefore no `run_bound` — which is exactly why F2
landed OUTSIDE the modeled frame in gate 8's frame metric. This file is the
smaller instrument that covers the hole, and its assumptions are written down
so that a reader can reject one and rerun.

SEMANTICS ENCODED (each traced to the page):

  A1  The act's intent is recorded at t = 0 (`recorded_at`), and the window is
      measured from there (Configuration §`compensation_window`).

  A2  [Reconcile] step 1 keeps intents older than
      `completion_bound + clock_skew_allowance`, and a run reads `now` once at
      its own seam under `clock_skew_allowance`. So a run whose seam reading
      falls before `completion_bound + 2 * skew` MAY legitimately miss the act,
      and one at or after it may not. Call that instant E.

  A3  Runs are serial: "a run that outlasts a cadence is one run — the next does
      not start beside it" (Configuration §`run_bound`). The next run starts at
      the first cadence tick at or after the previous run's end, so
      `next_start <= prev_end + cadence`.

  A4  A run's disclosed `run_bound` is "from a run's start to the last closing
      it lands ... plus the waits", and §`act_section` fixes the waits term as
      "one holder's remaining lease per act". So a surviving run lands our
      closing by `start + run_bound` — waits included — and a run that dies
      does so at most `run_bound` after its start.

  A5  A run that dies holding an act's section holds it until its own lease,
      `max(completion_bound, closure_latency)`, expires (Configuration).

  A6  The window budgets exactly one death.

WHAT IS SEARCHED. The adversary picks: where the last pre-E run starts and how
long it runs, when each later run starts within A3, which run dies and when,
and whether the dying run took our act's section first. The search returns the
latest instant at which the first closing record for our act can land.
"""
import itertools

# ---------------------------------------------------------------- the search

def worst_landing(cb, cl, skew, cad, rb, deaths=1, trace=False):
    """Latest first-closing instant for an act whose intent lands at t = 0."""
    lease = max(cb, cl)
    E = cb + 2 * skew

    best = (-1, None)

    def consider(t, why):
        nonlocal best
        if t > best[0]:
            best = (t, why)

    # The last run to start before E misses the act (A2) and may run its whole
    # pass (A4). Its start is at most E - 1; a run starting at or after E is
    # handled as the first examining run. The adversary may also choose to have
    # no pre-E run in flight, which is never worse, so both are enumerated.
    first_examining_starts = [
        (E, ["no run was in flight at E"]),
        (E - 1 + rb + cad, ["a run started at E-1, missed the act (A2),",
                            f"ran its whole pass (+{rb}), and the next tick",
                            f"followed its end (+{cad}) (A3, A4)"]),
    ]

    def run_from(s, deaths_left, why, section_free_at):
        # The run examines the act. It must wait for the section (A5) before it
        # can close; its disclosed bound is supposed to cover that wait (A4).
        take_at = max(s, section_free_at)
        landing_by_disclosure = s + rb
        landing_by_mechanism = take_at + cl
        # A run cannot land a closing before it has taken the section and done
        # one closure; where the mechanism exceeds the disclosure, the
        # deployment's `run_bound` is under-disclosed, which is reported.
        consider(max(landing_by_disclosure, landing_by_mechanism),
                 why + [f"the run starting at {s} lands the closing by "
                        f"{max(landing_by_disclosure, landing_by_mechanism)}"])
        if deaths_left:
            # It dies instead, at most rb after its start (A4), having taken
            # our act's section at the latest instant that still lets it die
            # holding it. The next run starts within a cadence of the death.
            for took in (True, False):
                death = s + rb
                held_until = (take_at + lease) if took else section_free_at
                run_from(death + cad, deaths_left - 1,
                         why + [f"the run starting at {s} "
                                + ("took the section and " if took else "")
                                + f"died at {death} (+{rb}), the next tick "
                                f"followed (+{cad})"],
                         held_until)

    for s, why in first_examining_starts:
        run_from(s, deaths, why, section_free_at=0)

    if trace:
        for line in best[1]:
            print("      " + line)
    return best[0]


# ------------------------------------------------------- candidate inequality

def current(cb, cl, skew, cad, rb):
    """What the page carries today."""
    return cb + max(cb, cl) + 2 * skew + cad + rb

def gate_fix(cb, cl, skew, cad, rb):
    """Gate 8's prescribed remedy: a second `run_bound`."""
    return cb + max(cb, cl) + 2 * skew + cad + 2 * rb

def derived(cb, cl, skew, cad, rb):
    """What the search above says the timeline actually costs."""
    return cb + 2 * skew + 2 * cad + 3 * rb


# ------------------------------------------------------------------ the sweep

def main():
    grid = list(itertools.product(
        [2, 3, 5, 30],        # completion_bound
        [1, 5, 40],           # closure_latency
        [0, 1, 2],            # clock_skew_allowance
        [1, 6, 60],           # reconciliation_cadence
        [5, 12, 120, 400],    # run_bound
    ))
    fails = {"current": [], "gate_fix": [], "derived": []}
    under_disclosed = []
    breach_under_c4 = []
    breach_under_old_floor = []
    old_floor_kept = 0
    JWB = 1  # one tick of journal_write_bound, this grid's unit
    for cb, cl, skew, cad, rb in grid:
        lease = max(cb, cl)
        w = worst_landing(cb, cl, skew, cad, rb)
        for name, fn in (("current", current), ("gate_fix", gate_fix),
                         ("derived", derived)):
            if fn(cb, cl, skew, cad, rb) < w:
                fails[name].append((cb, cl, skew, cad, rb, fn(cb, cl, skew, cad, rb), w))
        # condition 4 of instance start, in the `max` form: a run must contain
        # one holder's remaining lease and the closure that follows it, and the
        # holder may be an invocation (completion_bound) or a dead run/operator
        # (closure_latency + journal_write_bound).
        floor = max(cb, cl + JWB) + cl
        if rb < floor:
            under_disclosed.append((cb, cl, rb, floor))
        elif derived(cb, cl, skew, cad, rb) < w:
            breach_under_c4.append((cb, cl, skew, cad, rb))
        if rb >= 2 * cl + JWB:
            old_floor_kept += 1
            if derived(cb, cl, skew, cad, rb) < w:
                breach_under_old_floor.append((cb, cl, skew, cad, rb))

    print(f"grid: {len(grid)} parameter tuples\n")
    for name in ("current", "gate_fix", "derived"):
        bad = fails[name]
        verdict = "HOLDS" if not bad else f"BREACHED on {len(bad)}/{len(grid)}"
        print(f"  {name:9s} {verdict}")
        if bad:
            cb, cl, skew, cad, rb, claimed, actual = max(bad, key=lambda r: r[6] - r[5])
            print(f"            worst gap: completion_bound={cb} closure_latency={cl} "
                  f"skew={skew} cadence={cad} run_bound={rb}")
            print(f"            inequality certifies {claimed}, the timeline reaches {actual} "
                  f"(short by {actual - claimed})")
    kept_c4 = len(grid) - len(under_disclosed)
    print(f"\n  condition 4, max(completion_bound, closure_latency + journal_write_bound)"
          f" + closure_latency:")
    print(f"      admits {kept_c4}/{len(grid)} tuples; window inequality breaches among them: "
          f"{len(breach_under_c4)}")
    print(f"  the floor this page carried for two rounds, 2 x closure_latency + journal_write_bound:")
    print(f"      admits {old_floor_kept}/{len(grid)} tuples; window inequality breaches among them: "
          f"{len(breach_under_old_floor)}")

    print("\n  the walkthrough's own deployment:")
    cb, cl, skew, cad, rb, window = 30, 12, 2, 60, 135, 600
    w = worst_landing(cb, cl, skew, cad, rb, trace=True)
    print(f"      current   certifies {current(cb, cl, skew, cad, rb)}")
    print(f"      derived   certifies {derived(cb, cl, skew, cad, rb)}")
    print(f"      timeline  reaches   {w}   (window {window})")

    print("\n  gate 8's F2 counterexample deployment:")
    cb, cl, skew, cad, rb, window = 30, 5, 2, 60, 400, 530
    w = worst_landing(cb, cl, skew, cad, rb)
    print(f"      current   certifies {current(cb, cl, skew, cad, rb)} < {window} — starts")
    print(f"      gate_fix  certifies {gate_fix(cb, cl, skew, cad, rb)}")
    print(f"      derived   certifies {derived(cb, cl, skew, cad, rb)}")
    print(f"      timeline  reaches   {w}")


if __name__ == "__main__":
    main()
