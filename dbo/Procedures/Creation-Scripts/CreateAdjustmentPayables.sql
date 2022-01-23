SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreateAdjustmentPayables]
(
@AdjustmentPayableInfo AdjustmentPayableInfo READONLY,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET(7)
)
AS
BEGIN
SET NOCOUNT ON;
--DECLARE
--@AdjustmentPayables AdjustmentPayableInfo ,
--@CreatedById BIGINT = 100915,
--@CreatedTime DATETIMEOFFSET(7) = SYSDATETIMEOFFSET()
--INSERT INTO @AdjustmentPayables Values (173,'Approved')
CREATE TABLE #PayableOutput
(
[Id] BIGINT
)
MERGE Payables p
USING (SELECT *	FROM Payables
JOIN @AdjustmentPayableInfo adjustment ON Payables.Id = adjustment.OldPayableId) oldpayables ON 1 = 0
WHEN  NOT MATCHED THEN
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
(
[EntityType]
,[EntityId]
,oldpayables.Amount
,[Amount_Currency]
,oldpayables.Balance
,[Balance_Currency]
,[DueDate]
,oldpayables.[PayableStatus]
,[SourceTable]
,[SourceId]
,[InternalComment]
,[IsGLPosted]
,@CreatedById
,@CreatedTime
,NULL
,NULL
,[CurrencyId]
,[PayableCodeId]
,[LegalEntityId]
,[PayeeId]
,[RemitToId]
,[TaxPortion_Amount]
,[TaxPortion_Currency]
,oldpayables.OldPayableId
)
OUTPUT Inserted.Id INTO #PayableOutput;
SELECT * FROM #PayableOutput
DROP TABLE #PayableOutput
END

GO
