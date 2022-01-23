SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QuoteLeaseTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsCloseEndLease] [bit] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DealProductTypeId] [bigint] NULL,
	[DealTypeId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[IsFloatRate] [bit] NOT NULL,
	[VATBasis] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[MinimumResidualValuePercentage] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[QuoteLeaseTypes]  WITH CHECK ADD  CONSTRAINT [EQuoteLeaseType_DealProductType] FOREIGN KEY([DealProductTypeId])
REFERENCES [dbo].[DealProductTypes] ([Id])
GO
ALTER TABLE [dbo].[QuoteLeaseTypes] CHECK CONSTRAINT [EQuoteLeaseType_DealProductType]
GO
ALTER TABLE [dbo].[QuoteLeaseTypes]  WITH CHECK ADD  CONSTRAINT [EQuoteLeaseType_DealType] FOREIGN KEY([DealTypeId])
REFERENCES [dbo].[DealTypes] ([Id])
GO
ALTER TABLE [dbo].[QuoteLeaseTypes] CHECK CONSTRAINT [EQuoteLeaseType_DealType]
GO
ALTER TABLE [dbo].[QuoteLeaseTypes]  WITH CHECK ADD  CONSTRAINT [EQuoteLeaseType_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[QuoteLeaseTypes] CHECK CONSTRAINT [EQuoteLeaseType_LegalEntity]
GO
