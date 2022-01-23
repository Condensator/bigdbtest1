SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContractOriginationServicingDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsFromAcquiredPortfolio] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ServicingDetailId] [bigint] NOT NULL,
	[ContractOriginationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ContractOriginationServicingDetails]  WITH CHECK ADD  CONSTRAINT [EContractOrigination_ContractOriginationServicingDetails] FOREIGN KEY([ContractOriginationId])
REFERENCES [dbo].[ContractOriginations] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ContractOriginationServicingDetails] CHECK CONSTRAINT [EContractOrigination_ContractOriginationServicingDetails]
GO
ALTER TABLE [dbo].[ContractOriginationServicingDetails]  WITH CHECK ADD  CONSTRAINT [EContractOriginationServicingDetail_ServicingDetail] FOREIGN KEY([ServicingDetailId])
REFERENCES [dbo].[ServicingDetails] ([Id])
GO
ALTER TABLE [dbo].[ContractOriginationServicingDetails] CHECK CONSTRAINT [EContractOriginationServicingDetail_ServicingDetail]
GO
