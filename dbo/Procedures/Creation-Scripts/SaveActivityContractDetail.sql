SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveActivityContractDetail]
(
 @val [dbo].[ActivityContractDetail] READONLY
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
MERGE [dbo].[ActivityContractDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractId]=S.[ContractId],[FullPayoff]=S.[FullPayoff],[InitiatedTransactionEntityId]=S.[InitiatedTransactionEntityId],[IsActive]=S.[IsActive],[PaymentNumber]=S.[PaymentNumber],[TerminationReason]=S.[TerminationReason],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActivityForCustomerId],[ContractId],[CreatedById],[CreatedTime],[FullPayoff],[InitiatedTransactionEntityId],[IsActive],[PaymentNumber],[TerminationReason])
    VALUES (S.[ActivityForCustomerId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[FullPayoff],S.[InitiatedTransactionEntityId],S.[IsActive],S.[PaymentNumber],S.[TerminationReason])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
