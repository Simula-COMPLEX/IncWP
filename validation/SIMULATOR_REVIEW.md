# Full-path versus subpath validation review

Reviewed 2026-09-16. Read-only inspection of simulator code and the saved
REMUS100 FullWP validation checkpoint; no MATLAB session or simulations launched.
No simulator, checkpoint, or experiment data was changed by this review.

## What the reported numbers establish

For the first 4,676 completed individuals (28,056 subpaths), the checkpoint's
recalculated labels reproduce the supplied totals exactly: stable 17,808,
unstable 10,178, missing 70. The resume summary limits both label matrices to
completed rows, so unfinished individuals are not included in those counts.

All 28,056 saved trajectory comparisons are `original unavailable`. There are
no `*-paths-g*.mat` files in the source FullWP experiment folder. Classification
agreement therefore compares archived labels against newly simulated labels;
it does not verify coordinate agreement. The archived labels were not independently
recomputed in this review. Exact attribution of the 6,921 differences remains open.

Recalculated class counts by segment:

| Segment | Stable | Unstable | Missing |
| --- | ---: | ---: | ---: |
| 1 | 2,974 | 1,702 | 0 |
| 2 | 3,541 | 1,135 | 0 |
| 3 | 2,469 | 2,206 | 1 |
| 4 | 4,233 | 438 | 5 |
| 5 | 501 | 4,142 | 33 |
| 6 | 4,090 | 555 | 31 |

## Findings relevant to REMUS100

### 1. Segment continuation loses internal guidance/controller state

`runSubPathRemus100.m:103` clears `integralSMCheading` and `ALOS3D` on
every segment. `remus100path.m:3` clears them only once per entire route.
ALOS3D stores adaptive current estimates in persistent `alpha_hat` and
`beta_hat`; integralSMCheading stores its own persistent `psi_int`.
Those values are not part of the caller's workspace saved by `save`.
The similarly named local `psi_int` does not restore the controller's persistent
variable. Thus loading vessel state does not fully restore simulation state.

This is a strong explanation for divergence after the first segment, even with
identical decisions, environmental samples and initial vessel state. It has not
been quantified through replay. NPSAUV also resets the adaptive ALOS state at
every segment; it uses a different controller with explicitly saved integrals.

Do not simply remove the clears: incremental search evaluates branching candidate
segments. Each candidate needs an explicit copy of its selected parent's guidance
and controller state, independent of whichever candidate executed immediately before it.

### 2. The final subpath has a different endpoint for classification

`runSubPathRemus100.m:214` stops at the first sample inside R_switch.
The full simulator can continue after final arrival (its termination also depends
on R_switch/2 and a minimum simulation duration). `splitDataBetweenWaypoints.m:37`
appends all remaining samples to the final segment and moves its transition index
to the last simulated sample. Full-path class extraction uses those transitions.

Consequently the final classification can include substantial post-arrival motion,
while the validation classification ends at first arrival. Since the peak detector
uses autocorrelation of the whole segment, different windows can change the label
even if coordinates up to arrival match exactly.

### 3. Validation continues after a missed waypoint

`runValidation.m:165-242` continues its waypoint loop after an early-stopped,
unreached segment, using the unreached target as the next segment's nominal start.
The REMUS full-path simulator instead ends the entire route on divergence.
The full-path splitter stops looking for later waypoints when an earlier one is
not reached. These are different definitions of later-segment availability.
The state position itself is restored; the issue is the new target/guidance leg
and continuing a route that the full simulator would have terminated.

### 4. All three subpath simulators have a sample-budget off-by-one

They set N to the number of environmental columns and loop through N+1, but read
`environmentRandomValues(:,i)` inside that loop. The saved REMUS environment has
56,001 columns. Thus a subpath that reaches the final iteration attempts column
56,002. Full-path REMUS uses N=56,000 and loops through 56,001.
This is a latent out-of-range error, not an explanation for successfully completed
classification differences. Continuation after budget exhaustion also needs an
explicit empty-budget return rather than reusing variables from a loaded workspace.

## Other vessel-specific findings

- **NPSAUV and Mariner full-path early stopping is inactive.** Both set
  `stopSimulation=true`, but their exit conditions do not test that flag.
  Their subpath simulators do terminate on divergence. REMUS full-path does test it.
- **Mariner class inputs differ.** Its simdata layout starts with time, then
  `[u v r x y psi delta]`. `extractAnglesAndPath.m:9-15` takes columns
  `[1 2 3 4 7]`, i.e. `[time u v r psi]`. `runSubPathMariner.m:179` takes
  `[2 3 4 7 8]`, i.e. `[u v r psi delta]`. Full-path extraction is shifted and
  includes time while omitting rudder angle.
- **Mariner waypoint reach definitions differ.** Subpath success accepts the LOS
  switching event, whose criterion is along-track distance (`LOSchi.m`), while
  full-path splitting uses Euclidean distance on stored, un-noised positions.
  Switching to the next leg is not necessarily entering the waypoint sphere.
- **Mariner divergence tests differ.** Its subpath version tests positive
  differences between recent distances; the full-path version compares the current
  distance against all recent distances. These conditions are not equivalent.
- **Mariner validation is currently disabled.** The call to runSubPathMariner in
  runValidation is commented out; it would produce unavailable results.

## Validation/reproducibility issues

- Checkpoint matching checks inputs but not simulator/classifier source versions
  or the original classification file. Resuming after code changes can mix outputs
  from different implementations. Preserve this checkpoint as a historical run;
  use a separate output folder for corrected validation.
- Validation assumes 1,000 generations and population size 10. It does not yet
  support the newer variable-population experiment naming/loading rules.
- The original `classificiation.mat` is reused without a classifier version check.
  runValidation imports the Python peak module without explicitly reloading it.
  These are provenance risks; this review does not establish that either happened.
- In FullWPNoStopping's final detailed table, individual/waypoint IDs use
  individual-major ordering while `originalTypes(:)` and `newTypes(:)` use
  MATLAB column-major ordering. IDs are mislabeled in that table. This does not
  affect the FullWP resume totals reported here.
- setupProject recursively adds both standard and `withoutEarlyStopping` folders
  containing identically named functions. Explicitly recording resolved simulator
  paths is needed to know which implementation an actual MATLAB session used.

## Suggested correction and diagnostic order

1. Define one common segment endpoint: first arrival for all waypoint comparisons;
   keep post-final-arrival behavior as a separate metric if needed.
2. Make physical, guidance, observer and controller state explicit and serializable,
   and share the step logic between full-path and incremental simulation.
3. Standardize reachability, divergence stopping and environmental sample budgets.
4. Make validation stop/mark downstream segments consistently after failure, record
   implementation fingerprints and resolved function paths, and load actual run sizes.
5. Before another large validation, compare a small set of complete trajectories:
   first segment, first waypoint boundary, final arrival and a missing waypoint.
   Classify identical saved angle slices through both classification routes to
   separate classifier/window differences from dynamics differences.

Runtime verification remains pending the user's authorization to launch MATLAB.
