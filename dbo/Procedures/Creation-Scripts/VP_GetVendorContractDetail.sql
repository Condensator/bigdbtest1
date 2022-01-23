SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create PROC [dbo].[VP_GetVendorContractDetail]
(
@IsProgramVendor BIT,
@CurrentVendorId BIGINT,
@ProgramVendor NVARCHAR(100)=NULL,
@ContractId BIGINT=NULL,
@CustomerNumber NVARCHAR(100)=NULL,
@CustomerName NVARCHAR(100)=NULL,
@SequenceNumber NVARCHAR(100)=NULL,
@CreditApplication NVARCHAR(100)=NULL,
@ContractStatus NVARCHAR(100)=NULL,
@ApprovalStatus NVARCHAR(100)=NULL,
@CommencementDateFrom DATETIMEOFFSET=NULL,
@CommencementDateTo DATETIMEOFFSET=NULL,
@Term DECIMAL(10,6)=NULL,
@MaturityDateFrom DATETIMEOFFSET=NULL,
@MaturityDateTo DATETIMEOFFSET=NULL,
@SerialNumber nvarchar(100) = NULL,
@ExternalReferenceNumber nvarchar(100) = NULL,
@ContractAlias NVARCHAR(100) = NULL,
@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
DECLARE @Sql NVARCHAR(MAX)
SET @Sql =N'
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
With CTE_LeaseContractsFirst
AS
(
SELECT DISTINCT
C.Id AS Id
,C.Id AS ContractId
,C.SequenceNumber
,C.ContractType
,ISNull(CCD.OverallDPD,0) AS OverallDPD
,CurrencyCode.ISO AS ContractCurrency
,Opp.Number AS CreditApplication
,ProgramVendor.PartyName as ProgramVendor
,Party.PartyNumber as CustomerNumber
,Party.PartyName as CustomerName
,STUFF((SELECT distinct '',''+ VP.PromotionCode FROM ContractQualifiedPromotions CQP
JOIN ProgramPromotions VP ON CQP.ProgramPromotionId=VP.Id
WHERE CQP.ContractId= C.Id AND VP.IsBlindPromotion=0
FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,1,'''') PromotionCode
,ISNull(CCD.OverallDPD,0) AS DaysPastDue
,Party.DoingBusinessAs
,Lease.Id AS LeaseFinanceId
,Lease.BookingStatus AS Status
,Lease.ApprovalStatus  AS ApprovalStatus
,LeaseDetail.TermInMonths  AS Term
,LeaseDetail.PaymentFrequency AS PaymentFrequency
,LeaseDetail.NumberOfPayments AS TotalNumberofPayments
,LeaseDetail.NumberOfInceptionPayments AS NumberofInceptiomPayments
,(LeaseDetail.NumberOfPayments -  LeaseDetail.NumberOfInceptionPayments) AS RemainingNumberofPayments
,LeaseDetail.IsAdvance AS Advance
,(CASE WHEN LeaseDetail.IsRegularPaymentStream =1 THEN ''Regular''
WHEN LeaseDetail.IsRegularPaymentStream =0 THEN ''Irregular'' END) AS PaymentType
,LeaseDetail.CommencementDate AS CommencementDate
,LeaseDetail.MaturityDate AS MaturityDate
,LeaseDetail.FrequencyStartDate AS FirstPaymentDate
,CurrencyCode.ISO AS TotalCost_Currency
,LeaseDetail.InceptionPayment_Amount AS InceptionPayment_Amount
,LeaseDetail.InceptionPayment_Currency AS InceptionPayment_Currency
,LeaseDetail.DownPayment_Amount
,LeaseDetail.Rent_Amount AS RegularPaymentAmount_Amount
,LeaseDetail.Rent_Currency AS RegularPaymentAmount_Currency
,LeaseDetail.IsStepPayment AS IsStepPayment
,LeaseDetail.StepPeriod AS StepPeriod
,LeaseDetail.StepPercentage AS StepPercentage
,LeaseDetail.StubAdjustment AS StubAdjustment
,LeaseDetail.StepPaymentStartDate As StepPaymentStartDate
,NULL AS TerminationDate
,STUFF((SELECT distinct '','' + P.InvoiceNumber FROM PayableInvoices P WHERE C.Id= P.ContractId
FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,1,'''') InvoiceNumber
,C.ExternalReferenceNumber
,C.Alias as ContractAlias
FROM Contracts C
JOIN LeaseFinances Lease ON C.Id = Lease.ContractId AND Lease.IsCurrent = 1
JOIN LeaseFinanceDetails LeaseDetail ON Lease.Id = LeaseDetail.Id
join ContractOriginations ContractOrigination On Lease.ContractOriginationId = ContractOrigination.Id
join OriginationSourceTypes ON ContractOrigination.OriginationSourceTypeId = OriginationSourceTypes.Id
join Parties Party on Lease.CustomerId = Party.Id
JOIN Currencies Currency ON C.CurrencyId=Currency.Id
JOIN CurrencyCodes CurrencyCode ON Currency.CurrencyCodeId=CurrencyCode.Id
LEFT JOIN CreditApprovedStructures CPS ON C.CreditApprovedStructureId =CPS.Id
LEFT JOIN CreditProfiles CP ON CPS.CreditProfileId = CP.Id
LEFT  JOIN Opportunities Opp ON CP.OpportunityId = Opp.Id
LEFT JOIN Parties ProgramVendor on ContractOrigination.ProgramVendorOriginationSourceId = ProgramVendor.Id
LEFT JOIN ContractCollectionDetails CCD ON CCD.ContractId = C.Id
WHERE Lease.IsCurrent=1
AND  OriginationSourceTypes.Name = ''Vendor''
AND (
(@IsProgramVendor=1 AND
(ContractOrigination.OriginationSourceId = @CurrentVendorId OR
(ContractOrigination.OriginationSourceId IN (SELECT VendorId FROM ProgramsAssignedToAllVendors
WHERE IsAssigned = 1 AND ProgramVendorId =  @CurrentVendorId)
And ContractOrigination.ProgramVendorOriginationSourceId = @CurrentVendorId ))
OR
(@IsProgramVendor=0 AND (ContractOrigination.OriginationSourceId = @CurrentVendorId))
)
AND (@CommencementDateFrom IS NULL OR CAST(@CommencementDateFrom AS DATE) <= LeaseDetail.CommencementDate)
AND (@CommencementDateTo IS NULL OR CAST(@CommencementDateTo AS DATE)  >= LeaseDetail.CommencementDate)
AND (@MaturityDateFrom IS NULL OR CAST(@MaturityDateFrom AS DATE) <= LeaseDetail.MaturityDate)
AND (@MaturityDateTo IS NULL OR CAST(@MaturityDateTo AS DATE) >= LeaseDetail.MaturityDate)
AND (@ContractStatus  IS NULL OR Lease.BookingStatus LIKE REPLACE(@ContractStatus ,''*'',''%''))
AND (@ApprovalStatus  IS NULL OR Lease.ApprovalStatus LIKE REPLACE(@ApprovalStatus ,''*'',''%''))
AND (@Term  IS NULL OR LeaseDetail.TermInMonths LIKE REPLACE(@Term ,''*'',''%''))
AND Lease.BookingStatus NOT IN (''Inactive'')
AND	(@CustomerNumber IS NULL OR Party.PartyNumber LIKE REPLACE(@CustomerNumber,''*'',''%''))
AND (@CustomerName  IS NULL OR Party.PartyName LIKE REPLACE(@CustomerName ,''*'',''%''))
AND (@ContractId IS NULL OR C.Id = @ContractId)
AND (@ProgramVendor IS NULL OR ProgramVendor.PartyName LIKE REPLACE(@ProgramVendor,''*'',''%''))
AND (@SequenceNumber IS NULL OR C.SequenceNumber LIKE REPLACE(@SequenceNumber,''*'',''%''))
AND (@CreditApplication  IS NULL OR Opp.Number LIKE REPLACE(@CreditApplication ,''*'',''%''))
AND	(@ExternalReferenceNumber IS NULL OR C.ExternalReferenceNumber LIKE REPLACE(@ExternalReferenceNumber,''*'',''%''))
AND (C.Status NOT IN (''Cancelled'',''Inactive''))
AND (@ContractAlias IS NULL OR C.Alias LIKE REPLACE(@ContractAlias,''*'',''%''))
)),
CTE_LeaseAssetTotalCost
AS
(
SELECT
Lease.LeaseFinanceId
,SUM(LeaseAsset.NBV_Amount) AS TotalCost_Amount
FROM CTE_LeaseContractsFirst Lease
JOIN LeaseAssets LeaseAsset ON Lease.LeaseFinanceId=LeaseAsset.LeaseFinanceId
WHERE LeaseAsset.IsActive=1
GROUP BY Lease.LeaseFinanceId
),
CTE_LeaseAssets
AS
(
Select Lease.LeaseFinanceId,Asset.Id,
SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END
from CTE_LeaseContractsFirst Lease
JOIN LeaseAssets LeaseAsset on Lease.LeaseFinanceId = LeaseAsset.LeaseFinanceId
JOIN Assets Asset on LeaseAsset.AssetId = Asset.Id 
LEFT JOIN AssetSerialNumbers ASN on LeaseAsset.AssetId = ASN.AssetId   AND ASN.IsActive = 1
where LeaseAsset.IsActive = 1 AND (@SerialNumber IS NULL OR ASN.SerialNumber LIKE REPLACE(@SerialNumber, ''*'' , ''%''))
GROUP BY Lease.LeaseFinanceId,Asset.Id
),
CTE_LeaseContractFirstPaymentDate AS
(
SELECT
Lease.LeaseFinanceId
,MIN(DueDate) FirstPaymentDate
FROM CTE_LeaseContractsFirst Lease
JOIN LeasePaymentSchedules LPS ON Lease.LeaseFinanceId = LPS.LeaseFinanceDetailId
WHERE LPS.PaymentType = ''FixedTerm'' AND LPS.IsActive = 1
GROUP BY Lease.LeaseFinanceId
)
,CTE_LeaseContracts
AS
(
SELECT
Lease.ContractId AS Id
,Lease.ContractId
,Lease.SequenceNumber
,Lease.ContractType
,Lease.ContractCurrency
,Lease.CreditApplication
,Lease.ProgramVendor
,Lease.CustomerNumber
,Lease.CustomerName
,ISNULL(Lease.PromotionCode,'''') AS PromotionCode
,Lease.Status
,Lease.ApprovalStatus
,Lease.Term
,Lease.PaymentFrequency
,Lease.TotalNumberofPayments
,Lease.NumberofInceptiomPayments
,Lease.RemainingNumberofPayments
,Lease.Advance
,Lease.PaymentType
,''_'' AS BillingType
,Lease.CommencementDate
,Lease.MaturityDate
,FPD.FirstPaymentDate
,ISNULL(LeaseTotal.TotalCost_Amount,0) AS TotalCost_Amount
,Lease.TotalCost_Currency
,Lease.InceptionPayment_Amount
,Lease.InceptionPayment_Currency
,ISNULL((LeaseTotal.TotalCost_Amount- Lease.DownPayment_Amount),0.00) AS TotalFinancedAmount_Amount
,Lease.TotalCost_Currency AS TotalFinancedAmount_Currency
,Lease.RegularPaymentAmount_Amount
,Lease.IsStepPayment
,Lease.StepPeriod
,Lease.StepPercentage
,Lease.StubAdjustment
,Lease.StepPaymentStartDate
,Lease.RegularPaymentAmount_Currency
,0.00 AS ProgressPaymentCredit_Amount
,Lease.TotalCost_Currency AS ProgressPaymentCredit_Currency
,0.00 AS ProgressLoanBalance_Amount
,Lease.TotalCost_Currency AS ProgressLoanBalance_Currency
,Lease.DaysPastDue
,Lease.TerminationDate
,ISNULL(Lease.InvoiceNumber,'''') AS InvoiceNumber
,UDFs.UDF1Value
,UDFs.UDF2Value
,UDFs.UDF3Value
,UDFs.UDF4Value
,UDFs.UDF5Value
,UDFLabel.UDF1Label
,UDFLabel.UDF2Label
,UDFLabel.UDF3Label
,UDFLabel.UDF4Label
,UDFLabel.UDF5Label
,Lease.DoingBusinessAs
,Lease.ExternalReferenceNumber
,Lease.ContractAlias
FROM CTE_LeaseContractsFirst Lease
LEFT JOIN CTE_LeaseAssetTotalCost LeaseTotal ON Lease.LeaseFinanceId= LeaseTotal.LeaseFinanceId
LEFT JOIN CTE_LeaseContractFirstPaymentDate FPD ON FPD.LeaseFinanceId = Lease.LeaseFinanceId
LEFT JOIN CTE_LeaseAssets LeaseAsset on Lease.LeaseFinanceId = LeaseAsset.LeaseFinanceId
LEFT JOIN UDFs ON Lease.ContractId = UDFs.ContractId AND UDFs.IsActive = 1
LEFT JOIN UDFLabelForParties UL ON UL.EntityId = @CurrentVendorId AND  UL.EntityType = ''Vendor''
LEFT JOIN UDFLabelForPartyDetails UDFLabel ON UL.Id = UDFLabel.UDFLabelForPartyId AND UDFLabel.EntityType = ''Contract''
),
CTE_LoanContractsFirst
AS
(
SELECT DISTINCT
C.Id AS Id
,C.Id AS ContractId
,C.SequenceNumber
,C.ContractType
,ISNull(CCD.OverallDPD,0) AS OverallDPD
,CurrencyCode.ISO AS ContractCurrency
,Opp.Number AS CreditApplication
,ProgramVendor.PartyName as ProgramVendor
,Party.PartyNumber as CustomerNumber
,Party.PartyName as CustomerName
,STUFF((SELECT distinct '',''+ PP.PromotionCode FROM ContractQualifiedPromotions CQP
JOIN ProgramPromotions PP ON CQP.ProgramPromotionId=PP.Id
WHERE CQP.ContractId= C.Id AND PP.IsBlindPromotion=0
FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,1,'''') PromotionCode
,ISNull(CCD.OverallDPD,0) AS DaysPastDue
,Party.DoingBusinessAs
,Loan.Id AS LoanFinanceId
,(CASE WHEN Loan.Status =''Cancelled'' THEN ''Inactive''
WHEN Loan.Status !=''Cancelled'' THEN Loan.Status END) AS Status
,(CASE WHEN Loan.ApprovalStatus =''Rejected'' THEN ''Inactive''
WHEN Loan.ApprovalStatus !=''Rejected'' THEN Loan.ApprovalStatus END) AS ApprovalStatus
,Loan.Term  AS Term
,Loan.PaymentFrequency AS PaymentFrequency
,Loan.NumberOfPayments AS TotalNumberofPayments
,0 AS NumberofInceptiomPayments
,0 AS RemainingNumberofPayments
,NULL AS Advance
,'''' AS PaymentType
,Loan.InterimBillingType AS BillingType
,Loan.CommencementDate AS CommencementDate
,Loan.MaturityDate AS MaturityDate
,Loan.FirstPaymentDate  AS FirstPaymentDate
,Loan.LoanAmount_Amount AS TotalCost_Amount
,Loan.LoanAmount_Currency AS TotalCost_Currency
,0.00 AS InceptionPayment_Amount
,Loan.DownPayment_Currency AS InceptionPayment_Currency
,(Loan.LoanAmount_Amount- Loan.DownPayment_Amount ) AS TotalFinancedAmount_Amount
,Loan.LoanAmount_Currency AS TotalFinancedAmount_Currency
,NULL AS TerminationDate --Pending
,STUFF((SELECT distinct '',''+ P.InvoiceNumber FROM PayableInvoices P WHERE C.Id= P.ContractId
FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,1,'''') InvoiceNumber
,C.ExternalReferenceNumber
,C.Alias as ContractAlias
FROM Contracts C
JOIN LoanFinances Loan ON Loan.ContractId = C.Id AND Loan.IsCurrent = 1
join ContractOriginations ContractOrigination On Loan.ContractOriginationId = ContractOrigination.Id
join OriginationSourceTypes ON ContractOrigination.OriginationSourceTypeId = OriginationSourceTypes.Id
join Parties Party on Loan.CustomerId = Party.Id
JOIN Currencies Currency ON C.CurrencyId=Currency.Id
JOIN CurrencyCodes CurrencyCode ON Currency.CurrencyCodeId=CurrencyCode.Id
Left JOIN CreditApprovedStructures CPS ON C.CreditApprovedStructureId =CPS.Id
Left JOIN CreditProfiles CP ON CPS.CreditProfileId = CP.Id
left  JOIN Opportunities Opp ON CP.OpportunityId = Opp.Id
Left join Parties ProgramVendor on ContractOrigination.ProgramVendorOriginationSourceId = ProgramVendor.Id
LEFT JOIN ContractCollectionDetails CCD ON CCD.ContractId = C.Id
WHERE Loan.IsCurrent=1
AND  OriginationSourceTypes.Name = ''Vendor''
AND (
(@IsProgramVendor=1 AND (ContractOrigination.OriginationSourceId = @CurrentVendorId OR
(ContractOrigination.OriginationSourceId IN (SELECT VendorId FROM ProgramsAssignedToAllVendors
WHERE IsAssigned = 1 AND ProgramVendorId =  @CurrentVendorId)
AND ContractOrigination.ProgramVendorOriginationSourceId = @CurrentVendorId))
OR
(@IsProgramVendor=0 AND (ContractOrigination.OriginationSourceId = @CurrentVendorId))
)
AND (@CommencementDateFrom IS NULL OR CAST(@CommencementDateFrom AS DATE) <= Loan.CommencementDate)
AND (@CommencementDateTo IS NULL OR CAST(@CommencementDateTo AS DATE)  >= Loan.CommencementDate)
AND (@MaturityDateFrom IS NULL OR CAST(@MaturityDateFrom AS DATE)  <= Loan.MaturityDate)
AND (@MaturityDateTo IS NULL OR CAST(@MaturityDateTo AS DATE)  >= Loan.MaturityDate)
AND (@ContractStatus  IS NULL OR (@ContractStatus=''Inactive'' AND Loan.Status=''Cancelled'') OR  Loan.Status LIKE REPLACE(@ContractStatus ,''*'',''%''))
AND (@ApprovalStatus  IS NULL OR (@ApprovalStatus =''Inactive'' AND Loan.ApprovalStatus =''Rejected'') OR Loan.ApprovalStatus LIKE REPLACE(@ContractStatus ,''*'',''%''))
AND (@Term  IS NULL OR Loan.Term  LIKE REPLACE(@Term ,''*'',''%''))
AND Loan.Status NOT IN (''Cancelled'')
AND	(@CustomerNumber IS NULL OR Party.PartyNumber LIKE REPLACE(@CustomerNumber,''*'',''%''))
AND (@CustomerName  IS NULL OR Party.PartyName LIKE REPLACE(@CustomerName ,''*'',''%''))
AND (@ContractId IS NULL OR C.Id = @ContractId)
AND (@ProgramVendor IS NULL OR ProgramVendor.PartyName LIKE REPLACE(@ProgramVendor,''*'',''%''))
AND (@SequenceNumber IS NULL OR C.SequenceNumber LIKE REPLACE(@SequenceNumber,''*'',''%''))
AND (@CreditApplication  IS NULL OR Opp.Number LIKE REPLACE(@CreditApplication ,''*'',''%''))
AND	(@ExternalReferenceNumber IS NULL OR C.ExternalReferenceNumber LIKE REPLACE(@ExternalReferenceNumber,''*'',''%''))
AND (C.Status NOT IN (''Cancelled'',''Inactive''))
AND (@ContractAlias IS NULL OR C.Alias LIKE REPLACE(@ContractAlias,''*'',''%''))
)),
CTE_ProgressLoanContracts
AS
(
SELECT
LoanFinance.LoanFinanceId
,SUM((ProgressFunding.Amount_Amount* PayableInvoice.InitialExchangeRate)-(ProgressFunding.CreditBalance_Amount * PayableInvoice.InitialExchangeRate)) AS ProgressPaymentCredit_Amount
,SUM(ProgressFunding.CreditBalance_Amount * PayableInvoice.InitialExchangeRate) AS ProgressLoanBalance_Amount
FROM CTE_LoanContractsFirst LoanFinance
JOIN LoanFundings LoanFunding ON LoanFinance.LoanFinanceId=LoanFunding.LoanFinanceId
JOIN PayableInvoices PayableInvoice ON LoanFunding.FundingId=PayableInvoice.Id
JOIN PayableInvoiceOtherCosts ProgressFunding ON PayableInvoice.Id=ProgressFunding.PayableInvoiceId
WHERE LoanFunding.IsActive=1
AND ProgressFunding.IsActive=1
AND ProgressFunding.AllocationMethod=''LoanDisbursement''
AND LoanFunding.IsApproved=1
GROUP BY LoanFinance.LoanFinanceId
),
CTE_LoanContractFirstPaymentDate AS
(
SELECT
LPS.LoanFinanceId,
MIN(DueDate) FirstPaymentDate
FROM CTE_LoanContractsFirst Loan
JOIN LoanPaymentSchedules LPS ON Loan.LoanFinanceId = LPS.LoanFinanceId
WHERE LPS.PaymentType = ''FixedTerm''  AND LPS.IsActive = 1
GROUP BY
LPS.LoanFinanceId
)
,CTE_CollateralAssets
AS
(
Select Loan.LoanFinanceId,Asset.Id,
SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END
from CTE_LoanContractsFirst Loan
JOIN CollateralAssets CollateralAsset on Loan.LoanFinanceId = CollateralAsset.LoanFinanceId
JOIN Assets Asset on CollateralAsset.AssetId = Asset.Id 
LEFT JOIN AssetSerialNumbers ASN on CollateralAsset.AssetId = ASN.AssetId   AND ASN.IsActive = 1
where CollateralAsset.IsActive = 1 AND (@SerialNumber IS NULL OR ASN.SerialNumber LIKE REPLACE(@SerialNumber, ''*'' , ''%''))
Group By Loan.LoanFinanceId,Asset.Id
)
,CTE_LoanContracts
AS
( SELECT
Loan.ContractId AS Id
,Loan.ContractId
,Loan.SequenceNumber
,Loan.ContractType
,Loan.ContractCurrency
,Loan.CreditApplication
,Loan.ProgramVendor
,Loan.CustomerNumber
,Loan.CustomerName
,ISNULL(Loan.PromotionCode,'''') AS PromotionCode
,Loan.Status AS Status
,Loan.ApprovalStatus
,Loan.Term  AS Term
,Loan.PaymentFrequency
,Loan.TotalNumberofPayments
,Loan.NumberofInceptiomPayments
,Loan.RemainingNumberofPayments
,Loan.Advance
,Loan.PaymentType
,Loan.BillingType
,Loan.CommencementDate
,Loan.MaturityDate
,CASE WHEN Loan.ContractType = ''Loan'' THEN LoanFP.FirstPaymentDate ELSE Loan.FirstPaymentDate END AS FirstPaymentDate
,Loan.TotalCost_Amount
,Loan.TotalCost_Currency
,Loan.InceptionPayment_Amount
,Loan.InceptionPayment_Currency
,Loan.TotalFinancedAmount_Amount
,Loan.TotalFinancedAmount_Currency
,0.00 AS RegularPaymentAmount_Amount
,''false'' as IsStepPayment
,0 as StepPeriod
,0 As StepPercentage
,''BeginningOfTerm'' as StubAdjustment
,''01-01-01'' as StepPaymentStartDate
,Loan.ContractCurrency AS RegularPaymentAmount_Currency
,ISNULL(PPC.ProgressPaymentCredit_Amount,0.00) AS ProgressPaymentCredit_Amount
,Loan.ContractCurrency AS ProgressPaymentCredit_Currency
,ISNULL(PPC.ProgressLoanBalance_Amount,0.00) AS ProgressLoanBalance_Amount
,Loan.ContractCurrency AS ProgressLoanBalance_Currency
,Loan.DaysPastDue
,Loan.TerminationDate --Pending
,ISNULL(Loan.InvoiceNumber,'''') AS InvoiceNumber
,UDFs.UDF1Value
,UDFs.UDF2Value
,UDFs.UDF3Value
,UDFs.UDF4Value
,UDFs.UDF5Value
,UDFLabel.UDF1Label
,UDFLabel.UDF2Label
,UDFLabel.UDF3Label
,UDFLabel.UDF4Label
,UDFLabel.UDF5Label
,Loan.DoingBusinessAs
,Loan.ExternalReferenceNumber
,Loan.ContractAlias
FROM CTE_LoanContractsFirst Loan
LEFT JOIN CTE_LoanContractFirstPaymentDate LoanFP ON Loan.LoanFinanceId = LoanFP.LoanFinanceId
LEFT JOIN CTE_ProgressLoanContracts PPC ON Loan.LoanFinanceId=PPC.LoanFinanceId
LEFT JOIN CTE_CollateralAssets CollateralAsset on Loan.LoanFinanceId = CollateralAsset.LoanFinanceId
LEFT JOIN UDFs ON Loan.ContractId = UDFs.ContractId AND UDFs.IsActive = 1
LEFT JOIN UDFLabelForParties UL ON UL.EntityId = @CurrentVendorId AND  UL.EntityType = ''Vendor''
LEFT JOIN UDFLabelForPartyDetails UDFLabel ON UL.Id = UDFLabel.UDFLabelForPartyId AND UDFLabel.EntityType = ''Contract''
),
CTE_LeaseAssetTotalCostForThirdParty
AS
(
SELECT
LF.Id
,SUM(LeaseAsset.NBV_Amount) AS TotalCost_Amount
FROM Contracts C
JOIN LeaseFinances LF on C.Id=LF.ContractId
JOIN LeaseFinanceDetails LeaseDetail ON LF.Id = LeaseDetail.Id
JOIN LeaseAssets LeaseAsset ON LF.Id=LeaseAsset.LeaseFinanceId
JOIN Customers Cust  ON LF.CustomerId = Cust.Id
JOIN Parties CustParty ON Cust.Id= CustParty.Id
JOIN Vendors V on @CurrentVendorId=V.Id
WHERE LeaseAsset.IsActive=1 AND
LF.IsCurrent=1
AND	(@CustomerNumber IS NULL OR CustParty.PartyNumber LIKE REPLACE(@CustomerNumber,''*'',''%''))
AND (@CustomerName  IS NULL OR CustParty.PartyName LIKE REPLACE(@CustomerName ,''*'',''%''))
AND (@ContractId IS NULL OR C.Id = @ContractId)
AND (@SequenceNumber IS NULL OR C.SequenceNumber LIKE REPLACE(@SequenceNumber,''*'',''%''))
AND	(@ExternalReferenceNumber IS NULL OR C.ExternalReferenceNumber LIKE REPLACE(@ExternalReferenceNumber,''*'',''%''))
AND (C.Status NOT IN (''Cancelled'',''Inactive''))
AND (@ContractAlias IS NULL OR C.Alias LIKE REPLACE(@ContractAlias,''*'',''%''))
AND (@CreditApplication  IS NULL)
GROUP BY LF.Id
),
CTE_LeaseThirdPartyContracts
AS
(
SELECT
C.Id AS ID
,C.Id AS ContractId
,C.SequenceNumber
,C.ContractType
,CurrencyCode.ISO AS ContractCurrency
,Null ''CreditApplication''
,CASE WHEN V.IsVendorProgram=1 THEN CustParty.PartyName else NULL END ''ProgramVendor''
,CustParty.PartyNumber AS CustomerNumber
,CustParty.PartyName AS CustomerName
,'''' PromotionCode
,LF.BookingStatus AS Status
,LF.ApprovalStatus  AS ApprovalStatus
,LeaseDetail.TermInMonths  AS Term
,LeaseDetail.PaymentFrequency AS PaymentFrequency
,LeaseDetail.NumberOfPayments AS TotalNumberofPayments
,LeaseDetail.NumberOfInceptionPayments AS NumberofInceptiomPayments
,(LeaseDetail.NumberOfPayments -  LeaseDetail.NumberOfInceptionPayments) AS RemainingNumberofPayments
,LeaseDetail.IsAdvance AS Advance
,(CASE WHEN LeaseDetail.IsRegularPaymentStream =1 THEN ''Regular''
WHEN LeaseDetail.IsRegularPaymentStream =0 THEN ''Irregular'' END) AS PaymentType
,''_'' AS BillingType
,LeaseDetail.CommencementDate AS CommencementDate
,LeaseDetail.MaturityDate AS MaturityDate
,LeaseDetail.FrequencyStartDate AS FirstPaymentDate
,ISNULL(LeaseTotal.TotalCost_Amount,0) AS TotalCost_Amount
,CurrencyCode.ISO AS TotalCost_Currency
,LeaseDetail.InceptionPayment_Amount AS InceptionPayment_Amount
,LeaseDetail.InceptionPayment_Currency AS InceptionPayment_Currency
,ISNULL((LeaseTotal.TotalCost_Amount- LeaseDetail.DownPayment_Amount),0.00) AS TotalFinancedAmount_Amount
,CurrencyCode.ISO AS TotalFinancedAmount_Currency
,LeaseDetail.Rent_Amount AS RegularPaymentAmount_Amount
,LeaseDetail.IsStepPayment AS IsStepPayment
,LeaseDetail.StepPeriod AS StepPeriod
,LeaseDetail.StepPercentage AS StepPercentage
,LeaseDetail.StubAdjustment AS StubAdjustment
,LeaseDetail.StepPaymentStartDate As StepPaymentStartDate
,LeaseDetail.Rent_Currency AS RegularPaymentAmount_Currency
,0.00 AS ProgressPaymentCredit_Amount
,CurrencyCode.ISO AS ProgressPaymentCredit_Currency
,0.00 AS ProgressLoanBalance_Amount
,CurrencyCode.ISO AS ProgressLoanBalance_Currency
,ISNull(CCD.OverallDPD,0) AS DaysPastDue
,NULL AS TerminationDate
,STUFF((SELECT distinct '','' + P.InvoiceNumber FROM PayableInvoices P WHERE C.Id= P.ContractId
FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,1,'''') InvoiceNumber
,UDFs.UDF1Value
,UDFs.UDF2Value
,UDFs.UDF3Value
,UDFs.UDF4Value
,UDFs.UDF5Value
,UDFLabel.UDF1Label
,UDFLabel.UDF2Label
,UDFLabel.UDF3Label
,UDFLabel.UDF4Label
,UDFLabel.UDF5Label
,CustParty.DoingBusinessAs
,C.ExternalReferenceNumber
,C.Alias AS ContractAlias
FROM  Contracts C
JOIN LeaseFinances LF on C.Id=LF.ContractId
JOIN CTE_LeaseAssetTotalCostForThirdParty LeaseTotal ON LF.Id= LeaseTotal.Id
JOIN LeaseFinanceDetails LeaseDetail ON LF.Id = LeaseDetail.Id
JOIN Customers Cust  ON LF.CustomerId = Cust.Id
JOIN Parties CustParty ON Cust.Id= CustParty.Id
JOIN Vendors V on @CurrentVendorId=V.Id
JOIN Currencies Currency ON C.CurrencyId=Currency.Id
JOIN CurrencyCodes CurrencyCode ON Currency.CurrencyCodeId=CurrencyCode.Id
JOIN ContractThirdPartyRelationships ContractTP ON C.Id= ContractTP.ContractId
JOIN CustomerThirdPartyRelationships CustomerTP ON ContractTP.ThirdPartyRelationshipId = CustomerTP.Id
LEFT JOIN UDFs ON LF.ContractId = UDFs.ContractId AND UDFs.IsActive = 1
LEFT JOIN UDFLabelForParties UL ON UL.EntityId = @CurrentVendorId AND  UL.EntityType = ''Vendor''
LEFT JOIN UDFLabelForPartyDetails UDFLabel ON UL.Id = UDFLabel.UDFLabelForPartyId AND UDFLabel.EntityType = ''Contract''
LEFT JOIN ContractCollectionDetails CCD ON CCD.ContractId = C.Id
WHERE CustomerTP.ThirdPartyId= @CurrentVendorId AND ContractTP.IsActive=1 AND CustomerTP.IsActive = 1 AND C.CreditApprovedStructureId is null
AND LF.IsCurrent=1
AND	(@CustomerNumber IS NULL OR CustParty.PartyNumber LIKE REPLACE(@CustomerNumber,''*'',''%''))
AND (@CustomerName  IS NULL OR CustParty.PartyName LIKE REPLACE(@CustomerName ,''*'',''%''))
AND (@ContractId IS NULL OR C.Id = @ContractId)
AND (@SequenceNumber IS NULL OR C.SequenceNumber LIKE REPLACE(@SequenceNumber,''*'',''%''))
AND	(@ExternalReferenceNumber IS NULL OR C.ExternalReferenceNumber LIKE REPLACE(@ExternalReferenceNumber,''*'',''%''))
AND (C.Status NOT IN (''Cancelled'',''Inactive''))
AND (@ContractAlias IS NULL OR C.Alias LIKE REPLACE(@ContractAlias,''*'',''%''))
AND (@CreditApplication  IS NULL)
),
CTE_ProgressLoanContractsForThirdParty
AS
(
SELECT
LF.Id
,SUM((ProgressFunding.Amount_Amount* PayableInvoice.InitialExchangeRate)-(ProgressFunding.CreditBalance_Amount * PayableInvoice.InitialExchangeRate)) AS ProgressPaymentCredit_Amount
,SUM(ProgressFunding.CreditBalance_Amount * PayableInvoice.InitialExchangeRate) AS ProgressLoanBalance_Amount
FROM Contracts C
JOIN LoanFinances LF ON C.Id=LF.ContractId
JOIN LoanFundings LoanFunding ON LF.Id=LoanFunding.LoanFinanceId
JOIN PayableInvoices PayableInvoice ON LoanFunding.FundingId=PayableInvoice.Id
JOIN PayableInvoiceOtherCosts ProgressFunding ON PayableInvoice.Id=ProgressFunding.PayableInvoiceId
WHERE LoanFunding.IsActive=1
AND ProgressFunding.IsActive=1
AND ProgressFunding.AllocationMethod=''LoanDisbursement''
AND LoanFunding.IsApproved=1
GROUP BY LF.Id
),
CTE_LoanThirdPartyContracts
AS
(
SELECT
C.Id AS ID
,C.Id AS ContractId
,C.SequenceNumber
,C.ContractType
,CurrencyCode.ISO AS ContractCurrency
,Null ''CreditApplication''
,CASE WHEN V.IsVendorProgram=1 THEN CustParty.PartyName else NULL END ''ProgramVendor''
,CustParty.PartyNumber AS CustomerNumber
,CustParty.PartyName AS CustomerName
,'''' PromotionCode
,(CASE WHEN LF.Status =''Cancelled'' THEN ''Inactive''
WHEN LF.Status !=''Cancelled'' THEN LF.Status END) AS Status
,(CASE WHEN LF.ApprovalStatus =''Rejected'' THEN ''Inactive''
WHEN LF.ApprovalStatus !=''Rejected'' THEN LF.ApprovalStatus END) AS ApprovalStatus
,LF.Term  AS Term
,LF.PaymentFrequency AS PaymentFrequency
,LF.NumberOfPayments AS TotalNumberofPayments
,0 AS NumberofInceptiomPayments
,0 AS RemainingNumberofPayments
,NULL AS Advance
,'''' AS PaymentType
,LF.InterimBillingType AS BillingType
,LF.CommencementDate AS CommencementDate
,LF.MaturityDate AS MaturityDate
,CASE WHEN C.ContractType = ''Loan'' THEN LF.FirstPaymentDate ELSE LF.FirstPaymentDate END AS FirstPaymentDate
,LF.LoanAmount_Amount AS TotalCost_Amount
,LF.LoanAmount_Currency AS TotalCost_Currency
,0.00 AS InceptionPayment_Amount
,LF.DownPayment_Currency AS InceptionPayment_Currency
,(LF.LoanAmount_Amount- LF.DownPayment_Amount ) AS TotalFinancedAmount_Amount
,LF.LoanAmount_Currency AS TotalFinancedAmount_Currency
,0.00 AS RegularPaymentAmount_Amount
,''false'' as IsStepPayment
,0 as StepPeriod
,0 As StepPercentage
,''BeginningOfTerm'' as StubAdjustment
,''01-01-01'' as StepPaymentStartDate
,CurrencyCode.ISO AS RegularPaymentAmount_Currency
,ISNULL(PPC.ProgressPaymentCredit_Amount,0.00) AS ProgressPaymentCredit_Amount
,CurrencyCode.ISO AS ProgressPaymentCredit_Currency
,ISNULL(PPC.ProgressLoanBalance_Amount,0.00) AS ProgressLoanBalance_Amount
,CurrencyCode.ISO AS ProgressLoanBalance_Currency
,ISNull(CCD.OverallDPD,0) AS DaysPastDue
,NULL AS TerminationDate
,STUFF((SELECT distinct '','' + P.InvoiceNumber FROM PayableInvoices P WHERE C.Id= P.ContractId
FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,1,'''') InvoiceNumber
,UDFs.UDF1Value
,UDFs.UDF2Value
,UDFs.UDF3Value
,UDFs.UDF4Value
,UDFs.UDF5Value
,UDFLabel.UDF1Label
,UDFLabel.UDF2Label
,UDFLabel.UDF3Label
,UDFLabel.UDF4Label
,UDFLabel.UDF5Label
,CustParty.DoingBusinessAs
,C.ExternalReferenceNumber
,C.Alias AS ContractAlias
FROM  Contracts C
JOIN LoanFinances LF on C.Id=LF.ContractId
JOIN Customers Cust  ON LF.CustomerId = Cust.Id
JOIN Parties CustParty ON Cust.Id= CustParty.Id
JOIN Vendors V on @CurrentVendorId=V.Id
LEFT JOIN CTE_ProgressLoanContractsForThirdParty PPC ON LF.Id=PPC.Id
JOIN Currencies Currency ON C.CurrencyId=Currency.Id
JOIN CurrencyCodes CurrencyCode ON Currency.CurrencyCodeId=CurrencyCode.Id
JOIN ContractThirdPartyRelationships ContractTP ON C.Id= ContractTP.ContractId
JOIN CustomerThirdPartyRelationships CustomerTP ON ContractTP.ThirdPartyRelationshipId = CustomerTP.Id
LEFT JOIN UDFs ON LF.ContractId = UDFs.ContractId AND UDFs.IsActive = 1
LEFT JOIN UDFLabelForParties UL ON UL.EntityId = @CurrentVendorId AND  UL.EntityType = ''Vendor''
LEFT JOIN UDFLabelForPartyDetails UDFLabel ON UL.Id = UDFLabel.UDFLabelForPartyId AND UDFLabel.EntityType = ''Contract''
LEFT JOIN ContractCollectionDetails CCD ON CCD.ContractId = C.Id
WHERE CustomerTP.ThirdPartyId= @CurrentVendorId AND ContractTP.IsActive=1 AND CustomerTP.IsActive = 1 AND C.CreditApprovedStructureId is null
AND LF.IsCurrent=1
AND	(@CustomerNumber IS NULL OR CustParty.PartyNumber LIKE REPLACE(@CustomerNumber,''*'',''%''))
AND (@CustomerName  IS NULL OR CustParty.PartyName LIKE REPLACE(@CustomerName ,''*'',''%''))
AND (@ContractId IS NULL OR C.Id = @ContractId)
AND (@SequenceNumber IS NULL OR C.SequenceNumber LIKE REPLACE(@SequenceNumber,''*'',''%''))
AND	(@ExternalReferenceNumber IS NULL OR C.ExternalReferenceNumber LIKE REPLACE(@ExternalReferenceNumber,''*'',''%''))
AND (C.Status NOT IN (''Cancelled'',''Inactive''))
AND (@ContractAlias IS NULL OR C.Alias LIKE REPLACE(@ContractAlias,''*'',''%''))
AND (@CreditApplication  IS NULL)
)
SELECT * FROM CTE_LeaseContracts
UNION
SELECT * FROM CTE_LoanContracts
UNION
SELECT * FROM CTE_LeaseThirdPartyContracts
UNION
SELECT * FROM CTE_LoanThirdPartyContracts'
EXEC sp_executesql @Sql,N'
@IsProgramVendor BIT,
@CurrentVendorId BIGINT,
@ProgramVendor NVARCHAR(100),
@ContractId BIGINT=NULL,
@CustomerNumber NVARCHAR(100)=NULL,
@CustomerName NVARCHAR(100)=NULL,
@SequenceNumber NVARCHAR(100)=NULL,
@CreditApplication NVARCHAR(100)=NULL,
@ContractStatus NVARCHAR(100)=NULL,
@ApprovalStatus NVARCHAR(100)=NULL,
@CommencementDateFrom DATETIMEOFFSET=NULL,
@CommencementDateTo DATETIMEOFFSET=NULL,
@Term DECIMAL(10,6)=NULL,
@MaturityDateFrom DATETIMEOFFSET=NULL,
@MaturityDateTo  DATETIMEOFFSET=NULL,
@SerialNumber nvarchar(100) = NULL,
@ExternalReferenceNumber nvarchar(100) = NULL,
@ContractAlias NVARCHAR(100) = NULL,
@AssetMultipleSerialNumberType NVARCHAR(10)'
,@IsProgramVendor
,@CurrentVendorId
,@ProgramVendor
,@ContractId
,@CustomerNumber
,@CustomerName
,@SequenceNumber
,@CreditApplication
,@ContractStatus
,@ApprovalStatus
,@CommencementDateFrom
,@CommencementDateTo
,@Term
,@MaturityDateFrom
,@MaturityDateTo
,@SerialNumber
,@ExternalReferenceNumber
,@ContractAlias
,@AssetMultipleSerialNumberType

GO
