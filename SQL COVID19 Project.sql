-- LOAD DATA IN FILE, a faster alternative way to IMPORT DATA WIZARD
-- creating and importing table covidvaccinations
DROP TABLE IF EXISTS covidvaccinations;
CREATE TABLE covidvaccinations(
iso_code text, 
continent text,
location text,
date_ date,
total_cases	int,
new_cases int,
new_cases_smoothed int,
total_vaccinations int,
people_vaccinated int,
people_fully_vaccinated	int, 
total_boosters int, 
new_vaccinations int,
new_vaccinations_smoothed float, 
total_vaccinations_per_hundred float,
people_vaccinated_per_hundred float, 
people_fully_vaccinated_per_hundred float,
total_boosters_per_hundred float,
new_vaccinations_smoothed_per_million float,
new_people_vaccinated_smoothed float,
new_people_vaccinated_smoothed_per_hundred float
);

SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE '/Users/williamwu/Desktop/Tableau/Tableau Intro Course/CovidVaccinations.csv'
INTO TABLE covidvaccinations
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

-- creating and importing table coviddeaths
DROP TABLE IF EXISTS coviddeaths;
CREATE TABLE coviddeaths(
iso_code text,
continent text, 
location text,
date_ date,
total_cases int, 
new_cases int,
new_cases_smoothed float,
total_deaths int, 
new_deaths int,
new_deaths_smoothed	float, 
total_cases_per_million float,
new_cases_per_million float,
new_cases_smoothed_per_million float,
total_deaths_per_million float,
new_deaths_per_million float,
new_deaths_smoothed_per_million float,
reproduction_rate float,
icu_patients int,
icu_patients_per_million float,
hosp_patients int,
hosp_patients_per_million float,
weekly_icu_admissions int,
weekly_icu_admissions_per_million float,
weekly_hosp_admissions int,
weekly_hosp_admissions_per_million	float,
total_tests int,
new_tests int,
total_tests_per_thousand float,
new_tests_per_thousand float, 
new_tests_smoothed int, 
new_tests_smoothed_per_thousand	float, 
positive_rate float,
tests_per_case float,
tests_units	text, 
stringency_index float,
population_density float,
median_age float,
aged_65_older float,
aged_70_older float,
gdp_per_capita float, 
extreme_poverty	float, 
cardiovasc_death_rate float,
diabetes_prevalence float,
female_smokers	float, 
male_smokers float,
handwashing_facilities	float,
hospital_beds_per_thousand float,
life_expectancy	float,
human_development_index	float,
population int,
excess_mortality_cumulative_absolute float,
excess_mortality_cumulative	float, 
excess_mortality float,
excess_mortality_cumulative_per_million float
);

LOAD DATA LOCAL INFILE '/Users/williamwu/Desktop/Tableau/Tableau Intro Course/CovidDeaths.csv'
INTO TABLE coviddeaths
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

-- dropping unnecessary and duplicate columns in coviddeaths
ALTER TABLE coviddeaths
DROP COLUMN new_cases_smoothed,
DROP COLUMN new_deaths_smoothed,
DROP COLUMN total_cases_per_million,
DROP COLUMN new_cases_per_million,
DROP COLUMN new_cases_smoothed_per_million,
DROP COLUMN total_deaths_per_million,
DROP COLUMN new_deaths_per_million,
DROP COLUMN new_deaths_smoothed_per_million,
DROP COLUMN icu_patients_per_million,
DROP COLUMN hosp_patients_per_million,
DROP COLUMN weekly_icu_admissions_per_million,
DROP COLUMN weekly_hosp_admissions_per_million,
DROP COLUMN total_tests_per_thousand, 
DROP COLUMN new_tests_smoothed_per_thousand,
DROP COLUMN excess_mortality_cumulative_absolute,
DROP COLUMN excess_mortality_cumulative,
DROP COLUMN excess_mortality,
DROP COLUMN excess_mortality_cumulative_per_million,
DROP COLUMN new_tests_per_thousand,
DROP COLUMN new_tests_smoothed;

-- dropping unnecessary and duplicate columns in covidvaccinations
ALTER TABLE covidvaccinations
DROP COLUMN total_cases,
DROP COLUMN new_cases,
DROP COLUMN new_cases_smoothed,
DROP COLUMN total_vaccinations_per_hundred,
DROP COLUMN people_vaccinated_per_hundred, 
DROP COLUMN people_fully_vaccinated_per_hundred, 
DROP COLUMN new_vaccinations_smoothed_per_million,
DROP COLUMN new_people_vaccinated_smoothed,
DROP COLUMN new_people_vaccinated_smoothed_per_hundred,
DROP COLUMN total_boosters_per_hundred; 

-- Show the tables 
SELECT * 
FROM coviddeaths;

SELECT * 
FROM covidvaccinations;

-- finding the death_percentage of each location each day
SELECT location, date_, total_cases, total_deaths, population, (total_deaths/total_cases) * 100 AS death_percentage
FROM coviddeaths
ORDER BY location, date_;

-- finding the top 10 countries that experienced the highest infection rate compared to population 
SELECT *
FROM (SELECT location, population, ROUND(MAX(total_cases / population) * 100, 2) AS highest_infection_rate
	FROM coviddeaths
	GROUP BY location, population) AS sub 
ORDER BY highest_infection_rate DESC
LIMIT 10;

-- finding each country's total_deaths_count and death_rate 
-- Insight 1: The US, Brazil, India, Russia, Mexico have the highest deaths counts caused by COVID-19.
-- Insight 2: Some countries, including France, UK, and Germany have extremely high death rate that exceeds 100%, which shows 
-- there might be inaccuracies in the data. 
CREATE VIEW continent_list AS
SELECT DISTINCT continent 
FROM coviddeaths
WHERE continent <> '';

SELECT location, MAX(total_deaths) AS total_deaths_count, ROUND(MAX(total_deaths/total_cases) * 100, 2) AS death_rate
FROM coviddeaths
WHERE location NOT IN (SELECT 'World' AS location
						UNION SELECT 'High income' AS location
						UNION SELECT 'Upper middle income' AS location
						UNION SELECT 'Lower middle income' AS location
						UNION SELECT 'European Union' AS location
                        UNION SELECT continent FROM continent_list) 
GROUP BY location 
ORDER BY total_deaths_count DESC, death_rate DESC;

-- finding each continent's death rate and death count
-- Insight: Among all the continents, South America has the highest death rate of 0.31%, and Africa has the lowest death rate of 0.02%.
SELECT location, MAX(total_deaths) AS total_deaths_count, ROUND(MAX(total_deaths/population) * 100, 2) AS death_rate
FROM coviddeaths 
WHERE location IN (SELECT continent FROM continent_list)
GROUP BY location 
ORDER BY death_rate DESC;

-- finding the cumulative world cases over time 
SELECT date_, SUM(new_cases) AS daily_world_new_cases, SUM(SUM(new_cases)) OVER (ORDER BY date_) AS cumulative_world_cases
FROM coviddeaths
GROUP BY date_
ORDER BY date_;

-- Table that shows cumulative number of people vaccinated
WITH pop_vs_vac_cle (Location, Continent, Date_, Population, New_Vaccinations, Cumulative_Vaccinated)
AS(
	SELECT dea.location, dea.continent, dea.date_, dea.population, new_vaccinations, SUM(new_vaccinations) OVER(PARTITION BY location ORDER BY dea.location, dea.date_) AS Cumulative_vaccinated
	FROM coviddeaths AS dea
	JOIN covidvaccinations AS vac
	ON dea.date_ = vac.date_
		AND dea.location = vac.location 
	WHERE dea.continent <> '' 
)
SELECT *, ROUND(Cumulative_Vaccinated/Population * 100, 2) AS Cumulative_Vaccinated_Percentage
FROM pop_vs_vac_cle;


-- GOAL: Compare the percentage of population infected by and dead caused by COVID-19 between low-income, middle-income, and high-income countries 
-- mortality rate = total deaths/total population * 100K 
-- Low-income countries have GDP per capita < $1035 USD 
-- Middle-income between 1036 and 4085
-- High-income countries > 4086
	
CREATE VIEW wealth_list AS
	SELECT DISTINCT iso_code, CASE WHEN gdp_per_capita < 1036 THEN 'Low-income'
			  ELSE (CASE WHEN gdp_per_capita < 4086 THEN 'Middle-income' 
			  ELSE 'High-income' END) END AS wealth
	FROM coviddeaths;

SELECT wealth AS wealth_category, 
		AVG(percentage_infected) AS percentage_infected, 
		AVG(death_percentage) AS death_percentage, 
        AVG(hospital_beds_per_thousand) AS hospital_beds_per_thousand
FROM (SELECT iso_code, 
			location, 
			AVG(gdp_per_capita) AS gdp_per_capita,
			AVG(population) AS population, 
			ROUND(MAX(total_cases/population) * 100, 2) AS percentage_infected, 
			ROUND(MAX(total_deaths/population) * 100, 2) AS death_percentage, 
			AVG(hospital_beds_per_thousand) AS hospital_beds_per_thousand
	FROM coviddeaths
	GROUP BY iso_code, location) AS sub 
LEFT JOIN wealth_list
USING (iso_code) 
GROUP BY wealth;

-- We also want to compare the percentage of population vaccinated among the three wealth categories
-- Insight 1: High-income countries have the highest vaccination rate of 65.66% and surprisingly middle-income countries have the lowest
-- vaccination rate of 40.53%. Low-income countries have 46.97%. 
SELECT wealth, ROUND(AVG(people_vaccinated/population) * 100, 2) AS vaccination_rate
FROM (SELECT v.iso_code, location, AVG(population) AS population, MAX(people_vaccinated) AS people_vaccinated
	FROM covidvaccinations AS v
	LEFT JOIN (SELECT iso_code, date_, population FROM coviddeaths) AS d
	ON v.iso_code = d.iso_code AND v.date_ = d.date_
    WHERE location NOT IN (SELECT 'World' AS location
						UNION SELECT 'High income' AS location
						UNION SELECT 'Upper middle income' AS location
						UNION SELECT 'Lower middle income' AS location
						UNION SELECT 'European Union' AS location
                        UNION SELECT continent FROM continent_list) 
	GROUP BY iso_code, location) AS sub
LEFT JOIN wealth_list
USING (iso_code)
GROUP BY wealth;

-- Conclusion:
-- Despite having the lowest vaccination rate, middle-income countries have the lowest percentage of their population infected by
-- COVID-19 (2.86%).
-- The number of hospital beds per thousand shows 


