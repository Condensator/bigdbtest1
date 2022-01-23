SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CreateType3ActivityTypes]
(
@EntityType NVARCHAR(50),
@ActivityTypeName  NVARCHAR(50),
@ActivityTransactionConfigName  NVARCHAR(50),
@Type  NVARCHAR(50),
@Category NVARCHAR(22)='_',
@CreatedTime DATETIMEOFFSET= NULL
)
AS
BEGIN
SET NOCOUNT ON
IF(@CreatedTime IS NULL)
SET @CreatedTime = SYSDATETIMEOFFSET();
Declare @EntityTypeId INT =(Select TOP 1 Id from EntityConfigs where Name = @EntityType);
/*-----------------------------------------------Activity Type---------------------------------------------------------------------------------*/

IF NOT EXISTS(SELECT 1 FROM ActivityTypes WHERE Name = @ActivityTypeName AND Type=@Type AND EntityTypeId=@EntityTypeId AND PortfolioId Is Null AND IsActive=1)
BEGIN
INSERT INTO ActivityTypes
(Name,AllowDuplicate,DefaultPermission,CreationAllowed,IsActive,CreatedById,CreatedTime,
EntityTypeId,Category,IsWorkFlowEnabled,IsTrueTask,
TransactionTobeinitiatedId,Type,IsViewableInCustomerSummary)
Values
(@ActivityTypeName,1,'F','Allowed',1,1,@CreatedTime,
@EntityTypeId,@Category,0,0,
(Select Id from ActivityTransactionConfigs where Name = @ActivityTransactionConfigName),@Type,1)
/*-----------------------------------------------Activity Status For Type---------------------------------------------------------------------------------*/
Declare @ActivityTypeId INT =(SELECT TOP 1 Id FROM ActivityTypes WHERE Name = @ActivityTypeName AND Type=@Type AND EntityTypeId=@EntityTypeId AND PortfolioId Is Null AND IsActive=1);
Declare @OutputTblPending Table(Id INT)
INSERT INTO
UserSelectionParams (CreatedById,CreatedTime)
OUTPUT INSERTED.Id INTO @OutputTblPending(Id)
Values
(1,@CreatedTime),
(1,@CreatedTime)
INSERT INTO ActivityStatusForTypes (Sequence,IsActive,IsDefault,CreatedById,CreatedTime,StatusId,WhomToNotifyId,WhoCanChangeId,ActivityTypeId)
Select SequenceNumber,IsActive,IsDefault,1,@CreatedTime,Id,(Select Max(Id) From @OutputTblPending),(Select Min(Id) From @OutputTblPending),@ActivityTypeId
From ActivityStatusConfigs Where Name = 'Pending'
Declare @OutputTblCompleted Table(Id INT)
INSERT INTO
UserSelectionParams (CreatedById,CreatedTime)
OUTPUT INSERTED.Id INTO @OutputTblCompleted(Id)
Values
(1,@CreatedTime),
(1,@CreatedTime)
INSERT INTO ActivityStatusForTypes (Sequence,IsActive,IsDefault,CreatedById,CreatedTime,StatusId,WhomToNotifyId,WhoCanChangeId,ActivityTypeId)
Select SequenceNumber,IsActive,IsDefault,1,@CreatedTime,Id,(Select Max(Id) From @OutputTblCompleted),(Select Min(Id) From @OutputTblCompleted),@ActivityTypeId
From ActivityStatusConfigs Where Name = 'Completed'
/*-----------------------------------------------Activity Type SubSystem Details---------------------------------------------------------------------------------*/
IF EXISTS(Select Id from SubsystemConfigs where Name = 'LessorPortal')
INSERT INTO
ActivityTypeSubSystemDetails (Viewable,IsActive,CreatedById,CreatedTime,SubSystemId,ActivityTypeId)
Values (1,1,1,@CreatedTime,(Select Id from SubsystemConfigs where Name = 'LessorPortal'),@ActivityTypeId)
IF EXISTS(Select Id from SubsystemConfigs where Name = 'CustomerPortal')
INSERT INTO
ActivityTypeSubSystemDetails (Viewable,IsActive,CreatedById,CreatedTime,SubSystemId,ActivityTypeId)
Values (0,1,1,@CreatedTime,(Select Id from SubsystemConfigs where Name = 'CustomerPortal'),@ActivityTypeId)
IF EXISTS(Select Id from SubsystemConfigs where Name = 'VendorPortal')
INSERT INTO
ActivityTypeSubSystemDetails (Viewable,IsActive,CreatedById,CreatedTime,SubSystemId,ActivityTypeId)
Values (0,1,1,@CreatedTime,(Select Id from SubsystemConfigs where Name = 'VendorPortal'),@ActivityTypeId)
IF EXISTS(Select Id from SubsystemConfigs where Name = 'BrokerPortal')
INSERT INTO
ActivityTypeSubSystemDetails (Viewable,IsActive,CreatedById,CreatedTime,SubSystemId,ActivityTypeId)
Values (0,1,1,@CreatedTime,(Select Id from SubsystemConfigs where Name = 'BrokerPortal'),@ActivityTypeId)
END
END

GO
