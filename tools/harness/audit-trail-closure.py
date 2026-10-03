#!/usr/bin/env python3
"""Audit Trail — the closure arithmetic, enumerated.

A second instrument beside the TLA+ models of compositions/audit-trail.md. The models carry
interleavings at small constants and cannot run a conforming regime (their headers say so);
this script carries the ARITHMETIC: it reads the page's own term formulas, enumerates
parameter tuples the page's Instance start admits, walks each scan leg's timeline as the
page's rules state it, and reports every admitted tuple on which a conforming leg cannot
finish (C1) or a finding outlives closure sum (C3). pressure-testing.md, *An
outside-the-frame finding names the instrument you are missing*: a bound over a schedule
wants an enumerator.

What is read from the page, so the page and this script cannot drift apart silently:
  Term closure sum, Term closure floor (both parts), Term closure spend, Term re-drive
  spend, Term record edge, Term purge edge  — evaluated as written.
What is encoded here, each line citing the rule it transcribes; every cited label must
exist on the page or the run fails:
  the leg timeline (TIMELINE below), Term work bound's enumeration counts, Instance start
  23 and 25.

Twins: each re-introduces one hazard by overriding one formula and must BREACH. A twin that
holds is a failure of this instrument, not a pass.

  python3 tools/harness/audit-trail-closure.py            page + twins, exit 0 iff page holds and every twin breaches
  python3 tools/harness/audit-trail-closure.py --verbose  also print the first breach of each kind
"""
import itertools, os, re, sys
from functools import lru_cache

HERE = os.path.dirname(os.path.abspath(__file__))
PAGE = os.environ.get('AUDIT_TRAIL_PAGE') or os.path.join(HERE, '..', '..', 'compositions', 'audit-trail.md')

# ---------------------------------------------------------------- the page, read
NAMES = ['record_action_completion_bound', 'purge_completion_bound', 'seal_completion_bound',
         'call_pause_bound', 'clock_offset_allowance', 'reconciliation_cadence',
         'compensation_closure_latency', 'measured_enumeration', 'closure_floor']
SAFE = re.compile(r'^[\sa-z_0-9+*(),]+$')

def read_page(path=PAGE):
    text = open(path, encoding='utf-8').read()
    terms = {}
    for name in ['closure sum', 'closure spend', 're-drive spend', 'record edge', 'purge edge']:
        m = re.search(r'^Term %s: `([^`]+)`' % re.escape(name), text, re.M)
        if not m:
            sys.exit('page changed: Term %s has no formula in a code span' % name)
        terms[name] = m.group(1)
    m = re.search(r'^Term closure floor: `([^`]+)`, plus `([^`]+)` WHERE seal cadence EQUALS per-event', text, re.M)
    if not m:
        sys.exit('page changed: Term closure floor is not "`formula`, plus `formula` WHERE seal cadence EQUALS per-event"')
    terms['closure floor'], terms['closure floor per-event'] = m.group(1), m.group(2)
    for f in terms.values():
        if not SAFE.match(f) or '__' in f:
            sys.exit('page changed: formula not in the controlled form: %s' % f)
    missing = [lab for lab in CITED if not re.search(r'^\s*(?:Term )?%s:' % re.escape(lab), text, re.M)]
    if missing:
        sys.exit('page changed: cited labels missing: %s' % ', '.join(missing))
    return terms

def ev(formula, env):
    return eval(formula, {'__builtins__': {}, 'max': max, 'min': min}, env)

# ---------------------------------------------------------------- the timeline, transcribed
# One entry per fact this script supplies. Label -> what is taken from it.
TIMELINE = [
 ('reconciliation cadence 1a',        'a run starts no later than one cadence after the previous run\'s START; runs may overlap'),
 ('Reconciliation 5',                 'a run reads now once, before its enumeration; the age edge is read against that reading'),
 ('clock offset allowance 2',         'the edge is widened by the allowance, and the scan\'s reading may run one allowance behind the stamp: bound + 2A'),
 ('First half 1',                     'first half, before the take: one enumeration, the retention store'),
 ('Second half 1',                    'second half, before the take: the binding set (audit log, then destruction records) ...'),
 ('Reconciliation 1',                 '... and the attestation store the half runs over'),
 ('Third half 1',                     'third half, before the take: the audit-log pass ...'),
 ('Third half 3',                     '... and the rebuild of event to retention that makes a miss a true miss'),
 ('Per-act critical section 13a',     'leg lease = closure latency - time spent before the take - call pause bound'),
 ('Per-act critical section 13d',     'a leg whose lease does not exceed the half\'s work bound does not take, and skips'),
 ('Per-act critical section 5',       'a leg that finds the section held skips the act for the rest of the run'),
 ('work bound',                       'under the lease: second half one enumeration, third half two, first half the purge bound'),
 ('Second half 17',                   'second half, under the lease: ONE enumeration (audit log + destruction records)'),
 ('Third half 6',                     'third half, under the lease: the retention-store enumeration of the true miss'),
 ('Compensation 10',                  'third half, under the lease: the audit-log enumeration that reads narrated'),
 ('Reconciliation 1b',                'the take comes before the wait on the probe, so the wait is spent under the lease'),
 ('Invariant 1.10',                   'a run\'s first reconciliation-path record action goes alone ...'),
 ('Invariant 1.11',                   '... and the others wait for its RETURN: one record action, its per-event seal included'),
 ('Per-act critical section 9c',      'a record action seals at step 6 before it returns under per-event cadence'),
 ('Instance start 23',                'a seal call is priced at twice the seal bound; purge bound exceeds it'),
 ('Per-act critical section 13f',     'a leg starts a record action only while remaining > record bound + 2 call pauses'),
 ('Per-act critical section 13h',     'a record action a leg starts completes its truth-bearing writes inside the leg\'s lease'),
 ('record action completion bound',   'the bound runs from the first committed write; the attest call ahead of it is one call'),
 ('Third half 8',                     'intent before placement'),
 ('Third half 9',                     'placement before the compensation record'),
 ('lease',                            'live only while remaining > 2 call pauses (Lease Sizing 2)'),
 ('Per-act critical section 9a',      'an invocation\'s lease is its completion bound, so a dead holder strands the act that long'),
 ('record action step 2.10',          'the take lands no later than one record bound after the invocation\'s reading: the section frees by 2 record bounds'),
 ('compensation closure latency 1',   'one whole closure lands within closure latency of the run\'s start'),
 ('Instance start 16',                'window > closure sum'),
 ('Instance start 18',                'closure latency > closure spend'),
 ('Instance start 19',                'closure latency > re-drive spend'),
 ('Instance start 25',                'every completion bound > 2 call pauses'),
]
CITED = [lab for lab, _ in TIMELINE]

HALVES = ('first', 'second', 'third')

def derive(p, terms):
    """All derived quantities for one tuple, formulas read from the page."""
    env = dict(record_action_completion_bound=p['rab'], purge_completion_bound=p['pcb'],
               seal_completion_bound=p['scb'], call_pause_bound=p['cpb'],
               clock_offset_allowance=p['A'], reconciliation_cadence=p['C'])
    me = max(p['E_log'] + p['E_dest'], p['E_att'], p['E_ret'])       # Term measured enumeration
    env['measured_enumeration'] = me
    floor = ev(terms['closure floor'], env) + (ev(terms['closure floor per-event'], env) if p['per_event'] else 0)
    env['closure_floor'] = floor
    d = dict(me=me, floor=floor,
             spend=ev(terms['closure spend'], env), respend=ev(terms['re-drive spend'], env),
             record_edge=ev(terms['record edge'], env), purge_edge=ev(terms['purge edge'], env))
    d['sum_of'] = lambda lat: ev(terms['closure sum'], dict(env, compensation_closure_latency=lat))
    return d

def pretake(p, half, reading):
    """Time a run spends before a leg's take."""
    if half == 'first':
        return p['E_ret']
    if half == 'second':
        a, b = p['E_log'] + p['E_dest'], p['E_att']
    else:
        a, b = p['E_log'], p['E_ret']
    return a + b if reading == 'sequential' else max(a, b)

def leg(p, d, lat, half, reading):
    """C1: can a conforming leg of this half finish? Returns None, or the rule that stops it."""
    cpb, rab = p['cpb'], p['rab']
    e = pretake(p, half, reading)
    L = lat - e - cpb                                         # 13a
    work = {'first': p['pcb'], 'second': d['floor'] + d['me'], 'third': d['floor'] + 2 * d['me']}[half]
    if not L > work:
        return '13d: lease %d does not exceed work bound %d (before the take: %d)' % (L, work, e)
    if half == 'first':
        return None                                           # every cascade write is gated live; L > purge bound finishes it
    seal = 2 * p['scb'] if p['per_event'] else 0
    ra = cpb + rab + seal                                     # one record action, call to return
    t = (p['E_log'] + p['E_dest']) if half == 'second' else (p['E_log'] + p['E_ret'])
    t += ra                                                   # the probe's wait
    t += cpb                                                  # remaining, read for 13f
    if not L - t > rab + 2 * cpb:
        return '13f declines the intent: remaining %d' % (L - t)
    t += ra
    if half == 'third':
        t += cpb                                              # remaining, read for the placement
        if not L - t > 2 * cpb:
            return 'lease reads expired at the placement: remaining %d' % (L - t)
        t += cpb                                              # the placement
    t += cpb
    if not L - t > rab + 2 * cpb:
        return '13f declines the compensation: remaining %d' % (L - t)
    t += cpb + rab
    if t > L:
        return '13h: the compensation lands outside the lease'
    return None

def worst_landing(p, lat, half, reading):
    """C3: the latest a closure can land after the finding's creation, one dead run budgeted."""
    cpb, C, A = p['cpb'], p['C'], p['A']
    bound = p['pcb'] if half == 'first' else p['rab']
    t_age = bound + 2 * A
    free0 = {'first': p['pcb'], 'second': 2 * p['rab'], 'third': p['rab']}[half]
    emax = pretake(p, half, reading)
    sys.setrecursionlimit(100000)

    @lru_cache(maxsize=None)
    def go(s, free_at, deaths):
        best = 0
        take_possible = s >= t_age and s + emax >= free_at
        must_take = s >= t_age and s >= free_at            # every e succeeds
        if take_possible:
            best = s + lat                                    # the leg lives and closes
            if deaths:
                best = max(best, nxt(s, s + lat - cpb, deaths - 1))   # it dies; its lease stands to s + lat - cpb
        if not must_take:
            best = max(best, nxt(s, free_at, deaths))         # the adversary's e skips it
        return best

    def nxt(s, free_at, deaths):
        return max(go(s + g, free_at, deaths) for g in range(1, C + 1))

    return max(go(s0, free0, 1) for s0 in range(-(C - 1), 1))

# ---------------------------------------------------------------- tuples
# Two grids. A leg's arithmetic (C1) does not read the allowance or the cadence; the schedule (C3)
# reads the enumerations only through the time before the take. Every tuple satisfies Instance
# start 23 and 25 by construction and takes the least closure latency Instance start 18 and 19
# admit, and one looser.
BASE = dict(cpb=[1, 2], rab_over=[1, 2, 6], scb_over=[1, 4], pcb_over=[1, 5], per_event=[False, True], lat_over=[1, 4])
LEG_GRID = dict(BASE, E_log=[0, 1, 3], E_dest=[0, 1], E_att=[0, 2, 4], E_ret=[0, 1, 4], A=[0], C=[1])
SCHED_GRID = dict(BASE, E=[(0, 0, 0, 0), (1, 1, 2, 1), (3, 1, 4, 4)], A=[0, 1, 3], C=[1, 4, 9])

def tuples(terms, grid):
    keys = list(grid)
    for vals in itertools.product(*(grid[k] for k in keys)):
        g = dict(zip(keys, vals))
        if 'E' in g:
            g['E_log'], g['E_dest'], g['E_att'], g['E_ret'] = g['E']
        cpb = g['cpb']
        rab = 2 * cpb + g['rab_over']                         # Instance start 25
        scb = 2 * cpb + g['scb_over']                         # Instance start 25
        pcb = 2 * scb + g['pcb_over']                         # Instance start 23 (and 25)
        p = dict(cpb=cpb, rab=rab, scb=scb, pcb=pcb, A=g['A'], C=g['C'], E_log=g['E_log'], E_dest=g['E_dest'],
                 E_att=g['E_att'], E_ret=g['E_ret'], per_event=g['per_event'])
        d = derive(p, terms)
        lat = max(d['spend'], d['respend']) + g['lat_over']   # Instance start 18, 19
        yield p, d, lat

def run(terms, reading='sequential'):
    n1 = n3 = c1 = c3 = 0
    first = {}
    slack = None
    for p, d, lat in tuples(terms, LEG_GRID):
        n1 += 1
        for half in HALVES:
            why = leg(p, d, lat, half, reading)
            if why:
                c1 += 1
                first.setdefault('C1 ' + half, (p, lat, why))
    for p, d, lat in tuples(terms, SCHED_GRID):
        n3 += 1
        for half in HALVES:
            w = worst_landing(p, lat, half, reading)
            s = d['sum_of'](lat) - w
            slack = s if slack is None else min(slack, s)
            if s < 0:
                c3 += 1
                first.setdefault('C3 ' + half, (p, lat, 'lands %d after creation; closure sum %d' % (w, d['sum_of'](lat))))
    return (n1, n3), c1, c3, slack, first

TWINS = [
 ('spend-three',   'closure spend',  'closure_floor + call_pause_bound + 3 * measured_enumeration',
  'the third half\'s rebuild before the take uncounted (the page as it stood at b9c3e04)'),
 ('spend-no-pause', 'closure spend', 'closure_floor + 4 * measured_enumeration',
  'the take\'s own call pause uncounted'),
 ('floor-no-probe', 'closure floor', '3 * record_action_completion_bound + 6 * call_pause_bound',
  'the probe\'s wait uncounted'),
 ('sum-one-run',   'closure sum',
  'max(2 * record_action_completion_bound, purge_completion_bound) + 2 * clock_offset_allowance + reconciliation_cadence + compensation_closure_latency',
  'no dead run budgeted'),
]

WALKTHROUGH = dict(cpb=2, rab=30, scb=120, pcb=300, A=2, C=60, E_log=38, E_dest=2, E_att=40, E_ret=40, per_event=False)
WALK_LAT, WALK_WINDOW = 360, 86400

def main():
    verbose = '--verbose' in sys.argv
    terms = read_page()
    ok = True
    print('Audit Trail closure arithmetic — %s' % os.path.relpath(PAGE, os.path.join(HERE, '..', '..')))
    for reading in ('sequential', 'concurrent'):
        n, c1, c3, slack, first = run(terms, reading)
        verdict = 'HOLDS' if not (c1 or c3) else 'BREACH'
        print('  page, %-10s pre-take enumerations: %d leg tuples and %d schedule tuples, x 3 halves; leg cannot finish on %d; outlives closure sum on %d; least slack %d  -> %s'
              % (reading, n[0], n[1], c1, c3, slack, verdict))
        if c1 or c3:
            ok = False
            for k, (p, lat, why) in first.items():
                print('      first %s: %s | closure latency %d | %s' % (k, p, lat, why))
    # the walkthrough's own numbers satisfy every inequality the page declares
    d = derive(WALKTHROUGH, terms)
    w_ok = (WALK_WINDOW > d['sum_of'](WALK_LAT) and WALK_LAT > d['spend'] and WALK_LAT > d['respend']
            and all(leg(WALKTHROUGH, d, WALK_LAT, h, 'sequential') is None for h in HALVES))
    print('  walkthrough: closure sum %d s, closure spend %d s, re-drive spend %d s against closure latency %d s -> %s'
          % (d['sum_of'](WALK_LAT), d['spend'], d['respend'], WALK_LAT, 'HOLDS' if w_ok else 'BREACH'))
    ok = ok and w_ok
    for name, term, formula, what in TWINS:
        t = dict(terms)
        t[term] = formula
        n, c1, c3, slack, first = run(t, 'sequential')
        rejected = bool(c1 or c3)
        print('  twin %-15s leg %4d, sum %4d -> %-21s %s' % (name, c1, c3, 'BREACH (as required)' if rejected else 'HOLDS: THE TWIN FAILED', what))
        if verbose and first:
            k, (p, lat, why) = next(iter(first.items()))
            print('      first %s: %s | closure latency %d | %s' % (k, p, lat, why))
        ok = ok and rejected
    print('PASS' if ok else 'FAIL')
    return 0 if ok else 1

if __name__ == '__main__':
    sys.exit(main())
