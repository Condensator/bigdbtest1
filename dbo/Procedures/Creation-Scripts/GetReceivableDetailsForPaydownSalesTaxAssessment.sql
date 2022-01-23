SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetReceivableDetailsForPaydownSalesTaxAssessment]
(
@ReceivableIds NVARCHAR(MAX)
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex = 'Vertex';

DECLARE @Receivables TABLE
(
Id BIGINT
)
INSERT INTO @Receivables (Id) SELECT Id FROM ConvertCSVToBigIntTable(@ReceivableIds, ',');
SELECT
R.Id ReceivableId,
MAX(GLT.Id) GLTemplateId
INTO #SalesTaxGLTemplateDetail
FROM @Receivables RDs
INNER JOIN Receivables R ON R.Id = RDs.Id
INNER JOIN LegalEntities LE ON LE.Id = R.LegalEntityId AND LE.Status = 'Active'
INNER JOIN GLConfigurations GLC ON GLC.Id = LE.GLConfigurationId
INNER JOIN GLTemplates GLT ON GLC.Id = GLT.GLConfigurationId AND GLT.IsActive = 1
INNER JOIN GLTransactionTypes GTT ON GLT.GLTransactionTypeId = GTT.Id AND GTT.IsActive = 1 AND GTT.Name = 'SalesTax'
GROUP BY
R.Id
;
WITH CTE_ReceivableLocations AS
(
SELECT
R.LocationId AS LocationId
,R.DueDate
,R.Id
,states.ShortName AS MainDivision
,countries.ShortName AS Country
,Loc.City AS City
,Loc.ApprovalStatus AS LocationStatus
,Loc.IsActive AS IsLocationActive
,CAST(CASE WHEN countries.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) AS IsVertexSupported
,Loc.UpfrontTaxMode
FROM
@Receivables Rec
INNER JOIN Receivables R ON Rec.Id = R.Id
INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId  AND RD.IsActive = 1 AND RD.IsTaxAssessed = 0
LEFT JOIN Locations Loc ON R.LocationId = Loc.Id
LEFT JOIN States states ON Loc.StateId = states.Id
LEFT JOIN Countries countries ON states.CountryId = countries.Id
),
CTE_AllTaxAreaIdsForLocation AS
(
SELECT
ROW_NUMBER() OVER (PARTITION BY P.LocationId,Loc.Id ORDER BY CASE WHEN DATEDIFF(DAY,Loc.DueDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, Loc.DueDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC,
CASE WHEN DATEDIFF(DAY, Loc.DueDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END  ASC) Row_Num
,P.TaxAreaEffectiveDate
,P.TaxAreaId
,P.LocationId
,Loc.MainDivision
,Loc.City
,Loc.Country
,Loc.LocationStatus
,Loc.IsLocationActive
,Loc.Id
,Loc.IsVertexSupported
,Loc.UpfrontTaxMode
FROM	CTE_ReceivableLocations Loc
LEFT JOIN LocationTaxAreaHistories P ON P.LocationId = Loc.LocationId
)
,CTE_TaxAreaIdForLocationAsOfDueDate AS
(
SELECT *
FROM CTE_AllTaxAreaIdsForLocation
WHERE Row_Num = 1
)
,CTE_FromTaxAreaIdForLocationAsOfDueDate AS
(
SELECT *
FROM CTE_AllTaxAreaIdsForLocation
WHERE Row_Num = 2
)
SELECT
RD.Id AS ReceivableDetailId
,RD.ReceivableId AS ReceivableId
,R.DueDate AS DueDate
,RT.IsRental AS IsRental
,RT.Name AS Product
,0.00 AS FairMarketValue
,0.00 AS Cost
,0.00 AS AmountBilledToDate
,RD.Amount_Amount AS ExtendedPrice
,RD.Amount_Currency AS Currency
,CONVERT(BIT,0) AS IsAssetBased
,CONVERT(BIT,0) AS IsLeaseBased
,CONVERT(BIT,0) AS IsExemptAtAsset
,'LEASE' AS TransactionType
,LE.TaxPayer AS Company
,LoanParty.PartyNumber AS CustomerCode
,LoanParty.Id  AS CustomerId
,CC.Class AS ClassCode
,Loc.LocationId AS LocationId
,Loc.MainDivision  AS MainDivision
,Loc.Country AS Country
,Loc.City AS City
,Loc.TaxAreaId AS TaxAreaId
,Loc.TaxAreaEffectiveDate AS TaxAreaEffectiveDate
,Loc.IsLocationActive AS IsLocationActive
,R.EntityId AS ContractId
,NULL AS RentAccrualStartDate
,NULL AS MaturityDate
,0.0 AS CustomerCost
,CONVERT(BIT,0) AS IsExemptAtLease
,0.00 AS LessorRisk
,NULL AS AssetLocationId
,Loc.LocationStatus AS LocationStatus
,CONVERT(BIT,0)  AS IsExemptAtSundry
,RecT.Id AS ReceivableTaxId
,Loc.IsVertexSupported AS IsVertexSupportedLocation
,CAST(0 AS BIT) AS IsMultiComponent
,NULL AS ContractType
,cont.SequenceNumber AS LeaseUniqueId
,RC.Name AS SundryReceivableCode
,NULL AS AssetType
,DPT.LeaseType AS LeaseType
,0.00 AS LeaseTerm
,NULL AS TitleTransferCode
,NULL AS LocationEffectiveDate
,RT.Name AS ReceivableType
,LE.Id 'LegalEntityId'
,STGL.GLTemplateId GlTemplateId
--User Defined Flex Fields
,NULL AS SaleLeasebackCode
,CAST(0 AS BIT) AS IsElectronicallyDelivered
,REPLACE(cont.SalesTaxRemittanceMethod, 'Based','') TaxRemittanceType
,ToState.ShortName ToState
,FromState.ShortName FromState
,0 GrossVehicleWeight
,0.00 LienCredit_Amount
,'USD' LienCredit_Currency
,0.00 ReciprocityAmount_Amount
,'USD' ReciprocityAmount_Currency
,RD.AssetId AS AssetId
,CAST(NULL AS NVARCHAR) AS EngineType
,CAST(0.00 AS DECIMAL(16,2)) AS HorsePower
,ISNULL(Loc.UpfrontTaxMode,'_') UpfrontTaxMode
FROM
@Receivables Rs
JOIN Receivables R ON Rs.Id = R.Id
JOIN ReceivableDetails RD ON R.Id=RD.ReceivableId
INNER JOIN Contracts cont ON R.EntityId = cont.Id
INNER JOIN LegalEntities LE ON R.LegalEntityId = LE.Id
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
LEFT JOIN Sundries S ON R.Id = S.ReceivableId AND S.IsActive = 1 AND S.Type = 'Sundry'
LEFT JOIN DealProductTypes DPT ON cont.DealProductTypeId = DPT.Id AND DPT.IsActive=1
LEFT JOIN LoanFinances Loan ON cont.Id =  Loan.ContractId AND Loan.IsCurrent = 1
LEFT JOIN Customers LoanCust ON Loan.CustomerId = LoanCust.Id
LEFT JOIN CustomerClasses CC ON LoanCust.CustomerClassId = cc.Id
LEFT JOIN Parties LoanParty ON LoanParty.Id = LoanCust.Id
LEFT JOIN CTE_TaxAreaIdForLocationAsOfDueDate Loc ON RD.ReceivableId = Loc.Id
LEFT JOIN Locations ToLocation ON Loc.LocationId = ToLocation.Id
LEFT JOIN States ToState ON ToLocation.StateId = ToState.Id
LEFT JOIN CTE_FromTaxAreaIdForLocationAsOfDueDate FromLoc ON RD.Id = FromLoc.Id
LEFT JOIN Locations FromLocation ON FromLoc.LocationId = FromLocation.Id
LEFT JOIN States FromState ON FromLocation.StateId = FromState.Id
LEFT JOIN ReceivableTaxes RecT ON RD.ReceivableId = RecT.ReceivableId AND RecT.IsActive = 1
LEFT JOIN #SalesTaxGLTemplateDetail STGL ON R.Id = STGL.ReceivableId
WHERE RT.IsRental = 0
END

GO
