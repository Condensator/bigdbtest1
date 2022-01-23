SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveEmployeesAssignedToBranch]
(
 @val [dbo].[EmployeesAssignedToBranch] READONLY
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
MERGE [dbo].[EmployeesAssignedToBranches] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[DeactivationDate]=S.[DeactivationDate],[EmployeeId]=S.[EmployeeId],[IsActive]=S.[IsActive],[IsPrimary]=S.[IsPrimary],[RoleFunctionId]=S.[RoleFunctionId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[BranchId],[CreatedById],[CreatedTime],[DeactivationDate],[EmployeeId],[IsActive],[IsPrimary],[RoleFunctionId])
    VALUES (S.[ActivationDate],S.[BranchId],S.[CreatedById],S.[CreatedTime],S.[DeactivationDate],S.[EmployeeId],S.[IsActive],S.[IsPrimary],S.[RoleFunctionId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
