# gbs-hr-codir

Refactored migration of Dataiku project "HR GBS Project" to Lakeflow Spark Declarative Pipelines, organised as a medallion architecture.

The **catalog is the environment** (DAB variable `${var.catalog}`, default = project catalog); the **schema** is the programme default (forçable per table); the **table name** carries the medallion layer (`bronze_`/`silver_`/`gold_`, forçable). Generated code uses 2-part `schema.table` names, so the same bundle deploys to any environment by overriding the catalog.

Each transformation file is a validated step: one or more Dataiku recipes fused into a single dataset. SQL files (default) hold one CTE per Dataiku recipe, plus a CTE reapplying the schema of each removed intermediate; Python files (code recipes) hold one `_<recipe>` function per recipe and `_conform()` for the intermediates.

## Target schemas
The pipeline creates its target schema on first run; to pre-create them, run in the target catalog:
- `CREATE SCHEMA IF NOT EXISTS brz;`
- `CREATE SCHEMA IF NOT EXISTS gld;`
- `CREATE SCHEMA IF NOT EXISTS raw_data;`
- `CREATE SCHEMA IF NOT EXISTS slv;`

## Pipelines & scripts (deployment order)
1. **TA Requisitions Dataset** — `gbs_hr_codir_ta_requ_data_5_pipeline`: 8 steps (24 Dataiku recipes)
2. **TA / jobreq_history Dataset** — `gbs_hr_codir_ta_jobr_hist_data_7_pipeline`: 2 steps (2 Dataiku recipes)
3. **TA Funnel Final** — `gbs_hr_codir_ta_funn_final_9_pipeline`: 5 steps (8 Dataiku recipes)
4. **TA Application Final** — `gbs_hr_codir_ta_appl_final_10_pipeline`: 4 steps (13 Dataiku recipes)
5. **CM holidays_2** — `gbs_hr_codir_cm_holi_2_11_pipeline`: 2 steps (1 Dataiku recipes)
6. **Payroll KPIs Touchless & compliance rate** — `gbs_hr_codir_payr_kpis_touc_14_pipeline`: 4 steps (2 Dataiku recipes)
7. **TA Time to Hire & Time to Shortlist** — `gbs_hr_codir_ta_time_to_hire_time_16_pipeline`: 5 steps (11 Dataiku recipes)
8. **Training KPIs Deployment 2026** — `gbs_hr_codir_trai_kpis_depl_2026_17_pipeline`: 4 steps (7 Dataiku recipes)

## Deploy
```bash
# dev target shown; override the catalog per environment with --var="catalog=<env>"
databricks bundle validate -t dev
databricks bundle deploy -t dev
# run everything (pipelines + script tasks) in dependency order:
databricks bundle run gbs_hr_codir_orchestration -t dev
```

## Accepted simplifications
- **200 final outputs not built by any scenario** — `Agregated-DSET-GSR-FOR-GBS_filtered`, `BaseCommune_for_GBS_GEPP_Prepared`, `BaseCommune_for_GBS_extract_richard_apprenticeship`, `BaseCommune_for_GBS_pre`, `BaseCommune_for_GBS_prep1` and 195 others are flow outputs but no Dataiku scenario builds them: probably one-off analyses or abandoned. Excluding them also removes their exclusive steps. Confirm with business users.
- **61 isolated elements in the flow** — `01092025_History_Positions_Celonisv2`, `20250923_Ref_All_Countries___SC_Div2`, `2026`, `29082025_History_Positions_Celonisv2`, `APPLICATION_FINAL_prepare_filtered` and 56 others are not connected to any recipe (neither produced nor read). These are often leftover from development or manual imports: exclude them from the migration.
- **5 identical recipes (shaker) on the same inputs** — `compute_BaseCommune_for_GBS_`, `compute_BaseCommune_for_GBS_prep`, `compute_BaseCommune_for_GBS_prepared`, `compute_BaseCommune_for_GBS_prepared3`, `compute_BaseCommune_for_worklocation` have exactly the same parameters and inputs: they produce the same data. Compute `BaseCommune_for_GBS_` once and the other outputs (`basecommune`, `Output_DS_Base_commune`, `BaseCommune_for_GBS_prepared3`, `BaseCommune_for_worklocation`) read from it.
- **4 identical recipes (shaker) on the same inputs** — `compute_user_information_prep`, `compute_user_information_prepared`, `compute_user_information_prepared1`, `compute_user_information_prepared2` have exactly the same parameters and inputs: they produce the same data. Compute `user_information_prep` once and the other outputs (`user_information_prepared`, `user_information_prepared1`, `user_information_prepared2`) read from it.
- **3 identical recipes (shaker) on the same inputs** — `compute_BaseCommune_for_GBS_prep1`, `compute_BaseCommune_for_GBS_prepared11`, `compute_BaseCommune_for_GBS_prepared9` have exactly the same parameters and inputs: they produce the same data. Compute `BaseCommune_for_GBS_prep1` once and the other outputs (`BaseCommune_for_GBS_prepared11`, `BaseCommune_for_GBS_prepared9`) read from it.
- **3 identical recipes (shaker) on the same inputs** — `compute_classes_prepared1`, `compute_classes_prepared4`, `compute_classes_prepared__1` have exactly the same parameters and inputs: they produce the same data. Compute `classes_prepared1` once and the other outputs (`classes_prepared4`, `classes_prepared_`) read from it.
- **2 identical recipes (shaker) on the same inputs** — `compute_Items_prep`, `compute_Items_prepared6` have exactly the same parameters and inputs: they produce the same data. Compute `Items_prep` once and the other outputs (`Items_prepared6`) read from it.
- **4 identical recipes (shaker) on the same inputs** — `compute_REQ_GBS_prepare`, `compute_REQ_GBS_prepared_1`, `compute_REQ_GBS_preped_for_application`, `compute_change_type_jobreqID` have exactly the same parameters and inputs: they produce the same data. Compute `REQ_GBS_prepare` once and the other outputs (`REQ_GBS_prepared`, `REQ_GBS_preped_for_application`, `change_type_jobreqID`) read from it.
- **2 identical recipes (shaker) on the same inputs** — `compute_holidays_prepared`, `compute_holidays_prepared_1` have exactly the same parameters and inputs: they produce the same data. Compute `holidays` once and the other outputs (`holidays_2`) read from it.
- **2 identical recipes (shaker) on the same inputs** — `compute_Items_prepared1`, `compute_Items_prepared_1` have exactly the same parameters and inputs: they produce the same data. Compute `Items_prepared1` once and the other outputs (`Items_prepared`) read from it.
- **2 identical recipes (shaker) on the same inputs** — `compute_REQ_FINAL_prepared`, `compute_REQ_FINAL_prepared_1` have exactly the same parameters and inputs: they produce the same data. Compute `REQ_FINAL_prepared` once and the other outputs (`REQ_FINAL_prepared_1`) read from it.
- **2 identical recipes (shaker) on the same inputs** — `compute_applications_gbs_ID_Stringed`, `compute_applications_gbs_prepare` have exactly the same parameters and inputs: they produce the same data. Compute `applications_gbs_ID_Stringed` once and the other outputs (`applications_gbs_prepare`) read from it.
- **2 identical recipes (shaker) on the same inputs** — `compute_Dataset_STARHR_MD_prepared`, `compute_Dataset_STARHR_MD_prepared_1` have exactly the same parameters and inputs: they produce the same data. Compute `Dataset_STARHR_MD_prepared` once and the other outputs (`Dataset_STARHR_MD_prepared_1`) read from it.
- **2 identical recipes (shaker) on the same inputs** — `compute_Dataset_STARHR_PY_prepared`, `compute_Dataset_STARHR_PY_prepared_1` have exactly the same parameters and inputs: they produce the same data. Compute `Dataset_STARHR_PY_prepared` once and the other outputs (`Dataset_STARHR_PY_prepared_1`) read from it.
- **2 identical recipes (shaker) on the same inputs** — `compute_Item_events_prep`, `compute_Item_events_prepared4` have exactly the same parameters and inputs: they produce the same data. Compute `Item_events_prep` once and the other outputs (`Item_events_prepared4`) read from it.
- **2 identical recipes (distinct) on the same inputs** — `compute_div`, `compute_ref_GBS_client_distinct_distinct` have exactly the same parameters and inputs: they produce the same data. Compute `div` once and the other outputs (`ref_GBS_client_distinct_distinct`) read from it.
- **2 Dataiku datasets on the same path** — `TO_Data_`, `TO_data` point to the same files: one ingestion is enough, others read from `TO_Data_`.
- **REF_POS_prepared2: empty Prepare recipe — read REF_POS directly** — `compute_REF_POS_prepared2` is a Prepare recipe with **0 steps** (verified: step_count = 0, active_step_count = 0). It copies `REF_POS` to `REF_POS_prepared2` without changing anything — a classic Dataiku placeholder created to "have a dataset in the right zone".

In the current plan this costs a whole dedicated SDP step (`step:REF_POS_prepared2`, a streaming table) whose only job is `SELECT * FROM bronze_ref_pos`.

Proposal: inline it, so the final step `step:REQ_FINAL` joins directly on the ingested `REF_POS` (bronze_ref_pos) for its `POSITION_CODE = POSITION_CODE` left join. The result is bit-for-bit identical because no transformation is removed — only a pass-through table.

Gain: 1 SDP step and 1 silver table less in the "TA Requisitions Dataset" scenario, and one less hop to maintain.

Caveat: `REF_POS` is also read directly by `compute_REF_POS_filtered` in the same scenario, so the bronze table is needed anyway — no extra ingestion is created by this change.
- **compute_app_req-v2: legitimate join (3 Req date columns) but add a uniqueness guard on REQ_FINAL.Job Req ID to prevent fan-out** — `compute_app_req-v2` is a LEFT JOIN of `application` with `REQ_FINAL` on `Job Req ID = Job Req ID` that takes only **3 columns** out of REQ_FINAL's 56: `Req Created Date`, `Req Posting Start Date`, `Req Assignment Date`. The 15 other columns of `APPLICATION_FINAL` all come from the application side.

This is the same shape as the decided item 7 (REQ_FINAL re-joined to recover a couple of columns), but here it is legitimate: those 3 requisition dates genuinely do not exist on the application side (I checked `applications_gbs`' 26 columns — none of them is a Req date), so the join is needed, not redundant. Verdict: keep.

Two points for the generated code:
1. Fan-out: `REQ_FINAL` is the output of `compute_REQ_FLAG_FILTER_GRP` in scenario "TA Requisitions Dataset" and nothing declares `Job Req ID` as a key. If `REQ_FINAL` holds more than one row per `Job Req ID`, this LEFT JOIN duplicates application rows. Mitigation to add to the step: a de-duplicating CTE `SELECT \`Job Req ID\`, \`Req Created Date\`, \`Req Posting Start Date\`, \`Req Assignment Date\` FROM req_final GROUP BY 1,2,3,4` — or, better, an explicit uniqueness expectation on `REQ_FINAL.\`Job Req ID\`` in the SDP pipeline so the pipeline fails loudly instead of silently inflating `APPLICATION_FINAL`. The fact that the flow elsewhere contains a dataset literally named `drop_duplicates_jobreq_id` suggests duplicate Job Req IDs are a known phenomenon in this project.
2. Type mismatch: `applications_gbs.\`Job Req ID\`` is typed INT in the source schema hints, `REQ_FINAL.\`Job Req ID\`` is BIGINT, and `APPLICATION_FINAL.\`Job Req ID\`` is BIGINT. Harmless in Spark (implicit widening), but worth an explicit CAST in the join CTE so the schema of the target table is stable.

Since only 3 narrow date columns are needed, reading `REQ_FINAL` here is cheap and does not justify splitting the scenario; the dependency on "TA Requisitions Dataset" is correct as declared.
- **FUNNEL_FINAL: the self-join on its own grandparent can be replaced by one window function (no join)** — Verified anti-pattern, same family as the decided item 6 on REQ_FINAL, but here it is a self-join.

What the Dataiku chain does:
1. `compute_RECRUITMENT_FUNNEL_Time_to_Staff` (WINDOW) reads `RECRUITMENT_FUNNEL_Filled_OnHold`, partitions by `Application ID`, and adds ONE genuinely new column: `sum(DaysInStatus)` -> `DaysInStatus_sum`. All 29 other aggregations are `value(...)`, i.e. the column carried unchanged. It also applies a post-filter `TemplateID contains '10'`.
2. `compute_RECRUITMENT_FUNNEL_Time_to_Staff_prepared` removes `DaysInStatus`, renames `DaysInStatus_sum` -> `Time To Staff- sum days`, parses `EmploymentDetailsMostRecentHireDate_formatted`, reorders.
3. `compute_FUNNEL_FINAL` RIGHT-joins that result back onto `RECRUITMENT_FUNNEL_Filled_OnHold` on (`Application ID`, `FunnelStatusCategory`) and selects only `Time To Staff` from the left side; the other 29 columns all come from `RECRUITMENT_FUNNEL_Filled_OnHold` (the grandparent), including `DaysInStatus`, which step 2 had deliberately removed.

So the join exists only to recover the columns the window/prepare pair had dropped or altered. The equivalent, join-free SQL over `RECRUITMENT_FUNNEL_Filled_OnHold`:

SELECT *, SUM(`DaysInStatus`) OVER (PARTITION BY `Application ID`) AS `Time To Staff` FROM silver_recruitment_funnel_filled_onhold

Gains: one shuffle/join and two intermediates removed from the step's SQL, 3 CTEs instead of a window + prepare + self-join.

TWO CORRECTNESS GUARDS, both to be settled before coding (this is why I propose `none` = advice for the code review, not an automatic rewrite):

(a) The RIGHT join changes the row set. The left side is filtered by `TemplateID contains '10'`; the right side is not. A RIGHT join keeps every `RECRUITMENT_FUNNEL_Filled_OnHold` row and leaves `Time To Staff` NULL where the Template filter excluded it. A plain window would compute `Time To Staff` for all rows. The faithful rewrite must therefore keep the filter inside the window, e.g.
SUM(CASE WHEN `TemplateID` LIKE '%10%' THEN `DaysInStatus` END) OVER (PARTITION BY `Application ID`) — and NULL out the result for rows that do not match. Also: `TemplateID` is NOT in `RECRUITMENT_FUNNEL_Filled_OnHold`'s 31 columns (it is dropped back at `compute_RECRUITMENT_FUNNEL_HASHED`, which does not select it from `GBS_RECRUITMENT_FUNNEL_distinct`). So the Dataiku window filters on a column that no longer exists at that point — the filter is very likely a silent no-op today. This must be confirmed with the business team: if the filter never fired, the simple window is exactly equivalent; if Dataiku resolved it somehow, results differ.

(b) Join granularity. The join key is (`Application ID`, `FunnelStatusCategory`) while the window partition is `Application ID` alone. If one application has several rows sharing the same `FunnelStatusCategory`, the join fans out (row duplication) whereas the window does not. Non-regression check: compare row counts of `FUNNEL_FINAL` before/after.

Also note a naming mismatch to resolve while coding: the join selects a column called `Time To Staff` but the upstream dataset exposes `Time To Staff- sum days` (and `FUNNEL_FINAL` publishes `Time To Staff` bigint). Keep the published name `Time To Staff`.
- **Funnel pre-join cleanup: 2 full-row DISTINCTs + 1 format fix — one is a needed guard, one is probably dead weight, one is missing** — Checked the three "pre-join cleanup" recipes fused into step `RECRUITMENT_FUNNEL_Filled_OnHold`. They are NOT the same logic, so there is no stack/group to apply — but two of the three are reducible in SDP SQL.

1. `compute_GBS_RECRUITMENT_FUNNEL_distinct` — DISTINCT on all 30 columns of `GBS_RECRUITMENT_FUNNEL` (full-row dedup, no key subset, no aggregation). => plain `SELECT DISTINCT *`.
2. `compute_REQ_HASH_distinct` — DISTINCT on both columns of `REQ_HASH` (`JobRequisition_jobReqId`, `JobRequisition_jobReqId_Hashed`): again full-row dedup. => plain `SELECT DISTINCT *`.
3. `compute_APP_HASH_format` — NOT a dedup at all: a single NumericalFormatConverter (inFormat=EN, outFormat=RAW) on one column of `APP_HASH`, to turn the hashed id into a raw number so it matches `GBS_RECRUITMENT_FUNNEL.ApplicationID`. Note `APP_HASH` is NOT deduplicated, unlike the other two.

Why the two DISTINCTs exist: both tables are LEFT-joined into `compute_RECRUITMENT_FUNNEL_HASHED` as lookups (`APP_HASH_format` on `ApplicationID = Application ID_hashed`, `REQ_HASH_distinct` on `JobRequisitionID = JobRequisition_jobReqId_Hashed`). A duplicated hash row would fan out the funnel. So the DISTINCT on `REQ_HASH` is a genuine correctness guard on the lookup side — keep it.

Two concrete simplifications:
(a) The DISTINCT on `GBS_RECRUITMENT_FUNNEL` is on the LEFT (driving) side of both joins, so it does not protect against fan-out; it only removes exactly-duplicated source rows. If the S3 extract `s3://<GBSHRCODIR>/gbsfunnel/managed/` is already unique per (`ApplicationID`, `FunnelStatusCategory`, `Build_Date`), this DISTINCT is dead weight: a full 30-column shuffle on the largest input of the scenario, on every refresh. Needs business confirmation of source uniqueness; if confirmed, drop it (noticeable cost saving, zero row-count change).
(b) `APP_HASH` is used as a lookup with NO dedup while `REQ_HASH` has one. That asymmetry is suspicious. If `APP_HASH` can contain a duplicated `Application ID_hashed`, the funnel silently duplicates rows. Recommend adding the same `SELECT DISTINCT` on `APP_HASH` as a correctness guard, or confirming with the business team that the hash extract is unique by construction. Either way, document the choice: this is a behaviour decision, not a pure refactor.

Verdict: (a) needs business confirmation; (b) correctness guard to confirm. No stack_same_logic merge is applicable — the three recipes act on three different schemas.
- **REF_POS: sampling-type filter recipe (2% ratio) and double read of the same source** — Two points on the position referential inside "TA Requisitions Dataset", both affecting `REF_POS`:

**1. A filter recipe that also carries a 2% sampling setting.** `compute_REF_POS_filtered` is a `sampling`-type recipe: `Filter: POSITION_LABEL ≥ 0` with `samplingMethod: FULL, maxRecords: -1, targetRatio: 0.02`. The active setting is FULL (no sampling), so the migration must translate **only** the `WHERE POSITION_LABEL >= 0` clause and must NOT carry the 0.02 ratio into the SDP SQL. Worth stating explicitly because a 2% sample silently applied to the position referential would corrupt `REQ_FINAL` row counts in a way that is hard to spot.

Also note the filter itself is semantically odd: `POSITION_LABEL` is a STRING in the source schema (`POSITION_LABEL STRING`) but is compared with `≥ 0`. In Dataiku this numeric comparison on a string column effectively keeps rows whose label parses as a non-negative number and drops non-numeric/empty labels. In Spark the cast behaviour differs (non-numeric becomes NULL → row dropped, which may or may not match). This must be reproduced deliberately, e.g. `WHERE try_cast(POSITION_LABEL AS DOUBLE) >= 0`, and the row count compared against Dataiku.

**2. `REF_POS` is read twice in the same scenario** — once raw by `compute_REF_POS_filtered` (for the position attributes join) and once via the empty pass-through `REF_POS_prepared2` (for the final `POSITION_CODE` join). A single bronze ingestion serves both, which the plan already does correctly; just make sure the generated bundle does not create two Auto Loader ingestions for the same S3 path `s3://<GBSHRCODIR>/refpos/managed/`.

Gain: no step removed — this is a correctness guard on the scenario's reference data, plus confirmation that one ingestion covers both reads.

To confirm with the business team: the intended meaning of the `POSITION_LABEL ≥ 0` filter (is it "keep positions with a numeric label" or a leftover?). If it is a leftover, removing it would simplify the step further — but that is a functional decision, not a migration one.
- **REQ_FINAL: the requisition source is joined back only to recover 2 columns it already had** — The final step of "TA Requisitions Dataset" re-joins `REQ_GBS_jobreqid_type` onto the chain that already derives from it:

`compute_REQ_DISTINCT_w_Position_joined_GID_Recruteur` = LEFT JOIN of `REQ_DISTINCT_w_Position_joined_prepared_joined` with `REQ_GBS_jobreqid_type` on `Job Req ID = Job Req ID`, and it only picks **2 columns** from the right side: `JobRequisition_closedDateTime` and `Recruiter  GID`.

Both columns already exist in `REQ_GBS` (the ingested source) and `REQ_GBS_jobreqid_type` is just that source with the `Job Req ID` type cast. They were lost earlier because the de-duplication group-by (`compute_dataset_REQ_GBS_PBI_w_HASH_by_Job_Req_ID_1` + `_min` renames) did not carry them through — so Dataiku had to fetch them back with a second join.

Proposal (advice for the SDP SQL, no structural change): in the rebuilt query, carry `JobRequisition_closedDateTime` and `Recruiter  GID` through the de-duplication CTE (as `min()`/`first()` aggregations like the other 30+ `_min` columns) instead of re-joining the requisition source at the end. One join disappears from the generated SQL and the final materialized view reads one input less.

Gain: 1 join removed in `step:REQ_FINAL`; the step's input list drops from 5 to 4 datasets, which makes the incremental refresh cheaper.

To verify before applying — this is why I set medium confidence: it is only strictly equivalent if `Job Req ID` is unique in `REQ_GBS_jobreqid_type`. If a requisition appears on several rows with different `Recruiter  GID` or `closedDateTime`, the current LEFT JOIN would fan out rows (and the later group-by on 55 columns would hide it), whereas an aggregation would pick one value. Check `count(*) vs count(distinct Job Req ID)` on `bronze_req_gbs` first; if duplicates exist, keep the join as-is.
- **Funnel sources (APP_HASH, GBS_RECRUITMENT_FUNNEL, REQ_HASH): append-only vs snapshot not verifiable — confirm before any Auto Loader switch** — The two steps of "TA Funnel Final" are currently materialized views, which is the correct default: both contain joins (and a window), so they need the whole input. The question is only whether the three S3 ingestions can be Auto Loader streaming tables (cheap, append-only) or must be full snapshot reloads.

What I can read from the specs:
- `APP_HASH` -> `s3://<GBSHRCODIR>/applications_gbs_distinct_hashed/managed/`, parquet, 2 cols, no partitioning declared, no `Build_Date`.
- `REQ_HASH` -> `s3://<GBSHRCODIR>/req_gbs_hashed/managed/`, parquet, 2 cols, no partitioning declared, no `Build_Date`.
- `GBS_RECRUITMENT_FUNNEL` -> `s3://<GBSHRCODIR>/gbsfunnel/managed/`, parquet, 30 cols, no partitioning declared, but it DOES carry a `Build_Date` column.

What this suggests (and what I could not verify):
1. All three are Dataiku *managed* paths under `/managed/`, i.e. rewritten by an upstream Dataiku job. A managed output is normally **overwritten in full** at each build, not appended. That points to snapshot-replace semantics, which Auto Loader handles badly (re-reading replaced files as "new", or missing deletions). I could not verify the write mode: the ingestion specs expose no partition dimension and no incremental flag, and the three connections still need their S3 root set (`needs_root: true`, prerequisite "S3 bucket set on Dataiku connection GBSHRCODIR").
2. `GBS_RECRUITMENT_FUNNEL.Build_Date` is the one real clue in favour of append-only: a build-stamp column usually means successive snapshots are stacked. But note the flow then applies a full 30-column `DISTINCT` on it (`compute_GBS_RECRUITMENT_FUNNEL_distinct`) and `Build_Date` is part of the DISTINCT keys — consistent with an accumulating history that needs deduplication. If it is indeed append-only per `Build_Date`, Auto Loader + a streaming table is the right pattern and the daily cost drops a lot.
3. The two hash tables (`APP_HASH`, `REQ_HASH`) are tiny 2-column lookups. Even if they are snapshot-replaced, ingesting them as full-refresh bronze tables costs almost nothing; do not over-engineer them.

Concrete recommendation, for the business/platform team to confirm (this is why confidence is low):
- Ask the owner of the upstream job how each of the three S3 prefixes is written: files appended per run, or prefix emptied and rewritten?
- If appended: `GBS_RECRUITMENT_FUNNEL` becomes an Auto Loader streaming table and the two downstream steps stay materialized views (joins/window) — that combination is valid and incremental refresh still works.
- If snapshot-replaced: keep all three as full-refresh bronze ingestions (current plan), do NOT switch to Auto Loader.
- Either way, also set the S3 roots in Migration > Sources, otherwise these three ingestions cannot be generated at all. By contrast `REQ_GBS` is already resolved to a Volume path (`/Volumes/hr_gbs_dev/raw_data/sources_ta/req_gbs/`, mapping validated) — the same treatment is needed for the funnel's three sources.
- **FUNNEL_FINAL step: dead date parse, abandoned "Time To Staff" date-diff definition, and a string/boolean drift to guard** — Found while reading the funnel chain: two dead computations and one type drift inside step `FUNNEL_FINAL`.

1. Dead date parse. `compute_RECRUITMENT_FUNNEL_Time_to_Staff_prepared` step 1 parses `EmploymentDetailsMostRecentHireDate_formatted` (format `yyyy/MM/dd`) into a new DATE column `EmploymentDetailsMostRecentHireDate_formatted_parsed`. That column exists in `RECRUITMENT_FUNNEL_TIME_TO_STAFF` (30 cols) but `compute_FUNNEL_FINAL` does not select it, and it is absent from `FUNNEL_FINAL` (32 cols). The only steps that consumed it (step 3 FilterOnDate, step 6 DateDifference, step 7 cleanup) are all DISABLED. So the parse is pure dead code -> do not translate it. Safe.

2. The whole "Time To Staff - date diff" group is disabled. Steps 5-8 of the same recipe (parse `RequisitionDateCreated_formatted`, compute the day difference to the hire date, drop the two helpers, reorder) are switched off, i.e. the ORIGINAL definition of "Time To Staff" as a date difference has been abandoned in favour of `SUM(DaysInStatus)`. Worth stating plainly in the migration notes so nobody "restores" it during the rewrite. This overlaps the already-decided item 10 on disabled Prepare steps, but the business meaning here is specific: `FUNNEL_FINAL.Time To Staff` is a SUM OF DAYS IN STATUS, not a date difference. Confirm the KPI definition with the TA business team.

3. Type drift on `JobRequisition_evergreen`, to guard in the SQL. The column is STRING in `REQ_date_parsed`'s contribution and in `RECRUITMENT_FUNNEL_Filled_OnHold` (string), becomes BOOLEAN in `RECRUITMENT_FUNNEL_TIME_TO_STAFF` (boolean), and is STRING again in `FUNNEL_FINAL`. The window recipe declares it as `type: string` with `value(...)`. Since the final join takes this column from `RECRUITMENT_FUNNEL_Filled_OnHold` (string), the published type is string and the boolean detour is an artefact of the CSV intermediate's schema inference. Action for the code: force `JobRequisition_evergreen` to STRING in the step that reapplies the removed intermediates' schema, otherwise Spark may publish `true`/`false` instead of the original source literals (e.g. `TRUE`/`FALSE`/empty). Same vigilance for `Application ID` (int) and `Requisition Id` (bigint).

4. Minor: two CSV intermediates (`RECRUITMENT_FUNNEL_Filled_OnHold`, `RECRUITMENT_FUNNEL_TIME_TO_STAFF`) are being removed/kept in a chain whose sources and sink are parquet. Dropping the CSV round-trips removes a known source of silent type inference changes — an argument in favour of the fusions already planned.
- **DS_Req_History: the LEFT JOIN on REQ_FINAL is a scope filter in disguise — rebuild it as a semi-join** — Scenario "TA / jobreq_history Dataset" (#7), step `step:DS_Req_History`, recipe `compute_JOBREQ-HISTORY_scope`.

What the Dataiku chain does:
- LEFT JOIN `JOBREQ-HISTORY` (left) with `REQ_FINAL` (right) on `Job Req ID` = `Job Req ID`.
- Selected columns: all 5 columns of `JOBREQ-HISTORY` (`Job Req ID`, `Requisition Status`, `Created By`, `Created Date`, `Business Unit`) plus exactly ONE column from `REQ_FINAL`, auto-renamed `Job Req ID_scope` (REQ_FINAL has no column of that name — its 56 columns include `Job Req ID`; the `_scope` suffix is Dataiku's duplicate-name suffix).
- The very next recipe `compute_DS_Req_History` step 0 `ColumnsSelector` removes `Business Unit` and `Job Req ID_scope`.

So no column of `REQ_FINAL` survives in `DS_Req_History` (final schema = `job requisition id`, `requisition status`, `created by`, `created date`). The join contributes nothing but row multiplication / presence testing. Two consequences for the rebuild:

1. Because it is a LEFT join, non-matching history rows are KEPT (with `Job Req ID_scope` NULL). It is therefore NOT currently a filter at all: the "scope" naming is misleading. If the business intent is "history of requisitions published in REQ_FINAL", the correct rebuild is `WHERE EXISTS (SELECT 1 FROM silver_req_final r WHERE r.`Job Req ID` = h.`Job Req ID`)` (semi-join) — but that CHANGES the result (drops orphan history rows). Needs business confirmation before changing.
2. If instead we must stay byte-identical, the join must still be a LEFT join, and critically it must not duplicate rows: `REQ_FINAL` is produced by `compute_REQ_FLAG_FILTER_GRP` and `Job Req ID` is expected unique there, but I could NOT verify uniqueness (no distinct/row-count evidence available in the flow metadata). If `Job Req ID` is not unique in `REQ_FINAL`, the LEFT JOIN fans out history rows and the current Dataiku output already contains those duplicates.

Recommended rebuild, identical-result and cheaper, with zero REQ_FINAL columns projected:
`FROM jobreq_history h LEFT SEMI JOIN` is NOT equivalent — instead keep a LEFT JOIN against a de-duplicated key set:
`LEFT JOIN (SELECT DISTINCT `Job Req ID` FROM silver_req_final) r ON r.`Job Req ID` = h.`Job Req ID``.
This is provably identical to the Dataiku output as long as `Job Req ID` is unique in `REQ_FINAL` (and it REMOVES accidental duplication if it is not — which the team should decide on), and it lets SDP read only one column of `REQ_FINAL` instead of 56.

Also note a type mismatch to guard: `JOBREQ-HISTORY`.`Job Req ID` is INT (bronze schema hint) while `REQ_FINAL`.`Job Req ID` is BIGINT. Dataiku joined them implicitly; the generated SQL should cast explicitly so the comparison does not silently change (`CAST(h.`Job Req ID` AS BIGINT)`).

Action: advice only (no structural change applied), because the three options differ in result. Verdict: needs business confirmation on whether orphan history rows (history lines for requisitions absent from `REQ_FINAL`) must be kept.
- **DS_Req_History: date parse MM/dd/yyyy hh:mm:ss a — AM/PM, locale and DATE truncation risks** — Scenario "TA / jobreq_history Dataset" (#7), recipe `compute_DS_Req_History`, Prepare step 3: `DateParser: Parse created date as date (MM/dd/yyyy hh:mm:ss a) → in place`, applied to the renamed column `created date` (source: `JOBREQ-HISTORY`.`Created Date`, typed STRING in the bronze schema hints).

Three correctness guards for the SDP SQL rebuild:

1. AM/PM is mandatory in this pattern. `hh` is the 1–12 clock and `a` the AM/PM marker. In Spark, `to_timestamp(col, 'MM/dd/yyyy hh:mm:ss a')` under the default (CORRECTED) timeParserPolicy returns NULL for any row whose marker is missing or localised (e.g. `PM` vs `p.m.`), and raises on malformed input in some configurations. Dataiku's own date parser is more tolerant and also accepts a 24-hour string silently. So rows that Dataiku parsed can become NULL in Databricks. Recommended: parse with an explicit fallback and count the nulls once against the Dataiku output, e.g.
`COALESCE(try_to_timestamp(`created date`, 'MM/dd/yyyy hh:mm:ss a'), try_to_timestamp(`created date`, 'MM/dd/yyyy HH:mm:ss'))`
and only then cast. Use `try_to_timestamp` so a bad row yields NULL instead of failing the pipeline.

2. Locale. The AM/PM marker is locale-dependent; the Databricks session must be English (default) for `a` to match `AM`/`PM`. If the SAP SuccessFactors extract ever emits a French marker, parsing silently yields NULL. Worth one check on the raw files.

3. Truncation to DATE loses the time. The target column `DS_Req_History`.`created date` is typed `date` (4-column schema: `job requisition id` bigint, `requisition status` string, `created by` string, `created date` date), so the parsed timestamp is truncated to the day. This matters for the downstream consumers in zone "Zone de travail": `compute_DS_Req_History_by_job_requisition_id` takes `max(created date)` and `compute_DS_Req_History_by_job_requisition_id_joined` re-joins on `created date_max = created date` to recover the latest status. Because the time is dropped, several status changes on the SAME day tie, and that join returns MULTIPLE rows per requisition — the "latest status" is non-deterministic today. The fix (keeping the full timestamp, or using a window `row_number()`) would change results and belongs to the owner of those downstream datasets, which are OUTSIDE this programme.

Verdict: correctness guard (point 1 and 2 must be implemented in the generated SQL); point 3 is a pre-existing ambiguity to report to the "Zone de travail" owners, not to fix here.

What I could not verify: the actual format of the raw values in `Created Date` (no data sample available through the flow metadata), so I cannot confirm whether the AM/PM marker is always present.
- **DS_Req_History must stay a table: 3 consumers in "Zone de travail" are outside this programme** — Confirmation note for the plan of scenario "TA / jobreq_history Dataset" (#7): `DS_Req_History` must indeed stay a real table (materialized view `raw_data.silver_ds_req_history`), and the two reasons are worth recording.

1. It is the scenario target, so it is published by construction.
2. It is read by THREE recipes, all in zone "Zone de travail" and all outside programme GBS_HR_CODIR:
   - `compute_DS_Req_History_by_job_requisition` — grouping by `job requisition id`, count + countDistinct of `requisition status`;
   - `compute_DS_Req_History_by_job_requisition_id` — grouping by `job requisition id`, max of `created date`;
   - `compute_DS_Req_History_by_job_requisition_id_joined` — LEFT JOIN of the previous aggregate back onto `DS_Req_History` on (`job requisition id`, `created date_max` = `created date`).
   None of these is owned by a scenario of this programme: they are FUTURE external consumers, to be migrated in another programme (or to keep reading the Dataiku copy during the transition).

Consequences for the DAB of this programme:
- Do NOT inline or drop `DS_Req_History`, and do not rename its columns beyond what the Dataiku Prepare does: the three downstream recipes reference the renamed names exactly (`job requisition id`, `requisition status`, `created by`, `created date`). The lower-case names with spaces must be preserved as-is in `silver_ds_req_history` (back-quoted identifiers), otherwise the future consumers break.
- The step is correctly typed materialized view, not streaming table: it contains a join with `REQ_FINAL` and reads an existing UC table, so incremental refresh on serverless is the right mode.
- Cross-scenario wiring to check at deploy: scenario #7 depends on "TA Requisitions Dataset" (#5) and reads `REQ_FINAL` as an external input. Both scenarios are in the same programme/DAB, so the orchestration job must run #5 before #7 — the declared `depends_on` already expresses this.

Verdict: safe / informational — no change to apply, this is a guard against a later "inline the target" simplification.
- **REQ_FINAL: flag column Time_To_Hire_Grp_flag is created then dropped in the same recipe** — In `compute_REQ_FLAG_FILTER_GRP` (final Prepare of `REQ_FINAL`) the steps are, in order:

- step 3 `FlagOnCustomFormula`: creates `Time_To_Hire_Grp_flag = if(and(Time_to_Hire_grpscope == 1, Time_to_Hire_grpdate == 1), 1, "")`
- step 8 `ColumnsSelector`: **removes** `Time_To_Hire_Grp_flag`

The column never leaves the recipe and is not in the published schema. Nothing else in the recipe reads it (steps 4-7 touch other columns).

Proposal (advice for the code, no structural change): when generating the SDP SQL for `step:REQ_FINAL`, do not emit this GREL formula at all. This is also the single translation risk flagged on that step ("1 Dataiku formula (GREL) to translate to Spark expressions") — dropping a dead formula removes the risk instead of re-implementing `and()` / empty-string semantics in Spark.

Gain: the one GREL-to-Spark risk on the scenario's final step disappears; a few lines of CTE less.

To verify before applying: confirm with the TA reporting team that `Time_To_Hire_Grp_flag` is not expected to reappear (it looks like work-in-progress Time-to-Hire logic, alongside the disabled `FlagOnDate` step). If they want it published, keep the formula AND remove it from step 8 — but that would be a functional change, not a migration one.
- **GBS_Employee join is an OR-join (not AND) with no uniqueness guarantee — real fan-out risk on APPLICATION_FINAL** — `compute_applications_gbs_distinct2_filtered_joined` joins the stacked application rows to `GBS_Employee_prepared` with TWO conditions — `Employee ID = SEZAME_ID` and `User Sys ID = USER_ID` — but `conditions_mode` is **OR**, not AND (the step summary and the plan explanation both render it as "AND", which is misleading).

Consequences to handle explicitly in the generated SDP SQL:
- The ON clause must be `ON (a.\`Employee ID\` = e.SEZAME_ID OR a.\`User Sys ID\` = e.USER_ID)`. Writing AND would silently drop most employee enrichment.
- An OR-join is a fan-out machine: one application row matches every employee row that agrees on EITHER key. `GBS_Employee` has no declared uniqueness on `SEZAME_ID` or `USER_ID`, and `GBS_Employee` rows carry `EVENT_REASON` / `STATUS_NAME` / `EVENT_REASON_NAME`, which strongly suggests it is an **event/history table with several rows per employee** rather than a 1-row-per-employee reference. If so, this LEFT JOIN multiplies application rows.
- The multiplication is partly masked downstream: `compute_application` (INTERSECT) and the deduplicating effect of the final projection can hide it, but `APPLICATION_FINAL` keeps `SEZAME_ID` and `USER_ID`, so duplicates would be visible.
- Also note NULL behaviour: with OR, an application with a NULL `Employee ID` but a matching `User Sys ID` still joins — that asymmetry must be preserved.

Requested before translation: run a quick count in Dataiku — `GBS_Employee` row count vs `COUNT(DISTINCT SEZAME_ID)` and vs `COUNT(DISTINCT USER_ID)`, and compare the row count of `applications_gbs_distinct2_prepared2_by_Application_ID_stacked` with that of `applications_gbs_distinct2_filtered_joined`. If they differ, the fan-out is real and the business team must say which employee row wins (latest `HIRE_DATE`? `STATUS_NAME = 'Active'`?). The clean Databricks form would then be a deduplicated employee lookup CTE (one row per key, chosen by an explicit rule) instead of the raw OR-join.

Additional note: `compute_GBS_Employee_prepared` is a Prepare recipe with **0 active steps** — a pure pass-through, same situation as the decided `REF_POS_prepared2` item. The plan already inlines it, so there is no extra gain to claim, but it confirms `GBS_Employee` can be read directly.
- **Programme GBS_HR_CODIR: silver/gold funnel tables land in schema `raw_data`, and the kept intermediate may become inlinable** — Two programme-level observations on "TA Funnel Final" (#9), not about a recipe's logic.

1. Target schema looks wrong for the silver/gold tables. The programme GBS_HR_CODIR is generating:
- `raw_data.silver_recruitment_funnel_filled_onhold`
- `raw_data.gold_funnel_final`
plus the bronze ingestions `raw_data.bronze_app_hash`, `raw_data.bronze_gbs_recruitment_funnel`, `raw_data.bronze_req_hash`, `raw_data.bronze_req_gbs`.
So silver and gold tables land in a schema named `raw_data`, next to bronze. The layer is correctly encoded in the table name, but putting published outputs in `raw_data` defeats the usual access-control split (raw readable by few, gold readable by BI consumers). Suggest setting the programme's default schema to something neutral (e.g. `ta_analytics`) and keeping only the bronze ingestions in `raw_data`, or forcing the schema on the two non-bronze tables. Purely a naming/governance decision — zero impact on results — but it is cheap to fix now and painful later once BI reports point at `raw_data.gold_funnel_final`.

2. `RECRUITMENT_FUNNEL_Filled_OnHold` is kept as a table for the right reason, and that is worth confirming rather than changing. The step explanation says "read by multiple recipes": it feeds `compute_RECRUITMENT_FUNNEL_Time_to_Staff` AND `compute_FUNNEL_FINAL` (6 downstream links in total). Note that if the self-join simplification I proposed separately is adopted, this dataset would drop to a SINGLE consumer — and could then itself be inlined into `FUNNEL_FINAL`, collapsing scenario #9 to 3 ingestions + 1 transform step (from 5 steps). That is the compounding gain: do not re-evaluate it in isolation, re-run the detectors after deciding on the self-join.

Also: the dataset's physical name is inconsistent in Dataiku (`RECRUITMENT_FUNNEL_FILLED` on S3 / metastore, `RECRUITMENT_FUNNEL_Filled_OnHold` as the flow name, and `FUNNEL_FINAL` sits at `dataset_funnel_kpi/managed/` with metastore name `GBS_RECRUITMENT_FUNNEL_TimeToShorlist`). The migration is a good moment to settle one name per table; flag for the team so dashboards get repointed knowingly.
- **GenderPrediction: no ML recipe in the funnel chain (ETL only) — and the column is dropped before FUNNEL_FINAL anyway** — Checked explicitly because the column name suggests a model output.

Result: there is NO ML recipe, no scoring recipe and no saved model anywhere in "TA Funnel Final" (#9). `GenderPrediction` appears as a plain STRING column in exactly three datasets, all ETL:
- `GBS_RECRUITMENT_FUNNEL` (S3 source, parquet) — arrives already computed, upstream of Dataiku
- `GBS_RECRUITMENT_FUNNEL_distinct` — carried through the full-row DISTINCT
- `RECRUITMENT_FUNNEL_HASHED` — explicitly selected by `compute_RECRUITMENT_FUNNEL_HASHED`

The scenario's 8 recipes are: 2 distinct, 3 join, 2 shaker (Prepare), 1 window. No training / scoring / evaluation step. So the prediction is produced OUTSIDE this flow and the ETL merely transports the column. Nothing to exclude from scope here, and the ML out-of-scope rule does not bite.

Worth flagging to the team, though, as a free simplification: `GenderPrediction` is DROPPED at the next recipe. `compute_RECRUITMENT_FUNNEL_FILLED` selects 28 columns from `RECRUITMENT_FUNNEL_HASHED` and `GenderPrediction` is not among them; it is absent from `RECRUITMENT_FUNNEL_Filled_OnHold` (31 cols) and from `FUNNEL_FINAL` (32 cols). So the column is carried through an ingestion, a 30-column DISTINCT and a double LEFT JOIN only to be discarded. In the SDP SQL for step `RECRUITMENT_FUNNEL_Filled_OnHold` it can simply not be selected from the start.

Two caveats before pruning it:
- It is a gender attribute (inferred). Carrying it into a Unity Catalog silver table has data-protection implications; dropping it early is the privacy-friendly option. Confirm with the business/data-protection owner that no consumer expects it.
- It must stay in the bronze ingestion of `GBS_RECRUITMENT_FUNNEL` if other zones use the raw table (this scenario is its only consumer inside the programme, but the raw S3 extract is shared).

Verdict: ML-scope check is clear (safe, nothing out of scope). Early drop of the column is safe technically, needs a one-line business confirmation.
- **Application min/max: the two group-bys are NOT a two-pass min/max — different filters and different keys, keep them as two separate aggregations** — Verification of the suspected "min/max in two passes" pattern in step `applications_gbs_distinct2_filtered_joined`. The two group-bys CANNOT be merged into one GROUP BY with MIN() and MAX(), because they do not read the same rows nor group on the same keys:

`compute_applications_gbs_distinct2_prepared2_by_Application_ID` -> `application_min_status`
- pre-filter: `Application ID <> 'Hireable' AND Application ID <> 'Hired'`
- 18 keys, including `Application Status Category`, `Application Created Date`, `Is Internal`
- aggregates: MIN(`Application Status Date`), MIN(`Application Status Date (Timestamp)`)

`compute_applications_gbs_distinct2_prepared2_by_Application_ID2` -> `application_max_status`
- pre-filter: `Application ID = 'Hireable' OR Application ID = 'Hired' OR Application ID = 'Interviews'`
- 17 keys: `Application Created Date` is NOT a key (it becomes MAX), `Application Status Category` IS a key
- aggregates: MAX(`Application Created Date`), MAX(`Application Status Date`), MAX(`Application Status Date (Timestamp)`)

So: disjoint-ish row populations (except `Interviews`, see below), and a key set that differs by one column. One single GROUP BY would be wrong.

Two real points for the code and for the business team:
1. The two filters are NOT complementary: `Application ID = 'Interviews'` satisfies BOTH (it is <> 'Hireable' and <> 'Hired', and it is = 'Interviews'). Interviews rows therefore go through both branches and appear TWICE in the UNION — once labelled `Interviews min` (set in `..._by_Application_ID_prepared` step 2) and once intended as `Interviews max`. This duplication looks deliberate (min and max of the interview window as two rows). It must be preserved exactly; the SDP SQL must use UNION ALL, not UNION — `compute_applications_gbs_distinct2_prepared2_by_Application_ID_stacked` is declared mode UNION, which in Dataiku vstack means plain concatenation (no dedup). If the generated code emits SQL `UNION`, these paired rows and any other legitimate duplicates would be silently deduplicated.
2. Values other than `Hireable`/`Hired`/`Interviews` only pass the first filter, so they only get the MIN treatment; nothing is lost.

Recommended refactoring (equivalent, 1 scan instead of 2): a single CTE over `applications_gbs_distinct2_prepared2` plus one `GROUP BY GROUPING SETS`-style pair of aggregations is NOT safe here; instead keep two CTEs (`min_branch`, `max_branch`) reading the same already-materialized input and `UNION ALL` them. Dataiku needed 2 datasets + 2 prepares + 1 stack = 5 objects; SDP needs 3 CTEs in one step. That gain is already captured by the plan — this note is a correctness guard, not an extra merge.

Caveat I could not verify: whether `Application ID` really holds status labels like 'Hired'/'Interviews' (the filters compare an ID column to status strings, and `compute_applications_gbs_distinct2_prepared2` step 4 also tests `Application ID = 'Default'`, `'Pre-screening'`, and `Job Req ID = 'Longlist'`). The column naming suggests the source columns are shifted/mislabelled (`applications_gbs` is read as headerless CSV, `header=false`). This is worth a dedicated check with the TA team before translation — if the header handling is wrong, every one of these rules is reading the wrong column.
- **Application Status 2 / Application Status Category: both if/then/else rules now documented — ready for code generation (2 guards to confirm)** — Both Prepare rules that Dataiku rendered as "If ? ? 0.0" have been read in Dataiku by the user and are fully documented. They are no longer an obstacle to code generation.

RULE 1 — builds `Application Status 2` in recipe compute_applications_gbs_distinct2_prepared2.
Original GREL: if(( contains(strval('Application Status'), 'Interview 1') ) || ( contains(strval('Application Status'), 'Interview 2') ) || ( contains(strval('Application Status'), 'Interview 3') ) || ( contains(strval('Application Status'), 'Interview 4') ), "Interviews", val('Application Status'))
SDP SQL: CASE WHEN `Application Status` LIKE '%Interview 1%' OR `Application Status` LIKE '%Interview 2%' OR `Application Status` LIKE '%Interview 3%' OR `Application Status` LIKE '%Interview 4%' THEN 'Interviews' ELSE `Application Status` END AS `Application Status 2`
Effect: collapses the four interview stages into a single label 'Interviews'; all other statuses pass through unchanged. strval() is Dataiku string coercion (no CAST needed if the column is already STRING); `contains` is substring matching, so LIKE '%...%' is faithful.

RULE 2 — builds `Application Status Category` in recipe compute_applications_gbs_distinct2_prepared2_by_Application_ID2_prepared. A 13-branch ORDERED if/else-if waterfall on `Application Status`, to be generated as one ordered CASE WHEN ... END:
 1. = 'Default' -> '02 - Submission'
 2. = 'Pre-screening' -> '03 - Resume Qualification'
 3. = 'Longlist' -> '04 - Longlist'
 4. = 'Phone Qualifications' -> '05 - Phone Qualifications'
 5. LIKE '%Shortlist%' -> '06 - Shortlist'
 6. LIKE '%Interview 1%' OR '%Interview 2%' OR '%Interview 3%' OR '%Interview 4%' -> '07 - Interviews'
 7. IN ('Offer Build - Up','Pending for Approval','Approved','Declined') -> '08 - Offer Build Up'
 8. LIKE '%Background Check%' -> '98 - Skipped -Background check'
 9. LIKE '%Offer Letter%' OR LIKE '%Sent%' OR LIKE '%Offer Declined%' -> '09 - Offer Letter'
10. = 'Hireable' -> '10 - Ready to Hire'
11. is not defined -> '#'
12. IN (19 closed values) -> '99 - Skipped - Closed': 'Hired On Other Requisition','Minimum Requirements Not Met','Requisition Closed','Lack of Availability','Not a Fit','Auto Disqualified','Declined Offer','Before shortlist','After Interview','After Offer','Declined DPCS','Withdrawn By Candidate','Withdrawn by Recruiter','Deleted On Demand By Candidate','Forwarded to an existing job requisition','Deleted On Demand By Admin','Linked to a Talent Pool','Hired','Arrival'
13. no final ELSE -> NULL

TRANSLATION GUARDS (carry into generated SQL):
- Branch order is load-bearing: generate one ordered CASE, never an unordered mapping or lookup table. The exact value 'Declined' must be caught by branch 7 ('08 - Offer Build Up') before branch 9 (LIKE '%Offer Declined%') and branch 12 ('Declined Offer','Declined DPCS'). Reordering or flattening silently changes results.
- '%Sent%' in branch 9 is a broad substring: any status containing "Sent" anywhere lands in '09 - Offer Letter'. Faithful to Dataiku; flagged for business sanity check.
- No final ELSE: statuses outside the 13 branches yield NULL, not a catch-all. Keep that behaviour; an SDP expectation counting NULL `Application Status Category` would surface new SuccessFactors statuses early.
- Literal spacing is preserved verbatim: '98 - Skipped -Background check' (missing space after the second hyphen, lowercase "check"); '08 - Offer Build Up' has no hyphen whereas the status value 'Offer Build - Up' does. BI may filter on exact literals.

TWO REMAINING CONFIRMATIONS (these are the only open points; they do not block documenting the rules):
 (a) branch 11 "is not defined": translate as `IS NULL OR = ''` rather than IS NULL alone, since Dataiku's "is not defined" covers NULL and empty string and empty strings are likely here given the CSV source-format issue on applications_gbs. User confirmation pending.
 (b) the two group-by pre-filters were reported as testing `Application ID` with values 'Hireable'/'Hired'/'Interviews'. Those values belong to the status domain, and 'Interviews' is produced ONLY by RULE 1 into `Application Status 2`. If the filters genuinely read `Application ID`, the 'Interviews' branch never matches and those rows are silently dropped from the max-status group-by. To verify in Dataiku.

Link to the INTERSECT blocker (agent_none:683882ac6d): `Application Status Category` is one of the 19 columns compared by the INTERSECT in compute_application, and RULE 2 rewrites it upstream — which is part of why an exact-match INTERSECT would return almost nothing.
- **WINDOW compute_RECRUITMENT_FUNNEL_Time_to_Staff: ORDER BY FunnelStatusCategory is non-deterministic (and unused)** — Verification of the window's determinism, which matters for incremental refresh of the `FUNNEL_FINAL` materialized view.

Window definition as read in the recipe:
- PARTITION BY: `Application ID` (single column)
- ORDER BY: `FunnelStatusCategory` ascending (single column, no tie-breaker)
- No frame specified
- Aggregations: `sum` and `value` on `DaysInStatus`; `value(...)` on 28 other columns
- Post-filter: `TemplateID contains '10'`

Findings:
1. The ordering is NOT deterministic. `FunnelStatusCategory` is a low-cardinality status label (it is also one of the two join keys downstream), so many rows of the same `Application ID` share the same value. With no secondary sort column, ties are broken arbitrarily by the engine.
2. The only aggregate that actually consumes the order would be a frame-sensitive one. Here the single real computation is `SUM(DaysInStatus)`, which with no frame is an unbounded partition sum: order-independent. The 29 `value(...)` entries, however, ARE order-sensitive in Dataiku semantics (they pick a row of the partition). In practice the downstream join discards all of them except `Time To Staff`, so the non-determinism does not reach `FUNNEL_FINAL` today — but only because of that lucky discard.
3. Consequence for Databricks: if the chain is rewritten as the join-free window I propose separately, `SUM(DaysInStatus) OVER (PARTITION BY Application ID)` needs no ORDER BY at all. Drop the ORDER BY rather than translating it. That removes the non-determinism at the source and makes the materialized view's incremental refresh stable and reproducible.
4. If the team insists on keeping the literal window-plus-join translation, the ORDER BY must be made total (add a deterministic tie-breaker, e.g. `Application Date_parsed`, then `Requisition Id`) — otherwise two refreshes of the same data can produce different `value(...)` picks.

Verdict: safe to drop the ORDER BY for the sum. Any decision to keep `value(...)` columns from the window instead of the grandparent requires an explicit deterministic ordering agreed with the business team.
- **APPLICATION_FINAL: sampling artefact (targetRatio 0.02) on the applications filter — same pattern as the decided REF_POS item** — The recipe `compute_applications_gbs_distinct2_filtered2` (step `applications_gbs_distinct2_prepared2`, scenario "TA Application Final") is a Dataiku *sampling* recipe. Its business condition is only `Application ID not empty`, but it also carries a sampling block: `samplingMethod = FULL`, `targetRatio = 0.02`, `maxRecords = -1`, `ascending = true`.

This is exactly the artefact already decided for `REF_POS` (item 6): a 2% ratio left over from an interactive/design-time sample. With `samplingMethod = FULL` and `maxRecords = -1` the ratio is normally NOT applied at build time, so the generated SDP SQL should be a plain `WHERE \`Application ID\` IS NOT NULL AND \`Application ID\` <> ''` with no `TABLESAMPLE` / `LIMIT`.

Action requested: confirm with the TA business team that `APPLICATION_FINAL` is indeed built on 100% of `applications_gbs` (compare the row count of `APPLICATION_FINAL` in Dataiku against the full source). If the Dataiku build really ran at 2%, the Databricks table will legitimately contain ~50x more rows and the two are NOT comparable — which would invalidate any row-count reconciliation test on this scenario.

Also note the empty-string semantics: in Dataiku "not empty" excludes both NULL and `''`. The generated code must keep both conditions, otherwise rows with an empty-string Application ID would survive and reach the two group-bys (where `Application ID` is a grouping key), changing the output.
- **compute_application: INTERSECT of a dataset with its own parent — implicit DISTINCT risk, intent must be confirmed** — `compute_application` (step `APPLICATION_FINAL`) is a Dataiku vstack with `mode = INTERSECT` between:
- `application_arrival` (output of `compute_application_renamed`, schema_from = `application_renamed`)
- `applications_gbs_distinct2_filtered_joined` — which is `application_arrival`'s OWN PARENT.

So it intersects a dataset with a transformed version of itself, on 19 selected columns (`Job Req ID`, `Application ID`, `Application Created Date`, `Application Status Category`, `Application Status 2`, `Application Status Date`, `Application Status Date (Timestamp)`, `GID`, `Employee ID`, `User Sys ID`, `Candidate ID`, `External Candidate User ID`, `Hired On`, `Expected Start Date`, `Source`, `Source Details`, `GENDER`, `EMPLOYEE_CLASS`, `POSITION_ID`).

Two serious issues:

1) The intersect is almost certainly not doing what the author thinks. `compute_application_renamed` does NOT just rename: it (a) computes `Arrival` from `HIRE_DATE` when `Application Status Date >= 2025-03-20 AND Application ID = 'Hired'`, (b) REMOVES rows where `Arrival` is empty, (c) does a Multi-column fold on `Application Status Date` / `Application Status`, (d) drops `Arrival`, `EVENT_REASON`, `EVENT_REASON_NAME`, `STATUS_NAME`, `Job Start Date`, `First Name` (+2), (e) overwrites `Application Status Date (Timestamp)` with `Application Status Date`, (f) rewrites `Application Status Category` to `'99 - Skipped - Closed'` when `Application ID` contains 'Arrival'. After (b) + (e) + (f), the "arrival" rows are heavily rewritten, so intersecting them with the untouched parent should return very few rows — or the intersect is in fact being used as a UNION-like "add the arrival rows" and the mode is a mistake. **This must be confirmed with the business team before translation**: INTERSECT vs UNION ALL here changes the row count of `APPLICATION_FINAL` radically.

2) INTERSECT in SQL carries an **implicit DISTINCT** (set semantics), unlike Dataiku's row-wise stack modes. If the generated SDP SQL uses `INTERSECT`, duplicate rows that exist in the Dataiku output will collapse. In particular the deliberate `Interviews min` / `Interviews max` row pairs produced upstream (see the min/max note) differ on `Application Status` — but `Application Status` is NOT in the 19 selected columns; only `Application Status 2` is. Two rows that differ only by `Application Status` would therefore become identical on the projected columns and be merged by `INTERSECT`. Use `INTERSECT ALL` to reproduce Dataiku's multiplicity, or materialise the intersect as a semi-join (`WHERE EXISTS`) on the 19 columns if the business intent is "keep the arrival rows that also exist unchanged in the parent".

Correctness guard, not a simplification: the step currently declares 0 risks and the plan is still PROPOSED. I recommend this step is not translated until the INTERSECT intent is confirmed in writing.
- **DS_Req_History: "Requisition Status not empty" is filtered twice — keep one filter** — Scenario "TA / jobreq_history Dataset" (#7), step `step:DS_Req_History`: the condition "Requisition Status not empty" is applied twice on the same column, with nothing in between that could re-introduce empty values.

- `compute_JOBREQ-HISTORY_scope` — post-join filter, mode AND, single condition `Requisition Status not empty string 0`.
- `compute_DS_Req_History` — Prepare step 1 `RemoveRowsOnEmpty: Remove rows where Requisition Status is empty` (applied after step 0 which only drops `Business Unit` and `Job Req ID_scope`, so the column and its values are untouched).

The LEFT JOIN cannot create new rows with an empty `Requisition Status`: that column comes from the left table `JOBREQ-HISTORY` only, and a non-matching left row keeps its own value. The second filter is therefore a strict no-op and only one `WHERE` clause is needed in the fused SDP SQL step.

One nuance the team should be aware of rather than a risk: Dataiku's "not empty string" and "RemoveRowsOnEmpty" both treat NULL and the empty string `''` as empty, and Dataiku also trims nothing by default — so the faithful SQL guard is
`WHERE `Requisition Status` IS NOT NULL AND `Requisition Status` <> ''`
(not simply `IS NOT NULL`). Whitespace-only values such as `' '` are NOT removed by Dataiku, so do not add a `TRIM()` — that would change the result.

Verdict: safe — keep a single filter, with the NULL-or-empty-string semantics above. No business confirmation needed. Gain: 1 redundant CTE/filter removed from the generated step (no table or step saved, the two recipes were already fused).
- **Application chain: employee columns and First/Last Name carried through group-bys and joins then dropped; dead parse of Job Start Date; Is Internal unexplained in the target schema** — Dead weight found in step `APPLICATION_FINAL` and the step before it — columns that are computed, carried through a join, then dropped before the target.

1. `compute_GBS_Employee_prepared`'s join brings 9 columns from `GBS_Employee`, but `compute_application_renamed` then drops `EVENT_REASON`, `EVENT_REASON_NAME`, `STATUS_NAME` and `Job Start Date`, and `HIRE_DATE` survives only long enough to feed the `Arrival` rule (step 0) before `Arrival` itself is dropped at step 3. `APPLICATION_FINAL`'s 25 columns keep only `GENDER`, `EMPLOYEE_CLASS`, `POSITION_ID`, `SEZAME_ID`, `USER_ID` from the employee side. The SDP SQL should project only those 5 plus `HIRE_DATE` (needed transiently) in the join CTE — same pattern as the decided item 13 (`Time_To_Hire_Grp_flag` created then dropped).

2. `First Name` and `Last Name` are grouping keys in BOTH group-bys and are carried through the stack and the join, then dropped by `compute_application_renamed` step 3. They are never in `APPLICATION_FINAL`. They cannot simply be removed from the grouping keys, though — dropping a key changes the grain and could merge rows. Verdict: keep them as keys (correctness), but do not project them past the stack.

3. `Is Internal` is a grouping key in both branches and appears in `APPLICATION_FINAL` (typed boolean) — but it is NOT in the 19 columns selected by the INTERSECT `compute_application`, nor in the 15 columns selected from `application` by `compute_app_req-v2`. Yet the target schema lists `Is Internal boolean`. I could not reconcile this: either the column survives through the Multi-column fold in a way the metadata does not show, or the target schema is stale. **This needs checking in Dataiku** — if `Is Internal` is genuinely in the built table, one of the projections is under-reported and the generated SQL would be missing a column.

4. `compute_applications_gbs_distinct2_prepared2` step 0 parses `Job Start Date` as a date, and `Job Start Date` is dropped at `compute_application_renamed` step 3 without ever being used — a dead date parse, same as decided item 9 on the funnel step.

Gains: smaller shuffles in the two materialized views, no change to the target schema (except point 3, to be clarified). Low risk for 1 and 4, no action for 2, blocker for 3.
- **GBS_Employee: last unresolved source of the programme (needs_root) — blocks the DAB; consider mapping to an existing UC table instead of a new bronze ingestion** — `GBS_Employee` is the last source of programme GBS_HR_CODIR that is still unresolved: `needs_root = true`, `mapping_status = null`, path `s3://<GBSHRCODIR>/gbs_employee/managed/` (parquet, 10 columns), prerequisite "S3 bucket set on Dataiku connection `GBSHRCODIR`: set its root (s3://bucket/prefix) in Migration > Sources tab". Every other source in the programme (`applications_gbs`, `REF_POS`, `REF_WL`, `Ref_SOA`, `Recruiting_Route_Map`, `Organisation_Staffing_France`) is already resolved to `/Volumes/hr_gbs_dev/raw_data/sources_ta/...` and validated, and `REQ_GBS` is mapped to the existing table `hr_gbs_dev.raw_data.bronze_req_gbs`.

Blocker: the DAB cannot be generated with a usable ingestion for `GBS_Employee` until the bucket root is filled in. Two ways out, to be decided by the platform owner:
1. Same pattern as its siblings — if the parquet files are (or can be) landed under `/Volumes/hr_gbs_dev/raw_data/sources_ta/gbs_employee/`, declare it there and the Auto Loader ingestion is consistent with the rest of the programme.
2. If an employee table already exists in Unity Catalog (very likely, given `REQ_GBS` was matched at 0.895 to `hr_gbs_dev.raw_data.bronze_req_gbs`), map `GBS_Employee` to that existing table in mode `existing` instead of creating a bronze copy — one fewer ingestion in the programme.

Also inconsistent and worth fixing in the same pass: `GBS_Employee`'s target is `gbshr_ta_dev.brz.bronze_gbs_employee` while its ingestion spec writes `gbshr_ta_dev.raw_data.bronze_gbs_employee`, and the silver/gold tables of this programme land in schema `raw_data` (already flagged as decided item 14). Aligning catalog/schema for this source at the same time avoids a second review round.

I could not verify option 2 myself: the tool gives no match candidate for `GBS_Employee`, so the existence of a UC employee table has to be checked in the workspace.
- **applications_gbs read by both scenarios but with complementary filters — no duplicated distinct, no shared silver table needed (measure whether the 26-column DISTINCT is a no-op)** — I checked whether the full-row DISTINCT on `applications_gbs` is duplicated across the two scenarios, as suspected. Conclusion: **it is not** — the two readers do different things, so no shared silver table is warranted on that basis.

- Scenario "TA Application Final": `compute_applications_gbs_distinct2` is a DISTINCT on all 26 columns of `applications_gbs`, then `Application ID not empty`, then the Prepare.
- Scenario "TA Requisitions Dataset": `compute_req_sans_app` (inside step `REQ_DISTINCT_w_Position_joined_prepared`) reads `applications_gbs` with the **opposite** pre-filter `Application ID is empty`, INNER-joins it to `REQ_GBS_jobreqid_type` on `Job Req ID`, and selects a single column (`REQ_GBS_jobreqid_type.\`Job Req ID\``) — it is a semi-join used to flag requisitions without application (`REQ_FINAL.\`Req Without Application\``). No DISTINCT, complementary filter, different output.

So the two scenarios read `applications_gbs` twice but with disjoint row sets and incompatible shapes. Keeping two independent reads of the bronze table is the right design; a shared silver "clean applications" table would help neither.

Two genuine observations instead:
1. The full-row DISTINCT on all 26 columns is a full shuffle of the largest source in the programme, and it is a no-op if `applications_gbs` has no exact duplicate rows. Worth measuring once (`COUNT(*)` vs `COUNT(*)` after DISTINCT): if the counts match, the DISTINCT can be dropped from the step and the materialized view becomes substantially cheaper. Needs business/data confirmation — if duplicates do exist, removing it changes the group-by results.
2. `compute_req_sans_app` uses `Application ID is empty` on a column that scenario #10 immediately filters as `not empty`, and both scenarios read the same bronze table. These two filters together partition the source, which is a good consistency check: `rows(Application ID empty) + rows(Application ID not empty) = rows(applications_gbs)`. Worth adding as an SDP expectation in the programme so a change of header handling on this headerless CSV (`header = false`) is caught immediately.
- **compute_application_renamed: hardcoded cut-over date 2025-03-20 drives a row-removing filter — parameterise it and fix the string/date comparison** — `compute_application_renamed` (step `APPLICATION_FINAL`, scenario "TA Application Final") step 0 contains a **hardcoded date literal**: `If Application Status Date >= [column] 2025-03-20 AND Application ID = 'Hired' then Arrival = column HIRE_DATE`.

This is a business cut-over date baked into the transformation: only applications whose status date is on or after 2025-03-20 get an `Arrival` derived from `GBS_Employee.HIRE_DATE`. Step 1 then **removes every row where `Arrival` is empty**, so this literal decides which rows survive into `application_arrival` and therefore into the INTERSECT.

Points to settle with the TA business team before translation:
- Is 2025-03-20 a permanent business rule (e.g. the go-live of a new arrival process) or a temporary backfill guard that should now be removed or moved forward? If it is temporary, the migrated pipeline will silently keep applying it forever.
- The rule is rendered as `>= [column] 2025-03-20`, which suggests the comparison may be against a column rather than a constant. If it is truly a literal, it should become a pipeline parameter / SDP configuration value (`${var.arrival_cutover_date}`) rather than a hardcoded string, so it can be changed without editing SQL.
- `Application Status Date` is typed STRING in `APPLICATION_FINAL` but was parsed as a date upstream (`compute_applications_gbs_distinct2_prepared2` step 0, format `MM/dd/yyyy`); a string-vs-date comparison against `2025-03-20` would compare lexicographically and give wrong results if the value is still in `MM/dd/yyyy` form. This is the same string/date drift already decided as item 9 for the funnel. The generated SQL must compare two DATEs explicitly.

Verdict: needs business confirmation + a correctness guard on the type. Not a simplification on its own, but it is the single most result-changing line in the new scenario.
- **Change-data-capture candidate — `Registrations_financial_details_prepared_distinct`** — `Registrations_financial_details_prepared_distinct` looks like a 'keep latest per key' pattern (deduplicates keys from an append-only source). On Databricks this is best expressed as an AUTO CDC streaming table — KEYS (ID, User ID, Class ID, Registration Status, Registration Date, Registration Date_formatted, Enrollment Seat ID, FIRST_NAME, LAST_NAME, USER_ID, SENIORITY, SENIORITY_BRACKET, LE_ID, BU_ID, COST_CENTER_ID, GLOBAL_EMPLOYEE_LEVEL, EMPLOYEE_CLASS, CONTRACT_TYPE, POSITION_ID, DIVISION_ID, SEZAME_ID, MANAGEMENT_ENTITY, SIRET, REF_LE_NAME, REF_BU_NAME, REF_POSITION_NAME, REF_DIVISION_NAME, Payment Method, Charged Amount, Refund Amount, Currency Code, Transaction), SEQUENCE BY Registration Date, SCD type 1 — rather than a full rebuild. Confirm the key and the ordering column with the business before applying.
- **2 identical recipes (shaker) on the same inputs** — `compute_REF_POS_prepared2`, `compute_REF_POS_prepared_for_soazig` have exactly the same parameters and inputs: they produce the same data. Compute `REF_POS_prepared2` once and the other outputs (`REF_POS_prepared_for_soazig`) read from it.
- **2 identical recipes (shaker) on the same inputs** — `compute_Dataset_SAP_HCM_Chile_prepared`, `compute_Dataset_SAP_HCM_Chile_prepared_1` have exactly the same parameters and inputs: they produce the same data. Compute `Dataset_SAP_HCM_Chili_prepared` once and the other outputs (`Dataset_SAP_HCM_Chili_prepared_1`) read from it.
- **2 identical recipes (shaker) on the same inputs** — `compute_Dataset_ADP_Northam_prepared`, `compute_Dataset_ADP_Northam_prepared_1` have exactly the same parameters and inputs: they produce the same data. Compute `Dataset_ADP_Northam_prepared` once and the other outputs (`Dataset_ADP_Northam_prepared_1`) read from it.
- **2 identical recipes (shaker) on the same inputs** — `compute_Dataset_SAP_HCM_Mexico_prepared`, `compute_Dataset_SAP_HCM_Mexico_prepared_1` have exactly the same parameters and inputs: they produce the same data. Compute `Dataset_SAP_HCM_Mexico_prepared` once and the other outputs (`Dataset_SAP_HCM_Mexico_prepared_1`) read from it.
- **2 identical recipes (shaker) on the same inputs** — `compute_REQ_ENGIE_prepared1`, `compute_REQ_ENGIE_prepared1_1` have exactly the same parameters and inputs: they produce the same data. Compute `REQ_ENGIE_prepared1` once and the other outputs (`REQ_ENGIE_prepared1_1`) read from it.
- **2 identical recipes (shaker) on the same inputs** — `compute_REQ_GBS_jobreqid_type`, `compute_REQ_GBS_Transform_String` have exactly the same parameters and inputs: they produce the same data. Compute `REQ_GBS_jobreqid_type` once and the other outputs (`REQ_GBS_Transform_String`) read from it.
- **2 identical recipes (shaker) on the same inputs** — `compute_Registrations_financial_details_prepared`, `compute_Registrations_financial_details_prepared1` have exactly the same parameters and inputs: they produce the same data. Compute `Registrations_financial_details_prepared` once and the other outputs (`Registrations_financial_details_prepared1`) read from it.
- **8 disabled Prepare steps in 3 recipes** — These steps (`compute_RECRUITMENT_FUNNEL_Time_to_Staff_prepared`, `compute_REQ_FLAG_FILTER_GRP`, `compute_dataset_REQ_GBS_PBI_w_HASH_by_Job_Req_ID_prepared_1`) are disabled in Dataiku: they are not migrated.
- **Stacking of 6 branches with identical logic — `compute_Dataset_STARHR_FINAL_prepared_prepared_distinct_stacked`** — The branches stacked by `compute_Dataset_STARHR_FINAL_prepared_prepared_distinct_stacked` apply the same transformation (distinct) to different inputs. On Databricks: union the inputs first, then apply the transformation once.
- **Stacking of 2 branches with identical logic — `compute_Dataset_brut_LG10_joined_filtered_by_matcle_stacked_1`** — The branches stacked by `compute_Dataset_brut_LG10_joined_filtered_by_matcle_stacked_1` apply the same transformation (shaker) to different inputs. On Databricks: union the inputs first, then apply the transformation once.
- **Stacking of 2 branches with identical logic — `compute_Dataset_STARHR_FINAL_prepared_stacked_joined_prepared_stacked`** — The branches stacked by `compute_Dataset_STARHR_FINAL_prepared_stacked_joined_prepared_stacked` apply the same transformation (shaker) to different inputs. On Databricks: union the inputs first, then apply the transformation once.
- **Stacking of 2 branches with identical logic — `compute_Dataset_brut_LG10_joined_filtered_by_matcle_stacked`** — The branches stacked by `compute_Dataset_brut_LG10_joined_filtered_by_matcle_stacked` apply the same transformation (shaker) to different inputs. On Databricks: union the inputs first, then apply the transformation once.
- **Stacking of 2 branches with identical logic — `compute_LMS_extract_for_belgium_filtered_prepared_stacked`** — The branches stacked by `compute_LMS_extract_for_belgium_filtered_prepared_stacked` apply the same transformation (shaker) to different inputs. On Databricks: union the inputs first, then apply the transformation once.
- **5 Sync recipes (copies without transformation)** — `compute_DS_Deploiement_partition_Back-up`, `compute_DS_lot4`, `compute_DS_lot4_classes`, `compute_Instructors_copy`, `compute_dset_Bilan_2025` only copy a dataset (often to change storage). In a fused step they disappear; when their output stays a table, it's just a `SELECT *`.

## To handle
- Step `REF_POS_prepared2`: last translation failed.
- Step `REQ_GBS_jobreqid_type`: last translation failed.
- Step `REQ_DISTINCT_w_Position_joined_prepared`: last translation failed.
- Step `REQ_DISTINCT_w_Position_joined_prepared_joined`: last translation failed.
- Step `REQ_FINAL`: last translation failed.
- Step `applications_gbs_distinct2_prepared2`: last translation failed.
