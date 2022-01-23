SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureauRqstConsumerTradeLines](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SourceSegment] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AccountDesignatorCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AccountType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DateOpened] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CurrentStatus] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CreditBureauRqstConsumerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditBureauRqstConsumerTradeLines]  WITH CHECK ADD  CONSTRAINT [ECreditBureauRqstConsumer_CreditBureauRqstConsumerTradeLines] FOREIGN KEY([CreditBureauRqstConsumerId])
REFERENCES [dbo].[CreditBureauRqstConsumers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditBureauRqstConsumerTradeLines] CHECK CONSTRAINT [ECreditBureauRqstConsumer_CreditBureauRqstConsumerTradeLines]
GO
