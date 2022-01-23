SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditPrincipalDeclineReasonCodes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PrincipalDeclineReasonCodeConfigId] [bigint] NOT NULL,
	[CreditPrincipalDeclineReasonId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditPrincipalDeclineReasonCodes]  WITH CHECK ADD  CONSTRAINT [ECreditPrincipalDeclineReason_CreditPrincipalDeclineReasonCodes] FOREIGN KEY([CreditPrincipalDeclineReasonId])
REFERENCES [dbo].[CreditPrincipalDeclineReasons] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditPrincipalDeclineReasonCodes] CHECK CONSTRAINT [ECreditPrincipalDeclineReason_CreditPrincipalDeclineReasonCodes]
GO
ALTER TABLE [dbo].[CreditPrincipalDeclineReasonCodes]  WITH CHECK ADD  CONSTRAINT [ECreditPrincipalDeclineReasonCode_PrincipalDeclineReasonCodeConfig] FOREIGN KEY([PrincipalDeclineReasonCodeConfigId])
REFERENCES [dbo].[PrincipalDeclineReasonCodeConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditPrincipalDeclineReasonCodes] CHECK CONSTRAINT [ECreditPrincipalDeclineReasonCode_PrincipalDeclineReasonCodeConfig]
GO
