SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ManipulateAssetHoldingStatus]
(
@Assets ManipulateAssetHoldingStatusParam READONLY,
@IsReversal BIT,
@ReversalId BIGINT,
@Alias NVARCHAR(50),
@NewHoldingStatus NVARCHAR(3),
@PostDate DATETIME,
@GLTransferEffectiveDate DATETIME,
@ApprovedStatus NVARCHAR(10),
@InactiveStatus NVARCHAR(10),
@Time DATETIMEOFFSET,
@UserId BIGINT,
@CurrentBusinessUnitId BIGINT
)
AS
BEGIN
DECLARE @ManipulatedId BIGINT;
IF (@IsReversal = 1)
BEGIN
UPDATE AssetHoldingStatusChanges
SET Status = @InactiveStatus
,UpdatedById = @UserId
,UpdatedTime = @Time
WHERE Id = @ReversalId
;
SET @ManipulatedId = @ReversalId;
END
ELSE
BEGIN
INSERT INTO AssetHoldingStatusChanges (
Alias
,NewHoldingStatus
,PostDate
,GLTransferEffectiveDate
,Status
,CreatedById
,CreatedTime
,BusinessUnitId)
VALUES (
@Alias
,@NewHoldingStatus
,@PostDate
,@GLTransferEffectiveDate
,@ApprovedStatus
,@UserId
,@Time
,@CurrentBusinessUnitId)
;
SET @ManipulatedId = SCOPE_IDENTITY();
INSERT INTO AssetHoldingStatusChangeDetails (
AssetHoldingStatusChangeId
,AssetId
,IsActive
,CreatedById
,CreatedTime
,NewInstrumentTypeId
,NewLineofBusinessId
,InstrumentTypeId
,LineofBusinessid)
SELECT
@ManipulatedId
,Id
,1
,@UserId
,@Time
,NewInstrumentTypeId
,NewLineofBusinessId
,InstrumentTypeId
,LineofBusinessid
FROM @Assets
;
END
SELECT @ManipulatedId As Id;
END

GO
