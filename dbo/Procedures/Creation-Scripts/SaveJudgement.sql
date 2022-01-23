SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveJudgement]
(
 @val [dbo].[Judgement] READONLY
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
MERGE [dbo].[Judgements] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmendedAmount_Amount]=S.[AmendedAmount_Amount],[AmendedAmount_Currency]=S.[AmendedAmount_Currency],[AmendedDate]=S.[AmendedDate],[Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[Comments]=S.[Comments],[ContractId]=S.[ContractId],[CourtFilingActionId]=S.[CourtFilingActionId],[CourtFilingId]=S.[CourtFilingId],[CourtId]=S.[CourtId],[ExpirationDate]=S.[ExpirationDate],[Fees_Amount]=S.[Fees_Amount],[Fees_Currency]=S.[Fees_Currency],[InterestGrantedFromDate]=S.[InterestGrantedFromDate],[InterestRate]=S.[InterestRate],[IsActive]=S.[IsActive],[IsAmended]=S.[IsAmended],[IsAmendedAmountSettled]=S.[IsAmendedAmountSettled],[IsDomesticated]=S.[IsDomesticated],[JudgementDate]=S.[JudgementDate],[JudgementNumber]=S.[JudgementNumber],[RenewalDate]=S.[RenewalDate],[Status]=S.[Status],[TotalAmount_Amount]=S.[TotalAmount_Amount],[TotalAmount_Currency]=S.[TotalAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AmendedAmount_Amount],[AmendedAmount_Currency],[AmendedDate],[Amount_Amount],[Amount_Currency],[Comments],[ContractId],[CourtFilingActionId],[CourtFilingId],[CourtId],[CreatedById],[CreatedTime],[ExpirationDate],[Fees_Amount],[Fees_Currency],[InterestGrantedFromDate],[InterestRate],[IsActive],[IsAmended],[IsAmendedAmountSettled],[IsDomesticated],[JudgementDate],[JudgementNumber],[RenewalDate],[Status],[TotalAmount_Amount],[TotalAmount_Currency])
    VALUES (S.[AmendedAmount_Amount],S.[AmendedAmount_Currency],S.[AmendedDate],S.[Amount_Amount],S.[Amount_Currency],S.[Comments],S.[ContractId],S.[CourtFilingActionId],S.[CourtFilingId],S.[CourtId],S.[CreatedById],S.[CreatedTime],S.[ExpirationDate],S.[Fees_Amount],S.[Fees_Currency],S.[InterestGrantedFromDate],S.[InterestRate],S.[IsActive],S.[IsAmended],S.[IsAmendedAmountSettled],S.[IsDomesticated],S.[JudgementDate],S.[JudgementNumber],S.[RenewalDate],S.[Status],S.[TotalAmount_Amount],S.[TotalAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
