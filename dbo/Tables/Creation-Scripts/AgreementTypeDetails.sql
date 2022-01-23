SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AgreementTypeDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[AgreementTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DealTypeId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AgreementTypeDetails]  WITH CHECK ADD  CONSTRAINT [EAgreementType_AgreementTypeDetails] FOREIGN KEY([AgreementTypeId])
REFERENCES [dbo].[AgreementTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AgreementTypeDetails] CHECK CONSTRAINT [EAgreementType_AgreementTypeDetails]
GO
ALTER TABLE [dbo].[AgreementTypeDetails]  WITH CHECK ADD  CONSTRAINT [EAgreementTypeDetail_DealType] FOREIGN KEY([DealTypeId])
REFERENCES [dbo].[DealTypes] ([Id])
GO
ALTER TABLE [dbo].[AgreementTypeDetails] CHECK CONSTRAINT [EAgreementTypeDetail_DealType]
GO
ALTER TABLE [dbo].[AgreementTypeDetails]  WITH CHECK ADD  CONSTRAINT [EAgreementTypeDetail_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[AgreementTypeDetails] CHECK CONSTRAINT [EAgreementTypeDetail_LineofBusiness]
GO
