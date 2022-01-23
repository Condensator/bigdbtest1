SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PropertyTaxContractSettings](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LeaseContractType] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsBankQualified] [bit] NOT NULL,
	[EffectiveFromDate] [date] NOT NULL,
	[EffectiveToDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PropertyTaxParameterId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsFederalIncomeTaxExempt] [bit] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[UniqueIdentifier] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PropertyTaxContractSettings]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxContractSettings_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxContractSettings] CHECK CONSTRAINT [EPropertyTaxContractSettings_Portfolio]
GO
ALTER TABLE [dbo].[PropertyTaxContractSettings]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxParameter_PropertyTaxContractSettings] FOREIGN KEY([PropertyTaxParameterId])
REFERENCES [dbo].[PropertyTaxParameters] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PropertyTaxContractSettings] CHECK CONSTRAINT [EPropertyTaxParameter_PropertyTaxContractSettings]
GO
