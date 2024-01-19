select * 
 from portfolioproject1..CovidDeaths
order by 3,4

select * 
from portfolioproject1..CovidVaccinations
order by 3,4
--select data that we are going to using

select location,date, total_cases,new_cases,total_deaths,population
 from portfolioproject1..CovidDeaths
order by 1,2

--loooking into total cases vs total deaths
--show likelihood of dying people if you contract covid in your country
select location,date, total_cases,total_deaths, (total_deaths/total_cases)*100 as deathspercentage
 from portfolioproject1..CovidDeaths
 where location like '%pak%'

order by 1,2

--looking at total cases vs population
select location,population ,date, total_cases, (total_cases/population)*100 as deathpercentage
 from portfolioproject1..CovidDeaths
 --where location like '%stat%'

order by 1,2

--looking at countries with highest infection rate compare to population
select location,population , MAx(total_cases) as highestInfectionCount, MAx((total_cases/population))*100 as percentageInfected
 from portfolioproject1..CovidDeaths
 --where location like '%stat%'
 group by location,population
order by percentageInfected desc;

--countries with highest death count per population
select location, MAx(cast(total_deaths as int)) as totalDeathcount
from portfolioproject1..CovidDeaths
 where continent is not null
 group by location
order by totalDeathcount desc

--LET BREAK THNGS DOWN BY CONITINENT
 --SHOWING CONTINENTS WITH THE HIGHEST DEATHS COUNT PER POPULATION

 SELECT continent, max(cast(total_deaths as int))as TotalDeathCount
 from portfolioProject1..coviddeaths
 where continent is not null
 group by continent
 order by totaldeathcount desc

 --Global numbers

 select date, Sum(new_cases) as totalCases, sum(cast(new_deaths as int)) as totalDeaths, sum (cast(new_deaths as int))/ Sum(new_cases)*100 as NewCasesDeathPercentage
 from portfolioproject1..CovidDeaths
 --where location like '%pak%'
 where continent is not null
group by date
order by 1,2

--we are looking into total Population vs vaccinations

select dea.continent, dea.location, dea.date,dea.population,vac.new_vaccinations
,--sum(cast(vac.new_vaccinations as int)) over (partition by dea.location)
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as rollingPeopleVaccinated

--, rollingPeopleVaccinated/population*100
from portfolioproject1..CovidVaccinations as VAC
join portfolioproject1..CovidDeaths as dea
on dea.location=vac.location
and deA.date=vac.date
where dea.continent is not null --and vac.new_vaccinations is not null
order by 2,3

--looking into population vs vaccinations



-- ( we use partition by on dea.location which give us count of all new vaccination for each location 
--but we want the new_vaccination count to add up every single day for every new_vaccination for that
-- we have used order by with date)


--USE CTE

with PopVSVAC 
as(

select dea. continent, dea.location, dea.date, dea.population, vac.total_vaccinations, vac.new_vaccinations
--, sum(cast(vac.new_vaccinations as int)) --  we use cast opeator to get rid of this error "Operand data type nvarchar is invalid for sum operator."
, sum(convert(int,vac.new_vaccinations)) -- we can use covert as well to convert datatype
over (partition by dea.location order by dea.date) 
as RollingCountNoVac-- we used partition by on location because everytime we get to new location we want it go to next location and  startover
from PortfolioProject1..CovidDeaths dea
join portfolioProject1..CovidVaccinations vac
on dea.location=vac.location  and dea.date=vac.date
where dea.continent is not null
--order by 2,3 --we can't use orderby here otherwise error will popup
)
select continent, location, date, population, total_vaccinations, new_vaccinations, RollingCountNoVac, (RollingCountNoVac/population)*100 as PercentagePOPVac
from Popvsvac

-- BY using temp tables

drop table  if exists #PercentPopulationVaccinated
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
From PortfolioProject1..CovidDeaths dea
Join PortfolioProject1..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--create view to store data for later visualization

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject1..CovidDeaths dea
Join PortfolioProject1..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
