SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveMT940File_Dump]
(
 @val [dbo].[MT940File_Dump] READONLY
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
MERGE [dbo].[MT940File_Dump] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountIdentification]=S.[AccountIdentification],[ClosingAvailableBalance_Amount]=S.[ClosingAvailableBalance_Amount],[ClosingAvailableBalance_Currency]=S.[ClosingAvailableBalance_Currency],[ClosingAvailableBalance_DC]=S.[ClosingAvailableBalance_DC],[ClosingAvailableBalanceAsOf]=S.[ClosingAvailableBalanceAsOf],[ClosingBalance_Amount]=S.[ClosingBalance_Amount],[ClosingBalance_Currency]=S.[ClosingBalance_Currency],[ClosingBalance_DC]=S.[ClosingBalance_DC],[ClosingBalanceAsOf]=S.[ClosingBalanceAsOf],[FileName]=S.[FileName],[GUID]=S.[GUID],[InformationToOwner]=S.[InformationToOwner],[IsValid]=S.[IsValid],[JobStepInstanceId]=S.[JobStepInstanceId],[OpeningBalance_Amount]=S.[OpeningBalance_Amount],[OpeningBalance_Currency]=S.[OpeningBalance_Currency],[OpeningBalance_DC]=S.[OpeningBalance_DC],[OpeningBalanceAsOf]=S.[OpeningBalanceAsOf],[RelatedReference]=S.[RelatedReference],[SequenceNumber]=S.[SequenceNumber],[StatementNumber]=S.[StatementNumber],[Trans_DC]=S.[Trans_DC],[TransactionAmount_Amount]=S.[TransactionAmount_Amount],[TransactionAmount_Currency]=S.[TransactionAmount_Currency],[TransactionReferenceNumber]=S.[TransactionReferenceNumber],[TransBankReferenceNumber]=S.[TransBankReferenceNumber],[TransCustomerReference]=S.[TransCustomerReference],[TransEntryDate]=S.[TransEntryDate],[TransFundsCode]=S.[TransFundsCode],[TransSupplementaryDetails]=S.[TransSupplementaryDetails],[TransTypeIdCode]=S.[TransTypeIdCode],[TransValueDate]=S.[TransValueDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountIdentification],[ClosingAvailableBalance_Amount],[ClosingAvailableBalance_Currency],[ClosingAvailableBalance_DC],[ClosingAvailableBalanceAsOf],[ClosingBalance_Amount],[ClosingBalance_Currency],[ClosingBalance_DC],[ClosingBalanceAsOf],[CreatedById],[CreatedTime],[FileName],[GUID],[InformationToOwner],[IsValid],[JobStepInstanceId],[OpeningBalance_Amount],[OpeningBalance_Currency],[OpeningBalance_DC],[OpeningBalanceAsOf],[RelatedReference],[SequenceNumber],[StatementNumber],[Trans_DC],[TransactionAmount_Amount],[TransactionAmount_Currency],[TransactionReferenceNumber],[TransBankReferenceNumber],[TransCustomerReference],[TransEntryDate],[TransFundsCode],[TransSupplementaryDetails],[TransTypeIdCode],[TransValueDate])
    VALUES (S.[AccountIdentification],S.[ClosingAvailableBalance_Amount],S.[ClosingAvailableBalance_Currency],S.[ClosingAvailableBalance_DC],S.[ClosingAvailableBalanceAsOf],S.[ClosingBalance_Amount],S.[ClosingBalance_Currency],S.[ClosingBalance_DC],S.[ClosingBalanceAsOf],S.[CreatedById],S.[CreatedTime],S.[FileName],S.[GUID],S.[InformationToOwner],S.[IsValid],S.[JobStepInstanceId],S.[OpeningBalance_Amount],S.[OpeningBalance_Currency],S.[OpeningBalance_DC],S.[OpeningBalanceAsOf],S.[RelatedReference],S.[SequenceNumber],S.[StatementNumber],S.[Trans_DC],S.[TransactionAmount_Amount],S.[TransactionAmount_Currency],S.[TransactionReferenceNumber],S.[TransBankReferenceNumber],S.[TransCustomerReference],S.[TransEntryDate],S.[TransFundsCode],S.[TransSupplementaryDetails],S.[TransTypeIdCode],S.[TransValueDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
