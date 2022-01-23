SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureauConsumerRatingReasonCodes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Description] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CreditBureauConsumerDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditBureauConsumerRatingReasonCodes]  WITH CHECK ADD  CONSTRAINT [ECreditBureauConsumerDetail_CreditBureauConsumerRatingReasonCodes] FOREIGN KEY([CreditBureauConsumerDetailId])
REFERENCES [dbo].[CreditBureauConsumerDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditBureauConsumerRatingReasonCodes] CHECK CONSTRAINT [ECreditBureauConsumerDetail_CreditBureauConsumerRatingReasonCodes]
GO
