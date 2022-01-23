SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateGLDetailsForPayoffReceivables]
(
@GLPostingResults PayoffReceivablesGLPostingResult READONLY,
@PostDate DATETIME,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON

SELECT * INTO #GLPostingResults FROM @GLPostingResults
CREATE INDEX IX_EntityId ON #GLPostingResults(EntityId) INCLUDE(IsTaxReceivable)

INSERT INTO ReceivableGLJournals (PostDate,CreatedById,CreatedTime,GLJournalId,ReceivableId)
SELECT @PostDate,@CreatedById,@CreatedTime,GLJournalId,EntityId FROM #GLPostingResults
WHERE IsTaxReceivable = 0;
INSERT INTO ReceivableTaxGLs(PostDate,IsReversal,CreatedById,CreatedTime,GLJournalId,ReceivableTaxId)
SELECT @PostDate,0,@CreatedById,@CreatedTime,GLJournalId,EntityId FROM #GLPostingResults
WHERE IsTaxReceivable = 1;
UPDATE R SET IsGLPosted=1 FROM Receivables R
JOIN #GLPostingResults RS ON R.Id = RS.EntityId
WHERE RS.IsTaxReceivable=0;
UPDATE R SET IsGLPosted=1 FROM ReceivableTaxes R
JOIN #GLPostingResults RS ON R.Id = RS.EntityId
WHERE RS.IsTaxReceivable=1;
UPDATE R SET IsGLPosted=1 FROM ReceivableTaxDetails R
JOIN #GLPostingResults RS ON R.ReceivableTaxId = RS.EntityId
WHERE RS.IsTaxReceivable=1;
END

GO
