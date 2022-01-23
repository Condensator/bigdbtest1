SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveGLOrgStructureConfig]
(
 @val [dbo].[GLOrgStructureConfig] READONLY
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
MERGE [dbo].[GLOrgStructureConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AnalysisCodeBasedOnBizCode]=S.[AnalysisCodeBasedOnBizCode],[AnalysisCodeBasedOnCenter]=S.[AnalysisCodeBasedOnCenter],[BusinessCode]=S.[BusinessCode],[BusinessCodeDescription]=S.[BusinessCodeDescription],[CostCenterId]=S.[CostCenterId],[CounterpartyAnalysisCodeBasedOnBizCodeAndLE]=S.[CounterpartyAnalysisCodeBasedOnBizCodeAndLE],[CurrencyId]=S.[CurrencyId],[IsActive]=S.[IsActive],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[MORDate]=S.[MORDate],[OrgStructureComments]=S.[OrgStructureComments],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AnalysisCodeBasedOnBizCode],[AnalysisCodeBasedOnCenter],[BusinessCode],[BusinessCodeDescription],[CostCenterId],[CounterpartyAnalysisCodeBasedOnBizCodeAndLE],[CreatedById],[CreatedTime],[CurrencyId],[IsActive],[LegalEntityId],[LineofBusinessId],[MORDate],[OrgStructureComments])
    VALUES (S.[AnalysisCodeBasedOnBizCode],S.[AnalysisCodeBasedOnCenter],S.[BusinessCode],S.[BusinessCodeDescription],S.[CostCenterId],S.[CounterpartyAnalysisCodeBasedOnBizCodeAndLE],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[IsActive],S.[LegalEntityId],S.[LineofBusinessId],S.[MORDate],S.[OrgStructureComments])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
