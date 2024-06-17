-- OBJECTIVE: To clean the data and do a data analysis on this cleaned data


-- DATA CLEANING

-- Select the database
USE world_layoffs;

-- From the table layoffs, select everything
SELECT *
FROM layoffs;

-- WE WILL:
-- Remove duplicates
-- Standardize the data
-- Deal with Null and Blank values
-- Remove unnecessary rows and columns


-- 1. REMOVING DUPLICATES

-- To create a copy of the table layoffs called layoff_staging
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * FROM layoffs;

-- To check the number of records in the table
SELECT COUNT(*) FROM layoffs_staging;

-- To understand the structure of the table
DESC layoffs_staging;

-- Partition the data over all the values and assign row numbers
-- To identify the duplicate values in the data
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,
stage, country, funds_raised_millions)
FROM layoffs_staging;

-- To look at duplicated values
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
-- We cannot delete the duplicated data here itself as this is a CTE and cannot be used to perform update operations.
-- Moreover updating a CTE will not change the target table

-- We see that 'Casper' is company with duplicated values
-- To get more insight into the table, check all the details of the company Casper
SELECT *
FROM layoffs_staging 
WHERE company='Casper';

-- To add a new column to the table
ALTER TABLE layoffs_staging
ADD COLUMN row_num INT;

-- Delete the newly added column
ALTER TABLE layoffs_staging
DROP COLUMN row_num;

-- Create a new table called layoffs_staging2 with exactly the same rows as layoffs_staging
-- Additionally a new row_num column to check for the duplicates in the data
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


-- To copy the same table and also the value of the row_num column
INSERT INTO
layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SET SQL_SAFE_UPDATES = 0;

-- Delete the duplicated records
DELETE
FROM layoffs_staging2
WHERE row_num>1;

SET SQL_SAFE_UPDATES = 1;

-- To see if the duplicates have been deleted
SELECT *
FROM layoffs_staging2
WHERE row_num>1;

SELECT *
FROM layoffs_staging2;


-- 2. STANDARDIZING VALUE

-- To see if there is a need of change in the company names
SELECT company, TRIM(company)
FROM layoffs_staging2;
-- There are extra whitespaces before and after the text in some of the records

-- To change the company names into a proper format
UPDATE layoffs_staging2
SET company=TRIM(company);

-- To see all unique values of industry type in the data
SELECT DISTINCT(industry)
FROM layoffs_staging2;
-- The data has entries named, Crypto, CryptoCurrency etc. This needs to be fixed as all these values correspond to the same industry.

-- To get records of all values where the idustry name starts from Crypto(Crypto, Cryptocurrency, etc)
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- As all of them are the same industry(Crypto), we update the records
UPDATE layoffs_staging2
SET industry='Crypto'
WHERE industry LIKE 'Crypto%'; 

-- See different countries in the data
SELECT DISTINCT(country)
FROM layoffs_staging2;
-- It can be seen that in some of the records, 'United States' has been terminated by a period

SELECT * 
FROM layoffs_staging2
WHERE Country LIKE 'United States.%';

-- Update the inccorect records
UPDATE layoffs_staging2
SET country='United States'
WHERE country LIKE 'United States.'; 

-- To look at date column(which is in string format) in the SQl date format
SELECT `date`,
STR_TO_DATE(`date`,'%m/%d/%Y')
FROM layoffs_staging2;

-- Update the string to SQL date format
UPDATE layoffs_staging2
SET `date`=STR_TO_DATE(`date`,'%m/%d/%Y');

-- Change the data type of the 'date' column
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 3. Deal with Null and Blank values
-- Try to populate the data where ever possible

-- See the columns where industry is absent
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry='';

-- Now check if the same company is present in the data
-- If yes, we may use the already existing records to update the missing values
SELECT *
FROM layoffs_staging2
WHERE company='Airbnb';

-- Perform self-join to see the records of the same company side by side
-- From the first table t1, get the NULL values and join it with those records of table t2 that are not NULL
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    	AND t1.location = t2.location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL; 

-- Update the data as per found records
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry=t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL; 

-- We see that for the company called 'Bally's Interactive', we do not have another record
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';
-- Therefore, we will not be able to populate it

-- 4. DELETEING DATA
-- We want to do exploratory analysis on the layoffs
-- It is essential for us to have the data of layoffs

-- Look for records where there is no information about the layoffs whatsoever i.e. total and percentage layoffs absent
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete records where there is no information about the layoffs whatsoever
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2; 

-- Now we drop the unnecesary column i.e. row_num
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;




-- EXPLORATORY DATA ANALYSIS

-- To see the maximum number of layoffs and the maximum proportion of layoffs
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;
-- Maximum number of people laid off in one-go was 12000
-- Maximum percentage of people laid off in one-go was 100%

-- To see the record of the company in which all the employess were laid off
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off=1
ORDER BY funds_raised_millions DESC;
-- Many companys laid off all their employees
-- Possible reasons may be closure, bankruptcy

-- Look at the start and end date of the data
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;
-- The data is from March, 2020 to March, 2023 i.e. During and post COVID-19

-- To see the number of layoffs in each company for the whole data
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;
-- Big companies like Google, Amazon, Meta has laid off the maximum number of employees during this period

-- To see the number of layoffs industry wise for the whole data
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;
-- Maximum layoffs in Cosumer, Retail and Transportation sector

-- To see the number of layoffs country wise for the whole data
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;
-- Maximum number of layoffs in the Unites States followed by India and Netherlands

-- To see the number of layoffs year wise for the whole data
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;
-- As the year goes by, more and more people are being laid off

-- To see the number of layoffs stage wise for the whole data
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;
-- Maximum layoffs take place Post IPO.

-- Calculates the total number of laid off employees for each month extracting the year and month portion from the 'date' column and grouping 
-- the results accordingly. The results are ordered chronologically by month.
SELECT SUBSTRING(`date`,1,7) AS `month`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `month`
ORDER by `month`;
-- The number of layoffs increased substantially as the time passed
-- The maximum number of layoffs took place in January,2023 wherein more than 84 thousand people were laid off

-- To calculate the rolling total of layoffs
WITH rolling_total AS
(
SELECT SUBSTRING(`date`,1,7) AS `month`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `month`
ORDER by `month`
)
SELECT `month` , total_off, SUM(total_off) OVER(ORDER BY `month`) AS `Rolling total`
FROM rolling_total;
-- The total number of layoffs is over 3,80,000

-- To see the total number of layoffs by each company and each year
SELECT company,YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company,YEAR(`date`)
ORDER BY 3 DESC;

-- The first CTE will find the total layoffs by each company in each year
-- The second CTE will rank the total number of layoffs yearly
-- i.e. for each year, it'll assign the rank from the company which had the most layoffs all the way to the least
-- Then we take a look at the companys that laid off the maximum number of people for each year we have the data on
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
-- We have the data of the to 5 companies that laid off most people each year.
-- The companies who laid off maximum people are
-- - Uber in 2020
-- - Bytedance in 2021
-- - Meta in 2022
-- - Google in 2023
