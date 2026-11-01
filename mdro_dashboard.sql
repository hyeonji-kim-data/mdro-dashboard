/* MDRO Surveillance Dashboard - SQL views (Oracle)
   Source table: parsed_data_final (one row per test x organism x antibiotic)
   See README.md for the dashboard sections and MDRO definitions. */


/* =====================================================================
   1. MONITORING
   ===================================================================== */

-- ---------------------------------------------------------------------
-- 1-1. MDRO detections within vs. after 48 hours of admission
-- ---------------------------------------------------------------------

-- Step 1: classify each result by MDRO type and keep MDRO rows only
CREATE OR REPLACE VIEW mdro_view_stage1 AS
SELECT
    PATIENT_NO,
    ORG_NAME,
    TEST_DATE,
    ADMISSION_DATE,
    SPEC_TYPE,
    ABX_NAME,
    INTP_CODE,
    IS_ADMITTED,

    CASE
        -- MRSA
        WHEN ORG_NAME = 'Staphylococcus aureus'
             AND ABX_NAME IN ('Oxacillin', 'Cefoxitin')
             AND INTP_CODE = 'R'
        THEN 'MRSA'

        -- VRSA
        WHEN ORG_NAME = 'Staphylococcus aureus'
             AND ABX_NAME = 'Vancomycin'
             AND INTP_CODE IN ('R', 'I')
        THEN 'VRSA'

        -- VRE
        WHEN ORG_NAME IN ('Enterococcus faecium', 'Enterococcus faecalis')
             AND ABX_NAME = 'Vancomycin'
             AND INTP_CODE = 'R'
        THEN 'VRE'

        -- MRPA
        WHEN ORG_NAME = 'Pseudomonas aeruginosa'
             AND ABX_NAME IN ('Imipenem', 'Meropenem')
             AND INTP_CODE = 'R'
        THEN 'MRPA'

        -- MRAB
        WHEN ORG_NAME = 'Acinetobacter baumannii'
             AND ABX_NAME IN ('Imipenem', 'Meropenem')
             AND INTP_CODE = 'R'
        THEN 'MRAB'

        -- CRE
        WHEN ORG_NAME IN (
            'Escherichia coli','Escherichia hermanii','Escherichia vulneris',
            'Klebsiella aerogenes','Klebsiella ornithinolytica','Klebsiella oxytoca',
            'Klebsiella planticola','Klebsiella pneumoniae','Klebsiella variicola',
            'Enterobacter aerogenes','Enterobacter asburiae','Enterobacter bugandensis',
            'Enterobacter cloacae','Enterobacter gergoviae','Enterobacter kobei',
            'Enterobacter ludwigii','Enterobacter sakazakii',
            'Citrobacter amalonaticus','Citrobacter braakii','Citrobacter farmeri',
            'Citrobacter freundii','Citrobacter sedlakii','Citrobacter youngae',
            'Salmonella Group B','Salmonella Group C','Salmonella Group D','Salmonella species',
            'Proteus hauseri','Proteus mirabilis','Proteus penneri','Proteus vulgaris',
            'Morganella morganii','Providencia rettgeri','Providencia stuartii','Providencia vermicola',
            'Serratia grimesii','Serratia liquefaciens','Serratia marcescens',
            'Serratia nematodiphila','Serratia odorifera','Serratia plymuthica',
            'Serratia rubidaea','Hafnia alvei','Leclercia adecarboxylata'
        )
        AND ABX_NAME IN ('Imipenem', 'Meropenem', 'Ertapenem', 'Doripenem')
        AND INTP_CODE = 'R'
        THEN 'CRE'

        ELSE NULL
    END AS IS_MDRO

FROM parsed_data_final
WHERE
    (
        -- MRSA
        (ORG_NAME = 'Staphylococcus aureus' AND ABX_NAME IN ('Oxacillin', 'Cefoxitin') AND INTP_CODE = 'R') OR
        -- VRSA
        (ORG_NAME = 'Staphylococcus aureus' AND ABX_NAME = 'Vancomycin' AND INTP_CODE IN ('R', 'I')) OR
        -- VRE
        (ORG_NAME IN ('Enterococcus faecium', 'Enterococcus faecalis') AND ABX_NAME = 'Vancomycin' AND INTP_CODE = 'R') OR
        -- MRPA
        (ORG_NAME = 'Pseudomonas aeruginosa' AND ABX_NAME IN ('Imipenem', 'Meropenem') AND INTP_CODE = 'R') OR
        -- MRAB
        (ORG_NAME = 'Acinetobacter baumannii' AND ABX_NAME IN ('Imipenem', 'Meropenem') AND INTP_CODE = 'R') OR
        -- CRE
        (ORG_NAME IN (
            'Escherichia coli','Escherichia hermanii','Escherichia vulneris',
            'Klebsiella aerogenes','Klebsiella ornithinolytica','Klebsiella oxytoca',
            'Klebsiella planticola','Klebsiella pneumoniae','Klebsiella variicola',
            'Enterobacter aerogenes','Enterobacter asburiae','Enterobacter bugandensis',
            'Enterobacter cloacae','Enterobacter gergoviae','Enterobacter kobei',
            'Enterobacter ludwigii','Enterobacter sakazakii',
            'Citrobacter amalonaticus','Citrobacter braakii','Citrobacter farmeri',
            'Citrobacter freundii','Citrobacter sedlakii','Citrobacter youngae',
            'Salmonella Group B','Salmonella Group C','Salmonella Group D','Salmonella species',
            'Proteus hauseri','Proteus mirabilis','Proteus penneri','Proteus vulgaris',
            'Morganella morganii','Providencia rettgeri','Providencia stuartii','Providencia vermicola',
            'Serratia grimesii','Serratia liquefaciens','Serratia marcescens',
            'Serratia nematodiphila','Serratia odorifera','Serratia plymuthica',
            'Serratia rubidaea','Hafnia alvei','Leclercia adecarboxylata'
        )
        AND ABX_NAME IN ('Imipenem', 'Meropenem', 'Ertapenem', 'Doripenem') AND INTP_CODE = 'R')
    );

SELECT COUNT(*) FROM mdro_view_stage1;


-- Step 2: WHO GLASS deduplication
-- keep the first isolate per patient, specimen type, organism and year
CREATE OR REPLACE VIEW mdro_view_stage2 AS
SELECT *
FROM (
    SELECT
        mdro_view_stage1.*,
        ROW_NUMBER() OVER (
            PARTITION BY
                PATIENT_NO,
                SPEC_TYPE,
                ORG_NAME,
                EXTRACT(YEAR FROM TEST_DATE)
            ORDER BY TEST_DATE ASC
        ) AS RN
    FROM mdro_view_stage1
)
WHERE RN = 1;

SELECT COUNT(*) FROM mdro_view_stage2;


-- Step 3: inpatients only
CREATE OR REPLACE VIEW mdro_view_stage3 AS
SELECT *
FROM mdro_view_stage2
WHERE IS_ADMITTED = 'Y';


-- Step 4: split by time from admission to test
-- more than 2 days (48 hours) after admission = hospital-acquired
CREATE OR REPLACE VIEW mdro_view_stage4 AS
SELECT mdro_view_stage3.*,
       CASE
           WHEN TEST_DATE - ADMISSION_DATE > 2 THEN 'After 48h'
           WHEN TEST_DATE - ADMISSION_DATE <= 2 THEN 'Within 48h'
           ELSE NULL
       END AS APART_DATE
FROM mdro_view_stage3;


-- Step 5: monthly counts for the chart
CREATE OR REPLACE VIEW mdro_view_stage5 AS
SELECT
    TO_CHAR(TEST_DATE, 'YYYY') AS TEST_YEAR,
    TO_CHAR(TEST_DATE, 'MM') AS TEST_MONTH,
    IS_MDRO,
    APART_DATE,
    COUNT(*) AS MDRO_COUNT
FROM mdro_view_stage4
WHERE IS_MDRO IS NOT NULL
GROUP BY TO_CHAR(TEST_DATE, 'YYYY'), TO_CHAR(TEST_DATE, 'MM'), APART_DATE, IS_MDRO
ORDER BY TEST_YEAR, TEST_MONTH, APART_DATE;

SELECT * FROM mdro_view_stage5;


-- ---------------------------------------------------------------------
-- 1-2. MDRO detections in blood vs. non-blood specimens
-- Includes months with zero detections, so the chart has no gaps
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW VIEW_MONTH_BLOOD_COUNT AS
WITH
-- 1. All year-month pairs
month_list AS (
  SELECT DISTINCT
    TO_CHAR(TEST_DATE, 'YYYY') AS TEST_YEAR,
    TO_CHAR(TEST_DATE, 'MM') AS TEST_MONTH
  FROM MDRO_VIEW_STAGE2
),

-- 2. Blood flag (Y/N)
blood_flag AS (
  SELECT 'Y' AS IS_BLOOD FROM DUAL
  UNION ALL
  SELECT 'N' AS IS_BLOOD FROM DUAL
),

-- 3. MDRO types
mdro_flag AS (
  SELECT DISTINCT IS_MDRO FROM MDRO_VIEW_STAGE2
),

-- 4. Every month x blood flag x MDRO type combination
month_combinations AS (
  SELECT
    m.TEST_YEAR,
    m.TEST_MONTH,
    b.IS_BLOOD,
    d.IS_MDRO
  FROM month_list m
  CROSS JOIN blood_flag b
  CROSS JOIN mdro_flag d
),

-- 5. Actual detections
raw_data AS (
  SELECT
    TO_CHAR(TEST_DATE, 'YYYY') AS TEST_YEAR,
    TO_CHAR(TEST_DATE, 'MM') AS TEST_MONTH,
    CASE WHEN SPEC_TYPE = 'Whole Blood' THEN 'Y' ELSE 'N' END AS IS_BLOOD,
    IS_MDRO,
    PATIENT_NO
  FROM MDRO_VIEW_STAGE2
)

-- 6. LEFT JOIN so that missing combinations get a count of 0
SELECT
  mc.TEST_YEAR,
  mc.TEST_MONTH,
  mc.IS_BLOOD,
  mc.IS_MDRO,
  COUNT(rd.PATIENT_NO) AS MDRO_COUNT
FROM month_combinations mc
LEFT JOIN raw_data rd
  ON mc.TEST_YEAR = rd.TEST_YEAR
 AND mc.TEST_MONTH = rd.TEST_MONTH
 AND mc.IS_BLOOD = rd.IS_BLOOD
 AND mc.IS_MDRO = rd.IS_MDRO
GROUP BY
  mc.TEST_YEAR, mc.TEST_MONTH, mc.IS_BLOOD, mc.IS_MDRO
ORDER BY
  mc.TEST_YEAR, mc.TEST_MONTH, mc.IS_MDRO, mc.IS_BLOOD;

SELECT * FROM VIEW_MONTH_BLOOD_COUNT;


-- ---------------------------------------------------------------------
-- 1-3. KPI cards: isolation rates by MDRO type and month-over-month change
-- isolation rate = MDRO isolates / all isolates in the month
-- ---------------------------------------------------------------------

-- Step 1: all results with an organism, labeled by MDRO type (NULL = not MDRO)
CREATE OR REPLACE VIEW CARD_COUNT_STAGE1 AS
SELECT
    PATIENT_NO,
    ORG_NAME,
    TEST_DATE,
    ADMISSION_DATE,
    SPEC_TYPE,
    ABX_NAME,
    INTP_CODE,
    IS_ADMITTED,

    CASE
        -- MRSA
        WHEN ORG_NAME = 'Staphylococcus aureus'
             AND ABX_NAME IN ('Oxacillin', 'Cefoxitin')
             AND INTP_CODE = 'R'
        THEN 'MRSA'

        -- VRSA
        WHEN ORG_NAME = 'Staphylococcus aureus'
             AND ABX_NAME = 'Vancomycin'
             AND INTP_CODE IN ('R', 'I')
        THEN 'VRSA'

        -- VRE
        WHEN ORG_NAME IN ('Enterococcus faecium', 'Enterococcus faecalis')
             AND ABX_NAME = 'Vancomycin'
             AND INTP_CODE = 'R'
        THEN 'VRE'

        -- MRPA
        WHEN ORG_NAME = 'Pseudomonas aeruginosa'
             AND ABX_NAME IN ('Imipenem', 'Meropenem')
             AND INTP_CODE = 'R'
        THEN 'MRPA'

        -- MRAB
        WHEN ORG_NAME = 'Acinetobacter baumannii'
             AND ABX_NAME IN ('Imipenem', 'Meropenem')
             AND INTP_CODE = 'R'
        THEN 'MRAB'

        -- CRE
        WHEN ORG_NAME IN (
            'Escherichia coli','Escherichia hermanii','Escherichia vulneris',
            'Klebsiella aerogenes','Klebsiella ornithinolytica','Klebsiella oxytoca',
            'Klebsiella planticola','Klebsiella pneumoniae','Klebsiella variicola',
            'Enterobacter aerogenes','Enterobacter asburiae','Enterobacter bugandensis',
            'Enterobacter cloacae','Enterobacter gergoviae','Enterobacter kobei',
            'Enterobacter ludwigii','Enterobacter sakazakii',
            'Citrobacter amalonaticus','Citrobacter braakii','Citrobacter farmeri',
            'Citrobacter freundii','Citrobacter sedlakii','Citrobacter youngae',
            'Salmonella Group B','Salmonella Group C','Salmonella Group D','Salmonella species',
            'Proteus hauseri','Proteus mirabilis','Proteus penneri','Proteus vulgaris',
            'Morganella morganii','Providencia rettgeri','Providencia stuartii','Providencia vermicola',
            'Serratia grimesii','Serratia liquefaciens','Serratia marcescens',
            'Serratia nematodiphila','Serratia odorifera','Serratia plymuthica',
            'Serratia rubidaea','Hafnia alvei','Leclercia adecarboxylata'
        )
        AND ABX_NAME IN ('Imipenem', 'Meropenem', 'Ertapenem', 'Doripenem')
        AND INTP_CODE = 'R'
        THEN 'CRE'

        ELSE NULL
    END AS IS_MDRO

FROM parsed_data_final
WHERE ORG_NAME IS NOT NULL;

SELECT COUNT(*) FROM CARD_COUNT_STAGE1;


-- Step 2: total isolates per month (one per patient, organism and month)
CREATE OR REPLACE VIEW CARD_COUNT_MONTH AS
SELECT
    YEAR,
    MONTH,
    COUNT(*) AS TOTAL_ORG_COUNTS
FROM (
    SELECT
        PATIENT_NO,
        ORG_NAME,
        TEST_DATE,
        EXTRACT(YEAR FROM TEST_DATE) AS YEAR,
        EXTRACT(MONTH FROM TEST_DATE) AS MONTH,
        ROW_NUMBER() OVER (
            PARTITION BY PATIENT_NO, ORG_NAME, EXTRACT(YEAR FROM TEST_DATE), EXTRACT(MONTH FROM TEST_DATE)
            ORDER BY TEST_DATE
        ) AS RN
    FROM CARD_COUNT_STAGE1
    WHERE ORG_NAME IS NOT NULL
)
WHERE RN = 1
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;


-- Step 3: MDRO isolates per month, by type
CREATE OR REPLACE VIEW CARD_COUNT_MONTH_MDRO AS
SELECT
    EXTRACT(YEAR FROM TEST_DATE) AS YEAR,
    EXTRACT(MONTH FROM TEST_DATE) AS MONTH,
    IS_MDRO,
    COUNT(*) AS COUNT_PER_TYPE
FROM mdro_view_stage2
GROUP BY
    EXTRACT(YEAR FROM TEST_DATE),
    EXTRACT(MONTH FROM TEST_DATE),
    IS_MDRO
ORDER BY
    YEAR, MONTH, IS_MDRO;


-- Step 4: isolation rate and change from the previous month
CREATE OR REPLACE VIEW MDRO_ISOLATION_STATS AS
SELECT
    YEAR,
    MONTH,
    IS_MDRO,
    COUNT,
    TOTAL,
    ISOLATION_RATE_PCT,
    ROUND(ISOLATION_RATE_PCT - LAG(ISOLATION_RATE_PCT) OVER (
        PARTITION BY IS_MDRO
        ORDER BY YEAR, MONTH
    ), 2) AS DIFFERENCE
FROM (
    SELECT
        TO_CHAR(T.YEAR) AS YEAR,
        TO_CHAR(T.MONTH, 'FM00') AS MONTH,
        T.IS_MDRO,
        T.COUNT_PER_TYPE AS COUNT,
        M.TOTAL_ORG_COUNTS AS TOTAL,
        ROUND((T.COUNT_PER_TYPE / M.TOTAL_ORG_COUNTS) * 100, 2) AS ISOLATION_RATE_PCT
    FROM
        CARD_COUNT_MONTH M
    JOIN
        CARD_COUNT_MONTH_MDRO T
        ON M.YEAR = T.YEAR AND M.MONTH = T.MONTH
);

SELECT * FROM MDRO_ISOLATION_STATS;


/* =====================================================================
   2. WARD STATUS
   ===================================================================== */

-- ---------------------------------------------------------------------
-- 2-1. MDRO detections by ward
-- ---------------------------------------------------------------------

-- Step 1: attach the ward code to each deduplicated MDRO isolate
-- (if a result was reported more than once, use the latest report)
CREATE OR REPLACE VIEW MDRO_WARD_STATS AS
WITH p_dedup AS (
    SELECT parsed_data_final.*,
           ROW_NUMBER() OVER (
               PARTITION BY PATIENT_NO, TEST_DATE, ORG_NAME, ABX_NAME
               ORDER BY REPORT_DT DESC
           ) AS rn
    FROM parsed_data_final
)
SELECT
    m.*,
    p.WARD_CODE
FROM
    mdro_view_stage2 m
LEFT JOIN
    p_dedup p
ON
    m.PATIENT_NO = p.PATIENT_NO
    AND m.TEST_DATE = p.TEST_DATE
    AND m.ORG_NAME = p.ORG_NAME
    AND m.ABX_NAME = p.ABX_NAME
    AND p.rn = 1;

SELECT COUNT(*) FROM MDRO_WARD_STATS;


-- Step 2: monthly counts by ward and MDRO type, with 0 for missing combinations
CREATE OR REPLACE VIEW MDRO_WARD_SUMMARY AS
WITH mdro_list AS (
    SELECT 'MRSA' AS IS_MDRO FROM DUAL UNION ALL
    SELECT 'MRAB' FROM DUAL UNION ALL
    SELECT 'MRPA' FROM DUAL UNION ALL
    SELECT 'CRE'  FROM DUAL UNION ALL
    SELECT 'VRE'  FROM DUAL UNION ALL
    SELECT 'VRSA' FROM DUAL
),
date_ward_combinations AS (
    SELECT DISTINCT
        TO_CHAR(TEST_DATE, 'YYYY') AS TEST_YEAR,
        TO_CHAR(TEST_DATE, 'MM') AS TEST_MONTH,
        WARD_CODE
    FROM MDRO_WARD_STATS
    WHERE WARD_CODE IS NOT NULL
),
all_combinations AS (
    SELECT
        d.TEST_YEAR,
        d.TEST_MONTH,
        d.WARD_CODE,
        m.IS_MDRO
    FROM date_ward_combinations d
    CROSS JOIN mdro_list m
),
real_counts AS (
    SELECT
        TO_CHAR(TEST_DATE, 'YYYY') AS TEST_YEAR,
        TO_CHAR(TEST_DATE, 'MM') AS TEST_MONTH,
        WARD_CODE,
        IS_MDRO,
        COUNT(*) AS CNT
    FROM MDRO_WARD_STATS
    WHERE WARD_CODE IS NOT NULL AND IS_MDRO IS NOT NULL
    GROUP BY
        TO_CHAR(TEST_DATE, 'YYYY'),
        TO_CHAR(TEST_DATE, 'MM'),
        WARD_CODE,
        IS_MDRO
)
SELECT
    a.TEST_YEAR,
    a.TEST_MONTH,
    a.WARD_CODE,
    a.IS_MDRO,
    NVL(r.CNT, 0) AS COUNT
FROM
    all_combinations a
LEFT JOIN
    real_counts r
ON
    a.TEST_YEAR = r.TEST_YEAR AND
    a.TEST_MONTH = r.TEST_MONTH AND
    a.WARD_CODE = r.WARD_CODE AND
    a.IS_MDRO = r.IS_MDRO
ORDER BY
    a.TEST_YEAR, a.TEST_MONTH, a.WARD_CODE, a.IS_MDRO;

SELECT * FROM MDRO_WARD_SUMMARY;


/* =====================================================================
   3. STATISTICS
   ===================================================================== */

-- ---------------------------------------------------------------------
-- 3-1. Patients by sex and age group
-- ---------------------------------------------------------------------

-- Patients by sex, per month
CREATE OR REPLACE VIEW patient_gender_monthly_summary AS
SELECT
    TO_CHAR(TEST_DATE, 'YYYY') AS YEAR,
    TO_CHAR(TEST_DATE, 'MM') AS MONTH,
    CASE WHEN SEX = 'F' THEN 'Female'
         WHEN SEX = 'M' THEN 'Male'
    END AS GENDER,
    COUNT(DISTINCT PATIENT_NO) AS PATIENT_COUNT
FROM
    parsed_data_final
WHERE
    SEX IN ('F', 'M')
GROUP BY
    TO_CHAR(TEST_DATE, 'YYYY'),
    TO_CHAR(TEST_DATE, 'MM'),
    SEX
ORDER BY
    YEAR, MONTH, SEX;

SELECT * FROM patient_gender_monthly_summary;


-- Patients by sex and 10-year age group, per month (age at test date)
CREATE OR REPLACE VIEW patient_gender_age_summary AS
SELECT
    TO_CHAR(TEST_DATE, 'YYYY') AS YEAR,
    TO_CHAR(TEST_DATE, 'MM') AS MONTH,
    SEX,
    CASE
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) < 10 THEN '00-09'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 10 AND 19 THEN '10-19'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 20 AND 29 THEN '20-29'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 30 AND 39 THEN '30-39'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 40 AND 49 THEN '40-49'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 50 AND 59 THEN '50-59'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 60 AND 69 THEN '60-69'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 70 AND 79 THEN '70-79'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 80 AND 89 THEN '80-89'
        ELSE '90+'
    END AS AGE_GROUP,
    COUNT(DISTINCT PATIENT_NO) AS PATIENT_COUNT
FROM parsed_data_final
WHERE SEX IN ('F', 'M')
GROUP BY
    TO_CHAR(TEST_DATE, 'YYYY'),
    TO_CHAR(TEST_DATE, 'MM'),
    SEX,
    CASE
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) < 10 THEN '00-09'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 10 AND 19 THEN '10-19'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 20 AND 29 THEN '20-29'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 30 AND 39 THEN '30-39'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 40 AND 49 THEN '40-49'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 50 AND 59 THEN '50-59'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 60 AND 69 THEN '60-69'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 70 AND 79 THEN '70-79'
        WHEN FLOOR(MONTHS_BETWEEN(TEST_DATE, BIRTH_DATE) / 12) BETWEEN 80 AND 89 THEN '80-89'
        ELSE '90+'
    END
ORDER BY YEAR, MONTH, AGE_GROUP;

SELECT * FROM patient_gender_age_summary;


-- ---------------------------------------------------------------------
-- 3-2. Top 5 organisms by sex and season
-- The five most frequently detected organisms over the full study period,
-- identified first and fixed below so every period compares the same five.
-- ---------------------------------------------------------------------

-- Detections of the top 5 organisms by sex, per month
CREATE OR REPLACE VIEW GENDER_TOP5_SPECIES AS
SELECT
    YEAR,
    MONTH,
    ORG_NAME,
    SEX AS GENDER,
    DETECTION_COUNT
FROM (
    SELECT
        TO_CHAR(TEST_DATE, 'YYYY') AS YEAR,
        TO_CHAR(TEST_DATE, 'MM') AS MONTH,
        SEX,
        ORG_NAME,
        COUNT(*) AS DETECTION_COUNT,
        SUM(COUNT(*)) OVER (
            PARTITION BY TO_CHAR(TEST_DATE, 'YYYY'), TO_CHAR(TEST_DATE, 'MM'), ORG_NAME
        ) AS TOTAL_COUNT
    FROM parsed_data_final
    WHERE
        SEX IN ('F', 'M')
        AND ORG_NAME IN (
            'Escherichia coli',
            'Staphylococcus aureus',
            'Enterococcus faecalis',
            'Pseudomonas aeruginosa',
            'Klebsiella pneumoniae'
        )
    GROUP BY
        TO_CHAR(TEST_DATE, 'YYYY'),
        TO_CHAR(TEST_DATE, 'MM'),
        SEX,
        ORG_NAME
) t
ORDER BY YEAR, MONTH, ORG_NAME, GENDER;

SELECT * FROM GENDER_TOP5_SPECIES;


-- Monthly share of each top 5 organism within its year
-- (grouped into seasons in Tableau)
CREATE OR REPLACE VIEW SEASON_TOP5_SPECIES AS
SELECT
    YEAR,
    MONTH,
    ORG_NAME,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY YEAR, ORG_NAME),
        2
    ) AS PERCENTAGE
FROM (
    SELECT
        TO_CHAR(TEST_DATE, 'YYYY') AS YEAR,
        TO_CHAR(TEST_DATE, 'MM') AS MONTH,
        ORG_NAME
    FROM parsed_data_final
    WHERE ORG_NAME IN (
        'Escherichia coli',
        'Staphylococcus aureus',
        'Enterococcus faecalis',
        'Pseudomonas aeruginosa',
        'Klebsiella pneumoniae'
    )
)
GROUP BY YEAR, ORG_NAME, MONTH
ORDER BY YEAR, ORG_NAME, MONTH;

SELECT * FROM SEASON_TOP5_SPECIES;


-- ---------------------------------------------------------------------
-- 3-3. Antibiotic resistance rates by specimen and organism
-- Share of S / I / R results, using the first isolate per patient,
-- specimen type, organism, antibiotic and year
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW SIR_SPECIES_VIEW AS
WITH first_detection_per_patient AS (
    SELECT *
    FROM (
        SELECT
            parsed_data_final.*,
            ROW_NUMBER() OVER (
                PARTITION BY patient_no, spec_type, org_name, abx_name, TO_CHAR(test_date, 'YYYY')
                ORDER BY test_date ASC
            ) AS rn
        FROM parsed_data_final
        WHERE
            org_name IN (
                'Escherichia coli',
                'Staphylococcus aureus',
                'Enterococcus faecalis'
            )
            AND intp_code IN ('S', 'I', 'R')
    )
    WHERE rn = 1
),
summary_base AS (
    SELECT
        TO_CHAR(test_date, 'YYYY') AS year,
        org_name,
        spec_type,
        abx_name,
        COUNT(*) AS total_count,
        COUNT(CASE WHEN intp_code = 'S' THEN 1 END) AS s_count,
        COUNT(CASE WHEN intp_code = 'I' THEN 1 END) AS i_count,
        COUNT(CASE WHEN intp_code = 'R' THEN 1 END) AS r_count
    FROM first_detection_per_patient
    GROUP BY
        TO_CHAR(test_date, 'YYYY'),
        org_name,
        spec_type,
        abx_name
)

SELECT
    year AS "YEAR",
    org_name AS "ORG_NAME",
    spec_type AS "SPEC_TYPE",
    abx_name AS "ABX_NAME",
    'S' AS "INTP_CODE",
    ROUND(s_count * 100.0 / total_count, 2) AS "PERCENTAGE"
FROM summary_base

UNION ALL

SELECT
    year AS "YEAR",
    org_name AS "ORG_NAME",
    spec_type AS "SPEC_TYPE",
    abx_name AS "ABX_NAME",
    'I' AS "INTP_CODE",
    ROUND(i_count * 100.0 / total_count, 2) AS "PERCENTAGE"
FROM summary_base

UNION ALL

SELECT
    year AS "YEAR",
    org_name AS "ORG_NAME",
    spec_type AS "SPEC_TYPE",
    abx_name AS "ABX_NAME",
    'R' AS "INTP_CODE",
    ROUND(r_count * 100.0 / total_count, 2) AS "PERCENTAGE"
FROM summary_base

ORDER BY "YEAR", "ORG_NAME", "SPEC_TYPE", "ABX_NAME", "INTP_CODE";

SELECT * FROM SIR_SPECIES_VIEW;
