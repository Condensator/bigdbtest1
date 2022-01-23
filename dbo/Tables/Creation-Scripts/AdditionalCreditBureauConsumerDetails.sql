SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AdditionalCreditBureauConsumerDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FieldName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ResponseValue] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CreditBureauConsumerDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AdditionalCreditBureauConsumerDetails]  WITH CHECK ADD  CONSTRAINT [ECreditBureauConsumerDetail_AdditionalCreditBureauConsumerDetails] FOREIGN KEY([CreditBureauConsumerDetailId])
REFERENCES [dbo].[CreditBureauConsumerDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AdditionalCreditBureauConsumerDetails] CHECK CONSTRAINT [ECreditBureauConsumerDetail_AdditionalCreditBureauConsumerDetails]
GO
