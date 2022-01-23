SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureauRqstConsumerReasonCodes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
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
ALTER TABLE [dbo].[CreditBureauRqstConsumerReasonCodes]  WITH CHECK ADD  CONSTRAINT [ECreditBureauRqstConsumer_CreditBureauRqstConsumerReasonCodes] FOREIGN KEY([CreditBureauRqstConsumerId])
REFERENCES [dbo].[CreditBureauRqstConsumers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditBureauRqstConsumerReasonCodes] CHECK CONSTRAINT [ECreditBureauRqstConsumer_CreditBureauRqstConsumerReasonCodes]
GO
