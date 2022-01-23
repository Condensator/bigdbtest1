SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureauBusinessDetailErrorCodes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Description] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CreditBureauErrorMessageConfigId] [bigint] NULL,
	[CreditBureauBusinessDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Code] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ErrorType] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditBureauBusinessDetailErrorCodes]  WITH CHECK ADD  CONSTRAINT [ECreditBureauBusinessDetail_CreditBureauBusinessDetailErrorCodes] FOREIGN KEY([CreditBureauBusinessDetailId])
REFERENCES [dbo].[CreditBureauBusinessDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditBureauBusinessDetailErrorCodes] CHECK CONSTRAINT [ECreditBureauBusinessDetail_CreditBureauBusinessDetailErrorCodes]
GO
ALTER TABLE [dbo].[CreditBureauBusinessDetailErrorCodes]  WITH CHECK ADD  CONSTRAINT [ECreditBureauBusinessDetailErrorCode_CreditBureauErrorMessageConfig] FOREIGN KEY([CreditBureauErrorMessageConfigId])
REFERENCES [dbo].[CreditBureauErrorMessageConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauBusinessDetailErrorCodes] CHECK CONSTRAINT [ECreditBureauBusinessDetailErrorCode_CreditBureauErrorMessageConfig]
GO
