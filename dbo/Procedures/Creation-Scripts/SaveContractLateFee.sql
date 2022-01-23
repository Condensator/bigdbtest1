SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveContractLateFee]
(
 @val [dbo].[ContractLateFee] READONLY
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
MERGE [dbo].[ContractLateFees] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [HolidayMethod]=S.[HolidayMethod],[InterestCeilingPercentage]=S.[InterestCeilingPercentage],[InterestFloorPercentage]=S.[InterestFloorPercentage],[InvoiceGraceDays]=S.[InvoiceGraceDays],[InvoiceGraceDaysAtInception]=S.[InvoiceGraceDaysAtInception],[IsActive]=S.[IsActive],[IsIndexPercentage]=S.[IsIndexPercentage],[IsMoveAcrossMonth]=S.[IsMoveAcrossMonth],[LateFeeCeilingAmount_Amount]=S.[LateFeeCeilingAmount_Amount],[LateFeeCeilingAmount_Currency]=S.[LateFeeCeilingAmount_Currency],[LateFeeFloorAmount_Amount]=S.[LateFeeFloorAmount_Amount],[LateFeeFloorAmount_Currency]=S.[LateFeeFloorAmount_Currency],[LateFeeTemplateId]=S.[LateFeeTemplateId],[Percentage]=S.[Percentage],[PercentageBasis]=S.[PercentageBasis],[Spread]=S.[Spread],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WaiveIfInvoiceAmountBelow_Amount]=S.[WaiveIfInvoiceAmountBelow_Amount],[WaiveIfInvoiceAmountBelow_Currency]=S.[WaiveIfInvoiceAmountBelow_Currency],[WaiveIfLateFeeBelow_Amount]=S.[WaiveIfLateFeeBelow_Amount],[WaiveIfLateFeeBelow_Currency]=S.[WaiveIfLateFeeBelow_Currency]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[HolidayMethod],[Id],[InterestCeilingPercentage],[InterestFloorPercentage],[InvoiceGraceDays],[InvoiceGraceDaysAtInception],[IsActive],[IsIndexPercentage],[IsMoveAcrossMonth],[LateFeeCeilingAmount_Amount],[LateFeeCeilingAmount_Currency],[LateFeeFloorAmount_Amount],[LateFeeFloorAmount_Currency],[LateFeeTemplateId],[Percentage],[PercentageBasis],[Spread],[WaiveIfInvoiceAmountBelow_Amount],[WaiveIfInvoiceAmountBelow_Currency],[WaiveIfLateFeeBelow_Amount],[WaiveIfLateFeeBelow_Currency])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[HolidayMethod],S.[Id],S.[InterestCeilingPercentage],S.[InterestFloorPercentage],S.[InvoiceGraceDays],S.[InvoiceGraceDaysAtInception],S.[IsActive],S.[IsIndexPercentage],S.[IsMoveAcrossMonth],S.[LateFeeCeilingAmount_Amount],S.[LateFeeCeilingAmount_Currency],S.[LateFeeFloorAmount_Amount],S.[LateFeeFloorAmount_Currency],S.[LateFeeTemplateId],S.[Percentage],S.[PercentageBasis],S.[Spread],S.[WaiveIfInvoiceAmountBelow_Amount],S.[WaiveIfInvoiceAmountBelow_Currency],S.[WaiveIfLateFeeBelow_Amount],S.[WaiveIfLateFeeBelow_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
