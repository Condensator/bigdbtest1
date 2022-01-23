CREATE TYPE [dbo].[CreditBureauRequest] AS TABLE(
	[RequestedDate] [datetimeoffset](7) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RequestedBy] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DataRequestStatus] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[DataReceivedDate] [date] NULL,
	[ReviewStatus] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[ManuallyCreated] [bit] NOT NULL,
	[Active] [bit] NOT NULL,
	[ScorecardVersion] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[ODDXmlResponse] [varbinary](max) NULL,
	[ODDXmlRequest] [varbinary](max) NULL,
	[IsReportToGenerateFromUI] [bit] NOT NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
