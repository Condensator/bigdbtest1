SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableCodeTaxRules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[JurisdictionLevel] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[AppliesToLowerJurisdictions] [bit] NOT NULL,
	[ExemptionRate] [decimal](10, 6) NOT NULL,
	[IsTaxable] [bit] NOT NULL,
	[UseCorporateRate] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CountryId] [bigint] NULL,
	[StateId] [bigint] NULL,
	[TaxTypeId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableCodeTaxRules]  WITH CHECK ADD  CONSTRAINT [EReceivableCode_ReceivableCodeTaxRules] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableCodeTaxRules] CHECK CONSTRAINT [EReceivableCode_ReceivableCodeTaxRules]
GO
ALTER TABLE [dbo].[ReceivableCodeTaxRules]  WITH CHECK ADD  CONSTRAINT [EReceivableCodeTaxRule_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[ReceivableCodeTaxRules] CHECK CONSTRAINT [EReceivableCodeTaxRule_Country]
GO
ALTER TABLE [dbo].[ReceivableCodeTaxRules]  WITH CHECK ADD  CONSTRAINT [EReceivableCodeTaxRule_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[ReceivableCodeTaxRules] CHECK CONSTRAINT [EReceivableCodeTaxRule_State]
GO
ALTER TABLE [dbo].[ReceivableCodeTaxRules]  WITH CHECK ADD  CONSTRAINT [EReceivableCodeTaxRule_TaxType] FOREIGN KEY([TaxTypeId])
REFERENCES [dbo].[TaxTypes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableCodeTaxRules] CHECK CONSTRAINT [EReceivableCodeTaxRule_TaxType]
GO
