SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ReverseGLDetails]
(
@GLPostingResults ReceivablesGLReversal READONLY,
@PostDate DATETIME,
@CurrentUserId BIGINT,
@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
INSERT INTO ReceivableGLJournals (PostDate,CreatedById,CreatedTime,GLJournalId,ReceivableId ,ReversalGLJournalOfId )
SELECT @PostDate,@CurrentUserId,@CurrentTime,RS.GLJournalId ,RS.EntityId , RS.ReversalGLJournalOfId  FROM @GLPostingResults RS
WHERE RS.IsTaxReceivable = 0;
INSERT INTO ReceivableTaxGLs(PostDate,IsReversal,CreatedById,CreatedTime,GLJournalId,ReceivableTaxId)
SELECT @PostDate,1,@CurrentUserId,@CurrentTime,GLJournalId,EntityId FROM @GLPostingResults
WHERE IsTaxReceivable = 1;
UPDATE R SET IsGLPosted=1 FROM Receivables R
JOIN @GLPostingResults RS ON R.Id = RS.EntityId
WHERE RS.IsTaxReceivable=0;
UPDATE R SET IsGLPosted=1 FROM ReceivableTaxes R
JOIN @GLPostingResults RS ON R.Id = RS.EntityId
WHERE RS.IsTaxReceivable=1;
END

GO
