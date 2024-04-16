--Agricultural Production data, Porfolio Sample
--  Data Exploration

--Prepare data for use....
--Need to bring in data from individual .csv files for each food item.
--Used Excel...
--Each original .csv is missing the 'Product' field information so food anme needs to be insterted here.
--Remove columns to reduce size and include only the date we will work with (Columns M thru AN, Column I).
--Tidy Column headers/fieldnames.

--Create dbo tables....
--Tasks|Import Flat File | etc


--Database name typo, so rename (Using T-SQL for this example).
ALTER DATABASE [Agricultral Production] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
ALTER DATABASE [Agricultral Production] MODIFY NAME = [Agricultural Production];
GO  
ALTER DATABASE [Agricultural Production] SET MULTI_USER;
GO


--Quick check to view sample set of imported data to confirm we got what excpected. Change db name to check each.
SELECT TOP 100 *
FROM [Agricultural Production].[dbo].[global-food(Vegetables)]


--Sample queries
-- note: FAO meaning - Food and Agriculture Organization of the United Nations 
-- Got a divide by zero error. Some cells have the number 0 where it should be Null. 
--   So included WHERE clause to exclude them.
SELECT Country, Year, Population, Production_per_capita_kg, Land_use_per_capita_m2,
(Production_per_capita_kg/Land_use_per_capita_m2) AS Production_to_land_use_ratio
FROM [Agricultural Production].[dbo].[global-food(Potatoes)]
WHERE Production_per_capita_kg <> 0 OR Land_use_per_capita_m2 <> 0
ORDER BY 1,2 DESC


-- To view and compare Total Production Per Capita by Country
SELECT Country, MAX(Production_per_capita_t) AS Total_production_per_capita_t
FROM [Agricultural Production]..[global-food(Potatoes)]
WHERE Production_per_capita_kg <> 0 OR Land_use_per_capita_m2 <> 0
GROUP BY Country
ORDER BY Total_production_per_capita_t DESC


-- To view and compare Total Production Per Capita by Country for a specified Year
--   add Year in WHERE clause.
SELECT Country, Year, MAX(Production_per_capita_t) AS Total_production_per_capita_t
FROM [Agricultural Production].[dbo].[global-food(Potatoes)]
WHERE Year = 1968 AND Production_per_capita_kg <> 0 AND Land_use_per_capita_m2 <> 0
GROUP BY Country, Year
ORDER BY Total_production_per_capita_t DESC


-- Global info
-- Total Production Per Capita by Year
-- In one CSV the Production_t datatype was nvarchar(50). 
--	Could have used this to resolve: SUM(CAST(Production_t AS INT))
--  However, I set the datatype to float within the Table.
SELECT Year, Production_t, Population, (SUM(Production_t)/SUM(Population)) AS Total_production_per_capita_t
FROM [Agricultural Production]..[global-food(Potatoes)]
WHERE Production_per_capita_kg <> 0 OR Land_use_per_capita_m2 <> 0
GROUP BY Year, Production_t, Population
ORDER BY Total_production_per_capita_t DESC

--Look at Total Vegetagble Production vs Potato Production
SELECT veg.Country, veg.Year, veg.Product, veg.Production_per_capita_t, pot.Product, pot.Production_per_capita_t
FROM [Agricultural Production]..[global-food(Potatoes)] pot
JOIN [Agricultural Production]..[global-food(Vegetables)] veg
 ON pot.Country = veg.Country
 AND pot.Year = veg.Year
ORDER BY 2,1


--Look at Total Vegetagble Production vs Potato Production
-- Add some extra info: 
--	Cumulative total Year on Year by Country
SELECT veg.Country, veg.Year, veg.Product, veg.Production_per_capita_t
, SUM(veg.Production_per_capita_t) OVER (Partition by veg.Country ORDER BY veg.Year, veg.Country) AS veg_Cumulative_prod_per_capita
, pot.Product, pot.Production_per_capita_t
, SUM(pot.Production_per_capita_t) OVER (Partition by veg.Country ORDER BY veg.Year, veg.Country) AS pot_Cumulative_prod_per_capita
FROM [Agricultural Production]..[global-food(Potatoes)] pot
JOIN [Agricultural Production]..[global-food(Vegetables)] veg
 ON pot.Country = veg.Country
 AND pot.Year = veg.Year
ORDER BY 1,2


--Exmaple: To calculate and show the rolling percentage of Production per capita vs the Cumulative Production per capita to date
--	for Product - Vegetables
-- Using a CTE
WITH ProdvCumulative (Country, Year
, veg_Product, veg_Production_per_capita_t, veg_Cumulative_prod_per_capita
, pot_Product, pot_Production_per_capita_t, pot_Cumulative_prod_per_capita)
AS
(
SELECT veg.Country, veg.Year, veg.Product, veg.Production_per_capita_t
, SUM(veg.Production_per_capita_t) OVER (Partition by veg.Country ORDER BY veg.Year, veg.Country) AS veg_Cumulative_prod_per_capita
, pot.Product, pot.Production_per_capita_t
, SUM(pot.Production_per_capita_t) OVER (Partition by veg.Country ORDER BY veg.Year, veg.Country) AS pot_Cumulative_prod_per_capita
FROM [Agricultural Production]..[global-food(Potatoes)] pot
JOIN [Agricultural Production]..[global-food(Vegetables)] veg
 ON pot.Country = veg.Country
 AND pot.Year = veg.Year
)
SELECT Country, Year, (veg_Production_per_capita_t/veg_Cumulative_prod_per_capita)*100 AS veg_ProdvsCumulativePercetange
FROM ProdvCumulative
--
-- Using a TEMP TABLE
DROP TABLE IF EXISTS #veg_ProdvsCumulativePercetange
CREATE TABLE #veg_ProdvsCumulativePercetange
(
Country nvarchar(255),
Year int,
veg_Product nvarchar(255),
veg_Production_per_capita_t float,
veg_Cumulative_prod_per_capita float,
pot_Product nvarchar(255),
pot_Production_per_capita_t float,
pot_Cumulative_prod_per_capita float
)

INSERT INTO #veg_ProdvsCumulativePercetange
SELECT veg.Country, veg.Year, veg.Product, veg.Production_per_capita_t
, SUM(veg.Production_per_capita_t) OVER (Partition by veg.Country ORDER BY veg.Year, veg.Country) AS veg_Cumulative_prod_per_capita
, pot.Product, pot.Production_per_capita_t
, SUM(pot.Production_per_capita_t) OVER (Partition by veg.Country ORDER BY veg.Year, veg.Country) AS pot_Cumulative_prod_per_capita
FROM [Agricultural Production]..[global-food(Potatoes)] pot
JOIN [Agricultural Production]..[global-food(Vegetables)] veg
 ON pot.Country = veg.Country
 AND pot.Year = veg.Year

SELECT Country, Year, (veg_Production_per_capita_t/veg_Cumulative_prod_per_capita)*100 AS veg_ProdvsCumulativePercetange
FROM #veg_ProdvsCumulativePercetange


--View creation for later use in visualisations
CREATE VIEW veg_ProdvsCumulativePercetange
AS
SELECT veg.Country, veg.Year, veg.Product AS veg_Product, veg.Production_per_capita_t AS veg_Production_per_capita_t
, SUM(veg.Production_per_capita_t) OVER (Partition by veg.Country ORDER BY veg.Year, veg.Country) AS veg_Cumulative_prod_per_capita
, pot.Product AS pot_Product, pot.Production_per_capita_t AS pot_Production_per_capita_t
, SUM(pot.Production_per_capita_t) OVER (Partition by veg.Country ORDER BY veg.Year, veg.Country) AS pot_Cumulative_prod_per_capita
FROM [Agricultural Production]..[global-food(Potatoes)] pot
JOIN [Agricultural Production]..[global-food(Vegetables)] veg
 ON pot.Country = veg.Country
 AND pot.Year = veg.Year


