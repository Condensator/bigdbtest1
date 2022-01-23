SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePropertyTaxExemptCode]
(
 @val [dbo].[PropertyTaxExemptCode] READONLY
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
MERGE [dbo].[PropertyTaxExemptCodes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [EffectiveFromDate]=S.[EffectiveFromDate],[EffectiveToDate]=S.[EffectiveToDate],[IsActive]=S.[IsActive],[PortfolioId]=S.[PortfolioId],[PropertyTaxReportCodeId]=S.[PropertyTaxReportCodeId],[StateId]=S.[StateId],[UniqueIdentifier]=S.[UniqueIdentifier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[EffectiveFromDate],[EffectiveToDate],[IsActive],[PortfolioId],[PropertyTaxParameterId],[PropertyTaxReportCodeId],[StateId],[UniqueIdentifier])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[EffectiveFromDate],S.[EffectiveToDate],S.[IsActive],S.[PortfolioId],S.[PropertyTaxParameterId],S.[PropertyTaxReportCodeId],S.[StateId],S.[UniqueIdentifier])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
