SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveEscrowAccount]
(
 @val [dbo].[EscrowAccount] READONLY
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
MERGE [dbo].[EscrowAccounts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountStatus]=S.[AccountStatus],[Comments]=S.[Comments],[EscrowAccountNumber]=S.[EscrowAccountNumber],[EscrowAccountOpenDate]=S.[EscrowAccountOpenDate],[EscrowAgentContactName]=S.[EscrowAgentContactName],[EscrowAgentContactPhoneNumber]=S.[EscrowAgentContactPhoneNumber],[EscrowAgentEmail]=S.[EscrowAgentEmail],[EscrowAgentNameCompany]=S.[EscrowAgentNameCompany],[SalesRepName]=S.[SalesRepName],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountStatus],[Comments],[CreatedById],[CreatedTime],[EscrowAccountNumber],[EscrowAccountOpenDate],[EscrowAgentContactName],[EscrowAgentContactPhoneNumber],[EscrowAgentEmail],[EscrowAgentNameCompany],[Id],[SalesRepName])
    VALUES (S.[AccountStatus],S.[Comments],S.[CreatedById],S.[CreatedTime],S.[EscrowAccountNumber],S.[EscrowAccountOpenDate],S.[EscrowAgentContactName],S.[EscrowAgentContactPhoneNumber],S.[EscrowAgentEmail],S.[EscrowAgentNameCompany],S.[Id],S.[SalesRepName])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
