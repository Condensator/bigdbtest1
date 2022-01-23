SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCommissionPackageSalesOfficer]
(
 @val [dbo].[CommissionPackageSalesOfficer] READONLY
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
MERGE [dbo].[CommissionPackageSalesOfficers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [FeeSplit]=S.[FeeSplit],[FreeCashSplit]=S.[FreeCashSplit],[IsActive]=S.[IsActive],[IsPrimary]=S.[IsPrimary],[PlanBasisPayoutId]=S.[PlanBasisPayoutId],[SalesOfficerId]=S.[SalesOfficerId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VolumeSplit]=S.[VolumeSplit]
WHEN NOT MATCHED THEN
	INSERT ([CommissionPackageId],[CreatedById],[CreatedTime],[FeeSplit],[FreeCashSplit],[IsActive],[IsPrimary],[PlanBasisPayoutId],[SalesOfficerId],[VolumeSplit])
    VALUES (S.[CommissionPackageId],S.[CreatedById],S.[CreatedTime],S.[FeeSplit],S.[FreeCashSplit],S.[IsActive],S.[IsPrimary],S.[PlanBasisPayoutId],S.[SalesOfficerId],S.[VolumeSplit])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
