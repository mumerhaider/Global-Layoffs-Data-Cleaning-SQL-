SELECT * FROM layoffs;

# Create a copy of original table for cleaning.
CREATE TABLE layoffs_dev LIKE layoffs;
INSERT INTO layoffs_dev SELECT * FROM layoffs;
SELECT * FROM layoffs_dev;

# DATA CLEANING Starts.

# 1. Remove Duplicates

SELECT * ,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM  layoffs_dev;

SELECT * FROM 
(
SELECT * ,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM  layoffs_dev
) AS duplicates
WHERE row_num > 1;

CREATE TABLE layoffs_updated (
`company` text,
`location` text,
`industry` text,
`total_laid_off` int,
`percentage_laid_off` text,
`date` text,
`stage` text,
`country` text,
`funds_raised_millions` int,
row_num int
);

INSERT INTO layoffs_updated
(
`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`
) SELECT * ,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM  layoffs_dev;

DELETE FROM layoffs_updated WHERE row_num > 1;

# 2. Standardizing Data

UPDATE layoffs_updated SET company = TRIM(company);
UPDATE layoffs_updated SET industry = 'Crypto' WHERE industry LIKE 'Crypto%'; 
UPDATE layoffs_updated SET country =  TRIM(TRAILING '.' FROM country) WHERE country LIKE 'United States%';
UPDATE layoffs_updated SET `date` = STR_TO_DATE(`date`,'%m/%d/%Y');
ALTER TABLE layoffs_updated MODIFY COLUMN `date` DATE;

# 3. Removing Null/Blank Values 

SELECT * FROM layoffs_updated WHERE industry = '' OR industry IS NULL ORDER BY 1;
SELECT * FROM layoffs_updated WHERE company LIKE 'Airbnb%' OR company LIKE 'Bally%' OR company LIKE 'Carvana%' OR company LIKE 'Juul%';
SELECT * FROM layoffs_updated T1 
JOIN layoffs_updated T2 ON T1.company = T2.company
WHERE (T1.industry IS NULL OR T1.industry = '') AND T2.industry IS NOT NULL;
SELECT * FROM layoffs_updated WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

UPDATE layoffs_updated SET industry = NULL WHERE industry = '';
UPDATE layoffs_updated T1 
JOIN layoffs_updated T2 ON T1.company = T2.company SET T1.industry = T2.industry
WHERE (T1.industry IS NULL OR T1.industry = '') AND T2.industry IS NOT NULL;
DELETE FROM layoffs_updated WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

# 4. Remove any Coloumns

ALTER TABLE layoffs_updated DROP COLUMN row_num;
SELECT * FROM layoffs_updated ORDER BY 1;
