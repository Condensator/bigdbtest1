SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReAccrualContract]
(
 @val [dbo].[ReAccrualContract] READONLY
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
MERGE [dbo].[ReAccrualContracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingDate]=S.[AccountingDate],[ContractId]=S.[ContractId],[IsActive]=S.[IsActive],[LastIncomeUpdateDate]=S.[LastIncomeUpdateDate],[LastReceiptDate]=S.[LastReceiptDate],[NBV_Amount]=S.[NBV_Amount],[NBV_Currency]=S.[NBV_Currency],[NBVWithBlended_Amount]=S.[NBVWithBlended_Amount],[NBVWithBlended_Currency]=S.[NBVWithBlended_Currency],[NonAccrualDate]=S.[NonAccrualDate],[ReAccrualDate]=S.[ReAccrualDate],[ResumeBilling]=S.[ResumeBilling],[SuspendedIncome_Amount]=S.[SuspendedIncome_Amount],[SuspendedIncome_Currency]=S.[SuspendedIncome_Currency],[TotalOutstandingAR_Amount]=S.[TotalOutstandingAR_Amount],[TotalOutstandingAR_Currency]=S.[TotalOutstandingAR_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountingDate],[ContractId],[CreatedById],[CreatedTime],[IsActive],[LastIncomeUpdateDate],[LastReceiptDate],[NBV_Amount],[NBV_Currency],[NBVWithBlended_Amount],[NBVWithBlended_Currency],[NonAccrualDate],[ReAccrualDate],[ReAccrualId],[ResumeBilling],[SuspendedIncome_Amount],[SuspendedIncome_Currency],[TotalOutstandingAR_Amount],[TotalOutstandingAR_Currency])
    VALUES (S.[AccountingDate],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[LastIncomeUpdateDate],S.[LastReceiptDate],S.[NBV_Amount],S.[NBV_Currency],S.[NBVWithBlended_Amount],S.[NBVWithBlended_Currency],S.[NonAccrualDate],S.[ReAccrualDate],S.[ReAccrualId],S.[ResumeBilling],S.[SuspendedIncome_Amount],S.[SuspendedIncome_Currency],S.[TotalOutstandingAR_Amount],S.[TotalOutstandingAR_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
