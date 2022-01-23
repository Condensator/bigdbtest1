SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeveragedLeasePayoffs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[PayoffDate] [date] NOT NULL,
	[QuotationDate] [date] NOT NULL,
	[GoodThroughDate] [date] NOT NULL,
	[TerminationOption] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[UnearnedIncome_Amount] [decimal](24, 2) NULL,
	[UnearnedIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Residual_Amount] [decimal](24, 2) NULL,
	[Residual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DeferredTaxBalance_Amount] [decimal](24, 2) NULL,
	[DeferredTaxBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PayoffAmount_Amount] [decimal](24, 2) NULL,
	[PayoffAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RemainingRentalReceivable_Amount] [decimal](24, 2) NULL,
	[RemainingRentalReceivable_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DueDate] [date] NOT NULL,
	[IsPayOffAtInception] [bit] NOT NULL,
	[PostDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LeveragedLeaseId] [bigint] NOT NULL,
	[LeveragedLeasePayoffReceivableCodeId] [bigint] NOT NULL,
	[LeveragedLeasePayoffGLTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeveragedLeasePayoffs]  WITH CHECK ADD  CONSTRAINT [ELeveragedLeasePayoff_LeveragedLease] FOREIGN KEY([LeveragedLeaseId])
REFERENCES [dbo].[LeveragedLeases] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeasePayoffs] CHECK CONSTRAINT [ELeveragedLeasePayoff_LeveragedLease]
GO
ALTER TABLE [dbo].[LeveragedLeasePayoffs]  WITH CHECK ADD  CONSTRAINT [ELeveragedLeasePayoff_LeveragedLeasePayoffGLTemplate] FOREIGN KEY([LeveragedLeasePayoffGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeasePayoffs] CHECK CONSTRAINT [ELeveragedLeasePayoff_LeveragedLeasePayoffGLTemplate]
GO
ALTER TABLE [dbo].[LeveragedLeasePayoffs]  WITH CHECK ADD  CONSTRAINT [ELeveragedLeasePayoff_LeveragedLeasePayoffReceivableCode] FOREIGN KEY([LeveragedLeasePayoffReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeasePayoffs] CHECK CONSTRAINT [ELeveragedLeasePayoff_LeveragedLeasePayoffReceivableCode]
GO
