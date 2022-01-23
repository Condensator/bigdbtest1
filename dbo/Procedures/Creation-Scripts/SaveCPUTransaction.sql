SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPUTransaction]
(
 @val [dbo].[CPUTransaction] READONLY
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
MERGE [dbo].[CPUTransactions] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CPUContractId]=S.[CPUContractId],[CPUFinanceId]=S.[CPUFinanceId],[Date]=S.[Date],[InActiveReason]=S.[InActiveReason],[IsActive]=S.[IsActive],[ReferenceNumber]=S.[ReferenceNumber],[TransactionType]=S.[TransactionType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CPUContractId],[CPUFinanceId],[CreatedById],[CreatedTime],[Date],[InActiveReason],[IsActive],[ReferenceNumber],[TransactionType])
    VALUES (S.[CPUContractId],S.[CPUFinanceId],S.[CreatedById],S.[CreatedTime],S.[Date],S.[InActiveReason],S.[IsActive],S.[ReferenceNumber],S.[TransactionType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
