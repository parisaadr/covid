SELECT * FROM coviddeaths;
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
ORDER BY 1, YEAR(20);

SELECT location,total_deaths, date
FROM coviddeaths
WHERE location = 'iran';

-- looking at total cases vs total deaths
-- the likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, population, (total_deaths/total_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE location = 'IRAN'
ORDER BY 1, YEAR(20);

-- looking at total cases vs population
-- what percentage of population got covid
SELECT * FROM coviddeaths;
SELECT location, date, total_cases, total_deaths, population, (total_cases/population)*100 AS InfectedPercentage
FROM coviddeaths
WHERE location = 'south korea'
ORDER BY 1, YEAR(20);

-- looking at countries with highest infection rate compared to populations

SELECT location, MAX(total_cases) AS HighestInfectionCount, population,
       MAX((total_cases/population))*100 AS InfectedPercentage
FROM coviddeaths
WHERE total_cases IS NOT NULL
GROUP BY location, population
ORDER BY InfectedPercentage DESC;

-- showing countries with highest death count per population

SELECT location, MAX(total_deaths) AS TotalDeathCounts
FROM coviddeaths
WHERE continent IS NOT NULL
-- WHERE location = 'IRAN'
GROUP BY location
ORDER BY TotalDeathCounts DESC;

-- now we're gonna deal with continents instead of countries

SELECT location, MAX(total_deaths) AS TotalDeathCounts
FROM coviddeaths
WHERE continent IS NULL
-- WHERE location = 'IRAN'
GROUP BY location
ORDER BY TotalDeathCounts DESC;

-- showing the continents with the highest death counts

SELECT continent, MAX(total_deaths) AS TotalDeathCounts
FROM coviddeaths
WHERE continent IS NOT NULL
-- WHERE location = 'IRAN'
GROUP BY continent
ORDER BY TotalDeathCounts DESC;

-- global numbers

SELECT date, SUM(new_cases),SUM(new_deaths)
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, YEAR(20);

SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1,2;

-- looking at total population vs vaccination

SELECT coviddeaths.continent, coviddeaths.location,coviddeaths.date, population, new_vaccinations
FROM coviddeaths
JOIN covidvaccinations
ON coviddeaths.location = covidvaccinations.location
AND coviddeaths.date = covidvaccinations.date
WHERE coviddeaths.continent IS NOT NULL
ORDER BY 1,2,3 ;


SELECT coviddeaths.continent, coviddeaths.location,coviddeaths.date, population, new_vaccinations,
       SUM(new_vaccinations) OVER (PARTITION BY coviddeaths.location ORDER BY coviddeaths.location, coviddeaths.date) AS
RollingPeopleVAXX,(RollingPeopleVAXX/population)*100 AS XX
FROM coviddeaths
JOIN covidvaccinations
ON coviddeaths.location = covidvaccinations.location
AND coviddeaths.date = covidvaccinations.date
WHERE coviddeaths.continent IS NOT NULL
ORDER BY continent, location;

-- we can't really use rollingpeoplevaxx so we're gonna use CTE

WITH PopvsVac (continent,
               location,
               date,
               population,
               new_vaccinations,RollingPeopleVAXX, VAXXDead)
    AS (
    SELECT coviddeaths.continent,
               coviddeaths.location,
               coviddeaths.date,
               population,
               new_vaccinations,
               SUM(new_vaccinations)
                   OVER (PARTITION BY coviddeaths.location ORDER BY coviddeaths.location, coviddeaths.date) AS
                   RollingPeopleVAXX, (RollingPeopleVAXX/coviddeaths.population) * 100 AS VAXXDead
        FROM coviddeaths
                 JOIN covidvaccinations
                      ON coviddeaths.location = covidvaccinations.location
                          AND coviddeaths.date = covidvaccinations.date
        WHERE coviddeaths.continent IS NOT NULL)
        -- ORDER BY continent, location)

SELECT *, (RollingPeopleVAXX/population)*100 AS VAXXDead
FROM PopvsVac;

-- temp table
DROP TABLE IF EXISTS percentpopulationvaxx;

CREATE TABLE percentpopulationvaxx(
SELECT coviddeaths.continent, coviddeaths.location, coviddeaths.date, population, covidvaccinations.new_vaccinations
FROM coviddeaths
JOIN covidvaccinations
ON coviddeaths.iso_code = covidvaccinations.iso_code
AND coviddeaths.date = covidvaccinations.date);

SELECT * FROM percentpopulationvaxx WHERE new_vaccinations IS NOT NULL ;
SELECT * FROM percentpopulationvaxx WHERE RollingPeopleVAXX IS NOT NULL ;
SELECT * FROM percentpopulationvaxx;

ALTER TABLE percentpopulationvaxx ADD COLUMN VAXXDead DOUBLE  PRECISION;
INSERT INTO percentpopulationvaxx (percentpopulationvaxx.VAXXDead) SELECT VAXXDead FROM coviddeaths;
ALTER TABLE percentpopulationvaxx ADD COLUMN RollingPeopleVAXX DOUBLE PRECISION;
INSERT INTO percentpopulationvaxx (percentpopulationvaxx.RollingPeopleVAXX) SELECT RollingPeopleVAXX FROM coviddeaths;


INSERT INTO percentpopulationvaxx (percentpopulationvaxx.RollingPeopleVAXX, percentpopulationvaxx.VAXXDead)
SELECT SUM(new_vaccinations) OVER (PARTITION BY coviddeaths.location ORDER BY coviddeaths.location, coviddeaths.date) AS RollingPeopleVAXX,
(coviddeaths.RollingPeopleVAXX/population)*100 AS VAXXDead
FROM coviddeaths
JOIN covidvaccinations
ON coviddeaths.date = covidvaccinations.date
AND coviddeaths.location = covidvaccinations.location
WHERE coviddeaths.continent IS NOT NULL;





