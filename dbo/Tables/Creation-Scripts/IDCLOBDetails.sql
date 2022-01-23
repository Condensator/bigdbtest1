SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[IDCLOBDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IDCPercent] [decimal](5, 2) NULL,
	[Basis] [nvarchar](28) COLLATE Latin1_General_CI_AS NOT NULL,
	[AdditionalFixedAmount_Amount] [decimal](16, 2) NULL,
	[AdditionalFixedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[IDCTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[IDCLOBDetails]  WITH CHECK ADD  CONSTRAINT [EIDCLOBDetail_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[IDCLOBDetails] CHECK CONSTRAINT [EIDCLOBDetail_LineofBusiness]
GO
ALTER TABLE [dbo].[IDCLOBDetails]  WITH CHECK ADD  CONSTRAINT [EIDCTemplate_IDCLOBDetails] FOREIGN KEY([IDCTemplateId])
REFERENCES [dbo].[IDCTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[IDCLOBDetails] CHECK CONSTRAINT [EIDCTemplate_IDCLOBDetails]
GO
