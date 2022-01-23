SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptRentSharingDetails_Extract]
(
 @val [dbo].[ReceiptRentSharingDetails_Extract] READONLY
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
MERGE [dbo].[ReceiptRentSharingDetails_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [JobStepInstanceId]=S.[JobStepInstanceId],[PaidPayableAmount]=S.[PaidPayableAmount],[PayableCodeId]=S.[PayableCodeId],[ReceiptId]=S.[ReceiptId],[ReceivableId]=S.[ReceivableId],[RemitToId]=S.[RemitToId],[RentSharingPercentage]=S.[RentSharingPercentage],[SourceType]=S.[SourceType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId],[WithholdingTaxRate]=S.[WithholdingTaxRate]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[JobStepInstanceId],[PaidPayableAmount],[PayableCodeId],[ReceiptId],[ReceivableId],[RemitToId],[RentSharingPercentage],[SourceType],[VendorId],[WithholdingTaxRate])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[JobStepInstanceId],S.[PaidPayableAmount],S.[PayableCodeId],S.[ReceiptId],S.[ReceivableId],S.[RemitToId],S.[RentSharingPercentage],S.[SourceType],S.[VendorId],S.[WithholdingTaxRate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
