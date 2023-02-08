--PRESCRIPTION DRUG PROJECT--

--KEY DATA SOURCES
--PUF=public use file of PRESCRIPTION DRUG EVENTS
--for Medicare & Medicaid(CMS) beneficiaries with a Part D prescription drug plan
--for YEARS 2013- 2017
--organized by National Provider Identifier(NPI)=prescriber, drug name=drug,  drug utilization (claim counts and day supply)=prescription, and total drug costs=prescription.
--Primary Data Source = CMS Chronic Conditions Data Warehouse
--records received by claims submission cut-off-date of June 30th following the preceding year; so 2017 claims includes PDFS received through June 30, 2018.
--Contain 100 percent final-action (resolved claim adjustments).
--Beneficiary counts, claim counts, and total drug costs are summarized from these PDEs (prescription drug events)
--PDEs for over-the-counter drugs (status code "O" are excluded from all summarizations, though may be included in PDE records due to step-therapy protocols.
--Drug brand names and generic names from linking National Drug Codes(NDCs) with commercially available drug information database. PDE records with NDCs that do not match to the drug information datbase are excluded from all summarizations.

--DEMOGRAPHICS
--Prescriber Demographics: Name, gender, complete address, entity type from National Plan & Provider Enumeration System (NPPES)
--Health Care Provider Demographics: from time of enrollment and updated periodically
--PUF Demographics: from NPPES at end of subsequent calendar year (2017 PUF includes info as of end of calendar year 2018)

--POPULATION
--About 70 percent of Medicare beneficiaries are enrolled in Part D prescription drug program.
--Approx 2/3rds of that 70 percent of Part D beneficiaries are enrolled in stand-along Prescription Drug Plans (PDP), with remaining 1/3 in Medicare Advantage Prescription Drug (MAPD) plans.
--Part D Prescriber PUF restricted to prescribers who had a valid NPI and included on Medicare Part D PDEs submitted by Part D plan sponsors during calendar year.  Primarily individual providedrs, but also small proporation of organizational providers (nursing homes, group practices, non-physician practitioners, residential treatment facilities, ambulatory surgery centers, and other providers).

--AGGREGATION
--Spending and utilization data in Part D Prescriber PUF aggregated to the following:
--1) NPI of the prescriber, and
--2) the drug name (brand name and generic name)
--Each record in dataset represents a distinct combination of NPI, drug(brand) name, and generic name.  There can be multiple records for a given NPI based on the number of DISTINCT drugs that were filled. 
--For each prescriber and drug, dataset includes total number of prescriptions dispensed (including refills), total 30-day standardized fill counts, total day's supply for these prescriptions, and total drug cost.
--Any aggregated records derived from 10 or few claims excluded to protect privacy of beneficiaries.

------------------------------------
-- 1.a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
--Report the npi and the total number of claims.

SELECT npi
FROM prescription;
--TOTAL 656058 rows

SELECT DISTINCT npi
FROM prescription;
--TOTAL 20592

SELECT DISTINCT npi, total_claim_count
FROM prescription
ORDER BY total_claim_count DESC;
--TOTAL rows 387522 (too many rows?, should it match DISTINCT npi row count?)

SELECT DISTINCT npi, total_claim_count
FROM prescription
ORDER BY npi DESC;
--yes too many rows, there are repeated npis despite DISTINCT)
---------------------------------------------------
--ANSWER
SELECT npi, SUM(total_claim_count) AS total_claim_count_all_drugs
FROM prescription
GROUP BY npi
ORDER BY total_claim_count_all_drugs DESC;
--ANSWER 1881634483 = 99707
--CHECK: 20592 rows, same as DISTINCT npi

--1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM(total_claim_count) AS total_claim_count_all_drugs
FROM prescription
	INNER JOIN prescriber
	USING(npi)
GROUP BY npi, nppes_provider_last_org_name, nppes_provider_first_name, specialty_description
ORDER BY total_claim_count_all_drugs DESC;
--Should this be descending or in alpha order by last name, then first name?

--2.a. Which specialty had the most total number of claims (totaled over all drugs)?

--ANSWER:
SELECT specialty_description,
	SUM(total_claim_count) AS total_claim_count_all_drugs
FROM prescription
	INNER JOIN prescriber
	USING(npi)
GROUP BY specialty_description
ORDER BY total_claim_count_all_drugs DESC;
--ANSWER: Family Practice has the most claims  at 9752347

--NOTE: there are 15 specialities with no claims, see CHECKS below
--Q. should these have been grouped more, ex. 'Psychologist' with 'Psychologist, Clinical'?

--CHECKS
SELECT DISTINCT specialty_description
FROM prescriber;
--107 rows

SELECT specialty_description,
	SUM(total_claim_count) AS total_claim_count_all_drugs
FROM prescription
	FULL JOIN prescriber
	USING(npi)
GROUP BY specialty_description
ORDER BY total_claim_count_all_drugs DESC;
--15 null results for total_claim_count

--b. Which specialty had the most total number of claims for opioids?

TABLES: prescriber, prescription, drug
SUM(total_claim_count and FILTER out claims that do not have a flag for opioids

--USING 2a as a basis, added the opioid drug flag to sum only claims that have opioids
SELECT specialty_description,
	SUM(total_claim_count) AS total_opioid_claims
FROM prescriber
	INNER JOIN prescription
	USING(npi)
	INNER JOIN drug
	USING(drug_name)
WHERE opioid_drug_flag LIKE 'Y'
GROUP BY specialty_description
ORDER BY total_opioid_claims DESC
LIMIT 5;
--ANSWER: Nurse Practitioner had the most opioid claims at 900845

--CHECKS: all claims have the opioid drug flag
SELECT specialty_description,
	SUM(total_claim_count) AS total_opioid_claims,
	opioid_drug_flag
FROM prescriber
	INNER JOIN prescription
	USING(npi)
	INNER JOIN drug
	USING(drug_name)
WHERE opioid_drug_flag LIKE 'Y'
GROUP BY specialty_description, opioid_drug_flag
ORDER BY total_opioid_claims DESC;

--2nd result, sorted by drugs_claimed for opioid flagged only
SELECT specialty_description, COUNT(p1.drug_name) AS total_opioid_drugs_claimed
FROM prescriber
	INNER JOIN prescription as p1
	USING(npi)
	INNER JOIN drug
	USING(drug_name)
WHERE opioid_drug_flag LIKE 'Y'
GROUP BY specialty_description
ORDER BY total_opioid_drugs_claimed DESC
LIMIT 5;
--ANSWER: Nurse Practitioner had the most opioid drugs claimed at 9551
  
--WRONG DIRECTION: counting opiod_drug_flag and long_acting_opioid_drug_flag together (1. these are just flags, not counts of claims, and 2. long_acting is a subset of the larger opioid_drug_flag)
	
--TESTING: one column for each count
SELECT specialty_description,
	COUNT(opioid_drug_flag) AS count_of_opioids,
	COUNT(long_acting_opioid_drug_flag) AS count_of_long_acting_opioids
FROM prescription
	INNER JOIN prescriber
	USING(npi)
	INNER JOIN drug
	USING(drug_name)
WHERE opioid_drug_flag LIKE 'Y'
	AND long_acting_opioid_drug_flag LIKE 'Y'
GROUP BY specialty_description

--WRONG ANSWER: combined count
SELECT specialty_description,
	(SELECT COUNT(opioid_drug_flag) AS count_of_opioids)+
	(SELECT COUNT(long_acting_opioid_drug_flag) AS count_of_long_acting_opioids)
	AS total_count_of_opioids
FROM prescription
	INNER JOIN prescriber
	USING(npi)
	INNER JOIN drug
	USING(drug_name)
WHERE opioid_drug_flag LIKE 'Y'
	AND long_acting_opioid_drug_flag LIKE 'Y'
GROUP BY specialty_description
ORDER BY total_count_of_opioids DESC;

--c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description,
	SUM(total_claim_count) AS no_prescription_claims
FROM prescription
	FULL JOIN prescriber
	USING(npi)
GROUP BY specialty_description
ORDER BY no_prescription_claims DESC;
--ANSWER: Yes, there are 15 null results for total_claim_count
--NOTE: figure out how to write the IS NULL into this
	
--d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

--3.a. Which drug (generic_name) had the highest total drug cost?
	
SELECT t2.generic_name, SUM(total_drug_cost) AS total_generic_drug_cost
FROM prescription
	INNER JOIN drug as t2
	USING(drug_name)
GROUP BY t2.generic_name
ORDER BY total_generic_drug_cost DESC
LIMIT 1;
-- ANSWER: INSULIN GLARGINE,HUM.REC.ANLOG, 104264066.35
	
--3b. Which drug (generic_name) has the hightest total cost per day?
--THIS IS NOT RIGHT, same answer this way
--'total_day_supply' – The aggregate number of day’s supply for which this drug was dispensed

--CHERNAE's CODE -- 
SELECT generic_name, ROUND(SUM(total_drug_cost)/ 1825, 2) AS total_generic_drug_cost_per_day
FROM prescription
	INNER JOIN drug
	USING(drug_name)
GROUP BY generic_name
ORDER BY total_generic_drug_cost_per_day DESC;

--MINE - INCOMPLETE --	
SELECT *
FROM drug;
	
SELECT t2.generic_name, (SUM(total_drug_cost)/365) AS total_cost_per_day
FROM prescription
	LEFT JOIN drug as t2
	USING(drug_name)
GROUP BY t2.generic_name
ORDER BY total_cost_per_day DESC

SELECT t2.generic_name, (SUM(total_drug_cost)/(total_day_supply) AS total_cost_per_day
FROM prescription
	LEFT JOIN drug as t2
	USING(drug_name)
GROUP BY t2.generic_name
ORDER BY total_cost_per_day DESC
	
SELECT drug_name, total_day_supply
FROM prescription;
	
**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

	
--WORKSHEET

--total_drug_cost = The aggregate drug cost paid for all associated claims. This amount includes ingredient cost, dispensing fee, sales tax, and any applicable vaccine administration fees and is based on the amounts paid by the Part D plan, Medicare beneficiary, government subsidies, and any other third-party payers.
	
	drug TABLE, generic_name; prescription TABLE, total_drug_cost, ORDER BY total_drug_cost DESC
	drug_name KEY, group by drug_name
	
SELECT DISTINCT generic_name
FROM drug
ORDER BY generic_name;
--1787 rows
	
SELECT *
FROM prescription;
--606058 rows	

SELECT DISTINCT drug_name
FROM prescription
--1821 rows
	
SELECT total_drug_cost
FROM prescription
--606058 rows

SELECT npi, total_drug_cost
FROM prescription
--655905 rows

SELECT drug_name, total_drug_cost
FROM prescription
--656058 rows
						 
SELECT t2.generic_name, SUM(total_drug_cost) AS total_generic_drug_cost
FROM prescription
	INNER JOIN drug as t2
	USING(drug_name)
GROUP BY t2.generic_name
ORDER BY SUM(total_drug_cost) DESC
LIMIT 1;
--1199 rows
-- ANSWER: INSULIN GLARGINE,HUM.REC.ANLOG, 104264066.35
---------------------------------------------
	
--4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
						 
SELECT DISTINCT drug_name,
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug;
	
3425 rows without DISTINCT
3260 with DISTINCT

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.		 
						 
SELECT SUM(CASE WHEN opioid_drug_flag = 'Y' THEN CAST(total_drug_cost as money) END) AS total_opioid_drug_cost,
	SUM(CASE WHEN antibiotic_drug_flag = 'Y' THEN CAST(total_drug_cost as money) END) AS total_antibiotic_drug_cost
FROM drug
	INNER JOIN prescription 
	USING(drug_name)
						 
--ANSWER: more was spent on opioids, at $105,080,626.37 relative to the $38,435,121.26 spent on antibiotics.
--Q should drug name be a part of this table?  Should there be a calculation to result the MAX of either results, and how to do that?
			 
-- 5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
cbsa=core-based statistical area (geographic area defined by Office of Management and Budget (OMB) that consists of one or more counties anchored by an urban center)
Connect CBSA table to fips_county on fipscounty to access fipsstate
Using a from statement subquery?
						 
SELECT COUNT(DISTINCT cbsa.cbsa)
FROM cbsa
--RESULT: 409

SELECT state
FROM fips_county

--CLARIFY IS THIS ASKING FOR NAME OF CBSAs (10 or the total count of CBSAs (42)
--CBSA field is ID for area

SELECT COUNT(DISTINCT cbsa.cbsa),
		cbsa.cbsaname,
		fips_county.state
FROM cbsa, fips_county
WHERE cbsa.fipscounty = fips_county.fipscounty
	AND fips_county.state = 'TN'
GROUP BY cbsa.cbsaname, fips_county.state
--ANSWER - 42
--* check this answer with the FROM (SELECT ) 
--ANSWER
SELECT COUNT(DISTINCT cbsa.cbsa) AS CBSA_count_TN
FROM cbsa, fips_county
WHERE cbsa.fipscounty = fips_county.fipscounty
	AND fips_county.state = 'TN'
--ANSWER: 10
						 
-- 5. b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
						 
SELECT DISTINCT cbsaname, SUM(population) AS total_pop
FROM cbsa
INNER JOIN population 
	USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_pop DESC;

--ANSWER Nashville-Davidson-Murfreesboro has the largest total pop of 1830410,
--ANSWER Morristown, TN has the smallest at 116352
				 
-- 5.c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
						 
--ANSWER (CHERNAE'S) 
SELECT population, county 
FROM population 
LEFT JOIN fips_county
USING(fipscounty)
LEFT JOIN cbsa
USING(fipscounty)
WHERE cbsaname IS NULL
ORDER BY population DESC
LIMIT 1; 
--ANSWER: Sevier at 95523					 

--WORKING
SELECT county, population
FROM 
LEFT JOIN fips_county
USING(fipscounty)
LEFT JOIN cbsa
USING(fipscounty)
WHERE cbsa IS NULL
GROUP BY county, population
ORDER BY population DESC
						
EXCEPT or ANTI JOIN?
						 
-- 6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000
					 
--b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT total_claim_count,
		CASE WHEN opioid_drug_flag = 'Y' THEN 'Y' ELSE 'N' END AS opioid
FROM prescription
	INNER JOIN drug 
	USING(drug_name)
WHERE total_claim_count >= 3000

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT nppes_provider_first_name AS first_name,
		nppes_provider_last_org_name AS last_namedrug_name, 
		total_claim_count,
		CASE WHEN opioid_drug_flag = 'Y' THEN 'Y' ELSE 'N' END AS opioid
FROM prescription
	INNER JOIN drug 
	USING(drug_name)
	INNER JOIN prescriber
	USING(npi)
WHERE total_claim_count >= 3000

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.
						 
--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opioid_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
	AND specialty_description = 'Pain Management'
						 
b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

WITH nash_pms_opioid AS (SELECT npi, drug_name 
									FROM prescriber
										CROSS JOIN drug
										WHERE nppes_provider_city = 'NASHVILLE'
											AND opioid_drug_flag = 'Y'
											AND specialty_description = 'Pain Management')
SELECT COALESCE(nash_pms_opioid.npi, '0'), COALESCE(nash_pms_opioid.drug_name, '0'), SUM(total_claim_count) AS total_claim_count
FROM prescription AS p1
	LEFT JOIN nash_pms_opioid
	USING(npi)
GROUP BY nash_pms_opioid.npi, nash_pms_opioid.drug_name
ORDER BY total_claim_count DESC
						 
--*This isn't right, total claim count is the same for every drug for every subscriber						 

--BH's CODE
SELECT npi,drug.drug_name, SUM(total_claim_count) AS total_claim_count
FROM prescriber
CROSS JOIN drug
INNER JOIN prescription
USING(npi)
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city ILIKE 'Nashville'
AND opioid_drug_flag = 'Y'
GROUP BY npi, drug.drug_name
ORDER BY total_claim_count DESC;						 
						 
						 
						 
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

--BONUS--
						 
-- 	. How many npi numbers appear in the prescriber table but not in the prescription table?

-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
    
--     b. Now, report the same for Memphis.
    
--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

-- 5.
--     a. Write a query that finds the total population of Tennessee.
    
--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
						 
SAMPLE SUBQUERY
SELECT gameName 
FROM  game
WHERE gamefee = (SELECT MAX(gameFee) FROM game)