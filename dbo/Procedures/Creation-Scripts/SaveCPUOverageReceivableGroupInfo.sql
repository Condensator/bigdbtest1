SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPUOverageReceivableGroupInfo]
(
 @val [dbo].[CPUOverageReceivableGroupInfo] READONLY
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
MERGE [dbo].[CPUOverageReceivableGroupInfoes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BaseAllowance]=S.[BaseAllowance],[BeginPeriodDate]=S.[BeginPeriodDate],[EndPeriodDate]=S.[EndPeriodDate],[OverageAllowance]=S.[OverageAllowance],[Tier]=S.[Tier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BaseAllowance],[BeginPeriodDate],[CreatedById],[CreatedTime],[EndPeriodDate],[OverageAllowance],[Tier])
    VALUES (S.[BaseAllowance],S.[BeginPeriodDate],S.[CreatedById],S.[CreatedTime],S.[EndPeriodDate],S.[OverageAllowance],S.[Tier])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
