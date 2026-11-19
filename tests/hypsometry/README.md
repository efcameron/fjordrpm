# Hypsometry tests (FjordRPM, branch `fjord-hypsometry`)

Scripts used to verify the sill-position option `p.Gsill` (distance in metres
from the glacier front to the sill; default `p.L`, i.e. sill at the mouth).
Below sill depth, layers extend only from the glacier to the sill, so their
volume is `H * W * Gsill` instead of `H * W * L`.

Code lives here (version controlled). Outputs are kept **outside** the repo:

```
C:/Users/efc4/Documents/MATLAB/
  fjordrpm/             this repo (model code, examples, tests/hypsometry)
  fjordrpm_orig/        temporary copy of the ORIGINAL code (git worktree)
  fjordrpm_runs/
    results/            .mat outputs
    figures/            .png and .fig outputs
```

## Before running

1. **Run every script from this folder** (`cd .../fjordrpm/tests/hypsometry`).
   The comparison scripts take the new code off the MATLAB path while running
   the original code; MATLAB then finds the `setup_*.m` files only because they
   are in the current folder.
2. **The comparison scripts need the original code.** If `../fjordrpm_orig` does
   not exist, create it from the repo folder in Git Bash:
   ```bash
   git worktree add ../fjordrpm_orig baseline-before-hypsometry
   ```
   Remove it when no longer needed with `git worktree remove ../fjordrpm_orig`.
3. Folder paths are hard-coded (`C:/Users/efc4/...`). Change them at the top of
   each script if the folders move.
4. Scripts that switch code versions restore the path to the new code at the end.
   If one stops with an error part-way, run
   `rmpath(genpath('C:/Users/efc4/Documents/MATLAB/fjordrpm_orig')); addpath(genpath('C:/Users/efc4/Documents/MATLAB/fjordrpm')); clear functions`
   and check with `which -all run_model`.

## Files

### Shared helpers
| File | Purpose |
|---|---|
| `check_budgets.m` | Function. Step-by-step salt, heat and volume budgets for a run saved at **every** timestep (`p.t_save = t`). Prints a summary and returns residual time series. |
| `setup_example8.m` | Example 8 setup (synthetic depth-varying shelf, seasonal discharge, 15 yr) without `addpath` or run lines. Lines 14-88 of `examples/example8_synthetic_shelf.m`. |
| `setup_ex1.m` ... `setup_ex6.m` | Setups of the original examples 1-6, copied from `examples/` between the `addpath` and `run_model` lines (no path commands). |

### Tests, in the order they were run (2026-11-19)
| # | Script | What it does | Reads | Writes | Result |
|---|---|---|---|---|---|
| 0 | `../../examples/example8_synthetic_shelf.m` | Example 8 at Gsill = 60, 30, 15 km, dt = 0.2 d, 15 yr | - | `results/example8_Gsill{60,30,15}km.mat` | Basis for the timestep test and the sill comparison |
| 1a | `test_dt_15km.m` | Reruns the 15 km case at dt = 0.1 and 0.05 d | - | `results/example8_Gsill15km_dt0p1.mat`, `_dt0p05.mat` | |
| 1b | `plot_dt_test.m` | Timestep analysis: convergence ratios, comparison with the 15 vs 30 km difference, figures | runs from 0 and 1a | `figures/dt_test_15km_{S,T,bylayer,layer40_year5}.png` | First-order convergence (RMS ratios 1.7-1.9); largest differences are threshold events; dt = 0.2 d kept |
| 2 | `test_conservation.m` | Example 8, 3 yr, every step saved, Gsill = 60/30/15 km, `check_budgets` | - | `figures/conservation_example8.png` | Salt, heat, volume conserved to ~1e-15 |
| 3 | `test_vs_original_v2.m` | Original code vs new code (Gsill unset and Gsill = L) with the example 8 synthetic shelf | `setup_example8.m` | `results/compare_original_v2_synthetic_shelf.mat`, `figures/compare_original_v2_synthetic_shelf.png` | Identical: 0 of 46 output fields differ |
| 4 | `test_examples_all.m` | Examples 1-6 (+ example 3 with a sill): original vs new with the sill at the mouth; new code at Gsill = 60/30/15 km with `check_budgets` | `setup_ex*.m` | `results/stage4_examples.mat` | Identical to original in all 7 cases; budgets close to ~1e-15 |
| 5 | `original_vs_hypsometry_plots_allExamples.m` | Summary figures: end-of-run profiles, original vs new (with shelf), and the three sill positions | `setup_ex*.m`, `results/stage4_examples.mat` | `results/stage4_alignment.mat`, `figures/stage4_alignment_original.png`, `figures/stage4_sill_positions.png` | max diff = 0; sill positions physically sensible |

v1 of the comparison with the original (an earlier session) used the uniform
shelf of example 7 (`results/example7_baseline_ORIGINAL.mat`, protected: never overwrite).

### Earlier diagnostics
| File | Purpose |
|---|---|
| `plot_vertical_tracer_flux.m` | Plots vertical tracer (heat/salt) fluxes per layer from saved runs in `results/`. |
| `plot_vertical_volume_flux.m` | Plots vertical volume fluxes per layer from saved runs in `results/`. |
| `netVerticalVolumeFluxPerLayer.fig` | Saved figure (ignored by Git). |

## Notes
- `check_budgets.m` reports the unstable-layer mixing check relative to the size
  of the mixing; when mixing changes almost nothing (e.g. uniform salinity in
  example 6) this ratio is rounding noise and can look large. Relative to total
  content it is ~1e-17 (to be updated).
- Outputs (`*.mat`, `*.fig`, `*.png`) inside `tests/` are ignored by Git.
