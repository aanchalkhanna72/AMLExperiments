----------------SQL Data Cleaning Project ------------------------------
------------------------------------------------------------------------

-------Cleaning Data
SELECT *
FROM Projects.dbo.Nashville;
-----------------------------

-------STEP 1: Standardizing the Date Format


ALTER TABLE Projects.dbo.Nashville 
ADD SaleDateConverted Date;

UPDATE Projects.dbo.Nashville
SET SaleDateConverted=CONVERT(date,SaleDate);

SELECT SaleDateConverted
FROM Projects.dbo.Nashville;

--------STEP 2: Populate Property Address Data Where Missing

SELECT *
FROM Projects.dbo.Nashville
--WHERE PropertyAddress is null;
ORDER BY ParcelID;

---Self Join in order to compare parcelIDs and fill data where they are equal
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Projects.dbo.Nashville a
JOIN Projects.dbo.Nashville b
	on a.ParcelID=b.ParcelID
	AND a.UniqueID<>b.UniqueID
WHERE a.PropertyAddress is null;

---- replacing null values with Property Address where Parcel ID is the same

UPDATE a
SET PropertyAddress=ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Projects.dbo.Nashville a
JOIN Projects.dbo.Nashville b
	on a.ParcelID=b.ParcelID
	AND a.UniqueID<>b.UniqueID
WHERE a.PropertyAddress is null;

---- STEP 3: Breaking Down Property Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM Projects.dbo.Nashville

--- extracting individual address 
SELECT SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1) as Address 
---- -1 because we want to remove the comma and charindex gives us the index of the ',' we look for and substring gives us the 
---- part of the string that we want 
FROM Projects.dbo.Nashville

--- extracting individual address and city name 
SELECT SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1) as Address 
, SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) as Address 
FROM Projects.dbo.Nashville;

---- need to create two columns to store this separated data 

---- address data
ALTER TABLE Projects.dbo.Nashville
ADD PropertySplitAddress varchar(250);

UPDATE Projects.dbo.Nashville
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1)


--- city data 
ALTER TABLE Projects.dbo.Nashville
ADD PropertySplitCity varchar(250)

UPDATE Projects.dbo.Nashville
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress));

---- checking 
SELECT *
FROM Projects.dbo.Nashville;

------------STEP 4: Splitting Owner Address into individual address, city, state

SELECT OwnerAddress
FROM Projects.dbo.Nashville
GROUP BY OwnerAddress;
--- individual adddress
SELECT OwnerAddress,
SUBSTRING (OwnerAddress,1,CHARINDEX(',', OwnerAddress)-1)
FROM Projects.dbo.Nashville;
----- city AND state together
SELECT OwnerAddress,
SUBSTRING (OwnerAddress,CHARINDEX(',', OwnerAddress)+1,LEN(OwnerAddress))
FROM Projects.dbo.Nashville;

---- but, we want city and state separately so we will try the PARSE function 
---- however replace ',' with '.' because parsename function looks for '.'

SELECT PARSENAME(REPLACE(OwnerAddress,',','.'),1), --- locate last  element after the last fullstop ie state name
PARSENAME(REPLACE(OwnerAddress,',','.'),2), --- locate middle/second last  element after the last fullstop ie city name
PARSENAME(REPLACE(OwnerAddress,',','.'),3)  --- locate first  element after the last fullstop ie personal address name
FROM Projects.dbo.Nashville;

--- creating columns to separate data
ALTER TABLE Projects.dbo.Nashville
ADD OwnerSplitAddress varchar(250);

UPDATE Projects.dbo.Nashville
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3);
 
 ALTER TABLE Projects.dbo.Nashville
 ADD OwnerSplitCity varchar(250);

UPDATE Projects.dbo.Nashville
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2);

ALTER TABLE Projects.dbo.Nashville
ADD OwnerSplitState varchar(250);

UPDATE Projects.dbo.Nashville
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1);

SELECT *
FROM Projects.dbo.Nashville;

-------------STEP 5: Change Y and N to Yes and No in "Sold as Vacant" field to make data uniform

SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM Projects.dbo.Nashville
GROUP BY SoldAsVacant
ORDER BY 2;  -- Orders by the col number  stated in select query

SELECT SoldAsVacant,
CASE 
WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN  'No'
ELSE SoldAsVacant 
END
FROM Projects.dbo.Nashville;

UPDATE Projects.dbo.Nashville ---- Updating all entries of SoldAsVacant in 'Y','N' format
SET SoldAsVacant =
CASE 
WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN  'No'
ELSE SoldAsVacant 
END;

SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM Projects.dbo.Nashville
GROUP BY SoldAsVacant
ORDER BY 2;  -- Orders by the col number  stated in select query

--------------- STEP 6: Removing Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference
	ORDER BY 
		UniqueID) row_num
FROM Projects.dbo.Nashville)
DELETE
FROM RowNumCTE
WHERE row_num>1;

--- should yield no rows since all duplicates have been removed
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference
	ORDER BY 
		UniqueID) row_num
FROM Projects.dbo.Nashville)
SELECT *
FROM RowNumCTE
WHERE row_num>1
ORDER BY PropertyAddress;

-------------- STEP 7: Drop Unused/Repetitive Columns

ALTER TABLE Projects.dbo.Nashville
DROP COLUMN OwnerAddress,TaxDistrict,PropertyAddress,SaleDate;

-----------------------------------
SELECT *  
FROM Projects.dbo.Nashville;

SELECT *
FROM Projects.dbo.Nashville
WHERE OwnerSplitCity IS NULL;


SELECT DISTINCT(PropertySplitCity)
FROM Projects.dbo.Nashville;

--order by OwnerSplitCity
--WHERE UPPER(PropertySplitCity)="Goodlettsville";

SELECT UPPER('goodlettsville')
from Nashville;

SELECT OwnerName , PropertySplitCity from Nashville where PropertySplitCity = 'GOODLETTSVILLE';
