SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BookDepreciationEnMasseSetupDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CostBasis_Amount] [decimal](16, 2) NOT NULL,
	[CostBasis_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Salvage_Amount] [decimal](16, 2) NOT NULL,
	[Salvage_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BeginDate] [date] NOT NULL,
	[EndDate] [date] NULL,
	[RemainingLifeInMonths] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[BookDepreciationEnMasseSetupId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BookDepreciationTemplateId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BookDepreciationEnMasseSetupDetails]  WITH CHECK ADD  CONSTRAINT [EBookDepreciationEnMasseSetup_BookDepreciationEnMasseSetupDetails] FOREIGN KEY([BookDepreciationEnMasseSetupId])
REFERENCES [dbo].[BookDepreciationEnMasseSetups] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[BookDepreciationEnMasseSetupDetails] CHECK CONSTRAINT [EBookDepreciationEnMasseSetup_BookDepreciationEnMasseSetupDetails]
GO
ALTER TABLE [dbo].[BookDepreciationEnMasseSetupDetails]  WITH CHECK ADD  CONSTRAINT [EBookDepreciationEnMasseSetupDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[BookDepreciationEnMasseSetupDetails] CHECK CONSTRAINT [EBookDepreciationEnMasseSetupDetail_Asset]
GO
ALTER TABLE [dbo].[BookDepreciationEnMasseSetupDetails]  WITH CHECK ADD  CONSTRAINT [EBookDepreciationEnMasseSetupDetail_BookDepreciationTemplate] FOREIGN KEY([BookDepreciationTemplateId])
REFERENCES [dbo].[BookDepreciationTemplates] ([Id])
GO
ALTER TABLE [dbo].[BookDepreciationEnMasseSetupDetails] CHECK CONSTRAINT [EBookDepreciationEnMasseSetupDetail_BookDepreciationTemplate]
GO
