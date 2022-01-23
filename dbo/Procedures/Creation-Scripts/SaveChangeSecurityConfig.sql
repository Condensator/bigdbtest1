SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveChangeSecurityConfig]
(
 @val [dbo].[ChangeSecurityConfig] READONLY
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
MERGE [dbo].[ChangeSecurityConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountLockoutDurationInMins]=S.[AccountLockoutDurationInMins],[AccountLockoutThreshold]=S.[AccountLockoutThreshold],[ApprovalStatus]=S.[ApprovalStatus],[MaxPasswordAgeInDays]=S.[MaxPasswordAgeInDays],[MinPasswordAgeInDays]=S.[MinPasswordAgeInDays],[MinPasswordLength]=S.[MinPasswordLength],[NoOfSecurityQuestions]=S.[NoOfSecurityQuestions],[PasswordHistoryCount]=S.[PasswordHistoryCount],[ShowTracer]=S.[ShowTracer],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountLockoutDurationInMins],[AccountLockoutThreshold],[ApprovalStatus],[CreatedById],[CreatedTime],[MaxPasswordAgeInDays],[MinPasswordAgeInDays],[MinPasswordLength],[NoOfSecurityQuestions],[PasswordHistoryCount],[ShowTracer])
    VALUES (S.[AccountLockoutDurationInMins],S.[AccountLockoutThreshold],S.[ApprovalStatus],S.[CreatedById],S.[CreatedTime],S.[MaxPasswordAgeInDays],S.[MinPasswordAgeInDays],S.[MinPasswordLength],S.[NoOfSecurityQuestions],S.[PasswordHistoryCount],S.[ShowTracer])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
