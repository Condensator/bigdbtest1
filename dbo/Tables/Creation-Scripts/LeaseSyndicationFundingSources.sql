SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseSyndicationFundingSources](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ParticipationPercentage] [decimal](18, 8) NULL,
	[LessorGuaranteedResidualAmount_Amount] [decimal](16, 2) NULL,
	[LessorGuaranteedResidualAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CashHoldbackAmount_Amount] [decimal](16, 2) NULL,
	[CashHoldbackAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[UpfrontSyndicationFee_Amount] [decimal](16, 2) NULL,
	[UpfrontSyndicationFee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ScrapeFactor] [decimal](8, 4) NULL,
	[IsActive] [bit] NOT NULL,
	[SalesTaxResponsibility] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FunderId] [bigint] NOT NULL,
	[FunderRemitToId] [bigint] NULL,
	[FunderBillToId] [bigint] NULL,
	[FunderLocationId] [bigint] NULL,
	[LeaseSyndicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseSyndicationFundingSources]  WITH CHECK ADD  CONSTRAINT [ELeaseSyndication_LeaseSyndicationFundingSources] FOREIGN KEY([LeaseSyndicationId])
REFERENCES [dbo].[LeaseSyndications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseSyndicationFundingSources] CHECK CONSTRAINT [ELeaseSyndication_LeaseSyndicationFundingSources]
GO
ALTER TABLE [dbo].[LeaseSyndicationFundingSources]  WITH CHECK ADD  CONSTRAINT [ELeaseSyndicationFundingSource_Funder] FOREIGN KEY([FunderId])
REFERENCES [dbo].[Funders] ([Id])
GO
ALTER TABLE [dbo].[LeaseSyndicationFundingSources] CHECK CONSTRAINT [ELeaseSyndicationFundingSource_Funder]
GO
ALTER TABLE [dbo].[LeaseSyndicationFundingSources]  WITH CHECK ADD  CONSTRAINT [ELeaseSyndicationFundingSource_FunderBillTo] FOREIGN KEY([FunderBillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[LeaseSyndicationFundingSources] CHECK CONSTRAINT [ELeaseSyndicationFundingSource_FunderBillTo]
GO
ALTER TABLE [dbo].[LeaseSyndicationFundingSources]  WITH CHECK ADD  CONSTRAINT [ELeaseSyndicationFundingSource_FunderLocation] FOREIGN KEY([FunderLocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[LeaseSyndicationFundingSources] CHECK CONSTRAINT [ELeaseSyndicationFundingSource_FunderLocation]
GO
ALTER TABLE [dbo].[LeaseSyndicationFundingSources]  WITH CHECK ADD  CONSTRAINT [ELeaseSyndicationFundingSource_FunderRemitTo] FOREIGN KEY([FunderRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[LeaseSyndicationFundingSources] CHECK CONSTRAINT [ELeaseSyndicationFundingSource_FunderRemitTo]
GO
