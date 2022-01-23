SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAcceleratedBalanceDetail]
(
 @val [dbo].[AcceleratedBalanceDetail] READONLY
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
MERGE [dbo].[AcceleratedBalanceDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AsofDate]=S.[AsofDate],[Balance_Amount]=S.[Balance_Amount],[Balance_Currency]=S.[Balance_Currency],[BalanceType]=S.[BalanceType],[BusinessUnitId]=S.[BusinessUnitId],[ContractId]=S.[ContractId],[CopyFromAcceleratedBalanceId]=S.[CopyFromAcceleratedBalanceId],[CurrentLegalBalance]=S.[CurrentLegalBalance],[CustomerId]=S.[CustomerId],[DateofDefault]=S.[DateofDefault],[JobStepInstanceId]=S.[JobStepInstanceId],[JudgementId]=S.[JudgementId],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[MaturityDate]=S.[MaturityDate],[Number]=S.[Number],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserId]=S.[UserId]
WHEN NOT MATCHED THEN
	INSERT ([AsofDate],[Balance_Amount],[Balance_Currency],[BalanceType],[BusinessUnitId],[ContractId],[CopyFromAcceleratedBalanceId],[CreatedById],[CreatedTime],[CurrentLegalBalance],[CustomerId],[DateofDefault],[JobStepInstanceId],[JudgementId],[LegalEntityId],[LineofBusinessId],[MaturityDate],[Number],[Status],[UserId])
    VALUES (S.[AsofDate],S.[Balance_Amount],S.[Balance_Currency],S.[BalanceType],S.[BusinessUnitId],S.[ContractId],S.[CopyFromAcceleratedBalanceId],S.[CreatedById],S.[CreatedTime],S.[CurrentLegalBalance],S.[CustomerId],S.[DateofDefault],S.[JobStepInstanceId],S.[JudgementId],S.[LegalEntityId],S.[LineofBusinessId],S.[MaturityDate],S.[Number],S.[Status],S.[UserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
