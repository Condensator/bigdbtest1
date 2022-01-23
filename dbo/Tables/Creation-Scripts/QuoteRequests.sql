SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QuoteRequests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [bigint] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LastRequestedDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ProgramVendorId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[ProgramId] [bigint] NOT NULL,
	[QuoteDate] [date] NOT NULL,
	[Status] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[ReasonofDeclineId] [bigint] NULL,
	[LegalEntityId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[QuoteRequests]  WITH CHECK ADD  CONSTRAINT [EQuoteRequest_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[QuoteRequests] CHECK CONSTRAINT [EQuoteRequest_BusinessUnit]
GO
ALTER TABLE [dbo].[QuoteRequests]  WITH CHECK ADD  CONSTRAINT [EQuoteRequest_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[QuoteRequests] CHECK CONSTRAINT [EQuoteRequest_LegalEntity]
GO
ALTER TABLE [dbo].[QuoteRequests]  WITH CHECK ADD  CONSTRAINT [EQuoteRequest_Program] FOREIGN KEY([ProgramId])
REFERENCES [dbo].[Programs] ([Id])
GO
ALTER TABLE [dbo].[QuoteRequests] CHECK CONSTRAINT [EQuoteRequest_Program]
GO
ALTER TABLE [dbo].[QuoteRequests]  WITH CHECK ADD  CONSTRAINT [EQuoteRequest_ProgramVendor] FOREIGN KEY([ProgramVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[QuoteRequests] CHECK CONSTRAINT [EQuoteRequest_ProgramVendor]
GO
ALTER TABLE [dbo].[QuoteRequests]  WITH CHECK ADD  CONSTRAINT [EQuoteRequest_ReasonofDecline] FOREIGN KEY([ReasonofDeclineId])
REFERENCES [dbo].[ReasonofDeclineConfigs] ([Id])
GO
ALTER TABLE [dbo].[QuoteRequests] CHECK CONSTRAINT [EQuoteRequest_ReasonofDecline]
GO
