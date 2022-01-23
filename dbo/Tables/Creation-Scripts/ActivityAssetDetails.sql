SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityAssetDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[NetValue_Amount] [decimal](16, 2) NULL,
	[NetValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AssetId] [bigint] NOT NULL,
	[ActivityForCustomerId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityAssetDetails]  WITH CHECK ADD  CONSTRAINT [EActivityAssetDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[ActivityAssetDetails] CHECK CONSTRAINT [EActivityAssetDetail_Asset]
GO
ALTER TABLE [dbo].[ActivityAssetDetails]  WITH CHECK ADD  CONSTRAINT [EActivityForCustomer_ActivityAssetDetails] FOREIGN KEY([ActivityForCustomerId])
REFERENCES [dbo].[ActivityForCustomers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivityAssetDetails] CHECK CONSTRAINT [EActivityForCustomer_ActivityAssetDetails]
GO
