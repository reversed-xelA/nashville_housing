-- Display data head
SELECT TOP (100) *
  FROM nashville_housing


-- Standardise date format
SELECT
	SaleDate, 
	CONVERT(Date,SaleDate)
FROM nashville_housing

UPDATE nashville_housing
SET SaleDate = CONVERT(Date,SaleDate)


-- Checking to see if the data type has been modified

SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE 
    TABLE_NAME = 'nashville_housing' AND 
    COLUMN_NAME = 'SaleDate';

-- Populate Property Address
-- Conducting a self join on the table to correlate ParcelIDs with property adrress data to matching ParcelIDs without (each ParcelID is a unique address)
SELECT *
FROM nashville_housing
WHERE PropertyAddress is null

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashville_housing a
JOIN nashville_housing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is null

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashville_housing a
JOIN nashville_housing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is null


-- Breaking out PropertyAddress into individual columns (Street, City, State)

SELECT PropertyAddress
FROM nashville_housing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Street
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM nashville_housing

ALTER TABLE nashville_housing
ADD Street Nvarchar(255);

Update nashville_housing
SET Street = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE nashville_housing
ADD City Nvarchar(255);

Update nashville_housing
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

EXEC sp_rename 'nashville_housing.Street', 'PropertyStreet', 'COLUMN';
EXEC sp_rename 'nashville_housing.City', 'PropertyCity', 'COLUMN';

-- Doing the same for OwnerAddress

SELECT
PARSENAME(REPLACE(OwnerAddress, ',','.') ,3)
,PARSENAME(REPLACE(OwnerAddress, ',','.') ,2)
,PARSENAME(REPLACE(OwnerAddress, ',','.') ,1)
FROM nashville_housing

ALTER TABLE nashville_housing
ADD OwnerStreet Nvarchar(255);

ALTER TABLE nashville_housing
ADD OwnerCity Nvarchar(255);

ALTER TABLE nashville_housing
ADD OwnerState Nvarchar(255);

Update nashville_housing
SET OwnerStreet = PARSENAME(REPLACE(OwnerAddress, ',','.') ,3)

Update nashville_housing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',','.') ,2)

Update nashville_housing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',','.') ,1)


-- Checking values in SoldAsVacant column

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM nashville_housing
GROUP BY SoldAsVacant


-- Remove duplicates
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM nashville_housing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1


-- Delete unused columns

ALTER TABLE nashville_housing
DROP COLUMN OwnerAddress,
			TaxDistrict,
			PropertyAddress