SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePreQuoteLease]
(
 @val [dbo].[PreQuoteLease] READONLY
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
MERGE [dbo].[PreQuoteLeases] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BookedResidual_Amount]=S.[BookedResidual_Amount],[BookedResidual_Currency]=S.[BookedResidual_Currency],[IsActive]=S.[IsActive],[LeaseFinanceId]=S.[LeaseFinanceId],[ManagementYield]=S.[ManagementYield],[OTPDepreciation_Amount]=S.[OTPDepreciation_Amount],[OTPDepreciation_Currency]=S.[OTPDepreciation_Currency],[OTPIncome_Amount]=S.[OTPIncome_Amount],[OTPIncome_Currency]=S.[OTPIncome_Currency],[OTPStartDate]=S.[OTPStartDate],[Payment_Amount]=S.[Payment_Amount],[Payment_Currency]=S.[Payment_Currency],[PayoffId]=S.[PayoffId],[PreQuoteContractId]=S.[PreQuoteContractId],[RemainingIncomeBalance_Amount]=S.[RemainingIncomeBalance_Amount],[RemainingIncomeBalance_Currency]=S.[RemainingIncomeBalance_Currency],[RemainingRentalReceivable_Amount]=S.[RemainingRentalReceivable_Amount],[RemainingRentalReceivable_Currency]=S.[RemainingRentalReceivable_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BookedResidual_Amount],[BookedResidual_Currency],[CreatedById],[CreatedTime],[IsActive],[LeaseFinanceId],[ManagementYield],[OTPDepreciation_Amount],[OTPDepreciation_Currency],[OTPIncome_Amount],[OTPIncome_Currency],[OTPStartDate],[Payment_Amount],[Payment_Currency],[PayoffId],[PreQuoteContractId],[PreQuoteId],[RemainingIncomeBalance_Amount],[RemainingIncomeBalance_Currency],[RemainingRentalReceivable_Amount],[RemainingRentalReceivable_Currency])
    VALUES (S.[BookedResidual_Amount],S.[BookedResidual_Currency],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[LeaseFinanceId],S.[ManagementYield],S.[OTPDepreciation_Amount],S.[OTPDepreciation_Currency],S.[OTPIncome_Amount],S.[OTPIncome_Currency],S.[OTPStartDate],S.[Payment_Amount],S.[Payment_Currency],S.[PayoffId],S.[PreQuoteContractId],S.[PreQuoteId],S.[RemainingIncomeBalance_Amount],S.[RemainingIncomeBalance_Currency],S.[RemainingRentalReceivable_Amount],S.[RemainingRentalReceivable_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
