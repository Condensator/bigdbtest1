SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureauRequests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RequestedDate] [datetimeoffset](7) NULL,
	[RequestedBy] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DataRequestStatus] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[DataReceivedDate] [date] NULL,
	[ScorecardVersion] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[ODDXmlRequest] [varbinary](max) NULL,
	[ODDXmlResponse] [varbinary](max) NULL,
	[ReviewStatus] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[Active] [bit] NOT NULL,
	[ManuallyCreated] [bit] NOT NULL,
	[IsReportToGenerateFromUI] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditBureauRequests]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditBureauRequests] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditBureauRequests] CHECK CONSTRAINT [ECreditProfile_CreditBureauRequests]
GO
