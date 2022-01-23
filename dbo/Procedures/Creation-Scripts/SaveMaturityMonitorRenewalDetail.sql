SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveMaturityMonitorRenewalDetail]
(
 @val [dbo].[MaturityMonitorRenewalDetail] READONLY
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
MERGE [dbo].[MaturityMonitorRenewalDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractOptionId]=S.[ContractOptionId],[IsActive]=S.[IsActive],[RenewalAmount_Amount]=S.[RenewalAmount_Amount],[RenewalAmount_Currency]=S.[RenewalAmount_Currency],[RenewalApprovedById]=S.[RenewalApprovedById],[RenewalComment]=S.[RenewalComment],[RenewalDate]=S.[RenewalDate],[RenewalFrequency]=S.[RenewalFrequency],[RenewalTerm]=S.[RenewalTerm],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractOptionId],[CreatedById],[CreatedTime],[IsActive],[MaturityMonitorId],[RenewalAmount_Amount],[RenewalAmount_Currency],[RenewalApprovedById],[RenewalComment],[RenewalDate],[RenewalFrequency],[RenewalTerm])
    VALUES (S.[ContractOptionId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[MaturityMonitorId],S.[RenewalAmount_Amount],S.[RenewalAmount_Currency],S.[RenewalApprovedById],S.[RenewalComment],S.[RenewalDate],S.[RenewalFrequency],S.[RenewalTerm])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
