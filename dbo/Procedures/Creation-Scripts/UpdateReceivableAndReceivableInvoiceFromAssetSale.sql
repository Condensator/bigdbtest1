SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateReceivableAndReceivableInvoiceFromAssetSale]
(
@ReceivableIds ReceivableIds Readonly,
@InactivateReceivablesInfo BIT Null,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
IF(@InactivateReceivablesInfo = 0)
BEGIN
UPDATE Receivables SET IsDummy = 0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
WHERE Id In (SELECT ReceivableId FROM @ReceivableIds )

UPDATE ReceivableTaxes SET IsDummy = 0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
WHERE ReceivableId In (SELECT ReceivableId FROM @ReceivableIds )

UPDATE RD
SET BilledStatus = 'Invoiced', UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM ReceivableDetails RD
JOIN ReceivableInvoiceDetails RID on RD.Id = RID.ReceivableDetailId
--JOIn Receivables on RD.ReceivableId = Receivables.Id
Where RD.ReceivableId In (SELECT ReceivableId FROM @ReceivableIds)
END
IF(@InactivateReceivablesInfo = 1)
BEGIN
UPDATE Receivables
SET IsActive = 0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
where Id IN (SELECT ReceivableId FROM @ReceivableIds) AND IsActive = 1

UPDATE ReceivableDetails
SET IsActive = 0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
where ReceivableId IN (SELECT ReceivableId FROM @ReceivableIds) AND IsActive = 1

UPDATE ReceivableTaxes
SET IsActive = 0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
where ReceivableId IN (SELECT ReceivableId FROM @ReceivableIds) AND IsActive = 1

UPDATE RDT
SET IsActive = 0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FRom ReceivableTaxDetails RDT
Join ReceivableTaxes on  RDT.ReceivableTaxId = ReceivableTaxes.Id
Join @ReceivableIds recIds	on 	ReceivableTaxes.ReceivableId = recIds.ReceivableId
where RDT.IsActive = 1

UPDATE RI
SET IsActive = 0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM ReceivableInvoices RI
Join ReceivableInvoiceDetails on RI.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
JOIn ReceivableDetails on ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id
Join @ReceivableIds recIds on ReceivableDetails.ReceivableId = recIds.ReceivableId
Where RI.IsActive = 1

UPDATE RID
SET IsActive = 0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM ReceivableInvoiceDetails RID
JOIn ReceivableDetails on RID.ReceivableDetailId = ReceivableDetails.Id
Join @ReceivableIds recIds on ReceivableDetails.ReceivableId = recIds.ReceivableId
where RID.IsActive = 1
END
END

GO
