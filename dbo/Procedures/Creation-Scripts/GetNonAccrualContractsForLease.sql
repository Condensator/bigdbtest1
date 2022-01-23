SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetNonAccrualContractsForLease]
(
@ContractIds IdCollection READONLY,
@LeaseContractType NVARCHAR(20),
@ReceivableContractType NVARCHAR(20),
@ReceiptStatusPosted NVARCHAR(20),
@ReceiptStatusReadyForPosting NVARCHAR(20),
@InvoicePreferenceDoNotGenerate NVARCHAR(30),
@ValidReceivableTypes NVARCHAR(MAX),
@FromJob BIT,
@AmendmentAppprovedStatus NVARCHAR(30),
@RestructureAmendmentType NVARCHAR(30),
@RebookAmendmentType NVARCHAR(30),
@SyndicationAmendmentType NVARCHAR(30),
@AssumptionAmendmentType NVARCHAR(30),
@NonAccrualAmendmentType NVARCHAR(30),
@ReAccrualAmendmentType NVARCHAR(30),
@PayoffAmendmentType NVARCHAR(30),
@PayDownAmendmentType NVARCHAR(30),
@ReceiptAmendmentType NVARCHAR(20),
@GLTransferAmendmentType NVARCHAR(20),
@RenewalAmendmentType NVARCHAR(20),
@NBVImpairmentAmendmentType NVARCHAR(20),
@ResidualImpairmentAmendmentType NVARCHAR(20),
@IsEdit BIT
)
AS
BEGIN
SET NOCOUNT ON

SELECT ContractId = Id INTO #SelectedContracts FROM @ContractIds

SELECT DISTINCT NACI.ContractId
INTO #ContractsWithSKUs
FROM #SelectedContracts NACI
JOIN LeaseFinances LF ON NACI.ContractId = LF.ContractId AND LF.IsCurrent = 1
JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId AND LA.IsActive = 1
JOIN LeaseAssetSKUs LAS WITH (FORCESEEK) ON LA.Id = LAS.LeaseAssetId AND LAS.IsActive = 1

SELECT
C.Id ContractId,
LeaseLE.Id LegalEntityId,
LeaseLE.Name LegalEntityName,
Lease.Id LeaseFinanceId,
LeaseCustomer.Id CustomerId,
LeaseParty.PartyName CustomerName,
LeaseParty.PartyNumber CustomerNumber,
LFD.CommencementDate,
LFD.MaturityDate,
LFD.NetInvestment_Currency ContractCurrencyCode,
LFD.LeaseContractType,
LFD.NetInvestment_Amount NetInvestment,
LFD.Id LeaseFinanceDetailId,
CAST(0 AS BIT) IsDSL,
Lease.HoldingStatus,
C.AccountingStandard,
LFD.LastExtensionARUpdateRunDate,
LFD.LastSupplementalARUpdateRunDate,
LFD.IsFloatRateLease,
CASE WHEN CWS.ContractId IS NULL THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END HasSKU,
C.IsNonAccrualExempt IsContractNonAccrualExempt,
LeaseCustomer.IsNonAccrualExempt IsCustomerNonAccrualExempt,
C.Alias AS ContractAlias,
C.SequenceNumber,
Lease.FloatRateUpdateRunDate,
LFD.IsOverTermLease
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN LeaseFinances Lease ON Lease.ContractId = C.Id AND Lease.IsCurrent = 1
JOIN LeaseFinanceDetails LFD ON Lease.Id = LFD.Id
JOIN LegalEntities LeaseLE ON  Lease.LegalEntityId = LeaseLE.Id
JOIN Customers LeaseCustomer ON Lease.CustomerId = LeaseCustomer.Id
JOIN Parties LeaseParty ON LeaseCustomer.Id = LeaseParty.Id
LEFT JOIN #ContractsWithSKUs CWS ON C.Id = CWS.ContractId

DROP TABLE #SelectedContracts
END

GO
