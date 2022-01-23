SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPIReceivableDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Amount_Amount] [decimal](16, 2) NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[BeginUnit] [int] NOT NULL,
	[EndUnit] [int] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CPIReceivableId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[FromOverageTierId] [bigint] NULL,
	[ToOverageTierId] [bigint] NULL,
	[AssetId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPIReceivableDetails]  WITH CHECK ADD  CONSTRAINT [ECPIReceivable_CPIReceivableDetails] FOREIGN KEY([CPIReceivableId])
REFERENCES [dbo].[CPIReceivables] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPIReceivableDetails] CHECK CONSTRAINT [ECPIReceivable_CPIReceivableDetails]
GO
ALTER TABLE [dbo].[CPIReceivableDetails]  WITH CHECK ADD  CONSTRAINT [ECPIReceivableDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[CPIReceivableDetails] CHECK CONSTRAINT [ECPIReceivableDetail_Asset]
GO
ALTER TABLE [dbo].[CPIReceivableDetails]  WITH CHECK ADD  CONSTRAINT [ECPIReceivableDetail_FromOverageTier] FOREIGN KEY([FromOverageTierId])
REFERENCES [dbo].[CPIOverageTiers] ([Id])
GO
ALTER TABLE [dbo].[CPIReceivableDetails] CHECK CONSTRAINT [ECPIReceivableDetail_FromOverageTier]
GO
ALTER TABLE [dbo].[CPIReceivableDetails]  WITH CHECK ADD  CONSTRAINT [ECPIReceivableDetail_ToOverageTier] FOREIGN KEY([ToOverageTierId])
REFERENCES [dbo].[CPIOverageTiers] ([Id])
GO
ALTER TABLE [dbo].[CPIReceivableDetails] CHECK CONSTRAINT [ECPIReceivableDetail_ToOverageTier]
GO
