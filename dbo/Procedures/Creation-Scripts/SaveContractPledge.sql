SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveContractPledge]
(
 @val [dbo].[ContractPledge] READONLY
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
MERGE [dbo].[ContractPledges] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Bank]=S.[Bank],[BankAccountBGN]=S.[BankAccountBGN],[BankAccountEUR]=S.[BankAccountEUR],[BIC]=S.[BIC],[CascoCoverage]=S.[CascoCoverage],[Comment]=S.[Comment],[InterestBaseId]=S.[InterestBaseId],[IsActive]=S.[IsActive],[IsExpired]=S.[IsExpired],[LoanNumberId]=S.[LoanNumberId],[PledgeInFavorOf]=S.[PledgeInFavorOf],[PledgeReceivables]=S.[PledgeReceivables],[PledgeVehicles]=S.[PledgeVehicles],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Bank],[BankAccountBGN],[BankAccountEUR],[BIC],[CascoCoverage],[Comment],[ContractId],[CreatedById],[CreatedTime],[InterestBaseId],[IsActive],[IsExpired],[LoanNumberId],[PledgeInFavorOf],[PledgeReceivables],[PledgeVehicles])
    VALUES (S.[Bank],S.[BankAccountBGN],S.[BankAccountEUR],S.[BIC],S.[CascoCoverage],S.[Comment],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[InterestBaseId],S.[IsActive],S.[IsExpired],S.[LoanNumberId],S.[PledgeInFavorOf],S.[PledgeReceivables],S.[PledgeVehicles])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
