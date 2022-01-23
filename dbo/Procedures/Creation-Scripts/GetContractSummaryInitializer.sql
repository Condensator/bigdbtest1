SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetContractSummaryInitializer]
(
@ContractSequenceNumber nvarchar(80),
@ContractId BIGINT,
@SyndicationType NVarchar(16),
@ContractType NVarchar(16),
@Currency NVarchar(3),
@CurrentBusinessDate DATETIMEOFFSET,
@FilterCustomerId BIGINT NULL = NULL,
@AccessibleLegalEntities NVARCHAR(MAX)
)
AS
BEGIN
SET NOCOUNT ON
----DECLARE
---- @ContractSequenceNumber nvarchar(80) = 'M02_LSMP8',
----   @ContractId BIGINT=103351,
----   @SyndicationType NVarchar(16)='None',
----   @ContractType NVarchar(16)='Lease',
----   @Currency NVarchar(3)='USD',
----   @CurrentBusinessDate DATETIMEOFFSET= SYSDATETIMEOFFSET(),
----   @FilterCustomerId BIGINT = NULL ,
----   @AccessibleLegalEntities NVARCHAR(MAX) =1
--============================SecurityDepositAmount===============================
Declare @SecurityDepositAmount decimal(16,2)
Declare @Amount decimal(16,2)
Declare @AppliedAmount decimal(16,2)
SELECT @Amount = ISNULL(SUM(Amount_Amount),0) FROM SecurityDeposits WHERE ContractId = @ContractId AND (@FilterCustomerId IS NULL OR CustomerId = @FilterCustomerId) AND IsActive = 1
SELECT @AppliedAmount = ISNULL(SUM(sda.TransferToIncome_Amount + sda.TransferToReceipt_Amount + sda.AssumedAmount_Amount),0)
FROM SecurityDeposits s
JOIN dbo.SecurityDepositApplications sda
ON s.Id=sda.SecurityDepositId
AND s.ContractId = @ContractId AND (@FilterCustomerId IS NULL OR s.CustomerId = @FilterCustomerId)
AND s.IsActive = 1 AND sda.IsActive = 1
SELECT @SecurityDepositAmount = @Amount - @AppliedAmount
--========================Outstanding Receivable Balance=============================
Declare @OutstandingBalance decimal(16,2)
SELECT @OutstandingBalance= ISNULL(SUM(RID.Balance_Amount + RID.TaxBalance_Amount),0) FROM ReceivableInvoices AS RI
INNER JOIN ReceivableInvoiceDetails AS RID ON RI.Id = RID.ReceivableInvoiceId AND RI.Id = RID.ReceivableInvoiceId
INNER JOIN Receivables R ON RID.ReceivableId = R.Id AND R.IsActive = 1 AND (R.CreationSourceTable IS NULL OR (R.CreationSourceTable IS NOT NULL AND R.CreationSourceTable <> 'ReceivableForTransfer'))
AND RI.IsDummy = 0  AND RID.EntityType = 'CT' AND RID.EntityId = @ContractId AND RI.IsActive =1
--=========================================================================
DECLARE @PrivateLabel Bit=0
DECLARE @CoBrand Bit=0
DECLARE @IsNonNotification Bit=0
DECLARE @NumberofPaymentsMade int
DECLARE @NumberofSkipPayments int
DECLARE @RemainingRentalAmount decimal (16,2)
DECLARE @LastPaymentReceivedDate datetime
DECLARE @OTPReceivableExists bit
DECLARE @Owner NVARCHAR(MAX)
DECLARE @OriginationSourceType NVARCHAR(MAX)=''
DECLARE @Servicer NVARCHAR(MAX)
DECLARE @LegalEntityName NVARCHAR(100)
DECLARE @NumberOfPayments int
DECLARE @NumberOfPaymentsRemaining int
DECLARE @FirstPaymentDueDate DATETIME
DECLARE @NextPaymentDueDate DATETIME
DECLARE @NextPaymentAmount decimal (16,2)=0.0
DECLARE @PartyID BIGINT
DECLARE @DaysPastDue int
DECLARE @LastReceiptDate Datetime
DECLARE @OldestRentDueDate Datetime
DECLARE @NonRentPastDue Decimal(16,2)
DECLARE @RentPastDue Decimal(16,2)
DECLARE @NumberOfNSFs INT = 0
DECLARE @LastCollectionActivityType NVARCHAR(50)
DECLARE @LastCollectionActivityDate DATETIME
DECLARE @LastPromiseToPayKept DATETIME
IF @ContractType = 'Lease'
BEGIN
SELECT @LegalEntityName = LE.Name  , @PartyID = lf.CustomerId
from leasefinances lf
INNER JOIN LegalEntities LE ON lf.LegalEntityId = LE.Id
AND lf.IsCurrent = 1 AND lf.ContractId = @ContractId;
SELECT ContractOriginationId, co.AcquiredPortfolioId, co.OriginationSourceTypeId , co.OriginationSourceId , OST.Name OriginationSourceType
INTO #ContractOriginationIds
from leasefinances lf
JOIN dbo.ContractOriginations co ON lf.ContractOriginationId = co.Id
LEFT JOIN OriginationSourceTypes OST ON co.OriginationSourceTypeId = OST.Id
where lf.IsCurrent = 1 AND lf.ContractId = @ContractId
SET @OriginationSourceType = (SELECT OriginationSourceType FROM #ContractOriginationIds)
IF EXISTS (SELECT * FROM #ContractOriginationIds)
BEGIN
SELECT Top 1 @PrivateLabel=sd.IsPrivateLabel, @CoBrand=sd.IsCobrand, @IsNonNotification=sd.IsNonNotification
FROM dbo.ContractOriginationServicingDetails cosd
JOIN dbo.ServicingDetails sd ON cosd.ServicingDetailId = sd.Id AND sd.IsActive = 1
JOIN dbo.#ContractOriginationIds coi ON cosd.ContractOriginationId = coi.ContractOriginationId
JOIN dbo.OriginationSourceTypes ost ON coi.OriginationSourceTypeId = ost.Id AND ost.Name <> 'Direct'
END
--===========#Funders, @PrivateLabel, @OTPReceivableExists(contractreceivable) ============================
IF @SyndicationType <> 'None' AND @SyndicationType <> '_'
BEGIN
SELECT Distinct p.PartyName, p.PartyNumber, rfts.EffectiveDate, IsServiced INTO #Funders
FROM dbo.ReceivableForTransferFundingSources rftfs
JOIN dbo.ReceivableForTransfers rft ON rftfs.ReceivableForTransferId = rft.Id AND rft.ContractId = @ContractId
JOIN ReceivableForTransferServicings rfts ON rft.Id = rfts.ReceivableForTransferId And rfts.IsActive = 1
JOIN dbo.Parties p ON rftfs.FunderId = p.Id
SELECT @PrivateLabel = rfts.IsPrivateLabel FROM dbo.ReceivableForTransferServicings rfts
JOIN dbo.ReceivableForTransfers rft ON rfts.ReceivableForTransferId = rft.id
AND rft.ContractId = @ContractId AND rft.ApprovalStatus <> 'Inactive'
AND rfts.IsActive = 1 AND rfts.IsPrivateLabel = 1
SELECT @OTPReceivableExists = COUNT(*) FROM dbo.Receivables r
JOIN dbo.ReceivableCodes rc ON rc.Id = r.ReceivableCodeId
AND r.EntityId = @ContractId AND r.IsActive = 1
JOIN dbo.ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
AND rt.Name In ('OverTermRental','Supplemental')
IF(@SyndicationType = 'ParticipatedSale' OR (@SyndicationType = 'FullSale' AND (SELECT COUNT(Distinct PartyNumber) FROM #Funders) > 1 ))
BEGIN
SET @Owner = 'Multiple'
END
ELSE IF (@PrivateLabel = 0 AND (SELECT COUNT(*) FROM #ContractOriginationIds WHERE ContractOriginationId IS NOT NULL AND OriginationSourceId IS NOT NULL AND (AcquiredPortfolioId IS NOT NULL OR OriginationSourceType = 'Indirect')) > 0)
BEGIN
SELECT @Owner = (CASE WHEN IsSoleProprietor = 0 AND IsCorporate = 1 THEN CompanyName ELSE ISNULL(FirstName,'') + ' ' + ISNULL(MiddleName,'') + ' '+ ISNULL(LastName,'') END) FROM #ContractOriginationIds co
INNER JOIN Parties p on co.OriginationSourceId = p.Id
END
ELSE IF (@SyndicationType = 'SaleOfPayments' AND @OTPReceivableExists = 1)
BEGIN
SET @Owner = @LegalEntityName
END
ELSE
BEGIN
SELECT distinct  @Owner = ISNULL(@Owner + ', ', '') +  PartyName FROM #Funders
END
IF((SELECT TOP 1 IsServiced FROM #Funders WHERE EffectiveDate <= GETDATE()) = 1)
BEGIN
SET @Servicer = @LegalEntityName
END
ELSE
BEGIN
SELECT   @Servicer = ISNULL(@Owner + ', ', '') + PartyName FROM #Funders  WHERE EffectiveDate <= GETDATE()
END
DROP TABLE #Funders
END
ELSE
BEGIN
SET @Owner = @LegalEntityName
IF((SELECT COUNT(*) FROM #ContractOriginationIds WHERE OriginationSourceType IS NOT NULL AND OriginationSourceType <> 'Direct') > 0 AND (SELECT COUNT(*) FROM ContractOriginationServicingDetails cosd INNER JOIN #ContractOriginationIds co ON cosd.ContractOriginationId = co.ContractOriginationId INNER JOIN ServicingDetails sd ON cosd.ServicingDetailID = sd.ID WHERE sd.IsServiced = 1 AND sd.EffectiveDate <= GETDATE()) > 0)
BEGIN
SET @Servicer = @LegalEntityName
END
ELSE
BEGIN
SELECT @Servicer = PartyName FROM #ContractOriginationIds co
INNER JOIN Parties p on co.OriginationSourceId = p.Id    END
END
IF(@Servicer IS NULL)
BEGIN
SET @Servicer = @LegalEntityName
END
DROP TABLE #ContractOriginationIds
--======================NumberofPaymentsMade, NumberofSkipPayments,RemainingRentalAmount,LastReceiptDate============================
SELECT r.PaymentScheduleId,rd.ReceivableId, rd.Id ReceivableDetailId, rd.AdjustmentBasisReceivableDetailId, r.TotalAmount_Amount, r.TotalBalance_Amount, CAST(0.00 AS Decimal(16,2)) AS  TaxAmount_Amount, CAST(0.00 AS Decimal(16,2)) AS  TaxBalance_Amount
INTO #Receivables FROM dbo.Receivables r
JOIN dbo.ReceivableDetails rd ON r.Id=rd.ReceivableId
AND r.EntityId = @ContractId AND r.EntityType = 'CT' AND r.IsActive=1 AND rd.IsActive = 1 AND (@FilterCustomerId IS NULL OR r.CustomerId = @FilterCustomerId)
JOIN dbo.LeasePaymentSchedules lps ON r.PaymentScheduleId = lps.Id AND r.SourceTable = '_' AND lps.IsActive = 1
AND lps.PaymentType = 'FixedTerm'
JOIN ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
JOIN ReceivableTypes ON rc.ReceivableTypeId = ReceivableTypes.Id
WHERE ReceivableTypes.Name like '%Rental%'

Update #Receivables
set TaxAmount_Amount = ISNULL(rt.Amount_Amount,0.00), TaxBalance_Amount =  ISNULL(rt.Balance_Amount,0.00)
from #Receivables r
JOIN ReceivableTaxes rt ON r.ReceivableId = rt.ReceivableId AND rt.IsActive = 1

SELECT lps.DueDate , lps.Amount_Amount INTO #LeasePaymentScheduleDueDates
from leasefinances lf
JOIN dbo.LeasePaymentSchedules lps ON lf.Id = lps.LeaseFinanceDetailId AND lps.IsActive = 1
AND lps.PaymentType = 'FixedTerm'  AND lf.IsCurrent = 1 AND lf.ContractId = @ContractId AND (@FilterCustomerId IS NULL OR lps.CustomerId = @FilterCustomerId)
SELECT @NumberOfPayments = COUNT(*) FROM #LeasePaymentScheduleDueDates
SELECT TOP 1 @FirstPaymentDueDate = DueDate FROM #LeasePaymentScheduleDueDates ORDER BY DueDate ASC
SELECT TOP 1 @NextPaymentDueDate = DueDate, @NextPaymentAmount = Amount_Amount FROM #LeasePaymentScheduleDueDates
WHERE DueDate > GETDATE()
ORDER BY DueDate
SELECT @RemainingRentalAmount =   isnull(sum(temp.TotalBalance_Amount),0) FROM (
SELECT DISTINCT r.PaymentScheduleId, r.TotalBalance_Amount FROM dbo.Receivables r
JOIN dbo.ReceivableDetails rd ON r.Id=rd.ReceivableId
AND r.EntityId = @ContractId AND r.EntityType = 'CT' AND r.IsActive=1 AND rd.IsActive = 1
AND (@FilterCustomerId IS NULL OR r.CustomerId = @FilterCustomerId)
JOIN dbo.LeasePaymentSchedules lps ON r.PaymentScheduleId = lps.Id AND r.SourceTable = '_' AND lps.IsActive = 1
AND lps.PaymentType = 'FixedTerm')temp
SELECT @LastPaymentReceivedDate = MAX(CASE WHEN r.ReceivedDate IS NOT NULL THEN r.ReceivedDate ELSE r.PostDate End) FROM dbo.Receipts r
JOIN dbo.ReceiptApplications ra ON r.Id = ra.ReceiptId AND r.Status='Posted'
JOIN dbo.ReceiptApplicationReceivableDetails rard ON ra.Id=rard.ReceiptApplicationId AND rard.IsActive = 1
JOIN dbo.#Receivables r2 ON rard.ReceivableDetailId = r2.ReceivableDetailId
DELETE FROM #Receivables WHERE ReceivableDetailId IN (SELECT AdjustmentBasisReceivableDetailId FROM dbo.#Receivables)
DELETE FROM #Receivables WHERE AdjustmentBasisReceivableDetailId IS NOT NULL
SELECT @NumberofPaymentsMade = COUNT(DISTINCT PaymentScheduleId)  FROM dbo.#Receivables ar WHERE ar.TotalBalance_Amount = 0 AND ar.TotalAmount_Amount <> 0 AND ar.TaxBalance_Amount = 0 --AND ar.TaxAmount_Amount <> 0 Hint: If lease is tax exempted, then Tax Amount_Amount is always 0
SELECT @NumberofSkipPayments = COUNT(*) FROM dbo.#Receivables ar WHERE ar.TotalAmount_Amount = 0 AND ar.TotalBalance_Amount = 0 AND ar.TaxAmount_Amount = 0 AND ar.TaxBalance_Amount = 0
SELECT @NumberOfPaymentsRemaining = CASE WHEN (@NumberOfPayments - @NumberofPaymentsMade)>0 THEN(@NumberOfPayments - @NumberofPaymentsMade) ELSE 0 END
DROP TABLE #LeasePaymentScheduleDueDates
DROP TABLE #Receivables
END
ELSE IF @ContractType = 'Loan' Or @ContractType='ProgressLoan'
BEGIN
SELECT @LegalEntityName = LE.Name , @PartyID = lf.CustomerId
from LoanFinances lf
INNER JOIN LegalEntities LE ON lf.LegalEntityId = LE.Id
AND lf.IsCurrent = 1 AND lf.ContractId = @ContractId;
SELECT ContractOriginationId, co.AcquiredPortfolioId, co.OriginationSourceTypeId , co.OriginationSourceId , OST.Name OriginationSourceType
INTO #LoanContractOriginationIds
from LoanFinances lf
JOIN dbo.ContractOriginations co ON lf.ContractOriginationId = co.Id
LEFT JOIN OriginationSourceTypes OST ON co.OriginationSourceTypeId = OST.Id
where lf.IsCurrent = 1 AND lf.ContractId = @ContractId
SET @OriginationSourceType = (SELECT OriginationSourceType FROM #LoanContractOriginationIds)
IF EXISTS (SELECT * FROM #LoanContractOriginationIds)
BEGIN
SELECT Top 1 @PrivateLabel=sd.IsPrivateLabel, @CoBrand=sd.IsCobrand, @IsNonNotification=sd.IsNonNotification
FROM dbo.ContractOriginationServicingDetails cosd
JOIN dbo.ServicingDetails sd ON cosd.ServicingDetailId = sd.Id AND sd.IsActive = 1
JOIN dbo.#LoanContractOriginationIds coi ON cosd.ContractOriginationId = coi.ContractOriginationId
JOIN dbo.OriginationSourceTypes ost ON coi.OriginationSourceTypeId = ost.Id AND ost.Name <> 'Direct'
END
--===========#Funders, @PrivateLabel, @OTPReceivableExists(contractreceivable) ============================
IF @SyndicationType <> 'None' AND @SyndicationType <> '_'
BEGIN
SELECT Distinct p.PartyName, p.PartyNumber,rfts.EffectiveDate, IsServiced INTO #LoanFunders
FROM dbo.ReceivableForTransferFundingSources rftfs
JOIN dbo.ReceivableForTransfers rft ON rftfs.ReceivableForTransferId = rft.Id AND rft.ContractId = @ContractId
JOIN ReceivableForTransferServicings rfts ON rft.Id = rfts.ReceivableForTransferId And rfts.IsActive = 1
JOIN dbo.Parties p ON rftfs.FunderId = p.Id
SELECT @PrivateLabel = rfts.IsPrivateLabel FROM dbo.ReceivableForTransferServicings rfts
JOIN dbo.ReceivableForTransfers rft ON rfts.ReceivableForTransferId = rft.id
AND rft.ContractId = @ContractId AND rft.ApprovalStatus <> 'Inactive'
AND rfts.IsActive = 1 AND rfts.IsPrivateLabel = 1
SELECT @OTPReceivableExists = COUNT(*) FROM dbo.Receivables r
JOIN dbo.ReceivableCodes rc ON rc.Id = r.ReceivableCodeId
AND r.EntityId = @ContractId AND r.IsActive = 1
JOIN dbo.ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
AND rt.Name In ('OverTermRental','Supplemental')
IF(@SyndicationType = 'ParticipatedSale' OR (@SyndicationType = 'FullSale' AND (SELECT COUNT(Distinct PartyNumber) FROM #LoanFunders) > 1 ))
BEGIN
SET @Owner = 'Multiple'
END
ELSE IF (@PrivateLabel = 0 AND (SELECT COUNT(*) FROM #LoanContractOriginationIds WHERE ContractOriginationId IS NOT NULL AND OriginationSourceId IS NOT NULL AND (AcquiredPortfolioId IS NOT NULL OR OriginationSourceType = 'Indirect')) > 0)
BEGIN
SELECT @Owner = (CASE WHEN IsSoleProprietor = 0 AND IsCorporate = 1 THEN CompanyName ELSE ISNULL(FirstName,'') + ' ' + ISNULL(MiddleName,'') + ' '+ ISNULL(LastName,'') END) FROM #LoanContractOriginationIds co
INNER JOIN Parties p on co.OriginationSourceId = p.Id
END
ELSE IF (@SyndicationType = 'SaleOfPayments' AND @OTPReceivableExists = 1)
BEGIN
SET @Owner = @LegalEntityName
END
ELSE
BEGIN
SELECT distinct   @Owner = ISNULL(@Owner + ', ', '') + PartyName FROM #LoanFunders
END
IF((SELECT TOP 1 IsServiced FROM #LoanFunders WHERE EffectiveDate <= GETDATE()) = 1)
BEGIN
SET @Servicer = @LegalEntityName
END
ELSE
BEGIN
SELECT   @Servicer = ISNULL(@Owner + ', ', '') + PartyName FROM #LoanFunders  WHERE EffectiveDate <= GETDATE()
END
DROP TABLE #LoanFunders
END
ELSE
BEGIN
SET @Owner = @LegalEntityName
IF((SELECT COUNT(*) FROM #LoanContractOriginationIds WHERE OriginationSourceType IS NOT NULL AND OriginationSourceType <> 'Direct') > 0 AND (SELECT COUNT(*) FROM ContractOriginationServicingDetails cosd INNER JOIN #LoanContractOriginationIds co ON cosd.
ContractOriginationId = co.ContractOriginationId INNER JOIN ServicingDetails sd ON cosd.ServicingDetailID = sd.ID WHERE sd.IsServiced = 1 AND sd.EffectiveDate <= GETDATE()) > 0)
BEGIN
SET @Servicer = @LegalEntityName
END
ELSE
BEGIN
SELECT @Servicer = PartyName FROM #LoanContractOriginationIds co
INNER JOIN Parties p on co.OriginationSourceId = p.Id
END
END
IF(@Servicer IS NULL)
BEGIN
SET @Servicer = @LegalEntityName
END
--======================NumberofPaymentsMade, NumberofSkipPayments,RemainingRentalAmount,LastReceiptDate============================
SELECT r.PaymentScheduleId,rd.ReceivableId, rd.Id ReceivableDetailId, rd.AdjustmentBasisReceivableDetailId, r.TotalAmount_Amount, r.TotalBalance_Amount , ISNULL(rt.Amount_Amount,0.00) TaxAmount_Amount, ISNULL(rt.Balance_Amount,0.00) TaxBalance_Amount
INTO #LoanReceivables FROM dbo.Receivables r
JOIN dbo.ReceivableDetails rd ON r.Id=rd.ReceivableId
AND r.EntityId = @ContractId AND r.EntityType = 'CT' AND r.IsActive=1 AND rd.IsActive = 1 AND (@FilterCustomerId IS NULL OR r.CustomerId = @FilterCustomerId)
JOIN dbo.LoanPaymentSchedules lps ON r.PaymentScheduleId = lps.Id AND r.SourceTable = '_' AND lps.IsActive = 1 AND lps.PaymentNumber != 0
AND lps.PaymentType = 'FixedTerm' AND lps.IsFromReceiptPosting = 0
LEFT JOIN ReceivableTaxes rt ON r.id = rt.ReceivableId AND rt.IsActive = 1
JOIN ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
JOIN ReceivableTypes ON rc.ReceivableTypeId = ReceivableTypes.Id
WHERE (ReceivableTypes.Name = 'LoanInterest' OR ReceivableTypes.Name = 'LoanPrincipal')
SELECT lps.DueDate , lps.Amount_Amount INTO #LoanPaymentScheduleDueDates
from loanfinances lf
JOIN dbo.LoanPaymentSchedules lps ON lf.Id = lps.LoanFinanceId AND lps.IsActive = 1 AND lps.PaymentNumber != 0
AND lps.PaymentType = 'FixedTerm'  AND lf.IsCurrent = 1 AND lf.ContractId = @ContractId AND (@FilterCustomerId IS NULL OR lps.CustomerId = @FilterCustomerId)
SELECT @NumberOfPayments = COUNT(*) FROM #LoanPaymentScheduleDueDates
SELECT TOP 1 @FirstPaymentDueDate = DueDate FROM #LoanPaymentScheduleDueDates ORDER BY DueDate ASC
SELECT TOP 1 @NextPaymentDueDate = DueDate, @NextPaymentAmount = Amount_Amount FROM #LoanPaymentScheduleDueDates
WHERE DueDate > GETDATE()
ORDER BY DueDate
SELECT @RemainingRentalAmount =   isnull(sum(temp.TotalBalance_Amount),0) FROM (
SELECT DISTINCT r.PaymentScheduleId, r.TotalBalance_Amount FROM dbo.Receivables r
JOIN dbo.ReceivableDetails rd ON r.Id=rd.ReceivableId
AND r.EntityId = @ContractId AND r.EntityType = 'CT' AND r.IsActive=1 AND rd.IsActive = 1 AND r.SourceTable!='SundryRecurring'
AND (@FilterCustomerId IS NULL OR r.CustomerId = @FilterCustomerId)
JOIN dbo.LoanPaymentSchedules lps ON r.PaymentScheduleId = lps.Id AND r.SourceTable = '_' AND lps.IsActive = 1 AND lps.PaymentNumber != 0
AND lps.PaymentType = 'FixedTerm' AND lps.IsFromReceiptPosting = 0)temp
SELECT @LastPaymentReceivedDate = MAX(CASE WHEN r.ReceivedDate IS NOT NULL THEN r.ReceivedDate ELSE r.PostDate End) FROM dbo.Receipts r
JOIN dbo.ReceiptApplications ra ON r.Id = ra.ReceiptId AND r.Status='Posted'
JOIN dbo.ReceiptApplicationReceivableDetails rard ON ra.Id=rard.ReceiptApplicationId AND rard.IsActive = 1
JOIN dbo.#LoanReceivables  r2 ON rard.ReceivableDetailId = r2.ReceivableDetailId
DELETE FROM #LoanReceivables  WHERE ReceivableDetailId IN (SELECT AdjustmentBasisReceivableDetailId FROM dbo.#LoanReceivables )
DELETE FROM #LoanReceivables  WHERE AdjustmentBasisReceivableDetailId IS NOT NULL
SELECT @NumberofPaymentsMade=  COUNT(DISTINCT PaymentScheduleId)  FROM (SELECT PaymentScheduleId, SUM(TotalAmount_Amount) TotalAmount_Amount, SUM(TotalBalance_Amount) TotalBalance_Amount,SUM(TaxBalance_Amount)  TaxBalance_Amount,Sum(TaxAmount_Amount)  TaxAmount_Amount FROM
dbo.#LoanReceivables a GROUP BY a.PaymentScheduleId ) ar WHERE ar.TotalBalance_Amount = 0 AND ar.TotalAmount_Amount <> 0 AND ar.TaxBalance_Amount = 0 --AND ar.TaxAmount_Amount <> 0 Hint: For Loans TaxAmount_Amount is always 0 and if TotalAmount_Amount is 0, then TaxAmount_Amount is also 0
SELECT @NumberofSkipPayments = COUNT(*) FROM dbo.#LoanReceivables  ar WHERE ar.TotalAmount_Amount = 0 AND ar.TotalBalance_Amount = 0 AND ar.TaxAmount_Amount = 0 AND ar.TaxBalance_Amount = 0
SELECT @NumberOfPaymentsRemaining = CASE WHEN (@NumberOfPayments - @NumberofPaymentsMade)>0 THEN(@NumberOfPayments - @NumberofPaymentsMade) ELSE 0 END
DROP TABLE #LoanReceivables
DROP TABLE #LoanContractOriginationIds
DROP TABLE #LoanPaymentScheduleDueDates
END
--===================EffectiveBalance=================================
DECLARE @EffectiveBalance decimal(16,2)
SELECT r.EntityId,r.TotalBalance_Amount,rd.IsActive,r.DueDate,r.id into #totalDue FROM dbo.Receivables r
JOIN dbo.ReceivableDetails rd ON r.Id=rd.ReceivableId
AND r.EntityId = @ContractId AND r.EntityType = 'CT' AND ( @FilterCustomerId IS NULL OR r.CustomerId = @FilterCustomerId)
AND r.IsActive=1 AND rd.IsActive = 1 AND r.DueDate <= GETDATE()
AND (r.IsDSL =1 AND r.IsDummy=1 OR r.IsDSL =0 AND r.IsDummy =0)
AND (r.CreationSourceTable IS NULL OR (r.CreationSourceTable IS NOT null AND r.CreationSourceTable <> 'ReceivableForTransfer'))
SELECT @EffectiveBalance =  sum(TotalBalance_Amount) from (select TotalBalance_Amount from #totalDue group by TotalBalance_Amount,Id) r
SELECT afcwl.Id , at.Name ActivityTypeName,at.Type ActivityType,afcwl.PromiseToPayDate , a.CreatedDate ActivityCreatedDate INTO #CollectionWorkLists
FROM dbo.ActivityForCollectionWorkLists afcwl
JOIN Activities a on afcwl.Id = a.Id
JOIN ActivityTypes at on a.ActivityTypeId = at.Id
JOIN dbo.CollectionWorkLists cwl ON afcwl.CollectionWorkListId=cwl.Id
AND cwl.CustomerId = @PartyID AND afcwl.ContractId = @ContractId
AND a.IsActive = 1
CREATE TABLE #GetInvoicesPastDueForContractServiceInitializer (DaysPastDue int,LastReceiptDate Datetime,OldestRentDueDate Datetime,NonRentPastDue Decimal(16,2),RentPastDue Decimal(16,2),NumberOfNSFs INT )
INSERT INTO #GetInvoicesPastDueForContractServiceInitializer (DaysPastDue,LastReceiptDate,OldestRentDueDate,NonRentPastDue,RentPastDue,NumberOfNSFs)
exec GetInvoicesPastDueForContractServiceInitializer @ContractSequenceNumber,@FilterCustomerId,@CurrentBusinessDate,@AccessibleLegalEntities
SELECT @DaysPastDue =DaysPastDue,@LastReceiptDate =LastReceiptDate,@OldestRentDueDate =OldestRentDueDate,@NonRentPastDue =NonRentPastDue,@RentPastDue =RentPastDue,@NumberOfNSFs =NumberOfNSFs
FROM #GetInvoicesPastDueForContractServiceInitializer
SELECT TOP 1 @LastCollectionActivityType = ActivityTypeName,@LastCollectionActivityDate = ActivityCreatedDate FROM #CollectionWorkLists ORDER BY ID DESC
SELECT TOP 1 @LastPromiseToPayKept = PromiseToPayDate FROM #CollectionWorkLists WHERE ActivityType = 'PromiseToPay' AND PromiseToPayDate < GETDATE() ORDER BY ActivityCreatedDate DESC
SELECT
@LegalEntityName LegalEntity,
@SecurityDepositAmount SecurityDeposit_Amount ,
@Currency SecurityDeposit_Currency,
@OutstandingBalance OutstandingBalance_Amount ,
@Currency OutstandingBalance_Currency,
@PrivateLabel PrivateLabel,
@CoBrand CoBrand,
@IsNonNotification IsNonNotification ,
@Owner Owner,
@Servicer Servicer,
@NumberOfPayments NumberOfPayments,
@NumberofPaymentsMade NumberofPaymentsMade,
@NumberofSkipPayments NumberofSkipPayments,
@NumberOfPaymentsRemaining NumberOfPaymentsRemaining,
@FirstPaymentDueDate FirstPaymentDueDate,
@LastPaymentReceivedDate LastPaymentReceivedDate,
@RemainingRentalAmount RemainingRentalAmount_Amount,
@Currency RemainingRentalAmount_Currency,
@NextPaymentDueDate NextPaymentDueDate,
@NextPaymentAmount NextPaymentAmount_Amount,
@Currency NextPaymentAmount_Currency,
@EffectiveBalance TotalDueAmount_Amount,
@Currency TotalDueAmount_Currency,
@DaysPastDue DaysPastDue,
@LastReceiptDate LastReceiptDate,
@OldestRentDueDate OldestRentDueDate,
@NonRentPastDue NonRentPastDue_Amount,
@Currency NonRentPastDue_Currency,
@RentPastDue RentPastDue_Amount,
@Currency RentPastDue_Currency,
@NumberOfNSFs NumberOfNSFs,
@LastCollectionActivityType LastCollectionActivityType,
@LastCollectionActivityDate LastCollectionActivityDate,
@LastPromiseToPayKept LastPromiseToPayKept,
@OriginationSourceType OriginationChannel
DROP TABLE #totalDue
DROP TABLE #CollectionWorkLists
DROP TABLE #GetInvoicesPastDueForContractServiceInitializer
END

GO
