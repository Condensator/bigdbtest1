SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePropertyTax]
(
 @val [dbo].[PropertyTax] READONLY
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
MERGE [dbo].[PropertyTaxes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BillNumber]=S.[BillNumber],[CollectorTitle]=S.[CollectorTitle],[ContractId]=S.[ContractId],[DisbursementBatchID]=S.[DisbursementBatchID],[DueDate]=S.[DueDate],[InstallmentNumber]=S.[InstallmentNumber],[InvoiceAmendmentType]=S.[InvoiceAmendmentType],[InvoiceComment]=S.[InvoiceComment],[IsActive]=S.[IsActive],[IsManuallyAssessed]=S.[IsManuallyAssessed],[LienDate]=S.[LienDate],[NumberofInstallments]=S.[NumberofInstallments],[PostDate]=S.[PostDate],[PropertyTaxAmount_Amount]=S.[PropertyTaxAmount_Amount],[PropertyTaxAmount_Currency]=S.[PropertyTaxAmount_Currency],[PropertyTaxRate]=S.[PropertyTaxRate],[PropTaxReceivableId]=S.[PropTaxReceivableId],[ReceivableCodeForAdminFeeId]=S.[ReceivableCodeForAdminFeeId],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableForAdminFeeId]=S.[ReceivableForAdminFeeId],[RemitToId]=S.[RemitToId],[ReportingYear]=S.[ReportingYear],[ReversalPostDate]=S.[ReversalPostDate],[StateId]=S.[StateId],[TaxDistrict]=S.[TaxDistrict],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BillNumber],[CollectorTitle],[ContractId],[CreatedById],[CreatedTime],[DisbursementBatchID],[DueDate],[InstallmentNumber],[InvoiceAmendmentType],[InvoiceComment],[IsActive],[IsManuallyAssessed],[LienDate],[NumberofInstallments],[PostDate],[PropertyTaxAmount_Amount],[PropertyTaxAmount_Currency],[PropertyTaxRate],[PropTaxReceivableId],[ReceivableCodeForAdminFeeId],[ReceivableCodeId],[ReceivableForAdminFeeId],[RemitToId],[ReportingYear],[ReversalPostDate],[StateId],[TaxDistrict])
    VALUES (S.[BillNumber],S.[CollectorTitle],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[DisbursementBatchID],S.[DueDate],S.[InstallmentNumber],S.[InvoiceAmendmentType],S.[InvoiceComment],S.[IsActive],S.[IsManuallyAssessed],S.[LienDate],S.[NumberofInstallments],S.[PostDate],S.[PropertyTaxAmount_Amount],S.[PropertyTaxAmount_Currency],S.[PropertyTaxRate],S.[PropTaxReceivableId],S.[ReceivableCodeForAdminFeeId],S.[ReceivableCodeId],S.[ReceivableForAdminFeeId],S.[RemitToId],S.[ReportingYear],S.[ReversalPostDate],S.[StateId],S.[TaxDistrict])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
