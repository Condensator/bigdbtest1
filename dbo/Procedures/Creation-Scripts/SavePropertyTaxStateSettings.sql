SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePropertyTaxStateSettings]
(
 @val [dbo].[PropertyTaxStateSettings] READONLY
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
MERGE [dbo].[PropertyTaxStateSettings] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssessmentDay]=S.[AssessmentDay],[AssessmentMonth]=S.[AssessmentMonth],[Comment]=S.[Comment],[EffectiveFromDate]=S.[EffectiveFromDate],[EffectiveToDate]=S.[EffectiveToDate],[FilingDueDay]=S.[FilingDueDay],[FilingDueMonth]=S.[FilingDueMonth],[IsActive]=S.[IsActive],[IsExempt]=S.[IsExempt],[IsReportCSAs]=S.[IsReportCSAs],[IsReportInventory]=S.[IsReportInventory],[IsSalesTaxOnPropertyTax]=S.[IsSalesTaxOnPropertyTax],[LeadDays]=S.[LeadDays],[PortfolioId]=S.[PortfolioId],[StateId]=S.[StateId],[UniqueIdentifier]=S.[UniqueIdentifier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssessmentDay],[AssessmentMonth],[Comment],[CreatedById],[CreatedTime],[EffectiveFromDate],[EffectiveToDate],[FilingDueDay],[FilingDueMonth],[IsActive],[IsExempt],[IsReportCSAs],[IsReportInventory],[IsSalesTaxOnPropertyTax],[LeadDays],[PortfolioId],[PropertyTaxParameterId],[StateId],[UniqueIdentifier])
    VALUES (S.[AssessmentDay],S.[AssessmentMonth],S.[Comment],S.[CreatedById],S.[CreatedTime],S.[EffectiveFromDate],S.[EffectiveToDate],S.[FilingDueDay],S.[FilingDueMonth],S.[IsActive],S.[IsExempt],S.[IsReportCSAs],S.[IsReportInventory],S.[IsSalesTaxOnPropertyTax],S.[LeadDays],S.[PortfolioId],S.[PropertyTaxParameterId],S.[StateId],S.[UniqueIdentifier])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
