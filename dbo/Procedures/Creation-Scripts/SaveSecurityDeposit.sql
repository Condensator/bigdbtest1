SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSecurityDeposit]
(
 @val [dbo].[SecurityDeposit] READONLY
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
MERGE [dbo].[SecurityDeposits] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActualVATAmount_Amount]=S.[ActualVATAmount_Amount],[ActualVATAmount_Currency]=S.[ActualVATAmount_Currency],[Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[BillToId]=S.[BillToId],[ContractId]=S.[ContractId],[CostCenterId]=S.[CostCenterId],[CountryId]=S.[CountryId],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[DepositType]=S.[DepositType],[DueDate]=S.[DueDate],[EntityType]=S.[EntityType],[HoldEndDate]=S.[HoldEndDate],[HoldToMaturity]=S.[HoldToMaturity],[InstrumentTypeId]=S.[InstrumentTypeId],[InvoiceComment]=S.[InvoiceComment],[InvoiceReceivableGroupingOption]=S.[InvoiceReceivableGroupingOption],[IsActive]=S.[IsActive],[IsCollected]=S.[IsCollected],[IsOwned]=S.[IsOwned],[IsPrivateLabel]=S.[IsPrivateLabel],[IsServiced]=S.[IsServiced],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[LocationId]=S.[LocationId],[NumberOfMonthsRetained]=S.[NumberOfMonthsRetained],[PostDate]=S.[PostDate],[ProjectedVATAmount_Amount]=S.[ProjectedVATAmount_Amount],[ProjectedVATAmount_Currency]=S.[ProjectedVATAmount_Currency],[ReceiptGLTemplateId]=S.[ReceiptGLTemplateId],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableId]=S.[ReceivableId],[RemitToId]=S.[RemitToId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActualVATAmount_Amount],[ActualVATAmount_Currency],[Amount_Amount],[Amount_Currency],[BillToId],[ContractId],[CostCenterId],[CountryId],[CreatedById],[CreatedTime],[CurrencyId],[CustomerId],[DepositType],[DueDate],[EntityType],[HoldEndDate],[HoldToMaturity],[InstrumentTypeId],[InvoiceComment],[InvoiceReceivableGroupingOption],[IsActive],[IsCollected],[IsOwned],[IsPrivateLabel],[IsServiced],[LegalEntityId],[LineofBusinessId],[LocationId],[NumberOfMonthsRetained],[PostDate],[ProjectedVATAmount_Amount],[ProjectedVATAmount_Currency],[ReceiptGLTemplateId],[ReceivableCodeId],[ReceivableId],[RemitToId])
    VALUES (S.[ActualVATAmount_Amount],S.[ActualVATAmount_Currency],S.[Amount_Amount],S.[Amount_Currency],S.[BillToId],S.[ContractId],S.[CostCenterId],S.[CountryId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerId],S.[DepositType],S.[DueDate],S.[EntityType],S.[HoldEndDate],S.[HoldToMaturity],S.[InstrumentTypeId],S.[InvoiceComment],S.[InvoiceReceivableGroupingOption],S.[IsActive],S.[IsCollected],S.[IsOwned],S.[IsPrivateLabel],S.[IsServiced],S.[LegalEntityId],S.[LineofBusinessId],S.[LocationId],S.[NumberOfMonthsRetained],S.[PostDate],S.[ProjectedVATAmount_Amount],S.[ProjectedVATAmount_Currency],S.[ReceiptGLTemplateId],S.[ReceivableCodeId],S.[ReceivableId],S.[RemitToId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
