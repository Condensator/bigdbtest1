SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveUnallocatedRefund]
(
 @val [dbo].[UnallocatedRefund] READONLY
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
MERGE [dbo].[UnallocatedRefunds] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountToClear_Amount]=S.[AmountToClear_Amount],[AmountToClear_Currency]=S.[AmountToClear_Currency],[Comment]=S.[Comment],[ContractId]=S.[ContractId],[CostCenterId]=S.[CostCenterId],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[DiscountingId]=S.[DiscountingId],[EntityType]=S.[EntityType],[InstrumentTypeId]=S.[InstrumentTypeId],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[Memo]=S.[Memo],[PayableCodeId]=S.[PayableCodeId],[PayableDate]=S.[PayableDate],[PayableRemitToId]=S.[PayableRemitToId],[PostDate]=S.[PostDate],[ReceiptId]=S.[ReceiptId],[ReversalPostDate]=S.[ReversalPostDate],[Status]=S.[Status],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId],[WithholdingTaxRate]=S.[WithholdingTaxRate]
WHEN NOT MATCHED THEN
	INSERT ([AmountToClear_Amount],[AmountToClear_Currency],[Comment],[ContractId],[CostCenterId],[CreatedById],[CreatedTime],[CurrencyId],[CustomerId],[DiscountingId],[EntityType],[InstrumentTypeId],[LegalEntityId],[LineofBusinessId],[Memo],[PayableCodeId],[PayableDate],[PayableRemitToId],[PostDate],[ReceiptId],[ReversalPostDate],[Status],[Type],[VendorId],[WithholdingTaxRate])
    VALUES (S.[AmountToClear_Amount],S.[AmountToClear_Currency],S.[Comment],S.[ContractId],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerId],S.[DiscountingId],S.[EntityType],S.[InstrumentTypeId],S.[LegalEntityId],S.[LineofBusinessId],S.[Memo],S.[PayableCodeId],S.[PayableDate],S.[PayableRemitToId],S.[PostDate],S.[ReceiptId],S.[ReversalPostDate],S.[Status],S.[Type],S.[VendorId],S.[WithholdingTaxRate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
