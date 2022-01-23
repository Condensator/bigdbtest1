SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLegalReliefProofOfClaim]
(
 @val [dbo].[LegalReliefProofOfClaim] READONLY
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
MERGE [dbo].[LegalReliefProofOfClaims] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Active]=S.[Active],[ClaimNumber]=S.[ClaimNumber],[Date]=S.[Date],[FilingDate]=S.[FilingDate],[OriginalPOCId]=S.[OriginalPOCId],[StateId]=S.[StateId],[Status]=S.[Status],[TotalAmount_Amount]=S.[TotalAmount_Amount],[TotalAmount_Currency]=S.[TotalAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Active],[ClaimNumber],[CreatedById],[CreatedTime],[Date],[FilingDate],[LegalReliefId],[OriginalPOCId],[StateId],[Status],[TotalAmount_Amount],[TotalAmount_Currency])
    VALUES (S.[Active],S.[ClaimNumber],S.[CreatedById],S.[CreatedTime],S.[Date],S.[FilingDate],S.[LegalReliefId],S.[OriginalPOCId],S.[StateId],S.[Status],S.[TotalAmount_Amount],S.[TotalAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
