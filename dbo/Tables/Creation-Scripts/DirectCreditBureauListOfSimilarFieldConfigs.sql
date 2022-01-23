SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DirectCreditBureauListOfSimilarFieldConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FieldName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Value] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[RequestType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[CreditBureauDirectConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DirectCreditBureauListOfSimilarFieldConfigs]  WITH CHECK ADD  CONSTRAINT [EDirectCreditBureauListOfSimilarFieldConfig_CreditBureauDirectConfig] FOREIGN KEY([CreditBureauDirectConfigId])
REFERENCES [dbo].[CreditBureauDirectConfigs] ([Id])
GO
ALTER TABLE [dbo].[DirectCreditBureauListOfSimilarFieldConfigs] CHECK CONSTRAINT [EDirectCreditBureauListOfSimilarFieldConfig_CreditBureauDirectConfig]
GO
