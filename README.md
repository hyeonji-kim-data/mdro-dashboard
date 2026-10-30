# Monitoring MDRO Patterns through Time-Based Analysis with SQL and Tableau

Aggregated hospital microbiology test results under international surveillance rules (WHO GLASS) and built a **prototype** Tableau dashboard designed to let the infection control team see multidrug-resistant organism (MDRO) activity on a single screen.

- **Type:** Bootcamp team project (5 members), Jun–Aug 2025
- **My role:** Data extraction and transformation (SQL), statistics dashboard (Tableau)
- **Tools:** Oracle SQL, Tableau
- **Portfolio page:** [link]

> **Data not included.** The queries were run on confidential hospital records, which cannot be shared. This repository contains the SQL only.

---

## 1. Goal

Antimicrobial-resistant infections raise mortality, length of stay and medical costs, so hospitals must continuously monitor and report them. Using microbiology culture results from a university hospital, this project set out to:

1. Count MDRO cases in line with the WHO GLASS standard by removing repeat tests of the same patient.
2. Separate infections acquired in the hospital from those brought in from outside.
3. Design a prototype dashboard where the infection control team could filter by organism, specimen and period and see the current situation right away.

## 2. Team scope and data

- **Team project:** an infection response platform with four parts: lab report structuring (NLP), an alert system, a chatbot and a statistics dashboard. **I built the statistics dashboard**, including all SQL in this repository.
- **Data:** microbiology culture results over 3.5 years (Jul 2020 – Dec 2023). Teammates structured the free-text lab reports into one table, `parsed_data_final`, with one row per test × organism × antibiotic.
- **Main columns used:** patient ID, sex, birth date, organism, specimen type, antibiotic, susceptibility result (S/I/R), test date, admission date, inpatient flag, ward code

## 3. MDRO definitions

Each result is labeled with an MDRO type when the organism and antibiotic result match the rule below.

| MDRO | Organism | Antibiotic result |
|---|---|---|
| MRSA | *Staphylococcus aureus* | Oxacillin or Cefoxitin = R |
| VRSA | *Staphylococcus aureus* | Vancomycin = R or I |
| VRE | *Enterococcus faecium*, *E. faecalis* | Vancomycin = R |
| MRPA | *Pseudomonas aeruginosa* | Imipenem or Meropenem = R |
| MRAB | *Acinetobacter baumannii* | Imipenem or Meropenem = R |
| CRE | Enterobacterales (44 species listed in the SQL) | Imipenem, Meropenem, Ertapenem or Doripenem = R |

## 4. Processing pipeline

[`mdro_dashboard.sql`](mdro_dashboard.sql) builds every view used by the dashboard.

| Step | What it does | View |
|---|---|---|
| 1. Classify | Label each result by MDRO type and keep MDRO rows | `mdro_view_stage1` |
| 2. Deduplicate | **WHO GLASS:** keep the first isolate per patient, specimen type, organism and year (window function `ROW_NUMBER`) | `mdro_view_stage2` |
| 3. Inpatients | Keep admitted patients only | `mdro_view_stage3` |
| 4. 48-hour split | More than 2 days after admission = hospital-acquired; otherwise community-onset | `mdro_view_stage4` |
| 5. Aggregate | Monthly counts by MDRO type, with **0 filled in for months with no detections** so trend lines stay continuous | `mdro_view_stage5` and the chart views below |

## 5. Dashboard structure

Three tabs, with year, month, organism and ward filters.

| Tab | Chart | SQL view |
|---|---|---|
| **Monitoring** | 1-1. MDRO detections within vs. after 48 hours of admission | `mdro_view_stage5` |
| | 1-2. MDRO detections in blood vs. non-blood specimens | `VIEW_MONTH_BLOOD_COUNT` |
| | 1-3. KPI cards: isolation rate by MDRO type and month-over-month change | `MDRO_ISOLATION_STATS` |
| **Ward Status** | 2-1. MDRO detections by ward | `MDRO_WARD_SUMMARY` |
| | 2-2. Isolation precautions by type | built in Tableau |
| | 2-3. Ward floor plan with patient locations | built in Tableau |
| **Statistics** | 3-1. Patients by sex and age group | `patient_gender_monthly_summary`, `patient_gender_age_summary` |
| | 3-2. Top 5 organisms by sex and season | `GENDER_TOP5_SPECIES`, `SEASON_TOP5_SPECIES` |
| | 3-3. Antibiotic resistance rates by specimen and organism | `SIR_SPECIES_VIEW` |

**Metric definitions**
- **Isolation rate (KPI cards)** = MDRO isolates ÷ all isolates in the month × 100. The card also shows the change from the previous month (`LAG`).
- **Blood vs. non-blood:** specimen type "Whole Blood" vs. all others, to monitor high-risk bloodstream infections separately.
- **Resistance rate:** share of S, I and R results per organism, specimen and antibiotic, using the first isolate per patient and year.

<!-- Dashboard screenshot (rebuilt with synthetic data):
<p align="center"><img src="figures/mdro-dashboard.png" alt="Prototype MDRO dashboard rebuilt with synthetic data" width="800"></p>
-->

## 6. Findings

- **Most cases started inside the hospital.** In every month from January to June 2021, more MDROs were detected after 48 hours of admission than before, pointing infection control toward transmission inside the hospital.
- **A standard made the counts trustworthy.** Counting repeat tests of the same patient inflates cases; WHO GLASS deduplication produced numbers in a form ready for national reporting (KOR-GLASS).

Exact counts are not shown because the data is confidential.

## 7. From analysis to decision

- **See which organism is rising.** KPI cards show each MDRO type's isolation rate and its change from last month.
- **Catch rising hospital-acquired cases early.** The 48-hour indicator is designed to flag increases sooner.

**Limitations**
- This is a prototype that was not deployed.
- Ward-level views (2-2, 2-3) used simulated data.
- The data pipeline is not automated, and no usability test with clinicians was done.

## Repository structure

```
├── README.md
└── mdro_dashboard.sql    # all views for the dashboard (Oracle)
```

## Note on AI assistance

I used AI tools ([tool names]) for coding help while building the queries, and later to translate the comments into English and tidy the file. The analysis design — MDRO definitions, WHO GLASS deduplication, the 48-hour split and the dashboard structure — is my own.
