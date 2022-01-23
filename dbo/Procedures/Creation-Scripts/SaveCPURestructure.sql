SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPURestructure]
(
 @val [dbo].[CPURestructure] READONLY
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
MERGE [dbo].[CPURestructures] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AtInception]=S.[AtInception],[ContractAmendmentReasonCodeId]=S.[ContractAmendmentReasonCodeId],[CPUContractId]=S.[CPUContractId],[CPUFinanceId]=S.[CPUFinanceId],[Description]=S.[Description],[EffectiveDate]=S.[EffectiveDate],[Name]=S.[Name],[OldCPUFinanceId]=S.[OldCPUFinanceId],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AtInception],[ContractAmendmentReasonCodeId],[CPUContractId],[CPUFinanceId],[CreatedById],[CreatedTime],[Description],[EffectiveDate],[Name],[OldCPUFinanceId],[Status])
    VALUES (S.[AtInception],S.[ContractAmendmentReasonCodeId],S.[CPUContractId],S.[CPUFinanceId],S.[CreatedById],S.[CreatedTime],S.[Description],S.[EffectiveDate],S.[Name],S.[OldCPUFinanceId],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
