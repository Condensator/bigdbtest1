SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CourtFilings](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RecordStartDate] [date] NULL,
	[CaseNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[FilingDate] [date] NULL,
	[LegalRelief] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[RecordStatus] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsFromLegalRelief] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NOT NULL,
	[CourtId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CourtFilings]  WITH CHECK ADD  CONSTRAINT [ECourtFiling_Court] FOREIGN KEY([CourtId])
REFERENCES [dbo].[Courts] ([Id])
GO
ALTER TABLE [dbo].[CourtFilings] CHECK CONSTRAINT [ECourtFiling_Court]
GO
ALTER TABLE [dbo].[CourtFilings]  WITH CHECK ADD  CONSTRAINT [ECourtFiling_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[CourtFilings] CHECK CONSTRAINT [ECourtFiling_Customer]
GO
