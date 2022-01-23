SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveWriteDownAssetDetail]
(
 @val [dbo].[WriteDownAssetDetail] READONLY
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
MERGE [dbo].[WriteDownAssetDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[GrossWritedown_Amount]=S.[GrossWritedown_Amount],[GrossWritedown_Currency]=S.[GrossWritedown_Currency],[IsActive]=S.[IsActive],[LeaseComponentWriteDownAmount_Amount]=S.[LeaseComponentWriteDownAmount_Amount],[LeaseComponentWriteDownAmount_Currency]=S.[LeaseComponentWriteDownAmount_Currency],[NetInvestmentWithBlended_Amount]=S.[NetInvestmentWithBlended_Amount],[NetInvestmentWithBlended_Currency]=S.[NetInvestmentWithBlended_Currency],[NetInvestmentWithReserve_Amount]=S.[NetInvestmentWithReserve_Amount],[NetInvestmentWithReserve_Currency]=S.[NetInvestmentWithReserve_Currency],[NetWritedown_Amount]=S.[NetWritedown_Amount],[NetWritedown_Currency]=S.[NetWritedown_Currency],[NonLeaseComponentWriteDownAmount_Amount]=S.[NonLeaseComponentWriteDownAmount_Amount],[NonLeaseComponentWriteDownAmount_Currency]=S.[NonLeaseComponentWriteDownAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WriteDownAmount_Amount]=S.[WriteDownAmount_Amount],[WriteDownAmount_Currency]=S.[WriteDownAmount_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[CreatedById],[CreatedTime],[GrossWritedown_Amount],[GrossWritedown_Currency],[IsActive],[LeaseComponentWriteDownAmount_Amount],[LeaseComponentWriteDownAmount_Currency],[NetInvestmentWithBlended_Amount],[NetInvestmentWithBlended_Currency],[NetInvestmentWithReserve_Amount],[NetInvestmentWithReserve_Currency],[NetWritedown_Amount],[NetWritedown_Currency],[NonLeaseComponentWriteDownAmount_Amount],[NonLeaseComponentWriteDownAmount_Currency],[WriteDownAmount_Amount],[WriteDownAmount_Currency],[WriteDownId])
    VALUES (S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[GrossWritedown_Amount],S.[GrossWritedown_Currency],S.[IsActive],S.[LeaseComponentWriteDownAmount_Amount],S.[LeaseComponentWriteDownAmount_Currency],S.[NetInvestmentWithBlended_Amount],S.[NetInvestmentWithBlended_Currency],S.[NetInvestmentWithReserve_Amount],S.[NetInvestmentWithReserve_Currency],S.[NetWritedown_Amount],S.[NetWritedown_Currency],S.[NonLeaseComponentWriteDownAmount_Amount],S.[NonLeaseComponentWriteDownAmount_Currency],S.[WriteDownAmount_Amount],S.[WriteDownAmount_Currency],S.[WriteDownId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
