SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FlatFees](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PermissibleMassFrom] [decimal](16, 2) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PermissibleMassTill] [decimal](16, 2) NULL,
	[SeatFrom] [int] NULL,
	[SeatTill] [int] NULL,
	[EnginecapacityFrom] [decimal](16, 2) NULL,
	[EngineCapacityTill] [decimal](16, 2) NULL,
	[LoadCapacity] [decimal](16, 2) NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[FlatFees]  WITH CHECK ADD  CONSTRAINT [EFlatFee_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[FlatFees] CHECK CONSTRAINT [EFlatFee_AssetType]
GO
ALTER TABLE [dbo].[FlatFees]  WITH CHECK ADD  CONSTRAINT [EFlatFee_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[FlatFees] CHECK CONSTRAINT [EFlatFee_LegalEntity]
GO
