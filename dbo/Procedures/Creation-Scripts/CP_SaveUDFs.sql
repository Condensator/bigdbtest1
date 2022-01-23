SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CP_SaveUDFs]
(
@UDFAssignmentDetails CP_AssignmentType_UDF readonly,
@IsFromUDFLabelScreen tinyint,
@CreatedTime DATETIMEOFFSET = NULL
)
AS
IF @IsFromUDFLabelScreen = 0
BEGIN
SET NOCOUNT ON;
IF(@CreatedTime IS NULL)
SET @CreatedTime = SYSDATETIMEOFFSET();
MERGE INTO UDFs udf1
USING @UDFAssignmentDetails udf2
ON (
ISNULL(udf1.AssetId,0)=isnull(udf2.AssetID,0) and ISNULL(udf1.ContractId,0) =  ISNULL(udf2.ContractId,0)
)
WHEN MATCHED THEN
UPDATE SET udf1.UDF1Label = udf2.[UDF1Label]
,udf1.UDF2Label = udf2.[UDF2Label]
,udf1.UDF3Label = udf2.[UDF3Label]
,udf1.UDF4Label = udf2.[UDF4Label]
,udf1.UDF5Label = udf2.[UDF5Label]
,udf1.UDF1Value = udf2.[UDF1Value]
,udf1.UDF2Value = udf2.[UDF2Value]
,udf1.UDF3Value = udf2.[UDF3Value]
,udf1.UDF4Value = udf2.[UDF4Value]
,udf1.UDF5Value = udf2.[UDF5Value]
,udf1.IsActive = udf2.[IsActive]
,udf1.UpdatedById = udf2.UserID
,udf1.UpdatedTime = @CreatedTime
WHEN NOT MATCHED THEN
INSERT
(
[UDF1Label]
,[UDF2Label]
,[UDF3Label]
,[UDF4Label]
,[UDF5Label]
,[UDF1Value]
,[UDF2Value]
,[UDF3Value]
,[UDF4Value]
,[UDF5Value]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[AssetId]
,[ContractId]
,[CustomerId])
VALUES(udf2.[UDF1Label]
,udf2.[UDF2Label]
,udf2.[UDF3Label]
,udf2.[UDF4Label]
,udf2.[UDF5Label]
,udf2.[UDF1Value]
,udf2.[UDF2Value]
,udf2.[UDF3Value]
,udf2.[UDF4Value]
,udf2.[UDF5Value]
,udf2.[IsActive]
,udf2.[UserId]
,@CreatedTime
,NULL
,NULL
,udf2.[AssetId]
,udf2.[ContractId]
,udf2.CustomerId);
END
ELSE
BEGIN
BEGIN
SET NOCOUNT ON;
MERGE INTO UDFs udf1
USING @UDFAssignmentDetails udf2
ON (udf1.CustomerId=udf2.CustomerId  and udf2.EntityType = 'Asset' and udf1.AssetId > 0 )
WHEN MATCHED THEN
UPDATE SET udf1.UDF1Label = udf2.[UDF1Label]
,udf1.UDF2Label = udf2.[UDF2Label]
,udf1.UDF3Label = udf2.[UDF3Label]
,udf1.UDF4Label = udf2.[UDF4Label]
,udf1.UDF5Label = udf2.[UDF5Label]
,udf1.UpdatedById = udf2.UserID
,udf1.UpdatedTime = @CreatedTime;
MERGE INTO UDFs udf1
USING @UDFAssignmentDetails udf2
ON (udf1.CustomerId=udf2.CustomerId  and udf2.EntityType = 'Contract' and udf1.ContractId > 0 )
WHEN MATCHED THEN
UPDATE SET udf1.UDF1Label = udf2.[UDF1Label]
,udf1.UDF2Label = udf2.[UDF2Label]
,udf1.UDF3Label = udf2.[UDF3Label]
,udf1.UDF4Label = udf2.[UDF4Label]
,udf1.UDF5Label = udf2.[UDF5Label]
,udf1.UpdatedById = udf2.UserID
,udf1.UpdatedTime = @CreatedTime;
END
END

GO
