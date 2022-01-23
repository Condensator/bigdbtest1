SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditApplicationAdditionalCharge]
(
 @val [dbo].[CreditApplicationAdditionalCharge] READONLY
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
MERGE [dbo].[CreditApplicationAdditionalCharges] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdditionalChargeId]=S.[AdditionalChargeId],[AmountExclVAT_Amount]=S.[AmountExclVAT_Amount],[AmountExclVAT_Currency]=S.[AmountExclVAT_Currency],[AmountInclVAT_Amount]=S.[AmountInclVAT_Amount],[AmountInclVAT_Currency]=S.[AmountInclVAT_Currency],[BlendedItemCodeId]=S.[BlendedItemCodeId],[CreditApplicationEquipmentDetailId]=S.[CreditApplicationEquipmentDetailId],[FeeDetailId]=S.[FeeDetailId],[FeeId]=S.[FeeId],[IncludeInAPR]=S.[IncludeInAPR],[IsPopulatedFromCreditApplicationEquipment]=S.[IsPopulatedFromCreditApplicationEquipment],[IsVAT]=S.[IsVAT],[PayableCodeId]=S.[PayableCodeId],[ReceivableCodeId]=S.[ReceivableCodeId],[SundryOrBlendedItem]=S.[SundryOrBlendedItem],[SundryType]=S.[SundryType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdditionalChargeId],[AmountExclVAT_Amount],[AmountExclVAT_Currency],[AmountInclVAT_Amount],[AmountInclVAT_Currency],[BlendedItemCodeId],[CreatedById],[CreatedTime],[CreditApplicationEquipmentDetailId],[CreditApplicationId],[FeeDetailId],[FeeId],[IncludeInAPR],[IsPopulatedFromCreditApplicationEquipment],[IsVAT],[PayableCodeId],[ReceivableCodeId],[SundryOrBlendedItem],[SundryType])
    VALUES (S.[AdditionalChargeId],S.[AmountExclVAT_Amount],S.[AmountExclVAT_Currency],S.[AmountInclVAT_Amount],S.[AmountInclVAT_Currency],S.[BlendedItemCodeId],S.[CreatedById],S.[CreatedTime],S.[CreditApplicationEquipmentDetailId],S.[CreditApplicationId],S.[FeeDetailId],S.[FeeId],S.[IncludeInAPR],S.[IsPopulatedFromCreditApplicationEquipment],S.[IsVAT],S.[PayableCodeId],S.[ReceivableCodeId],S.[SundryOrBlendedItem],S.[SundryType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
