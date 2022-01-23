SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditApplicationFeeDetail]
(
 @val [dbo].[CreditApplicationFeeDetail] READONLY
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
MERGE [dbo].[CreditApplicationFeeDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[AmountInclVAT_Amount]=S.[AmountInclVAT_Amount],[AmountInclVAT_Currency]=S.[AmountInclVAT_Currency],[FeeDetailId]=S.[FeeDetailId],[IncludeInAPR]=S.[IncludeInAPR],[IsVAT]=S.[IsVAT],[Name]=S.[Name],[RowNumber]=S.[RowNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[AmountInclVAT_Amount],[AmountInclVAT_Currency],[CreatedById],[CreatedTime],[CreditApplicationId],[FeeDetailId],[IncludeInAPR],[IsVAT],[Name],[RowNumber])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[AmountInclVAT_Amount],S.[AmountInclVAT_Currency],S.[CreatedById],S.[CreatedTime],S.[CreditApplicationId],S.[FeeDetailId],S.[IncludeInAPR],S.[IsVAT],S.[Name],S.[RowNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
