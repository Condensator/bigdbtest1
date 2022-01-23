SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AgreementTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[AgreementTypeConfigId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AgreementTypes]  WITH CHECK ADD  CONSTRAINT [EAgreementType_AgreementTypeConfig] FOREIGN KEY([AgreementTypeConfigId])
REFERENCES [dbo].[AgreementTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[AgreementTypes] CHECK CONSTRAINT [EAgreementType_AgreementTypeConfig]
GO
ALTER TABLE [dbo].[AgreementTypes]  WITH CHECK ADD  CONSTRAINT [EAgreementType_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[AgreementTypes] CHECK CONSTRAINT [EAgreementType_Portfolio]
GO
