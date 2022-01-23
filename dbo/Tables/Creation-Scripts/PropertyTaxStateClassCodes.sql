SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PropertyTaxStateClassCodes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EffectiveFromDate] [date] NOT NULL,
	[EffectiveToDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StateId] [bigint] NOT NULL,
	[AssetClassCodeId] [bigint] NOT NULL,
	[PropertyTaxParameterId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[UniqueIdentifier] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PropertyTaxStateClassCodes]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxParameter_PropertyTaxStateClassCodes] FOREIGN KEY([PropertyTaxParameterId])
REFERENCES [dbo].[PropertyTaxParameters] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PropertyTaxStateClassCodes] CHECK CONSTRAINT [EPropertyTaxParameter_PropertyTaxStateClassCodes]
GO
ALTER TABLE [dbo].[PropertyTaxStateClassCodes]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxStateClassCode_AssetClassCode] FOREIGN KEY([AssetClassCodeId])
REFERENCES [dbo].[AssetClassCodes] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxStateClassCodes] CHECK CONSTRAINT [EPropertyTaxStateClassCode_AssetClassCode]
GO
ALTER TABLE [dbo].[PropertyTaxStateClassCodes]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxStateClassCode_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxStateClassCodes] CHECK CONSTRAINT [EPropertyTaxStateClassCode_Portfolio]
GO
ALTER TABLE [dbo].[PropertyTaxStateClassCodes]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxStateClassCode_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxStateClassCodes] CHECK CONSTRAINT [EPropertyTaxStateClassCode_State]
GO
