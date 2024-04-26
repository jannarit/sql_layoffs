
-- FIRST STEP: DATA CLEANING 

SELECT * FROM world_layoffs.layoffs;

SET SQL_SAFE_UPDATES = 0;

-- Fill blanks with NULL

SELECT total_laid_off FROM layoffs WHERE total_laid_off IS NULL;
UPDATE layoffs SET total_laid_off = NULL WHERE total_laid_off = '';
ALTER TABLE layoffs
MODIFY COLUMN total_laid_off INT NULL;

SELECT percentage_laid_off FROM layoffs WHERE percentage_laid_off IS NULL;
UPDATE layoffs SET percentage_laid_off = NULL WHERE percentage_laid_off = '';

SELECT funds_raised_millions FROM layoffs WHERE funds_raised_millions IS NULL;
UPDATE layoffs SET funds_raised_millions = NULL WHERE funds_raised_millions = '';
ALTER TABLE layoffs
MODIFY COLUMN funds_raised_millions INT NULL;

SELECT industry FROM layoffs WHERE industry IS NULL;
UPDATE layoffs SET industry = NULL WHERE industry = '';

SELECT date FROM layoffs WHERE date IS NULL;
UPDATE layoffs SET date = NULL WHERE date = '';

SET SQL_SAFE_UPDATES = 1;

-- Create copy of raw data to work with.

CREATE TABLE layoffs_staging
LIKE world_layoffs.layoffs;

INSERT layoffs_staging
SELECT * FROM world_layoffs.layoffs;


-- 1. Remove duplicates

SELECT *
FROM world_layoffs.layoffs;

-- 1.1 Check for duplicates

WITH duplicate_cte AS
(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- 1.2 Create new column row_num and delete row numbers greater than 1

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- 1.3 Delete rows where row_num is greater than 1

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- 1.4 Check again for duplicates

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- 2. Standardize the data
-- 2.1 Delete empty spaces in column "company"

SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- 2.2 Standardize column "industry" by using the same term "Crypto" and not 3 different ways of writing

SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- 2.3 Standardize column "country" by deleting the "." after "United States" 

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'UNITED STATES%';

-- 2.4. Change datatype for 'date' to date

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- 3. Null Values or Blank Values by populating the NULLs if possible
-- Check for NULL

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- Populate NULL by using JOIN

SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
	AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry  IS NOT NULL;


UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry  IS NOT NULL;

-- Check again for NULL. Bally´s is the only company where the NULL could not be populated.

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;


-- 4. Remove columns and rows we don´t need

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT * 
FROM layoffs_staging2;



