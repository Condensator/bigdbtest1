SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivableForTransferPaymentDetail]
(
 @val [dbo].[ReceivableForTransferPaymentDetail] READONLY
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
MERGE [dbo].[ReceivableForTransferPaymentDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[ContractId]=S.[ContractId],[DueDate]=S.[DueDate],[IsActive]=S.[IsActive],[IsResidualPayment]=S.[IsResidualPayment],[PaymentAmount_Amount]=S.[PaymentAmount_Amount],[PaymentAmount_Currency]=S.[PaymentAmount_Currency],[PaymentScheduleId]=S.[PaymentScheduleId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[ContractId],[CreatedById],[CreatedTime],[DueDate],[IsActive],[IsResidualPayment],[PaymentAmount_Amount],[PaymentAmount_Currency],[PaymentScheduleId],[ReceivableForTransferFundingSourceId])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[DueDate],S.[IsActive],S.[IsResidualPayment],S.[PaymentAmount_Amount],S.[PaymentAmount_Currency],S.[PaymentScheduleId],S.[ReceivableForTransferFundingSourceId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
