SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssumptionAssets]
(
 @val [dbo].[AssumptionAssets] READONLY
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
MERGE [dbo].[AssumptionAssets] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[BillToId]=S.[BillToId],[IsActive]=S.[IsActive],[LocationId]=S.[LocationId],[NewDriverId]=S.[NewDriverId],[OriginalLocationId]=S.[OriginalLocationId],[UpdatedById]=S.[UpdatedById],[UpdateDriverAssignment]=S.[UpdateDriverAssignment],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[AssumptionId],[BillToId],[CreatedById],[CreatedTime],[IsActive],[LocationId],[NewDriverId],[OriginalLocationId],[UpdateDriverAssignment])
    VALUES (S.[AssetId],S.[AssumptionId],S.[BillToId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[LocationId],S.[NewDriverId],S.[OriginalLocationId],S.[UpdateDriverAssignment])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
