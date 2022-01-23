SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTaxDepRateDetail]
(
 @val [dbo].[TaxDepRateDetail] READONLY
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
MERGE [dbo].[TaxDepRateDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DepreciationPercent]=S.[DepreciationPercent],[PeriodNumber]=S.[PeriodNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[YearNumber]=S.[YearNumber]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[DepreciationPercent],[PeriodNumber],[TaxDepRateId],[YearNumber])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[DepreciationPercent],S.[PeriodNumber],S.[TaxDepRateId],S.[YearNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
