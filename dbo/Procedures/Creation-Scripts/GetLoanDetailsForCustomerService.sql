SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetLoanDetailsForCustomerService]
(
@CustomerNumber nvarchar(50),
@UserID BIGINT,
@Yes NVARCHAR(10),
@No NVARCHAR(10)
)
AS
SET NOCOUNT ON
BEGIN
CREATE TABLE #PrimaryAndSecondaryCollectorForContract (ContractId BIGINT,PrimaryCollector NVARCHAR(MAX));
DECLARE @CustomerId BIGINT = (Select Id From Parties  where PartyNumber =  @CustomerNumber)
SELECT DISTINCT CAH.ContractId
INTO #AssumptionDetails
FROM ContractAssumptionHistories CAH
INNER JOIN Assumptions A ON A.Id = CAH.AssumptionId
AND CAH.CustomerId = @CustomerId;
SELECT DISTINCT C.ContractId AS Id INTO #ValidContractIds
FROM
((((SELECT LoanContract.Id ContractId
From LoanFinances
INNER JOIN Contracts LoanContract
ON LoanFinances.ContractId = LoanContract.Id
AND LoanFinances.IsCurrent=1
AND LoanFinances.CustomerId = @CustomerId
AND (LoanContract.IsConfidential = 0 OR
LoanContract.ID IN (SELECT C.[Id]
FROM  [dbo].[Contracts] AS C
INNER JOIN [dbo].[EmployeesAssignedToContracts] AS EAC ON C.[Id] = EAC.[ContractId]
INNER JOIN [dbo].[EmployeesAssignedToParties] AS EACu ON EAC.[EmployeeAssignedToPartyId] = EACu.[Id]
WHERE EACu.[EmployeeId] = @UserId AND C.[IsConfidential] = 1  AND EACU.PartyId = @CustomerId ))
)))
UNION
(
SELECT ContractId
FROM #AssumptionDetails
)) C
CREATE TABLE #LoanDetails ( SequenceNumber NVARCHAR(MAX) ,
Alias NVARCHAR(MAX) ,
LegalEntityName NVARCHAR(MAX) ,
LineOfBusiness NVARCHAR(MAX) ,
Status NVARCHAR(MAX) ,
ProductType NVARCHAR(MAX) ,
CollateralValue decimal,
Term decimal(10,6),
RemainingTerm decimal(10,6),
CommencementDate DATE,
MaturityDate DATE,
Frequency NVARCHAR(MAX),
CollectionStatus NVARCHAR(MAX),
IsAccrual NVARCHAR(MAX),
LoanFinanceID bigint,
Id bigint,
CustomerId bigint,
Currency nvarchar(80),
SyndicationType nvarchar(max),
IsAdvance BIT,
OverallDPD INT  ,
IsNonNotification BIT
)
INSERT INTO
#LoanDetails
(SequenceNumber ,
Alias ,
LegalEntityName  ,
LineOfBusiness  ,
Status ,
ProductType  ,
Term ,
RemainingTerm ,
CommencementDate ,
MaturityDate ,
Frequency,
CollectionStatus ,
IsAccrual,
LoanFinanceID,
Id ,
CustomerId,
Currency,
SyndicationType,
IsAdvance,
OverallDPD,
IsNonNotification)
SELECT
C.SequenceNumber as SequenceNumber ,
C.Alias as Alias ,
LE.Name as LegalEntityName  ,
LOB.Name as LineOfBusiness  ,
LoanF.Status as Status ,
DPT.Name as ProductType  ,
LoanF.Term as Term ,
Cast(0.00 as decimal(10,6)) as RemainingTerm ,
LoanF.CommencementDate as CommencementDate ,
LoanF.MaturityDate as MaturityDate ,
LoanF.PaymentFrequency as Frequency,
CS.Name as CollectionStatus ,
CASE WHEN  C.IsNonAccrual = 0 THEN @Yes ELSE @No END as IsAccrual ,
LoanF.Id as LoanFinanceID ,
C.Id as Id ,
P.Id ,
CurrCod.ISO as Currency,
C.SyndicationType,
LoanF.IsAdvance,
ISNULL(ccd.OverallDPD,0) ,
ISNULL(ServicingDetails.IsNonNotification,0) as IsNonNotification
FROM
LoanFinances LoanF
INNER JOIN Contracts C
on LoanF.ContractId = C.Id
AND LoanF.IsCurrent=1
AND (C.ContractType='Loan' OR C.ContractType='ProgressLoan' )
left join ContractCollectionDetails ccd on ccd.ContractId = C.Id
INNER JOIN Parties P
on LoanF.CustomerId = P.Id
INNER JOIN Customers Cus
on P.Id = Cus.Id
INNER JOIN Currencies Curr
on C.CurrencyId = Curr.Id
INNER JOIN CurrencyCodes CurrCod
on Curr.CurrencyCodeId = CurrCod.Id
INNER JOIN LegalEntities LE
on LoanF.LegalEntityId = LE.Id
INNER JOIN LineofBusinesses LOB
on C.LineofBusinessId = LOB.Id
LEFT JOIN CollectionStatus CS
on CS.Id = Cus.CollectionStatusId
LEFT JOIN DealProductTypes DPT
on C.DealProductTypeId = DPT.Id
left join (
select MIN(serdtl.Id) ServicingDetailId , LF.Id LFId
from  LoanFinances LF
join ContractOriginations cntorg   on LF.ContractOriginationId = cntorg.Id
left join ContractOriginationServicingDetails cntorgser
on cntorg.id=cntorgser.ContractOriginationId
left join ServicingDetails serdtl
on cntorgser.ServicingDetailId=serdtl.id and serdtl.IsActive=1
GROUP BY LF.Id
)T
on LoanF.Id = T.LFId
LEFT JOIN ServicingDetails on T.ServicingDetailId = ServicingDetails.Id
WHERE C.ID IN (SELECT ID FROM #ValidContractIds)

SELECT
SUM(CA.AcquisitionCost_Amount) as CollateralValue,
LoanF.LoanFinanceID
INTO #LoanCollateralValueDetails
From
#LoanDetails LoanF
LEFT JOIN CollateralAssets CA
on LoanF.LoanFinanceID = CA.LoanFinanceId
GROUP BY LoanF.LoanFinanceID

Select
LoanF.SequenceNumber as SequenceNumber ,
LoanF.Alias as Alias ,
LoanF.LegalEntityName as LegalEntityName  ,
LoanF.LineOfBusiness as LineOfBusiness  ,
LoanF.Status as Status ,
LoanF.ProductType as ProductType  ,
CTE.CollateralValue as CollateralValue,
LoanF.Term as Term ,
LoanF.RemainingTerm  as RemainingTerm ,
LoanF.CommencementDate as CommencementDate ,
LoanF.MaturityDate as MaturityDate ,
LoanF.Frequency as Frequency,
LoanF.CollectionStatus as CollectionStatus ,
LoanF.IsAccrual ,
LoanF.Id,
LoanF.Currency,
LoanF.SyndicationType,
LoanF.IsAdvance,
LoanF.OverallDPD ,
LoanF.IsNonNotification INTO #LD
From
#LoanDetails LoanF
INNER JOIN #LoanCollateralValueDetails CTE
on LoanF.LoanFinanceID = CTE.LoanFinanceId


SELECT
Contracts.Id [ContractId],
PrimaryCollector.FullName [PrimaryCollector]
INTO #ContractCollectionDetail
FROM Contracts
INNER JOIN CollectionWorkListContractDetails ON Contracts.Id = CollectionWorkListContractDetails.ContractId
INNER JOIN CollectionWorkLists ON CollectionWorkListContractDetails.CollectionWorkListId = CollectionWorkLists.Id
INNER JOIN Users [PrimaryCollector] ON CollectionWorkLists.PrimaryCollectorId = PrimaryCollector.Id
WHERE CollectionWorkLists.Status = 'Open'
AND CollectionWorkLists.CustomerId = @CustomerId

INSERT INTO #PrimaryAndSecondaryCollectorForContract(ContractId,PrimaryCollector)
SELECT #ContractCollectionDetail.ContractId,PrimaryCollector
FROM #ContractCollectionDetail
INNER JOIN  #LD AS LF
ON  #ContractCollectionDetail.ContractId = LF.Id
Select Distinct
LoanF.SequenceNumber as SequenceNumber ,
LoanF.Alias as Alias ,
LoanF.LegalEntityName as LegalEntityName  ,
LoanF.LineOfBusiness as LineOfBusiness  ,
LoanF.Status as Status ,
LoanF.ProductType as ProductType  ,
LoanF.CollateralValue as CollateralValue,
LoanF.Term as Term ,
LoanF.RemainingTerm  as RemainingTerm ,
LoanF.CommencementDate as CommencementDate ,
LoanF.MaturityDate as MaturityDate ,
LoanF.Frequency as Frequency,
LoanF.CollectionStatus as CollectionStatus ,
LoanF.IsAccrual ,
LoanF.Id,
LoanF.Currency,
LoanF.SyndicationType,
PS.PrimaryCollector,
LoanF.IsAdvance,
LoanF.OverallDPD ,
LoanF.IsnonNotification  as IsNonNotification
From
#LD LoanF
LEFT JOIN #PrimaryAndSecondaryCollectorForContract  PS
on LoanF.Id = PS.ContractId
DROP TABLE #PrimaryAndSecondaryCollectorForContract
DROP TABLE #AssumptionDetails
DROP TABLE #ValidContractIds
DROP TABLE #LoanDetails
DROP TABLE #LD
DROP TABLE #ContractCollectionDetail
DROP TABLE #LoanCollateralValueDetails
END

GO
