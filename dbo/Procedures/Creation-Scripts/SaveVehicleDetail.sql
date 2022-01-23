SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVehicleDetail]
(
 @val [dbo].[VehicleDetail] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[VehicleDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetClassConfigId]=S.[AssetClassConfigId],[Axles]=S.[Axles],[BeginningMileage]=S.[BeginningMileage],[BodyDescription]=S.[BodyDescription],[BodyTypeConfigId]=S.[BodyTypeConfigId],[CO2]=S.[CO2],[ColourId]=S.[ColourId],[ColourTypeId]=S.[ColourTypeId],[ContractMileage]=S.[ContractMileage],[DoorKeyCode]=S.[DoorKeyCode],[DriveTrainConfigId]=S.[DriveTrainConfigId],[EngineCapacity]=S.[EngineCapacity],[EngineKeyCode]=S.[EngineKeyCode],[EngineNumber]=S.[EngineNumber],[EngineSize]=S.[EngineSize],[ExcessMileage]=S.[ExcessMileage],[ExteriorColor]=S.[ExteriorColor],[FrontTyreSizeId]=S.[FrontTyreSizeId],[FuelTypeConfigId]=S.[FuelTypeConfigId],[GrossCurbCombinedWeight]=S.[GrossCurbCombinedWeight],[GVW]=S.[GVW],[Horsepower]=S.[Horsepower],[InteriorColor]=S.[InteriorColor],[IsGPS]=S.[IsGPS],[IsGPSTracker]=S.[IsGPSTracker],[IsImmobiliser]=S.[IsImmobiliser],[KeylessEntry]=S.[KeylessEntry],[KW]=S.[KW],[LastDateOfExecution]=S.[LastDateOfExecution],[LoadCapacity]=S.[LoadCapacity],[MPG]=S.[MPG],[NextDateOfExecution]=S.[NextDateOfExecution],[NumberOfCylinders]=S.[NumberOfCylinders],[NumberOfDoors]=S.[NumberOfDoors],[NumberOfKeys]=S.[NumberOfKeys],[NumberOfPassengers]=S.[NumberOfPassengers],[NumberOfRemotes]=S.[NumberOfRemotes],[NumberOfSeats]=S.[NumberOfSeats],[OdometerReadingUnit]=S.[OdometerReadingUnit],[OriginalOdometerReading]=S.[OriginalOdometerReading],[PayloadCapacity]=S.[PayloadCapacity],[RearTyreSizeId]=S.[RearTyreSizeId],[RegistrationCertificateNumber]=S.[RegistrationCertificateNumber],[RegistrationDate]=S.[RegistrationDate],[SuspensionId]=S.[SuspensionId],[TankCapacity]=S.[TankCapacity],[TerminationMileage]=S.[TerminationMileage],[TireSize]=S.[TireSize],[TitleApplicationSubmissionDate]=S.[TitleApplicationSubmissionDate],[TitleBorrowedDate]=S.[TitleBorrowedDate],[TitleBorrowedReason]=S.[TitleBorrowedReason],[TitleCodeConfigId]=S.[TitleCodeConfigId],[Titled]=S.[Titled],[TitleLienHolder]=S.[TitleLienHolder],[TitleReceivedDate]=S.[TitleReceivedDate],[TitleStateId]=S.[TitleStateId],[TitleTrustOverride]=S.[TitleTrustOverride],[TransmissionType]=S.[TransmissionType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserInRegistrationCertificate]=S.[UserInRegistrationCertificate],[VehicleContractMileage]=S.[VehicleContractMileage],[VehicleCurbWeight]=S.[VehicleCurbWeight],[VehicleNumberOfDoors]=S.[VehicleNumberOfDoors],[VehicleNumberOfKeys]=S.[VehicleNumberOfKeys],[VehiclePlateNumber]=S.[VehiclePlateNumber],[VehicleRegisteredWeight]=S.[VehicleRegisteredWeight],[VehicleType]=S.[VehicleType],[WeightClass]=S.[WeightClass],[WeightUnit]=S.[WeightUnit],[WheelId]=S.[WheelId]
WHEN NOT MATCHED THEN
	INSERT ([AssetClassConfigId],[Axles],[BeginningMileage],[BodyDescription],[BodyTypeConfigId],[CO2],[ColourId],[ColourTypeId],[ContractMileage],[CreatedById],[CreatedTime],[DoorKeyCode],[DriveTrainConfigId],[EngineCapacity],[EngineKeyCode],[EngineNumber],[EngineSize],[ExcessMileage],[ExteriorColor],[FrontTyreSizeId],[FuelTypeConfigId],[GrossCurbCombinedWeight],[GVW],[Horsepower],[Id],[InteriorColor],[IsGPS],[IsGPSTracker],[IsImmobiliser],[KeylessEntry],[KW],[LastDateOfExecution],[LoadCapacity],[MPG],[NextDateOfExecution],[NumberOfCylinders],[NumberOfDoors],[NumberOfKeys],[NumberOfPassengers],[NumberOfRemotes],[NumberOfSeats],[OdometerReadingUnit],[OriginalOdometerReading],[PayloadCapacity],[RearTyreSizeId],[RegistrationCertificateNumber],[RegistrationDate],[SuspensionId],[TankCapacity],[TerminationMileage],[TireSize],[TitleApplicationSubmissionDate],[TitleBorrowedDate],[TitleBorrowedReason],[TitleCodeConfigId],[Titled],[TitleLienHolder],[TitleReceivedDate],[TitleStateId],[TitleTrustOverride],[TransmissionType],[UserInRegistrationCertificate],[VehicleContractMileage],[VehicleCurbWeight],[VehicleNumberOfDoors],[VehicleNumberOfKeys],[VehiclePlateNumber],[VehicleRegisteredWeight],[VehicleType],[WeightClass],[WeightUnit],[WheelId])
    VALUES (S.[AssetClassConfigId],S.[Axles],S.[BeginningMileage],S.[BodyDescription],S.[BodyTypeConfigId],S.[CO2],S.[ColourId],S.[ColourTypeId],S.[ContractMileage],S.[CreatedById],S.[CreatedTime],S.[DoorKeyCode],S.[DriveTrainConfigId],S.[EngineCapacity],S.[EngineKeyCode],S.[EngineNumber],S.[EngineSize],S.[ExcessMileage],S.[ExteriorColor],S.[FrontTyreSizeId],S.[FuelTypeConfigId],S.[GrossCurbCombinedWeight],S.[GVW],S.[Horsepower],S.[Id],S.[InteriorColor],S.[IsGPS],S.[IsGPSTracker],S.[IsImmobiliser],S.[KeylessEntry],S.[KW],S.[LastDateOfExecution],S.[LoadCapacity],S.[MPG],S.[NextDateOfExecution],S.[NumberOfCylinders],S.[NumberOfDoors],S.[NumberOfKeys],S.[NumberOfPassengers],S.[NumberOfRemotes],S.[NumberOfSeats],S.[OdometerReadingUnit],S.[OriginalOdometerReading],S.[PayloadCapacity],S.[RearTyreSizeId],S.[RegistrationCertificateNumber],S.[RegistrationDate],S.[SuspensionId],S.[TankCapacity],S.[TerminationMileage],S.[TireSize],S.[TitleApplicationSubmissionDate],S.[TitleBorrowedDate],S.[TitleBorrowedReason],S.[TitleCodeConfigId],S.[Titled],S.[TitleLienHolder],S.[TitleReceivedDate],S.[TitleStateId],S.[TitleTrustOverride],S.[TransmissionType],S.[UserInRegistrationCertificate],S.[VehicleContractMileage],S.[VehicleCurbWeight],S.[VehicleNumberOfDoors],S.[VehicleNumberOfKeys],S.[VehiclePlateNumber],S.[VehicleRegisteredWeight],S.[VehicleType],S.[WeightClass],S.[WeightUnit],S.[WheelId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
