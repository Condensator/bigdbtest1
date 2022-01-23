SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableForTransferScrapes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[SyndicationScrapeFactor] [decimal](8, 4) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableForTransferFundingSourceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableForTransferScrapes]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransferFundingSource_ReceivableForTransferScrapes] FOREIGN KEY([ReceivableForTransferFundingSourceId])
REFERENCES [dbo].[ReceivableForTransferFundingSources] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableForTransferScrapes] CHECK CONSTRAINT [EReceivableForTransferFundingSource_ReceivableForTransferScrapes]
GO
