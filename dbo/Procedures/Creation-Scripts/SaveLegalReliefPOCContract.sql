SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLegalReliefPOCContract]
(
 @val [dbo].[LegalReliefPOCContract] READONLY
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
MERGE [dbo].[LegalReliefPOCContracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcceleratedBalanceDetailId]=S.[AcceleratedBalanceDetailId],[Active]=S.[Active],[Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[ContractId]=S.[ContractId],[Include]=S.[Include],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcceleratedBalanceDetailId],[Active],[Amount_Amount],[Amount_Currency],[ContractId],[CreatedById],[CreatedTime],[Include],[LegalReliefProofOfClaimId])
    VALUES (S.[AcceleratedBalanceDetailId],S.[Active],S.[Amount_Amount],S.[Amount_Currency],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[Include],S.[LegalReliefProofOfClaimId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
