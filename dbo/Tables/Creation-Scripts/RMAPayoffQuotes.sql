SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RMAPayoffQuotes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PayoffQuoteId] [bigint] NOT NULL,
	[RMAProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CreatedById] [bigint] NOT NULL,
	[UpdatedById] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RMAPayoffQuotes]  WITH CHECK ADD  CONSTRAINT [ERMAPayoffQuote_PayoffQuote] FOREIGN KEY([PayoffQuoteId])
REFERENCES [dbo].[Payoffs] ([Id])
GO
ALTER TABLE [dbo].[RMAPayoffQuotes] CHECK CONSTRAINT [ERMAPayoffQuote_PayoffQuote]
GO
ALTER TABLE [dbo].[RMAPayoffQuotes]  WITH CHECK ADD  CONSTRAINT [ERMAProfile_RMAPayoffQuotes] FOREIGN KEY([RMAProfileId])
REFERENCES [dbo].[RMAProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RMAPayoffQuotes] CHECK CONSTRAINT [ERMAProfile_RMAPayoffQuotes]
GO
