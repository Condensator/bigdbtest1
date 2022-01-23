SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanIncomeAmortJobExtract]
(
 @val [dbo].[LoanIncomeAmortJobExtract] READONLY
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
MERGE [dbo].[LoanIncomeAmortJobExtracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractId]=S.[ContractId],[InvoiceLeadDays]=S.[InvoiceLeadDays],[IsSubmitted]=S.[IsSubmitted],[JobInstanceId]=S.[JobInstanceId],[LegalEntityId]=S.[LegalEntityId],[LoanFinanceId]=S.[LoanFinanceId],[SequenceNumber]=S.[SequenceNumber],[TaskChunkServiceInstanceId]=S.[TaskChunkServiceInstanceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractId],[CreatedById],[CreatedTime],[InvoiceLeadDays],[IsSubmitted],[JobInstanceId],[LegalEntityId],[LoanFinanceId],[SequenceNumber],[TaskChunkServiceInstanceId])
    VALUES (S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[InvoiceLeadDays],S.[IsSubmitted],S.[JobInstanceId],S.[LegalEntityId],S.[LoanFinanceId],S.[SequenceNumber],S.[TaskChunkServiceInstanceId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
