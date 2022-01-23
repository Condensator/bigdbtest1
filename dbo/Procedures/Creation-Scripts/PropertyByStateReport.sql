SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[PropertyByStateReport]
(
@LegalEntityNumber NVARCHAR(MAX),
@SequenceNumber NVARCHAR(MAX),
@CustomerName NVARCHAR(MAX),
@FromDate DATE,
@ToDate DATE,
@LeaseCommencedBookingStatus NVARCHAR(MAX),
@CapitalLeaseRental NVARCHAR(MAX),
@OperatingLeaseRental NVARCHAR(MAX),
@LeaseFloatRateAdj NVARCHAR(MAX),
@OverTermRental NVARCHAR(MAX),
@LeaseType NVARCHAR(MAX),
@FullyPaidOffStatus NVARCHAR(MAX),
@AllStates BIT,
@StateShortName NVARCHAR(MAX),
@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
--DECLARE @LegalEntityNumber NVARCHAR(MAX)
--DECLARE @SequenceNumber NVARCHAR(MAX)
--DECLARE @CustomerName NVARCHAR(MAX)
--DECLARE	@FromDate DATE
--DECLARE	@ToDate DATE
--DECLARE	@LeaseCommencedBookingStatus NVARCHAR(MAX)
--DECLARE	@CapitalLeaseRental NVARCHAR(MAX)
--DECLARE	@OperatingLeaseRental NVARCHAR(MAX)
--DECLARE	@LeaseFloatRateAdj NVARCHAR(MAX)
--DECLARE	@OverTermRental NVARCHAR(MAX)
--DECLARE @LeaseType NVARCHAR(MAX)
--DECLARE @FullyPaidOffStatus NVARCHAR(MAX)
--DECLARE @AllStates BIT
--DECLARE @StateShortName NVARCHAR(MAX)
--SET @LegalEntityNumber = NULL
--SET @SequenceNumber = NULL
--SET @CustomerName = NULL
--SET @FromDate = '1/1/16'
--SET @ToDate = '12/31/16'
--SET @LeaseCommencedBookingStatus = 'Commenced'
--SET @CapitalLeaseRental = 'CapitalLeaseRental'
--SET @OperatingLeaseRental = 'OperatingLeaseRental'
--SET @LeaseFloatRateAdj = 'LeaseFloatRateAdj'
--SET @OverTermRental = 'OverTermRental'
--SET @LeaseType = 'Both'
--SET @FullyPaidOffStatus = 'FullyPaidOff'
--SET @AllStates = 0
--SET @StateShortName = 'FL'
;WITH CTE_Leases As
(
SELECT C.SequenceNumber,
P.PartyNumber 'CustomerNumber',
P.PartyName 'CustomerName',
LFD.LeaseContractType,
LFD.IsTaxLease,
LF.Id 'LeaseFinanceId',
C.Id 'ContractId',
CI.ISO 'Currency'
FROM Contracts C
JOIN LeaseFinances LF ON C.Id = LF.ContractId
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
JOIN Customers CUS ON LF.CustomerId = CUS.Id
JOIN Parties P ON CUS.Id = P.Id
JOIN Currencies CC ON C.CurrencyId = CC.Id
JOIN CurrencyCodes CI ON CC.CurrencyCodeId = CI.Id
WHERE (LF.BookingStatus = @LeaseCommencedBookingStatus OR LF.BookingStatus = @FullyPaidOffStatus)
AND LF.IsCurrent = 1
AND (@LegalEntityNumber IS NULL OR LE.LegalEntityNumber in (select value from String_split(@LegalEntityNumber,',')))
AND (@CustomerName IS NULL OR P.PartyName = @CustomerName)
AND (@SequenceNumber IS NULL OR C.SequenceNumber = @SequenceNumber)
AND (@LeaseType = 'Both' OR LFD.IsTaxLease = (CASE WHEN @LeaseType = 'Tax' THEN 1 WHEN @LeaseType = 'NonTax' THEN 0 END))
),
CTE_Assets As
(
SELECT CTE.ContractId,
ISNULL(EntityResourcesForCountry.Value,CO.LongName) 'Country',
ISNULL(EntityResourcesForState.Value,S.LongName) 'State',
L.Division 'County',
L.City,
SUM(RD.Amount_Amount) 'RentalRevenueAmount'
FROM CTE_Leases CTE
JOIN LeaseAssets LA ON CTE.LeaseFinanceId = LA.LeaseFinanceId AND LA.IsActive = 1
JOIN ReceivableDetails RD ON LA.AssetId = RD.AssetId AND RD.IsActive = 1
JOIN Receivables R ON RD.ReceivableId = R.Id
JOIN AssetLocations AL ON RD.AssetId = AL.AssetId AND AL.IsCurrent = 1
JOIN Locations L ON AL.LocationId = L.Id
JOIN States S ON L.StateId = S.Id
LEFT JOIN EntityResources EntityResourcesForState on EntityResourcesForState.EntityId=S.Id
AND EntityResourcesForState.EntityType='State'
AND EntityResourcesForState.Name='LongName'
AND EntityResourcesForState.Culture=@Culture
JOIN Countries CO ON S.CountryId = CO.Id
LEFT JOIN EntityResources EntityResourcesForCountry on EntityResourcesForCountry.EntityId=CO.Id
AND EntityResourcesForCountry.EntityType='Country'
AND EntityResourcesForCountry.Name='LongName'
AND EntityResourcesForCountry.Culture=@Culture
WHERE R.DueDate >= @FromDate AND R.DueDate <= @ToDate AND (@AllStates = 1 OR S.ShortName = @StateShortName)
GROUP BY CTE.ContractId,EffectiveFromDate,ISNULL(EntityResourcesForCountry.Value,CO.LongName),ISNULL(EntityResourcesForState.Value,S.LongName),L.Division,L.City
)
SELECT CTEL.SequenceNumber,
CTEL.CustomerName,
CTEL.CustomerNumber,
CTEL.LeaseContractType,
CTEL.IsTaxLease,
CTEA.Country,
CTEA.State,
CTEA.County,
CTEA.City,
CTEL.Currency,
CTEA.RentalRevenueAmount
FROM CTE_Leases CTEL
JOIN CTE_Assets CTEA ON CTEL.ContractId = CTEA.ContractId
SET NOCOUNT OFF;
END

GO
