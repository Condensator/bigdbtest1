SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreateNewPayables]
(
@NewPayableInfo NewPayableInfo READONLY,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET(7)
)
AS
SET NOCOUNT ON;
CREATE TABLE #NewPayable
(
[Key] BigInt,
[Id] BIGINT
)
MERGE Payables
USING @NewPayableInfo newPayable
ON 1 = 0
WHEN NOT MATCHED
THEN
INSERT
([EntityType]
,[EntityId]
,[Amount_Amount]
,[Amount_Currency]
,[Balance_Amount]
,[Balance_Currency]
,[DueDate]
,[Status]
,[SourceTable]
,[SourceId]
,[InternalComment]
,[IsGLPosted]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[CurrencyId]
,[PayableCodeId]
,[LegalEntityId]
,[PayeeId]
,[RemitToId]
,[TaxPortion_Amount]
,[TaxPortion_Currency]
,[AdjustmentBasisPayableId])
VALUES
(newPayable.EntityType
,newPayable.EntityId
,newPayable.Amount
,newPayable.Currency
,newPayable.Balance
,newPayable.Currency
,newPayable.DueDate
,newPayable.PayableStatus
,newPayable.SourceTable
,newPayable.SourceId
,newPayable.InternalComment
,newPayable.IsGLPosted
,@CreatedById
,@CreatedTime
,NULL
,NULL
,newPayable.CurrencyId
,newPayable.PayableCodeId
,newPayable.LegalEntityId
,newPayable.PayeeId
,newPayable.RemitToId
,newPayable.TaxPortion
,newPayable.Currency
,newPayable.AdjustmentBasisPayableId
)
OUTPUT newPayable.[Key] AS [Key],INSERTED.Id AS [Id]  INTO #NewPayable;
SELECT * FROM #NewPayable;
DROP TABLE #NewPayable;

GO
