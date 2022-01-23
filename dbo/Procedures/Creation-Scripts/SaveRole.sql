SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveRole]
(
 @val [dbo].[Role] READONLY
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
MERGE [dbo].[Roles] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[CollectorCapacity]=S.[CollectorCapacity],[DeactivationDate]=S.[DeactivationDate],[DefaultPermission]=S.[DefaultPermission],[Description]=S.[Description],[IsActive]=S.[IsActive],[Name]=S.[Name],[RoleFunctionId]=S.[RoleFunctionId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[ValidationOverrideLevel]=S.[ValidationOverrideLevel]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[CollectorCapacity],[CreatedById],[CreatedTime],[DeactivationDate],[DefaultPermission],[Description],[IsActive],[Name],[RoleFunctionId],[ValidationOverrideLevel])
    VALUES (S.[ActivationDate],S.[CollectorCapacity],S.[CreatedById],S.[CreatedTime],S.[DeactivationDate],S.[DefaultPermission],S.[Description],S.[IsActive],S.[Name],S.[RoleFunctionId],S.[ValidationOverrideLevel])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
