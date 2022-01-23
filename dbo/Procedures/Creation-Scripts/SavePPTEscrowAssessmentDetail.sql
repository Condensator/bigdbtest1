SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePPTEscrowAssessmentDetail]
(
 @val [dbo].[PPTEscrowAssessmentDetail] READONLY
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
MERGE [dbo].[PPTEscrowAssessmentDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CRAccount]=S.[CRAccount],[CRAmount_Amount]=S.[CRAmount_Amount],[CRAmount_Currency]=S.[CRAmount_Currency],[CRDescription]=S.[CRDescription],[DRAccount]=S.[DRAccount],[DRAmount_Amount]=S.[DRAmount_Amount],[DRAmount_Currency]=S.[DRAmount_Currency],[DRDescription]=S.[DRDescription],[EscrowEndBalance_Amount]=S.[EscrowEndBalance_Amount],[EscrowEndBalance_Currency]=S.[EscrowEndBalance_Currency],[GLCreatedTime]=S.[GLCreatedTime],[IsActive]=S.[IsActive],[PostDate]=S.[PostDate],[TransactionType]=S.[TransactionType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CRAccount],[CRAmount_Amount],[CRAmount_Currency],[CRDescription],[CreatedById],[CreatedTime],[DRAccount],[DRAmount_Amount],[DRAmount_Currency],[DRDescription],[EscrowEndBalance_Amount],[EscrowEndBalance_Currency],[GLCreatedTime],[IsActive],[PostDate],[PPTEscrowAssessmentId],[TransactionType])
    VALUES (S.[CRAccount],S.[CRAmount_Amount],S.[CRAmount_Currency],S.[CRDescription],S.[CreatedById],S.[CreatedTime],S.[DRAccount],S.[DRAmount_Amount],S.[DRAmount_Currency],S.[DRDescription],S.[EscrowEndBalance_Amount],S.[EscrowEndBalance_Currency],S.[GLCreatedTime],S.[IsActive],S.[PostDate],S.[PPTEscrowAssessmentId],S.[TransactionType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
