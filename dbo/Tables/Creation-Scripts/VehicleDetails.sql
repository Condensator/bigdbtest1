SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VehicleDetails](
	[Id] [bigint] NOT NULL,
	[VehicleType] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[TransmissionType] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[TankCapacity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[InteriorColor] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[NumberOfCylinders] [int] NULL,
	[PayloadCapacity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[EngineSize] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[WeightClass] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CO2] [decimal](16, 2) NULL,
	[ContractMileage] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BodyDescription] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[OriginalOdometerReading] [int] NULL,
	[OdometerReadingUnit] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[NumberOfDoors] [int] NULL,
	[NumberOfPassengers] [int] NULL,
	[NumberOfSeats] [int] NULL,
	[KeylessEntry] [bit] NOT NULL,
	[MPG] [int] NULL,
	[NumberOfKeys] [int] NULL,
	[DoorKeyCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[NumberOfRemotes] [int] NULL,
	[TireSize] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[EngineKeyCode] [int] NULL,
	[ExteriorColor] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[WeightUnit] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[GVW] [decimal](16, 2) NULL,
	[GrossCurbCombinedWeight] [decimal](16, 2) NULL,
	[VehicleRegisteredWeight] [decimal](16, 2) NULL,
	[VehicleCurbWeight] [decimal](16, 2) NULL,
	[Titled] [bit] NOT NULL,
	[TitleTrustOverride] [bit] NOT NULL,
	[TitleBorrowedReason] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[TitleBorrowedDate] [date] NULL,
	[TitleLienHolder] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[TitleApplicationSubmissionDate] [date] NULL,
	[TitleReceivedDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetClassConfigId] [bigint] NULL,
	[FuelTypeConfigId] [bigint] NULL,
	[DriveTrainConfigId] [bigint] NULL,
	[BodyTypeConfigId] [bigint] NULL,
	[TitleStateId] [bigint] NULL,
	[TitleCodeConfigId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[VehiclePlateNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RegistrationCertificateNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RegistrationDate] [date] NULL,
	[UserInRegistrationCertificate] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[EngineNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Horsepower] [decimal](16, 2) NULL,
	[BeginningMileage] [decimal](16, 2) NULL,
	[TerminationMileage] [decimal](16, 2) NULL,
	[ExcessMileage] [decimal](16, 2) NULL,
	[EngineCapacity] [decimal](16, 2) NULL,
	[KW] [decimal](16, 2) NULL,
	[VehicleContractMileage] [decimal](16, 2) NULL,
	[Axles] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[VehicleNumberOfKeys] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[VehicleNumberOfDoors] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[ColourId] [bigint] NULL,
	[ColourTypeId] [bigint] NULL,
	[SuspensionId] [bigint] NULL,
	[FrontTyreSizeId] [bigint] NULL,
	[RearTyreSizeId] [bigint] NULL,
	[WheelId] [bigint] NULL,
	[LoadCapacity] [decimal](16, 2) NULL,
	[IsGPS] [bit] NULL,
	[IsGPSTracker] [bit] NULL,
	[IsImmobiliser] [bit] NULL,
	[LastDateOfExecution] [date] NULL,
	[NextDateOfExecution] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[VehicleDetails]  WITH CHECK ADD  CONSTRAINT [EAsset_VehicleDetail] FOREIGN KEY([Id])
REFERENCES [dbo].[Assets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[VehicleDetails] CHECK CONSTRAINT [EAsset_VehicleDetail]
GO
ALTER TABLE [dbo].[VehicleDetails]  WITH CHECK ADD  CONSTRAINT [EVehicleDetail_AssetClassConfig] FOREIGN KEY([AssetClassConfigId])
REFERENCES [dbo].[AssetClassConfigs] ([Id])
GO
ALTER TABLE [dbo].[VehicleDetails] CHECK CONSTRAINT [EVehicleDetail_AssetClassConfig]
GO
ALTER TABLE [dbo].[VehicleDetails]  WITH CHECK ADD  CONSTRAINT [EVehicleDetail_BodyTypeConfig] FOREIGN KEY([BodyTypeConfigId])
REFERENCES [dbo].[BodyTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[VehicleDetails] CHECK CONSTRAINT [EVehicleDetail_BodyTypeConfig]
GO
ALTER TABLE [dbo].[VehicleDetails]  WITH CHECK ADD  CONSTRAINT [EVehicleDetail_Colour] FOREIGN KEY([ColourId])
REFERENCES [dbo].[ColourConfigs] ([Id])
GO
ALTER TABLE [dbo].[VehicleDetails] CHECK CONSTRAINT [EVehicleDetail_Colour]
GO
ALTER TABLE [dbo].[VehicleDetails]  WITH CHECK ADD  CONSTRAINT [EVehicleDetail_ColourType] FOREIGN KEY([ColourTypeId])
REFERENCES [dbo].[ColourTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[VehicleDetails] CHECK CONSTRAINT [EVehicleDetail_ColourType]
GO
ALTER TABLE [dbo].[VehicleDetails]  WITH CHECK ADD  CONSTRAINT [EVehicleDetail_DriveTrainConfig] FOREIGN KEY([DriveTrainConfigId])
REFERENCES [dbo].[DriveTrainConfigs] ([Id])
GO
ALTER TABLE [dbo].[VehicleDetails] CHECK CONSTRAINT [EVehicleDetail_DriveTrainConfig]
GO
ALTER TABLE [dbo].[VehicleDetails]  WITH CHECK ADD  CONSTRAINT [EVehicleDetail_FrontTyreSize] FOREIGN KEY([FrontTyreSizeId])
REFERENCES [dbo].[TireSizeConfigs] ([Id])
GO
ALTER TABLE [dbo].[VehicleDetails] CHECK CONSTRAINT [EVehicleDetail_FrontTyreSize]
GO
ALTER TABLE [dbo].[VehicleDetails]  WITH CHECK ADD  CONSTRAINT [EVehicleDetail_FuelTypeConfig] FOREIGN KEY([FuelTypeConfigId])
REFERENCES [dbo].[FuelTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[VehicleDetails] CHECK CONSTRAINT [EVehicleDetail_FuelTypeConfig]
GO
ALTER TABLE [dbo].[VehicleDetails]  WITH CHECK ADD  CONSTRAINT [EVehicleDetail_RearTyreSize] FOREIGN KEY([RearTyreSizeId])
REFERENCES [dbo].[TireSizeConfigs] ([Id])
GO
ALTER TABLE [dbo].[VehicleDetails] CHECK CONSTRAINT [EVehicleDetail_RearTyreSize]
GO
ALTER TABLE [dbo].[VehicleDetails]  WITH CHECK ADD  CONSTRAINT [EVehicleDetail_Suspension] FOREIGN KEY([SuspensionId])
REFERENCES [dbo].[SuspensionConfigs] ([Id])
GO
ALTER TABLE [dbo].[VehicleDetails] CHECK CONSTRAINT [EVehicleDetail_Suspension]
GO
ALTER TABLE [dbo].[VehicleDetails]  WITH CHECK ADD  CONSTRAINT [EVehicleDetail_TitleCodeConfig] FOREIGN KEY([TitleCodeConfigId])
REFERENCES [dbo].[TitleCodeConfigs] ([Id])
GO
ALTER TABLE [dbo].[VehicleDetails] CHECK CONSTRAINT [EVehicleDetail_TitleCodeConfig]
GO
ALTER TABLE [dbo].[VehicleDetails]  WITH CHECK ADD  CONSTRAINT [EVehicleDetail_TitleState] FOREIGN KEY([TitleStateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[VehicleDetails] CHECK CONSTRAINT [EVehicleDetail_TitleState]
GO
ALTER TABLE [dbo].[VehicleDetails]  WITH CHECK ADD  CONSTRAINT [EVehicleDetail_Wheel] FOREIGN KEY([WheelId])
REFERENCES [dbo].[WheelConfigs] ([Id])
GO
ALTER TABLE [dbo].[VehicleDetails] CHECK CONSTRAINT [EVehicleDetail_Wheel]
GO
