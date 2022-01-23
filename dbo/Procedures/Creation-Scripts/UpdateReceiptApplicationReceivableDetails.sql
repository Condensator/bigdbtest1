SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdateReceiptApplicationReceivableDetails]
(  
    @PrepaidGLDetailsToUpdate PrepaidGLDetailsToUpdate READONLY,
	@RecoveryDetailsToUpdate RecoveryDetailsToUpdate READONLY,
	@UpdatedById BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS

BEGIN
	SET NOCOUNT ON

	SELECT * INTO #PrepaidGLDetailsToUpdate FROM @PrepaidGLDetailsToUpdate

	CREATE CLUSTERED INDEX IX_PrepaidRARDId ON #PrepaidGLDetailsToUpdate (ReceiptApplicationReceivableDetailId);

	SELECT * INTO #RecoveryDetailsToUpdate FROM @RecoveryDetailsToUpdate

	CREATE CLUSTERED INDEX IX_RecoveryRARDId ON #RecoveryDetailsToUpdate (ReceiptApplicationReceivableDetailId);

	UPDATE RARD SET 
		IsGLPosted = PGL.IsGLPosted
		,IsTaxGLPosted = PGL.IsTaxGLPosted
		,PrepaidAmount_Amount = PGL.PrepaidAmount
		,PrepaidTaxAmount_Amount = PGL.PrepaidTaxAmount
		,LeaseComponentPrepaidAmount_Amount = PGL.LeaseComponentPrepaidAmount
		,NonLeaseComponentPrepaidAmount_Amount = PGL.NonLeaseComponentPrepaidAmount
	    ,UpdatedById = @UpdatedById 
	    ,UpdatedTime = @UpdatedTime
	FROM ReceiptApplicationReceivableDetails RARD
	INNER JOIN #PrepaidGLDetailsToUpdate PGL ON RARD.Id = PGL.ReceiptApplicationReceivableDetailId

	UPDATE RARD SET
		RecoveryAmount_Amount = RD.RecoveryAmount
		,GainAmount_Amount = RD.GainAmount
		,UpdatedById = @UpdatedById 
	    ,UpdatedTime = @UpdatedTime
	FROM ReceiptApplicationReceivableDetails RARD
	INNER JOIN #RecoveryDetailsToUpdate RD ON RARD.Id = RD.ReceiptApplicationReceivableDetailId
END

GO
