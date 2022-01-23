SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPUAsset]
(
 @val [dbo].[CPUAsset] READONLY
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
MERGE [dbo].[CPUAssets] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[BaseAmount_Amount]=S.[BaseAmount_Amount],[BaseAmount_Currency]=S.[BaseAmount_Currency],[BaseDistributionBasisAmount_Amount]=S.[BaseDistributionBasisAmount_Amount],[BaseDistributionBasisAmount_Currency]=S.[BaseDistributionBasisAmount_Currency],[BaseReceivablesGeneratedTillDate]=S.[BaseReceivablesGeneratedTillDate],[BaseUnits]=S.[BaseUnits],[BeginDate]=S.[BeginDate],[BillToId]=S.[BillToId],[ContractId]=S.[ContractId],[IsActive]=S.[IsActive],[IsCreatedFromBooking]=S.[IsCreatedFromBooking],[IsServiceOnly]=S.[IsServiceOnly],[MaximumReading]=S.[MaximumReading],[OriginalAssetCost_Amount]=S.[OriginalAssetCost_Amount],[OriginalAssetCost_Currency]=S.[OriginalAssetCost_Currency],[OverageDistributionBasisAmount_Amount]=S.[OverageDistributionBasisAmount_Amount],[OverageDistributionBasisAmount_Currency]=S.[OverageDistributionBasisAmount_Currency],[PayoffDate]=S.[PayoffDate],[RemitToId]=S.[RemitToId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[BaseAmount_Amount],[BaseAmount_Currency],[BaseDistributionBasisAmount_Amount],[BaseDistributionBasisAmount_Currency],[BaseReceivablesGeneratedTillDate],[BaseUnits],[BeginDate],[BillToId],[ContractId],[CPUScheduleId],[CreatedById],[CreatedTime],[IsActive],[IsCreatedFromBooking],[IsServiceOnly],[MaximumReading],[OriginalAssetCost_Amount],[OriginalAssetCost_Currency],[OverageDistributionBasisAmount_Amount],[OverageDistributionBasisAmount_Currency],[PayoffDate],[RemitToId])
    VALUES (S.[AssetId],S.[BaseAmount_Amount],S.[BaseAmount_Currency],S.[BaseDistributionBasisAmount_Amount],S.[BaseDistributionBasisAmount_Currency],S.[BaseReceivablesGeneratedTillDate],S.[BaseUnits],S.[BeginDate],S.[BillToId],S.[ContractId],S.[CPUScheduleId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsCreatedFromBooking],S.[IsServiceOnly],S.[MaximumReading],S.[OriginalAssetCost_Amount],S.[OriginalAssetCost_Currency],S.[OverageDistributionBasisAmount_Amount],S.[OverageDistributionBasisAmount_Currency],S.[PayoffDate],S.[RemitToId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
