SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveNonAccrualContract]
(
 @val [dbo].[NonAccrualContract] READONLY
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
MERGE [dbo].[NonAccrualContracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingDate]=S.[AccountingDate],[BillingSuppressed]=S.[BillingSuppressed],[ContractId]=S.[ContractId],[DeferredRentalIncomeReclass_Amount]=S.[DeferredRentalIncomeReclass_Amount],[DeferredRentalIncomeReclass_Currency]=S.[DeferredRentalIncomeReclass_Currency],[DoubtfulCollectability]=S.[DoubtfulCollectability],[IncomeRecognizedAfterNonAccrual_Amount]=S.[IncomeRecognizedAfterNonAccrual_Amount],[IncomeRecognizedAfterNonAccrual_Currency]=S.[IncomeRecognizedAfterNonAccrual_Currency],[IsActive]=S.[IsActive],[IsNonAccrualApproved]=S.[IsNonAccrualApproved],[LastIncomeUpdateDate]=S.[LastIncomeUpdateDate],[LastReceiptDate]=S.[LastReceiptDate],[NBV_Amount]=S.[NBV_Amount],[NBV_Currency]=S.[NBV_Currency],[NBVWithBlended_Amount]=S.[NBVWithBlended_Amount],[NBVWithBlended_Currency]=S.[NBVWithBlended_Currency],[NonAccrualDate]=S.[NonAccrualDate],[PostDate]=S.[PostDate],[TotalOutstandingAR_Amount]=S.[TotalOutstandingAR_Amount],[TotalOutstandingAR_Currency]=S.[TotalOutstandingAR_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountingDate],[BillingSuppressed],[ContractId],[CreatedById],[CreatedTime],[DeferredRentalIncomeReclass_Amount],[DeferredRentalIncomeReclass_Currency],[DoubtfulCollectability],[IncomeRecognizedAfterNonAccrual_Amount],[IncomeRecognizedAfterNonAccrual_Currency],[IsActive],[IsNonAccrualApproved],[LastIncomeUpdateDate],[LastReceiptDate],[NBV_Amount],[NBV_Currency],[NBVWithBlended_Amount],[NBVWithBlended_Currency],[NonAccrualDate],[NonAccrualId],[PostDate],[TotalOutstandingAR_Amount],[TotalOutstandingAR_Currency])
    VALUES (S.[AccountingDate],S.[BillingSuppressed],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[DeferredRentalIncomeReclass_Amount],S.[DeferredRentalIncomeReclass_Currency],S.[DoubtfulCollectability],S.[IncomeRecognizedAfterNonAccrual_Amount],S.[IncomeRecognizedAfterNonAccrual_Currency],S.[IsActive],S.[IsNonAccrualApproved],S.[LastIncomeUpdateDate],S.[LastReceiptDate],S.[NBV_Amount],S.[NBV_Currency],S.[NBVWithBlended_Amount],S.[NBVWithBlended_Currency],S.[NonAccrualDate],S.[NonAccrualId],S.[PostDate],S.[TotalOutstandingAR_Amount],S.[TotalOutstandingAR_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
