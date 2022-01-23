SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdatePostDateForReceiptsInBatch]
(
@JobStepInstanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
Update receipts set postdate = null where jobstepinstanceid = @JobStepInstanceId
update receiptapplications set postdate = null
from receipts INNER JOIN receiptapplications on receipts.id = receiptapplications.receiptid
where receipts.jobstepinstanceid = @JobStepInstanceId
END

GO
