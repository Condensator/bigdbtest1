SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PropertyTaxStateSettings](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsExempt] [bit] NOT NULL,
	[AssessmentMonth] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[AssessmentDay] [int] NULL,
	[LeadDays] [int] NULL,
	[FilingDueMonth] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[FilingDueDay] [int] NULL,
	[IsSalesTaxOnPropertyTax] [bit] NOT NULL,
	[IsReportCSAs] [bit] NOT NULL,
	[IsReportInventory] [bit] NOT NULL,
	[EffectiveFromDate] [date] NOT NULL,
	[EffectiveToDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StateId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[PropertyTaxStateSettings]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxParameter_PropertyTaxStateSettings] FOREIGN KEY([PropertyTaxParameterId])
REFERENCES [dbo].[PropertyTaxParameters] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PropertyTaxStateSettings] CHECK CONSTRAINT [EPropertyTaxParameter_PropertyTaxStateSettings]
GO
ALTER TABLE [dbo].[PropertyTaxStateSettings]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxStateSettings_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxStateSettings] CHECK CONSTRAINT [EPropertyTaxStateSettings_Portfolio]
GO
ALTER TABLE [dbo].[PropertyTaxStateSettings]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxStateSettings_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxStateSettings] CHECK CONSTRAINT [EPropertyTaxStateSettings_State]
GO
