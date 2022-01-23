SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PropertyTaxReportCodeStateAssociations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LeaseContractType] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LeaseTransactionType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StateId] [bigint] NULL,
	[PropertyTaxReportCodeConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PropertyTaxReportCodeStateAssociations]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxReportCodeConfig_PropertyTaxReportCodeStateAssociations] FOREIGN KEY([PropertyTaxReportCodeConfigId])
REFERENCES [dbo].[PropertyTaxReportCodeConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PropertyTaxReportCodeStateAssociations] CHECK CONSTRAINT [EPropertyTaxReportCodeConfig_PropertyTaxReportCodeStateAssociations]
GO
ALTER TABLE [dbo].[PropertyTaxReportCodeStateAssociations]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxReportCodeStateAssociation_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxReportCodeStateAssociations] CHECK CONSTRAINT [EPropertyTaxReportCodeStateAssociation_State]
GO
