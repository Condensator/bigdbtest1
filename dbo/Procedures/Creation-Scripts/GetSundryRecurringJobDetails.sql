SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Proc [dbo].[GetSundryRecurringJobDetails]
(
@ProcessThroughDate datetime ,
@IsInvoiceSensitive bit ,
@ValidLegalEntityIds nvarchar(MAX) ,
@EntityType nvarchar(40) ,
@EntityId bigint NULL
)
AS
BEGIN
-- Sundry Recurring Details
Select
SR.Id SundryRecurringId,
SR.ContractId,
SR.CustomerId,
SR.TerminationDate,
(CASE WHEN @IsInvoiceSensitive = 1 THEN
(CASE WHEN SR.ContractId Is Not Null AND CB.InvoiceLeaddays != 0 THEN CB.InvoiceLeaddays
ELSE CU.InvoiceLeadDays END)
ELSE 0 END) InvoiceLeadDays,
SR.BillPastEndDate,
PR.PartyId FunderId,
CASE WHEN C.SyndicationType Is Not Null ANd C.SyndicationType <> 'None' And C.SyndicationType <> '_' THEN CAST(1 As bit) ELSE CAST(0 As bit ) END IsSyndicated
INTO #SundryRecurrings
From SundryRecurrings SR
Join dbo.ConvertCSVToBigIntTable(@ValidLegalEntityIds,',') LE ON SR.LegalEntityId = LE.ID
Left Join PartyRemitToes PR ON SR.ReceivableRemitToId = PR.RemitToId
Left Join Customers CU ON SR.CustomerId = CU.Id
Left Join Contracts C ON SR.ContractId = C.Id
Left Join ContractBillings CB On C.Id = CB.Id
Where SR.IsActive = 1 AND sR.Status = 'Approved'
AND ((@EntityType = 'Lease' AND (@EntityId IS NULL OR C.Id = @EntityId))
OR (@EntityType = 'Loan' AND (@EntityId IS NULL OR C.Id = @EntityId))
OR (@EntityType = 'Customer' AND (@EntityId IS NULL OR CU.Id = @EntityId)));
With CTE As
(
Select
SR.SundryRecurringId,
SR.ContractId,
SR.CustomerId,
CASE WHEN SR.TerminationDate IS NOT NULL And SR.TerminationDate <= DATEADD(DAY, SR.InvoiceLeadDays, @ProcessThroughDate) THEN SR.TerminationDate
ELSE DATEADD(DAY, SR.InvoiceLeadDays,@ProcessThroughDate) END ProcessThruDate,
R.Id ReceivableId,
SR.BillPastEndDate,
SRP.DueDate,
SR.FunderId,
SR.IsSyndicated
From #SundryRecurrings SR
Join SundryRecurringPaymentSchedules SRP On SR.SundryRecurringId = SRP.SundryRecurringId And SRP.IsActive = 1
Left Join Receivables R On SRP.ReceivableId = R.Id And R.IsActive = 1
)
Select Distinct
SR.ProcessThruDate ComputedProcessThroughDate,
SR.SundryRecurringId,
SR.ContractId,
SR.FunderId,
SR.IsSyndicated,
COALESCE(LFD.IsAdvance,LoanF.IsAdvance,CAST(0 As bit)) IsAdvance
INTO #ValidSundryRecurrings
From CTE SR
Left Join LeaseFinances LeaseF On SR.ContractId = LeaseF.ContractId And LeaseF.IsCurrent = 1
Left Join LeaseFinanceDetails LFD On LeaseF.Id = LFD.ID
Left Join LoanFinances LoanF On SR.ContractId = LoanF.ContractId And LoanF.IsCurrent =1
Where BillPastEndDate = 1 OR (SR.DueDate <= SR.ProcessThruDate And SR.ReceivableId Is NULL)
Select * From #ValidSundryRecurrings
-- Alternate Billing Details
Select *
FROM
(Select
EffectiveDate,
BillingCurrencyId,
BillingExchangeRate,
SundryRecurringId
From #ValidSundryRecurrings SR
Inner Join LeaseFinances LF on SR.ContractId = LF.ContractId And LF.IsCurrent =1 And LF.IsBillInAlternateCurrency =1
Inner Join LeaseFinanceAlternateCurrencyDetails LFAC on LF.Id = LFAC.LeaseFinanceId And LFAC.IsActive = 1
Where SR.ContractId IS NOT NULL
UNION
Select
EffectiveDate,
BillingCurrencyId,
BillingExchangeRate,
SundryRecurringId
From #ValidSundryRecurrings SR
Inner Join LoanFinances LF on SR.ContractId = LF.ContractId And LF.IsCurrent =1 And LF.IsBillInAlternateCurrency =1
Inner Join LoanFinanceAlternateCurrencyDetails LFAC on LF.Id = LFAC.LoanFinanceId And LFAC.IsActive = 1
Where SR.ContractId IS NOT NULL) T
-- Lease Over Term Details
Select
DueDate,
SundryRecurringId
From #ValidSundryRecurrings SR
Inner Join LeaseFinances LF on SR.ContractId = LF.ContractId And LF.IsCurrent =1
Inner Join LeasePaymentSchedules LPS on LF.Id = LPS.LeaseFinanceDetailId And LPS.IsActive = 1 And LPS.PaymentType = 'OTP'
-- Servicing Details
Select
RFTS.EffectiveDate,
SundryRecurringId,
IsServiced,
IsCollected,
IsPrivateLabel,
RFTS.Id ServicingDetailId
INTO #ServicingDetails
From #ValidSundryRecurrings SR
Inner Join ReceivableForTransfers RFT on SR.ContractId = RFt.ContractId And SR.IsSyndicated = 1
Inner Join ReceivableForTransferServicings RFTS on RFT.Id = RFTS.ReceivableForTransferId And RFTS.IsActive =1
Insert Into #ServicingDetails
Select
LFSD.EffectiveDate,
SR.SundryRecurringId,
LFSD.IsServiced,
LFSD.IsCollected,
LFSD.IsPrivateLabel,
LFSD.Id ServicingDetailId
From #ValidSundryRecurrings SR
Inner Join LeaseFinances LF on SR.ContractId = LF.ContractId And SR.IsSyndicated = 1 And LF.IsCurrent =1
Inner Join LeaseSyndicationServicingDetails LFSD on LF.Id = LFSD.LeaseSyndicationId And LFSD.IsActive =1
Left Join #ServicingDetails SD on SR.SundryRecurringId = SD.SundryRecurringId
Where SD.SundryRecurringId IS NULL
Insert Into #ServicingDetails
Select
LFSD.EffectiveDate,
SR.SundryRecurringId,
LFSD.IsServiced,
LFSD.IsCollected,
LFSD.IsPrivateLabel,
LFSD.Id ServicingDetailId
From #ValidSundryRecurrings SR
Inner Join LoanFinances LF on SR.ContractId = LF.ContractId And SR.IsSyndicated = 1 And LF.IsCurrent =1
Inner Join LoanSyndicationServicingDetails LFSD on LF.Id = LFSD.LoanSyndicationId And LFSD.IsActive =1
Left Join #ServicingDetails SD on SR.SundryRecurringId = SD.SundryRecurringId
Where SD.SundryRecurringId IS NULL
Insert Into #ServicingDetails
Select
SD.EffectiveDate,
SR.SundryRecurringId,
SD.IsServiced,
SD.IsCollected,
SD.IsPrivateLabel,
SD.Id ServicingDetailId
From #ValidSundryRecurrings SR
Inner Join LoanFinances LF on SR.ContractId = LF.ContractId And LF.IsCurrent =1 And SR.IsSyndicated = 0
Inner Join ContractOriginationServicingDetails COSD on LF.ContractOriginationId = COSD.ContractOriginationId
Inner Join ServicingDetails SD on SD.Id = COSD.ServicingDetailId And SD.IsActive =1
Insert Into #ServicingDetails
Select
SD.EffectiveDate,
SR.SundryRecurringId,
SD.IsServiced,
SD.IsCollected,
SD.IsPrivateLabel,
SD.Id ServicingDetailId
From #ValidSundryRecurrings SR
Inner Join LeaseFinances LF on SR.ContractId = LF.ContractId And LF.IsCurrent =1 And SR.IsSyndicated = 0
Inner Join ContractOriginationServicingDetails COSD on LF.ContractOriginationId = COSD.ContractOriginationId
Inner Join ServicingDetails SD on SD.Id = COSD.ServicingDetailId And SD.IsActive =1
Select * From #ServicingDetails
END

GO
