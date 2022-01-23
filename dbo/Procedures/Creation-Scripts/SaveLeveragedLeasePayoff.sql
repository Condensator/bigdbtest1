SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeveragedLeasePayoff]
(
 @val [dbo].[LeveragedLeasePayoff] READONLY
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
MERGE [dbo].[LeveragedLeasePayoffs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Comment]=S.[Comment],[DeferredTaxBalance_Amount]=S.[DeferredTaxBalance_Amount],[DeferredTaxBalance_Currency]=S.[DeferredTaxBalance_Currency],[DueDate]=S.[DueDate],[GoodThroughDate]=S.[GoodThroughDate],[IsPayOffAtInception]=S.[IsPayOffAtInception],[LeveragedLeaseId]=S.[LeveragedLeaseId],[LeveragedLeasePayoffGLTemplateId]=S.[LeveragedLeasePayoffGLTemplateId],[LeveragedLeasePayoffReceivableCodeId]=S.[LeveragedLeasePayoffReceivableCodeId],[Number]=S.[Number],[PayoffAmount_Amount]=S.[PayoffAmount_Amount],[PayoffAmount_Currency]=S.[PayoffAmount_Currency],[PayoffDate]=S.[PayoffDate],[PostDate]=S.[PostDate],[QuotationDate]=S.[QuotationDate],[RemainingRentalReceivable_Amount]=S.[RemainingRentalReceivable_Amount],[RemainingRentalReceivable_Currency]=S.[RemainingRentalReceivable_Currency],[Residual_Amount]=S.[Residual_Amount],[Residual_Currency]=S.[Residual_Currency],[Status]=S.[Status],[TerminationOption]=S.[TerminationOption],[UnearnedIncome_Amount]=S.[UnearnedIncome_Amount],[UnearnedIncome_Currency]=S.[UnearnedIncome_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Comment],[CreatedById],[CreatedTime],[DeferredTaxBalance_Amount],[DeferredTaxBalance_Currency],[DueDate],[GoodThroughDate],[IsPayOffAtInception],[LeveragedLeaseId],[LeveragedLeasePayoffGLTemplateId],[LeveragedLeasePayoffReceivableCodeId],[Number],[PayoffAmount_Amount],[PayoffAmount_Currency],[PayoffDate],[PostDate],[QuotationDate],[RemainingRentalReceivable_Amount],[RemainingRentalReceivable_Currency],[Residual_Amount],[Residual_Currency],[Status],[TerminationOption],[UnearnedIncome_Amount],[UnearnedIncome_Currency])
    VALUES (S.[Comment],S.[CreatedById],S.[CreatedTime],S.[DeferredTaxBalance_Amount],S.[DeferredTaxBalance_Currency],S.[DueDate],S.[GoodThroughDate],S.[IsPayOffAtInception],S.[LeveragedLeaseId],S.[LeveragedLeasePayoffGLTemplateId],S.[LeveragedLeasePayoffReceivableCodeId],S.[Number],S.[PayoffAmount_Amount],S.[PayoffAmount_Currency],S.[PayoffDate],S.[PostDate],S.[QuotationDate],S.[RemainingRentalReceivable_Amount],S.[RemainingRentalReceivable_Currency],S.[Residual_Amount],S.[Residual_Currency],S.[Status],S.[TerminationOption],S.[UnearnedIncome_Amount],S.[UnearnedIncome_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
