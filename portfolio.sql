select * from covid_deaths
where continent is not null
order by 3,4


select location, date, total_cases, new_cases, total_deaths, population
from covid_deaths
order by 1,2

--looking at total cases vs total deaths
select location, date, total_cases, total_deaths,
case
when total_cases = 0 then null
else (total_deaths::numeric / total_cases)*100
end as death_rate
from covid_deaths
where location like '%States%'
order by 1,2

--looking at totalcases vs population
select location, date, total_cases, population, total_deaths,
case
when total_cases = 0 then null
else (total_cases::numeric / population)*100
end as death_rate
from covid_deaths
where location like '%States'
order by 1,2

--looking at countries with highest infection rate compared to population
select location, max(total_cases)as highest_infection_count, population, max(total_deaths)as total_deaths,
case
when max(total_cases) = 0 then null
else (max(total_cases)::numeric / max(population))*100
end as percent_population_infected
from covid_deaths
group by location, population
order by percent_population_infected desc


--showing the countries with highest death count per population
select location, max(cast(total_deaths as int)) as highest_death_count
from covid_deaths
where continent is not null
group by location
having max(cast(total_deaths as int)) is not null
order by highest_death_count desc

--let's break things down by continent
--showing continents with the highest death count per population
select continent, max(cast(total_deaths as int)) as total_death_count
from covid_deaths
where continent is not null
group by continent
order by total_death_count desc

--global numbers
SELECT date, 
    SUM(total_cases) AS total_cases, 
    SUM(total_deaths) AS total_deaths, 
    (SUM(total_deaths) / SUM(total_cases)) * 100 AS death_percentage 
FROM 
    covid_deaths 
WHERE 
    continent IS NOT NULL 
    AND total_cases IS NOT NULL 
GROUP BY 
    date 
ORDER BY 
    1,2
	
--looking at total population vs vaccinations
with popvsvac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.date) as rolling_people_vaccinated
from covid_deaths dea
join covid_vaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3
)
select *, (rolling_people_vaccinated::float / population)*100 as percentage_vaccinated
from popvsvac

--temp table
create table percent_population_vaccinated
(
 continent varchar(255),
 location varchar(255),
 date timestamp,
 population numeric(18, 2),
 new_vaccinations numeric(18, 2),
 rolling_people_vaccinated numeric(18, 2)

)
insert into percent_population_vaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.date) as rolling_people_vaccinated
from covid_deaths dea
join covid_vaccinations vac
on dea.location = vac.location
and dea.date = vac.date

select *, (rolling_people_vaccinated::float / population)*100 as percentage_vaccinated
from percent_population_vaccinated

--creating view to store data for later visualizations

CREATE VIEW percent_population_vaccinated1 AS
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.date) as rolling_people_vaccinated
from covid_deaths dea
join covid_vaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
