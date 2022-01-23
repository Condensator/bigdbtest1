SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveFinancialStatementDocument]
(
 @val [dbo].[FinancialStatementDocument] READONLY
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
MERGE [dbo].[FinancialStatementDocuments] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Comment]=S.[Comment],[CPLTD_Amount]=S.[CPLTD_Amount],[CPLTD_Currency]=S.[CPLTD_Currency],[CurrentAssets_Amount]=S.[CurrentAssets_Amount],[CurrentAssets_Currency]=S.[CurrentAssets_Currency],[CurrentLiabilities_Amount]=S.[CurrentLiabilities_Amount],[CurrentLiabilities_Currency]=S.[CurrentLiabilities_Currency],[DebtToTNW]=S.[DebtToTNW],[DocumentRequirementId]=S.[DocumentRequirementId],[EBITDA_Amount]=S.[EBITDA_Amount],[EBITDA_Currency]=S.[EBITDA_Currency],[ExceptionComment]=S.[ExceptionComment],[InterestExpense_Amount]=S.[InterestExpense_Amount],[InterestExpense_Currency]=S.[InterestExpense_Currency],[LatestStatementDate]=S.[LatestStatementDate],[NetIncome_Amount]=S.[NetIncome_Amount],[NetIncome_Currency]=S.[NetIncome_Currency],[StatusId]=S.[StatusId],[TNW_Amount]=S.[TNW_Amount],[TNW_Currency]=S.[TNW_Currency],[TotalAssets_Amount]=S.[TotalAssets_Amount],[TotalAssets_Currency]=S.[TotalAssets_Currency],[TotalLiabilities_Amount]=S.[TotalLiabilities_Amount],[TotalLiabilities_Currency]=S.[TotalLiabilities_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UploadStatus]=S.[UploadStatus]
WHEN NOT MATCHED THEN
	INSERT ([Comment],[CPLTD_Amount],[CPLTD_Currency],[CreatedById],[CreatedTime],[CurrentAssets_Amount],[CurrentAssets_Currency],[CurrentLiabilities_Amount],[CurrentLiabilities_Currency],[DebtToTNW],[DocumentRequirementId],[EBITDA_Amount],[EBITDA_Currency],[ExceptionComment],[FinancialStatementId],[InterestExpense_Amount],[InterestExpense_Currency],[LatestStatementDate],[NetIncome_Amount],[NetIncome_Currency],[StatusId],[TNW_Amount],[TNW_Currency],[TotalAssets_Amount],[TotalAssets_Currency],[TotalLiabilities_Amount],[TotalLiabilities_Currency],[UploadStatus])
    VALUES (S.[Comment],S.[CPLTD_Amount],S.[CPLTD_Currency],S.[CreatedById],S.[CreatedTime],S.[CurrentAssets_Amount],S.[CurrentAssets_Currency],S.[CurrentLiabilities_Amount],S.[CurrentLiabilities_Currency],S.[DebtToTNW],S.[DocumentRequirementId],S.[EBITDA_Amount],S.[EBITDA_Currency],S.[ExceptionComment],S.[FinancialStatementId],S.[InterestExpense_Amount],S.[InterestExpense_Currency],S.[LatestStatementDate],S.[NetIncome_Amount],S.[NetIncome_Currency],S.[StatusId],S.[TNW_Amount],S.[TNW_Currency],S.[TotalAssets_Amount],S.[TotalAssets_Currency],S.[TotalLiabilities_Amount],S.[TotalLiabilities_Currency],S.[UploadStatus])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
