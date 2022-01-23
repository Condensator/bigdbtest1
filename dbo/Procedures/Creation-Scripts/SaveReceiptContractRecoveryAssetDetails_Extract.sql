SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptContractRecoveryAssetDetails_Extract]
(
 @val [dbo].[ReceiptContractRecoveryAssetDetails_Extract] READONLY
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
MERGE [dbo].[ReceiptContractRecoveryAssetDetails_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[ChargeOffId]=S.[ChargeOffId],[ContractId]=S.[ContractId],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseComponentWriteDownAmount]=S.[LeaseComponentWriteDownAmount],[NetInvestmentWithBlended]=S.[NetInvestmentWithBlended],[NetWriteDownForChargeOff]=S.[NetWriteDownForChargeOff],[NonLeaseComponentWriteDownAmount]=S.[NonLeaseComponentWriteDownAmount],[TotalWriteDownAmount]=S.[TotalWriteDownAmount],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WriteDownId]=S.[WriteDownId]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[ChargeOffId],[ContractId],[CreatedById],[CreatedTime],[JobStepInstanceId],[LeaseComponentWriteDownAmount],[NetInvestmentWithBlended],[NetWriteDownForChargeOff],[NonLeaseComponentWriteDownAmount],[TotalWriteDownAmount],[WriteDownId])
    VALUES (S.[AssetId],S.[ChargeOffId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[JobStepInstanceId],S.[LeaseComponentWriteDownAmount],S.[NetInvestmentWithBlended],S.[NetWriteDownForChargeOff],S.[NonLeaseComponentWriteDownAmount],S.[TotalWriteDownAmount],S.[WriteDownId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
