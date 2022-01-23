SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetsLocationChange]
(
 @val [dbo].[AssetsLocationChange] READONLY
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
MERGE [dbo].[AssetsLocationChanges] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BusinessUnitId]=S.[BusinessUnitId],[Comment]=S.[Comment],[CustomerComment]=S.[CustomerComment],[EffectiveFromDate]=S.[EffectiveFromDate],[LocationChangeSourceType]=S.[LocationChangeSourceType],[LocationId]=S.[LocationId],[MigrationId]=S.[MigrationId],[MoveChildAssets]=S.[MoveChildAssets],[NewLocationId]=S.[NewLocationId],[Status]=S.[Status],[TaxBasisType]=S.[TaxBasisType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontTaxMode]=S.[UpfrontTaxMode],[VendorComment]=S.[VendorComment],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([BusinessUnitId],[Comment],[CreatedById],[CreatedTime],[CustomerComment],[EffectiveFromDate],[LocationChangeSourceType],[LocationId],[MigrationId],[MoveChildAssets],[NewLocationId],[Status],[TaxBasisType],[UpfrontTaxMode],[VendorComment],[VendorId])
    VALUES (S.[BusinessUnitId],S.[Comment],S.[CreatedById],S.[CreatedTime],S.[CustomerComment],S.[EffectiveFromDate],S.[LocationChangeSourceType],S.[LocationId],S.[MigrationId],S.[MoveChildAssets],S.[NewLocationId],S.[Status],S.[TaxBasisType],S.[UpfrontTaxMode],S.[VendorComment],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
