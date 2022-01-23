SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VendorProgramAddendums](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Date1] [date] NULL,
	[Date2] [date] NULL,
	[Comment1] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Amount1_Amount] [decimal](16, 2) NOT NULL,
	[Amount1_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount2_Amount] [decimal](16, 2) NOT NULL,
	[Amount2_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Percentage1] [decimal](5, 2) NULL,
	[Number1] [bigint] NULL,
	[Flag1] [bit] NOT NULL,
	[VendorProgramAddendumTypeId] [bigint] NOT NULL,
	[VendorId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[VendorProgramAddendums]  WITH CHECK ADD  CONSTRAINT [EVendor_VendorProgramAddendums] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[VendorProgramAddendums] CHECK CONSTRAINT [EVendor_VendorProgramAddendums]
GO
ALTER TABLE [dbo].[VendorProgramAddendums]  WITH CHECK ADD  CONSTRAINT [EVendorProgramAddendum_VendorProgramAddendumType] FOREIGN KEY([VendorProgramAddendumTypeId])
REFERENCES [dbo].[VendorProgramAddendumTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[VendorProgramAddendums] CHECK CONSTRAINT [EVendorProgramAddendum_VendorProgramAddendumType]
GO
