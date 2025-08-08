-- Data Cleaning

SELECT * 
FROM layoffs;

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * 
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

WITH duplicate_cte AS (
SELECT *,
ROW_NUMBER() OVER(
partition by company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

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
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
partition by company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- standardizing data

SELECT company 
FROM layoffs_staging2
WHERE company LIKE '%Paid';

UPDATE layoffs_staging2
SET company = 'Paid'
WHERE company LIKE '%Paid';

SELECT company
FROM layoffs_staging2;

SELECT distinct industry
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country Like 'United States%';

SELECT DISTINCT country
FROM layoffs_staging2;

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y') AS `DATE`
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT company,industry
FROM layoffs_staging2
WHERE industry IS NULL OR industry = '';

UPDATE layoffs_staging2
SET industry = null
WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;








































