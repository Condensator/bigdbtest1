SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DirectCreditRatingFieldConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FieldName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Value] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[RequestType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[IsColumnMapped] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreditBureauDirectConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DirectCreditRatingFieldConfigs]  WITH CHECK ADD  CONSTRAINT [EDirectCreditRatingFieldConfig_CreditBureauDirectConfig] FOREIGN KEY([CreditBureauDirectConfigId])
REFERENCES [dbo].[CreditBureauDirectConfigs] ([Id])
GO
ALTER TABLE [dbo].[DirectCreditRatingFieldConfigs] CHECK CONSTRAINT [EDirectCreditRatingFieldConfig_CreditBureauDirectConfig]
GO
