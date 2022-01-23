SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateTaxDepAmortizationDetail]
(
@IsGLPosted BIT,
@TaxDepAmortDetailIds TaxDepAmortDetailId READONLY,
@UpdatedById  BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
UPDATE TDAD SET IsGLPosted = @IsGLPosted, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM TaxDepAmortizationDetails TDAD
JOIN @TaxDepAmortDetailIds TDADI ON TDAD.Id = TDADI.Id
END

GO
