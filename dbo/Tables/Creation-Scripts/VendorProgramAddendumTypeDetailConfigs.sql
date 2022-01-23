SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VendorProgramAddendumTypeDetailConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Attribute] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Label] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[VendorProgramAddendumTypeConfigId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[VendorProgramAddendumTypeDetailConfigs]  WITH CHECK ADD  CONSTRAINT [EVendorProgramAddendumTypeConfig_VendorProgramAddendumTypeDetailConfigs] FOREIGN KEY([VendorProgramAddendumTypeConfigId])
REFERENCES [dbo].[VendorProgramAddendumTypeConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[VendorProgramAddendumTypeDetailConfigs] CHECK CONSTRAINT [EVendorProgramAddendumTypeConfig_VendorProgramAddendumTypeDetailConfigs]
GO
