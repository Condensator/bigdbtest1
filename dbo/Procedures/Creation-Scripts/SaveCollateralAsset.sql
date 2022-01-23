SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCollateralAsset]
(
 @val [dbo].[CollateralAsset] READONLY
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
MERGE [dbo].[CollateralAssets] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquisitionCost_Amount]=S.[AcquisitionCost_Amount],[AcquisitionCost_Currency]=S.[AcquisitionCost_Currency],[AssetId]=S.[AssetId],[IsActive]=S.[IsActive],[IsFromProgressFunding]=S.[IsFromProgressFunding],[IsNewlyAdded]=S.[IsNewlyAdded],[IsPrimary]=S.[IsPrimary],[TerminationDate]=S.[TerminationDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcquisitionCost_Amount],[AcquisitionCost_Currency],[AssetId],[CreatedById],[CreatedTime],[IsActive],[IsFromProgressFunding],[IsNewlyAdded],[IsPrimary],[LoanFinanceId],[TerminationDate])
    VALUES (S.[AcquisitionCost_Amount],S.[AcquisitionCost_Currency],S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsFromProgressFunding],S.[IsNewlyAdded],S.[IsPrimary],S.[LoanFinanceId],S.[TerminationDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
