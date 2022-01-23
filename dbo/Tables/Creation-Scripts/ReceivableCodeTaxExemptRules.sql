SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableCodeTaxExemptRules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxExemptRuleId] [bigint] NOT NULL,
	[StateId] [bigint] NOT NULL,
	[ReceivableCodeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableCodeTaxExemptRules]  WITH CHECK ADD  CONSTRAINT [EReceivableCode_ReceivableCodeTaxExemptRules] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableCodeTaxExemptRules] CHECK CONSTRAINT [EReceivableCode_ReceivableCodeTaxExemptRules]
GO
ALTER TABLE [dbo].[ReceivableCodeTaxExemptRules]  WITH CHECK ADD  CONSTRAINT [EReceivableCodeTaxExemptRule_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[ReceivableCodeTaxExemptRules] CHECK CONSTRAINT [EReceivableCodeTaxExemptRule_State]
GO
ALTER TABLE [dbo].[ReceivableCodeTaxExemptRules]  WITH CHECK ADD  CONSTRAINT [EReceivableCodeTaxExemptRule_TaxExemptRule] FOREIGN KEY([TaxExemptRuleId])
REFERENCES [dbo].[TaxExemptRules] ([Id])
GO
ALTER TABLE [dbo].[ReceivableCodeTaxExemptRules] CHECK CONSTRAINT [EReceivableCodeTaxExemptRule_TaxExemptRule]
GO
