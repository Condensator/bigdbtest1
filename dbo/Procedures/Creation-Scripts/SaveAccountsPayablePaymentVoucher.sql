SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAccountsPayablePaymentVoucher]
(
 @val [dbo].[AccountsPayablePaymentVoucher] READONLY
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
MERGE [dbo].[AccountsPayablePaymentVouchers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [IsActive]=S.[IsActive],[IsManual]=S.[IsManual],[OverNightRequired]=S.[OverNightRequired],[PaymentVoucherId]=S.[PaymentVoucherId],[RequestedDate]=S.[RequestedDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountsPayablePaymentId],[CreatedById],[CreatedTime],[IsActive],[IsManual],[OverNightRequired],[PaymentVoucherId],[RequestedDate])
    VALUES (S.[AccountsPayablePaymentId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsManual],S.[OverNightRequired],S.[PaymentVoucherId],S.[RequestedDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
