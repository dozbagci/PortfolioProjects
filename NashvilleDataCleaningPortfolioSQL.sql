/*

Cleaning Data in SQL Queries

*/
Select *
From PortfolioProject.dbo.Nashville

------------------------------------------------
-- Standardize Date Format
Select SaleDate, CONVERT(Date,SaleDate)
From PortfolioProject.dbo.Nashville

Update PortfolioProject.dbo.Nashville
SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE PortfolioProject.dbo.Nashville
Add SaleDateConverted Date;

Update Nashville
SET SaleDateConverted = CONVERT(Date,SaleDate)


----------------------------------------------------
-- Populate Property Address Data

Select *
From PortfolioProject.dbo.Nashville
--Where PropertyAddress is null
order by ParcelID

Select a.ParcelID, a.PropertyAddress,b.ParcelID,b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject.dbo.Nashville a
JOIN PortfolioProject.dbo.Nashville b
 on a.ParcelID = b.ParcelID
 AND a.[UniqueID] <> b.[UniqueID] 
 Where a.PropertyAddress is null

 Update a 
 SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
 From PortfolioProject.dbo.Nashville a
JOIN PortfolioProject.dbo.Nashville b
 on a.ParcelID = b.ParcelID
 AND a.[UniqueID] <> b.[UniqueID] 


------------------------------------------------------------------------
 --Breaking out Address into Individual Columns (Address, City, State)

 Select PropertyAddress
From PortfolioProject.dbo.Nashville
--Where PropertyAddress is null
--order by ParcelID

Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) as City
From PortfolioProject.dbo.Nashville

ALTER TABLE PortfolioProject.dbo.Nashville
Add PropertySplitAddress Nvarchar(255);

Update PortfolioProject.dbo.Nashville
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) 

ALTER TABLE PortfolioProject.dbo.Nashville
Add PropertySplitCity Nvarchar(255);

Update PortfolioProject.dbo.Nashville
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))


-----------------------------------------------------------------------------------
--Easier method than substring, again separates address,city,state for Owner Address
Select OwnerAddress
From PortfolioProject.dbo.Nashville

Select
PARSENAME(REPLACE(OwnerAddress,',','.'),1),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),3)
From PortfolioProject.dbo.Nashville

ALTER TABLE PortfolioProject.dbo.Nashville
Add OwnerSplitAddress Nvarchar(255);

Update PortfolioProject.dbo.Nashville
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE PortfolioProject.dbo.Nashville
Add OwnerSplitCity Nvarchar(255);

Update PortfolioProject.dbo.Nashville
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE PortfolioProject.dbo.Nashville
Add OwnerSplitState Nvarchar(255);

Update PortfolioProject.dbo.Nashville
SET OwnerSplitState= PARSENAME(REPLACE(OwnerAddress,',','.'),1)



-------------------------------------------------------------
--Change Y and N to Yes and No in Sold as Vacant field

Select Distinct(SoldasVacant), Count(SoldasVacant)
From PortfolioProject.dbo.Nashville
Group by SoldAsVacant
Order by 2

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
        When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
From PortfolioProject.dbo.Nashville

Update PortfolioProject.dbo.Nashville
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
        When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END


------------------------------------------------------
-- Remove Duplicates

WITH RowNumCTE AS(
Select *, 
 ROW_NUMBER() over(
 PARTITION BY ParcelID,
			  PropertyAddress,
			  SalePrice,
			  SaleDate,
			  LegalReference
			  ORDER BY
			     UniqueID
				 ) row_num

From PortfolioProject.dbo.Nashville
)

DELETE 
From RowNumCTE
Where row_num > 1


--------------------------------------------------------
-- Delete Unused Columns

Select *
From PortfolioProject.dbo.Nashville

ALTER TABLE PortfolioProject.dbo.Nashville
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject.dbo.Nashville
DROP COLUMN SaleDate