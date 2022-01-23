SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VendorExposures](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[OwnedDirectExposure_Amount] [decimal](24, 2) NOT NULL,
	[OwnedDirectExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OwnedIndirectExposure_Amount] [decimal](24, 2) NOT NULL,
	[OwnedIndirectExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SyndicatedDirectExposure_Amount] [decimal](24, 2) NOT NULL,
	[SyndicatedDirectExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SyndicatedIndirectExposure_Amount] [decimal](24, 2) NOT NULL,
	[SyndicatedIndirectExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalVendorExposure_Amount] [decimal](24, 2) NOT NULL,
	[TotalVendorExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ExposureDate] [date] NULL,
	[ExposureVendorId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[VendorExposures]  WITH CHECK ADD  CONSTRAINT [EVendorExposure_ExposureVendor] FOREIGN KEY([ExposureVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[VendorExposures] CHECK CONSTRAINT [EVendorExposure_ExposureVendor]
GO
