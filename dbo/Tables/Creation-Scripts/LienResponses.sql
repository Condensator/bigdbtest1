SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LienResponses](
	[Id] [bigint] NOT NULL,
	[ExternalSystemNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ExternalRecordStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[AuthorityFilingStatus] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
	[AuthoritySubmitDate] [date] NULL,
	[AuthorityFileNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AuthorityFileDate] [date] NULL,
	[AuthorityOriginalFileDate] [date] NULL,
	[AuthorityFileExpiryDate] [date] NULL,
	[AuthorityFilingOffice] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AuthorityFilingType] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AuthorityFilingStateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ReasonReport_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ReasonReport_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[ReasonReport_Content] [varbinary](82) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LienResponses]  WITH CHECK ADD  CONSTRAINT [ELienFiling_LienResponse] FOREIGN KEY([Id])
REFERENCES [dbo].[LienFilings] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LienResponses] CHECK CONSTRAINT [ELienFiling_LienResponse]
GO
ALTER TABLE [dbo].[LienResponses]  WITH CHECK ADD  CONSTRAINT [ELienResponse_AuthorityFilingState] FOREIGN KEY([AuthorityFilingStateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[LienResponses] CHECK CONSTRAINT [ELienResponse_AuthorityFilingState]
GO
