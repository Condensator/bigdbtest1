SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDealTeamDetails]
(
 @val [dbo].[DealTeamDetails] READONLY
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
MERGE [dbo].[DealTeamDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Assign]=S.[Assign],[AssignedDate]=S.[AssignedDate],[DisplayInDashboard]=S.[DisplayInDashboard],[Primary]=S.[Primary],[RoleFunctionId]=S.[RoleFunctionId],[UnassignedDate]=S.[UnassignedDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserId]=S.[UserId]
WHEN NOT MATCHED THEN
	INSERT ([Assign],[AssignedDate],[CreatedById],[CreatedTime],[DealTeamId],[DisplayInDashboard],[Primary],[RoleFunctionId],[UnassignedDate],[UserId])
    VALUES (S.[Assign],S.[AssignedDate],S.[CreatedById],S.[CreatedTime],S.[DealTeamId],S.[DisplayInDashboard],S.[Primary],S.[RoleFunctionId],S.[UnassignedDate],S.[UserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
