SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveNonVertexLeaseDetail_Extract]
(
 @val [dbo].[NonVertexLeaseDetail_Extract] READONLY
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
MERGE [dbo].[NonVertexLeaseDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ClassificationContractType]=S.[ClassificationContractType],[CommencementDate]=S.[CommencementDate],[ContractId]=S.[ContractId],[IsCityTaxExempt]=S.[IsCityTaxExempt],[IsContractCapitalizeUpfront]=S.[IsContractCapitalizeUpfront],[IsCountryTaxExempt]=S.[IsCountryTaxExempt],[IsCountyTaxExempt]=S.[IsCountyTaxExempt],[IsLease]=S.[IsLease],[IsStateTaxExempt]=S.[IsStateTaxExempt],[IsSyndicated]=S.[IsSyndicated],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseFinanceId]=S.[LeaseFinanceId],[NumberOfInceptionPayments]=S.[NumberOfInceptionPayments],[SalesTaxRemittanceMethod]=S.[SalesTaxRemittanceMethod],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ClassificationContractType],[CommencementDate],[ContractId],[CreatedById],[CreatedTime],[IsCityTaxExempt],[IsContractCapitalizeUpfront],[IsCountryTaxExempt],[IsCountyTaxExempt],[IsLease],[IsStateTaxExempt],[IsSyndicated],[JobStepInstanceId],[LeaseFinanceId],[NumberOfInceptionPayments],[SalesTaxRemittanceMethod])
    VALUES (S.[ClassificationContractType],S.[CommencementDate],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[IsCityTaxExempt],S.[IsContractCapitalizeUpfront],S.[IsCountryTaxExempt],S.[IsCountyTaxExempt],S.[IsLease],S.[IsStateTaxExempt],S.[IsSyndicated],S.[JobStepInstanceId],S.[LeaseFinanceId],S.[NumberOfInceptionPayments],S.[SalesTaxRemittanceMethod])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
