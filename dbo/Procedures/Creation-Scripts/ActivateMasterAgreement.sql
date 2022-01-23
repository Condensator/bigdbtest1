SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ActivateMasterAgreement]
(
@MasterAgreementId BIGINT,
@MasterAgreementStatus NVARCHAR(16),
@WorkItemStatus NVARCHAR(20),
@TransactionInstanceStatus NVARCHAR(20),
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
SET NOCOUNT ON;
DECLARE @TransactionInstanceId BIGINT = 0
UPDATE MasterAgreements SET Status = @MasterAgreementStatus, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
WHERE Id = @MasterAgreementId
SELECT @TransactionInstanceId = Id FROM TransactionInstances
where EntityId = @MasterAgreementId AND EntityName = 'MasterAgreement' AND Status = 'Active'
UPDATE WorkItems SET Status = @WorkItemStatus, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
WHERE TransactionInstanceId = @TransactionInstanceId
UPDATE TransactionInstances SET Status = @TransactionInstanceStatus, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
WHERE Id = @TransactionInstanceId

GO
