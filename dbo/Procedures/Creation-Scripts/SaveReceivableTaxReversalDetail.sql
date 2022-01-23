SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivableTaxReversalDetail]
(
 @val [dbo].[ReceivableTaxReversalDetail] READONLY
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
MERGE [dbo].[ReceivableTaxReversalDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountBilledToDate]=S.[AmountBilledToDate],[AssetId]=S.[AssetId],[AssetLocationId]=S.[AssetLocationId],[AssetType]=S.[AssetType],[BusCode]=S.[BusCode],[Company]=S.[Company],[ContractType]=S.[ContractType],[FromStateName]=S.[FromStateName],[IsCapitalizeUpfrontSalesTax]=S.[IsCapitalizeUpfrontSalesTax],[IsExemptAtAsset]=S.[IsExemptAtAsset],[IsExemptAtLease]=S.[IsExemptAtLease],[IsExemptAtSundry]=S.[IsExemptAtSundry],[LeaseTerm]=S.[LeaseTerm],[LeaseType]=S.[LeaseType],[Product]=S.[Product],[SalesTaxRemittanceResponsibility]=S.[SalesTaxRemittanceResponsibility],[TitleTransferCode]=S.[TitleTransferCode],[ToStateName]=S.[ToStateName],[TransactionCode]=S.[TransactionCode],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontTaxAssessedInLegacySystem]=S.[UpfrontTaxAssessedInLegacySystem]
WHEN NOT MATCHED THEN
	INSERT ([AmountBilledToDate],[AssetId],[AssetLocationId],[AssetType],[BusCode],[Company],[ContractType],[CreatedById],[CreatedTime],[FromStateName],[Id],[IsCapitalizeUpfrontSalesTax],[IsExemptAtAsset],[IsExemptAtLease],[IsExemptAtSundry],[LeaseTerm],[LeaseType],[Product],[SalesTaxRemittanceResponsibility],[TitleTransferCode],[ToStateName],[TransactionCode],[UpfrontTaxAssessedInLegacySystem])
    VALUES (S.[AmountBilledToDate],S.[AssetId],S.[AssetLocationId],S.[AssetType],S.[BusCode],S.[Company],S.[ContractType],S.[CreatedById],S.[CreatedTime],S.[FromStateName],S.[Id],S.[IsCapitalizeUpfrontSalesTax],S.[IsExemptAtAsset],S.[IsExemptAtLease],S.[IsExemptAtSundry],S.[LeaseTerm],S.[LeaseType],S.[Product],S.[SalesTaxRemittanceResponsibility],S.[TitleTransferCode],S.[ToStateName],S.[TransactionCode],S.[UpfrontTaxAssessedInLegacySystem])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
