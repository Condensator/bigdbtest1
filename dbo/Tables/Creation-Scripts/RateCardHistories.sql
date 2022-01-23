SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RateCardHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[RateCardFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[RateCardFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[RateCardFile_Content] [varbinary](82) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CurrencyId] [bigint] NOT NULL,
	[RateCardId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RateCardHistories]  WITH CHECK ADD  CONSTRAINT [ERateCardHistory_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[RateCardHistories] CHECK CONSTRAINT [ERateCardHistory_Currency]
GO
ALTER TABLE [dbo].[RateCardHistories]  WITH CHECK ADD  CONSTRAINT [ERateCardHistory_RateCard] FOREIGN KEY([RateCardId])
REFERENCES [dbo].[RateCards] ([Id])
GO
ALTER TABLE [dbo].[RateCardHistories] CHECK CONSTRAINT [ERateCardHistory_RateCard]
GO
ALTER TABLE [dbo].[RateCardHistories]  WITH CHECK ADD  CONSTRAINT [ERateCardHistory_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[RateCardHistories] CHECK CONSTRAINT [ERateCardHistory_Vendor]
GO
