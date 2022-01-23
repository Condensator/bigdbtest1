SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LateFeeTemplates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[LateFeeType] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[LateFeeBasis] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[BasisPercentage] [decimal](5, 2) NULL,
	[Compounding] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[DayCountConvention] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AccountingTreatment] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[FloorAmount_Amount] [decimal](16, 2) NOT NULL,
	[FloorAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CeilingAmount_Amount] [decimal](16, 2) NOT NULL,
	[CeilingAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsAssessedOnlyOnce] [bit] NOT NULL,
	[IsAssessedOnTax] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsFloatRate] [bit] NOT NULL,
	[FloatRateResetFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[FloatRateResetUnit] [int] NULL,
	[IsLeadUnitsinBusinessDays] [bit] NOT NULL,
	[LeadFrequency] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[LeadUnits] [int] NULL,
	[EffectiveDayofMonth] [int] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableCodeId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[FloatRateIndexId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LateFeeTemplates]  WITH CHECK ADD  CONSTRAINT [ELateFeeTemplate_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[LateFeeTemplates] CHECK CONSTRAINT [ELateFeeTemplate_Currency]
GO
ALTER TABLE [dbo].[LateFeeTemplates]  WITH CHECK ADD  CONSTRAINT [ELateFeeTemplate_FloatRateIndex] FOREIGN KEY([FloatRateIndexId])
REFERENCES [dbo].[FloatRateIndexes] ([Id])
GO
ALTER TABLE [dbo].[LateFeeTemplates] CHECK CONSTRAINT [ELateFeeTemplate_FloatRateIndex]
GO
ALTER TABLE [dbo].[LateFeeTemplates]  WITH CHECK ADD  CONSTRAINT [ELateFeeTemplate_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LateFeeTemplates] CHECK CONSTRAINT [ELateFeeTemplate_ReceivableCode]
GO
