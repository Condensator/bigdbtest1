CREATE TYPE [dbo].[CustomerReview] AS TABLE(
	[ScheduledDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ActualReviewDate] [date] NULL,
	[Status] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[ReviewType] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[IsManualReviewRequired] [bit] NOT NULL,
	[ManualReviewReason] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsFinancialDocumentRequired] [bit] NOT NULL,
	[FinancialDate] [date] NULL,
	[FinancialDocumentExpectedDate] [date] NULL,
	[FinancialDocumentReceivedDate] [date] NULL,
	[ReviewComments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsDummy] [bit] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[LastCustomerReviewId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
