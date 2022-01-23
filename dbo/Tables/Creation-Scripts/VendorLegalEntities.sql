SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VendorLegalEntities](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsApproved] [bit] NOT NULL,
	[IsOnHold] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CumulativeFundingLimit_Amount] [decimal](16, 2) NOT NULL,
	[CumulativeFundingLimit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[VendorId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[VendorLegalEntities]  WITH CHECK ADD  CONSTRAINT [EVendor_VendorLegalEntities] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[VendorLegalEntities] CHECK CONSTRAINT [EVendor_VendorLegalEntities]
GO
ALTER TABLE [dbo].[VendorLegalEntities]  WITH CHECK ADD  CONSTRAINT [EVendorLegalEntity_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[VendorLegalEntities] CHECK CONSTRAINT [EVendorLegalEntity_LegalEntity]
GO
