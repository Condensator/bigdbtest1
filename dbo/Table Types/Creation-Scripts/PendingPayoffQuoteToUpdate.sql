CREATE TYPE [dbo].[PendingPayoffQuoteToUpdate] AS TABLE(
	[PayoffQuoteId] [bigint] NOT NULL,
	[ScheduleNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsRefreshRequired] [bit] NOT NULL,
	[IsPaymentGenerationRequired] [bit] NOT NULL
)
GO
