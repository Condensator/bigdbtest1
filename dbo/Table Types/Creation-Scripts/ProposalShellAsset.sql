CREATE TYPE [dbo].[ProposalShellAsset] AS TABLE(
	[EquipmentTypeName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ModalityName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Quantity] [int] NOT NULL,
	[ManufacturerName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EquipmentLocation] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[EquipmentDescription] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[ModelYear] [decimal](4, 0) NULL,
	[Model] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SellingPrice_Amount] [decimal](16, 2) NULL,
	[SellingPrice_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ProposalId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
