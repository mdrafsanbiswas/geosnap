# Task 2 Optimization Approach (Interviewer Notes)

## Context
Task 2 implements camera capture, batch upload, offline queue retention, and auto-retry on network recovery. During review, we identified correctness and performance issues in sync behavior and UI refresh patterns.

## Optimization Goals
1. Make upload retry/resume deterministic after reconnect.
2. Keep UI state accurate across screen navigation.
3. Reduce unnecessary rebuilds in presentation widgets.
4. Minimize expensive local persistence writes during upload progress.

## Approach Summary

### 1) State Integrity: Emit Immutable Snapshots
Problem:
- Upload item collections were updated in-place during progress callbacks.
- This created stale UI symptoms and non-deterministic rebuild behavior.

Optimization:
- Emitted unmodifiable list snapshots for every queue update.
- Ensured each state emission is referentially safe and predictable.

Why this matters:
- Prevents hidden post-emit mutations.
- Improves consistency of `Bloc` diffing and widget updates.

### 2) Reconnect Behavior: Refresh + Auto-Resume in Bloc
Problem:
- Pending uploads sometimes resumed only after opening camera/sync screen.

Optimization:
- On network restore event, immediately reloaded latest queue from storage.
- Triggered silent processing when retryable items exist.
- Kept this behavior app-scoped so it works from home screen too.

Why this matters:
- Retry is no longer route-dependent.
- Background-like user experience is preserved while app is active.

### 3) Write Amplification Reduction During Progress
Problem:
- Persisting full queue to SharedPreferences on every progress chunk caused avoidable I/O overhead.

Optimization:
- Removed per-chunk persistence writes.
- Persisted only at meaningful state transitions (status/progress completion, failures, waiting-for-network, uploaded).
- Kept transient progress updates in memory for UI smoothness.

Why this matters:
- Lower serialization + disk write frequency.
- Better responsiveness under large batches and unstable networks.

### 4) UI Rebuild Granularity
Problem:
- Some widgets rebuilt larger UI sections than necessary when queue state changed.

Optimization:
- Moved queue-dependent updates into narrow selectors/chips.
- Kept static card layout outside reactive scope where possible.

Why this matters:
- Smaller rebuild surfaces.
- More stable frame timing, especially during rapid upload progress updates.

## UX/Requirement Alignment
- Pending/offline state is visible from home and camera views.
- Pending count and sync indicators update correctly after reconnect.
- Image preview flow is explicit (batch grid + upload list to full preview).
- User-facing copy avoids implementation-level/internal wording.

## Validation Performed
- `flutter analyze` with zero issues.
- `flutter test` passed after updates.
- Manual flow validation focused on:
  - offline -> pending queue
  - reconnect -> auto-resume
  - home screen state clearing after queue completion

## Tradeoffs and Future Extensions
- SharedPreferences remains acceptable for assessment scope, but for very large queues an indexed local DB (e.g., Drift/Isar) would improve scalability.
- True OS-level background guarantees can be strengthened with platform-specific scheduling constraints and retry policies.
- If needed, progress event throttling can further reduce render pressure in extremely noisy upload streams.

## Interviewer Takeaway
The optimization strategy prioritized correctness first (state integrity + reconnect determinism), then targeted practical performance wins (I/O reduction and rebuild scoping) without overengineering the architecture.
