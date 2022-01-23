SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditProfileReceivableVATInfo]
(
 @val [dbo].[CreditProfileReceivableVATInfo] READONLY
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
MERGE [dbo].[CreditProfileReceivableVATInfoes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DueDate]=S.[DueDate],[IsActive]=S.[IsActive],[ReceivableAmount_Amount]=S.[ReceivableAmount_Amount],[ReceivableAmount_Currency]=S.[ReceivableAmount_Currency],[ReceivableType]=S.[ReceivableType],[TotalAmount_Amount]=S.[TotalAmount_Amount],[TotalAmount_Currency]=S.[TotalAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VATAmount_Amount]=S.[VATAmount_Amount],[VATAmount_Currency]=S.[VATAmount_Currency]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[CreditApprovedStructureId],[DueDate],[IsActive],[ReceivableAmount_Amount],[ReceivableAmount_Currency],[ReceivableType],[TotalAmount_Amount],[TotalAmount_Currency],[VATAmount_Amount],[VATAmount_Currency])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[CreditApprovedStructureId],S.[DueDate],S.[IsActive],S.[ReceivableAmount_Amount],S.[ReceivableAmount_Currency],S.[ReceivableType],S.[TotalAmount_Amount],S.[TotalAmount_Currency],S.[VATAmount_Amount],S.[VATAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
