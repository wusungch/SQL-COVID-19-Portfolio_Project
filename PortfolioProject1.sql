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

LOAD DATA LOCAL INFILE '/Users/williamwu/Desktop/mySQL/CovidVaccinations.csv'
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

LOAD DATA LOCAL INFILE '/Users/williamwu/Desktop/mySQL/CovidDeaths.csv'
INTO TABLE coviddeaths
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

-- Show the tables 
SELECT * 
FROM coviddeaths;

SELECT * 
FROM covidvaccinations;

-- finding the death_percentage of each location each day
SELECT location, date_, total_cases, total_deaths, population, (total_deaths/total_cases) * 100 AS death_percentage
FROM coviddeaths
ORDER BY location, date_;

-- finding countries with highest infection rate compared to population 
SELECT location, population, MAX(total_cases / population) * 100 AS highest_infection_rate
FROM coviddeaths
GROUP BY location, population
ORDER BY location, population;

-- finding the percentage of population being infected
SELECT location, MAX(total_cases / population) * 100 AS highest_infection_rate, MAX(total_cases/population) * 100 AS infection_rate
FROM coviddeaths
GROUP BY location
ORDER BY infection_rate DESC;

-- finding each country's total_deaths_count and death_rate
SELECT location, MAX(total_deaths) AS total_deaths_count, MAX(total_deaths/total_cases) * 100 AS death_rate
FROM coviddeaths
GROUP BY location 
ORDER BY total_deaths_count, death_rate;

-- finding each continent's death rate and death count
SELECT location, MAX(total_deaths) AS total_deaths_count, MAX(total_deaths/population) * 100 AS death_rate
FROM coviddeaths 
GROUP BY location 
ORDER BY total_deaths_count, death_rate;

-- finding the global numbers: world_total_deaths, world_death_rate
SELECT date_, SUM(new_cases) AS world_total_cases, SUM(new_deaths) AS world_total_deaths, (SUM(new_deaths))/(SUM(new_cases)) * 100 AS world_death_percentage
FROM coviddeaths
GROUP BY date_;

-- finding the cumulative world cases over time 
SELECT date_, SUM(new_cases) AS daily_world_new_cases, SUM(SUM(new_cases)) OVER (ORDER BY date_) AS cumulative_world_cases
FROM coviddeaths
GROUP BY date_
ORDER BY date_;

-- Creating a new table (using CTE) that shows total population vs total vaccinated after joining the tables coviddeaths and covidvaccinations 
WITH pop_vs_vac_cle (Location, Continent, Date_, Population, New_Vaccinations, Cumulative_Vaccinated)
AS(
	SELECT dea.location, dea.continent, dea.date_, dea.population, new_vaccinations, SUM(new_vaccinations) OVER(PARTITION BY location ORDER BY dea.location, dea.date_) AS Cumulative_vaccinated
	FROM coviddeaths AS dea
	JOIN covidvaccinations AS vac
	ON dea.date_ = vac.date_
		AND dea.location = vac.location 
	WHERE dea.continent <> '' 
)

SELECT *, Cumulative_Vaccinated/Population 
FROM pop_vs_vac_cle;

-- Creating a view (an alternative to table) 
CREATE VIEW pop_vs_vac_view (Location, Continent, Date_, Population, New_Vaccinations, Cumulative_Vaccinated)
AS(
	SELECT dea.location, dea.continent, dea.date_, dea.population, new_vaccinations, SUM(new_vaccinations) OVER(PARTITION BY location ORDER BY dea.location, dea.date_) AS Cumulative_vaccinated
	FROM coviddeaths AS dea
	JOIN covidvaccinations AS vac
	ON dea.date_ = vac.date_
		AND dea.location = vac.location 
	WHERE dea.continent <> '' 
);
