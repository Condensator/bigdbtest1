SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveMTPLConfig]
(
 @val [dbo].[MTPLConfig] READONLY
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
MERGE [dbo].[MTPLConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetTypeId]=S.[AssetTypeId],[EngineCapacityFrom]=S.[EngineCapacityFrom],[EngineCapacityTo]=S.[EngineCapacityTo],[Frequency]=S.[Frequency],[InsurancePremium_Amount]=S.[InsurancePremium_Amount],[InsurancePremium_Currency]=S.[InsurancePremium_Currency],[IsActive]=S.[IsActive],[LegalEntityId]=S.[LegalEntityId],[PermissibleMassFrom]=S.[PermissibleMassFrom],[PermissibleMassTo]=S.[PermissibleMassTo],[RegionId]=S.[RegionId],[SeatsFrom]=S.[SeatsFrom],[SeatsTo]=S.[SeatsTo],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetTypeId],[CreatedById],[CreatedTime],[EngineCapacityFrom],[EngineCapacityTo],[Frequency],[InsurancePremium_Amount],[InsurancePremium_Currency],[IsActive],[LegalEntityId],[PermissibleMassFrom],[PermissibleMassTo],[RegionId],[SeatsFrom],[SeatsTo])
    VALUES (S.[AssetTypeId],S.[CreatedById],S.[CreatedTime],S.[EngineCapacityFrom],S.[EngineCapacityTo],S.[Frequency],S.[InsurancePremium_Amount],S.[InsurancePremium_Currency],S.[IsActive],S.[LegalEntityId],S.[PermissibleMassFrom],S.[PermissibleMassTo],S.[RegionId],S.[SeatsFrom],S.[SeatsTo])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
