SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[DeactivateNonCurrentLeaseFromAmendment]
(
@LeaseFinanceId BIGINT,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
UPDATE LeaseFinances SET IsCurrent = 0,UpdatedById = @UpdatedById,UpdatedTime=@UpdatedTime WHERE Id = @LeaseFinanceId

GO
