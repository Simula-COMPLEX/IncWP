# Display route comparison results

Open runRemusComparison.m, runNspauvComparison.m or runMarinerComparison.m and Run.
Defaults: generation 1, individuals 1:10. Edit generations and individuals to
select available saved population rows. Generation 1 inputs are prepared for all
three vessels. No MATLAB simulations were launched while making these changes.

The Command Window shows one row per individual:

- Trajectory: positions and classification signals agree, with equal sample counts.
- Reachability: both simulations agree about reaching each segment's target.
- IncWPFitness: both trajectories scored with the incremental fitness formula agree.
- FullWPFitness: both trajectories scored with the original full-path formula agree.
- Verdict: PASS, FAIL, INCOMPLETE or ERROR.

PASS requires all checks to be available and pass (1e-8 absolute + relative
numerical tolerance). FAIL means a measured difference. INCOMPLETE means no known
failure but some required comparisons could not be made. ERROR means simulation
or fitness evaluation raised an error. Missing values are never treated as passes.
The final summary counts these outcomes and prints the overall comparison verdict.

PASS establishes agreement for the tested inputs, not physical correctness of the
vessel models or correctness for every possible route.

## No result files

Comparison results are no longer saved to MAT/CSV files. They remain in the MATLAB
workspace as results.routes, results.segments, results.fitness and results.summary.
Stopping MATLAB loses those unsaved results. Previously generated files are not
deleted. Incremental simulation still uses its existing temporary state files;
these are cleaned up after each route and are not retained as comparison results.

## Detailed metrics in the workspace

Segment metrics include position RMSE, maximum coordinate error, per-channel
signal RMSE, endpoint separation, both path lengths, sample counts, reachability
and fitness differences. Position/signal errors compare overlapping segment rows;
sample-count equality is checked separately, so a matching prefix cannot pass a
longer unmatched trajectory. AUV signals are roll/pitch/yaw (radians). Mariner
signals are u/v (m/s), r (rad/s), psi/delta (radians).

Route metrics include runtime (incremental includes its existing state-file IO),
coverage, mean segment position RMSE, maximum endpoint/coordinate differences and
complete-route path-length difference. Metrics are computed outside simulation timers.

The fitness table contains both objectives and their absolute differences, using
two explicitly labeled formulas. IncWP uses mean negative normalized segment
length and summed nominal-target displacement; failed simulated segments receive
-999999999 and unattempted segments remain NaN. FullWP uses the existing splitter,
evaluator and missing-path penalty unchanged. Their different normalization and
boundary rules are not conflated. Proximity should agree for identical waypoints.

These scripts evaluate the current simulator implementations. The full
simulators now initialize guidance on the current leg after each reset; runtime
agreement still needs to be checked with these scripts.

## Path type and the main display

The main overview now says SAME, DIFFERENT, UNAVAILABLE or ERROR for path type,
fitness, trajectory and reached waypoints. You only need to run your vessel's
run*Comparison.m script; the other files are functions used by that script.

Path type is now explicitly calculated for each simulated segment using the
existing calculate_number_of_peaks Python classifier and calculateNumberOfPeaks
MATLAB adapter: unreached = missing; reached with any positive peak count =
unstable; otherwise stable. Unattempted segments and classifier errors are not
counted as matching. This requires the same MATLAB Python/NumPy/SciPy setup as
existing analysis. Classifier errors are reported without discarding trajectory
and fitness comparisons. Classification happens outside simulation timers.

The default display is one compact row per individual: verdict, path-type match
count, fitness agreement, reached-target counts and first differing or unavailable
trajectory segment. Detailed errors, per-segment types and objective values are
available on demand. Path type can agree even when trajectories or fitness differ.

## Read an existing result without rerunning simulations

Run `displayVesselComparison(results)` for the compact overview, or
`displayVesselComparison(results, 1, 3)` for details of generation 1, individual 3.
Neither command runs simulations. Details include the actual path types, fitness
values and errors for that individual. Future batch runs use the compact display
automatically. A route-level failure means at least one mismatch, not that all
its waypoints differ. Waypoint 1 is the origin; segment 1 is 1 -> 2.
