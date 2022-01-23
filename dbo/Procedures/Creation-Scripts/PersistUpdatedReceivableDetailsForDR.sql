SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[PersistUpdatedReceivableDetailsForDR]
(
	@UpdatedById						BIGINT,
	@UpdatedTime						DATETIMEOFFSET,
	@UpdatedReceivables					UpdatedBalancesToPersist READONLY,
	@UpdatedReceivableDetails			UpdatedBalancesToPersist READONLY,
	@UpdatedReceivableTaxes				UpdatedBalancesToPersist READONLY,
	@UpdatedReceivableTaxDetails		UpdatedBalancesToPersist READONLY,
	@UpdatedReceivableTaxImpositions	UpdatedBalancesToPersist READONLY
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN

	UPDATE R SET 
		R.TotalEffectiveBalance_Amount = UR.EffectiveBalance,
		R.UpdatedById = @UpdatedById,
		R.UpdatedTime = @UpdatedTime
	FROM Receivables R
		INNER JOIN @UpdatedReceivables UR ON R.Id = UR.Id;
		
	UPDATE RD SET 
		RD.EffectiveBalance_Amount = URD.EffectiveBalance,
		RD.UpdatedById = @UpdatedById,
		RD.UpdatedTime = @UpdatedTime
	FROM ReceivableDetails RD
		INNER JOIN @UpdatedReceivableDetails URD ON RD.Id = URD.Id;

	UPDATE RT SET 
		RT.EffectiveBalance_Amount = URT.EffectiveBalance,
		RT.UpdatedById = @UpdatedById,
		RT.UpdatedTime = @UpdatedTime
	FROM ReceivableTaxes RT
		INNER JOIN @UpdatedReceivableTaxes URT ON RT.Id = URT.Id;

	UPDATE RTD SET 
		RTD.EffectiveBalance_Amount = URTD.EffectiveBalance,
		RTD.UpdatedById = @UpdatedById,
		RTD.UpdatedTime = @UpdatedTime
	FROM ReceivableTaxDetails RTD
		INNER JOIN @UpdatedReceivableTaxDetails URTD ON RTD.Id = URTD.Id;

	UPDATE RTI SET 
		RTI.EffectiveBalance_Amount = URTI.EffectiveBalance,
		RTI.UpdatedById = @UpdatedById,
		RTI.UpdatedTime = @UpdatedTime
	FROM ReceivableTaxImpositions RTI
		INNER JOIN @UpdatedReceivableTaxImpositions URTI ON RTI.Id = URTI.Id;

END

GO
