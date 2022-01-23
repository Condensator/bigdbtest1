SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveActivityType]
(
 @val [dbo].[ActivityType] READONLY
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
MERGE [dbo].[ActivityTypes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AllowDuplicate]=S.[AllowDuplicate],[Category]=S.[Category],[CreationAllowed]=S.[CreationAllowed],[DefaultPermission]=S.[DefaultPermission],[DefaultUserGroupId]=S.[DefaultUserGroupId],[DefaultUserId]=S.[DefaultUserId],[Description]=S.[Description],[Duration]=S.[Duration],[EntityTypeId]=S.[EntityTypeId],[IsActive]=S.[IsActive],[IsTrueTask]=S.[IsTrueTask],[IsViewableInCustomerSummary]=S.[IsViewableInCustomerSummary],[IsWorkflowEnabled]=S.[IsWorkflowEnabled],[Name]=S.[Name],[PortfolioId]=S.[PortfolioId],[TransactionTobeInitiatedId]=S.[TransactionTobeInitiatedId],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AllowDuplicate],[Category],[CreatedById],[CreatedTime],[CreationAllowed],[DefaultPermission],[DefaultUserGroupId],[DefaultUserId],[Description],[Duration],[EntityTypeId],[IsActive],[IsTrueTask],[IsViewableInCustomerSummary],[IsWorkflowEnabled],[Name],[PortfolioId],[TransactionTobeInitiatedId],[Type])
    VALUES (S.[AllowDuplicate],S.[Category],S.[CreatedById],S.[CreatedTime],S.[CreationAllowed],S.[DefaultPermission],S.[DefaultUserGroupId],S.[DefaultUserId],S.[Description],S.[Duration],S.[EntityTypeId],S.[IsActive],S.[IsTrueTask],S.[IsViewableInCustomerSummary],S.[IsWorkflowEnabled],S.[Name],S.[PortfolioId],S.[TransactionTobeInitiatedId],S.[Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
