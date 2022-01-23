SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePropertiesInformationForCreditDecision]
(
 @val [dbo].[PropertiesInformationForCreditDecision] READONLY
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
MERGE [dbo].[PropertiesInformationForCreditDecisions] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActType]=S.[ActType],[IsActive]=S.[IsActive],[Location]=S.[Location],[m2]=S.[m2],[Number]=S.[Number],[Property]=S.[Property],[RegistryAgency]=S.[RegistryAgency],[RelatedActs]=S.[RelatedActs],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActType],[CreatedById],[CreatedTime],[CreditDecisionForCreditApplicationId],[IsActive],[Location],[m2],[Number],[Property],[RegistryAgency],[RelatedActs],[Type])
    VALUES (S.[ActType],S.[CreatedById],S.[CreatedTime],S.[CreditDecisionForCreditApplicationId],S.[IsActive],S.[Location],S.[m2],S.[Number],S.[Property],S.[RegistryAgency],S.[RelatedActs],S.[Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
