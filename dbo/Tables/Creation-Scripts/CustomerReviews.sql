SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerReviews](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ScheduledDate] [date] NOT NULL,
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
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NOT NULL,
	[LastCustomerReviewId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsDummy] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CustomerReviews]  WITH CHECK ADD  CONSTRAINT [ECustomerReview_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[CustomerReviews] CHECK CONSTRAINT [ECustomerReview_Customer]
GO
ALTER TABLE [dbo].[CustomerReviews]  WITH CHECK ADD  CONSTRAINT [ECustomerReview_LastCustomerReview] FOREIGN KEY([LastCustomerReviewId])
REFERENCES [dbo].[CustomerReviews] ([Id])
GO
ALTER TABLE [dbo].[CustomerReviews] CHECK CONSTRAINT [ECustomerReview_LastCustomerReview]
GO
