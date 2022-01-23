SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDiscountingWriteDown]
(
 @val [dbo].[DiscountingWriteDown] READONLY
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
MERGE [dbo].[DiscountingWriteDowns] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Comment]=S.[Comment],[DiscountingFinanceId]=S.[DiscountingFinanceId],[DiscountingId]=S.[DiscountingId],[DiscountingWriteDownGLJournalId]=S.[DiscountingWriteDownGLJournalId],[GrossWriteDown_Amount]=S.[GrossWriteDown_Amount],[GrossWriteDown_Currency]=S.[GrossWriteDown_Currency],[IsActive]=S.[IsActive],[IsRecovery]=S.[IsRecovery],[NBVPostAdjustments_Amount]=S.[NBVPostAdjustments_Amount],[NBVPostAdjustments_Currency]=S.[NBVPostAdjustments_Currency],[NetInvestmentWithReserve_Amount]=S.[NetInvestmentWithReserve_Amount],[NetInvestmentWithReserve_Currency]=S.[NetInvestmentWithReserve_Currency],[NetWriteDown_Amount]=S.[NetWriteDown_Amount],[NetWriteDown_Currency]=S.[NetWriteDown_Currency],[PostDate]=S.[PostDate],[RecoveryGLTemplateId]=S.[RecoveryGLTemplateId],[SourceId]=S.[SourceId],[SourceModule]=S.[SourceModule],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WriteDownAmount_Amount]=S.[WriteDownAmount_Amount],[WriteDownAmount_Currency]=S.[WriteDownAmount_Currency],[WriteDownDate]=S.[WriteDownDate],[WriteDownGLTemplateId]=S.[WriteDownGLTemplateId]
WHEN NOT MATCHED THEN
	INSERT ([Comment],[CreatedById],[CreatedTime],[DiscountingFinanceId],[DiscountingId],[DiscountingWriteDownGLJournalId],[GrossWriteDown_Amount],[GrossWriteDown_Currency],[IsActive],[IsRecovery],[NBVPostAdjustments_Amount],[NBVPostAdjustments_Currency],[NetInvestmentWithReserve_Amount],[NetInvestmentWithReserve_Currency],[NetWriteDown_Amount],[NetWriteDown_Currency],[PostDate],[RecoveryGLTemplateId],[SourceId],[SourceModule],[Status],[WriteDownAmount_Amount],[WriteDownAmount_Currency],[WriteDownDate],[WriteDownGLTemplateId])
    VALUES (S.[Comment],S.[CreatedById],S.[CreatedTime],S.[DiscountingFinanceId],S.[DiscountingId],S.[DiscountingWriteDownGLJournalId],S.[GrossWriteDown_Amount],S.[GrossWriteDown_Currency],S.[IsActive],S.[IsRecovery],S.[NBVPostAdjustments_Amount],S.[NBVPostAdjustments_Currency],S.[NetInvestmentWithReserve_Amount],S.[NetInvestmentWithReserve_Currency],S.[NetWriteDown_Amount],S.[NetWriteDown_Currency],S.[PostDate],S.[RecoveryGLTemplateId],S.[SourceId],S.[SourceModule],S.[Status],S.[WriteDownAmount_Amount],S.[WriteDownAmount_Currency],S.[WriteDownDate],S.[WriteDownGLTemplateId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
