SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AdditionalCharges](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Capitalize] [bit] NOT NULL,
	[CreateSoftAsset] [bit] NOT NULL,
	[Recurring] [bit] NOT NULL,
	[ReceivableDueDate] [date] NULL,
	[RecurringNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[FirstDueDate] [date] NULL,
	[DueDay] [int] NULL,
	[Frequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[ChargeApplicable] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[FeeId] [bigint] NOT NULL,
	[AssetTypeId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[GLTemplateId] [bigint] NULL,
	[AssetLocationId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[RowNumber] [int] NOT NULL,
	[SourceType] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[VATAmount_Amount] [decimal](16, 2) NOT NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FeePercent] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AdditionalCharges]  WITH CHECK ADD  CONSTRAINT [EAdditionalCharge_AssetLocation] FOREIGN KEY([AssetLocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[AdditionalCharges] CHECK CONSTRAINT [EAdditionalCharge_AssetLocation]
GO
ALTER TABLE [dbo].[AdditionalCharges]  WITH CHECK ADD  CONSTRAINT [EAdditionalCharge_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[AdditionalCharges] CHECK CONSTRAINT [EAdditionalCharge_AssetType]
GO
ALTER TABLE [dbo].[AdditionalCharges]  WITH CHECK ADD  CONSTRAINT [EAdditionalCharge_Fee] FOREIGN KEY([FeeId])
REFERENCES [dbo].[FeeTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[AdditionalCharges] CHECK CONSTRAINT [EAdditionalCharge_Fee]
GO
ALTER TABLE [dbo].[AdditionalCharges]  WITH CHECK ADD  CONSTRAINT [EAdditionalCharge_GLTemplate] FOREIGN KEY([GLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AdditionalCharges] CHECK CONSTRAINT [EAdditionalCharge_GLTemplate]
GO
ALTER TABLE [dbo].[AdditionalCharges]  WITH CHECK ADD  CONSTRAINT [EAdditionalCharge_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[AdditionalCharges] CHECK CONSTRAINT [EAdditionalCharge_ReceivableCode]
GO
