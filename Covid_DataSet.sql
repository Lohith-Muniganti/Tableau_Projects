SELECT *
FROM [Git Project1]..Covid_Deaths
WHERE continent is null

--Total cases by Country--
  
SELECT continent,location,date,total_cases,SUM(new_cases) AS Total_Cases
FROM [Git Project1]..Covid_Deaths
WHERE location = 'China'
GROUP BY location,date,continent,total_cases
ORDER BY date

--Population tracking--

--Negligbe Difference betweene Death_Rate and DaytoDay_Death_Rate--So we can avooid it in our Viz--

SELECT continent,location,date,population,total_cases,new_cases,
CAST(total_deaths as int) AS Total_Deaths,
CAST(new_deaths as int) AS New_Deaths,
(population - (CAST(total_deaths as int))) AS Present_Population,
ROUND((CAST(total_deaths as int)/population)*100,5) AS Death_Rate,
ROUND((CAST(total_deaths as int)/(population - (CAST(total_deaths as int))))*100,5) AS DaytoDay_Death_Rate,
reproduction_rate
FROM [Git Project1]..Covid_Deaths
WHERE continent is not NULL 
GROUP BY date,location,continent,population,Total_Deaths,New_Deaths,reproduction_rate,total_cases,new_cases
ORDER BY date,Total_Deaths DESC		

--Eliminating groupby caluse with subquery---

SELECT *
FROM (
SELECT continent,location,date,population,total_cases,new_cases,
CAST(total_deaths as int) AS Total_Deaths,
CAST(new_deaths as int) AS New_Deaths,
(population - (CAST(total_deaths as int))) AS Present_Population,
ROUND((CAST(total_deaths as int)/population)*100,5) AS Death_Rate,
ROUND((CAST(total_deaths as int)/(population - (CAST(total_deaths as int))))*100,5) AS DaytoDay_Death_Rate,
reproduction_rate
FROM [Git Project1]..Covid_Deaths) AS Covid_Deaths1
WHERE continent is not NULL
ORDER BY date

--Joining Vaccination Table on Countries--

SELECT Covid_Deaths1.continent,Covid_Deaths1.location,Covid_Deaths1.date,
Covid_Deaths1.population,Covid_Deaths1.total_cases,Covid_Deaths1.new_cases,
Covid_Deaths1.Total_Deaths,Covid_Deaths1.New_Deaths,Covid_Deaths1.Present_Population,
Covid_Deaths1.Death_Rate,Covid_Deaths1.DaytoDay_Death_Rate,new_vaccinations
FROM (
SELECT continent,location,date,population,total_cases,new_cases,
CAST(total_deaths as int) AS Total_Deaths,
CAST(new_deaths as int) AS New_Deaths,
(population - (CAST(total_deaths as int))) AS Present_Population,
ROUND((CAST(total_deaths as int)/population)*100,5) AS Death_Rate,
ROUND((CAST(total_deaths as int)/(population - (CAST(total_deaths as int))))*100,5) AS DaytoDay_Death_Rate,
reproduction_rate
FROM [Git Project1]..Covid_Deaths) AS Covid_Deaths1
JOIN [Git Project1]..Covid_Vaccinations ON
Covid_Deaths1.location = Covid_Vaccinations.location
and Covid_Deaths1.date = Covid_Vaccinations.date
WHERE Covid_Deaths1.continent is not NULL
ORDER BY Covid_Deaths1.date


--Joining Vaccination Table on Continent--

SELECT Covid_Deaths1.location,Covid_Deaths1.date,
Covid_Deaths1.population,Covid_Deaths1.total_cases,Covid_Deaths1.new_cases,
Covid_Deaths1.Total_Deaths,Covid_Deaths1.New_Deaths,Covid_Deaths1.Present_Population,
Covid_Deaths1.Death_Rate,Covid_Deaths1.DaytoDay_Death_Rate,
ISNULL(Covid_Vaccinations.total_vaccinations,0) AS Total_Vaccinations,ISNULL(Covid_Vaccinations.new_vaccinations,0) AS New_Vaccinations,Covid_Deaths1.reproduction_rate
FROM (
SELECT continent,location,date,population,total_cases,new_cases,
ISNULL(CAST(total_deaths as int),0) AS Total_Deaths,
CAST(new_deaths as int) AS New_Deaths,
ISNULL((population - (CAST(total_deaths as int))),0) AS Present_Population,
ISNULL(ROUND((CAST(total_deaths as int)/population)*100,5),0) AS Death_Rate,
ISNULL(ROUND((CAST(total_deaths as int)/(population - (CAST(total_deaths as int))))*100,5),0) AS DaytoDay_Death_Rate,
ISNULL(reproduction_rate,0) 
FROM [Git Project1]..Covid_Deaths) AS Covid_Deaths1
JOIN [Git Project1]..Covid_Vaccinations ON
Covid_Deaths1.location = Covid_Vaccinations.location
and Covid_Deaths1.date = Covid_Vaccinations.date
WHERE Covid_Deaths1.continent is NULL
ORDER BY Covid_Deaths1.date

--Using Temporary tables--

WITH Covid_Data(continent,location,date,
population,total_cases,new_cases,
Total_Deaths,New_Deaths,Present_Population,
Death_Rate,DaytoDay_Death_Rate,reproduction_rate,New_Vaccinations_Day,Vaccinated_Population)
AS(
SELECT Covid_Deaths1.continent,Covid_Deaths1.location,Covid_Deaths1.date,Covid_Deaths1.population,
ISNULL(Covid_Deaths1.total_cases,0),
ISNULL(Covid_Deaths1.new_cases,0),
ISNULL(CAST(total_deaths as int),0) AS Total_Deaths,
ISNULL(CAST(new_deaths as int),0) AS New_Deaths,
ISNULL((Covid_Deaths1.population - (CAST(total_deaths as int))),0) AS Present_Population,
ISNULL(ROUND((CAST(total_deaths as int)/Covid_Deaths1.population)*100,5),0) AS Death_Rate,
ISNULL(ROUND((CAST(total_deaths as int)/(Covid_Deaths1.population - (CAST(total_deaths as int))))*100,5),0) AS DaytoDay_Death_Rate,
ISNULL(reproduction_rate,0),ISNULL(Covid_Vaccinations.new_vaccinations,0) AS New_Vaccinations_Day,
ISNULL(SUM(CAST(Covid_Vaccinations.new_vaccinations AS int)) OVER (PARTITION BY Covid_Deaths1.location ORDER BY Covid_Deaths1.date,Covid_Deaths1.location),0) AS Vaccinated_Population
FROM [Git Project1]..Covid_Deaths AS Covid_Deaths1
JOIN [Git Project1]..Covid_Vaccinations ON
Covid_Deaths1.location = Covid_Vaccinations.location
and Covid_Deaths1.date = Covid_Vaccinations.date
)
SELECT * FROM Covid_Data
WHERE Covid_Data.continent is not NULL
ORDER BY Covid_Data.date

--Creating a Final table--

CREATE TABLE [Git Project1].[dbo].Covid_Data
(
continent nvarchar(200),location nvarchar(200),
date Date ,population numeric,
total_cases numeric,new_cases numeric,
Total_Deaths numeric, New_Deaths numeric,
Present_Population numeric,Death_Rate float,DaytoDay_Death_Rate float,
reproduction_rate float, New_Vaccinations_Day numeric,
Vaccinated_Population numeric
)
INSERT INTO [Git Project1].[dbo].Covid_Data
SELECT Covid_Deaths1.continent,Covid_Deaths1.location,Covid_Deaths1.date,Covid_Deaths1.population,
ISNULL(Covid_Deaths1.total_cases,0),
ISNULL(Covid_Deaths1.new_cases,0),
ISNULL(CAST(total_deaths as int),0) AS Total_Deaths,
ISNULL(CAST(new_deaths as int),0) AS New_Deaths,
ISNULL((Covid_Deaths1.population - (CAST(total_deaths as int))),0) AS Present_Population,
ISNULL(ROUND((CAST(total_deaths as int)/Covid_Deaths1.population)*100,5),0) AS Death_Rate,
ISNULL(ROUND((CAST(total_deaths as int)/(Covid_Deaths1.population - (CAST(total_deaths as int))))*100,5),0) AS DaytoDay_Death_Rate,
ISNULL(reproduction_rate,0),ISNULL(Covid_Vaccinations.new_vaccinations,0) AS New_Vaccinations_Day,
ISNULL(SUM(CAST(Covid_Vaccinations.new_vaccinations AS int)) OVER (PARTITION BY Covid_Deaths1.location ORDER BY Covid_Deaths1.date,Covid_Deaths1.location),0) AS Vaccinated_Population
FROM [Git Project1]..Covid_Deaths AS Covid_Deaths1
JOIN [Git Project1]..Covid_Vaccinations ON
Covid_Deaths1.location = Covid_Vaccinations.location
and Covid_Deaths1.date = Covid_Vaccinations.date
WHERE Covid_Deaths1.continent is not NULL

Select * FROM [Git Project1]..Covid_Data
WHERE location ='China'
Order BY Death_Rate DESC

--Creating Final table with Conslidated count only continents--

CREATE TABLE [Git Project1].[dbo].Covid_Data1
(
location nvarchar(200),
date Date ,population numeric,
total_cases numeric,new_cases numeric,
Total_Deaths numeric, New_Deaths numeric,
Present_Population numeric,Death_Rate float,DaytoDay_Death_Rate float,
reproduction_rate float, New_Vaccinations_Day numeric,
Vaccinated_Population numeric
)
INSERT INTO [Git Project1].[dbo].Covid_Data1
SELECT Covid_Deaths1.location,Covid_Deaths1.date,Covid_Deaths1.population,
ISNULL(Covid_Deaths1.total_cases,0),
ISNULL(Covid_Deaths1.new_cases,0),
ISNULL(CAST(total_deaths as int),0) AS Total_Deaths,
ISNULL(CAST(new_deaths as int),0) AS New_Deaths,
ISNULL((Covid_Deaths1.population - (CAST(total_deaths as int))),0) AS Present_Population,
ISNULL(ROUND((CAST(total_deaths as int)/Covid_Deaths1.population)*100,5),0) AS Death_Rate,
ISNULL(ROUND((CAST(total_deaths as int)/(Covid_Deaths1.population - (CAST(total_deaths as int))))*100,5),0) AS DaytoDay_Death_Rate,
ISNULL(reproduction_rate,0),ISNULL(Covid_Vaccinations.new_vaccinations,0) AS New_Vaccinations_Day,
ISNULL(SUM(CAST(Covid_Vaccinations.new_vaccinations AS int)) OVER (PARTITION BY Covid_Deaths1.location ORDER BY Covid_Deaths1.date,Covid_Deaths1.location),0) AS Vaccinated_Population
FROM [Git Project1]..Covid_Deaths AS Covid_Deaths1
JOIN [Git Project1]..Covid_Vaccinations ON
Covid_Deaths1.location = Covid_Vaccinations.location
and Covid_Deaths1.date = Covid_Vaccinations.date
WHERE Covid_Deaths1.continent is NULL AND Covid_Deaths1.location NOT IN ('International','European Union','World')

Select * FROM [Git Project1]..Covid_Data1