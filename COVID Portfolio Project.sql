USE PortfolioProject

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT null
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

-- SELECT Data that I will be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT null
ORDER BY 1,2

-- Looking at total cases VS total deaths
-- Shows the likelihood of dying if you contracted Covid in Belgium in 2020-2021

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE 'belgium'
ORDER BY 1,2

--Looking at total cases VS population
--Shows percentage of population who contracted Covid

SELECT Location, date, total_cases, population, (total_deaths/population)*100 as ContractionPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE 'belgium'
ORDER BY 1,2

--Looking at countries with the highest infection rate compared to population

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectedPopulationPercentage
FROM PortfolioProject..CovidDeaths
--WHERE continent IS NOT null
GROUP BY location, population
ORDER BY InfectedPopulationPercentage DESC 

-- Same but with date

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population, date
order by PercentPopulationInfected desc

--Showing countries with the highest death count per population

SELECT continent, Location, MAX(cast(total_deaths as int)) as HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT null
GROUP BY continent, location
ORDER BY HighestDeathCount DESC 

-- Showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) as HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT  null
GROUP BY continent
ORDER BY HighestDeathCount DESC 



-- Global Numbers



SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 


-- Taking the total death count for the world, not including the EU since it's part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc


-- Looking at total population VS vaccinations


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as VaccinationSum
	--(VaccinationSum/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
ORDER BY 2,3

--CTE

WITH PopVSVacc (Continent, Location, Date, Population, New_Vaccinations, VaccinationSum)
as
(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as VaccinationSum
	--(VaccinationSum/population)*100
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent is not null 
	--ORDER BY 2,3
)
SELECT *, (VaccinationSum/Population)*100 as VaccinatedPercentage
FROM PopVSVacc

--Temp Table

DROP Table if exists #PercentagePopulationVaccinated
CREATE Table #PercentagePopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric, 
	New_Vaccinations numeric, 
	VaccinationSum numeric
)

INSERT INTO #PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as VaccinationSum
	--(VaccinationSum/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 


SELECT *, (VaccinationSum/Population)*100 as VaccinatedPercentage
FROM #PercentagePopulationVaccinated



-- Creating View to store data for later visualizations

CREATE View VaccinatedPercentageView as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as VaccinationSum
	--(VaccinationSum/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 

SELECT *
FROM VaccinatedPercentageView