<!-- Recoverable Invocation — the [Yield] and [Resolve] sections (the tail of part 2 of 5, lost in the paste). Same text GLM read; nothing changed. -->
---

#### `yield`

```
yield(kind, act_key, invocation_id) → ok
```

```text
YD1: [Yield] MUST release the section without writing.
YD2: The adopter's action MUST call [Yield] on the unknown partition.
YD3: No adopter MAY touch act_section directly.
YD4: [Yield] MUST NOT close the intent.
```

---

#### `resolve`

```
resolve(kind, act_key, invocation_id, intent_event_id, actor_ref, credential,
        disposition) →
    {closing_event_id}
  | rejected(
      already-accounted(closing_event_id)
    | not-known
    | section-unavailable
    | invalid-credential
    | invalid-request(purged | malformed | too-young | already-abandoned
                    | candidates-over-cap)
    | recording-failure(resolution)
    )
```

The human-attested close: an operator closes an open intent the sweep cannot — under `service_identity = none`, or for an escalated act the operator has investigated — supplying the disposition the operator's own run of the adopter's `probe` supports.

```text
RS1: The operator MUST supply disposition as EXACTLY ONE OF outcome(outcome_action_ref, outcome_data), abandoned(cause), escalated(candidates).
RS2: The substrate MUST validate the operator's credential at the closing record_action and nowhere earlier.
RS3: A credential failure MUST land rejected(invalid-credential) with the section released and nothing appended.
RS4: [Resolve] MUST take the section: take((kind, act_key), operator_run_id, sweep_lease).
RS4a: The take MUST NOT block longer than the holder's remaining lease.
RS5: A failed take MUST land rejected(section-unavailable).
RS6: IF journal_write_bound EXCEEDS remaining THEN [Resolve] MUST NOT write.
RS7: [Resolve] MUST re-read the act's records under the section.
RS8: An outcome or a refusal naming the invocation_id MUST land rejected(already-accounted(closing_event_id)).
RS9: An invocation_id with no readable intent record MUST land rejected(not-known).
RS10: [Resolve] MUST read the intent by read_record(intent_event_id).
RS11: An intent whose payload the substrate reports Purged MUST land rejected(invalid-request(purged)).
RS12: EVERY closing [Resolve] writes over an existing record MUST carry supersedes = that record's event_id.
RS13: WHEN no closing stands:
    RS13a: [Resolve] MAY write any disposition as the act's closing.
RS14: WHEN an escalated record stands:
    RS14a: [Resolve] MUST name the record in supersedes for any disposition.
RS15: WHEN an abandoned record stands:
    RS15a: [Resolve] MAY supersede the record ONLY IF disposition = outcome.
RS16: An abandoned disposition over an abandoned record MUST land rejected(invalid-request(already-abandoned)).
RS18: An abandoned disposition for an in-flight intent MUST land rejected(invalid-request(too-young)).
RS19: The too-young guard MUST compare against now injected at the operator's seam.
RS20: WHEN commit_fence = none:
    RS20a: [Resolve] MUST admit the operator's abandoned disposition as the operator's attestation that the store has been quiet for as long as the operator's judgment requires.
RS21: [Resolve] MUST write the closing record under the operator's own credential with recovery = true, resolved_by = actor_ref, acting_actor_ref = the intent's actor_ref, and no recovery_intended.
RS22: [Resolve] MUST release after the write.
RS23: The closing write's arms MUST follow the outcome position.
RS23a: After step-4 or the retention-source invalid-request, [Resolve] MUST read the record back by invocation_id and return success with a hard alert.
RS23b: [Resolve] MUST NOT retry after step-4 or the retention-source invalid-request.
RS24: step-2 | step-3, and a lost reply after an empty read-back, MUST land rejected(recording-failure(resolution)).
RS26: invalid-request MUST carry the cause: malformed, candidates-over-cap, purged, already-abandoned, too-young.
RS27: A candidate list exceeding intent_candidates_cap MUST land rejected(invalid-request(candidates-over-cap)).
```

WHY:
Audit Trail projects no read that validates a credential without appending, so validation before the take had no call to make; both substitutes broke it (an early `record_action` appends before the section; a direct `attest` mints an orphan attestation on every typo). RS10 is why [Resolve] takes `intent_event_id`: every route from an `invocation_id` to an `event_id` reads the payload the purge destroyed, and without the id a lawfully destroyed record answers `not-known`. `resolved_by` names the operator, not a record; without RS12 a lawful resolution read as a `binding_duplicate` (`-buggy-supersede`, rejected). The transitive rule is a prose repair the model does not confirm. RS19: a reading nothing bounds must not decide a destructive record (`-buggy-opclock` violates Invariant 5 against `probe-reportonly-clean`). RS23: a retry after `step-4` appends the duplicate in a deployment that has the fence and needs no pause to do it. RS26: the five causes imply three moves — fix and retry, nothing to do, wait and re-issue unchanged.

---

