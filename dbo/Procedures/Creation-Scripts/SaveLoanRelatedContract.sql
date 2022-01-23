SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanRelatedContract]
(
 @val [dbo].[LoanRelatedContract] READONLY
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
MERGE [dbo].[LoanRelatedContracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractId]=S.[ContractId],[IsActive]=S.[IsActive],[IsInclude]=S.[IsInclude],[IsParent]=S.[IsParent],[MasterDate]=S.[MasterDate],[ReasonCode]=S.[ReasonCode],[ScheduleDate]=S.[ScheduleDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractId],[CreatedById],[CreatedTime],[IsActive],[IsInclude],[IsParent],[LoanFinanceId],[MasterDate],[ReasonCode],[ScheduleDate])
    VALUES (S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsInclude],S.[IsParent],S.[LoanFinanceId],S.[MasterDate],S.[ReasonCode],S.[ScheduleDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
