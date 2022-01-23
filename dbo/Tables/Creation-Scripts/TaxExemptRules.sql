SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxExemptRules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsCountryTaxExempt] [bit] NOT NULL,
	[IsStateTaxExempt] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxExemptionReasonId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[StateTaxExemptionReasonId] [bigint] NULL,
	[StateExemptionNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CountryExemptionNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsCityTaxExempt] [bit] NOT NULL,
	[IsCountyTaxExempt] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxExemptRules]  WITH CHECK ADD  CONSTRAINT [ETaxExemptRule_StateTaxExemptionReason] FOREIGN KEY([StateTaxExemptionReasonId])
REFERENCES [dbo].[TaxExemptionReasonConfigs] ([Id])
GO
ALTER TABLE [dbo].[TaxExemptRules] CHECK CONSTRAINT [ETaxExemptRule_StateTaxExemptionReason]
GO
ALTER TABLE [dbo].[TaxExemptRules]  WITH CHECK ADD  CONSTRAINT [ETaxExemptRule_TaxExemptionReason] FOREIGN KEY([TaxExemptionReasonId])
REFERENCES [dbo].[TaxExemptionReasonConfigs] ([Id])
GO
ALTER TABLE [dbo].[TaxExemptRules] CHECK CONSTRAINT [ETaxExemptRule_TaxExemptionReason]
GO
