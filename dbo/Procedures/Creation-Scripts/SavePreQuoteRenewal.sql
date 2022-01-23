SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePreQuoteRenewal]
(
 @val [dbo].[PreQuoteRenewal] READONLY
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
MERGE [dbo].[PreQuoteRenewals] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetCatalogId]=S.[AssetCatalogId],[ContractId]=S.[ContractId],[ExistingNBV_Amount]=S.[ExistingNBV_Amount],[ExistingNBV_Currency]=S.[ExistingNBV_Currency],[InterestRate]=S.[InterestRate],[IsActive]=S.[IsActive],[IsRenewalAccepted]=S.[IsRenewalAccepted],[PaymentAmount_Amount]=S.[PaymentAmount_Amount],[PaymentAmount_Currency]=S.[PaymentAmount_Currency],[PaymentFrequency]=S.[PaymentFrequency],[Price_Amount]=S.[Price_Amount],[Price_Currency]=S.[Price_Currency],[RenewalType]=S.[RenewalType],[ResidualValue_Amount]=S.[ResidualValue_Amount],[ResidualValue_Currency]=S.[ResidualValue_Currency],[ServiceAmount_Amount]=S.[ServiceAmount_Amount],[ServiceAmount_Currency]=S.[ServiceAmount_Currency],[SuggestedPrice_Amount]=S.[SuggestedPrice_Amount],[SuggestedPrice_Currency]=S.[SuggestedPrice_Currency],[Term]=S.[Term],[TotalPayment_Amount]=S.[TotalPayment_Amount],[TotalPayment_Currency]=S.[TotalPayment_Currency],[TotalPrice_Amount]=S.[TotalPrice_Amount],[TotalPrice_Currency]=S.[TotalPrice_Currency],[TotalService_Amount]=S.[TotalService_Amount],[TotalService_Currency]=S.[TotalService_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpgradeRenewalDollar_Amount]=S.[UpgradeRenewalDollar_Amount],[UpgradeRenewalDollar_Currency]=S.[UpgradeRenewalDollar_Currency],[UpgradeRenewalPMT_Amount]=S.[UpgradeRenewalPMT_Amount],[UpgradeRenewalPMT_Currency]=S.[UpgradeRenewalPMT_Currency],[UpgradeRenewalPrice_Amount]=S.[UpgradeRenewalPrice_Amount],[UpgradeRenewalPrice_Currency]=S.[UpgradeRenewalPrice_Currency],[UpgradeRenewalRV_Amount]=S.[UpgradeRenewalRV_Amount],[UpgradeRenewalRV_Currency]=S.[UpgradeRenewalRV_Currency],[UpgradeRenewalService_Amount]=S.[UpgradeRenewalService_Amount],[UpgradeRenewalService_Currency]=S.[UpgradeRenewalService_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AssetCatalogId],[ContractId],[CreatedById],[CreatedTime],[ExistingNBV_Amount],[ExistingNBV_Currency],[InterestRate],[IsActive],[IsRenewalAccepted],[PaymentAmount_Amount],[PaymentAmount_Currency],[PaymentFrequency],[PreQuoteId],[Price_Amount],[Price_Currency],[RenewalType],[ResidualValue_Amount],[ResidualValue_Currency],[ServiceAmount_Amount],[ServiceAmount_Currency],[SuggestedPrice_Amount],[SuggestedPrice_Currency],[Term],[TotalPayment_Amount],[TotalPayment_Currency],[TotalPrice_Amount],[TotalPrice_Currency],[TotalService_Amount],[TotalService_Currency],[UpgradeRenewalDollar_Amount],[UpgradeRenewalDollar_Currency],[UpgradeRenewalPMT_Amount],[UpgradeRenewalPMT_Currency],[UpgradeRenewalPrice_Amount],[UpgradeRenewalPrice_Currency],[UpgradeRenewalRV_Amount],[UpgradeRenewalRV_Currency],[UpgradeRenewalService_Amount],[UpgradeRenewalService_Currency])
    VALUES (S.[AssetCatalogId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[ExistingNBV_Amount],S.[ExistingNBV_Currency],S.[InterestRate],S.[IsActive],S.[IsRenewalAccepted],S.[PaymentAmount_Amount],S.[PaymentAmount_Currency],S.[PaymentFrequency],S.[PreQuoteId],S.[Price_Amount],S.[Price_Currency],S.[RenewalType],S.[ResidualValue_Amount],S.[ResidualValue_Currency],S.[ServiceAmount_Amount],S.[ServiceAmount_Currency],S.[SuggestedPrice_Amount],S.[SuggestedPrice_Currency],S.[Term],S.[TotalPayment_Amount],S.[TotalPayment_Currency],S.[TotalPrice_Amount],S.[TotalPrice_Currency],S.[TotalService_Amount],S.[TotalService_Currency],S.[UpgradeRenewalDollar_Amount],S.[UpgradeRenewalDollar_Currency],S.[UpgradeRenewalPMT_Amount],S.[UpgradeRenewalPMT_Currency],S.[UpgradeRenewalPrice_Amount],S.[UpgradeRenewalPrice_Currency],S.[UpgradeRenewalRV_Amount],S.[UpgradeRenewalRV_Currency],S.[UpgradeRenewalService_Amount],S.[UpgradeRenewalService_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
