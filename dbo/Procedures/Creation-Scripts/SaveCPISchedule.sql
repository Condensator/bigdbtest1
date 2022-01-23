SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPISchedule]
(
 @val [dbo].[CPISchedule] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[CPISchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdminFee_Amount]=S.[AdminFee_Amount],[AdminFee_Currency]=S.[AdminFee_Currency],[ApplyByAsset]=S.[ApplyByAsset],[BaseAllowance]=S.[BaseAllowance],[BaseAmount_Amount]=S.[BaseAmount_Amount],[BaseAmount_Currency]=S.[BaseAmount_Currency],[BaseChargeGeneratedTillDate]=S.[BaseChargeGeneratedTillDate],[BaseRate]=S.[BaseRate],[BaseRateCalculated]=S.[BaseRateCalculated],[BaseStepPaymentEffectiveDate]=S.[BaseStepPaymentEffectiveDate],[BaseStepPayments]=S.[BaseStepPayments],[BaseStepPercentage]=S.[BaseStepPercentage],[BaseStepPeriod]=S.[BaseStepPeriod],[BeginDate]=S.[BeginDate],[InvoiceAmendmentType]=S.[InvoiceAmendmentType],[IsActive]=S.[IsActive],[MeterTypeId]=S.[MeterTypeId],[NextStartDate]=S.[NextStartDate],[Number]=S.[Number],[OverageChargeGeneratedTillDate]=S.[OverageChargeGeneratedTillDate],[OverageStepPaymentEffectiveDate]=S.[OverageStepPaymentEffectiveDate],[OverageStepPayments]=S.[OverageStepPayments],[OverageStepPercentage]=S.[OverageStepPercentage],[OverageStepPeriod]=S.[OverageStepPeriod],[OverageTier]=S.[OverageTier],[TaxLocationId]=S.[TaxLocationId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdminFee_Amount],[AdminFee_Currency],[ApplyByAsset],[BaseAllowance],[BaseAmount_Amount],[BaseAmount_Currency],[BaseChargeGeneratedTillDate],[BaseRate],[BaseRateCalculated],[BaseStepPaymentEffectiveDate],[BaseStepPayments],[BaseStepPercentage],[BaseStepPeriod],[BeginDate],[CPIContractId],[CreatedById],[CreatedTime],[InvoiceAmendmentType],[IsActive],[MeterTypeId],[NextStartDate],[Number],[OverageChargeGeneratedTillDate],[OverageStepPaymentEffectiveDate],[OverageStepPayments],[OverageStepPercentage],[OverageStepPeriod],[OverageTier],[TaxLocationId])
    VALUES (S.[AdminFee_Amount],S.[AdminFee_Currency],S.[ApplyByAsset],S.[BaseAllowance],S.[BaseAmount_Amount],S.[BaseAmount_Currency],S.[BaseChargeGeneratedTillDate],S.[BaseRate],S.[BaseRateCalculated],S.[BaseStepPaymentEffectiveDate],S.[BaseStepPayments],S.[BaseStepPercentage],S.[BaseStepPeriod],S.[BeginDate],S.[CPIContractId],S.[CreatedById],S.[CreatedTime],S.[InvoiceAmendmentType],S.[IsActive],S.[MeterTypeId],S.[NextStartDate],S.[Number],S.[OverageChargeGeneratedTillDate],S.[OverageStepPaymentEffectiveDate],S.[OverageStepPayments],S.[OverageStepPercentage],S.[OverageStepPeriod],S.[OverageTier],S.[TaxLocationId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
