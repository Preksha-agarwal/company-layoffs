-- DATA CLEANING

-- select the database
USE world_layoffs;

-- from the table layoffs, select everything
SELECT *
FROM layoffs;
-- Remove duplicates
-- Standardize the data
-- Null valuea and Blank values
-- Remove unnecessary rows and columns


-- REMOVING DUPLICATES

-- to create a new table layoffs_staging with structure exactly like layoffs
CREATE TABLE layoffs_staging
LIKE layoffs;

-- to populte the new table layoffs_staging
INSERT layoffs_staging
SELECT * FROM layoffs;

-- to check the number of records in the table
SELECT COUNT(*) FROM layoffs_staging;

-- to understand thw structure of the table
DESC layoffs_staging;

-- this step helps us to check for the duplictes
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,
stage, country, funds_raised_millions)
FROM layoffs_staging; 

-- to look at only thise rows that are duplicated
-- we cannot delete the dupplicated here itself as this is a cte and cannot perform update operations on it
-- moreover updating a cte will not change a target table
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte 
WHERE row_num >1;

-- check all the details of the company Casper
SELECT *
FROM layoffs_staging 
WHERE company='Casper';

-- to add a new column to the table
ALTER TABLE layoffs_staging
ADD COLUMN row_num INT;

-- delete the newly added column
ALTER TABLE layoffs_staging
DROP COLUMN row_num;

-- create a new table with exactly the same rows+ a new row_num column to check for the duplicates in the data
CREATE TABLE `layoffs_staging2` (
  `company` varchar(29) DEFAULT NULL,
  `location` varchar(16) DEFAULT NULL,
  `industry` varchar(15) DEFAULT NULL,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` decimal(6,4) DEFAULT NULL,
  `date` varchar(10) DEFAULT NULL,
  `stage` varchar(14) DEFAULT NULL,
  `country` varchar(20) DEFAULT NULL,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- to copy the same table and also the value of the row_num column
INSERT INTO
layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SET SQL_SAFE_UPDATES = 0;

-- just delete the records
DELETE
FROM layoffs_staging2
WHERE row_num>1;

SET SQL_SAFE_UPDATES = 1;

-- to see if the duplicates have been deleted
SELECT *
FROM layoffs_staging2
WHERE row_num>1;

SELECT *
FROM layoffs_staging2;


-- STANDARDIZING VALUES

-- to see if there is a need of change in the company names
SELECT company, TRIM(company)
FROM layoffs_staging2;

-- to change the company names into a proper format
UPDATE layoffs_staging2
SET company=TRIM(company);

-- to see all unique values of industry type in the data
SELECT DISTINCT(industry)
FROM layoffs_staging2;

-- to get records of all values where the idustry name starts from Crypto(Crypto, cryptocurrency, etc)
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- as all of them are the same industry(Crypto), we update the records
UPDATE layoffs_staging2
SET industry='Crypto'
WHERE industry LIKE 'Crypto%'; 

-- see different countries in the data
SELECT DISTINCT(country)
FROM layoffs_staging2;

-- look at all different 'United states' we have
-- we see that in some of the records, the United States has been terminated by a period and we wish to remove it
SELECT * 
FROM layoffs_staging2
WHERE Country LIKE 'United States.%';

-- update the wrong records
UPDATE layoffs_staging2
SET country='United States'
WHERE country LIKE 'United States.'; 

-- to look at date column(string) in the SQl date format
SELECT `date`,
STR_TO_DATE(`date`,'%m/%d/%Y')
FROM layoffs_staging2;

-- update the string to SQL date format
UPDATE layoffs_staging2
SET `date`=STR_TO_DATE(`date`,'%m/%d/%Y');

-- change the data type of the table
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- NULL AND BLANK VALUES
-- trying to populate the data where ever possible

-- see the columns where industry is absent
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry='';

-- after taking a look at records, we want to take a look at the records and try to populte it where ever we can
SELECT *
FROM layoffs_staging2
WHERE company='Airbnb';

-- see the null values along with non null values
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL; 

-- make the required changes
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry=t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL; 

-- we see that for this company, we do not have another record
-- therefore, we will not be able to populate it
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';


-- DELETEING DATA
-- we want to do exploratory analysis on the layoffs
-- it is essential for us to have the data of layoffs

-- look for records where there is no information about the layoffs whatsoever
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- and delete records where there is no information about the layoffs whatsoever
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2; 

-- now we drop the unnecesary column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;




-- EXPLORATORY DATA ANALYSIS

-- to see the maximum number of layoofs and the proportion of layoffs
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2; 

-- to see the record of the company in which all the employess were laid off
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off=1
ORDER BY funds_raised_millions DESC;

-- see the number of layoffs in each company for the whole data
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- look at the start and end date of the data
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- see the number of layoffs industry wise for the whole data
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- see the number of layoffs country wise for the whole data
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- see the number of layoffs year wise for the whole data
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- see the number of layoffs stage wise for the whole data
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- to see the total number of laid off based on each month of each year
SELECT SUBSTRING(`date`,1,7) AS `month`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `month`
ORDER by `month`;

-- to calculate the rolling total of total laid offs in the data
WITH rolling_total AS
(
SELECT SUBSTRING(`date`,1,7) AS `month`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `month`
ORDER by `month`
)
SELECT `month` , total_off, SUM(total_off) OVER(ORDER BY `month`) AS Rolling_tot
FROM rolling_total;

-- see the total number of lyoffs by each company and each year
SELECT company,YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company,YEAR(`date`)
ORDER BY 3 DESC;

-- the first CTE will find the total layoffs by each company in each year
-- the second CTE will rank the total number of layoffs yearly
-- i.e. for each year, it'll assign the rank from the company which had the most layoffs all the way to the least
-- then we take a look at the companys that laid off the maximum number of people for each year we have the data on
WITH company_year(company, years, total_laid_off) AS
(
SELECT company,YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company,YEAR(`date`)
), Comapny_Year_Rank AS
(
SELECT *,
DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
FROM company_year
WHERE years IS NOT NULL
)
SELECT * 
FROM Comapny_Year_Rank
WHERE ranking <=5;
