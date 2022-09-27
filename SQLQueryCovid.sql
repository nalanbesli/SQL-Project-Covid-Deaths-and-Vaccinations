/*
Analyzing world wide Covid 19 Data 
Source: https://ourworldindata.org/covid-deaths
Skills used: Joins, CTE's, Subqueries, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/
--Exploring data

SELECT *
FROM Portfolio..CovidDeaths
ORDER BY 3,4


SELECT *
FROM Portfolio..CovidVaccination
ORDER BY 3,4


--Looking at Total Cases vs Population

SELECT location, date, total_cases, total_deaths, population
FROM Portfolio..CovidDeaths
ORDER BY 1,2

--Loking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in Turkey

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM Portfolio..CovidDeaths
WHERE location = 'Turkey'
ORDER BY 2


--Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount
, MAX((total_cases/population))*100 AS InfectedPercentage
FROM Portfolio..CovidDeaths
GROUP BY location, population
ORDER BY 4 DESC


--Showing countries with Highest Death Count per Population

SELECT location, population, MAX(CAST (total_deaths AS int)) AS TotalDeathCount
FROM Portfolio..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY TotalDeathCount DESC

--Showing continents Total Deaths and Total People who are fully vaccinated with percentages.

SELECT dea.location, dea.population, MAX(CAST (dea.total_deaths AS int)) AS TotalDeathCount
, MAX((dea.total_deaths/dea.population))*100 AS DeathPercentage
, max(vac.people_fully_vaccinated) as PeopleFullyVaccinated
, MAX((vac.people_fully_vaccinated/dea.population))*100 AS VaccinatedPercentage
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE 
dea.continent is null AND
dea.location IN ('World','Europe', 'North America', 'Asia', 'South America', 'Africa', 'Oceania')
GROUP BY dea.location, dea.population
ORDER BY 2 DESC


--Showing countries with Highest Death Count and Total People who are fully vaccinated with percentages.

SELECT dea.location, dea.population, MAX(CAST (dea.total_deaths AS int)) AS TotalDeathCount
, MAX((dea.total_deaths/dea.population))*100 AS DeathPercentage
, max(vac.people_fully_vaccinated) as PeopleFullyVaccinated
, MAX((vac.people_fully_vaccinated/dea.population))*100 AS VaccinatedPercentage
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE 
dea.continent is not null
GROUP BY dea.location, dea.population
ORDER BY 3 DESC


--Global Numbers
--By date
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Portfolio..CovidDeaths
where continent is not null 
Group By date
order by 1,2

--Total
SELECT (SELECT population 
FROM Portfolio..CovidDeaths 
WHERE continent is null AND
location IN ('World') 
GROUP BY location,population) AS WorldPopulation
, SUM(dea.new_cases) as total_cases, SUM(CAST(dea.new_deaths AS int)) AS total_deaths
, SUM(CAST(dea.new_deaths AS int))/SUM(dea.new_cases)*100 AS DeathPercentage
, MAX(vac.people_fully_vaccinated) AS PeopleFullyVaccinated
, MAX((vac.people_fully_vaccinated/dea.population))*100 AS VaccinatedPercentage
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null


--Looking at Total Population vs Vaccinations
-- Shows how many Covid Vaccine has recieved.

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location
, dea.Date ROWS UNBOUNDED PRECEDING) AS RollingPeopleVaccinated
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3


--Total Population vs Vaccinations in Turkey
-- Shows how many Covid Vaccine has recieved.

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location
, dea.Date ROWS UNBOUNDED PRECEDING) AS RollingPeopleVaccinated
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.location = 'turkey'
ORDER BY 2, 3


-- Using CTE to perform Calculation on Partition By in previous query
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location
, dea.Date ROWS UNBOUNDED PRECEDING) AS RollingPeopleVaccinated
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio..CovidDeaths dea
Join Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentofPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio..CovidDeaths dea
Join Portfolio..CovidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


Create View Infection_Rate_Vaccination_Rate_byCountry as
SELECT dea.location, dea.population, MAX(CAST (dea.total_deaths AS int)) AS TotalDeathCount
, MAX((dea.total_deaths/dea.population))*100 AS DeathPercentage
, max(vac.people_fully_vaccinated) as PeopleFullyVaccinated
, MAX((vac.people_fully_vaccinated/dea.population))*100 AS VaccinatedPercentage
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE 
dea.continent is not null
GROUP BY dea.location, dea.population

