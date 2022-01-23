SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveMasterConfigDetail]
(
 @val [dbo].[MasterConfigDetail] READONLY
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
MERGE [dbo].[MasterConfigDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CanAddRows]=S.[CanAddRows],[ConfigType]=S.[ConfigType],[CreateTransactionName]=S.[CreateTransactionName],[DynamicFilterConditions]=S.[DynamicFilterConditions],[EditTransactionName]=S.[EditTransactionName],[IsActive]=S.[IsActive],[IsRoot]=S.[IsRoot],[MasterConfigEntityId]=S.[MasterConfigEntityId],[NonEditableColumns]=S.[NonEditableColumns],[ProcessingOrder]=S.[ProcessingOrder],[RowSecurityConditions]=S.[RowSecurityConditions],[SelectorName]=S.[SelectorName],[TransactionScriptName]=S.[TransactionScriptName],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CanAddRows],[ConfigType],[CreatedById],[CreatedTime],[CreateTransactionName],[DynamicFilterConditions],[EditTransactionName],[IsActive],[IsRoot],[MasterConfigEntityId],[MasterConfigId],[NonEditableColumns],[ProcessingOrder],[RowSecurityConditions],[SelectorName],[TransactionScriptName])
    VALUES (S.[CanAddRows],S.[ConfigType],S.[CreatedById],S.[CreatedTime],S.[CreateTransactionName],S.[DynamicFilterConditions],S.[EditTransactionName],S.[IsActive],S.[IsRoot],S.[MasterConfigEntityId],S.[MasterConfigId],S.[NonEditableColumns],S.[ProcessingOrder],S.[RowSecurityConditions],S.[SelectorName],S.[TransactionScriptName])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
