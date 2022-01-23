SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetConsentDocumentParam]
(
@CurrentRole nvarchar(200),
@SystemStatusValue nvarchar(10),
@EntityId bigint
)
AS
BEGIN
	SET NOCOUNT ON;

	Declare @EntityTypeId bigint
	Declare @DocumentStatusId bigint
	Declare @EntityHeaderId bigint

	SELECT @EntityTypeId = Id FROM EntityConfigs WHERE [Name] = @CurrentRole

	SELECT @DocumentStatusId = Id FROM DocumentStatusConfigs  WHERE [SystemStatus] = @SystemStatusValue

	SELECT @EntityHeaderId = Id FROM EntityHeaders WHERE EntityId = @EntityId and EntityTypeId = @EntityTypeId

	SELECT ISNULL(@EntityHeaderId, 0) AS 'EntityHeaderId', ISNULL(@EntityTypeId,0) AS 'EntityConfigId', ISNULL(@DocumentStatusId,0) AS 'DocumentStatusId'

	SET NOCOUNT OFF;
END

GO
