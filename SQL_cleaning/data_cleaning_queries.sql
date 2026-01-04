-- Data cleaning with DuckDB

/* data source

https://www.kaggle.com/datasets/tanvirachowdhury/layoffs-2020-to-2023?select=layoffs.csv 


 Data cleaning steps:
 1. Load the CSV-file into Duckdb
 2. Create a working table
 3. Identify and remove exact duplicate rows
 4. Handle NULL and string-based 'NULL' values
 5. Standardize text and date formats
 6. Remove unnecessary columns and rows
 7. export the cleaned CSV-file
 */

----------------------------------------------------------------

/* Load the CSV-file into Duckdb*/

CREATE schema world_layoffs.staging

CREATE TABLE staging.layoffs AS
SELECT * 
FROM read_csv(layoffs.csv)

/* Create a working table (to delete and update information) */
CREATE TABLE staging.layoffs_cleaned AS
SELECT * 
FROM staging.layoffs
WHERE 1 = 0;

-- this column is added to be able to delete duplicated rows
ALTER TABLE staging.layoffs_cleaned
ADD COLUMN row_num;    

-- Insert data into working table
INSERT INTO staging.layoffs_cleaned
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company,
        "location",
        industry,
        total_laid_off,
        percentage_laid_off,
        date,
        stage,
        country,
        funds_raised_millions
    ) AS row_num
FROM staging.layoffs;

-----------------------------------------------------------------------

/* Identify and remove exact duplicate rows */

-- exploratory check: inspect duplicate rows identified by row_num
SELECT *
FROM staging.layoffs_cleaned
WHERE row_num > 1;

-- delete duplicated rows
DELETE FROM staging.layoffs_cleaned
WHERE row_num > 1;

--------------------------------------------------------------------------

/* Handle NULL and string-based 'NULL' values */

-- set all string-based 'NULL' to NULL
UPDATE staging.layoffs_cleaned
SET industry = NULLIF(industry, 'NULL'),
    company = NULLIF(company, 'NULL'),
    total_laid_off = NULLIF(total_laid_off, 'NULL'),
    percentage_laid_off = NULLIF(percentage_laid_off, 'NULL'),
    date = NULLIF(date, 'NULL'),
    stage = NULLIF(stage, 'NULL'),
    country = NULLIF(country, 'NULL'),
    funds_raised_millions = NULLIF(funds_raised_millions, 'NULL');

----------------------------------------------------------------------------

/* Standardize text and date formats */

-- exploratory check: count rows with leading or trailing whitespace in company
SELECT COUNT(*) AS rows_with_whitespace
FROM staging.layoffs_cleaned
WHERE company <> TRIM(company);

-- exploratory check: inspect company values with whitespace issues
SELECT company
FROM staging.layoffs_cleaned
WHERE company <> TRIM(company);

UPDATE staging.layoffs_cleaned
SET company = TRIM(company);

-- exploratory check: review distinct location values
SELECT DISTINCT "location"
FROM staging.layoffs_cleaned;

-- exploratory check: review distinct industry values
SELECT DISTINCT industry
FROM staging.layoffs_cleaned;

-- multiple naming variations exist for the Crypto industry; values are standardized to 'Crypto'
UPDATE staging.layoffs_cleaned
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Impute missing industry values based on known business domain
UPDATE staging.layoffs_cleaned c
SET industry = r.industry
FROM staging.layoffs_cleaned r
WHERE c.company = r.company
  AND c.industry IS NULL
  AND r.industry IS NOT NULL;

-- exploratory check: inspect date values 
SELECT date
FROM staging.layoffs_cleaned;

-- format needs to be changed from 'MM/DD/YYYY' to 'YYYY-MM-DD'
UPDATE staging.layoffs_cleaned
SET date = STRPTIME(date, '%m/%d/%Y')::DATE;

-- exploratory check: inspect country values
SELECT DISTINCT country
FROM staging.layoffs_cleaned
ORDER BY country;

-- There is a trailing dot after "United States" that needs to be removed
UPDATE staging.layoffs_cleaned
SET country = TRIM(
        TRAILING '.'
        FROM country
    )
WHERE country LIKE 'United States%';

--------------------------------------------------------------------------

/* Remove unnecessary columns and rows */

-- column row_num is not needed anymore, so that will be deleted
ALTER TABLE staging.layoffs_cleaned DROP COLUMN row_num;

/*
 Following agreement with stakeholders, 361 rows were removed from the
 dataset where both total_laid_off and percentage_laid_off
 were NULL, as these records did not contain actionable layoff information.
 */

DELETE FROM staging.layoffs_cleaned
WHERE total_laid_off IS NULL
    AND percentage_laid_off IS NULL;

/* Export cleaned dataset to csv */

COPY (
  SELECT *
  FROM staging.layoffs_cleaned
)
TO 'layoffs_cleaned.csv'
(header, delimiter ',');

