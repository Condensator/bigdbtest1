SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDisbursementRequestPayee]
(
 @val [dbo].[DisbursementRequestPayee] READONLY
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
MERGE [dbo].[DisbursementRequestPayees] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ApprovedAmount_Amount]=S.[ApprovedAmount_Amount],[ApprovedAmount_Currency]=S.[ApprovedAmount_Currency],[IsActive]=S.[IsActive],[PaidAmount_Amount]=S.[PaidAmount_Amount],[PaidAmount_Currency]=S.[PaidAmount_Currency],[PayeeId]=S.[PayeeId],[ReceivablesApplied_Amount]=S.[ReceivablesApplied_Amount],[ReceivablesApplied_Currency]=S.[ReceivablesApplied_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ApprovedAmount_Amount],[ApprovedAmount_Currency],[CreatedById],[CreatedTime],[DisbursementRequestPayableId],[IsActive],[PaidAmount_Amount],[PaidAmount_Currency],[PayeeId],[ReceivablesApplied_Amount],[ReceivablesApplied_Currency])
    VALUES (S.[ApprovedAmount_Amount],S.[ApprovedAmount_Currency],S.[CreatedById],S.[CreatedTime],S.[DisbursementRequestPayableId],S.[IsActive],S.[PaidAmount_Amount],S.[PaidAmount_Currency],S.[PayeeId],S.[ReceivablesApplied_Amount],S.[ReceivablesApplied_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
