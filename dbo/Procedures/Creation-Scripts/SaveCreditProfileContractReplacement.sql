SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditProfileContractReplacement]
(
 @val [dbo].[CreditProfileContractReplacement] READONLY
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
MERGE [dbo].[CreditProfileContractReplacements] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractId]=S.[ContractId],[IsActive]=S.[IsActive],[ReplacementAmount_Amount]=S.[ReplacementAmount_Amount],[ReplacementAmount_Currency]=S.[ReplacementAmount_Currency],[RNIAmount_Amount]=S.[RNIAmount_Amount],[RNIAmount_Currency]=S.[RNIAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractId],[CreatedById],[CreatedTime],[CreditProfileId],[IsActive],[ReplacementAmount_Amount],[ReplacementAmount_Currency],[RNIAmount_Amount],[RNIAmount_Currency])
    VALUES (S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CreditProfileId],S.[IsActive],S.[ReplacementAmount_Amount],S.[ReplacementAmount_Currency],S.[RNIAmount_Amount],S.[RNIAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
