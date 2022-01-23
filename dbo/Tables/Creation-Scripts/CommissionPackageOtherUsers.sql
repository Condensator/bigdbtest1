SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommissionPackageOtherUsers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserId] [bigint] NOT NULL,
	[CommissionPackageId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CommissionPackageOtherUsers]  WITH CHECK ADD  CONSTRAINT [ECommissionPackage_CommissionPackageOtherUsers] FOREIGN KEY([CommissionPackageId])
REFERENCES [dbo].[CommissionPackages] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommissionPackageOtherUsers] CHECK CONSTRAINT [ECommissionPackage_CommissionPackageOtherUsers]
GO
ALTER TABLE [dbo].[CommissionPackageOtherUsers]  WITH CHECK ADD  CONSTRAINT [ECommissionPackageOtherUser_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[CommissionPackageOtherUsers] CHECK CONSTRAINT [ECommissionPackageOtherUser_User]
GO
