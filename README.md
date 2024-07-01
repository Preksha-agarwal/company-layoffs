# World Layoffs Data Analysis

This project involves comprehensive data cleaning, standardization, and analysis of a layoffs dataset using SQL. The dataset covers layoff information from March 2020 to March 2023, including various companies, industries, locations, and stages of the companies. The project aims to extract meaningful insights and trends from the data through a series of SQL queries.

# Project Overview

**1. Database Setup and Structure Overview**

- Used the world_layoffs database.
- Analyzed the structure and initial data in the layoffs table.
  
**2. Data Cleaning**

- Removed duplicates by identifying and deleting repeated records.
- Standardized the data by standardizing and correcting various records and converting the date column from string to SQL date format.
- Dealt with null and blank values by populating data where possible and removing records with essential missing information.
- Removed unnecessary columns after cleaning.

**3. Exploratory Data Analysis (EDA)**

- Identified the maximum number of layoffs and the highest percentage of layoffs.
- Found companies where all employees were laid off.
- Calculated monthly layoffs and the rolling total over time.
- Determined the top companies with the most layoffs each year.

**4. Key Findings**

- The dataset spans from March 2020 to March 2023, covering the COVID-19 pandemic and post-pandemic period.
- Large companies like Google, Amazon, and Meta laid off the most employees during this period.
- The Consumer, Retail, and Transportation sectors experienced the highest layoffs.
- The United States had the most layoffs in this period, followed by India and the Netherlands.
- The total number of layoffs exceeded 380,000.
- The top companies with the most layoffs each year included Uber (2020), Bytedance (2021), Meta (2022), and Google (2023).

# Conclusion
This project demonstrates the power of SQL in cleaning, standardizing, and analyzing a complex dataset. The insights derived can help organizations understand layoff trends and make informed decisions regarding workforce management and industry stability.
