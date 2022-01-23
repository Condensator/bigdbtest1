SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditRACQualifiers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Type] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[RuleDisplayText] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[ActualValue] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RACQualifierId] [bigint] NOT NULL,
	[CreditRACId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditRACQualifiers]  WITH CHECK ADD  CONSTRAINT [ECreditRAC_CreditRACQualifiers] FOREIGN KEY([CreditRACId])
REFERENCES [dbo].[CreditRACs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditRACQualifiers] CHECK CONSTRAINT [ECreditRAC_CreditRACQualifiers]
GO
ALTER TABLE [dbo].[CreditRACQualifiers]  WITH CHECK ADD  CONSTRAINT [ECreditRACQualifier_RACQualifier] FOREIGN KEY([RACQualifierId])
REFERENCES [dbo].[RACQualifiers] ([Id])
GO
ALTER TABLE [dbo].[CreditRACQualifiers] CHECK CONSTRAINT [ECreditRACQualifier_RACQualifier]
GO
