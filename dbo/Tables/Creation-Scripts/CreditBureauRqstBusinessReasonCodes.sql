SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureauRqstBusinessReasonCodes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ModelReasonConfigId] [bigint] NOT NULL,
	[CreditBureauRqstBusinessId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditBureauRqstBusinessReasonCodes]  WITH CHECK ADD  CONSTRAINT [ECreditBureauRqstBusiness_CreditBureauRqstBusinessReasonCodes] FOREIGN KEY([CreditBureauRqstBusinessId])
REFERENCES [dbo].[CreditBureauRqstBusinesses] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditBureauRqstBusinessReasonCodes] CHECK CONSTRAINT [ECreditBureauRqstBusiness_CreditBureauRqstBusinessReasonCodes]
GO
ALTER TABLE [dbo].[CreditBureauRqstBusinessReasonCodes]  WITH CHECK ADD  CONSTRAINT [ECreditBureauRqstBusinessReasonCode_ModelReasonConfig] FOREIGN KEY([ModelReasonConfigId])
REFERENCES [dbo].[ModelReasonConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauRqstBusinessReasonCodes] CHECK CONSTRAINT [ECreditBureauRqstBusinessReasonCode_ModelReasonConfig]
GO
