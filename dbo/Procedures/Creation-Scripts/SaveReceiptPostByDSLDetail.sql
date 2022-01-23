SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptPostByDSLDetail]
(
 @val [dbo].[ReceiptPostByDSLDetail] READONLY
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
MERGE [dbo].[ReceiptPostByDSLDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccruedInterest_Amount]=S.[AccruedInterest_Amount],[AccruedInterest_Currency]=S.[AccruedInterest_Currency],[ContractId]=S.[ContractId],[InterestAmount_Amount]=S.[InterestAmount_Amount],[InterestAmount_Currency]=S.[InterestAmount_Currency],[InterestRemaining_Amount]=S.[InterestRemaining_Amount],[InterestRemaining_Currency]=S.[InterestRemaining_Currency],[IsActive]=S.[IsActive],[PrincipalAmount_Amount]=S.[PrincipalAmount_Amount],[PrincipalAmount_Currency]=S.[PrincipalAmount_Currency],[PrincipalBalance_Amount]=S.[PrincipalBalance_Amount],[PrincipalBalance_Currency]=S.[PrincipalBalance_Currency],[PrincipalRemaining_Amount]=S.[PrincipalRemaining_Amount],[PrincipalRemaining_Currency]=S.[PrincipalRemaining_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpdateRunTillDate]=S.[UpdateRunTillDate]
WHEN NOT MATCHED THEN
	INSERT ([AccruedInterest_Amount],[AccruedInterest_Currency],[ContractId],[CreatedById],[CreatedTime],[InterestAmount_Amount],[InterestAmount_Currency],[InterestRemaining_Amount],[InterestRemaining_Currency],[IsActive],[PrincipalAmount_Amount],[PrincipalAmount_Currency],[PrincipalBalance_Amount],[PrincipalBalance_Currency],[PrincipalRemaining_Amount],[PrincipalRemaining_Currency],[ReceiptId],[UpdateRunTillDate])
    VALUES (S.[AccruedInterest_Amount],S.[AccruedInterest_Currency],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[InterestAmount_Amount],S.[InterestAmount_Currency],S.[InterestRemaining_Amount],S.[InterestRemaining_Currency],S.[IsActive],S.[PrincipalAmount_Amount],S.[PrincipalAmount_Currency],S.[PrincipalBalance_Amount],S.[PrincipalBalance_Currency],S.[PrincipalRemaining_Amount],S.[PrincipalRemaining_Currency],S.[ReceiptId],S.[UpdateRunTillDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
