SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeaseFinanceAdditionalCharge]
(
 @val [dbo].[LeaseFinanceAdditionalCharge] READONLY
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
MERGE [dbo].[LeaseFinanceAdditionalCharges] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdditionalChargeId]=S.[AdditionalChargeId],[AdditionalChargeLeaseAssetId]=S.[AdditionalChargeLeaseAssetId],[DueDate]=S.[DueDate],[GracePeriodinMonths]=S.[GracePeriodinMonths],[IsAssetBased]=S.[IsAssetBased],[IsIncludeinAPR]=S.[IsIncludeinAPR],[IsRentalBased]=S.[IsRentalBased],[IsVatable]=S.[IsVatable],[LeaseAssetId]=S.[LeaseAssetId],[PayableAmount_Amount]=S.[PayableAmount_Amount],[PayableAmount_Currency]=S.[PayableAmount_Currency],[PayableCodeId]=S.[PayableCodeId],[ReceivableAmountInclVAT_Amount]=S.[ReceivableAmountInclVAT_Amount],[ReceivableAmountInclVAT_Currency]=S.[ReceivableAmountInclVAT_Currency],[RecurringSundryId]=S.[RecurringSundryId],[RemitToId]=S.[RemitToId],[SundryId]=S.[SundryId],[SundryType]=S.[SundryType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([AdditionalChargeId],[AdditionalChargeLeaseAssetId],[CreatedById],[CreatedTime],[DueDate],[GracePeriodinMonths],[IsAssetBased],[IsIncludeinAPR],[IsRentalBased],[IsVatable],[LeaseAssetId],[LeaseFinanceId],[PayableAmount_Amount],[PayableAmount_Currency],[PayableCodeId],[ReceivableAmountInclVAT_Amount],[ReceivableAmountInclVAT_Currency],[RecurringSundryId],[RemitToId],[SundryId],[SundryType],[VendorId])
    VALUES (S.[AdditionalChargeId],S.[AdditionalChargeLeaseAssetId],S.[CreatedById],S.[CreatedTime],S.[DueDate],S.[GracePeriodinMonths],S.[IsAssetBased],S.[IsIncludeinAPR],S.[IsRentalBased],S.[IsVatable],S.[LeaseAssetId],S.[LeaseFinanceId],S.[PayableAmount_Amount],S.[PayableAmount_Currency],S.[PayableCodeId],S.[ReceivableAmountInclVAT_Amount],S.[ReceivableAmountInclVAT_Currency],S.[RecurringSundryId],S.[RemitToId],S.[SundryId],S.[SundryType],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
