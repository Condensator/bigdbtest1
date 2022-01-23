SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeaseSyndicationProgressPaymentCredit]
(
 @val [dbo].[LeaseSyndicationProgressPaymentCredit] READONLY
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
MERGE [dbo].[LeaseSyndicationProgressPaymentCredits] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [IsActive]=S.[IsActive],[IsNewlyAdded]=S.[IsNewlyAdded],[OtherCostCapitalizedAmount_Amount]=S.[OtherCostCapitalizedAmount_Amount],[OtherCostCapitalizedAmount_Currency]=S.[OtherCostCapitalizedAmount_Currency],[PayableInvoiceOtherCostId]=S.[PayableInvoiceOtherCostId],[TakeDownAmount_Amount]=S.[TakeDownAmount_Amount],[TakeDownAmount_Currency]=S.[TakeDownAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[IsActive],[IsNewlyAdded],[LeaseSyndicationId],[OtherCostCapitalizedAmount_Amount],[OtherCostCapitalizedAmount_Currency],[PayableInvoiceOtherCostId],[TakeDownAmount_Amount],[TakeDownAmount_Currency])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsNewlyAdded],S.[LeaseSyndicationId],S.[OtherCostCapitalizedAmount_Amount],S.[OtherCostCapitalizedAmount_Currency],S.[PayableInvoiceOtherCostId],S.[TakeDownAmount_Amount],S.[TakeDownAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
